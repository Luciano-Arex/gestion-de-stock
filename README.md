# Gestion de stock

Application de gestion de stock simple et accessible, pour Android et Windows, avec une seule base de code Flutter.

Spécification : https://claude.ai/artifact/Kns1HWGZScfQDtdxxBJ6YB

## Ce que fait l'appli

- Accueil avec deux grands boutons « J'ai reçu » et « J'ai vendu » : choisir le produit (ou le créer pendant une réception), indiquer la quantité, valider. Un bouton « Annuler » reste affiché quelques secondes après chaque saisie.
- Liste du stock avec recherche ; ruptures et seuils bas signalés par un mot et une icône, pas seulement une couleur.
- Fiches produits : nom, catégorie, seuil d'alerte, prix (facultatifs), code-barres (facultatif), archivage.
- Sauvegarde et restauration dans un fichier JSON.
- Synchronisation entre le téléphone et le PC via Supabase. L'appli marche hors ligne et rattrape le retard quand internet revient.

Le stock n'est jamais saisi : il se calcule (entrées − sorties). Un mouvement ne se supprime pas, il s'annule par un mouvement inverse. C'est ce qui permet à deux appareils de vendre hors ligne sans se contredire.

## Fichiers d'installation

À chaque envoi sur `main`, GitHub Actions lance les tests puis publie dans **Releases** :

- `mon-stock.apk` pour Android (à ouvrir sur le téléphone ; autoriser l'installation depuis cette source) ;
- `mon-stock-setup.exe` pour Windows (si Windows affiche « Windows a protégé votre ordinateur », cliquer sur « Informations complémentaires » puis « Exécuter quand même » : l'installateur n'est pas signé).

### Secrets GitHub à renseigner (Settings > Secrets and variables > Actions)

| Secret | Rôle |
| --- | --- |
| `SUPABASE_URL` | Adresse du projet Supabase (ex. `https://abcd.supabase.co`) |
| `SUPABASE_KEY` | Clé publique (« publishable » ou « anon ») du projet |
| `ANDROID_KEYSTORE_BASE64` | Clé de signature Android, encodée en base64. Sans elle, chaque APK est signé avec une clé différente et ne peut pas mettre à jour le précédent. |
| `ANDROID_KEYSTORE_PASSWORD` | Mot de passe de cette clé (alias `upload`) |

Sans les deux premiers, l'appli fonctionne mais sans synchronisation.

## Mettre en place Supabase (une fois)

1. Créer un projet sur supabase.com, région Europe (Francfort).
2. SQL Editor : coller `supabase/schema.sql`, puis « Run ».
3. Authentication > Users : créer un utilisateur (e-mail + mot de passe). Ce compte servira sur le téléphone et sur le PC.
4. Authentication > Sign In / Providers : désactiver « Allow new users to sign up ». La clé publique est dans l'appli : sans ce réglage, n'importe qui pourrait se créer un compte et lire le stock.

## Développer

Prérequis : [Flutter](https://docs.flutter.dev/get-started/install) 3.47 (stable). Pour Windows, Visual Studio avec la charge « Développement Desktop en C++ ».

```
flutter pub get
dart run build_runner build   # régénère database.g.dart après un changement de tables
flutter test
flutter run -d windows --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_KEY=…
```
