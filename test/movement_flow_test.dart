import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/database.dart';
import 'package:gestion_stock/main.dart';

import 'nav.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  // drift annule ses requêtes en direct avec un timer : on démonte l'appli
  // pour le laisser s'exécuter avant la fin du test.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  Future<int> stockOf(WidgetTester tester, String name) async {
    final lines = await tester.runAsync(() => db.watchStock(search: name).first);
    return lines!.single.quantity;
  }

  testWidgets('réception d\'un nouveau produit, puis vente', (tester) async {
    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();

    // Réception : le produit n'existe pas, on le crée depuis la recherche.
    await tester.tap(find.text("J'ai reçu"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Closure 4x4');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouveau produit'));
    await tester.pumpAndSettle();
    expect(find.text('Closure 4x4'), findsOneWidget); // nom repris
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '5');
    await tester.ensureVisible(find.text('Valider'));
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('5 × Closure 4x4 ajouté au stock'), findsOneWidget);
    expect(await stockOf(tester, 'Closure'), 5);

    // Vente de 2 avec le bouton « Un de plus ».
    await tester.tap(find.text("J'ai vendu"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Closure 4x4'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Un de plus'));
    await tester.ensureVisible(find.text('Valider'));
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('2 × Closure 4x4 retiré du stock'), findsOneWidget);
    expect(await stockOf(tester, 'Closure'), 3);

    await unmount(tester);
  });

  testWidgets('vendre plus que le stock affiche un message clair', (tester) async {
    final p = await tester.runAsync(
      () => db.addProduct(name: 'Maillot PSG 2025 L', category: Category.maillot),
    );
    await tester.runAsync(() => db.receive(p!.id, 1));

    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text("J'ai vendu"));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau produit'), findsNothing);
    await tester.tap(find.text('Maillot PSG 2025 L'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '3');
    await tester.ensureVisible(find.text('Valider'));
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text("Il n'en reste que 1. Vérifie la quantité."), findsOneWidget);
    expect(await stockOf(tester, 'PSG'), 1);

    await unmount(tester);
  });

  testWidgets('le bouton Annuler défait la dernière saisie', (tester) async {
    final p = await tester.runAsync(
      () => db.addProduct(name: 'Tissage ondulé 20', category: Category.meche),
    );

    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();
    await tester.tap(find.text("J'ai reçu"));
    await tester.pumpAndSettle();
    await tester.tap(find.text(p!.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(await stockOf(tester, 'ondulé'), 1);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Saisie annulée'), findsOneWidget);
    expect(await stockOf(tester, 'ondulé'), 0);

    await unmount(tester);
  });

  testWidgets('créer un produit avec sa quantité, puis faire l\'inventaire depuis sa fiche',
      (tester) async {
    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();
    await openTab(tester, 'Stock');
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Nouveau produit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nom du produit'), 'Jus de bissap');
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantité déjà en stock'), '12');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(await stockOf(tester, 'bissap'), 12);

    await tester.tap(find.text('Jus de bissap'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Inventaire'));
    await tester.pumpAndSettle();
    expect(find.text('Combien en avez-vous compté ?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '10');
    await tester.ensureVisible(find.text('Valider'));
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    expect(find.text('Jus de bissap : stock corrigé à 10'), findsOneWidget);
    expect(await stockOf(tester, 'bissap'), 10);
    expect(find.text('-2'), findsOneWidget, reason: 'écart visible dans l\'historique');

    await unmount(tester);
  });
}
