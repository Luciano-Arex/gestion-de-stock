import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/backup.dart';
import 'package:gestion_stock/data/database.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase source;
  late AppDatabase target;

  setUp(() async {
    source = AppDatabase(NativeDatabase.memory());
    target = AppDatabase(NativeDatabase.memory());
    final p = await source.addProduct(
      name: 'Frontal 13x4 body wave',
      category: Category.meche,
      salePriceCents: 8990,
    );
    await source.receive(p.id, 6);
    final vente = await source.sell(p.id, 2);
    await source.undo(vente.id);
    await source.sell(p.id, 1);
  });

  tearDown(() async {
    await source.close();
    await target.close();
  });

  test('une sauvegarde restaurée redonne le même stock', () async {
    final result = await target.importJson(await source.exportJson());

    expect(result.products, 1);
    expect(result.newMovements, 4);
    final ligne = (await target.watchStock().first).single;
    expect(ligne.product.name, 'Frontal 13x4 body wave');
    expect(ligne.product.salePriceCents, 8990);
    expect(ligne.quantity, 5);
  });

  test('restaurer deux fois ne double pas le stock', () async {
    final json = await source.exportJson();
    await target.importJson(json);
    final second = await target.importJson(json);

    expect(second.newMovements, 0);
    expect((await target.watchStock().first).single.quantity, 5);
  });

  test('un fichier étranger est refusé sans rien toucher', () async {
    expect(() => target.importJson('{"hello": 1}'), throwsFormatException);
    expect(() => target.importJson('pas du json'), throwsFormatException);
    expect(await target.watchStock().first, isEmpty);
  });

  test('une sauvegarde d\'avant la suppression de produits se restaure', () async {
    final data = jsonDecode(await source.exportJson()) as Map<String, dynamic>;
    for (final p in data['products'] as List) {
      (p as Map<String, dynamic>).remove('deleted');
    }
    await target.importJson(jsonEncode(data));
    expect((await target.watchStock().first).single.quantity, 5);
  });
}
