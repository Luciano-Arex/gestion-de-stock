import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// Résumé d'une restauration.
class ImportResult {
  ImportResult(this.products, this.newMovements);
  final int products;
  final int newMovements;
}

/// Sauvegarde complète de la base dans un fichier JSON lisible.
///
/// La restauration fusionne : les produits sont mis à jour par identifiant,
/// les mouvements déjà présents sont ignorés. Restaurer deux fois le même
/// fichier ne double donc jamais le stock.
extension Backup on AppDatabase {
  static const format = 'gestion-stock';
  static const version = 1;

  Future<String> exportJson() async {
    final allProducts = await select(products).get();
    final allMovements = await (select(movements)
          ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
        .get();
    return const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'products': [for (final p in allProducts) p.toJson()],
      'movements': [for (final m in allMovements) m.toJson()],
    });
  }

  /// Lève [FormatException] si le fichier n'est pas une sauvegarde de l'appli.
  Future<ImportResult> importJson(String content) async {
    final Object? data;
    try {
      data = jsonDecode(content);
    } on FormatException {
      throw const FormatException('Fichier illisible');
    }
    if (data is! Map<String, dynamic> || data['format'] != format) {
      throw const FormatException('Ce fichier n\'est pas une sauvegarde de l\'appli');
    }
    if ((data['version'] as int? ?? 0) > version) {
      throw const FormatException('Sauvegarde faite avec une version plus récente de l\'appli');
    }
    final productRows = [
      // Les sauvegardes d'avant la suppression de produits n'ont pas « deleted ».
      for (final p in data['products'] as List)
        Product.fromJson({'deleted': false, ...p as Map<String, dynamic>}),
    ];
    final movementRows = [
      for (final m in data['movements'] as List) Movement.fromJson(m as Map<String, dynamic>),
    ];

    return transaction(() async {
      final before = await movements.count().getSingle();
      await batch((b) {
        b.insertAllOnConflictUpdate(products, productRows);
        b.insertAll(movements, movementRows, mode: InsertMode.insertOrIgnore);
      });
      final after = await movements.count().getSingle();
      return ImportResult(productRows.length, after - before);
    });
  }
}
