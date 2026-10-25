import 'package:flutter/material.dart';

import '../data/database.dart';
import '../l10n/app_localizations.dart';

/// Demande un nom de catégorie. Renvoie null si l'utilisatrice annule.
Future<String?> askCategoryName(BuildContext context, {String initial = ''}) {
  final t = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) {
      void submit() {
        final name = controller.text.trim();
        if (name.isNotEmpty) Navigator.pop(context, name);
      }

      return AlertDialog(
        title: Text(initial.isEmpty ? t.newCategory : t.renameCategory),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: t.categoryName),
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          FilledButton(onPressed: submit, child: Text(t.save)),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}

/// Création, renommage et retrait des catégories.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.categories)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(t.newCategory),
        onPressed: () async {
          final name = await askCategoryName(context);
          if (name != null) await db.addCategory(name);
        },
      ),
      body: StreamBuilder<List<ProductCategory>>(
        stream: db.watchCategories(),
        builder: (context, snapshot) {
          final list = snapshot.data;
          if (list == null) return const Center(child: CircularProgressIndicator());
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = list[i];
              return ListTile(
                minTileHeight: 64,
                title: Text(c.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: t.renameCategory,
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final name = await askCategoryName(context, initial: c.name);
                        if (name != null) await db.renameCategory(c.id, name);
                      },
                    ),
                    IconButton(
                      tooltip: t.removeCategory,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _remove(context, c),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _remove(BuildContext context, ProductCategory c) async {
    final t = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.removeCategory),
        content: Text(t.removeCategoryConfirm(c.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.confirm)),
        ],
      ),
    );
    if (ok == true) await db.archiveCategory(c.id);
  }
}
