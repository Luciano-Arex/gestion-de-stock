import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Langue choisie dans les réglages. null = langue du téléphone ou du PC.
///
/// Gardée sur l'appareil et non dans le stock : il faut la connaître dès la
/// page de connexion, avant d'ouvrir le stock d'un compte.
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController(super.initial, {this.save});

  // Enregistre le code de langue ('' = langue de l'appareil).
  final Future<void> Function(String code)? save;

  static const key = 'ui.locale';

  static Future<LocaleController> load(SharedPreferencesAsync prefs) async {
    final code = await prefs.getString(key);
    return LocaleController(
      code == null || code.isEmpty ? null : Locale(code),
      save: (code) => prefs.setString(key, code),
    );
  }

  Future<void> choose(Locale? locale) async {
    value = locale;
    await save?.call(locale?.languageCode ?? '');
  }
}
