import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon stock'**
  String get appTitle;

  /// No description provided for @received.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai reçu'**
  String get received;

  /// No description provided for @receivedHint.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer un arrivage'**
  String get receivedHint;

  /// No description provided for @sold.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai vendu'**
  String get sold;

  /// No description provided for @soldHint.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer une vente'**
  String get soldHint;

  /// No description provided for @myStock.
  ///
  /// In fr, this message translates to:
  /// **'Voir mon stock'**
  String get myStock;

  /// No description provided for @stockEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit pour l\'instant.'**
  String get stockEmpty;

  /// No description provided for @noResult.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit ne correspond.'**
  String get noResult;

  /// No description provided for @quantity.
  ///
  /// In fr, this message translates to:
  /// **'{count} en stock'**
  String quantity(int count);

  /// No description provided for @outOfStock.
  ///
  /// In fr, this message translates to:
  /// **'Rupture'**
  String get outOfStock;

  /// No description provided for @lowStock.
  ///
  /// In fr, this message translates to:
  /// **'À recommander'**
  String get lowStock;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Chercher un produit'**
  String get search;

  /// No description provided for @newProduct.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau produit'**
  String get newProduct;

  /// No description provided for @editProduct.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le produit'**
  String get editProduct;

  /// No description provided for @productName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du produit'**
  String get productName;

  /// No description provided for @productNameHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ex. : Maillot Cameroun domicile 2024, taille M'**
  String get productNameHelp;

  /// No description provided for @productNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Indique un nom.'**
  String get productNameRequired;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @categoryMeche.
  ///
  /// In fr, this message translates to:
  /// **'Mèches'**
  String get categoryMeche;

  /// No description provided for @categoryMaillot.
  ///
  /// In fr, this message translates to:
  /// **'Maillots'**
  String get categoryMaillot;

  /// No description provided for @categoryAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get categoryAutre;

  /// No description provided for @alertThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Me prévenir à partir de'**
  String get alertThreshold;

  /// No description provided for @alertThresholdHelp.
  ///
  /// In fr, this message translates to:
  /// **'Le produit passe « À recommander » quand il en reste ce nombre ou moins.'**
  String get alertThresholdHelp;

  /// No description provided for @salePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix de vente (facultatif)'**
  String get salePrice;

  /// No description provided for @purchasePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix d\'achat (facultatif)'**
  String get purchasePrice;

  /// No description provided for @barcode.
  ///
  /// In fr, this message translates to:
  /// **'Code-barres (facultatif)'**
  String get barcode;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @archive.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus vendre ce produit'**
  String get archive;

  /// No description provided for @archiveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Le produit sera masqué. Son historique est conservé.'**
  String get archiveConfirm;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @whichProduct.
  ///
  /// In fr, this message translates to:
  /// **'Quel produit ?'**
  String get whichProduct;

  /// No description provided for @howMany.
  ///
  /// In fr, this message translates to:
  /// **'Combien ?'**
  String get howMany;

  /// No description provided for @less.
  ///
  /// In fr, this message translates to:
  /// **'Un de moins'**
  String get less;

  /// No description provided for @more.
  ///
  /// In fr, this message translates to:
  /// **'Un de plus'**
  String get more;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @invalidQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Indique un nombre supérieur à 0.'**
  String get invalidQuantity;

  /// No description provided for @notEnoughStock.
  ///
  /// In fr, this message translates to:
  /// **'Il n\'en reste que {count}. Vérifie la quantité.'**
  String notEnoughStock(int count);

  /// No description provided for @receivedDone.
  ///
  /// In fr, this message translates to:
  /// **'{count} × {name} ajouté au stock'**
  String receivedDone(int count, String name);

  /// No description provided for @soldDone.
  ///
  /// In fr, this message translates to:
  /// **'{count} × {name} retiré du stock'**
  String soldDone(int count, String name);

  /// No description provided for @undo.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get undo;

  /// No description provided for @undone.
  ///
  /// In fr, this message translates to:
  /// **'Saisie annulée'**
  String get undone;

  /// No description provided for @invalidPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix non valide. Ex. : 25 ou 25,50'**
  String get invalidPrice;

  /// No description provided for @backup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde'**
  String get backup;

  /// No description provided for @backupIntro.
  ///
  /// In fr, this message translates to:
  /// **'Une sauvegarde est un fichier qui contient tous tes produits et tout l\'historique. Range-la sur une clé USB ou dans ton espace cloud. Fais-en une au moins une fois par semaine.'**
  String get backupIntro;

  /// No description provided for @backupCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer une sauvegarde'**
  String get backupCreate;

  /// No description provided for @backupCreated.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde enregistrée'**
  String get backupCreated;

  /// No description provided for @backupRestore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer une sauvegarde'**
  String get backupRestore;

  /// No description provided for @backupRestoreConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Les produits et les saisies du fichier seront ajoutés à ceux déjà présents. Rien n\'est effacé, et une saisie déjà présente n\'est pas comptée deux fois.'**
  String get backupRestoreConfirm;

  /// No description provided for @backupRestored.
  ///
  /// In fr, this message translates to:
  /// **'{products} produits et {movements} nouvelles saisies restaurés'**
  String backupRestored(int products, int movements);

  /// No description provided for @backupError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de lire ce fichier : {reason}'**
  String backupError(String reason);

  /// No description provided for @sync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation'**
  String get sync;

  /// No description provided for @syncIntro.
  ///
  /// In fr, this message translates to:
  /// **'Connecte le téléphone et le PC au même compte : ce que tu saisis sur l\'un apparaît sur l\'autre. Sans internet, l\'appli continue de marcher et rattrape le retard dès que la connexion revient.'**
  String get syncIntro;

  /// No description provided for @syncNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'La synchronisation n\'est pas encore activée dans cette version de l\'appli.'**
  String get syncNotConfigured;

  /// No description provided for @syncSignedOut.
  ///
  /// In fr, this message translates to:
  /// **'Pas connecté'**
  String get syncSignedOut;

  /// No description provided for @syncIdle.
  ///
  /// In fr, this message translates to:
  /// **'À jour'**
  String get syncIdle;

  /// No description provided for @syncSyncing.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation…'**
  String get syncSyncing;

  /// No description provided for @syncOffline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne, nouvel essai bientôt'**
  String get syncOffline;

  /// No description provided for @syncLast.
  ///
  /// In fr, this message translates to:
  /// **'Dernière synchronisation : {when}'**
  String syncLast(String when);

  /// No description provided for @syncAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte : {email}'**
  String syncAccount(String email);

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get signOut;

  /// No description provided for @signInError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion refusée. Vérifie l\'adresse et le mot de passe.'**
  String get signInError;

  /// No description provided for @syncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser maintenant'**
  String get syncNow;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @historyEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune saisie sur cette période.'**
  String get historyEmpty;

  /// No description provided for @periodToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get periodToday;

  /// No description provided for @period7.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get period7;

  /// No description provided for @period30.
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get period30;

  /// No description provided for @periodAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get periodAll;

  /// No description provided for @typeReceived.
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get typeReceived;

  /// No description provided for @typeSold.
  ///
  /// In fr, this message translates to:
  /// **'Vendu'**
  String get typeSold;

  /// No description provided for @typeLoss.
  ///
  /// In fr, this message translates to:
  /// **'Perte'**
  String get typeLoss;

  /// No description provided for @typeCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Annulation'**
  String get typeCorrection;

  /// No description provided for @cancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get cancelled;

  /// No description provided for @undoEntry.
  ///
  /// In fr, this message translates to:
  /// **'Annuler cette saisie'**
  String get undoEntry;

  /// No description provided for @undoEntryConfirm.
  ///
  /// In fr, this message translates to:
  /// **'La quantité sera remise comme avant. La saisie reste visible dans l\'historique, marquée « Annulée ».'**
  String get undoEntryConfirm;

  /// No description provided for @toReorder.
  ///
  /// In fr, this message translates to:
  /// **'À recommander'**
  String get toReorder;

  /// No description provided for @toReorderCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 produit à recommander} other{{count} produits à recommander}}'**
  String toReorderCount(int count);

  /// No description provided for @toReorderEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Rien à recommander pour l\'instant.'**
  String get toReorderEmpty;

  /// No description provided for @undoNotEnough.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'annuler : une partie a déjà été vendue (il en reste {count}).'**
  String undoNotEnough(int count);

  /// No description provided for @salePriceShort.
  ///
  /// In fr, this message translates to:
  /// **'Vente :'**
  String get salePriceShort;

  /// No description provided for @purchasePriceShort.
  ///
  /// In fr, this message translates to:
  /// **'Achat :'**
  String get purchasePriceShort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
