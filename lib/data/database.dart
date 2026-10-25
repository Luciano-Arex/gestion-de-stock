import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';

const _uuid = Uuid();

/// Catégories de produits vendus. Stockées par leur nom.
enum Category { meche, maillot, autre }

/// Type d'un mouvement de stock.
///
/// `correction` sert uniquement à annuler un mouvement précédent :
/// un mouvement n'est jamais modifié ni supprimé.
enum MovementType { received, sold, loss, correction }

/// Une ligne = une combinaison précise (ex. « maillot Cameroun domicile 2024, taille M »).
class Products extends Table {
  TextColumn get id => text().clientDefault(() => _uuid.v4())();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get category => textEnum<Category>()();
  // Attributs libres (taille, couleur, longueur, club, saison…), en JSON.
  TextColumn get attributes => text().withDefault(const Constant('{}'))();
  IntColumn get purchasePriceCents => integer().nullable()();
  IntColumn get salePriceCents => integer().nullable()();
  IntColumn get alertThreshold => integer().withDefault(const Constant(0))();
  TextColumn get barcode => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())();

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
  // Rempli quand le mouvement a été envoyé au serveur (synchronisation, plus tard).
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
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

@DriftDatabase(tables: [Products, Movements])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openDefault() => driftDatabase(name: 'gestion_stock');

  Future<Product> addProduct({
    required String name,
    required Category category,
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
      return into(movements).insertReturning(MovementsCompanion.insert(
        productId: original.productId,
        type: MovementType.correction,
        delta: -original.delta,
        cancelsId: Value(original.id),
      ));
    });
  }

  /// Liste du stock, mise à jour en direct, produits archivés exclus.
  Stream<List<StockLine>> watchStock() {
    final total = movements.delta.sum();
    final query = select(products).join([
      leftOuterJoin(movements, movements.productId.equalsExp(products.id)),
    ])
      ..addColumns([total])
      ..where(products.archived.equals(false))
      ..groupBy([products.id])
      ..orderBy([OrderingTerm.asc(products.name)]);
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
