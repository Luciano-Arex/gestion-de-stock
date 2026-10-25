import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database.dart';
import 'supabase_remote.dart';
import 'sync.dart';

enum SyncStatus { notConfigured, signedOut, idle, syncing, offline }

/// Lance la synchronisation tout seul : au démarrage, quelques secondes après
/// chaque saisie, dès qu'un autre appareil du même compte envoie une
/// modification, au retour dans l'appli, et chaque minute au cas où. L'appli
/// marche sans : en cas d'échec on réessaie plus tard, rien n'est perdu.
class SyncController extends ChangeNotifier {
  SyncController(this.db) {
    if (!supabaseConfigured) return;
    _authChanges = _auth.onAuthStateChange.listen((_) {
      _status = _auth.currentSession == null ? SyncStatus.signedOut : SyncStatus.idle;
      notifyListeners();
      if (_auth.currentSession != null) syncNow();
    });
    _changes = db
        .tableUpdates(TableUpdateQuery.onAllTables([db.categories, db.products, db.movements]))
        .listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 3), () async {
        // La synchro écrit aussi dans ces tables : on ne relance que s'il reste à envoyer.
        if (await db.hasPendingChanges()) await syncNow();
      });
    });
    _live = _listenToServer();
    _lifecycle = AppLifecycleListener(onResume: syncNow);
    // Filet de sécurité si le direct est coupé (réseau d'entreprise, veille…).
    _periodic = Timer.periodic(const Duration(minutes: 1), (_) => syncNow());
  }

  /// Le serveur prévient dès qu'une ligne du compte change, ce qui fait
  /// apparaître en quelques secondes ce qu'une autre personne vient de saisir.
  /// Le serveur n'envoie que les lignes du compte connecté.
  RealtimeChannel _listenToServer() {
    final client = Supabase.instance.client;
    final channel = client.channel('stock');
    for (final table in ['categories', 'products', 'movements']) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => _syncSoon(),
      );
    }
    return channel
      ..subscribe((status, _) {
        // Reconnecté après une coupure : on rattrape ce qui a été manqué.
        if (status == RealtimeSubscribeStatus.subscribed) syncNow();
      });
  }

  // Une saisie envoie souvent plusieurs lignes d'un coup : une seule synchro suffit.
  void _syncSoon() {
    _liveDebounce?.cancel();
    _liveDebounce = Timer(const Duration(seconds: 1), syncNow);
  }

  final AppDatabase db;
  StreamSubscription<AuthState>? _authChanges;
  StreamSubscription<void>? _changes;
  RealtimeChannel? _live;
  AppLifecycleListener? _lifecycle;
  Timer? _debounce;
  Timer? _liveDebounce;
  Timer? _periodic;
  // Une demande arrivée pendant une synchro : on en refait une juste après.
  bool _again = false;

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
    if (!supabaseConfigured || _auth.currentSession == null) return;
    if (_status == SyncStatus.syncing) {
      _again = true;
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
    if (_again) {
      _again = false;
      await syncNow();
    }
  }

  @override
  void dispose() {
    _authChanges?.cancel();
    _changes?.cancel();
    _debounce?.cancel();
    _liveDebounce?.cancel();
    _periodic?.cancel();
    _lifecycle?.dispose();
    final live = _live;
    if (live != null) Supabase.instance.client.removeChannel(live);
    super.dispose();
  }
}
