import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import '../util/money.dart';
import 'product_form_screen.dart';

enum HistoryPeriod { today, week, month, all }

/// Début de la période, ou null pour « Tout ».
DateTime? periodStart(HistoryPeriod period) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return switch (period) {
    HistoryPeriod.today => today,
    HistoryPeriod.week => today.subtract(const Duration(days: 6)),
    HistoryPeriod.month => today.subtract(const Duration(days: 29)),
    HistoryPeriod.all => null,
  };
}

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
  MovementDirection _direction = MovementDirection.all;
  late Stream<List<HistoryEntry>> _stream = _watch();
  late Stream<MovementTotals> _totals = _watchTotals();

  Stream<List<HistoryEntry>> _watch() => widget.db.watchHistory(
      productId: widget.product?.id, since: periodStart(_period), direction: _direction);

  Stream<MovementTotals> _watchTotals() =>
      widget.db.watchTotals(productId: widget.product?.id, since: periodStart(_period));

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
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() {
                _period = s.single;
                _stream = _watch();
                _totals = _watchTotals();
              }),
            ),
          ),
          _Totals(
            stream: _totals,
            direction: _direction,
            onDirection: (d) => setState(() {
              _direction = d;
              _stream = _watch();
            }),
          ),
          Expanded(
            child: StreamBuilder<List<HistoryEntry>>(
              stream: _stream,
              builder: (context, snapshot) {
                final entries = snapshot.data;
                if (entries == null) return const Center(child: CircularProgressIndicator());
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 48, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(height: 12),
                        Text(t.historyEmpty),
                      ],
                    ),
                  );
                }
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
    final details = [
      entry.cancelled ? '$when · ${t.cancelled}' : when,
      if (m.unitPriceCents != null) '${formatCents(m.unitPriceCents)} € / ${t.unit}',
      if (m.note case final note? when note.isNotEmpty) note,
    ];
    final quantity = m.delta > 0 ? '+${m.delta}' : '${m.delta}';
    final strike = entry.cancelled ? const TextStyle(decoration: TextDecoration.lineThrough) : null;
    return ListTile(
      minTileHeight: 64,
      leading: Icon(icon),
      title: Text(
        showProduct ? '$label · ${entry.product.name}' : label,
        style: strike,
      ),
      subtitle: Text(details.join('\n')),
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

/// Total des entrées et des sorties de la période. Un appui filtre la liste.
class _Totals extends StatelessWidget {
  const _Totals({required this.stream, required this.direction, required this.onDirection});

  final Stream<MovementTotals> stream;
  final MovementDirection direction;
  final ValueChanged<MovementDirection> onDirection;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return StreamBuilder<MovementTotals>(
      stream: stream,
      builder: (context, snapshot) {
        final totals = snapshot.data ?? const MovementTotals(entered: 0, removed: 0);
        Widget tile(MovementDirection d, IconData icon, String label, String value) {
          final selected = direction == d;
          return Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onDirection(selected ? MovementDirection.all : d),
                child: Semantics(
                  selected: selected,
                  button: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(icon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: Theme.of(context).textTheme.labelLarge),
                              Text(value, style: Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                        ),
                        if (selected) const Icon(Icons.filter_alt, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              tile(MovementDirection.entries, Icons.south_west, t.entries, '+${totals.entered}'),
              tile(MovementDirection.exits, Icons.north_east, t.exits, '−${totals.removed}'),
            ],
          ),
        );
      },
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
