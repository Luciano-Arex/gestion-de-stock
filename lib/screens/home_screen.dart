import 'package:flutter/material.dart';

import '../data/account.dart';
import '../data/database.dart';
import '../data/locale_controller.dart';
import '../data/pin_lock.dart';
import '../data/sync_controller.dart';
import '../l10n/app_localizations.dart';
import 'history_screen.dart';
import 'movement_screen.dart';
import 'product_form_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'stock_screen.dart';
import 'sync_screen.dart';

/// Ouvre une saisie, puis confirme avec un bouton « Annuler » pendant quelques secondes.
///
/// Avec [product], la saisie commence directement à la quantité.
Future<void> recordMovement(BuildContext context, AppDatabase db, MovementKind kind,
    {StockLine? product}) async {
  final t = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final result = await Navigator.of(context).push<MovementResult>(
    MaterialPageRoute(builder: (_) => MovementScreen(db: db, kind: kind, product: product)),
  );
  if (result == null) return;
  final name = result.product.name;
  final movement = result.movement;
  // Une seule confirmation à l'écran : la plus récente.
  messenger.hideCurrentSnackBar();
  if (movement == null) {
    messenger.showSnackBar(SnackBar(content: Text(t.countUnchanged(name))));
    return;
  }
  messenger.showSnackBar(SnackBar(
    duration: const Duration(seconds: 8),
    content: Text(switch (kind) {
      MovementKind.receive => t.receivedDone(result.quantity, name),
      MovementKind.sell => t.soldDone(result.quantity, name),
      MovementKind.loss => t.lossDone(result.quantity, name),
      MovementKind.count => t.countDone(result.quantity, name),
    }),
    action: SnackBarAction(
      label: t.undo,
      onPressed: () async {
        messenger.hideCurrentSnackBar();
        try {
          await db.undo(movement.id);
          messenger.showSnackBar(SnackBar(content: Text(t.undone)));
        } on NotEnoughStock catch (e) {
          messenger.showSnackBar(SnackBar(content: Text(t.undoNotEnough(e.available))));
        }
      },
    ),
  ));
}

/// Écran principal : une barre de navigation vers l'accueil, le stock,
/// l'historique, les rapports et les réglages. En bas sur un téléphone,
/// sur le côté sur un écran large (PC).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.db, this.sync, this.locale, this.pin, this.accounts});

  final AppDatabase db;
  final SyncController? sync;
  final LocaleController? locale;
  final PinLock? pin;
  final AccountController? accounts;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final db = widget.db;
    final destinations = [
      (Icons.home_outlined, Icons.home, t.navHome),
      (Icons.inventory_2_outlined, Icons.inventory_2, t.navStock),
      (Icons.history, Icons.history, t.history),
      (Icons.bar_chart_outlined, Icons.bar_chart, t.reports),
      (Icons.settings_outlined, Icons.settings, t.settings),
    ];
    final pages = [
      _Dashboard(db: db, sync: widget.sync, onOpenTab: (i) => setState(() => _tab = i)),
      StockScreen(db: db),
      HistoryScreen(db: db),
      ReportsScreen(db: db),
      SettingsScreen(db: db, locale: widget.locale, pin: widget.pin, accounts: widget.accounts),
    ];
    // Chaque onglet garde son état (recherche, filtres) quand on change d'onglet.
    final body = IndexedStack(
      index: _tab,
      children: [
        for (var i = 0; i < pages.length; i++) TickerMode(enabled: i == _tab, child: pages[i]),
      ],
    );
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              labelType: NavigationRailLabelType.all,
              groupAlignment: -0.8,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Icon(Icons.inventory_2, size: 32, color: Theme.of(context).colorScheme.primary),
              ),
              destinations: [
                for (final (icon, selected, label) in destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: Text(label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          for (final (icon, selected, label) in destinations)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
        ],
      ),
    );
  }
}

/// Accueil : les chiffres du jour et les saisies du quotidien, en gros.
class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.db, required this.onOpenTab, this.sync});

  final AppDatabase db;
  final SyncController? sync;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          if (sync case final sync?)
            ListenableBuilder(
              listenable: sync,
              builder: (context, _) => IconButton(
                tooltip: t.sync,
                icon: Icon(switch (sync.status) {
                  SyncStatus.idle => Icons.cloud_done_outlined,
                  SyncStatus.syncing => Icons.sync,
                  _ => Icons.cloud_off_outlined,
                }),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SyncScreen(sync: sync)),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Summary(db: db, onTap: () => onOpenTab(1)),
                  const SizedBox(height: 24),
                  _ReorderBanner(db: db),
                  _BigAction(
                    icon: movementIcon(MovementKind.receive),
                    label: t.received,
                    hint: t.receivedHint,
                    onPressed: () => _record(context, MovementKind.receive),
                  ),
                  const SizedBox(height: 16),
                  _BigAction(
                    icon: movementIcon(MovementKind.sell),
                    label: t.sold,
                    hint: t.soldHint,
                    onPressed: () => _record(context, MovementKind.sell),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final kind in [MovementKind.loss, MovementKind.count]) ...[
                        if (kind == MovementKind.count) const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                            icon: Icon(movementIcon(kind)),
                            label: Text(movementTitle(t, kind), textAlign: TextAlign.center),
                            onPressed: () => _record(context, kind),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(t.newProduct),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ProductFormScreen(db: db)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _record(BuildContext context, MovementKind kind) =>
      recordMovement(context, db, kind);
}

class _BigAction extends StatelessWidget {
  const _BigAction({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      hint: hint,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(96),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                label,
                style: text.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chiffres du jour en un coup d'œil : articles, pièces en stock, entrées et sorties.
class _Summary extends StatelessWidget {
  const _Summary({required this.db, required this.onTap});

  final AppDatabase db;
  // Ouvre l'onglet Stock.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();
    return StreamBuilder<List<StockLine>>(
      stream: db.watchStock(),
      builder: (context, stock) => StreamBuilder<MovementTotals>(
        stream: db.watchTotals(since: DateTime(now.year, now.month, now.day)),
        builder: (context, today) {
          final lines = stock.data ?? const <StockLine>[];
          final pieces = lines.fold<int>(0, (sum, l) => sum + (l.quantity > 0 ? l.quantity : 0));
          return Card(
            clipBehavior: Clip.antiAlias,
            child: MergeSemantics(
              child: InkWell(
              onTap: onTap,
              child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Row(
                children: [
                  _Figure(value: '${lines.length}', label: t.summaryProducts),
                  _Figure(value: '$pieces', label: t.summaryPieces),
                  _Figure(value: _signed(today.data?.entered ?? 0, '+'), label: t.summaryInToday),
                  _Figure(value: _signed(today.data?.removed ?? 0, '−'), label: t.summaryOutToday),
                ],
              ),
            ),
            ),
            ),
          );
        },
      ),
    );
  }
}

String _signed(int n, String sign) => n == 0 ? '0' : '$sign$n';

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(label, style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Bandeau visible seulement quand des produits sont sous leur seuil.
class _ReorderBanner extends StatelessWidget {
  const _ReorderBanner({required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return StreamBuilder<List<StockLine>>(
      stream: db.watchToReorder(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Card(
            color: scheme.tertiaryContainer,
            child: ListTile(
              minTileHeight: 64,
              leading: Icon(Icons.warning_amber, color: scheme.onTertiaryContainer),
              title: Text(
                t.toReorderCount(count),
                style: TextStyle(color: scheme.onTertiaryContainer, fontWeight: FontWeight.bold),
              ),
              trailing: Icon(Icons.chevron_right, color: scheme.onTertiaryContainer),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StockScreen(db: db, reorderOnly: true),
              )),
            ),
          ),
        );
      },
    );
  }
}
