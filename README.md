# AutoParc — application mobile

Vente et location de véhicules, pièces détachées et accessoires au Burkina Faso.
Flutter, avec une API Laravel séparée ([autoparc-backend](https://github.com/AchyOUATT/autoparc-backend)).

## Développement

```bash
flutter pub get
flutter run
```

Par défaut l'application vise `http://10.0.2.2:8000/api`, c'est-à-dire le
`php artisan serve` de la machine hôte vu depuis l'émulateur Android. Aucun
réglage n'est donc nécessaire au quotidien.

Pour viser une autre API :

```bash
flutter run --dart-define=API_BASE_URL=https://autoparc-backend.onrender.com/api
```

`API_BASE_URL` se lit dans [`lib/core/api/endpoints.dart`](lib/core/api/endpoints.dart),
qui conserve en commentaire les adresses usuelles : téléphone sur le même WiFi,
tunnel ngrok, production.

**Tout build destiné à quelqu'un d'autre doit passer cette variable.** Sans
elle, l'application distribuée pointe sur `10.0.2.2`, une adresse qui n'existe
que dans l'émulateur.

```bash
flutter test
flutter analyze
```

### Retrouver une erreur qui ne se reproduit pas

Les erreurs sont écrites sur l'appareil, en plus de la console. Le tampon de
`logcat` est circulaire : une poignée de minutes suffit à l'écraser, et un écran
rouge aperçu le matin n'a plus de trace l'après-midi.

```bash
adb shell run-as bf.autoparc.app cat databases/erreurs.log
```

Chaque entrée porte l'horodatage, l'exception, la bibliothèque et la pile
d'appels complète. Pour repartir de zéro :

```bash
adb shell run-as bf.autoparc.app rm databases/erreurs.log
```

Le fichier ne quitte jamais l'appareil — rien n'est envoyé nulle part, ce serait
une collecte de données à déclarer. Voir
[`error_journal.dart`](lib/core/diagnostics/error_journal.dart).

## Publication Android

### 1. La clé de signature

Une seule fois, et à conserver à vie.

Sous Windows (PowerShell) — `keytool` est un binaire Windows et ne développe pas
le `~` d'un shell POSIX, il faut donc un chemin explicite :

```bash
keytool -genkey -v -keystore "$env:USERPROFILE\autoparc-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias autoparc
```

Sous macOS, Linux, ou Git Bash sous Windows :

```bash
keytool -genkey -v -keystore "$HOME/autoparc-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias autoparc
```

`-validity 10000` fait environ 27 ans. Google Play exige une validité qui
dépasse le 22 octobre 2033 ; une clé plus courte est refusée.

Copier ensuite [`android/key.properties.example`](android/key.properties.example)
vers `android/key.properties` et le remplir. Les deux fichiers — la clé et le
`key.properties` — sont ignorés par git et ne doivent jamais y entrer.

> **Inscris-toi à Play App Signing dès le premier envoi.** Google conserve alors
> la clé de signature finale, et celle générée ci-dessus ne sert plus qu'à
> l'envoi : perdue, elle se remplace. Sans cette inscription, perdre la clé rend
> l'application impossible à mettre à jour — il faut republier sous un autre
> identifiant, en perdant installations et avis.

### 2. Construire

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://autoparc-backend.onrender.com/api
```

Le `.aab` produit dans `build/app/outputs/bundle/release/` est ce que Play
accepte. Pour une installation directe — test terrain, envoi par WhatsApp — il
faut un APK, que Play n'accepte pas :

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://autoparc-backend.onrender.com/api
```

Sans `android/key.properties`, le build **réussit quand même** mais signe avec la
clé de debug : c'est ce qui permet de tester une version release sans clé. Gradle
l'annonce alors en clair au début du build. Vérifier avant tout envoi :

```bash
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Si le propriétaire est `CN=Android Debug`, Play refusera le fichier.

### 3. Intégration continue

[`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml) construit le
bundle et l'APK à chaque poussée sur `main`, et **échoue si le bundle est signé
en debug** — sans quoi l'erreur ne se découvrirait qu'au téléversement, avec un
message qui n'en donne pas la cause.

Secrets à renseigner dans les paramètres du dépôt :

| Secret | Contenu |
|---|---|
| `GOOGLE_SERVICES_JSON` | contenu de `android/app/google-services.json` |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/autoparc-upload.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | mot de passe du magasin |
| `ANDROID_KEY_ALIAS` | `autoparc` |
| `ANDROID_KEY_PASSWORD` | mot de passe de la clé |

Tant que `ANDROID_KEYSTORE_BASE64` est absent, le workflow construit quand même
— et s'arrête à la vérification de signature, en nommant les secrets manquants.

### 4. Numéro de version

Deux nombres distincts :

- le **nom de version** (`1.0.0`), affiché aux utilisateurs, vient de
  [`pubspec.yaml`](pubspec.yaml) — la partie avant le `+`. À changer à la main
  quand une version le mérite ;
- le **`versionCode`**, que Play exige strictement croissant d'un envoi à
  l'autre, est fixé par la CI au **numéro d'exécution du workflow**
  (`--build-number=${{ github.run_number }}`). Il augmente tout seul.

La partie après le `+` dans `pubspec.yaml` ne sert plus qu'aux builds locaux.
**N'envoie pas à Play un bundle construit sur ta machine** : il porterait ce
petit numéro, inférieur à ceux déjà publiés, et serait refusé par des messages
qui ne nomment pas la cause — « cette release ne permet pas d'ajouter ni de
supprimer des app bundles », « aucun utilisateur actuel ne peut effectuer une
mise à jour ».

## iOS

Voir [`ios/README.md`](ios/README.md). Il manque encore un Mac ou une CI macOS,
un compte Apple Developer, le `GoogleService-Info.plist` de `bf.autoparc.app`,
une clé APNs et une équipe de signature.
