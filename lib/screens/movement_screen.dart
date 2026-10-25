import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import 'product_form_screen.dart';
import 'stock_screen.dart';

enum MovementKind { receive, sell }

/// Résultat d'une saisie, pour proposer « Annuler » sur l'accueil.
class MovementResult {
  MovementResult(this.movement, this.product, this.quantity);
  final Movement movement;
  final Product product;
  final int quantity;
}

/// Saisie en deux temps : quel produit, puis combien.
class MovementScreen extends StatefulWidget {
  const MovementScreen({super.key, required this.db, required this.kind});

  final AppDatabase db;
  final MovementKind kind;

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  StockLine? _selected;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final title = widget.kind == MovementKind.receive ? t.received : t.sold;
    final selected = _selected;
    return PopScope(
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selected = null);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(selected == null ? '$title — ${t.whichProduct}' : title)),
        body: SafeArea(
          child: selected == null
              ? ProductSearchList(
                  db: widget.db,
                  autofocus: true,
                  onTap: (line) => setState(() => _selected = line),
                  // On ne crée un produit qu'à la réception : on ne vend pas ce qu'on n'a pas.
                  onCreate: widget.kind == MovementKind.receive ? _createProduct : null,
                )
              : _QuantityStep(
                  db: widget.db,
                  kind: widget.kind,
                  line: selected,
                ),
        ),
      ),
    );
  }

  Future<void> _createProduct(String name) async {
    final product = await Navigator.of(context).push<Product>(MaterialPageRoute(
      builder: (_) => ProductFormScreen(db: widget.db, initialName: name),
    ));
    if (product != null && mounted) setState(() => _selected = StockLine(product, 0));
  }
}

class _QuantityStep extends StatefulWidget {
  const _QuantityStep({required this.db, required this.kind, required this.line});

  final AppDatabase db;
  final MovementKind kind;
  final StockLine line;

  @override
  State<_QuantityStep> createState() => _QuantityStepState();
}

class _QuantityStepState extends State<_QuantityStep> {
  final _quantity = TextEditingController(text: '1');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_quantity.text) ?? 0;

  void _step(int delta) {
    final next = (_value + delta).clamp(1, 99999);
    setState(() {
      _quantity.text = '$next';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(widget.line.product.name, style: text.headlineSmall),
        const SizedBox(height: 4),
        Text(t.quantity(widget.line.quantity), style: text.bodyLarge),
        const SizedBox(height: 32),
        Text(t.howMany, style: text.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton.filledTonal(
              iconSize: 32,
              tooltip: t.less,
              onPressed: () => _step(-1),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _quantity,
                autofocus: true,
                textAlign: TextAlign.center,
                style: text.headlineMedium,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: t.howMany,
                  errorText: _error,
                  errorMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 16),
            IconButton.filledTonal(
              iconSize: 32,
              tooltip: t.more,
              onPressed: () => _step(1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 32),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
          onPressed: _saving ? null : _submit,
          child: Text(t.validate, style: text.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    final quantity = _value;
    if (quantity <= 0) {
      setState(() => _error = t.invalidQuantity);
      return;
    }
    setState(() => _saving = true);
    final product = widget.line.product;
    try {
      final movement = widget.kind == MovementKind.receive
          ? await widget.db.receive(product.id, quantity, unitPriceCents: product.purchasePriceCents)
          : await widget.db.sell(product.id, quantity, unitPriceCents: product.salePriceCents);
      if (mounted) Navigator.of(context).pop(MovementResult(movement, product, quantity));
    } on NotEnoughStock catch (e) {
      setState(() {
        _saving = false;
        _error = t.notEnoughStock(e.available);
      });
    }
  }
}
