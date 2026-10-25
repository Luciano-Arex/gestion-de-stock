import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/account.dart';
import 'package:gestion_stock/data/database.dart';
import 'package:gestion_stock/data/pin_lock.dart';
import 'package:gestion_stock/main.dart';

import 'nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

/// Serveur de comptes simulé : adresse → mot de passe.
class FakeAuth implements AuthGateway {
  final accounts = <String, String>{};
  final _changes = StreamController<void>.broadcast();
  bool confirmEmail = false;
  String? _email;

  @override
  String? get userId => _email == null ? null : 'id-$_email';

  @override
  String? get email => _email;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> signIn(String email, String password) async {
    if (accounts[email.trim()] != password) {
      throw const AuthException('Invalid login credentials', code: 'invalid_credentials');
    }
    _email = email.trim();
    _changes.add(null);
  }

  @override
  Future<bool> signUp(String email, String password) async {
    if (accounts.containsKey(email.trim())) {
      throw const AuthException('User already registered', code: 'user_already_exists');
    }
    accounts[email.trim()] = password;
    if (confirmEmail) return false;
    await signIn(email, password);
    return true;
  }

  @override
  Future<void> sendResetCode(String email) async {}

  @override
  Future<void> resetPassword(String email, String code, String newPassword) async {
    if (code != '123456') throw const AuthException('expired', code: 'otp_expired');
    accounts[email.trim()] = newPassword;
    await signIn(email, newPassword);
  }

  @override
  Future<void> signOut() async {
    _email = null;
    _changes.add(null);
  }
}

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  // Un fichier de stock par compte, ici en mémoire.
  late Map<String, AppDatabase> files;
  late FakeAuth auth;
  late AccountController accounts;

  setUp(() {
    files = {};
    auth = FakeAuth();
    accounts = AccountController(auth, openWorkspace: (userId, email) async {
      final db = files.putIfAbsent(userId, () => _KeepOpen(NativeDatabase.memory()));
      return Workspace(userId: userId, email: email, db: db, pin: PinLock(db));
    });
  });
  tearDown(() async {
    for (final db in files.values) {
      await (db as _KeepOpen).reallyClose();
    }
  });

  test('chaque compte a son propre stock', () async {
    await accounts.start();
    expect(accounts.current, isNull);

    auth.accounts['awa@example.com'] = 'secret1';
    auth.accounts['ben@example.com'] = 'secret2';
    await auth.signIn('awa@example.com', 'secret1');
    await pumpEventQueue();
    final awa = accounts.current!;
    await awa.db.addProduct(name: 'Jus de bissap', category: Category.autre);

    await auth.signOut();
    await pumpEventQueue();
    expect(accounts.current, isNull);

    await auth.signIn('ben@example.com', 'secret2');
    await pumpEventQueue();
    expect(accounts.current!.email, 'ben@example.com');
    expect(await accounts.current!.db.watchStock().first, isEmpty);

    await auth.signOut();
    await auth.signIn('awa@example.com', 'secret1');
    await pumpEventQueue();
    expect((await accounts.current!.db.watchStock().first).single.product.name, 'Jus de bissap');
    accounts.dispose();
  });

  test('le premier compte reprend le stock déjà sur l\'appareil, pas les suivants', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = SharedPreferencesAsync();
    expect(await AccountController.databaseNameFor('a', prefs), AppDatabase.localName);
    expect(await AccountController.databaseNameFor('b', prefs), 'stock_b');
    expect(await AccountController.databaseNameFor('a', prefs), AppDatabase.localName);
  });

  group('page de connexion', () {
    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
      accounts.dispose();
    }

    // Écran de téléphone en hauteur, pour que tout le formulaire soit visible.
    setUp(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(1080, 2400);
      view.devicePixelRatio = 2.5;
    });
    tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.reset());

    Future<void> fill(WidgetTester tester, String label, String value) =>
        tester.enterText(find.widgetWithText(TextFormField, label), value);

    testWidgets('créer un compte ouvre un stock vide, se déconnecter revient à la connexion',
        (tester) async {
      await tester.runAsync(accounts.start);
      await tester.pumpWidget(StockApp(accounts: accounts));
      await tester.pumpAndSettle();
      expect(find.text('Votre stock, sur votre téléphone et votre PC.'), findsOneWidget);

      await tester.tap(find.text('Créer un compte').first);
      await tester.pumpAndSettle();
      await fill(tester, 'Adresse e-mail', 'awa@example.com');
      await fill(tester, 'Mot de passe', 'secret1');
      await fill(tester, 'Retapez le mot de passe', 'secret2');
      await tester.tap(find.widgetWithText(FilledButton, 'Créer un compte'));
      await tester.pumpAndSettle();
      expect(find.text('Les deux mots de passe ne sont pas pareils'), findsOneWidget);

      await fill(tester, 'Retapez le mot de passe', 'secret1');
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Créer un compte'));
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.text('J\'ai vendu'), findsOneWidget, reason: 'accueil du stock');
      expect(auth.accounts['awa@example.com'], 'secret1');

      await openTab(tester, 'Réglages');
      expect(find.text('awa@example.com'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Se déconnecter'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Se déconnecter'));
      await tester.pump();
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(find.text('Votre stock, sur votre téléphone et votre PC.'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('mauvais mot de passe : message clair', (tester) async {
      auth.accounts['awa@example.com'] = 'secret1';
      await tester.runAsync(accounts.start);
      await tester.pumpWidget(StockApp(accounts: accounts));
      await tester.pumpAndSettle();

      await fill(tester, 'Adresse e-mail', 'awa@example.com');
      await fill(tester, 'Mot de passe', 'faux');
      await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
      await tester.pumpAndSettle();
      expect(find.text('Adresse e-mail ou mot de passe incorrect'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('confirmation par e-mail demandée : on l\'explique', (tester) async {
      auth.confirmEmail = true;
      await tester.runAsync(accounts.start);
      await tester.pumpWidget(StockApp(accounts: accounts));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Créer un compte').first);
      await tester.pumpAndSettle();
      await fill(tester, 'Adresse e-mail', 'ben@example.com');
      await fill(tester, 'Mot de passe', 'secret1');
      await fill(tester, 'Retapez le mot de passe', 'secret1');
      await tester.tap(find.widgetWithText(FilledButton, 'Créer un compte'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ouvrez l\'e-mail envoyé à ben@example.com'), findsOneWidget);
      expect(accounts.current, isNull);

      await unmount(tester);
    });

    testWidgets('mot de passe oublié : le code permet d\'en choisir un nouveau', (tester) async {
      auth.accounts['awa@example.com'] = 'ancien';
      await tester.runAsync(accounts.start);
      await tester.pumpWidget(StockApp(accounts: accounts));
      await tester.pumpAndSettle();

      await fill(tester, 'Adresse e-mail', 'awa@example.com');
      await tester.tap(find.text('Mot de passe oublié ?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recevoir un code'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Un code a été envoyé à awa@example.com'), findsOneWidget);

      await fill(tester, 'Code reçu par e-mail', '000000');
      await fill(tester, 'Nouveau mot de passe', 'nouveau1');
      await tester.tap(find.text('Changer le mot de passe'));
      await tester.pumpAndSettle();
      expect(find.text('Code incorrect ou expiré'), findsOneWidget);

      await fill(tester, 'Code reçu par e-mail', '123456');
      await tester.runAsync(() async {
        await tester.tap(find.text('Changer le mot de passe'));
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.text('J\'ai vendu'), findsOneWidget);
      expect(auth.accounts['awa@example.com'], 'nouveau1');

      await unmount(tester);
    });
  });
}

/// Base en mémoire qui survit à la déconnexion, comme un fichier sur l'appareil.
class _KeepOpen extends AppDatabase {
  _KeepOpen(super.e);

  @override
  Future<void> close() async {}

  Future<void> reallyClose() => super.close();
}
