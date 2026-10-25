import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database.dart';
import 'pin_lock.dart';
import 'sync_controller.dart';

/// Ce qui appartient au compte connecté : son stock, sa synchro et son code PIN.
class Workspace {
  Workspace({required this.userId, required this.db, required this.pin, this.email, this.sync});

  final String userId;
  final String? email;
  final AppDatabase db;
  final PinLock pin;
  final SyncController? sync;

  Future<void> close() async {
    sync?.dispose();
    pin.dispose();
    await db.close();
  }
}

/// Connexion et création de compte. Interface séparée pour pouvoir tester
/// les écrans sans serveur.
abstract class AuthGateway {
  String? get userId;
  String? get email;

  /// Signale chaque connexion ou déconnexion.
  Stream<void> get changes;

  Future<void> signIn(String email, String password);

  /// Renvoie true si le compte est ouvert tout de suite, false s'il faut
  /// d'abord confirmer l'adresse e-mail.
  Future<bool> signUp(String email, String password);

  /// Envoie par e-mail un code pour choisir un nouveau mot de passe.
  Future<void> sendResetCode(String email);

  /// Vérifie le code reçu, change le mot de passe et ouvre le compte.
  Future<void> resetPassword(String email, String code, String newPassword);

  Future<void> signOut();
}

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this.client);

  final SupabaseClient client;
  GoTrueClient get _auth => client.auth;

  @override
  String? get userId => _auth.currentUser?.id;

  @override
  String? get email => _auth.currentUser?.email;

  @override
  Stream<void> get changes => _auth.onAuthStateChange;

  @override
  Future<void> signIn(String email, String password) =>
      _auth.signInWithPassword(email: email.trim(), password: password);

  @override
  Future<bool> signUp(String email, String password) async {
    final response = await _auth.signUp(email: email.trim(), password: password);
    return response.session != null;
  }

  @override
  Future<void> sendResetCode(String email) => _auth.resetPasswordForEmail(email.trim());

  @override
  Future<void> resetPassword(String email, String code, String newPassword) async {
    await _auth.verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.recovery);
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Ouvre le stock du compte connecté et le referme à la déconnexion.
///
/// Chaque compte a son propre fichier sur l'appareil : deux personnes qui se
/// connectent tour à tour sur le même PC ne voient jamais le stock de l'autre.
class AccountController extends ChangeNotifier {
  AccountController(this.auth, {required this.openWorkspace});

  final AuthGateway auth;
  final Future<Workspace> Function(String userId, String? email) openWorkspace;

  Workspace? _current;
  Workspace? get current => _current;

  bool _opening = false;
  bool get opening => _opening;

  StreamSubscription<void>? _changes;
  Future<void> _pending = Future.value();

  Future<void> start() {
    _changes = auth.changes.listen((_) => _refresh());
    return _refresh();
  }

  // Les changements sont traités un par un, dans l'ordre.
  Future<void> _refresh() => _pending = _pending.then((_) => _apply()).catchError((Object e) {
        debugPrint('Ouverture du stock impossible : $e');
      });

  Future<void> _apply() async {
    final userId = auth.userId;
    if (userId == _current?.userId) return;
    final old = _current;
    _current = null;
    _opening = userId != null;
    notifyListeners();
    await old?.close();
    if (userId != null) {
      try {
        _current = await openWorkspace(userId, auth.email);
      } finally {
        _opening = false;
        notifyListeners();
      }
    }
  }

  /// Le fichier du stock de ce compte sur l'appareil.
  ///
  /// Le premier compte connecté reprend le stock déjà présent (celui des
  /// versions sans comptes), les suivants partent d'un stock vide qui se
  /// remplit avec leurs données du serveur.
  static Future<String> databaseNameFor(String userId, SharedPreferencesAsync prefs) async {
    const key = 'account.localOwner';
    final owner = await prefs.getString(key);
    if (owner == null) {
      await prefs.setString(key, userId);
      return AppDatabase.localName;
    }
    return owner == userId ? AppDatabase.localName : 'stock_$userId';
  }

  @override
  void dispose() {
    _changes?.cancel();
    _current?.close();
    super.dispose();
  }
}
