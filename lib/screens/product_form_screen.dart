import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';
import '../util/money.dart';
import 'categories_screen.dart';

enum _DeleteChoice { archive, delete }

/// Demande confirmation, puis supprime (ou archive, au choix) le produit et
/// revient à l'écran principal, avec « Annuler » pendant quelques secondes.
Future<void> deleteProductWithConfirmation(
    BuildContext context, AppDatabase db, Product product) async {
  final t = AppLocalizations.of(context)!;
  final choice = await showDialog<_DeleteChoice>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.delete_outline),
      title: Text(t.deleteProductTitle(product.name)),
      content: Text(t.deleteProductConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        if (!product.archived)
          TextButton(
            onPressed: () => Navigator.pop(context, _DeleteChoice.archive),
            child: Text(t.archiveInstead),
          ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, _DeleteChoice.delete),
          child: Text(t.delete),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final deleting = choice == _DeleteChoice.delete;
  if (deleting) {
    await db.deleteProduct(product.id);
  } else {
    await db.archiveProduct(product.id);
  }
  // La fiche et le formulaire du produit n'ont plus de sens : retour à l'accueil.
  navigator.popUntil((route) => route.isFirst);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(deleting ? t.productDeleted(product.name) : t.productArchived(product.name)),
      duration: const Duration(seconds: 5),
      // Avec un bouton, Flutter garde le bandeau jusqu'à ce qu'on le ferme : on veut qu'il parte seul.
      persist: false,
      action: SnackBarAction(
        label: t.undo,
        onPressed: () =>
            deleting ? db.undeleteProduct(product.id) : db.restoreProduct(product.id),
      ),
    ));
}

/// Création ou modification d'un produit. Renvoie le produit enregistré.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    super.key,
    required this.db,
    this.product,
    this.initialName = '',
    this.askQuantity = true,
  });

  final AppDatabase db;
  final Product? product;
  final String initialName;
  // À la création : demander la quantité déjà en stock. Faux quand une
  // réception suit, qui demande elle-même la quantité.
  final bool askQuantity;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name ?? widget.initialName);
  late final _threshold =
      TextEditingController(text: (widget.product?.alertThreshold ?? 2).toString());
  late final _salePrice = TextEditingController(text: formatCents(widget.product?.salePriceCents));
  late final _purchasePrice =
      TextEditingController(text: formatCents(widget.product?.purchasePriceCents));
  late final _barcode = TextEditingController(text: widget.product?.barcode ?? '');
  late final _color = TextEditingController(text: widget.product?.color ?? '');
  final _colorFocus = FocusNode();
  // Couleurs déjà saisies sur d'autres produits, proposées en tapant.
  late final Future<List<String>> _knownColors = widget.db.knownColors();
  final _initialQuantity = TextEditingController(text: '0');
  late String _category = widget.product?.category ?? Category.autre;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _threshold, _salePrice, _purchasePrice, _barcode, _color]) {
      c.dispose();
    }
    _initialQuantity.dispose();
    _colorFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final existing = widget.product;
    return Scaffold(
      appBar: AppBar(title: Text(existing == null ? t.newProduct : t.editProduct)),
      // Toujours visible, même quand le clavier cache le bas du formulaire.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: _saving ? null : _save,
            child: Text(t.save),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                autofocus: existing == null && widget.initialName.isEmpty,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: t.productName,
                  helperText: t.productNameHelp,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? t.productNameRequired : null,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<String>>(
                future: _knownColors,
                builder: (context, snapshot) => Autocomplete<String>(
                  textEditingController: _color,
                  focusNode: _colorFocus,
                  optionsBuilder: (value) {
                    final typed = value.text.trim().toLowerCase();
                    return (snapshot.data ?? const <String>[]).where(
                        (c) => c.toLowerCase().contains(typed) && c.toLowerCase() != typed);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t.color,
                      helperText: t.colorHelp,
                      prefixIcon: const Icon(Icons.palette_outlined),
                    ),
                    onFieldSubmitted: (_) => onSubmitted(),
                  ),
                ),
              ),
              if (existing == null && widget.askQuantity) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _initialQuantity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: t.initialQuantity,
                    helperText: t.initialQuantityHelp,
                    helperMaxLines: 3,
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(t.category, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              StreamBuilder<List<ProductCategory>>(
                stream: widget.db.watchCategories(),
                builder: (context, snapshot) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in snapshot.data ?? const <ProductCategory>[])
                      ChoiceChip(
                        label: Text(c.name),
                        selected: c.id == _category,
                        onSelected: (_) => setState(() => _category = c.id),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add),
                      label: Text(t.newCategory),
                      onPressed: _createCategory,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _threshold,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: t.alertThreshold,
                  helperText: t.alertThresholdHelp,
                  helperMaxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
              _priceField(_salePrice, t.salePrice, t),
              const SizedBox(height: 16),
              _priceField(_purchasePrice, t.purchasePrice, t),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcode,
                decoration: InputDecoration(
                  labelText: t.barcode,
                ),
              ),
              if (existing != null) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  icon: const Icon(Icons.archive_outlined),
                  label: Text(t.archive),
                  onPressed: _saving ? null : _archive,
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(t.deleteProduct),
                  onPressed: _saving
                      ? null
                      : () => deleteProductWithConfirmation(context, widget.db, existing),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceField(TextEditingController controller, String label, AppLocalizations t) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        suffixText: '€',
      ),
      validator: (v) {
        try {
          parseCents(v ?? '');
          return null;
        } on FormatException {
          return t.invalidPrice;
        }
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final name = _name.text.trim();
    final threshold = int.tryParse(_threshold.text) ?? 0;
    final sale = parseCents(_salePrice.text);
    final purchase = parseCents(_purchasePrice.text);
    final barcode = _barcode.text.trim().isEmpty ? null : _barcode.text.trim();

    final existing = widget.product;
    final Product saved;
    if (existing == null) {
      saved = await widget.db.addProduct(
        name: name,
        category: _category,
        alertThreshold: threshold,
        salePriceCents: sale,
        purchasePriceCents: purchase,
        barcode: barcode,
        color: _color.text,
        initialQuantity: int.tryParse(_initialQuantity.text) ?? 0,
      );
    } else {
      saved = existing.copyWith(
        name: name,
        category: _category,
        alertThreshold: threshold,
        salePriceCents: Value(sale),
        purchasePriceCents: Value(purchase),
        barcode: Value(barcode),
        attributes: attributesWithColor(existing.attributes, _color.text),
      );
      await widget.db.updateProduct(saved);
    }
    if (mounted) Navigator.of(context).pop(saved);
  }

  Future<void> _createCategory() async {
    final name = await askCategoryName(context);
    if (name == null) return;
    final created = await widget.db.addCategory(name);
    if (mounted) setState(() => _category = created.id);
  }

  Future<void> _archive() async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.archive),
        content: Text(t.archiveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.confirm)),
        ],
      ),
    );
    if (ok != true) return;
    await widget.db.archiveProduct(widget.product!.id);
    if (mounted) Navigator.of(context).pop();
  }
}
