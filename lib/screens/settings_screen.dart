import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/account.dart';
import '../data/csv_export.dart';
import '../data/database.dart';
import '../data/locale_controller.dart';
import '../data/pin_lock.dart';
import '../l10n/app_localizations.dart';
import 'backup_screen.dart';
import 'categories_screen.dart';
import 'pin_screen.dart';

/// Compte, langue, code PIN, catégories, sauvegarde et export.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.db, this.locale, this.pin, this.accounts});

  final AppDatabase db;
  final LocaleController? locale;
  final PinLock? pin;
  // Absent sans serveur : pas de compte.
  final AccountController? accounts;

  // Les langues gardent leur propre nom, pour qu'on retrouve la sienne.
  static const languages = {'fr': 'Français', 'en': 'English', 'de': 'Deutsch'};

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final current = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        children: [
          if (accounts case final accounts?)
            ListTile(
              minTileHeight: 64,
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(t.account),
              subtitle: Text(accounts.current?.email ?? ''),
              trailing: TextButton(
                onPressed: () => _signOut(context, accounts),
                child: Text(t.signOut),
              ),
            ),
          if (locale case final locale?)
            ListTile(
              minTileHeight: 64,
              leading: const Icon(Icons.language),
              title: Text(t.language),
              subtitle: Text(languages[current] ?? current),
              onTap: () => chooseLanguage(context, locale),
            ),
          if (pin case final pin?)
            ListenableBuilder(
              listenable: pin,
              builder: (context, _) => ListTile(
                minTileHeight: 64,
                leading: Icon(pin.enabled ? Icons.lock_outline : Icons.lock_open_outlined),
                title: Text(t.pinTitle),
                subtitle: Text(pin.enabled ? t.pinChange : t.pinCreate),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PinSettingsScreen(pin: pin)),
                ),
              ),
            ),
          ListTile(
            minTileHeight: 64,
            leading: const Icon(Icons.label_outline),
            title: Text(t.categories),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CategoriesScreen(db: db)),
            ),
          ),
          ListTile(
            minTileHeight: 64,
            leading: const Icon(Icons.save_outlined),
            title: Text(t.backup),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BackupScreen(db: db)),
            ),
          ),
          ListTile(
            minTileHeight: 64,
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(t.exportTitle),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExportScreen(db: db)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, AccountController accounts) async {
    final t = AppLocalizations.of(context)!;
    final pending = await db.hasPendingChanges();
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.signOut),
        content: Text(pending ? t.signOutPending : t.signOutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.signOut)),
        ],
      ),
    );
    if (ok == true) await accounts.auth.signOut();
  }
}

/// Choix de la langue, aussi proposé sur la page de connexion.
Future<void> chooseLanguage(BuildContext context, LocaleController locale) async {
  final t = AppLocalizations.of(context)!;
  const languages = SettingsScreen.languages;
  final chosen = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(t.language),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, ''),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(t.languageSystem),
          ),
        ),
        for (final MapEntry(:key, :value) in languages.entries)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, key),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(value),
            ),
          ),
      ],
    ),
  );
  if (chosen == null) return;
  await locale.choose(chosen.isEmpty ? null : Locale(chosen));
}

/// Export du stock et de l'historique en CSV pour Excel.
class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.exportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(t.exportIntro, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 32),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            icon: const Icon(Icons.inventory_2_outlined),
            label: Text(t.exportStock),
            onPressed: () => _export(context, stock: true),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            icon: const Icon(Icons.history),
            label: Text(t.exportHistory),
            onPressed: () => _export(context, stock: false),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, {required bool stock}) async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final labels = CsvLabels(
      product: t.colProduct,
      category: t.colCategory,
      quantity: t.colQuantity,
      threshold: t.colThreshold,
      purchasePrice: t.colPurchasePrice,
      salePrice: t.colSalePrice,
      barcode: t.colBarcode,
      date: t.colDate,
      type: t.colType,
      unitPrice: t.colUnitPrice,
      cancelled: t.colCancelled,
      yes: t.yes,
      no: t.no,
      typeName: (type) => switch (type) {
        MovementType.received => t.typeReceived,
        MovementType.sold => t.typeSold,
        MovementType.loss => t.typeLoss,
        MovementType.correction => t.typeCorrection,
      },
    );
    final CsvTable table;
    if (stock) {
      final categories = await db.select(db.categories).get();
      table = stockCsv(
        await db.watchStock().first,
        {for (final c in categories) c.id: c.name},
        labels,
      );
    } else {
      table = historyCsv(await db.watchHistory(limit: 1000000).first, labels);
    }
    final day = DateTime.now().toIso8601String().substring(0, 10);
    final name = stock ? 'stock-$day.csv' : 'historique-$day.csv';
    final saved = await FilePicker.saveFile(
      fileName: name,
      bytes: utf8.encode(table.encode()),
      mimeType: 'text/csv',
    );
    if (saved != null) messenger.showSnackBar(SnackBar(content: Text(t.exportDone)));
  }
}
