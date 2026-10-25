import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/database.dart';
import 'package:gestion_stock/data/sync.dart';

/// Serveur en mémoire qui se comporte comme le schéma Supabase :
/// numéro `seq` partagé, produit gardé s'il est plus récent, mouvements uniques.
class FakeRemote implements SyncRemote {
  final categories = <String, Map<String, Object?>>{};
  final products = <String, Map<String, Object?>>{};
  final movements = <String, Map<String, Object?>>{};
  var _seq = 0;
  var calls = 0;

  @override
  Future<void> upsertCategories(List<Map<String, Object?>> rows) async =>
      _upsertLatest(categories, rows);

  @override
  Future<void> upsertProducts(List<Map<String, Object?>> rows) async =>
      _upsertLatest(products, rows);

  void _upsertLatest(Map<String, Map<String, Object?>> table, List<Map<String, Object?>> rows) {
    for (final row in rows) {
      final existing = table[row['id']];
      if (existing != null &&
          DateTime.parse(existing['updated_at'] as String)
              .isAfter(DateTime.parse(row['updated_at'] as String))) {
        continue;
      }
      table[row['id'] as String] = {...row, 'seq': ++_seq};
    }
  }

  @override
  Future<void> insertMovements(List<Map<String, Object?>> rows) async {
    for (final row in rows) {
      movements.putIfAbsent(row['id'] as String, () => {...row, 'seq': ++_seq});
    }
  }

  @override
  Future<RemoteChanges> changesSince(int cursor, int limit) async {
    calls++;
    List<Map<String, Object?>> after(Iterable<Map<String, Object?>> rows) =>
        (rows.where((r) => (r['seq'] as int) > cursor).toList()
              ..sort((a, b) => (a['seq'] as int).compareTo(b['seq'] as int)))
            .take(limit)
            .toList();
    return (
      categories: after(categories.values),
      products: after(products.values),
      movements: after(movements.values),
    );
  }
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late FakeRemote server;
  late AppDatabase phone;
  late AppDatabase pc;

  setUp(() {
    server = FakeRemote();
    phone = AppDatabase(NativeDatabase.memory());
    pc = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await phone.close();
    await pc.close();
  });

  Future<int> stock(AppDatabase db) async => (await db.watchStock().first).single.quantity;

  test('une vente saisie sur le téléphone apparaît sur le PC', () async {
    final p = await pc.addProduct(name: 'Maillot OM 2025 M', category: Category.maillot);
    await pc.receive(p.id, 10);
    await SyncEngine(pc, server).sync();

    await SyncEngine(phone, server).sync();
    expect(await stock(phone), 10);

    await phone.sell(p.id, 3);
    await SyncEngine(phone, server).sync();
    await SyncEngine(pc, server).sync();

    expect(await stock(pc), 7);
  });

  test('deux appareils hors ligne qui vendent chacun : tout est compté', () async {
    final p = await pc.addProduct(name: 'Tissage 22', category: Category.meche);
    await pc.receive(p.id, 10);
    await SyncEngine(pc, server).sync();
    await SyncEngine(phone, server).sync();

    // Les deux vendent sans réseau.
    await pc.sell(p.id, 2);
    await phone.sell(p.id, 4);

    await SyncEngine(pc, server).sync();
    await SyncEngine(phone, server).sync();
    await SyncEngine(pc, server).sync();

    expect(await stock(pc), 4);
    expect(await stock(phone), 4);
  });

  test('synchroniser sans changement n\'envoie rien', () async {
    final p = await phone.addProduct(name: 'Closure 5x5', category: Category.meche);
    await phone.receive(p.id, 1);
    final first = await SyncEngine(phone, server).sync();
    final second = await SyncEngine(phone, server).sync();

    expect(first.pushed, 5); // 3 catégories de départ + 1 produit + 1 mouvement
    expect(second.pushed, 0);
    expect(second.pulled, 0);
  });

  test('pour un produit, la modification la plus récente gagne', () async {
    final p = await pc.addProduct(name: 'Frontal', category: Category.meche);
    await SyncEngine(pc, server).sync();
    await SyncEngine(phone, server).sync();

    await pc.updateProduct(p.copyWith(name: 'Frontal 13x4'));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final onPhone = (await phone.watchStock().first).single.product;
    await phone.updateProduct(onPhone.copyWith(name: 'Frontal 13x6'));

    await SyncEngine(phone, server).sync();
    await SyncEngine(pc, server).sync();
    await SyncEngine(phone, server).sync();

    expect((await pc.watchStock().first).single.product.name, 'Frontal 13x6');
    expect((await phone.watchStock().first).single.product.name, 'Frontal 13x6');
  });

  test('une annulation se synchronise aussi', () async {
    final p = await phone.addProduct(name: 'Maillot Lions 2026 S', category: Category.maillot);
    await phone.receive(p.id, 5);
    final vente = await phone.sell(p.id, 1);
    await phone.undo(vente.id);
    await SyncEngine(phone, server).sync();
    await SyncEngine(pc, server).sync();

    expect(await stock(pc), 5);
  });

  test('beaucoup de lignes arrivent par pages sans rien perdre', () async {
    final p = await pc.addProduct(name: 'Petit article', category: Category.autre);
    for (var i = 0; i < 25; i++) {
      await pc.receive(p.id, 1);
    }
    await SyncEngine(pc, server).sync();

    await SyncEngine(phone, server, pageSize: 7).sync();

    expect(await stock(phone), 25);
    expect(server.calls, greaterThan(3));
  });

  test('un envoi validé en retard par le serveur n\'est pas perdu', () async {
    final p = await pc.addProduct(name: 'Maillot retard', category: Category.maillot);
    await pc.receive(p.id, 3);
    await SyncEngine(pc, server).sync();
    await SyncEngine(phone, server).sync();

    // Le serveur attribue un numéro plus petit que le dernier vu par le téléphone.
    server.movements['tardif'] = {
      'id': 'tardif', 'product_id': p.id, 'type': 'sold', 'delta': -1,
      'unit_price_cents': null, 'note': null, 'cancels_id': null,
      'created_at': DateTime.now().toUtc().toIso8601String(), 'seq': 1,
    };
    final report = await SyncEngine(phone, server).sync();

    expect(report.pulled, 1);
    expect(await stock(phone), 2);
  });

  test('une catégorie créée sur le PC apparaît sur le téléphone', () async {
    final c = await pc.addCategory('Perruques');
    await pc.addProduct(name: 'Perruque bob', category: c.id);
    await SyncEngine(pc, server).sync();
    await SyncEngine(phone, server).sync();

    final noms = (await phone.watchCategories().first).map((c) => c.name);
    expect(noms, contains('Perruques'));
    expect((await phone.watchStock(categoryId: c.id).first).single.product.name, 'Perruque bob');
  });

  test('les catégories par défaut renommées se synchronisent', () async {
    await pc.renameCategory(Category.maillot, 'Maillots de foot');
    await SyncEngine(pc, server).sync();
    await SyncEngine(phone, server).sync();

    final noms = (await phone.watchCategories().first).map((c) => c.name);
    expect(noms, contains('Maillots de foot'));
    expect(noms, isNot(contains('Maillots')));
  });
}
