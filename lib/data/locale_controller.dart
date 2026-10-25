import 'package:flutter/widgets.dart';

import 'database.dart';

/// Langue choisie dans les réglages. null = langue du téléphone ou du PC.
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController(this.db, super.initial);

  final AppDatabase db;
  static const key = 'ui.locale';

  static Future<LocaleController> load(AppDatabase db) async {
    final code = await db.readSetting(key);
    return LocaleController(db, code == null || code.isEmpty ? null : Locale(code));
  }

  Future<void> choose(Locale? locale) async {
    value = locale;
    await db.writeSetting(key, locale?.languageCode ?? '');
  }
}
