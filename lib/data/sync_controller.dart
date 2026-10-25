import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database.dart';
import 'supabase_remote.dart';
import 'sync.dart';

enum SyncStatus { notConfigured, signedOut, idle, syncing, offline }

/// Lance la synchronisation tout seul : au démarrage, quelques secondes après
/// chaque saisie, et toutes les deux minutes. L'appli marche sans : en cas
/// d'échec on réessaie plus tard, rien n'est perdu.
class SyncController extends ChangeNotifier {
  SyncController(this.db) {
    if (!supabaseConfigured) return;
    _authChanges = _auth.onAuthStateChange.listen((_) {
      _status = _auth.currentSession == null ? SyncStatus.signedOut : SyncStatus.idle;
      notifyListeners();
      if (_auth.currentSession != null) syncNow();
    });
    _changes = db
        .tableUpdates(TableUpdateQuery.onAllTables([db.products, db.movements]))
        .listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 3), () async {
        // La synchro écrit aussi dans ces tables : on ne relance que s'il reste à envoyer.
        if (await db.hasPendingChanges()) await syncNow();
      });
    });
    _periodic = Timer.periodic(const Duration(minutes: 2), (_) => syncNow());
  }

  final AppDatabase db;
  StreamSubscription<AuthState>? _authChanges;
  StreamSubscription<void>? _changes;
  Timer? _debounce;
  Timer? _periodic;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  SyncStatus _status = supabaseConfigured ? SyncStatus.signedOut : SyncStatus.notConfigured;
  SyncStatus get status => _status;

  DateTime? _lastSuccess;
  DateTime? get lastSuccess => _lastSuccess;

  String? get account => supabaseConfigured ? _auth.currentUser?.email : null;

  /// Lève [AuthException] si l'adresse ou le mot de passe est faux.
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> syncNow() async {
    if (_status == SyncStatus.syncing || !supabaseConfigured || _auth.currentSession == null) {
      return;
    }
    _status = SyncStatus.syncing;
    notifyListeners();
    final engine = SyncEngine(db, SupabaseRemote(Supabase.instance.client));
    try {
      await engine.sync();
      _lastSuccess = await engine.lastSuccess();
      _status = SyncStatus.idle;
    } catch (e) {
      debugPrint('Synchronisation impossible : $e');
      _status = SyncStatus.offline;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authChanges?.cancel();
    _changes?.cancel();
    _debounce?.cancel();
    _periodic?.cancel();
    super.dispose();
  }
}
