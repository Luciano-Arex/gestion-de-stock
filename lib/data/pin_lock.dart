import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'database.dart';

/// Code PIN demandé à l'ouverture de l'appli.
///
/// Le code n'est jamais enregistré : seulement une empreinte salée et
/// étirée (PBKDF2-HMAC-SHA256). C'est une protection contre un passant qui
/// prend le téléphone, pas un chiffrement des données.
class PinLock extends ChangeNotifier {
  PinLock(this.db, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() _clock;

  static const hashKey = 'pin.hash';
  static const saltKey = 'pin.salt';
  static const iterations = 20000;
  static const maxAttempts = 5;
  static const lockout = Duration(seconds: 30);

  bool _enabled = false;
  bool get enabled => _enabled;

  bool _locked = false;
  bool get locked => _locked;

  int _failures = 0;
  DateTime? _blockedUntil;

  /// Temps d'attente restant après trop d'erreurs, sinon null.
  Duration? get waitRemaining {
    final until = _blockedUntil;
    if (until == null) return null;
    final left = until.difference(_clock());
    return left.isNegative ? null : left;
  }

  static bool isValidPin(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);

  /// À appeler au démarrage : verrouille si un PIN existe.
  Future<void> load() async {
    _enabled = (await db.readSetting(hashKey))?.isNotEmpty ?? false;
    _locked = _enabled;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) throw ArgumentError.value(pin, 'pin', '4 à 6 chiffres');
    final random = Random.secure();
    final salt = base64Encode(List<int>.generate(16, (_) => random.nextInt(256)));
    await db.writeSetting(saltKey, salt);
    await db.writeSetting(hashKey, _hash(pin, salt));
    _enabled = true;
    notifyListeners();
  }

  Future<void> removePin() async {
    await db.writeSetting(hashKey, '');
    await db.writeSetting(saltKey, '');
    _enabled = false;
    _locked = false;
    notifyListeners();
  }

  /// Vérifie le PIN sans déverrouiller (pour changer ou supprimer le code).
  Future<bool> check(String pin) async {
    final hash = await db.readSetting(hashKey);
    final salt = await db.readSetting(saltKey);
    if (hash == null || hash.isEmpty || salt == null) return false;
    return _constantTimeEquals(_hash(pin, salt), hash);
  }

  /// Renvoie true si le PIN est bon. Après [maxAttempts] erreurs, bloque [lockout].
  Future<bool> unlock(String pin) async {
    if (waitRemaining != null) return false;
    if (await check(pin)) {
      _failures = 0;
      _blockedUntil = null;
      _locked = false;
      notifyListeners();
      return true;
    }
    _failures++;
    if (_failures >= maxAttempts) {
      _failures = 0;
      _blockedUntil = _clock().add(lockout);
    }
    notifyListeners();
    return false;
  }

  /// Reverrouille, par exemple quand l'appli revient au premier plan.
  void lock() {
    if (!_enabled || _locked) return;
    _locked = true;
    notifyListeners();
  }

  @visibleForTesting
  static String hashPin(String pin, String salt) => _hash(pin, salt);

  static String _hash(String pin, String salt) =>
      base64Encode(_pbkdf2(utf8.encode(pin), base64Decode(salt), iterations, 32));

  static List<int> _pbkdf2(List<int> password, List<int> salt, int rounds, int length) {
    final hmac = Hmac(sha256, password);
    final out = <int>[];
    for (var block = 1; out.length < length; block++) {
      var u = hmac.convert([...salt, block >> 24, block >> 16 & 0xff, block >> 8 & 0xff, block & 0xff]).bytes;
      final t = List<int>.of(u);
      for (var i = 1; i < rounds; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.addAll(t);
    }
    return out.sublist(0, length);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
