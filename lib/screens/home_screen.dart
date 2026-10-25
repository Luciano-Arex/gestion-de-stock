import 'package:flutter/material.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import 'stock_screen.dart';

/// Accueil : les deux actions du quotidien, en gros, et l'accès au stock.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.appTitle)),
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
                    onPressed: () => _comingSoon(context, t.received),
                  ),
                  const SizedBox(height: 24),
                  _BigAction(
                    icon: Icons.sell,
                    label: t.sold,
                    hint: t.soldHint,
                    onPressed: () => _comingSoon(context, t.sold),
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

  // Les écrans de saisie arrivent aux tâches 4 et 5 du plan.
  void _comingSoon(BuildContext context, String title) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(AppLocalizations.of(context)!.comingSoon)),
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
