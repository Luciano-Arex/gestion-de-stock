import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/database.dart';
import 'package:gestion_stock/data/locale_controller.dart';
import 'package:gestion_stock/main.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  testWidgets('choisir l\'allemand dans les réglages traduit l\'appli et s\'en souvient',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final locale = LocaleController(db, const Locale('fr'));

    await tester.pumpWidget(StockApp(db: db, locale: locale));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Réglages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Langue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(find.text('Sprache'), findsOneWidget);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('Verkauft'), findsOneWidget);
    expect(await tester.runAsync(() => db.readSetting(LocaleController.key)), 'de');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
