import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/database.dart';
import 'data/locale_controller.dart';
import 'data/supabase_remote.dart';
import 'data/sync_controller.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  if (supabaseConfigured) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  }
  final db = AppDatabase();
  final locale = await LocaleController.load(db);
  runApp(StockApp(db: db, sync: SyncController(db), locale: locale));
}

class StockApp extends StatelessWidget {
  const StockApp({super.key, required this.db, this.sync, this.locale});

  final AppDatabase db;
  // Absent dans les tests : l'appli fonctionne alors uniquement en local.
  final SyncController? sync;
  // Absent dans les tests : l'interface est alors en français.
  final LocaleController? locale;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF00695C));
    final locale = this.locale;
    if (locale == null) return _app(scheme, const Locale('fr'));
    return ValueListenableBuilder<Locale?>(
      valueListenable: locale,
      builder: (context, value, _) => _app(scheme, value),
    );
  }

  Widget _app(ColorScheme scheme, Locale? locale) {
    return MaterialApp(
      locale: locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(colorScheme: scheme, visualDensity: VisualDensity.standard),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: Brightness.dark,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(db: db, sync: sync, locale: this.locale),
    );
  }
}
