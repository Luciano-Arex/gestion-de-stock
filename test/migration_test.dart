import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/database.dart';

/// Tables telles que créées par la version 1.0 de l'appli.
const _v1Schema = [
  '''CREATE TABLE products (id TEXT NOT NULL, name TEXT NOT NULL, category TEXT NOT NULL,
     attributes TEXT NOT NULL DEFAULT '{}', purchase_price_cents INTEGER NULL,
     sale_price_cents INTEGER NULL, alert_threshold INTEGER NOT NULL DEFAULT 0,
     barcode TEXT NULL, archived INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL,
     synced_at TEXT NULL, PRIMARY KEY (id))''',
  '''CREATE TABLE movements (id TEXT NOT NULL, product_id TEXT NOT NULL REFERENCES products (id),
     type TEXT NOT NULL, delta INTEGER NOT NULL, unit_price_cents INTEGER NULL, note TEXT NULL,
     cancels_id TEXT NULL REFERENCES movements (id), created_at TEXT NOT NULL,
     synced_at TEXT NULL, PRIMARY KEY (id))''',
  'CREATE TABLE settings ("key" TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY ("key"))',
  """INSERT INTO products (id, name, category, updated_at)
     VALUES ('p1', 'Maillot Cameroun 2024 M', 'maillot', '2026-10-25T10:00:00.000')""",
  """INSERT INTO movements (id, product_id, type, delta, created_at)
     VALUES ('m1', 'p1', 'received', 4, '2026-10-25T10:00:00.000')""",
  'PRAGMA user_version = 1',
];

/// Version 2 : les catégories en plus, pas encore de suppression de produits.
final _v2Schema = [
  for (final sql in _v1Schema)
    if (!sql.startsWith('PRAGMA')) sql,
  '''CREATE TABLE categories (id TEXT NOT NULL, name TEXT NOT NULL,
     archived INTEGER NOT NULL DEFAULT 0, updated_at TEXT NOT NULL, synced_at TEXT NULL,
     PRIMARY KEY (id))''',
  """INSERT INTO categories (id, name, updated_at)
     VALUES ('maillot', 'Maillots', '2000-01-01T00:00:00.000')""",
  'PRAGMA user_version = 2',
];

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('passer de la version 1 à la 2 garde les produits et crée les catégories', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      for (final sql in _v1Schema) {
        raw.execute(sql);
      }
    }));
    addTearDown(db.close);

    final lignes = await db.watchStock().first;
    expect(lignes.single.quantity, 4);
    expect(lignes.single.product.category, Category.maillot);

    final categories = await db.watchCategories().first;
    expect(categories.map((c) => c.name), containsAll(['Mèches', 'Maillots', 'Autre']));
  });

  test('un nouveau stock part d\'une seule catégorie, dans la langue de l\'appli', () async {
    final db = AppDatabase(NativeDatabase.memory(), 'Sonstiges');
    addTearDown(db.close);
    final categories = await db.watchCategories().first;
    expect(categories.single.id, Category.autre);
    expect(categories.single.name, 'Sonstiges');
  });

  test('passer de la version 2 à la 3 permet de supprimer un produit', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      for (final sql in _v2Schema) {
        raw.execute(sql);
      }
    }));
    addTearDown(db.close);

    final ligne = (await db.watchStock().first).single;
    expect(ligne.product.deleted, isFalse);
    expect(ligne.quantity, 4);
    await db.deleteProduct(ligne.product.id);
    expect(await db.watchStock().first, isEmpty);
  });
}
