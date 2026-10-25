# Gestion de stock

Application de gestion de stock simple et accessible, pour Android et Windows, avec une seule base de code Flutter.

Spécification : https://claude.ai/artifact/Kns1HWGZScfQDtdxxBJ6YB

## Où en est le code

- Base de données locale (SQLite via drift) : produits et mouvements. Le stock n'est jamais saisi, il se calcule (entrées − sorties). Un mouvement ne se supprime pas, il s'annule par un mouvement inverse.
- Accueil avec deux grands boutons « J'ai reçu » et « J'ai vendu » (écrans de saisie à venir).
- Liste du stock, avec ruptures et seuils bas signalés par un mot et une icône.
- Textes de l'interface dans `lib/l10n/app_fr.arb`, prêts pour l'anglais et l'allemand.

## Lancer le projet

Prérequis : [Flutter](https://docs.flutter.dev/get-started/install) (stable). Pour Windows, Visual Studio avec la charge « Développement Desktop en C++ ».

```
flutter pub get
dart run build_runner build   # régénère database.g.dart après un changement de tables
flutter test
flutter run -d windows        # ou un téléphone Android branché
```
