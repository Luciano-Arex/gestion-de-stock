import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/database.dart';
import 'data/supabase_remote.dart';
import 'data/sync_controller.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr');
  if (supabaseConfigured) {
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  }
  final db = AppDatabase();
  runApp(StockApp(db: db, sync: SyncController(db)));
}

class StockApp extends StatelessWidget {
  const StockApp({super.key, required this.db, this.sync});

  final AppDatabase db;
  // Absent dans les tests : l'appli fonctionne alors uniquement en local.
  final SyncController? sync;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF00695C));
    return MaterialApp(
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
      home: HomeScreen(db: db, sync: sync),
    );
  }
}
