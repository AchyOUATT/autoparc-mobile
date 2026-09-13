# iOS — ce qu'il faut savoir avant de compiler

## `GoogleService-Info.plist` est obligatoire et absent du dépôt

Le fichier est **exclu par `.gitignore`** (ligne 3), mais **déclaré dans le
projet Xcode**. Un clone frais ne le contient donc pas, et le build s'arrête
avec :

```
Build input file cannot be found: '.../ios/Runner/GoogleService-Info.plist'
```

C'est voulu. L'alternative — ne pas le déclarer — laisse compiler une
application où Firebase ne démarre pas : pas d'authentification client, pas de
notifications, et aucun message qui l'explique. Un échec bruyant au bon moment
vaut mieux qu'une panne silencieuse à l'exécution.

**Pour compiler :** récupérer le fichier depuis la console Firebase (projet
`auto-55551`, application iOS `bf.autoparc.app`) et le poser dans
`ios/Runner/`. Rien à faire dans Xcode : le projet le référence déjà, avec sa
phase de ressources.

**En intégration continue :** le restaurer depuis un secret avant le build,
comme le fait déjà `google-services.json` côté Android.

```yaml
- name: Restaurer GoogleService-Info.plist
  run: echo '${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}' > ios/Runner/GoogleService-Info.plist
```

## Le `Podfile` n'existe pas encore

Normal : CocoaPods le génère au premier `flutter build ipa` sur macOS. Il n'y a
rien à créer à la main.

## L'URL de l'API se passe à la compilation

Sans cela, une version distribuée pointe sur l'adresse de l'émulateur Android.

```bash
flutter build ipa --dart-define=API_BASE_URL=https://autoparc-backend.onrender.com/api
```

## Ce qui reste à faire sur un Mac

- Choisir l'équipe de signature dans `ios/Runner.xcworkspace`.
- Activer la capacité **Push Notifications** sur l'identifiant d'application
  dans le portail développeur Apple — sans quoi la signature échoue.
  L'entitlement `aps-environment` est déjà en place côté projet.
- Remplacer l'icône : les deux plateformes portent encore celle de Flutter.
