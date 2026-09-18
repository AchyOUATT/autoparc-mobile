# Publication sur Google Play

Aide-mémoire pour remplir la console. Chaque réponse ci-dessous est établie sur
le code, pas sur une supposition — les sources sont citées quand la réponse n'a
rien d'évident.

> **Une déclaration inexacte dans « Sécurité des données » se sanctionne par une
> suspension**, même après publication, et même de bonne foi. C'est la section à
> lire en entier avant de cocher quoi que ce soit.

---

## 1. Fiche du magasin

### Nom de l'application — 30 caractères

```
AutoParc
```

### Description courte — 80 caractères

Elle s'affiche sous le nom, dans les résultats de recherche. C'est la seule
phrase que beaucoup liront.

```
Véhicules, pièces et accessoires au Burkina — et le carnet de votre voiture.
```

*(76 caractères.)*

### Description longue — 4 000 caractères maximum

*(2202 caractères. Ne promet que ce qui existe : le VIN se **saisit**, il ne se scanne pas.)*

```
AutoParc réunit tout ce qu'il faut pour acheter, louer et entretenir un véhicule au Burkina Faso : un catalogue de véhicules, de pièces détachées et d'accessoires, et un carnet d'entretien qui vous prévient avant chaque échéance.

🚗 ACHETER OU LOUER UN VÉHICULE
• Des véhicules à la vente et à la location, avec leur prix en FCFA
• Location à la journée, à la semaine ou au mois
• Filtres par offre (à vendre, à louer, bonnes affaires) et par carrosserie : berline, SUV/4x4, citadine…
• Chaque fiche détaille la marque, le modèle, l'année, le kilométrage, la finition, la motorisation, la transmission et les équipements
• Joignez le vendeur en un geste, par appel ou par WhatsApp

🔧 PIÈCES DÉTACHÉES ET ACCESSOIRES
• Freinage, filtration, distribution, suspension, électricité, carrosserie…
• Disponibilité en stock et état de chaque pièce : neuve, reconditionnée ou d'occasion
• Retrouvez une pièce à partir de sa référence constructeur (numéro OEM)
• Accessoires de confort, de sécurité et d'esthétique
• Remplissez votre panier et passez commande par WhatsApp

🏠 MON GARAGE
• Enregistrez un ou plusieurs véhicules
• Saisissez le numéro de châssis (VIN) : le formulaire se remplit tout seul
• AutoParc vous montre les pièces compatibles avec chacun de vos véhicules
• L'application vous aide à choisir la bonne génération de modèle, et vous prévient si elle ne correspond pas à l'année de votre voiture

🔔 NE PLUS RIEN OUBLIER
• Visite technique, assurance, vidange : indiquez les dates et le kilométrage
• Recevez un rappel avant chaque échéance
• L'accueil met en avant le véhicule qui demande votre attention, et affiche clairement ce qui est dépassé

🔎 VOUS NE TROUVEZ PAS ?
Décrivez ce que vous cherchez : un véhicule, une pièce, un budget. Votre demande nous parvient directement, et nous revenons vers vous dès que nous l'avons.

🔒 VOS DONNÉES
• Consultez tout le catalogue sans créer de compte
• Un compte n'est demandé que pour enregistrer un véhicule et recevoir vos rappels
• Aucune publicité, aucun suivi de votre activité
• Supprimez votre compte et vos données à tout moment, depuis l'application

AutoParc — Ouagadougou, Burkina Faso
Une question, une suggestion ? achyouatt@gmail.com
```

### Éléments graphiques

| Élément | Fichier | Contrainte |
|---|---|---|
| Icône | `assets/icon/play_icone_512.png` | 512×512, PNG 32 bits, sans transparence |
| Bandeau | `assets/icon/play_banniere_1024x500.png` | 1024×500 exactement |
| Captures téléphone | `docs/captures/play-*.png` (4 fichiers) | 2 minimum, 8 maximum, format 16:9 ou 9:16 |

Les captures montrent encore les données de démonstration : à refaire avec de
vraies photos de véhicules avant la production (voir `docs/captures/README.md`).

### Catégorie et coordonnées

- Catégorie : **Achats** (ou *Automobile et véhicules* si la liste le propose).
- Courriel d'assistance : le même que dans la politique de confidentialité.
- Politique de confidentialité : `https://achyouatt.github.io/autoparc-mobile/confidentialite.html`
- **URL de suppression de compte** :
  `https://achyouatt.github.io/autoparc-mobile/suppression-compte.html`

Les deux demandent que **GitHub Pages soit activé** sur `main` / dossier
`/docs`. Play teste les liens : une page introuvable fait rejeter la fiche.

La page de suppression est réclamée séparément de la politique de
confidentialité, dans *Sécurité des données*. Elle doit s'ouvrir **sans
connexion** — quelqu'un qui a désinstallé l'application doit pouvoir demander
la suppression — et énumérer ce qui est effacé, ce qui est conservé et pour
combien de temps.

---

## 2. Sécurité des données

Le formulaire pose trois questions par type de donnée : est-elle **collectée**,
est-elle **partagée** avec des tiers, est-elle **obligatoire**. Voici les
réponses, avec ce qui les justifie dans le code.

### Réponses générales

| Question | Réponse | Pourquoi |
|---|---|---|
| Les données sont-elles chiffrées en transit ? | **Oui** | L'API est en HTTPS ; le trafic en clair n'est autorisé que dans les manifestes *debug* et *profile*, jamais en production. |
| Les utilisateurs peuvent-ils demander la suppression de leurs données ? | **Oui** | *Mon garage* → menu du compte → *Supprimer mon compte*, et par courriel. |
| L'application contient-elle des publicités ? | **Non** | Aucune régie, aucun SDK publicitaire dans `pubspec.yaml`. |
| Y a-t-il des achats intégrés ? | **Non** | Aucun paiement dans l'application : les commandes partent par WhatsApp. |
| Les utilisateurs peuvent-ils communiquer entre eux ? | **Non** | Les demandes vont au personnel, jamais à d'autres utilisateurs. |

### Données collectées

| Type Google | Collectée | Partagée | Obligatoire | Finalité | D'où elle vient |
|---|---|---|---|---|---|
| **Informations personnelles → Adresse e-mail** | Oui | Non | Oui | Fonctionnalité de l'application, gestion du compte | Firebase Authentication |
| **Informations personnelles → Nom** | Oui | Non | Non | Fonctionnalité de l'application | Fourni par le fournisseur d'identité, ou saisi dans une demande |
| **Informations personnelles → Numéro de téléphone** | Oui | Non | Non | Fonctionnalité de l'application | Champ facultatif de « mes besoins » (`customer_needs.contact_phone`) |
| **Informations personnelles → ID utilisateur** | Oui | Non | Oui | Fonctionnalité, gestion du compte | UID Firebase, clé de rattachement de toutes les données client |
| **Informations personnelles → Autres informations** | Oui | Non | Non | Fonctionnalité de l'application | **VIN et plaque d'immatriculation** des véhicules du garage — tous deux facultatifs |
| **Identifiants d'appareil** | Oui | Non | Non | Fonctionnalité de l'application | Jeton FCM (`client_fcm_tokens`), pour envoyer les rappels d'échéance |
| **Photos et vidéos** | Oui | Non | Non | Fonctionnalité de l'application | Téléversées par le personnel pour illustrer le catalogue |

### Données **non** collectées — à laisser décochées

- **Position** — l'application ne demande aucune autorisation de localisation.
- **Informations financières** — aucun paiement n'a lieu dans l'application.
- **Contacts, agenda, SMS, fichiers, audio** — aucune autorisation correspondante.
- **Journaux de plantage et diagnostics** — Crashlytics n'est pas intégré. Le
  journal d'erreurs de l'application reste sur l'appareil et n'est envoyé nulle
  part.
- **Activité dans l'application** — aucun outil de mesure d'audience (voir
  ci-dessous).

### Firebase Analytics : retiré

`android/app/build.gradle.kts` déclarait `firebase-analytics`, collé depuis
l'assistant de la console Firebase. Aucune ligne de Dart ne l'appelait, mais la
bibliothèque recueillait d'elle-même ouvertures, sessions, modèle d'appareil et
pays — une collecte qu'il aurait fallu déclarer ici.

Elle a été retirée, et le retrait vérifié de deux façons :

- **dans l'arbre des dépendances** : le moteur de mesure
  (`play-services-measurement`, `-impl`, `-sdk`) n'y figure plus. Seule reste
  `firebase-measurement-connector`, une interface dont `firebase-messaging` se
  sert *si* Analytics est présent, et qui sans lui ne fait rien ;
- **sur un appareil vierge** : ni base `google_app_measurement_local.db`, ni
  préférences `measurement`, ni une seule ligne sous les balises `FA`.

Pour le revérifier après une mise à jour de dépendances :

```bash
cd android && ./gradlew :app:dependencies --configuration releaseRuntimeClasspath | grep play-services-measurement
```

Rien ne doit sortir, hormis `-base` et `-sdk-api`. Si le moteur réapparaît — un
greffon peut l'amener avec lui —, il faudra soit le retirer, soit cocher
*Activité dans l'application* et mettre à jour la politique de confidentialité.

### Le cas des photos

Le personnel photographie les véhicules et les pièces du catalogue. Aucun écran
client n'y mène — le téléversement n'est atteint que depuis les pages d'ajout de
véhicule, de pièce et d'accessoire, réservées au personnel.

Seule l'autorisation `CAMERA` est demandée. **Aucun accès étendu aux photos** :
la galerie passe par le sélecteur de photos d'Android (`useAndroidPhotoPicker`
activé dans `main.dart`), qui ne transmet que les images choisies et ne requiert
aucune autorisation.

`READ_MEDIA_IMAGES` était déclarée auparavant. Play a bloqué la version 45 pour
cette raison — depuis Android 13, les autorisations étendues aux photos et vidéos
ne sont admises que si un sélecteur système ne suffit pas. Elle est désormais
retirée, avec `READ_MEDIA_VIDEO` et `READ_EXTERNAL_STORAGE`, par
`tools:node="remove"` dans le manifeste : un greffon ne peut plus la ramener.

Côté *Sécurité des données*, les photos restent **collectées** — le personnel les
téléverse —, indépendamment de toute autorisation. Le formulaire raisonne sur ce
que l'application fait, pas sur qui s'en sert : déclarer est le choix exact.

---

## 3. Classification du contenu

Questionnaire IARC. Les réponses attendues, l'application ne contenant ni
violence, ni contenu sexuel, ni jeux d'argent, ni substances :

- Violence, sexualité, langage grossier, substances, jeux d'argent : **non** à tout.
- Les utilisateurs peuvent-ils communiquer entre eux : **non**.
- L'application partage-t-elle la position : **non**.
- Permet-elle d'acheter des biens : **oui**, hors de l'application (mise en
  relation par téléphone et WhatsApp).

Classification attendue : **Tous publics**.

## 4. Public cible

**18 ans et plus.** L'application sert à acheter, louer et entretenir un
véhicule ; la politique de confidentialité indique déjà qu'elle s'adresse à des
personnes majeures. Ce choix évite en outre les obligations supplémentaires du
programme *Familles*.

## 5. Pays de distribution

Burkina Faso au minimum. Les pays voisins — Côte d'Ivoire, Mali, Niger, Togo,
Bénin, Ghana — se justifient si les véhicules importés y transitent ; à décider
selon l'activité réelle, pas par défaut.

---

## 6. Avant d'envoyer

- [ ] Clé de signature créée et sauvegardée **hors de cette machine**
- [ ] Quatre secrets GitHub renseignés (voir le README) et build vert
- [ ] `[RESPONSABLE]`, `[EMAIL]`, `[ADRESSE]` remplacés dans `docs/confidentialite.html`
- [ ] GitHub Pages activé, URL de la politique accessible depuis un navigateur
- [ ] Mots de passe du personnel changés en production (`staff:rotate-password --all`)
- [ ] `db:seed --class=VehicleModelsSeeder --force` puis `catalog:backfill-fitments --fresh` passés en production
- [ ] Captures d'écran produites
- [ ] Inscription à **Play App Signing** au premier envoi
- [ ] `versionCode` incrémenté dans `pubspec.yaml` à chaque nouvel envoi
- [x] Firebase Analytics retiré — revérifier après chaque mise à jour de greffon (section 2)

## 7. Le délai auquel personne ne pense

Pour un compte développeur **personnel** créé récemment, Google impose un test
fermé avec un nombre minimal de testeurs pendant plusieurs jours avant
d'autoriser la production. Un compte **organisation** en est dispensé, mais
demande un numéro D-U-N-S, dont l'obtention prend elle-même du temps.

Cette règle a changé plusieurs fois : **vérifier celle en vigueur au moment de
l'inscription**. Elle pèse davantage sur le calendrier que tout le reste de
cette liste.
