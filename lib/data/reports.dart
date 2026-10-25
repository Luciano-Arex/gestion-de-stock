import 'database.dart';

/// Valeur du stock au prix d'achat.
class StockValue {
  StockValue(this.cents, this.productsWithoutPrice);

  final int cents;
  // Produits en stock dont le prix d'achat n'est pas renseigné.
  final int productsWithoutPrice;

  factory StockValue.of(List<StockLine> lines) {
    var cents = 0;
    var missing = 0;
    for (final line in lines.where((l) => l.quantity > 0)) {
      final price = line.product.purchasePriceCents;
      if (price == null) {
        missing++;
      } else {
        cents += price * line.quantity;
      }
    }
    return StockValue(cents, missing);
  }
}

class ProductSales {
  ProductSales(this.product);
  final Product product;
  int units = 0;
  int revenueCents = 0;
}

/// Bilan des ventes d'une période, ventes annulées exclues.
class SalesReport {
  SalesReport._(this.byProduct, this.units, this.revenueCents, this.marginCents);

  /// Du produit le plus vendu au moins vendu.
  final List<ProductSales> byProduct;
  final int units;
  final int revenueCents;
  // Calculée seulement sur les ventes dont on connaît les deux prix.
  final int marginCents;

  factory SalesReport.of(List<HistoryEntry> history) {
    final byId = <String, ProductSales>{};
    var units = 0;
    var revenue = 0;
    var margin = 0;
    for (final entry in history) {
      final m = entry.movement;
      if (m.type != MovementType.sold || entry.cancelled) continue;
      final quantity = -m.delta;
      final sales = byId.putIfAbsent(entry.product.id, () => ProductSales(entry.product));
      sales.units += quantity;
      units += quantity;
      final price = m.unitPriceCents;
      if (price != null) {
        sales.revenueCents += price * quantity;
        revenue += price * quantity;
        final cost = entry.product.purchasePriceCents;
        if (cost != null) margin += (price - cost) * quantity;
      }
    }
    final ranked = byId.values.toList()
      ..sort((a, b) => b.units != a.units
          ? b.units.compareTo(a.units)
          : a.product.name.compareTo(b.product.name));
    return SalesReport._(ranked, units, revenue, margin);
  }
}
