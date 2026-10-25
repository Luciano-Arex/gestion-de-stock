import 'package:flutter/material.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';

/// Liste de tous les produits avec la quantité restante.
class StockScreen extends StatelessWidget {
  const StockScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.myStock)),
      body: StreamBuilder<List<StockLine>>(
        stream: db.watchStock(),
        builder: (context, snapshot) {
          final lines = snapshot.data;
          if (lines == null) return const Center(child: CircularProgressIndicator());
          if (lines.isEmpty) return Center(child: Text(t.stockEmpty));
          return ListView.separated(
            itemCount: lines.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _StockTile(line: lines[i]),
          );
        },
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.line});

  final StockLine line;

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
