import 'package:flutter/material.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import 'product_form_screen.dart';

/// Liste de tous les produits avec la quantité restante.
class StockScreen extends StatelessWidget {
  const StockScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.myStock)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(t.newProduct),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductFormScreen(db: db)),
        ),
      ),
      body: ProductSearchList(
        db: db,
        onTap: (line) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductFormScreen(db: db, product: line.product)),
        ),
      ),
    );
  }
}

/// Champ de recherche + liste des produits avec leur stock.
///
/// Sert à la fois à consulter le stock et à choisir un produit lors d'une saisie.
class ProductSearchList extends StatefulWidget {
  const ProductSearchList({
    super.key,
    required this.db,
    required this.onTap,
    this.onCreate,
    this.autofocus = false,
  });

  final AppDatabase db;
  final ValueChanged<StockLine> onTap;
  // Si fourni, propose « Nouveau produit » avec le texte cherché.
  final ValueChanged<String>? onCreate;
  final bool autofocus;

  @override
  State<ProductSearchList> createState() => _ProductSearchListState();
}

class _ProductSearchListState extends State<ProductSearchList> {
  final _search = TextEditingController();
  late Stream<List<StockLine>> _stream = widget.db.watchStock();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            autofocus: widget.autofocus,
            decoration: InputDecoration(
              labelText: t.search,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (text) => setState(() => _stream = widget.db.watchStock(search: text)),
          ),
        ),
        if (widget.onCreate != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.add),
              label: Text(t.newProduct),
              onPressed: () => widget.onCreate!(_search.text.trim()),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<StockLine>>(
            stream: _stream,
            builder: (context, snapshot) {
              final lines = snapshot.data;
              if (lines == null) return const Center(child: CircularProgressIndicator());
              if (lines.isEmpty) {
                return Center(
                  child: Text(_search.text.trim().isEmpty ? t.stockEmpty : t.noResult),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: lines.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) =>
                    _StockTile(line: lines[i], onTap: () => widget.onTap(lines[i])),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.line, required this.onTap});

  final StockLine line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // Jamais la couleur seule : un mot et une icône accompagnent l'état.
    final (String? status, IconData? icon, Color? color) = line.isOut
        ? (t.outOfStock, Icons.error, scheme.error)
        : line.isLow
            ? (t.lowStock, Icons.warning_amber, scheme.tertiary)
            : (null, null, null);
    return ListTile(
      minTileHeight: 64,
      onTap: onTap,
      title: Text(line.product.name),
      subtitle: Text(t.quantity(line.quantity)),
      trailing: status == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
    );
  }
}
