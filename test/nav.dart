import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ouvre un onglet, que la navigation soit en bas (téléphone) ou sur le côté (PC).
Future<void> openTab(WidgetTester tester, String label) async {
  final bar = find.byWidgetPredicate((w) => w is NavigationBar || w is NavigationRail);
  await tester.tap(find.descendant(of: bar, matching: find.text(label)));
  await tester.pumpAndSettle();
}
