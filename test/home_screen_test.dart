import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/database.dart';
import 'package:gestion_stock/main.dart';

import 'nav.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  // drift annule ses requêtes en direct avec un timer : on démonte l'appli
  // pour le laisser s'exécuter avant la fin du test.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  testWidgets('l\'accueil montre les deux actions principales', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();

    expect(find.text("J'ai reçu"), findsOneWidget);
    expect(find.text("J'ai vendu"), findsOneWidget);
    expect(find.text('Perte / sortie'), findsOneWidget);
    expect(find.text('Inventaire'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('les boutons respectent la taille tactile minimale', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await unmount(tester);
  });

  testWidgets('la liste du stock affiche une rupture en toutes lettres', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.addProduct(name: 'Closure 4x4', category: Category.meche);

    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();
    await openTab(tester, 'Stock');

    expect(find.text('Closure 4x4'), findsOneWidget);
    expect(find.text('Rupture'), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);

    await unmount(tester);
  });
}
