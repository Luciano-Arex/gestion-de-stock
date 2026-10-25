import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/backup.dart';
import '../data/database.dart';
import '../l10n/app_localizations.dart';

/// Export et restauration de toute la base dans un fichier.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.backup)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(t.backupIntro, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              icon: const Icon(Icons.save_alt),
              label: Text(t.backupCreate),
              onPressed: _busy ? null : _export,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              icon: const Icon(Icons.restore),
              label: Text(t.backupRestore),
              onPressed: _busy ? null : _import,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export() async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final json = await widget.db.exportJson();
      final day = DateTime.now().toIso8601String().substring(0, 10);
      final saved = await FilePicker.saveFile(
        fileName: 'stock-$day.json',
        bytes: utf8.encode(json),
        mimeType: 'application/json',
      );
      if (saved != null) messenger.showSnackBar(SnackBar(content: Text(t.backupCreated)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (files.isEmpty || !mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.backupRestore),
        content: Text(t.backupRestoreConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.confirm)),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final content = await files.single.xFile.readAsString();
      final result = await widget.db.importJson(content);
      messenger.showSnackBar(
        SnackBar(content: Text(t.backupRestored(result.products, result.newMovements))),
      );
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(t.backupError(e.message))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
