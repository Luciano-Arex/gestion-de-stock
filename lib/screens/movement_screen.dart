import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import '../util/money.dart';
import 'product_form_screen.dart';
import 'stock_screen.dart';

/// Les saisies possibles : arrivage, vente, perte (casse, cadeau, usage perso)
/// et inventaire (on compte, l'appli corrige l'écart).
enum MovementKind { receive, sell, loss, count }

/// Résultat d'une saisie, pour proposer « Annuler » sur l'accueil.
///
/// [movement] est null pour un inventaire où le compte était déjà juste.
class MovementResult {
  MovementResult(this.movement, this.product, this.quantity);
  final Movement? movement;
  final Product product;
  final int quantity;
}

/// Titre d'une saisie, repris sur l'accueil et sur la fiche produit.
String movementTitle(AppLocalizations t, MovementKind kind) => switch (kind) {
      MovementKind.receive => t.received,
      MovementKind.sell => t.sold,
      MovementKind.loss => t.lost,
      MovementKind.count => t.stockCount,
    };

IconData movementIcon(MovementKind kind) => switch (kind) {
      MovementKind.receive => Icons.move_to_inbox,
      MovementKind.sell => Icons.sell,
      MovementKind.loss => Icons.remove_circle_outline,
      MovementKind.count => Icons.fact_check_outlined,
    };

/// Saisie en deux temps : quel produit, puis combien.
///
/// Avec [product], la saisie commence directement à la quantité.
class MovementScreen extends StatefulWidget {
  const MovementScreen({super.key, required this.db, required this.kind, this.product});

  final AppDatabase db;
  final MovementKind kind;
  final StockLine? product;

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  late StockLine? _selected = widget.product;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final title = movementTitle(t, widget.kind);
    final selected = _selected;
    return PopScope(
      // Retour depuis la quantité : on revient au choix du produit, sauf si
      // le produit était donné d'avance.
      canPop: selected == null || widget.product != null,
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
      // La quantité se saisit à l'étape suivante.
      builder: (_) => ProductFormScreen(db: widget.db, initialName: name, askQuantity: false),
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
  late final _quantity = TextEditingController(
      text: widget.kind == MovementKind.count ? '${widget.line.quantity.clamp(0, 99999)}' : '1');
  late final _price = TextEditingController(
    text: formatCents(switch (widget.kind) {
      MovementKind.receive => widget.line.product.purchasePriceCents,
      MovementKind.sell => widget.line.product.salePriceCents,
      _ => null,
    }),
  );
  final _note = TextEditingController();
  String? _error;
  String? _priceError;
  bool _saving = false;

  bool get _counting => widget.kind == MovementKind.count;
  bool get _hasPrice => widget.kind == MovementKind.receive || widget.kind == MovementKind.sell;

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_quantity.text) ?? 0;

  void _step(int delta) {
    final next = (_value + delta).clamp(_counting ? 0 : 1, 99999);
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
        Text(_counting ? t.countedQuestion : t.howMany, style: text.titleMedium),
        if (_counting) ...[
          const SizedBox(height: 4),
          Text(t.countHelp, style: text.bodyMedium),
        ],
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
                  labelText: _counting ? t.countedQuantity : t.howMany,
                  errorText: _error,
                  errorMaxLines: 3,
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
        if (_hasPrice) ...[
          const SizedBox(height: 24),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: t.unitPriceLabel,
              helperText: widget.kind == MovementKind.sell ? t.unitPriceSellHelp : null,
              suffixText: '€',
              errorText: _priceError,
            ),
            onChanged: (_) => setState(() => _priceError = null),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: t.noteLabel,
            helperText: widget.kind == MovementKind.loss ? t.lossNoteHelp : null,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
          onPressed: _saving ? null : _submit,
          child: Text(t.validate,
              style: text.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    final quantity = _value;
    if (quantity <= 0 && !(_counting && _quantity.text.isNotEmpty)) {
      setState(() => _error = t.invalidQuantity);
      return;
    }
    int? price;
    try {
      price = parseCents(_price.text);
    } on FormatException {
      setState(() => _priceError = t.invalidPrice);
      return;
    }
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    setState(() => _saving = true);
    final product = widget.line.product;
    final db = widget.db;
    try {
      final movement = switch (widget.kind) {
        MovementKind.receive => await db.receive(product.id, quantity, unitPriceCents: price, note: note),
        MovementKind.sell => await db.sell(product.id, quantity, unitPriceCents: price, note: note),
        MovementKind.loss => await db.lose(product.id, quantity, note: note),
        MovementKind.count => await db.adjustTo(product.id, quantity, note: note),
      };
      if (mounted) Navigator.of(context).pop(MovementResult(movement, product, quantity));
    } on NotEnoughStock catch (e) {
      setState(() {
        _saving = false;
        _error = t.notEnoughStock(e.available);
      });
    }
  }
}
