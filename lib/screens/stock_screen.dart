import 'package:flutter/material.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import 'history_screen.dart';
import 'product_form_screen.dart';

/// Liste de tous les produits avec la quantité restante.
class StockScreen extends StatefulWidget {
  const StockScreen({super.key, required this.db, this.reorderOnly = false});

  final AppDatabase db;
  // N'affiche que les ruptures et les produits sous leur seuil.
  final bool reorderOnly;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  StockSort _sort = StockSort.name;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final db = widget.db;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reorderOnly ? t.toReorder : t.myStock),
        actions: [
          PopupMenuButton<StockSort>(
            tooltip: t.sortBy,
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              PopupMenuItem(value: StockSort.name, child: Text(t.sortName)),
              PopupMenuItem(value: StockSort.quantityAsc, child: Text(t.sortQuantityAsc)),
              PopupMenuItem(value: StockSort.quantityDesc, child: Text(t.sortQuantityDesc)),
            ],
          ),
          if (!widget.reorderOnly)
            IconButton(
              tooltip: t.archivedProducts,
              icon: const Icon(Icons.inventory_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ArchivedScreen(db: db)),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(t.newProduct),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductFormScreen(db: db)),
        ),
      ),
      body: ProductSearchList(
        db: db,
        reorderOnly: widget.reorderOnly,
        sort: _sort,
        onTap: (line) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HistoryScreen(db: db, product: line.product)),
        ),
      ),
    );
  }
}

/// Produits qu'on ne vend plus. Leur historique est gardé, on peut les remettre en vente.
class ArchivedScreen extends StatelessWidget {
  const ArchivedScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.archivedProducts)),
      body: StreamBuilder<List<StockLine>>(
        stream: db.watchArchived(),
        builder: (context, snapshot) {
          final lines = snapshot.data;
          if (lines == null) return const Center(child: CircularProgressIndicator());
          if (lines.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(t.archivedEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.separated(
            itemCount: lines.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final line = lines[i];
              return ListTile(
                minTileHeight: 64,
                title: Text(line.product.name),
                subtitle: Text([?line.product.color, t.quantity(line.quantity)].join(' · ')),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HistoryScreen(db: db, product: line.product),
                )),
                trailing: TextButton.icon(
                  icon: const Icon(Icons.unarchive_outlined),
                  label: Text(t.restore),
                  onPressed: () async {
                    await db.restoreProduct(line.product.id);
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                        SnackBar(content: Text(t.restored(line.product.name))));
                  },
                ),
              );
            },
          );
        },
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
    this.reorderOnly = false,
    this.sort = StockSort.name,
  });

  final AppDatabase db;
  final ValueChanged<StockLine> onTap;
  // Si fourni, propose « Nouveau produit » avec le texte cherché.
  final ValueChanged<String>? onCreate;
  final bool autofocus;
  final bool reorderOnly;
  final StockSort sort;

  @override
  State<ProductSearchList> createState() => _ProductSearchListState();
}

class _ProductSearchListState extends State<ProductSearchList> {
  final _search = TextEditingController();
  String? _categoryId;
  late Stream<List<StockLine>> _stream = _watch();

  Stream<List<StockLine>> _watch() {
    final search = _search.text;
    return widget.reorderOnly
        ? widget.db.watchToReorder(search: search, categoryId: _categoryId, sort: widget.sort)
        : widget.db.watchStock(search: search, categoryId: _categoryId, sort: widget.sort);
  }

  @override
  void didUpdateWidget(ProductSearchList old) {
    super.didUpdateWidget(old);
    if (old.sort != widget.sort) _stream = _watch();
  }

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
            ),
            onChanged: (text) => setState(() => _stream = _watch()),
          ),
        ),
        _CategoryFilter(
          db: widget.db,
          selected: _categoryId,
          onSelected: (id) => setState(() {
            _categoryId = id;
            _stream = _watch();
          }),
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
                  child: Text(_search.text.trim().isNotEmpty
                      ? t.noResult
                      : widget.reorderOnly
                          ? t.toReorderEmpty
                          : t.stockEmpty),
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

/// Puces « Toutes » et une par catégorie, pour filtrer la liste.
class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.db, required this.selected, required this.onSelected});

  final AppDatabase db;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return StreamBuilder<List<ProductCategory>>(
      stream: db.watchCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <ProductCategory>[];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              for (final (id, name) in [
                (null, t.allCategories),
                for (final c in categories) (c.id, c.name),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(name),
                    selected: selected == id,
                    onSelected: (_) => onSelected(id),
                  ),
                ),
            ],
          ),
        );
      },
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
      subtitle: Text([?line.product.color, t.quantity(line.quantity)].join(' · ')),
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
