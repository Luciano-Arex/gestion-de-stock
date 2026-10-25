import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/database.dart';
import 'package:gestion_stock/data/pin_lock.dart';
import 'package:gestion_stock/main.dart';

import 'nav.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  Future<void> type(WidgetTester tester, String code) async {
    for (final d in code.split('')) {
      await tester.tap(find.widgetWithText(FilledButton, d));
      await tester.pump();
    }
    await tester.tap(find.byTooltip('Valider'));
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  testWidgets('créer un PIN dans les réglages, puis l\'appli le demande', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final pin = PinLock(db);

    await tester.pumpWidget(StockApp(db: db, pin: pin));
    await tester.pumpAndSettle();
    await openTab(tester, 'Réglages');
    await tester.tap(find.text('Code PIN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un code PIN'));
    await tester.pumpAndSettle();

    await type(tester, '2468');
    expect(find.text('Retapez le même code'), findsOneWidget);
    await type(tester, '1357');
    expect(find.text('Les deux codes ne sont pas pareils. Recommencez.'), findsOneWidget);
    await type(tester, '2468');
    await type(tester, '2468');
    expect(find.text('Code PIN enregistré'), findsOneWidget);
    expect(pin.enabled, isTrue);

    // L'appli se reverrouille : l'écran où on était reste derrière.
    pin.lock();
    await tester.pumpAndSettle();
    expect(find.text('Entrez votre code PIN'), findsOneWidget);
    expect(find.text('Changer le code PIN'), findsNothing);

    await type(tester, '1111');
    expect(find.text('Code incorrect'), findsOneWidget);
    await type(tester, '2468');
    expect(pin.locked, isFalse);
    expect(find.text('Changer le code PIN'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('supprimer le PIN demande d\'abord le code actuel', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final pin = PinLock(db);
    await tester.runAsync(() => pin.setPin('1234'));

    await tester.pumpWidget(StockApp(db: db, pin: pin));
    await tester.pumpAndSettle();
    await openTab(tester, 'Réglages');
    await tester.tap(find.text('Code PIN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer le code PIN'));
    await tester.pumpAndSettle();

    await type(tester, '9999');
    expect(find.text('Code incorrect'), findsOneWidget);
    expect(pin.enabled, isTrue);
    await type(tester, '1234');
    expect(find.text('Code PIN supprimé'), findsOneWidget);
    expect(pin.enabled, isFalse);

    await unmount(tester);
  });
}
