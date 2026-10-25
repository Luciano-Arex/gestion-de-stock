// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Mein Lager';

  @override
  String get received => 'Erhalten';

  @override
  String get receivedHint => 'Lieferung erfassen';

  @override
  String get sold => 'Verkauft';

  @override
  String get soldHint => 'Verkauf erfassen';

  @override
  String get myStock => 'Lager ansehen';

  @override
  String get stockEmpty => 'Noch keine Produkte.';

  @override
  String get noResult => 'Kein passendes Produkt.';

  @override
  String quantity(int count) {
    return '$count auf Lager';
  }

  @override
  String get outOfStock => 'Ausverkauft';

  @override
  String get lowStock => 'Nachbestellen';

  @override
  String get search => 'Produkt suchen';

  @override
  String get newProduct => 'Neues Produkt';

  @override
  String get editProduct => 'Produkt bearbeiten';

  @override
  String get productName => 'Produktname';

  @override
  String get productNameHelp => 'z. B. Kamerun Heimtrikot 2024, Größe M';

  @override
  String get productNameRequired => 'Bitte einen Namen eingeben.';

  @override
  String get category => 'Kategorie';

  @override
  String get alertThreshold => 'Warnen ab';

  @override
  String get alertThresholdHelp =>
      'Das Produkt erscheint unter „Nachbestellen“, wenn höchstens so viele übrig sind.';

  @override
  String get salePrice => 'Verkaufspreis (optional)';

  @override
  String get purchasePrice => 'Einkaufspreis (optional)';

  @override
  String get barcode => 'Barcode (optional)';

  @override
  String get save => 'Speichern';

  @override
  String get archive => 'Produkt nicht mehr verkaufen';

  @override
  String get archiveConfirm =>
      'Das Produkt wird ausgeblendet. Sein Verlauf bleibt erhalten.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get whichProduct => 'Welches Produkt?';

  @override
  String get howMany => 'Wie viele?';

  @override
  String get less => 'Eins weniger';

  @override
  String get more => 'Eins mehr';

  @override
  String get validate => 'Bestätigen';

  @override
  String get invalidQuantity => 'Bitte eine Zahl größer als 0 eingeben.';

  @override
  String notEnoughStock(int count) {
    return 'Nur noch $count da. Bitte die Menge prüfen.';
  }

  @override
  String receivedDone(int count, String name) {
    return '$count × $name zum Lager hinzugefügt';
  }

  @override
  String soldDone(int count, String name) {
    return '$count × $name aus dem Lager entnommen';
  }

  @override
  String get undo => 'Rückgängig';

  @override
  String get undone => 'Eintrag rückgängig gemacht';

  @override
  String get invalidPrice => 'Ungültiger Preis. z. B. 25 oder 25,50';

  @override
  String get backup => 'Sicherung';

  @override
  String get backupIntro =>
      'Eine Sicherung ist eine Datei mit allen Produkten und dem gesamten Verlauf. Bewahre sie auf einem USB-Stick oder in deinem Cloud-Speicher auf. Mach mindestens einmal pro Woche eine.';

  @override
  String get backupCreate => 'Sicherung erstellen';

  @override
  String get backupCreated => 'Sicherung gespeichert';

  @override
  String get backupRestore => 'Sicherung wiederherstellen';

  @override
  String get backupRestoreConfirm =>
      'Produkte und Einträge aus der Datei werden zu den vorhandenen hinzugefügt. Nichts wird gelöscht, und ein bereits vorhandener Eintrag wird nicht doppelt gezählt.';

  @override
  String backupRestored(int products, int movements) {
    return '$products Produkte und $movements neue Einträge wiederhergestellt';
  }

  @override
  String backupError(String reason) {
    return 'Diese Datei kann nicht gelesen werden: $reason';
  }

  @override
  String get sync => 'Synchronisierung';

  @override
  String get syncIntro =>
      'Melde dich auf Handy und PC mit demselben Konto an: Was du auf einem Gerät eingibst, erscheint auf dem anderen. Ohne Internet funktioniert die App weiter und holt alles nach, sobald die Verbindung zurück ist.';

  @override
  String get syncNotConfigured =>
      'Die Synchronisierung ist in dieser Version der App noch nicht aktiviert.';

  @override
  String get syncSignedOut => 'Nicht angemeldet';

  @override
  String get syncIdle => 'Aktuell';

  @override
  String get syncSyncing => 'Wird synchronisiert…';

  @override
  String get syncOffline => 'Offline, neuer Versuch gleich';

  @override
  String syncLast(String when) {
    return 'Letzte Synchronisierung: $when';
  }

  @override
  String syncAccount(String email) {
    return 'Konto: $email';
  }

  @override
  String get email => 'E-Mail-Adresse';

  @override
  String get password => 'Passwort';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signInError =>
      'Anmeldung abgelehnt. Bitte Adresse und Passwort prüfen.';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get history => 'Verlauf';

  @override
  String get historyEmpty => 'Keine Einträge in diesem Zeitraum.';

  @override
  String get periodToday => 'Heute';

  @override
  String get period7 => '7 Tage';

  @override
  String get period30 => '30 Tage';

  @override
  String get periodAll => 'Alle';

  @override
  String get typeReceived => 'Erhalten';

  @override
  String get typeSold => 'Verkauft';

  @override
  String get typeLoss => 'Verlust';

  @override
  String get typeCorrection => 'Storno';

  @override
  String get cancelled => 'Storniert';

  @override
  String get undoEntry => 'Diesen Eintrag stornieren';

  @override
  String get undoEntryConfirm =>
      'Die Menge wird wie vorher. Der Eintrag bleibt im Verlauf sichtbar, markiert als „Storniert“.';

  @override
  String get toReorder => 'Nachbestellen';

  @override
  String toReorderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Produkte nachbestellen',
      one: '1 Produkt nachbestellen',
    );
    return '$_temp0';
  }

  @override
  String get toReorderEmpty => 'Im Moment nichts nachzubestellen.';

  @override
  String undoNotEnough(int count) {
    return 'Stornieren nicht möglich: Ein Teil wurde schon verkauft (noch $count da).';
  }

  @override
  String get salePriceShort => 'Verkauf:';

  @override
  String get purchasePriceShort => 'Einkauf:';

  @override
  String get categories => 'Kategorien';

  @override
  String get newCategory => 'Neue Kategorie';

  @override
  String get renameCategory => 'Kategorie umbenennen';

  @override
  String get categoryName => 'Name der Kategorie';

  @override
  String get removeCategory => 'Kategorie entfernen';

  @override
  String removeCategoryConfirm(String name) {
    return '„$name“ wird nicht mehr angeboten. Die Produkte dieser Kategorie bleiben im Lager.';
  }

  @override
  String get allCategories => 'Alle';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'Wie auf dem Handy / PC';

  @override
  String get reports => 'Berichte';

  @override
  String get stockValue => 'Lagerwert';

  @override
  String get stockValueHelp => 'Menge × Einkaufspreis, für Produkte auf Lager.';

  @override
  String productsWithoutPrice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Produkte ohne Einkaufspreis werden nicht mitgezählt.',
      one: '1 Produkt ohne Einkaufspreis wird nicht mitgezählt.',
    );
    return '$_temp0';
  }

  @override
  String get salesSummary => 'Verkäufe';

  @override
  String get unitsSold => 'Verkaufte Artikel';

  @override
  String get revenue => 'Umsatz';

  @override
  String get margin => 'Marge';

  @override
  String get marginHelp =>
      'Preis jedes Verkaufs minus aktueller Einkaufspreis des Produkts. Verkäufe ohne Preis werden nicht mitgezählt.';

  @override
  String get bestSellers => 'Bestseller';

  @override
  String soldCount(int count) {
    return '$count verkauft';
  }

  @override
  String get noSales => 'Keine Verkäufe in diesem Zeitraum.';

  @override
  String get exportTitle => 'Excel-Export';

  @override
  String get exportIntro =>
      'Diese Dateien öffnen sich in Excel oder LibreOffice, zum Ansehen oder Drucken. Um Daten wieder in die App zu holen, nutze die Sicherung.';

  @override
  String get exportStock => 'Lager exportieren';

  @override
  String get exportHistory => 'Verlauf exportieren';

  @override
  String get exportDone => 'Datei gespeichert';

  @override
  String get colProduct => 'Produkt';

  @override
  String get colCategory => 'Kategorie';

  @override
  String get colQuantity => 'Menge';

  @override
  String get colThreshold => 'Warnschwelle';

  @override
  String get colPurchasePrice => 'Einkaufspreis';

  @override
  String get colSalePrice => 'Verkaufspreis';

  @override
  String get colBarcode => 'Barcode';

  @override
  String get colDate => 'Datum';

  @override
  String get colType => 'Art';

  @override
  String get colUnitPrice => 'Stückpreis';

  @override
  String get colCancelled => 'Storniert';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get pinTitle => 'PIN-Code';

  @override
  String get pinIntro =>
      'Die PIN wird bei jedem Öffnen der App abgefragt und nach einer Minute in einer anderen App. So kann niemand, der das Handy oder den PC nimmt, den Bestand sehen oder ändern.';

  @override
  String get pinCreate => 'PIN erstellen';

  @override
  String get pinChange => 'PIN ändern';

  @override
  String get pinRemove => 'PIN löschen';

  @override
  String get pinEnter => 'PIN eingeben';

  @override
  String get pinCurrent => 'Aktuelle PIN eingeben';

  @override
  String get pinNew => 'Code mit 4 bis 6 Ziffern wählen';

  @override
  String get pinConfirm => 'Denselben Code noch einmal eingeben';

  @override
  String get pinMismatch =>
      'Die beiden Codes stimmen nicht überein. Bitte noch einmal.';

  @override
  String get pinSaved => 'PIN gespeichert';

  @override
  String get pinRemoved => 'PIN gelöscht';

  @override
  String get pinWrong => 'Falscher Code';

  @override
  String pinWait(int seconds) {
    return 'Zu viele Versuche. In $seconds s erneut versuchen.';
  }

  @override
  String get pinErase => 'Löschen';

  @override
  String pinDigits(int count) {
    return '$count Ziffern eingegeben';
  }

  @override
  String get pinForgot => 'PIN vergessen?';

  @override
  String get pinForgotNoAccount =>
      'Ohne Sync-Konto kann die PIN hier nicht zurückgesetzt werden. Die App muss deinstalliert und neu installiert werden: Der lokale Bestand geht verloren, außer es gibt eine Sicherung.';

  @override
  String pinForgotWithAccount(String email) {
    return 'Passwort des Kontos $email eingeben, um die PIN zu löschen.';
  }
}
