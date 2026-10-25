import 'database.dart';
import '../util/money.dart';

/// Fichiers CSV lisibles par Excel en français et en allemand :
/// séparateur point-virgule, décimales à virgule, BOM UTF-8 pour les accents.
class CsvTable {
  CsvTable(this.header, this.rows);

  final List<String> header;
  final List<List<String>> rows;

  String encode() {
    final buffer = StringBuffer('﻿');
    for (final row in [header, ...rows]) {
      buffer.write(row.map(_cell).join(';'));
      buffer.write('\r\n');
    }
    return buffer.toString();
  }

  static String _cell(String value) {
    // Une cellule qui commence par = + - @ serait lue comme une formule par Excel.
    final safe = RegExp(r'^[=+\-@]').hasMatch(value) && int.tryParse(value) == null
        ? "'$value"
        : value;
    if (safe.contains(RegExp('[;"\r\n]'))) return '"${safe.replaceAll('"', '""')}"';
    return safe;
  }
}

/// Libellés des colonnes, dans la langue de l'interface.
class CsvLabels {
  const CsvLabels({
    required this.product,
    required this.color,
    required this.category,
    required this.quantity,
    required this.threshold,
    required this.purchasePrice,
    required this.salePrice,
    required this.barcode,
    required this.date,
    required this.type,
    required this.unitPrice,
    required this.cancelled,
    required this.yes,
    required this.no,
    required this.typeName,
  });

  final String product, color, category, quantity, threshold, purchasePrice, salePrice, barcode;
  final String date, type, unitPrice, cancelled, yes, no;
  final String Function(MovementType) typeName;
}

CsvTable stockCsv(List<StockLine> lines, Map<String, String> categoryNames, CsvLabels l) {
  return CsvTable(
    [l.product, l.color, l.category, l.quantity, l.threshold, l.purchasePrice, l.salePrice, l.barcode],
    [
      for (final line in lines)
        [
          line.product.name,
          line.product.color ?? '',
          categoryNames[line.product.category] ?? '',
          '${line.quantity}',
          '${line.product.alertThreshold}',
          formatCents(line.product.purchasePriceCents),
          formatCents(line.product.salePriceCents),
          line.product.barcode ?? '',
        ],
    ],
  );
}

CsvTable historyCsv(List<HistoryEntry> entries, CsvLabels l) {
  String two(int n) => n.toString().padLeft(2, '0');
  String date(DateTime d) =>
      '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  return CsvTable(
    [l.date, l.product, l.type, l.quantity, l.unitPrice, l.cancelled],
    [
      for (final e in entries)
        [
          date(e.movement.createdAt),
          e.product.name,
          l.typeName(e.movement.type),
          '${e.movement.delta}',
          formatCents(e.movement.unitPriceCents),
          e.cancelled ? l.yes : l.no,
        ],
    ],
  );
}
