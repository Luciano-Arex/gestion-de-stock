import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import '../util/money.dart';
import 'product_form_screen.dart';

enum HistoryPeriod { today, week, month, all }

/// Journal des saisies, pour un produit ou pour tout le stock.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.db, this.product});

  final AppDatabase db;
  // Si présent, n'affiche que ce produit.
  final Product? product;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryPeriod _period = HistoryPeriod.month;
  late Stream<List<HistoryEntry>> _stream = _watch();

  Stream<List<HistoryEntry>> _watch() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final since = switch (_period) {
      HistoryPeriod.today => today,
      HistoryPeriod.week => today.subtract(const Duration(days: 6)),
      HistoryPeriod.month => today.subtract(const Duration(days: 29)),
      HistoryPeriod.all => null,
    };
    return widget.db.watchHistory(productId: widget.product?.id, since: since);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: Text(product == null ? t.history : product.name),
        actions: [
          if (product != null)
            IconButton(
              tooltip: t.editProduct,
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ProductFormScreen(db: widget.db, product: product),
              )),
            ),
        ],
      ),
      body: Column(
        children: [
          if (product != null) _ProductHeader(db: widget.db, productId: product.id),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<HistoryPeriod>(
              segments: [
                ButtonSegment(value: HistoryPeriod.today, label: Text(t.periodToday)),
                ButtonSegment(value: HistoryPeriod.week, label: Text(t.period7)),
                ButtonSegment(value: HistoryPeriod.month, label: Text(t.period30)),
                ButtonSegment(value: HistoryPeriod.all, label: Text(t.periodAll)),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() {
                _period = s.single;
                _stream = _watch();
              }),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<HistoryEntry>>(
              stream: _stream,
              builder: (context, snapshot) {
                final entries = snapshot.data;
                if (entries == null) return const Center(child: CircularProgressIndicator());
                if (entries.isEmpty) return Center(child: Text(t.historyEmpty));
                return ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _HistoryTile(
                    entry: entries[i],
                    showProduct: product == null,
                    onUndo: () => _undo(entries[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _undo(HistoryEntry entry) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.undoEntry),
        content: Text(t.undoEntryConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.confirm)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.db.undo(entry.movement.id);
      messenger.showSnackBar(SnackBar(content: Text(t.undone)));
    } on NotEnoughStock catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(t.undoNotEnough(e.available))));
    }
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.showProduct, required this.onUndo});

  final HistoryEntry entry;
  final bool showProduct;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final m = entry.movement;
    final (label, icon) = switch (m.type) {
      MovementType.received => (t.typeReceived, Icons.move_to_inbox),
      MovementType.sold => (t.typeSold, Icons.sell),
      MovementType.loss => (t.typeLoss, Icons.broken_image_outlined),
      MovementType.correction => (t.typeCorrection, Icons.undo),
    };
    final when = DateFormat.yMd(locale).add_Hm().format(m.createdAt);
    final quantity = m.delta > 0 ? '+${m.delta}' : '${m.delta}';
    final strike = entry.cancelled ? const TextStyle(decoration: TextDecoration.lineThrough) : null;
    return ListTile(
      minTileHeight: 64,
      leading: Icon(icon),
      title: Text(
        showProduct ? '$label · ${entry.product.name}' : label,
        style: strike,
      ),
      subtitle: Text(entry.cancelled ? '$when · ${t.cancelled}' : when),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(quantity, style: Theme.of(context).textTheme.titleMedium?.merge(strike)),
          if (entry.canUndo)
            IconButton(tooltip: t.undoEntry, icon: const Icon(Icons.undo), onPressed: onUndo),
        ],
      ),
    );
  }
}

/// Quantité en stock et prix du produit, en tête de son historique.
class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.db, required this.productId});

  final AppDatabase db;
  final String productId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<StockLine>(
      stream: db.watchProduct(productId),
      builder: (context, snapshot) {
        final line = snapshot.data;
        if (line == null) return const SizedBox(height: 96);
        final p = line.product;
        final status = line.isOut
            ? t.outOfStock
            : line.isLow
                ? t.lowStock
                : null;
        final prices = [
          if (p.salePriceCents != null) '${t.salePriceShort} ${formatCents(p.salePriceCents)} €',
          if (p.purchasePriceCents != null)
            '${t.purchasePriceShort} ${formatCents(p.purchasePriceCents)} €',
        ].join(' · ');
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.quantity(line.quantity), style: text.headlineMedium),
                if (status != null)
                  Row(
                    children: [
                      Icon(line.isOut ? Icons.error : Icons.warning_amber,
                          color: line.isOut ? scheme.error : scheme.tertiary),
                      const SizedBox(width: 8),
                      Text(status, style: text.titleMedium),
                    ],
                  ),
                if (prices.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(prices, style: text.bodyLarge),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
