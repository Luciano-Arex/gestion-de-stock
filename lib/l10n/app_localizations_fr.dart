// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Mon stock';

  @override
  String get received => 'J\'ai reçu';

  @override
  String get receivedHint => 'Enregistrer un arrivage';

  @override
  String get sold => 'J\'ai vendu';

  @override
  String get soldHint => 'Enregistrer une vente';

  @override
  String get myStock => 'Voir mon stock';

  @override
  String get stockEmpty => 'Aucun produit pour l\'instant.';

  @override
  String get noResult => 'Aucun produit ne correspond.';

  @override
  String quantity(int count) {
    return '$count en stock';
  }

  @override
  String get outOfStock => 'Rupture';

  @override
  String get lowStock => 'À recommander';

  @override
  String get search => 'Chercher un produit';

  @override
  String get newProduct => 'Nouveau produit';

  @override
  String get editProduct => 'Modifier le produit';

  @override
  String get productName => 'Nom du produit';

  @override
  String get productNameHelp =>
      'Ex. : Maillot Cameroun domicile 2024, taille M';

  @override
  String get productNameRequired => 'Indique un nom.';

  @override
  String get category => 'Catégorie';

  @override
  String get alertThreshold => 'Me prévenir à partir de';

  @override
  String get alertThresholdHelp =>
      'Le produit passe « À recommander » quand il en reste ce nombre ou moins.';

  @override
  String get salePrice => 'Prix de vente (facultatif)';

  @override
  String get purchasePrice => 'Prix d\'achat (facultatif)';

  @override
  String get barcode => 'Code-barres (facultatif)';

  @override
  String get save => 'Enregistrer';

  @override
  String get archive => 'Ne plus vendre ce produit';

  @override
  String get archiveConfirm =>
      'Le produit sera masqué. Son historique est conservé.';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get whichProduct => 'Quel produit ?';

  @override
  String get howMany => 'Combien ?';

  @override
  String get less => 'Un de moins';

  @override
  String get more => 'Un de plus';

  @override
  String get validate => 'Valider';

  @override
  String get invalidQuantity => 'Indique un nombre supérieur à 0.';

  @override
  String notEnoughStock(int count) {
    return 'Il n\'en reste que $count. Vérifie la quantité.';
  }

  @override
  String receivedDone(int count, String name) {
    return '$count × $name ajouté au stock';
  }

  @override
  String soldDone(int count, String name) {
    return '$count × $name retiré du stock';
  }

  @override
  String get undo => 'Annuler';

  @override
  String get undone => 'Saisie annulée';

  @override
  String get invalidPrice => 'Prix non valide. Ex. : 25 ou 25,50';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get backupIntro =>
      'Une sauvegarde est un fichier qui contient tous tes produits et tout l\'historique. Range-la sur une clé USB ou dans ton espace cloud. Fais-en une au moins une fois par semaine.';

  @override
  String get backupCreate => 'Créer une sauvegarde';

  @override
  String get backupCreated => 'Sauvegarde enregistrée';

  @override
  String get backupRestore => 'Restaurer une sauvegarde';

  @override
  String get backupRestoreConfirm =>
      'Les produits et les saisies du fichier seront ajoutés à ceux déjà présents. Rien n\'est effacé, et une saisie déjà présente n\'est pas comptée deux fois.';

  @override
  String backupRestored(int products, int movements) {
    return '$products produits et $movements nouvelles saisies restaurés';
  }

  @override
  String backupError(String reason) {
    return 'Impossible de lire ce fichier : $reason';
  }

  @override
  String get sync => 'Synchronisation';

  @override
  String get syncIntro =>
      'Connecte le téléphone et le PC au même compte : ce que tu saisis sur l\'un apparaît sur l\'autre. Sans internet, l\'appli continue de marcher et rattrape le retard dès que la connexion revient.';

  @override
  String get syncNotConfigured =>
      'La synchronisation n\'est pas encore activée dans cette version de l\'appli.';

  @override
  String get syncSignedOut => 'Pas connecté';

  @override
  String get syncIdle => 'À jour';

  @override
  String get syncSyncing => 'Synchronisation…';

  @override
  String get syncOffline => 'Hors ligne, nouvel essai bientôt';

  @override
  String syncLast(String when) {
    return 'Dernière synchronisation : $when';
  }

  @override
  String syncAccount(String email) {
    return 'Compte : $email';
  }

  @override
  String get email => 'Adresse e-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signInError =>
      'Connexion refusée. Vérifie l\'adresse et le mot de passe.';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get history => 'Historique';

  @override
  String get historyEmpty => 'Aucune saisie sur cette période.';

  @override
  String get periodToday => 'Aujourd\'hui';

  @override
  String get period7 => '7 jours';

  @override
  String get period30 => '30 jours';

  @override
  String get periodAll => 'Tout';

  @override
  String get typeReceived => 'Reçu';

  @override
  String get typeSold => 'Vendu';

  @override
  String get typeLoss => 'Perte';

  @override
  String get typeCorrection => 'Annulation';

  @override
  String get cancelled => 'Annulée';

  @override
  String get undoEntry => 'Annuler cette saisie';

  @override
  String get undoEntryConfirm =>
      'La quantité sera remise comme avant. La saisie reste visible dans l\'historique, marquée « Annulée ».';

  @override
  String get toReorder => 'À recommander';

  @override
  String toReorderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits à recommander',
      one: '1 produit à recommander',
    );
    return '$_temp0';
  }

  @override
  String get toReorderEmpty => 'Rien à recommander pour l\'instant.';

  @override
  String undoNotEnough(int count) {
    return 'Impossible d\'annuler : une partie a déjà été vendue (il en reste $count).';
  }

  @override
  String get salePriceShort => 'Vente :';

  @override
  String get purchasePriceShort => 'Achat :';

  @override
  String get categories => 'Catégories';

  @override
  String get newCategory => 'Nouvelle catégorie';

  @override
  String get renameCategory => 'Renommer la catégorie';

  @override
  String get categoryName => 'Nom de la catégorie';

  @override
  String get removeCategory => 'Retirer la catégorie';

  @override
  String removeCategoryConfirm(String name) {
    return '« $name » ne sera plus proposée. Les produits de cette catégorie restent dans le stock.';
  }

  @override
  String get allCategories => 'Toutes';

  @override
  String get settings => 'Réglages';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Celle du téléphone / PC';

  @override
  String get reports => 'Rapports';

  @override
  String get stockValue => 'Valeur du stock';

  @override
  String get stockValueHelp =>
      'Quantité × prix d\'achat, pour les produits en stock.';

  @override
  String productsWithoutPrice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits sans prix d\'achat ne sont pas comptés.',
      one: '1 produit sans prix d\'achat n\'est pas compté.',
    );
    return '$_temp0';
  }

  @override
  String get salesSummary => 'Ventes';

  @override
  String get unitsSold => 'Articles vendus';

  @override
  String get revenue => 'Chiffre d\'affaires';

  @override
  String get margin => 'Marge';

  @override
  String get marginHelp =>
      'Prix de chaque vente moins le prix d\'achat actuel du produit. Les ventes sans prix ne sont pas comptées.';

  @override
  String get bestSellers => 'Meilleures ventes';

  @override
  String soldCount(int count) {
    return '$count vendus';
  }

  @override
  String get noSales => 'Aucune vente sur cette période.';

  @override
  String get exportTitle => 'Export Excel';

  @override
  String get exportIntro =>
      'Ces fichiers s\'ouvrent dans Excel ou LibreOffice, pour consulter ou imprimer. Pour remettre des données dans l\'appli, utilise la sauvegarde.';

  @override
  String get exportStock => 'Exporter le stock';

  @override
  String get exportHistory => 'Exporter l\'historique';

  @override
  String get exportDone => 'Fichier enregistré';

  @override
  String get colProduct => 'Produit';

  @override
  String get colCategory => 'Catégorie';

  @override
  String get colQuantity => 'Quantité';

  @override
  String get colThreshold => 'Seuil d\'alerte';

  @override
  String get colPurchasePrice => 'Prix d\'achat';

  @override
  String get colSalePrice => 'Prix de vente';

  @override
  String get colBarcode => 'Code-barres';

  @override
  String get colDate => 'Date';

  @override
  String get colType => 'Type';

  @override
  String get colUnitPrice => 'Prix unitaire';

  @override
  String get colCancelled => 'Annulée';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get pinTitle => 'Code PIN';

  @override
  String get pinIntro =>
      'Le code PIN est demandé à chaque ouverture de l\'appli, et après une minute passée sur une autre appli. Il empêche quelqu\'un qui prend le téléphone ou le PC de voir ou modifier le stock.';

  @override
  String get pinCreate => 'Créer un code PIN';

  @override
  String get pinChange => 'Changer le code PIN';

  @override
  String get pinRemove => 'Supprimer le code PIN';

  @override
  String get pinEnter => 'Entrez votre code PIN';

  @override
  String get pinCurrent => 'Entrez le code PIN actuel';

  @override
  String get pinNew => 'Choisissez un code de 4 à 6 chiffres';

  @override
  String get pinConfirm => 'Retapez le même code';

  @override
  String get pinMismatch => 'Les deux codes ne sont pas pareils. Recommencez.';

  @override
  String get pinSaved => 'Code PIN enregistré';

  @override
  String get pinRemoved => 'Code PIN supprimé';

  @override
  String get pinWrong => 'Code incorrect';

  @override
  String pinWait(int seconds) {
    return 'Trop d\'essais. Réessayez dans $seconds s.';
  }

  @override
  String get pinErase => 'Effacer';

  @override
  String pinDigits(int count) {
    return '$count chiffres tapés';
  }

  @override
  String get pinForgot => 'Code PIN oublié ?';

  @override
  String get pinForgotNoAccount =>
      'Sans compte de synchronisation, le code ne peut pas être réinitialisé ici. Il faut désinstaller puis réinstaller l\'appli : le stock local sera perdu, sauf s\'il existe une sauvegarde.';

  @override
  String pinForgotWithAccount(String email) {
    return 'Entrez le mot de passe du compte $email pour supprimer le code PIN.';
  }

  @override
  String get defaultCategory => 'Autre';

  @override
  String get loginSubtitle => 'Votre stock, sur votre téléphone et votre PC.';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get passwordRule => 'Au moins 6 caractères';

  @override
  String get passwordConfirm => 'Retapez le mot de passe';

  @override
  String get passwordMismatch => 'Les deux mots de passe ne sont pas pareils';

  @override
  String signUpCheckEmail(String email) {
    return 'Compte créé. Ouvrez l\'e-mail envoyé à $email, cliquez sur le lien de confirmation, puis connectez-vous ici.';
  }

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get resetIntro =>
      'Entrez l\'adresse e-mail de votre compte. Vous recevrez un code pour choisir un nouveau mot de passe.';

  @override
  String resetCodeSent(String email) {
    return 'Un code a été envoyé à $email. Entrez-le ci-dessous avec votre nouveau mot de passe.';
  }

  @override
  String get resetCode => 'Code reçu par e-mail';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get resetSend => 'Recevoir un code';

  @override
  String get resetConfirm => 'Changer le mot de passe';

  @override
  String get authEmailInvalid => 'Adresse e-mail invalide';

  @override
  String get authOffline =>
      'Pas de connexion internet. La première connexion sur un appareil a besoin d\'internet.';

  @override
  String get authInvalid => 'Adresse e-mail ou mot de passe incorrect';

  @override
  String get authNotConfirmed =>
      'Adresse pas encore confirmée : cliquez d\'abord sur le lien reçu par e-mail.';

  @override
  String get authExists =>
      'Un compte existe déjà avec cette adresse. Connectez-vous.';

  @override
  String get authSignupDisabled =>
      'La création de comptes est désactivée sur le serveur.';

  @override
  String get authRateLimit =>
      'Trop de demandes. Réessayez dans quelques minutes.';

  @override
  String get authCodeInvalid => 'Code incorrect ou expiré';

  @override
  String authUnknown(String message) {
    return 'Erreur : $message';
  }

  @override
  String get account => 'Compte';

  @override
  String get signOutConfirm =>
      'Vous devrez entrer à nouveau votre mot de passe. Votre stock reste enregistré sur le serveur.';

  @override
  String get signOutPending =>
      'Certaines saisies ne sont pas encore envoyées au serveur. Elles restent sur cet appareil et partiront à votre prochaine connexion.';

  @override
  String get unit => 'pièce';

  @override
  String get entries => 'Entrées';

  @override
  String get exits => 'Sorties';

  @override
  String get summaryProducts => 'articles';

  @override
  String get summaryPieces => 'pièces en stock';

  @override
  String get summaryInToday => 'entrées aujourd\'hui';

  @override
  String get summaryOutToday => 'sorties aujourd\'hui';

  @override
  String get navHome => 'Accueil';

  @override
  String get navStock => 'Stock';

  @override
  String get lost => 'Perte / sortie';

  @override
  String get stockCount => 'Inventaire';

  @override
  String get countedQuestion => 'Combien en avez-vous compté ?';

  @override
  String get countHelp =>
      'Comptez ce qui est vraiment en rayon. L\'appli enregistre l\'écart avec la quantité calculée.';

  @override
  String get countedQuantity => 'Quantité comptée';

  @override
  String get unitPriceLabel => 'Prix unitaire';

  @override
  String get unitPriceSellHelp => 'Modifiez-le en cas de remise.';

  @override
  String get noteLabel => 'Note (facultatif)';

  @override
  String get lossNoteHelp => 'Par exemple : cassé, offert, usage personnel';

  @override
  String get initialQuantity => 'Quantité déjà en stock';

  @override
  String get initialQuantityHelp =>
      'Ce que vous avez aujourd\'hui. Elle est enregistrée comme une première réception, visible dans l\'historique.';

  @override
  String get sortBy => 'Trier';

  @override
  String get sortName => 'Par nom';

  @override
  String get sortQuantityAsc => 'Quantité : la plus faible d\'abord';

  @override
  String get sortQuantityDesc => 'Quantité : la plus forte d\'abord';

  @override
  String get archivedProducts => 'Produits archivés';

  @override
  String get archivedEmpty =>
      'Aucun produit archivé. Un produit archivé disparaît du stock mais garde son historique.';

  @override
  String get restore => 'Remettre en vente';

  @override
  String restored(String name) {
    return '$name est de retour dans le stock';
  }

  @override
  String countUnchanged(String name) {
    return 'Inventaire de $name : le stock était juste';
  }

  @override
  String lossDone(int count, String name) {
    return '$count × $name sorti du stock';
  }

  @override
  String countDone(int count, String name) {
    return '$name : stock corrigé à $count';
  }

  @override
  String get typeAdjustment => 'Inventaire';

  @override
  String get deleteProduct => 'Supprimer le produit';

  @override
  String deleteProductTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get deleteProductConfirm =>
      'Le produit disparaîtra du stock, de l\'historique et des rapports, sur tous tes appareils.\n\nSi tu ne le vends plus mais veux garder une trace de ses ventes, archive-le plutôt.';

  @override
  String get archiveInstead => 'Archiver plutôt';

  @override
  String get delete => 'Supprimer';

  @override
  String productDeleted(String name) {
    return '$name a été supprimé';
  }

  @override
  String productArchived(String name) {
    return '$name a été archivé';
  }

  @override
  String get color => 'Couleur (facultatif)';

  @override
  String get colorHelp => 'Ex. : Noir, 1B, Blond 613, Rouge et blanc';

  @override
  String get colColor => 'Couleur';
}
