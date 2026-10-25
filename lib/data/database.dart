import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

const _uuid = Uuid();

/// Identifiants des catégories des premières versions. Les autres sont des UUID.
///
/// Un nouveau stock ne contient que [autre] : chacun crée ses propres catégories
/// (maillots, jus, mèches…).
abstract final class Category {
  static const meche = 'meche';
  static const maillot = 'maillot';
  static const autre = 'autre';
}

/// Catégories de produits, modifiables par l'utilisatrice.
@DataClassName('ProductCategory')
class Categories extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Type d'un mouvement de stock.
///
/// `correction` sert uniquement à annuler un mouvement précédent :
/// un mouvement n'est jamais modifié ni supprimé.
enum MovementType { received, sold, loss, correction }

/// Une ligne = une combinaison précise (ex. « maillot Cameroun domicile 2024, taille M »).
class Products extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  // Identifiant d'une ligne de Categories.
  TextColumn get category => text()();
  // Attributs libres (taille, couleur, longueur, club, saison…), en JSON.
  TextColumn get attributes => text().withDefault(const Constant('{}'))();
  IntColumn get purchasePriceCents => integer().nullable()();
  IntColumn get salePriceCents => integer().nullable()();
  IntColumn get alertThreshold => integer().withDefault(const Constant(0))();
  TextColumn get barcode => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())();
  // Date du dernier envoi au serveur. À renvoyer si `updatedAt` est plus récent.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Journal des entrées et sorties. Le stock d'un produit = somme des `delta`.
class Movements extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get type => textEnum<MovementType>()();
  // Positif pour une entrée, négatif pour une sortie.
  IntColumn get delta => integer()();
  IntColumn get unitPriceCents => integer().nullable()();
  TextColumn get note => text().nullable()();
  // Pour une correction : le mouvement qu'elle annule.
  TextColumn get cancelsId => text().nullable().references(Movements, #id)();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  // Rempli quand le mouvement a été envoyé au serveur.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Petites valeurs persistantes (ex. où en est la synchronisation).
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Levée quand une sortie dépasse la quantité disponible.
class NotEnoughStock implements Exception {
  NotEnoughStock(this.available, this.requested);
  final int available;
  final int requested;

  @override
  String toString() => 'NotEnoughStock(available: $available, requested: $requested)';
}

/// Un produit et sa quantité en stock.
class StockLine {
  StockLine(this.product, this.quantity);
  final Product product;
  final int quantity;

  bool get isOut => quantity <= 0;
  bool get isLow => !isOut && quantity <= product.alertThreshold;
}

/// Sens des mouvements affichés dans l'historique.
enum MovementDirection { all, entries, exits }

/// Total des entrées et des sorties sur une période.
class MovementTotals {
  const MovementTotals({required this.entered, required this.removed});
  final int entered;
  final int removed;
}

/// Une ligne de l'historique : le mouvement, son produit, et s'il a été annulé.
class HistoryEntry {
  HistoryEntry(this.movement, this.product, {required this.cancelled});
  final Movement movement;
  final Product product;
  final bool cancelled;

  /// Une saisie normale encore valable, qu'on peut annuler.
  bool get canUndo => !cancelled && movement.type != MovementType.correction;
}

@DriftDatabase(tables: [Categories, Products, Movements, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor, this.defaultCategoryName = 'Autre'])
      : super(executor ?? driftDatabase(name: localName));

  /// Le stock enregistré sur l'appareil sous le fichier [name].
  AppDatabase.named(String name, {String defaultCategoryName = 'Autre'})
      : this(driftDatabase(name: name), defaultCategoryName);

  /// Fichier du stock sans compte (et des versions sans comptes séparés).
  static const localName = 'gestion_stock';

  /// Nom, dans la langue de l'appli, de la catégorie créée avec un nouveau stock.
  final String defaultCategoryName;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _insertCategories({Category.autre: defaultCategoryName});
        },
        onUpgrade: (m, from, to) async {
          // v2 : catégories modifiables. Les produits gardent leurs identifiants
          // (« meche », « maillot », « autre »), qui deviennent des lignes de Categories.
          if (from < 2) {
            await m.createTable(categories);
            await _insertCategories({
              Category.meche: 'Mèches',
              Category.maillot: 'Maillots',
              Category.autre: 'Autre',
            });
          }
        },
      );

  Future<void> _insertCategories(Map<String, String> names) async {
    // Date ancienne : un renommage fait sur un autre appareil l'emporte toujours.
    final epoch = DateTime.utc(2000);
    await batch((b) => b.insertAll(
          categories,
          [
            for (final MapEntry(key: id, value: name) in names.entries)
              CategoriesCompanion.insert(id: Value(id), name: name, updatedAt: Value(epoch)),
          ],
          mode: InsertMode.insertOrIgnore,
        ));
  }

  /// Catégories actives, par ordre alphabétique, mises à jour en direct.
  Stream<List<ProductCategory>> watchCategories() => (select(categories)
        ..where((c) => c.archived.equals(false))
        ..orderBy([(c) => OrderingTerm.asc(c.name.collate(Collate.noCase))]))
      .watch();

  Future<ProductCategory> addCategory(String name) =>
      into(categories).insertReturning(CategoriesCompanion.insert(name: name.trim()));

  Future<void> renameCategory(String id, String name) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(name: Value(name.trim()), updatedAt: Value(DateTime.now())),
      );

  /// Masque une catégorie. Ses produits restent visibles, sous « Sans catégorie ».
  Future<void> archiveCategory(String id) =>
      (update(categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(archived: const Value(true), updatedAt: Value(DateTime.now())),
      );

  /// Catégories modifiées ici depuis le dernier envoi au serveur.
  SimpleSelectStatement<$CategoriesTable, ProductCategory> pendingCategories() =>
      select(categories)
        ..where((c) => c.syncedAt.isNull() | c.updatedAt.isBiggerThan(c.syncedAt));

  Future<Product> addProduct({
    required String name,
    required String category,
    int alertThreshold = 0,
    int? purchasePriceCents,
    int? salePriceCents,
    String? barcode,
  }) {
    return into(products).insertReturning(ProductsCompanion.insert(
      name: name,
      category: category,
      alertThreshold: Value(alertThreshold),
      purchasePriceCents: Value(purchasePriceCents),
      salePriceCents: Value(salePriceCents),
      barcode: Value(barcode),
    ));
  }

  Future<void> updateProduct(Product product) {
    return update(products).replace(product.copyWith(updatedAt: DateTime.now()));
  }

  /// Masque un produit qu'on ne vend plus, sans perdre son historique.
  Future<void> archiveProduct(String productId) {
    return (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(archived: const Value(true), updatedAt: Value(DateTime.now())),
    );
  }

  /// Produits modifiés ici depuis le dernier envoi au serveur.
  SimpleSelectStatement<$ProductsTable, Product> pendingProducts() =>
      select(products)..where((p) => p.syncedAt.isNull() | p.updatedAt.isBiggerThan(p.syncedAt));

  /// Mouvements pas encore envoyés, du plus ancien au plus récent.
  SimpleSelectStatement<$MovementsTable, Movement> pendingMovements() => select(movements)
    ..where((m) => m.syncedAt.isNull())
    ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]);

  Future<bool> hasPendingChanges() async =>
      (await (pendingCategories()..limit(1)).get()).isNotEmpty ||
      (await (pendingProducts()..limit(1)).get()).isNotEmpty ||
      (await (pendingMovements()..limit(1)).get()).isNotEmpty;

  Future<String?> readSetting(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeSetting(String key, String value) {
    return into(settings).insertOnConflictUpdate(Setting(key: key, value: value));
  }

  Future<int> stockOf(String productId) async {
    final total = movements.delta.sum();
    final row = await (selectOnly(movements)
          ..addColumns([total])
          ..where(movements.productId.equals(productId)))
        .getSingle();
    return row.read(total) ?? 0;
  }

  /// Enregistre une arrivée de marchandise.
  Future<Movement> receive(String productId, int quantity, {int? unitPriceCents, String? note}) {
    _checkPositive(quantity);
    return _insertMovement(productId, MovementType.received, quantity, unitPriceCents, note);
  }

  /// Enregistre une vente. Refuse si le stock est insuffisant.
  Future<Movement> sell(String productId, int quantity, {int? unitPriceCents, String? note}) {
    return _takeOut(productId, MovementType.sold, quantity, unitPriceCents, note);
  }

  /// Enregistre une perte (casse, cadeau…). Refuse si le stock est insuffisant.
  Future<Movement> lose(String productId, int quantity, {String? note}) {
    return _takeOut(productId, MovementType.loss, quantity, null, note);
  }

  /// Annule un mouvement en ajoutant le mouvement inverse.
  Future<Movement> undo(String movementId) {
    return transaction(() async {
      final original =
          await (select(movements)..where((m) => m.id.equals(movementId))).getSingle();
      final alreadyCancelled = await (select(movements)
            ..where((m) => m.cancelsId.equals(movementId)))
          .getSingleOrNull();
      if (alreadyCancelled != null) {
        throw StateError('Mouvement déjà annulé');
      }
      // Annuler une réception déjà vendue ferait passer le stock sous zéro.
      if (original.delta > 0) {
        final available = await stockOf(original.productId);
        if (available < original.delta) throw NotEnoughStock(available, original.delta);
      }
      return into(movements).insertReturning(MovementsCompanion.insert(
        productId: original.productId,
        type: MovementType.correction,
        delta: -original.delta,
        cancelsId: Value(original.id),
      ));
    });
  }

  /// Historique des mouvements, du plus récent au plus ancien.
  ///
  /// [productId] limite à un produit, [since] aux mouvements à partir de cette date.
  Stream<List<HistoryEntry>> watchHistory({
    String? productId,
    DateTime? since,
    MovementDirection direction = MovementDirection.all,
    int limit = 500,
  }) {
    final cancellation = alias(movements, 'cancellation');
    final query = select(movements).join([
      innerJoin(products, products.id.equalsExp(movements.productId)),
      leftOuterJoin(cancellation, cancellation.cancelsId.equalsExp(movements.id)),
    ])
      ..orderBy([OrderingTerm.desc(movements.createdAt)])
      ..limit(limit);
    if (productId != null) query.where(movements.productId.equals(productId));
    if (since != null) query.where(movements.createdAt.isBiggerOrEqualValue(since));
    switch (direction) {
      case MovementDirection.all:
        break;
      case MovementDirection.entries:
        query.where(movements.type.equalsValue(MovementType.received));
      case MovementDirection.exits:
        query.where(movements.type.isInValues([MovementType.sold, MovementType.loss]));
    }
    return query.watch().map((rows) => [
          for (final row in rows)
            HistoryEntry(
              row.readTable(movements),
              row.readTable(products),
              cancelled: row.readTableOrNull(cancellation) != null,
            ),
        ]);
  }

  /// Quantités entrées et sorties, saisies annulées exclues, pour la période
  /// commençant à [since] (ou depuis toujours).
  Stream<MovementTotals> watchTotals({String? productId, DateTime? since}) {
    final m = alias(movements, 'm');
    final c = alias(movements, 'c');
    final entered = CaseWhenExpression<int>(
      cases: [CaseWhen(m.delta.isBiggerThanValue(0), then: m.delta)],
      orElse: const Constant(0),
    ).sum();
    final removed = CaseWhenExpression<int>(
      cases: [CaseWhen(m.delta.isSmallerThanValue(0), then: -m.delta)],
      orElse: const Constant(0),
    ).sum();
    final cancelled = existsQuery(select(c)..where((c) => c.cancelsId.equalsExp(m.id)));
    final query = selectOnly(m)
      ..addColumns([entered, removed])
      ..where(m.type.equalsValue(MovementType.correction).not() & cancelled.not());
    if (productId != null) query.where(m.productId.equals(productId));
    if (since != null) query.where(m.createdAt.isBiggerOrEqualValue(since));
    return query.watchSingle().map(
        (row) => MovementTotals(entered: row.read(entered) ?? 0, removed: row.read(removed) ?? 0));
  }

  /// Produits en rupture ou sous leur seuil : la liste « à recommander ».
  Stream<List<StockLine>> watchToReorder({String search = '', String? categoryId}) =>
      watchStock(search: search, categoryId: categoryId)
      .map((lines) => lines.where((l) => l.isOut || l.isLow).toList());

  /// Un produit et sa quantité, mis à jour en direct.
  Stream<StockLine> watchProduct(String productId) {
    final total = movements.delta.sum();
    final query = select(products).join([
      leftOuterJoin(movements, movements.productId.equalsExp(products.id)),
    ])
      ..addColumns([total])
      ..where(products.id.equals(productId))
      ..groupBy([products.id]);
    return query
        .watchSingle()
        .map((row) => StockLine(row.readTable(products), row.read(total) ?? 0));
  }

  /// Liste du stock, mise à jour en direct, produits archivés exclus.
  ///
  /// [search] filtre sur le nom ou le code-barres (majuscules ignorées).
  Stream<List<StockLine>> watchStock({String search = '', String? categoryId}) {
    final total = movements.delta.sum();
    final query = select(products).join([
      leftOuterJoin(movements, movements.productId.equalsExp(products.id)),
    ])
      ..addColumns([total])
      ..where(products.archived.equals(false))
      ..groupBy([products.id])
      ..orderBy([OrderingTerm.asc(products.name.collate(Collate.noCase))]);
    if (categoryId != null) query.where(products.category.equals(categoryId));
    final term = search.trim();
    if (term.isNotEmpty) {
      final pattern = '%${term.replaceAll('%', '').replaceAll('_', '')}%';
      query.where(products.name.like(pattern) | products.barcode.like(pattern));
    }
    return query.watch().map((rows) => [
          for (final row in rows) StockLine(row.readTable(products), row.read(total) ?? 0),
        ]);
  }

  Future<Movement> _takeOut(
      String productId, MovementType type, int quantity, int? unitPriceCents, String? note) {
    _checkPositive(quantity);
    return transaction(() async {
      final available = await stockOf(productId);
      if (quantity > available) throw NotEnoughStock(available, quantity);
      return _insertMovement(productId, type, -quantity, unitPriceCents, note);
    });
  }

  Future<Movement> _insertMovement(
      String productId, MovementType type, int delta, int? unitPriceCents, String? note) {
    return into(movements).insertReturning(MovementsCompanion.insert(
      productId: productId,
      type: type,
      delta: delta,
      unitPriceCents: Value(unitPriceCents),
      note: Value(note),
    ));
  }

  static void _checkPositive(int quantity) {
    if (quantity <= 0) throw ArgumentError.value(quantity, 'quantity', 'doit être positive');
  }
}
