import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/sync_controller.dart';
import '../l10n/app_localizations.dart';
import 'backup_screen.dart';
import 'movement_screen.dart';
import 'stock_screen.dart';
import 'sync_screen.dart';

/// Accueil : les deux actions du quotidien, en gros, et l'accès au stock.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.db, this.sync});

  final AppDatabase db;
  final SyncController? sync;

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
          IconButton(
            tooltip: t.backup,
            icon: const Icon(Icons.save_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BackupScreen(db: db)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BigAction(
                    icon: Icons.move_to_inbox,
                    label: t.received,
                    hint: t.receivedHint,
                    onPressed: () => _record(context, MovementKind.receive),
                  ),
                  const SizedBox(height: 24),
                  _BigAction(
                    icon: Icons.sell,
                    label: t.sold,
                    hint: t.soldHint,
                    onPressed: () => _record(context, MovementKind.sell),
                  ),
                  const SizedBox(height: 40),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                    icon: const Icon(Icons.inventory_2),
                    label: Text(t.myStock),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => StockScreen(db: db)),
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

  /// Ouvre la saisie, puis confirme avec un bouton « Annuler » pendant quelques secondes.
  Future<void> _record(BuildContext context, MovementKind kind) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<MovementResult>(
      MaterialPageRoute(builder: (_) => MovementScreen(db: db, kind: kind)),
    );
    if (result == null) return;
    final name = result.product.name;
    // Une seule confirmation à l'écran : la plus récente.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      content: Text(kind == MovementKind.receive
          ? t.receivedDone(result.quantity, name)
          : t.soldDone(result.quantity, name)),
      action: SnackBarAction(
        label: t.undo,
        onPressed: () async {
          await db.undo(result.movement.id);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(SnackBar(content: Text(t.undone)));
        },
      ),
    ));
  }
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
