// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My stock';

  @override
  String get received => 'I received';

  @override
  String get receivedHint => 'Record a delivery';

  @override
  String get sold => 'I sold';

  @override
  String get soldHint => 'Record a sale';

  @override
  String get myStock => 'View my stock';

  @override
  String get stockEmpty => 'No products yet.';

  @override
  String get noResult => 'No matching product.';

  @override
  String quantity(int count) {
    return '$count in stock';
  }

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get lowStock => 'To reorder';

  @override
  String get search => 'Search for a product';

  @override
  String get newProduct => 'New product';

  @override
  String get editProduct => 'Edit product';

  @override
  String get productName => 'Product name';

  @override
  String get productNameHelp => 'E.g. Cameroon home jersey 2024, size M';

  @override
  String get productNameRequired => 'Enter a name.';

  @override
  String get category => 'Category';

  @override
  String get alertThreshold => 'Warn me at';

  @override
  String get alertThresholdHelp =>
      'The product shows as “To reorder” when this many or fewer are left.';

  @override
  String get salePrice => 'Sale price (optional)';

  @override
  String get purchasePrice => 'Purchase price (optional)';

  @override
  String get barcode => 'Barcode (optional)';

  @override
  String get save => 'Save';

  @override
  String get archive => 'Stop selling this product';

  @override
  String get archiveConfirm =>
      'The product will be hidden. Its history is kept.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get whichProduct => 'Which product?';

  @override
  String get howMany => 'How many?';

  @override
  String get less => 'One less';

  @override
  String get more => 'One more';

  @override
  String get validate => 'Confirm';

  @override
  String get invalidQuantity => 'Enter a number greater than 0.';

  @override
  String notEnoughStock(int count) {
    return 'Only $count left. Check the quantity.';
  }

  @override
  String receivedDone(int count, String name) {
    return '$count × $name added to stock';
  }

  @override
  String soldDone(int count, String name) {
    return '$count × $name removed from stock';
  }

  @override
  String get undo => 'Undo';

  @override
  String get undone => 'Entry undone';

  @override
  String get invalidPrice => 'Invalid price. E.g. 25 or 25.50';

  @override
  String get backup => 'Backup';

  @override
  String get backupIntro =>
      'A backup is a file with all your products and the full history. Keep it on a USB stick or in your cloud storage. Make one at least once a week.';

  @override
  String get backupCreate => 'Create a backup';

  @override
  String get backupCreated => 'Backup saved';

  @override
  String get backupRestore => 'Restore a backup';

  @override
  String get backupRestoreConfirm =>
      'Products and entries from the file will be added to the ones already here. Nothing is deleted, and an entry already present is not counted twice.';

  @override
  String backupRestored(int products, int movements) {
    return '$products products and $movements new entries restored';
  }

  @override
  String backupError(String reason) {
    return 'Cannot read this file: $reason';
  }

  @override
  String get sync => 'Sync';

  @override
  String get syncIntro =>
      'Sign in to the same account on the phone and the PC: what you enter on one shows up on the other. Without internet, the app keeps working and catches up once the connection is back.';

  @override
  String get syncNotConfigured =>
      'Sync is not enabled in this version of the app yet.';

  @override
  String get syncSignedOut => 'Not signed in';

  @override
  String get syncIdle => 'Up to date';

  @override
  String get syncSyncing => 'Syncing…';

  @override
  String get syncOffline => 'Offline, retrying soon';

  @override
  String syncLast(String when) {
    return 'Last sync: $when';
  }

  @override
  String syncAccount(String email) {
    return 'Account: $email';
  }

  @override
  String get email => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signInError => 'Sign-in refused. Check the address and password.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get history => 'History';

  @override
  String get historyEmpty => 'No entries in this period.';

  @override
  String get periodToday => 'Today';

  @override
  String get period7 => '7 days';

  @override
  String get period30 => '30 days';

  @override
  String get periodAll => 'All';

  @override
  String get typeReceived => 'Received';

  @override
  String get typeSold => 'Sold';

  @override
  String get typeLoss => 'Loss';

  @override
  String get typeCorrection => 'Undo';

  @override
  String get cancelled => 'Undone';

  @override
  String get undoEntry => 'Undo this entry';

  @override
  String get undoEntryConfirm =>
      'The quantity goes back to what it was. The entry stays in the history, marked “Undone”.';

  @override
  String get toReorder => 'To reorder';

  @override
  String toReorderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products to reorder',
      one: '1 product to reorder',
    );
    return '$_temp0';
  }

  @override
  String get toReorderEmpty => 'Nothing to reorder right now.';

  @override
  String undoNotEnough(int count) {
    return 'Cannot undo: some of it has already been sold ($count left).';
  }

  @override
  String get salePriceShort => 'Sale:';

  @override
  String get purchasePriceShort => 'Purchase:';

  @override
  String get categories => 'Categories';

  @override
  String get newCategory => 'New category';

  @override
  String get renameCategory => 'Rename category';

  @override
  String get categoryName => 'Category name';

  @override
  String get removeCategory => 'Remove category';

  @override
  String removeCategoryConfirm(String name) {
    return '“$name” will no longer be offered. Its products stay in stock.';
  }

  @override
  String get allCategories => 'All';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Same as the phone / PC';

  @override
  String get reports => 'Reports';

  @override
  String get stockValue => 'Stock value';

  @override
  String get stockValueHelp =>
      'Quantity × purchase price, for products in stock.';

  @override
  String productsWithoutPrice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products without a purchase price are not counted.',
      one: '1 product without a purchase price is not counted.',
    );
    return '$_temp0';
  }

  @override
  String get salesSummary => 'Sales';

  @override
  String get unitsSold => 'Items sold';

  @override
  String get revenue => 'Revenue';

  @override
  String get margin => 'Margin';

  @override
  String get marginHelp =>
      'Price of each sale minus the product\'s current purchase price. Sales without a price are not counted.';

  @override
  String get bestSellers => 'Best sellers';

  @override
  String soldCount(int count) {
    return '$count sold';
  }

  @override
  String get noSales => 'No sales in this period.';

  @override
  String get exportTitle => 'Excel export';

  @override
  String get exportIntro =>
      'These files open in Excel or LibreOffice, to view or print. To put data back into the app, use the backup.';

  @override
  String get exportStock => 'Export stock';

  @override
  String get exportHistory => 'Export history';

  @override
  String get exportDone => 'File saved';

  @override
  String get colProduct => 'Product';

  @override
  String get colCategory => 'Category';

  @override
  String get colQuantity => 'Quantity';

  @override
  String get colThreshold => 'Alert threshold';

  @override
  String get colPurchasePrice => 'Purchase price';

  @override
  String get colSalePrice => 'Sale price';

  @override
  String get colBarcode => 'Barcode';

  @override
  String get colDate => 'Date';

  @override
  String get colType => 'Type';

  @override
  String get colUnitPrice => 'Unit price';

  @override
  String get colCancelled => 'Undone';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get pinTitle => 'PIN code';

  @override
  String get pinIntro =>
      'The PIN is asked every time the app opens, and after one minute in another app. It stops someone who picks up the phone or PC from seeing or changing the stock.';

  @override
  String get pinCreate => 'Create a PIN';

  @override
  String get pinChange => 'Change the PIN';

  @override
  String get pinRemove => 'Remove the PIN';

  @override
  String get pinEnter => 'Enter your PIN';

  @override
  String get pinCurrent => 'Enter the current PIN';

  @override
  String get pinNew => 'Choose a code with 4 to 6 digits';

  @override
  String get pinConfirm => 'Type the same code again';

  @override
  String get pinMismatch => 'The two codes don\'t match. Try again.';

  @override
  String get pinSaved => 'PIN saved';

  @override
  String get pinRemoved => 'PIN removed';

  @override
  String get pinWrong => 'Wrong code';

  @override
  String pinWait(int seconds) {
    return 'Too many attempts. Try again in $seconds s.';
  }

  @override
  String get pinErase => 'Delete';

  @override
  String pinDigits(int count) {
    return '$count digits entered';
  }

  @override
  String get pinForgot => 'Forgot your PIN?';

  @override
  String get pinForgotNoAccount =>
      'Without a sync account, the PIN can\'t be reset here. You have to uninstall and reinstall the app: the local stock will be lost unless you have a backup.';

  @override
  String pinForgotWithAccount(String email) {
    return 'Enter the password of the account $email to remove the PIN.';
  }
}
