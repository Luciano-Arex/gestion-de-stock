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
  String get categoryMeche => 'Mèches';

  @override
  String get categoryMaillot => 'Maillots';

  @override
  String get categoryAutre => 'Autre';

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
}
