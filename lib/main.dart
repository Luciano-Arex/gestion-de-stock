import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/account.dart';
import 'data/database.dart';
import 'data/locale_controller.dart';
import 'data/pin_lock.dart';
import 'data/supabase_remote.dart';
import 'data/sync_controller.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pin_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final prefs = SharedPreferencesAsync();
  final locale = await LocaleController.load(prefs);

  if (!supabaseConfigured) {
    // Sans serveur : un seul stock, sur cet appareil, sans connexion.
    final db = AppDatabase();
    final pin = PinLock(db);
    await pin.load();
    runApp(StockApp(db: db, locale: locale, pin: pin));
    return;
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);
  final accounts = AccountController(
    SupabaseAuthGateway(Supabase.instance.client),
    openWorkspace: (userId, email) async {
      final name = await AccountController.databaseNameFor(userId, prefs);
      final t = lookupAppLocalizations(resolveLocale(locale.value));
      final db = AppDatabase.named(name, defaultCategoryName: t.defaultCategory);
      final pin = PinLock(db);
      await pin.load();
      return Workspace(userId: userId, email: email, db: db, pin: pin, sync: SyncController(db));
    },
  );
  await accounts.start();
  runApp(StockApp(accounts: accounts, locale: locale));
}

/// La langue de l'appli : celle choisie, sinon celle de l'appareil si elle est
/// traduite, sinon l'anglais.
Locale resolveLocale(Locale? chosen, [List<Locale>? device]) {
  final wanted = [?chosen, ...(device ?? PlatformDispatcher.instance.locales)];
  for (final l in wanted) {
    for (final s in AppLocalizations.supportedLocales) {
      if (s.languageCode == l.languageCode) return s;
    }
  }
  return const Locale('en');
}

class StockApp extends StatelessWidget {
  const StockApp({super.key, this.accounts, this.db, this.sync, this.locale, this.pin})
      : assert(accounts != null || db != null);

  /// Avec un serveur : connexion obligatoire, un stock par compte.
  final AccountController? accounts;

  /// Sans serveur (et dans les tests) : ce stock, sans connexion.
  final AppDatabase? db;
  final SyncController? sync;
  final PinLock? pin;

  // Absent dans les tests : l'interface est alors en français.
  final LocaleController? locale;

  @override
  Widget build(BuildContext context) {
    final locale = this.locale;
    if (locale == null) return _withAccount(const Locale('fr'));
    return ValueListenableBuilder<Locale?>(
      valueListenable: locale,
      builder: (context, value, _) => _withAccount(value),
    );
  }

  Widget _withAccount(Locale? locale) {
    final accounts = this.accounts;
    if (accounts == null) {
      return _app(locale, HomeScreen(db: db!, sync: sync, locale: this.locale, pin: pin), pin, sync);
    }
    return ListenableBuilder(
      listenable: accounts,
      builder: (context, _) {
        final w = accounts.current;
        final Widget home;
        if (w != null) {
          home = HomeScreen(
              db: w.db, sync: w.sync, locale: this.locale, pin: w.pin, accounts: accounts);
        } else if (accounts.opening) {
          home = const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else {
          home = LoginScreen(auth: accounts.auth, locale: this.locale);
        }
        // Changer de compte repart d'écrans neufs : rien de l'ancien compte ne reste ouvert.
        return _app(locale, home, w?.pin, w?.sync, key: ValueKey(w?.userId));
      },
    );
  }

  Widget _app(Locale? locale, Widget home, PinLock? pin, SyncController? sync, {Key? key}) {
    return MaterialApp(
      key: key,
      locale: locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (device, _) => resolveLocale(null, device),
      builder: (context, child) => switch (pin) {
        final pin? => PinGate(pin: pin, sync: sync, child: child!),
        null => child!,
      },
      home: home,
    );
  }
}
