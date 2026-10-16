FICHE DE REMISE EN SERVICE — BUILD PLAY STORE AUTOPARC
Etat au 2026-10-15. Analyse en lecture seule, aucune modification faite.

---

## 1. Pourquoi l'app publiee echoue

1. Le bundle `build/app/outputs/bundle/release/app-release.aab` (20 sept., 63 606 926 o) contient l'adresse `http://10.0.2.2:8000/api` dans `base/lib/arm64-v8a/libapp.so`, `armeabi-v7a` et `x86_64` ; `onrender.com` y est absent des trois. Fait mesure trois fois, independamment.
2. Cause : `lib/core/api/endpoints.dart:33-36` retombe sur `_emulator` (`endpoints.dart:9`) quand `--dart-define=API_BASE_URL` n'est pas passe. Ce bundle a donc ete construit sans le define. `10.0.2.2` n'existe que dans l'emulateur Android : aucune requete ne peut aboutir.
3. A l'inverse `build/app/outputs/flutter-apk/app-release.apk` (18 sept., 64 786 208 o) contient `onrender.com` et pas `10.0.2.2` : le meme poste sait produire un artefact correct.
4. RESERVE QUI DOIT ETRE LEVEE AVANT DE CLORE : rien n'etablit que ce .aab-la est l'artefact servi par le Play Store, et deux indices disent le contraire (detail au point 6). Le defaut d'URL est certain ; son imputation au binaire installe ne l'est pas.
5. Le backend, lui, fonctionne : `GET https://autoparc-backend.onrender.com/api/catalog/parts` rend 200 avec de vraies donnees (verifie aujourd'hui). Le probleme est entierement cote application.

---

## 2. Correction immediate : obtenir un bundle qui marche

**Etape 2.1 — Lire le code de version de la release active dans la Play Console.** A faire en premier, avant tout build. Console Play > votre application > Production > la release en cours > code de version.
- Code de version = 1 → le bundle manuel du 20 sept. est bien en ligne, le diagnostic tient, enchainer sur 2.2.
- Code de version > 1 (p. ex. un numero d'execution GitHub) → l'app installee vient de la CI et contient deja l'URL Render : ARRETER ICI, la cause est ailleurs, aller au point 6.

**Etape 2.2 — Construire par la CI, jamais a la main.** Onglet Actions > workflow « Build Android » > Run workflow. Le workflow passe les bons arguments : `.github/workflows/build-apk.yml:147-152` (appbundle) et `:157-161` (apk) posent `--dart-define=API_BASE_URL=https://autoparc-backend.onrender.com/api` et `--build-number=${{ github.run_number }}`.
- Verification : l'etape « Construire l'App Bundle » affiche le numero de build. Le workflow doit etre vert de bout en bout, y compris l'etape de verification de signature (`build-apk.yml:170-183`).

**Etape 2.3 — Recuperer le .aab dans l'artefact `autoparc-android` de l'execution** (conserve 30 jours, `docs/publication-play.md:246-247`). Ne pas prendre le fichier present dans `build/` sur le poste.

**Etape 2.4 — Verifier l'artefact AVANT de l'envoyer.** Dans un repertoire vide :

```
unzip -o app-release.aab 'base/lib/*/libapp.so' -d verif
for so in verif/base/lib/*/libapp.so; do
  echo "$so"
  echo -n "  10.0.2.2    : "; grep -ac '10\.0\.2\.2' "$so"
  echo -n "  onrender.com: "; grep -ac 'onrender\.com' "$so"
done
```
Attendu : `10.0.2.2 : 0` et `onrender.com : 1` pour les trois ABI. J'ai eprouve cette commande : elle rend l'inverse exact sur le .aab fautif du 20 septembre, et le resultat attendu sur l'apk du 18. Elle discrimine (les libapp.so des deux artefacts ont des tailles identiques mais des sha256 differents : ne jamais juger a la taille).

**Etape 2.5 — Verifier le code de version du bundle.** Il doit etre strictement superieur au plus haut code deja envoye sur cette application. Un code 45 a deja ete envoye et refuse en revue pour `READ_MEDIA_IMAGES` (`docs/publication-play.md:183-188`) : un bundle en code 1 sera refuse au televersement.

**Etape 2.6 — Televerser, puis constater.** Apres installation depuis Play : l'onglet Pieces doit afficher des articles reels. C'est la seule verification qui vaut. Les onglets Vehicules et Accessoires resteront vides — c'est normal aujourd'hui, voir 4.3, ce n'est pas un echec du correctif.

---

## 3. Correctif de fond : rendre la faute impossible

### 3.1 Le defaut de compilation ne doit plus etre l'emulateur en release

`lib/core/api/endpoints.dart` — ajouter l'import en tete de fichier :

```dart
import 'package:flutter/foundation.dart' show kDebugMode;
```

puis remplacer `endpoints.dart:33-36` par :

```dart
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: kDebugMode ? _emulator : _render,
  );
```

Pourquoi `kDebugMode` et non `kReleaseMode` : `kReleaseMode` laisserait les builds *profile* sur l'emulateur. La documentation Flutter le dit elle-meme dans `packages/flutter/lib/src/foundation/constants.dart:17-18`. `kDebugMode` (`constants.dart:64`) couvre release ET profile d'un coup, et le developpement quotidien continue sans aucun reglage.

J'ai verifie que la construction tient : un conditionnel est accepte dans un `defaultValue:` const et bascule bien a la compilation AOT (eprouve sur un fichier jetable hors depot, `dart run` → emulateur, `dart compile exe` → Render).

Consequence a traiter dans le meme geste : `_emulator` et `_render` deviennent reference. Retirer les `// ignore: dead_code` de `endpoints.dart:8` et `:15`, les garder sur `:10` (`_device`) et `:12` (`_ngrok`).

Reste a faire par vous : `flutter analyze` apres l'edition. Je n'ai pas pu compiler (mandat de lecture seule).

### 3.2 Le garde-fou qui controle l'objet reellement expedie

C'est la seule couche qui protege vraiment, parce qu'elle inspecte le binaire. A inserer dans `.github/workflows/build-apk.yml` **apres la ligne 183** (fin de l'etape de verification de signature) et **avant la ligne 185** (debut de l'etape de publication des artefacts) :

```yaml
      - name: Verifier l'URL compilee dans le bundle
        run: |
          set -e
          rm -rf /tmp/verif && mkdir -p /tmp/verif
          unzip -o build/app/outputs/bundle/release/app-release.aab \
            'base/lib/*/libapp.so' -d /tmp/verif
          for so in /tmp/verif/base/lib/*/libapp.so; do
            if grep -aq '10\.0\.2\.2' "$so"; then
              echo "ECHEC: $so contient l'adresse de l'emulateur."; exit 1
            fi
            if ! grep -aq "${API_BASE_HOST}" "$so"; then
              echo "ECHEC: $so ne contient pas l'hote de production."; exit 1
            fi
          done
          echo "URL de production confirmee dans les trois ABI."
```

Mettre `API_BASE_HOST: autoparc-backend.onrender.com` et l'URL complete dans un bloc `env:` du workflow : l'URL y figure deja en dur deux fois (`build-apk.yml:152` et `:161`), et elle est encore recopiee dans `docs/publication-play.md:245`, `ios/README.md:41`, `README.md:20`, `:92`, `:100`.

Ce garde-fou est de la meme famille que celui qui existe deja et qui fonctionne : le refus d'un bundle signe en debug (`build-apk.yml:170-183`).

### 3.3 Mettre a jour l'avertissement de la documentation

`docs/publication-play.md:241-247` dit aujourd'hui qu'un bundle construit sur un poste cumule deux defauts, dont l'URL. Apres 3.1 cette phrase devient fausse. La reecrire : le defaut restant est le numero de build. Un document faux cesse d'etre lu.

---

## 4. Les risques suivants, par ordre de probabilite

Ils mordront APRES la correction de l'URL. Aucun d'eux n'est la cause actuelle.

### 4.1 Un second defaut, deja visible dans le texte du message (probabilite elevee)

C'est le point le plus genant du dossier, et il est confirme par trois analyses independantes.

Le message rapporte, « Erreur inconnue. », ne peut PAS etre produit par un echec de connexion. `lib/core/api/api_exception.dart:47-49` ne retient ce texte que si `e.message` est nul. Or dans Dio 5.11.0 (verrouille, `pubspec.lock:300-307`) toutes les fabriques d'echec reseau posent un message non nul : une socket injoignable donne « The connection errored: … » ou le message de delai depasse. Ces deux chaines sont presentes dans le libapp.so livre. Un telephone qui echoue a joindre `10.0.2.2` afficherait donc « ApiException(?): The connection errored: … ».

Le seul chemin vers `message == null` est `DioMixin.assureDioException` (dio 5.11.0, `dio_mixin.dart:781-794`), qui emballe une exception NON-Dio levee dans le pipeline. Trois candidats, tous dans votre code, tous independants de l'URL :
- `lib/core/api/api_client.dart:72` — `_kStorage.read(...)` sans try/catch, dans l'intercepteur `onRequest`, alors que la lecture Firebase voisine (`:80-92`) est protegee.
- `lib/core/api/api_client.dart:113` et `:129` — `_dio.get<Map<String, dynamic>>` : un corps JSON d'un autre type leve a l'interieur du pipeline.
- `lib/core/api/api_exception.dart:48` — `parsed['message'] as String` : si le serveur rend `"message": null` ou une liste, le cast leve A L'INTERIEUR de `fromDioError` et c'est un `_TypeError` brut qui remonte a l'ecran.

Comment verifier AVANT de republier : impossible depuis le poste. Comment verifier apres : installer le build CI, reproduire, et lire le message exact. S'il dit « The connection errored » ou « Pas de connexion », l'URL etait bien la cause et c'est fini. S'il dit encore « Erreur inconnue. », le second defaut existe — et il faudra une remontee d'erreur (4.7) pour le nommer.

### 4.2 Google Sign-In casse uniquement depuis le Play Store (probabilite elevee, effet circonscrit)

Play resigne votre bundle avec sa propre cle. L'empreinte vue par les serveurs Google n'est donc pas celle de votre cle de televersement — c'est la mecanique documentee par l'aide Google Play et par « Authenticating Your Client ». Si l'empreinte de la cle de signature Play n'est pas declaree dans Firebase, le bouton « Continuer avec Google » echoue sur les installations Play, et seulement sur elles. Un APK transfere a la main ne reproduit pas le probleme.

Perimetre exact : `lib/features/auth/data/auth_repository.dart:105-106` (Google) est le seul fournisseur concerne. Email/mot de passe (`auth_repository.dart:112-127`) n'en depend pas. Aucune connexion par telephone, aucun autre fournisseur OAuth.

Bonne nouvelle mesuree : les empreintes ne sont PAS embarquees dans le binaire. Aucune des 5 empreintes declarees localement n'apparait dans le .aab, sous aucune forme (hexa, majuscules, deux-points, octets bruts), et `google-services.json` n'est pas livre dans le bundle. La verification est entierement cote serveur Google. **Corriger cela ne demande donc ni reconstruction ni republication** — c'est une operation independante de tout le reste de cette fiche, et elle repare aussi les installations deja en place.

Comment verifier AVANT de republier :
1. Play Console > votre application > « Protected with Play » > « Play Store distribution » > « Go to Play app signing » (ancien intitule : Release > Setup > App Integrity). Relever le SHA-1 ET le SHA-256 du **certificat de cle de signature d'application**, pas ceux du certificat de cle de televersement.
2. Console Firebase > Parametres du projet > General > carte « Vos applications » > l'application Android `bf.autoparc.app` > « Empreintes du certificat SHA ». Comparer.
3. Si l'empreinte Play manque, l'ajouter (SHA-1 ; ajouter aussi le SHA-256 si vous activez un jour la connexion par telephone, Play Integrity l'exige).

Cinq empreintes sont deja declarees pour `bf.autoparc.app` dans `android/app/google-services.json` (fichier local, non suivi par git). J'ai pu en identifier deux — la cle de televersement et la cle de debug du poste. Trois restent non attribuees : l'une d'elles est peut-etre deja celle de Play. D'ou la consigne : comparer avant de modifier.

Deux reserves honnetes. (a) Je n'ai pas trouve de source sur le **delai de prise en compte** cote Google : ne concluez pas a l'echec cinq minutes apres l'ajout. (b) La documentation Credential Manager — le chemin reellement emprunte par `google_sign_in 7.2.0` — ne mentionne nulle part la SHA-1 ; l'exigence n'est documentee que cote Firebase. Le risque merite la verification, mais le mecanisme n'est pas aussi etabli qu'il en a l'air pour ce greffon precis.

Point lie, non verifiable d'ici et plus grave s'il se confirme : la cle d'API Google **est** embarquee dans le bundle. Si elle porte dans Google Cloud une restriction « Applications Android » par paquet + SHA-1, une installation Play se verrait refuser TOUTE l'authentification Firebase, email/mot de passe compris. A regarder dans le meme passage : Google Cloud > Identifiants > la cle d'API > Restrictions relatives aux applications. Declarer la SHA-1 dans Firebase ne met pas a jour cette restriction, c'est une seconde operation.

### 4.3 Les ecrans Vehicules et Accessoires resteront vides (certitude)

Mesure du jour, 2026-10-15 : `GET /api/catalog/vehicles` → 200 avec `"data":[]` ; `GET /api/catalog/accessories` → 200 avec `"data":[]` ; `/api/catalog/accessory-categories` → `[]`. Seuls `/api/catalog/parts` (14 772 o) et `/api/catalog/part-categories` (4 532 o) rendent des donnees. Aucun article ne porte de media (`"media":[]` partout) : pas de photos non plus.

Consequence directe : apres le correctif, deux onglets sur trois paraitront en panne et vous conclurez que rien n'a change. Peupler la base Render en vehicules, accessoires et categories d'accessoires AVANT de tester, ou le savoir. A verifier avant de republier : relancer les deux GET ci-dessus et exiger un `data` non vide.

### 4.4 La permission INTERNET n'est declaree nulle part en release (probabilite faible, effet total)

`android/app/src/main/AndroidManifest.xml` ne declare pas `android.permission.INTERNET` — seuls les manifestes debug (`:6`) et profile (`:6`) le font. En release elle n'arrive que par fusion depuis un greffon : `build/app/outputs/logs/manifest-merger-release-report.txt:552-553` montre « ADDED from [:firebase_messaging] ». Elle est bien dans le manifeste fusionne livre, donc rien n'est casse aujourd'hui. Mais retirer `firebase_messaging` un jour couperait Internet en release sans toucher une ligne de Dart. C'est exactement la meme famille de faute que celle qu'on corrige : une version distribuee dont le reseau depend d'un effet de bord. La declarer explicitement dans le manifeste principal.

### 4.5 La sonde de sante du backend est cassee (probabilite faible, effet de supervision)

Verifie aujourd'hui, deux appels : `GET /up` → **500** (1 017 o, la meme page d'erreur que `GET /`). Une analyse du dossier annoncait 200 : c'est faux, j'ai remesure. Toute supervision branchee sur `/up` signalera l'application morte en permanence, alors que l'API repond. A corriger cote Laravel, hors du chemin critique.

### 4.6 Ce qu'il ne faut PAS faire

- **Ne pas ajouter `usesCleartextTraffic` ni `networkSecurityConfig`.** La politique reseau Android ne s'applique pas aux sockets possedees par Dart/Flutter — la documentation officielle Flutter (`docs.flutter.dev/release/breaking-changes/network-policy-ios-android`) le dit, et l'application au niveau `dart:io` a ete annulee en Flutter 2.2.0. Mesure confirmante : la chaine `--disallow-insecure-connections` est absente du dex du bundle et du jar de l'embedding. Ajouter ce drapeau n'aurait qu'un effet : autoriser du HTTP en clair en production. Les `usesCleartextTraffic="true"` des manifestes debug (`:12`) et profile (`:11`) ne servent probablement a rien et entretiennent une croyance fausse.
- **Ne pas ajouter de regles `-keep` R8 pour les modeles de donnees.** R8 ne traite que le bytecode JVM. Le code Dart est compile AOT dans `libapp.so` et n'est ni reduit ni obscurci (aucun `--obfuscate` dans la CI). La deserialisation JSON est hors de son perimetre.

### 4.7 Aucune erreur ne remonte (c'est ce qui a coute ce diagnostic)

Ni Crashlytics ni Sentry dans `pubspec.yaml` / `pubspec.lock`. Le journal local (`error_journal.dart:22-23`, installe a `main.dart:60`) n'attrape que les erreurs NON rattrapees : une `ApiException` affichee dans un `_ErrorView` n'y passe jamais. Et trois `catch` du chemin d'authentification sont muets en release — `main.dart:73-77`, `main.dart:86-90`, `api_client.dart:85-92` — ils n'ecrivent que dans `debugPrint`.

Mise en place : `firebase_crashlytics`, avec un `recordError` non fatal dans `ApiClient._handleError` (`api_client.dart:97-104`) portant quatre cles et pas davantage — l'hote de `Endpoints.baseUrl`, `e.type`, `e.response?.statusCode`, le `requestId`. L'hote seul aurait repondu a cette panne-ci en une minute. Attention au cout reel : il faut aussi le greffon Gradle `com.google.firebase.crashlytics` dans `android/settings.gradle.kts` et `android/app/build.gradle.kts` (seul `com.google.gms.google-services` y figure), pas seulement une dependance Dart. Et la declaration « Securite des donnees » de Play est aujourd'hui « aucune donnee » : une remontee de diagnostic se declare separement.

---

## 5. Ce que l'utilisateur verra au prochain echec

Aujourd'hui, huit endroits affichent l'exception brute au lieu de passer par `messageFor()`. Trois d'entre eux sont exactement les trois onglets du catalogue (`main.dart:119-121`), c'est-a-dire le coeur de l'application. L'onglet Accueil, lui, est correct (`home_page.dart:90`) : `messageFor` est utilise 41 fois ailleurs dans `lib/`.

Le texte rapporte par l'utilisateur ne peut donc venir que de ces trois pages de liste. Les corriger n'est pas cosmetique : c'est la condition pour que le prochain diagnostic ne reparte pas a l'aveugle.

**A remplacer par `messageFor(...)` :**

| Fichier:ligne | Aujourd'hui |
|---|---|
| `lib/features/catalog/presentation/pages/vehicle_list_page.dart:141` | `paged.error.toString()` |
| `lib/features/catalog/presentation/pages/accessory_list_page.dart:149` | `paged.error.toString()` |
| `lib/features/catalog/presentation/pages/part_list_page.dart:166` | `paged.error.toString()` |
| `add_part_page.dart:474` | `'… : $e'` |
| `add_accessory_page.dart:389` | `'… : $e'` |
| `add_vehicle_to_garage_page.dart:303` | `'… : $e'` |
| `vehicle_register_page.dart:235` | `'… : $e'` |
| `fitments_section.dart:619` | `'$erreur'` |

Cinq de ces fichiers n'importent pas `core/api/api_exception.dart` et ont besoin de l'import : les trois pages de liste, `fitments_section.dart`, `add_vehicle_to_garage_page.dart`. Les trois autres l'importent deja et utilisent `messageFor` ailleurs dans le meme fichier (`add_part_page.dart:324`, `vehicle_register_page.dart:323`) — incoherence interne, simple remplacement de texte.

**Trois choses a corriger en meme temps, sinon le message devient lisible mais faux :**

1. `api_exception.dart:85-86` repond « Pas de connexion. Verifiez votre reseau puis reessayez. » des que `isNetworkFailure` est vrai, et `isNetworkFailure` (`api_exception.dart:57`) vaut `e.response == null` — ce qui est vrai aussi pour un plantage interne de l'application (4.1). On accuse le reseau de l'utilisateur d'un bug maison. Porter `e.type` dans `ApiException` et, pour le couple `type == DioExceptionType.unknown && response == null`, afficher un message distinct qui dise « erreur imprevue dans l'application ».
2. Le `_ErrorView` des trois pages de liste (`vehicle_list_page.dart:847-864`, `accessory_list_page.dart:625-643`, `part_list_page.dart:825-843`) affiche `Icons.wifi_off` quelle que soit l'erreur. Un 500 serveur y est presente comme une panne de reseau. Si on corrige le texte sans l'icone, l'icone continue de mentir.
3. Cote Google Sign-In, la phrase claire existe deja mais elle est branchee au mauvais endroit : `auth_provider.dart:209-211` traite `clientConfigurationError`, qui sur Android ne sort que pour un `serverClientId` manquant. Un refus lie a la signature atterrit dans la branche fourre-tout (`auth_provider.dart:227-230`) et l'utilisateur lira « Connexion Google impossible (unknownError) » suivi d'une description en anglais. Ajouter dans cette branche fourre-tout une phrase mentionnant la configuration de signature.

**Garde-fou de test** : un test de widget par ecran de liste, verifiant que le texte rendu en cas d'erreur ne contient pas « ApiException ». `test/error_messages_test.dart` teste la couche de message mais aucun test ne verifie son emploi par les ecrans — c'est precisement l'ecart qui a produit cette panne. Prevoir aussi un cas `unknown + response == null` : le test existant (`error_messages_test.dart:25-38`) resterait vert sans couvrir le nouveau comportement du point 1.

---

## 6. Ce qui reste a verifier ou a decider par vous

**Contradiction importante entre les analyses, a trancher en premier.** La chaine entiere suppose que le .aab local du 20 septembre est le binaire servi par le Play Store. Trois faits mesures s'y opposent :
- Le .aab porte **versionCode 1 / versionName 1.0.0** (manifeste du bundle, confirme par `build/app/intermediates/packaged_manifests/release/processReleaseManifestForPackage/output-metadata.json`).
- Un artefact en **versionCode 45** a deja ete envoye a Play et refuse en revue, pour `READ_MEDIA_IMAGES` (`docs/publication-play.md:183-188`). Play exige un code strictement croissant (`README.md:140-142`). Un bundle en code 1 n'aurait pas du passer le televersement.
- Le texte du message ne correspond pas a la panne supposee (4.1), et les parentheses vides ne correspondent a aucune version du code : `api_exception.dart:120` ecrit `ApiException(${statusCode ?? "?"})`, soit « ApiException(?) », depuis le commit initial du 3 septembre — donc bien avant le build du 20.

**Le test qui departage, en une minute :** le code de version de la release active dans la Play Console.
- `1` → le bundle manuel est en ligne, tout ce qui precede s'applique tel quel.
- autre nombre → l'app installee vient de la CI et contient deja l'URL Render. La cause du symptome est ailleurs : reprendre au point 4.1, et mettre en place la remontee d'erreur (4.7) avant toute autre chose.

**A vous fournir, et qui coute zero :**
- Une **capture d'ecran** du message exact. Y a-t-il un `?` entre les parentheses ? un point apres « inconnue » ? C'est ce qui dit si l'on cherche une panne reseau paraphrasee ou un vrai `message == null`.
- **Sur quel onglet** le message apparait. Accueil, Vehicules, Pieces ou Accessoires : a lui seul, cela elimine plusieurs hypotheses.
- Le message apparait-il **instantanement ou apres plusieurs secondes** ? Un delai d'environ 30 s correspond au `connectTimeout` de `api_client.dart:36`. Attention : une reponse immediate n'infirme rien — `10.0.2.2` est une adresse privee non routable, une pile mobile la rejette instantanement.

**A decider par vous :**
- Reconduire ou non la publication manuelle. Mon avis : non. `docs/publication-play.md:241-247` decrivait deja le piege avec precision, et le piege s'est referme quand meme. Une consigne ecrite ne suffit pas, d'ou le garde-fou de 3.2.
- Durcir la CI sur `google-services.json` : elle verifie le nom de paquet (`build-apk.yml:79`) mais jamais la presence d'empreintes. Le contenu du secret est opaque ; rien ne garantit qu'il porte les memes empreintes que le fichier local.
- Supprimer l'application residuelle `com.example.auto` du projet Firebase (`android/app/google-services.json`, deuxieme entree). Sans effet sur la panne — son client web est identique a celui de `bf.autoparc.app` — mais cela reduit le bruit au prochain audit.
- Verifier si la **signature hybride « quantum-ready »** est activee sur votre application : l'aide Google Play impose alors trois empreintes, pas une. Meme page de la Play Console que 4.2.

**Ce que je n'ai pas pu etablir, et qui le restera depuis le poste :** l'empreinte de la cle de signature Play ; l'origine des trois empreintes non identifiees ; le contenu du secret `GOOGLE_SERVICES_JSON` ; l'etat de `FIREBASE_CREDENTIALS` sur Render ; et si les listes vides de `/catalog/vehicles` viennent d'une base vide ou d'un filtre de publication cote serveur.

**Deux points de methode, pour la prochaine fois :** le .aab du 20 septembre est signe avec votre vraie cle de publication (certificat valide depuis le 15 sept. 2026), pas avec la cle de debug — le garde-fou `build-apk.yml:170-183` l'aurait attrape sinon. Et l'ecart de version entre ce bundle (1.0.0) et `pubspec.yaml:4` (1.1.0+1) n'est pas une anomalie : `pubspec.yaml` est passe a 1.1.0 le 2 octobre, douze jours apres le build.