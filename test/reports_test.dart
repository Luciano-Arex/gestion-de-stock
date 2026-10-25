import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/csv_export.dart';
import 'package:gestion_stock/data/database.dart';
import 'package:gestion_stock/data/reports.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late Product maillot;
  late Product meche;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    maillot = await db.addProduct(
      name: 'Maillot', category: Category.maillot,
      purchasePriceCents: 2000, salePriceCents: 4500,
    );
    meche = await db.addProduct(name: 'Mèche', category: Category.meche);
  });
  tearDown(() => db.close());

  test('la valeur du stock compte les prix d\'achat et signale les manquants', () async {
    await db.receive(maillot.id, 3);
    await db.receive(meche.id, 10);

    final value = StockValue.of(await db.watchStock().first);
    expect(value.cents, 6000);
    expect(value.productsWithoutPrice, 1);
  });

  test('le bilan des ventes ignore les annulations et classe les produits', () async {
    await db.receive(maillot.id, 10);
    await db.receive(meche.id, 10);
    await db.sell(maillot.id, 2, unitPriceCents: 4500);
    final annulee = await db.sell(maillot.id, 1, unitPriceCents: 4500);
    await db.undo(annulee.id);
    await db.sell(meche.id, 3, unitPriceCents: 3000);

    final report = SalesReport.of(await db.watchHistory().first);
    expect(report.units, 5);
    expect(report.revenueCents, 2 * 4500 + 3 * 3000);
    // Marge connue seulement pour le maillot (la mèche n'a pas de prix d'achat).
    expect(report.marginCents, 2 * (4500 - 2000));
    expect(report.byProduct.map((s) => s.product.name), ['Mèche', 'Maillot']);
  });

  test('le CSV est lisible par Excel et protégé contre les formules', () {
    final csv = CsvTable(['Produit', 'Note'], [
      ['Tissage; lisse', '=SOMME(A1)'],
      ['Maillot "OM"', '-3'],
    ]).encode();

    expect(csv.startsWith('﻿'), isTrue);
    expect(csv, contains('"Tissage; lisse";\'=SOMME(A1)\r\n'));
    expect(csv, contains('"Maillot ""OM""";-3\r\n'));
  });
}
