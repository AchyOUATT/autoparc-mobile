# Espace partenaire

Entrée publique : `PartnerAccountPage`, exportée par `partner_accounts.dart`.
Le routeur principal peut l'ouvrir à `/partner`. La navigation dans les
inventaires et les formulaires utilise le navigateur de cette page.

La session est indépendante du personnel et de Firebase : `PartnerRepository`
possède son propre Dio, vise `Endpoints.baseUrl` et conserve uniquement le
jeton `partner_sanctum_token`. Il n'appelle pas `ApiClient.saveToken` et ne
modifie pas le rôle utilisé par les écrans du personnel.

Le module couvre inscription, connexion, restauration de session, statut de
validation et déconnexion, puis gestion des véhicules, pièces et accessoires
du partenaire approuvé. Les photos sont envoyées en multipart à partir des
octets de `XFile`, sans dépendre de `dart:io`. Les références de formulaire
sont lues directement dans l'API, sans cache SQLite.

Les prix de location peuvent être journaliers, mensuels ou les deux. Une pièce
d'occasion demande un véhicule donneur choisi dans l'inventaire partenaire.
L'API reste l'autorité pour la validation et les restrictions de propriété.

Tests ciblés :

```sh
flutter test test/partner_accounts test/features/partner_accounts
```

Ces tests isolent le transport et le stockage ou remplacent le repository
pour éprouver les formulaires. Ils ne constituent pas des captures du parcours
réel ni une preuve de connexion à un backend déployé. La validation réelle
demande le SDK opérationnel, l'API locale et l'exécution de l'application.
