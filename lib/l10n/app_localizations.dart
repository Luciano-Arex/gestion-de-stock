import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
  ];

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

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @newCategory.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get newCategory;

  /// No description provided for @renameCategory.
  ///
  /// In fr, this message translates to:
  /// **'Renommer la catégorie'**
  String get renameCategory;

  /// No description provided for @categoryName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la catégorie'**
  String get categoryName;

  /// No description provided for @removeCategory.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la catégorie'**
  String get removeCategory;

  /// No description provided for @removeCategoryConfirm.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » ne sera plus proposée. Les produits de cette catégorie restent dans le stock.'**
  String removeCategoryConfirm(String name);

  /// No description provided for @allCategories.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get allCategories;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In fr, this message translates to:
  /// **'Celle du téléphone / PC'**
  String get languageSystem;

  /// No description provided for @reports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get reports;

  /// No description provided for @stockValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur du stock'**
  String get stockValue;

  /// No description provided for @stockValueHelp.
  ///
  /// In fr, this message translates to:
  /// **'Quantité × prix d\'achat, pour les produits en stock.'**
  String get stockValueHelp;

  /// No description provided for @productsWithoutPrice.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 produit sans prix d\'achat n\'est pas compté.} other{{count} produits sans prix d\'achat ne sont pas comptés.}}'**
  String productsWithoutPrice(int count);

  /// No description provided for @salesSummary.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get salesSummary;

  /// No description provided for @unitsSold.
  ///
  /// In fr, this message translates to:
  /// **'Articles vendus'**
  String get unitsSold;

  /// No description provided for @revenue.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d\'affaires'**
  String get revenue;

  /// No description provided for @margin.
  ///
  /// In fr, this message translates to:
  /// **'Marge'**
  String get margin;

  /// No description provided for @marginHelp.
  ///
  /// In fr, this message translates to:
  /// **'Prix de chaque vente moins le prix d\'achat actuel du produit. Les ventes sans prix ne sont pas comptées.'**
  String get marginHelp;

  /// No description provided for @bestSellers.
  ///
  /// In fr, this message translates to:
  /// **'Meilleures ventes'**
  String get bestSellers;

  /// No description provided for @soldCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} vendus'**
  String soldCount(int count);

  /// No description provided for @noSales.
  ///
  /// In fr, this message translates to:
  /// **'Aucune vente sur cette période.'**
  String get noSales;

  /// No description provided for @exportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Export Excel'**
  String get exportTitle;

  /// No description provided for @exportIntro.
  ///
  /// In fr, this message translates to:
  /// **'Ces fichiers s\'ouvrent dans Excel ou LibreOffice, pour consulter ou imprimer. Pour remettre des données dans l\'appli, utilise la sauvegarde.'**
  String get exportIntro;

  /// No description provided for @exportStock.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le stock'**
  String get exportStock;

  /// No description provided for @exportHistory.
  ///
  /// In fr, this message translates to:
  /// **'Exporter l\'historique'**
  String get exportHistory;

  /// No description provided for @exportDone.
  ///
  /// In fr, this message translates to:
  /// **'Fichier enregistré'**
  String get exportDone;

  /// No description provided for @colProduct.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get colProduct;

  /// No description provided for @colCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get colCategory;

  /// No description provided for @colQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get colQuantity;

  /// No description provided for @colThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil d\'alerte'**
  String get colThreshold;

  /// No description provided for @colPurchasePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix d\'achat'**
  String get colPurchasePrice;

  /// No description provided for @colSalePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix de vente'**
  String get colSalePrice;

  /// No description provided for @colBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Code-barres'**
  String get colBarcode;

  /// No description provided for @colDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get colDate;

  /// No description provided for @colType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get colType;

  /// No description provided for @colUnitPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix unitaire'**
  String get colUnitPrice;

  /// No description provided for @colCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get colCancelled;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @pinTitle.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN'**
  String get pinTitle;

  /// No description provided for @pinIntro.
  ///
  /// In fr, this message translates to:
  /// **'Le code PIN est demandé à chaque ouverture de l\'appli, et après une minute passée sur une autre appli. Il empêche quelqu\'un qui prend le téléphone ou le PC de voir ou modifier le stock.'**
  String get pinIntro;

  /// No description provided for @pinCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un code PIN'**
  String get pinCreate;

  /// No description provided for @pinChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer le code PIN'**
  String get pinChange;

  /// No description provided for @pinRemove.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le code PIN'**
  String get pinRemove;

  /// No description provided for @pinEnter.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code PIN'**
  String get pinEnter;

  /// No description provided for @pinCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code PIN actuel'**
  String get pinCurrent;

  /// No description provided for @pinNew.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un code de 4 à 6 chiffres'**
  String get pinNew;

  /// No description provided for @pinConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retapez le même code'**
  String get pinConfirm;

  /// No description provided for @pinMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux codes ne sont pas pareils. Recommencez.'**
  String get pinMismatch;

  /// No description provided for @pinSaved.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN enregistré'**
  String get pinSaved;

  /// No description provided for @pinRemoved.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN supprimé'**
  String get pinRemoved;

  /// No description provided for @pinWrong.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect'**
  String get pinWrong;

  /// No description provided for @pinWait.
  ///
  /// In fr, this message translates to:
  /// **'Trop d\'essais. Réessayez dans {seconds} s.'**
  String pinWait(int seconds);

  /// No description provided for @pinErase.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get pinErase;

  /// No description provided for @pinDigits.
  ///
  /// In fr, this message translates to:
  /// **'{count} chiffres tapés'**
  String pinDigits(int count);

  /// No description provided for @pinForgot.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN oublié ?'**
  String get pinForgot;

  /// No description provided for @pinForgotNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Sans compte de synchronisation, le code ne peut pas être réinitialisé ici. Il faut désinstaller puis réinstaller l\'appli : le stock local sera perdu, sauf s\'il existe une sauvegarde.'**
  String get pinForgotNoAccount;

  /// No description provided for @pinForgotWithAccount.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le mot de passe du compte {email} pour supprimer le code PIN.'**
  String pinForgotWithAccount(String email);

  /// No description provided for @defaultCategory.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get defaultCategory;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre stock, sur votre téléphone et votre PC.'**
  String get loginSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @showPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get hidePassword;

  /// No description provided for @passwordRule.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 6 caractères'**
  String get passwordRule;

  /// No description provided for @passwordConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Retapez le mot de passe'**
  String get passwordConfirm;

  /// No description provided for @passwordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les deux mots de passe ne sont pas pareils'**
  String get passwordMismatch;

  /// No description provided for @signUpCheckEmail.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé. Ouvrez l\'e-mail envoyé à {email}, cliquez sur le lien de confirmation, puis connectez-vous ici.'**
  String signUpCheckEmail(String email);

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @resetIntro.
  ///
  /// In fr, this message translates to:
  /// **'Entrez l\'adresse e-mail de votre compte. Vous recevrez un code pour choisir un nouveau mot de passe.'**
  String get resetIntro;

  /// No description provided for @resetCodeSent.
  ///
  /// In fr, this message translates to:
  /// **'Un code a été envoyé à {email}. Entrez-le ci-dessous avec votre nouveau mot de passe.'**
  String resetCodeSent(String email);

  /// No description provided for @resetCode.
  ///
  /// In fr, this message translates to:
  /// **'Code reçu par e-mail'**
  String get resetCode;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @resetSend.
  ///
  /// In fr, this message translates to:
  /// **'Recevoir un code'**
  String get resetSend;

  /// No description provided for @resetConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get resetConfirm;

  /// No description provided for @authEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide'**
  String get authEmailInvalid;

  /// No description provided for @authOffline.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet. La première connexion sur un appareil a besoin d\'internet.'**
  String get authOffline;

  /// No description provided for @authInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail ou mot de passe incorrect'**
  String get authInvalid;

  /// No description provided for @authNotConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Adresse pas encore confirmée : cliquez d\'abord sur le lien reçu par e-mail.'**
  String get authNotConfirmed;

  /// No description provided for @authExists.
  ///
  /// In fr, this message translates to:
  /// **'Un compte existe déjà avec cette adresse. Connectez-vous.'**
  String get authExists;

  /// No description provided for @authSignupDisabled.
  ///
  /// In fr, this message translates to:
  /// **'La création de comptes est désactivée sur le serveur.'**
  String get authSignupDisabled;

  /// No description provided for @authRateLimit.
  ///
  /// In fr, this message translates to:
  /// **'Trop de demandes. Réessayez dans quelques minutes.'**
  String get authRateLimit;

  /// No description provided for @authCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect ou expiré'**
  String get authCodeInvalid;

  /// No description provided for @authUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {message}'**
  String authUnknown(String message);

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get account;

  /// No description provided for @signOutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Vous devrez entrer à nouveau votre mot de passe. Votre stock reste enregistré sur le serveur.'**
  String get signOutConfirm;

  /// No description provided for @signOutPending.
  ///
  /// In fr, this message translates to:
  /// **'Certaines saisies ne sont pas encore envoyées au serveur. Elles restent sur cet appareil et partiront à votre prochaine connexion.'**
  String get signOutPending;

  /// No description provided for @unit.
  ///
  /// In fr, this message translates to:
  /// **'pièce'**
  String get unit;

  /// No description provided for @entries.
  ///
  /// In fr, this message translates to:
  /// **'Entrées'**
  String get entries;

  /// No description provided for @exits.
  ///
  /// In fr, this message translates to:
  /// **'Sorties'**
  String get exits;

  /// No description provided for @summaryProducts.
  ///
  /// In fr, this message translates to:
  /// **'articles'**
  String get summaryProducts;

  /// No description provided for @summaryPieces.
  ///
  /// In fr, this message translates to:
  /// **'pièces en stock'**
  String get summaryPieces;

  /// No description provided for @summaryInToday.
  ///
  /// In fr, this message translates to:
  /// **'entrées aujourd\'hui'**
  String get summaryInToday;

  /// No description provided for @summaryOutToday.
  ///
  /// In fr, this message translates to:
  /// **'sorties aujourd\'hui'**
  String get summaryOutToday;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get navStock;

  /// No description provided for @lost.
  ///
  /// In fr, this message translates to:
  /// **'Perte / sortie'**
  String get lost;

  /// No description provided for @stockCount.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire'**
  String get stockCount;

  /// No description provided for @countedQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Combien en avez-vous compté ?'**
  String get countedQuestion;

  /// No description provided for @countHelp.
  ///
  /// In fr, this message translates to:
  /// **'Comptez ce qui est vraiment en rayon. L\'appli enregistre l\'écart avec la quantité calculée.'**
  String get countHelp;

  /// No description provided for @countedQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité comptée'**
  String get countedQuantity;

  /// No description provided for @unitPriceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix unitaire'**
  String get unitPriceLabel;

  /// No description provided for @unitPriceSellHelp.
  ///
  /// In fr, this message translates to:
  /// **'Modifiez-le en cas de remise.'**
  String get unitPriceSellHelp;

  /// No description provided for @noteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note (facultatif)'**
  String get noteLabel;

  /// No description provided for @lossNoteHelp.
  ///
  /// In fr, this message translates to:
  /// **'Par exemple : cassé, offert, usage personnel'**
  String get lossNoteHelp;

  /// No description provided for @initialQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité déjà en stock'**
  String get initialQuantity;

  /// No description provided for @initialQuantityHelp.
  ///
  /// In fr, this message translates to:
  /// **'Ce que vous avez aujourd\'hui. Elle est enregistrée comme une première réception, visible dans l\'historique.'**
  String get initialQuantityHelp;

  /// No description provided for @sortBy.
  ///
  /// In fr, this message translates to:
  /// **'Trier'**
  String get sortBy;

  /// No description provided for @sortName.
  ///
  /// In fr, this message translates to:
  /// **'Par nom'**
  String get sortName;

  /// No description provided for @sortQuantityAsc.
  ///
  /// In fr, this message translates to:
  /// **'Quantité : la plus faible d\'abord'**
  String get sortQuantityAsc;

  /// No description provided for @sortQuantityDesc.
  ///
  /// In fr, this message translates to:
  /// **'Quantité : la plus forte d\'abord'**
  String get sortQuantityDesc;

  /// No description provided for @archivedProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits archivés'**
  String get archivedProducts;

  /// No description provided for @archivedEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit archivé. Un produit archivé disparaît du stock mais garde son historique.'**
  String get archivedEmpty;

  /// No description provided for @restore.
  ///
  /// In fr, this message translates to:
  /// **'Remettre en vente'**
  String get restore;

  /// No description provided for @restored.
  ///
  /// In fr, this message translates to:
  /// **'{name} est de retour dans le stock'**
  String restored(String name);

  /// No description provided for @countUnchanged.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire de {name} : le stock était juste'**
  String countUnchanged(String name);

  /// No description provided for @lossDone.
  ///
  /// In fr, this message translates to:
  /// **'{count} × {name} sorti du stock'**
  String lossDone(int count, String name);

  /// No description provided for @countDone.
  ///
  /// In fr, this message translates to:
  /// **'{name} : stock corrigé à {count}'**
  String countDone(int count, String name);

  /// No description provided for @typeAdjustment.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire'**
  String get typeAdjustment;
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
      <String>['de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
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
