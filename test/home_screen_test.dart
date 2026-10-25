import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/database.dart';
import 'package:gestion_stock/main.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  testWidgets('l\'accueil montre les deux actions principales', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();

    expect(find.text("J'ai reçu"), findsOneWidget);
    expect(find.text("J'ai vendu"), findsOneWidget);
    expect(find.text('Voir mon stock'), findsOneWidget);
  });

  testWidgets('les boutons respectent la taille tactile minimale', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('la liste du stock affiche une rupture en toutes lettres', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.addProduct(name: 'Closure 4x4', category: Category.meche);

    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir mon stock'));
    await tester.pumpAndSettle();

    expect(find.text('Closure 4x4'), findsOneWidget);
    expect(find.text('Rupture'), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);

    // drift annule ses requêtes en direct avec un timer : on démonte l'écran
    // pour le laisser s'exécuter avant la fin du test.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
