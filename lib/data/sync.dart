import 'package:drift/drift.dart';

import 'database.dart';

/// Ce que le serveur sait faire. Les lignes sont des Map aux noms de colonnes
/// du serveur (snake_case), chaque ligne lue porte un numéro `seq` croissant.
abstract class SyncRemote {
  Future<void> upsertCategories(List<Map<String, Object?>> rows);

  Future<void> upsertProducts(List<Map<String, Object?>> rows);

  /// Ignore les mouvements déjà présents (un envoi peut être rejoué).
  Future<void> insertMovements(List<Map<String, Object?>> rows);

  /// Lignes modifiées après [cursor], triées par `seq`, au plus [limit] par table.
  Future<RemoteChanges> changesSince(int cursor, int limit);
}

typedef RemoteChanges = ({
  List<Map<String, Object?>> categories,
  List<Map<String, Object?>> products,
  List<Map<String, Object?>> movements,
});

class SyncReport {
  SyncReport({required this.pushed, required this.pulled});
  final int pushed;
  final int pulled;
}

/// Synchronisation « chacun garde tout » :
///
/// 1. on envoie ce qui a changé ici (produits modifiés, mouvements nouveaux) ;
/// 2. on récupère ce qui a changé ailleurs depuis la dernière fois.
///
/// Les mouvements ne sont jamais modifiés, donc deux appareils ne peuvent pas
/// se contredire sur eux. Pour les produits, la modification la plus récente gagne.
class SyncEngine {
  SyncEngine(this.db, this.remote, {this.pageSize = 500});

  final AppDatabase db;
  final SyncRemote remote;
  final int pageSize;

  static const cursorKey = 'sync.cursor';
  static const lastSyncKey = 'sync.lastSuccess';

  Future<SyncReport> sync() async {
    final pushed = await _push();
    final pulled = await _pull();
    await db.writeSetting(lastSyncKey, DateTime.now().toUtc().toIso8601String());
    return SyncReport(pushed: pushed, pulled: pulled);
  }

  Future<DateTime?> lastSuccess() async {
    final value = await db.readSetting(lastSyncKey);
    return value == null ? null : DateTime.parse(value).toLocal();
  }

  Future<int> _push() async {
    final now = DateTime.now();
    final p = db.products;
    final dirtyCategories = await db.pendingCategories().get();
    final dirtyProducts = await db.pendingProducts().get();
    final newMovements = await db.pendingMovements().get();

    if (dirtyCategories.isNotEmpty) {
      await remote.upsertCategories([for (final c in dirtyCategories) categoryToRow(c)]);
      await (db.update(db.categories)..where((c) => c.id.isIn(dirtyCategories.map((c) => c.id))))
          .write(CategoriesCompanion(syncedAt: Value(now)));
    }
    // Les produits avant les mouvements : un mouvement doit pointer vers un produit connu du serveur.
    if (dirtyProducts.isNotEmpty) {
      await remote.upsertProducts([for (final r in dirtyProducts) productToRow(r)]);
      await (db.update(p)..where((r) => r.id.isIn(dirtyProducts.map((r) => r.id))))
          .write(ProductsCompanion(syncedAt: Value(now)));
    }
    if (newMovements.isNotEmpty) {
      await remote.insertMovements([for (final m in newMovements) movementToRow(m)]);
      await (db.update(db.movements)..where((m) => m.id.isIn(newMovements.map((m) => m.id))))
          .write(MovementsCompanion(syncedAt: Value(now)));
    }
    return dirtyCategories.length + dirtyProducts.length + newMovements.length;
  }

  /// Numéros relus à chaque synchronisation. Deux envois presque simultanés
  /// peuvent être validés par le serveur dans le désordre : sans cette marge,
  /// le plus lent pourrait être sauté. Relire une ligne déjà connue est sans effet.
  static const overlap = 50;

  Future<int> _pull() async {
    final saved = int.tryParse(await db.readSetting(cursorKey) ?? '') ?? 0;
    var cursor = saved > overlap ? saved - overlap : 0;
    var pulled = 0;
    while (true) {
      final changes = await remote.changesSince(cursor, pageSize);
      final rows = [...changes.categories, ...changes.products, ...changes.movements];
      if (rows.isEmpty) break;

      final now = DateTime.now();
      pulled += await db.transaction(() async {
        var applied = 0;
        for (final row in changes.categories) {
          final incoming = categoryFromRow(row).copyWith(syncedAt: Value(now));
          final local = await (db.select(db.categories)..where((c) => c.id.equals(incoming.id)))
              .getSingleOrNull();
          if (local == null || incoming.updatedAt.isAfter(local.updatedAt)) {
            await db.into(db.categories).insertOnConflictUpdate(incoming);
            applied++;
          }
        }
        for (final row in changes.products) {
          final incoming = productFromRow(row).copyWith(syncedAt: Value(now));
          final local = await (db.select(db.products)..where((p) => p.id.equals(incoming.id)))
              .getSingleOrNull();
          if (local == null || incoming.updatedAt.isAfter(local.updatedAt)) {
            await db.into(db.products).insertOnConflictUpdate(incoming);
            applied++;
          }
        }
        final before = await db.movements.count().getSingle();
        await db.batch((b) => b.insertAll(
              db.movements,
              [for (final row in changes.movements) movementFromRow(row).copyWith(syncedAt: Value(now))],
              mode: InsertMode.insertOrIgnore,
            ));
        return applied + await db.movements.count().getSingle() - before;
      });

      // Si une table a rempli sa page, on ne peut avancer que jusqu'à son dernier
      // numéro : la suite viendra au tour suivant. Relire une ligne est sans effet.
      final truncated = [changes.categories, changes.products, changes.movements]
          .where((l) => l.length >= pageSize);
      final next = truncated.isEmpty
          ? rows.map(_seq).reduce((a, b) => a > b ? a : b)
          : truncated.map((l) => _seq(l.last)).reduce((a, b) => a < b ? a : b);
      if (next > saved) await db.writeSetting(cursorKey, '$next');
      if (truncated.isEmpty || next <= cursor) break;
      cursor = next;
    }
    return pulled;
  }

  static int _seq(Map<String, Object?> row) => (row['seq'] as num).toInt();
}

Map<String, Object?> categoryToRow(ProductCategory c) => {
      'id': c.id,
      'name': c.name,
      'archived': c.archived,
      'updated_at': c.updatedAt.toUtc().toIso8601String(),
    };

ProductCategory categoryFromRow(Map<String, Object?> r) => ProductCategory(
      id: r['id'] as String,
      name: r['name'] as String,
      archived: r['archived'] as bool? ?? false,
      updatedAt: DateTime.parse(r['updated_at'] as String).toLocal(),
    );

Map<String, Object?> productToRow(Product p) => {
      'id': p.id,
      'name': p.name,
      'category': p.category,
      'attributes': p.attributes,
      'purchase_price_cents': p.purchasePriceCents,
      'sale_price_cents': p.salePriceCents,
      'alert_threshold': p.alertThreshold,
      'barcode': p.barcode,
      'archived': p.archived,
      'deleted': p.deleted,
      'updated_at': p.updatedAt.toUtc().toIso8601String(),
    };

Product productFromRow(Map<String, Object?> r) => Product(
      id: r['id'] as String,
      name: r['name'] as String,
      category: r['category'] as String,
      attributes: r['attributes'] as String? ?? '{}',
      purchasePriceCents: r['purchase_price_cents'] as int?,
      salePriceCents: r['sale_price_cents'] as int?,
      alertThreshold: r['alert_threshold'] as int? ?? 0,
      barcode: r['barcode'] as String?,
      archived: r['archived'] as bool? ?? false,
      deleted: r['deleted'] as bool? ?? false,
      updatedAt: DateTime.parse(r['updated_at'] as String).toLocal(),
    );

Map<String, Object?> movementToRow(Movement m) => {
      'id': m.id,
      'product_id': m.productId,
      'type': m.type.name,
      'delta': m.delta,
      'unit_price_cents': m.unitPriceCents,
      'note': m.note,
      'cancels_id': m.cancelsId,
      'created_at': m.createdAt.toUtc().toIso8601String(),
    };

Movement movementFromRow(Map<String, Object?> r) => Movement(
      id: r['id'] as String,
      productId: r['product_id'] as String,
      type: MovementType.values.byName(r['type'] as String),
      delta: r['delta'] as int,
      unitPriceCents: r['unit_price_cents'] as int?,
      note: r['note'] as String?,
      cancelsId: r['cancels_id'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
    );
