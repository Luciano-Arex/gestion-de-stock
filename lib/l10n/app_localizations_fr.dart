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
}
