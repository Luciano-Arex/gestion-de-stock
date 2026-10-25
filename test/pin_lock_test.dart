import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/database.dart';
import 'package:gestion_stock/data/pin_lock.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late DateTime now;
  late PinLock pin;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 10, 25, 12);
    pin = PinLock(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('sans PIN, l\'appli n\'est pas verrouillée', () async {
    await pin.load();
    expect(pin.enabled, isFalse);
    expect(pin.locked, isFalse);
  });

  test('le PIN n\'est jamais stocké en clair', () async {
    await pin.setPin('2468');
    final hash = await db.readSetting(PinLock.hashKey);
    expect(hash, isNot(contains('2468')));
    expect(hash, isNotEmpty);
  });

  test('au redémarrage l\'appli est verrouillée, le bon PIN la déverrouille', () async {
    await pin.setPin('2468');
    final restart = PinLock(db, clock: () => now);
    await restart.load();

    expect(restart.locked, isTrue);
    expect(await restart.unlock('1111'), isFalse);
    expect(restart.locked, isTrue);
    expect(await restart.unlock('2468'), isTrue);
    expect(restart.locked, isFalse);
  });

  test('après 5 erreurs, il faut attendre 30 secondes', () async {
    await pin.setPin('2468');
    pin.lock();
    for (var i = 0; i < PinLock.maxAttempts; i++) {
      await pin.unlock('0000');
    }
    expect(pin.waitRemaining, isNotNull);
    expect(await pin.unlock('2468'), isFalse, reason: 'bloqué même avec le bon code');

    now = now.add(const Duration(seconds: 31));
    expect(pin.waitRemaining, isNull);
    expect(await pin.unlock('2468'), isTrue);
  });

  test('supprimer le PIN retire le verrouillage', () async {
    await pin.setPin('2468');
    await pin.removePin();
    final restart = PinLock(db);
    await restart.load();
    expect(restart.locked, isFalse);
  });

  test('seuls 4 à 6 chiffres sont acceptés', () {
    expect(PinLock.isValidPin('123'), isFalse);
    expect(PinLock.isValidPin('1234'), isTrue);
    expect(PinLock.isValidPin('123456'), isTrue);
    expect(PinLock.isValidPin('12a4'), isFalse);
    expect(() => pin.setPin('12'), throwsArgumentError);
  });

  test('l\'empreinte suit PBKDF2-HMAC-SHA256 (vecteur calculé avec Python hashlib)', () {
    final salt = base64Encode(utf8.encode('0123456789abcdef'));
    expect(PinLock.hashPin('2468', salt), 'Ti8BW4oYXuCVLKpOlGx+u6QPWnBb7rCZ/SwWvlyzLOo=');
  });
}
