import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/reports.dart';
import '../l10n/app_localizations.dart';
import '../util/money.dart';
import 'history_screen.dart' show HistoryPeriod, periodStart;

/// Valeur du stock et bilan des ventes sur une période.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  HistoryPeriod _period = HistoryPeriod.month;
  late final Stream<List<StockLine>> _stock = widget.db.watchStock();
  late Stream<List<HistoryEntry>> _history = _watchHistory();

  Stream<List<HistoryEntry>> _watchHistory() =>
      widget.db.watchHistory(since: periodStart(_period), limit: 1000000);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(t.reports)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<List<StockLine>>(
            stream: _stock,
            builder: (context, snapshot) {
              final value = StockValue.of(snapshot.data ?? const []);
              return _Figure(
                label: t.stockValue,
                value: '${formatCents(value.cents)} €',
                help: [
                  t.stockValueHelp,
                  if (value.productsWithoutPrice > 0) t.productsWithoutPrice(value.productsWithoutPrice),
                ].join(' '),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(t.salesSummary, style: text.titleLarge),
          const SizedBox(height: 8),
          SegmentedButton<HistoryPeriod>(
            segments: [
              ButtonSegment(value: HistoryPeriod.today, label: Text(t.periodToday)),
              ButtonSegment(value: HistoryPeriod.week, label: Text(t.period7)),
              ButtonSegment(value: HistoryPeriod.month, label: Text(t.period30)),
              ButtonSegment(value: HistoryPeriod.all, label: Text(t.periodAll)),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() {
              _period = s.single;
              _history = _watchHistory();
            }),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<HistoryEntry>>(
            stream: _history,
            builder: (context, snapshot) {
              final history = snapshot.data;
              if (history == null) return const Center(child: CircularProgressIndicator());
              final report = SalesReport.of(history);
              if (report.units == 0) return Text(t.noSales, style: text.bodyLarge);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Figure(label: t.unitsSold, value: '${report.units}'),
                  _Figure(label: t.revenue, value: '${formatCents(report.revenueCents)} €'),
                  _Figure(
                    label: t.margin,
                    value: '${formatCents(report.marginCents)} €',
                    help: t.marginHelp,
                  ),
                  const SizedBox(height: 16),
                  Text(t.bestSellers, style: text.titleLarge),
                  for (final s in report.byProduct.take(10))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.product.displayName),
                      trailing: Text(t.soldCount(s.units), style: text.titleMedium),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.help});

  final String label;
  final String value;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.titleMedium),
            Text(value, style: text.headlineMedium),
            if (help != null) ...[
              const SizedBox(height: 4),
              Text(help!, style: text.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
