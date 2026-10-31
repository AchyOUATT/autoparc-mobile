# Annonces de particuliers

Le workflow `.github/workflows/build-apk.yml` active le module dans ses deux
builds de publication, App Bundle et APK, avec
`--dart-define=ENABLE_PRIVATE_SALES=true`. Les prochaines versions compilées
par ce workflow afficheront donc le parcours particulier. Une version déjà
installée doit être mise à jour pour recevoir cette activation.

Un build lancé sans ce drapeau garde le module masqué. Pour le développement ou
un build manuel, passer aussi `--dart-define=ENABLE_PRIVATE_SALES=true`.
Le serveur doit activer `PRIVATE_SALES_ENABLED=true` après avoir appliqué les
migrations du module.

La saisie du véhicule reprend les sélecteurs du formulaire d’enregistrement :
`VehicleReferenceDropdown` est désormais partagé avec `VehicleRegisterPage`, et
`VehicleIdentityFields` compose marque, génération, finition, carburant, motricité,
couleur, boîte, année et kilométrage pour le parcours particulier. Les transitions
reposent sur `VehicleClassificationSelection`, déjà utilisé par le stock et le
garage. Le chargement passe par le même `catalogRefsProvider` et son cache.

L’annonce envoie les identifiants choisis, pas un titre libre. Le serveur valide
leurs relations et compose le titre et les libellés publics. Un modèle absent du
catalogue peut être saisi avec `model_libre`. Un changement de marque ou de modèle
efface les anciennes caractéristiques dépendantes ; aucun défaut technique n’est
présumé. Le préremplissage du garage ne transmet ni VIN, ni plaque, ni code moteur.

Entrées proposées, toutes conditionnées par cette constante :

- accueil : vendre / consulter les voitures de particuliers ;
- garage : vendre ce véhicule avec préremplissage choisi ;
- compte client : Mes annonces ;
- personnel autorisé : Valider les annonces depuis l’accueil.

Routes ajoutées : `/sell`, `/private-listings`, `/my-listings`,
`/private-listing-reviews`. La consultation reste séparée du catalogue de stock
existant ; son intégration définitive peut être décidée après examen.

Le client utilise sa session Firebase habituelle ; le personnel sa session
Sanctum existante. Le vendeur saisit son téléphone avec l’indicatif international.
Il n’y a pas de vérification par SMS : avant de publier, le personnel appelle
ce numéro et confirme que la personne a bien déposé l’annonce. Le serveur exige
cette confirmation, sauf si le numéro courant a déjà été vérifié par un appel.
Il reste seul juge de la vérification téléphonique et des droits de publication.

Interface initiale en français, comme l’espace partenaire existant. La traduction
anglaise du module reste à prévoir avant une diffusion aux utilisateurs anglophones.

Tests : `flutter test test/private_sales`. Les tests ne contactent ni Firebase,
ni l’API en ligne, ni un destinataire SMS. Les captures optionnelles utilisent
`PRIVATE_SALES_SCREENSHOTS` pour désigner un dossier local déjà créé.

Voir `docs/ventes-particuliers.md` dans la copie backend pour le contrat d’API,
les choix de confidentialité et la mise en route locale.
