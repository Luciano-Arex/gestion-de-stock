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

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  testWidgets('la fiche d\'un produit montre sa quantité et son historique', (tester) async {
    await tester.runAsync(() async {
      final p = await db.addProduct(name: 'Maillot Bayern 2025 M', category: Category.maillot);
      await db.receive(p.id, 4);
      await db.sell(p.id, 1);
    });

    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();
    await openTab(tester, 'Stock');
    await tester.tap(find.text('Maillot Bayern 2025 M'));
    await tester.pumpAndSettle();

    expect(find.text('3 en stock'), findsOneWidget);
    expect(find.text('Reçu'), findsOneWidget);
    expect(find.text('Vendu'), findsOneWidget);
    expect(find.text('+4'), findsNWidgets(2)); // la ligne et le total des entrées
    expect(find.text('-1'), findsOneWidget);
    expect(find.text('−1'), findsOneWidget); // total des sorties

    await unmount(tester);
  });

  testWidgets('l\'accueil signale les produits à recommander', (tester) async {
    await tester.runAsync(() async {
      final p = await db.addProduct(name: 'Closure', category: Category.meche, alertThreshold: 2);
      await db.receive(p.id, 1);
    });

    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();
    expect(find.text('1 produit à recommander'), findsOneWidget);

    await tester.tap(find.text('1 produit à recommander'));
    await tester.pumpAndSettle();
    expect(find.text('Closure'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('supprimer un produit depuis sa fiche, puis annuler', (tester) async {
    await tester.runAsync(() async {
      await db.addProduct(name: 'Jus gingembre', category: Category.autre, initialQuantity: 5);
    });

    await tester.pumpWidget(StockApp(db: db));
    await tester.pumpAndSettle();
    await openTab(tester, 'Stock');
    await tester.tap(find.text('Jus gingembre'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Supprimer le produit'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer Jus gingembre ?'), findsOneWidget);
    expect(find.text('Archiver plutôt'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();

    expect(find.text('Jus gingembre a été supprimé'), findsOneWidget);
    expect(find.text('Jus gingembre'), findsNothing);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Jus gingembre'), findsOneWidget);

    await unmount(tester);
  });
}
