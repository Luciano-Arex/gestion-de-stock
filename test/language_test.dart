import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/database.dart';
import 'package:gestion_stock/data/locale_controller.dart';
import 'package:gestion_stock/main.dart';

import 'nav.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  testWidgets('choisir l\'allemand dans les réglages traduit l\'appli et s\'en souvient',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    String? saved;
    final locale = LocaleController(const Locale('fr'), save: (code) async => saved = code);

    await tester.pumpWidget(StockApp(db: db, locale: locale));
    await tester.pumpAndSettle();
    await openTab(tester, 'Réglages');
    await tester.tap(find.text('Langue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(find.text('Sprache'), findsOneWidget);
    await openTab(tester, 'Start');
    expect(find.text('Verkauft'), findsOneWidget);
    expect(saved, 'de');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  test('langue de l\'appareil non traduite : anglais', () {
    expect(resolveLocale(null, const [Locale('es')]), const Locale('en'));
    expect(resolveLocale(null, const [Locale('es'), Locale('de', 'AT')]), const Locale('de'));
    expect(resolveLocale(const Locale('fr'), const [Locale('de')]), const Locale('fr'));
  });
}
