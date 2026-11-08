# Récupération de mot de passe

Le bouton « Mot de passe oublié ? » apparaît uniquement dans les formulaires de
connexion, dans la page de connexion générale et dans l'espace partenaire. Il
ouvre un écran traduit en français et en anglais et conserve un email déjà saisi.
Un numéro de téléphone n'est jamais recopié dans le champ email.

Dans la connexion générale, la personne choisit **Client** ou **Personnel
AutoParc**. Depuis l'espace partenaire, le type est fixé à **Partenaire**.

- **Client** : Firebase envoie le lien dans la langue de l'application. Sa page
  hébergée permet de choisir le nouveau mot de passe dans le navigateur. Pour une
  connexion Google, l'écran invite à continuer avec Google ; la récupération du
  mot de passe Google reste gérée par Google.
- **Partenaire et personnel** : `POST /api/auth/password/forgot` reçoit `email`,
  `account_type` (`partner` ou `staff`) et `locale` (`fr` ou `en`). Le serveur
  AutoParc envoie le lien vers son formulaire web. Un transport d'email réel doit
  être configuré côté serveur ; une indisponibilité d'envoi est affichée comme
  telle, sans confirmation trompeuse.
- **Partenaire sans email ou email inaccessible** : l'écran permet d'appeler
  AutoParc ou d'ouvrir WhatsApp au numéro paramétré depuis le back-office. La
  récupération est assistée, après vérification d'identité. Un numéro simplement
  saisi dans l'application ne suffit pas pour changer un mot de passe.

La confirmation reste volontairement identique lorsqu'aucun compte ne correspond.
Les erreurs réseau et les limitations de demandes permettent de réessayer. Les
boutons de contact restent disponibles lorsque l'envoi du lien échoue.

Cette opération n'authentifie personne et ne modifie ni les sessions mobiles, ni
le rôle d'un compte, ni l'accès au garage. Après avoir choisi le nouveau mot de
passe dans le navigateur, la personne revient se connecter dans l'application.

Validation ciblée : `flutter test test/password_recovery_test.dart`.
