import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/util/money.dart';

void main() {
  test('lit les prix écrits à la française ou à l\'anglaise', () {
    expect(parseCents('25'), 2500);
    expect(parseCents('25,5'), 2550);
    expect(parseCents('25.50'), 2550);
    expect(parseCents(' 1 200,00 € '), 120000);
    expect(parseCents(''), isNull);
  });

  test('refuse ce qui n\'est pas un prix', () {
    expect(() => parseCents('abc'), throwsFormatException);
    expect(() => parseCents('-3'), throwsFormatException);
    expect(() => parseCents('2,555'), throwsFormatException);
  });

  test('affiche des centimes en euros', () {
    expect(formatCents(2550), '25,50');
    expect(formatCents(7), '0,07');
    expect(formatCents(null), '');
  });
}
