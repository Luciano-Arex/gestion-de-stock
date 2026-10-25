/// Convertit « 25 », « 25,5 » ou « 25.50 » en centimes. Vide → null.
///
/// Lève [FormatException] si le texte n'est pas un prix.
int? parseCents(String input) {
  final text = input.trim().replaceAll('€', '').replaceAll(' ', '').replaceAll(',', '.');
  if (text.isEmpty) return null;
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(text);
  if (match == null) throw FormatException('Prix non valide', input);
  final euros = int.parse(match.group(1)!);
  final cents = int.parse((match.group(2) ?? '0').padRight(2, '0'));
  return euros * 100 + cents;
}

/// Affiche des centimes à la française : 2550 → « 25,50 ». null → « ».
String formatCents(int? cents) {
  if (cents == null) return '';
  final euros = cents ~/ 100;
  final rest = (cents % 100).toString().padLeft(2, '0');
  return '$euros,$rest';
}
