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

```
AutoParc réunit ce qu'il faut pour acheter, louer et entretenir un véhicule au
Burkina Faso.

ACHETER ET LOUER
Parcourez les véhicules disponibles : marque, modèle, année, kilométrage,
finition, motorisation, équipements et photos. Les prix sont affichés, à la
vente comme à la location — journalière, hebdomadaire ou mensuelle. Un appel ou
un message WhatsApp suffit à joindre le vendeur depuis la fiche.

PIÈCES ET ACCESSOIRES
Le catalogue couvre les pièces détachées et les accessoires, avec leur
disponibilité en stock, leur état — neuf, reconditionné, occasion — et leur
référence constructeur. La recherche par numéro OEM retrouve une pièce à partir
de la référence lue sur l'ancienne.

MON GARAGE
Enregistrez vos véhicules et l'application vous dit quelles pièces vont dessus.
La compatibilité se calcule sur le modèle, l'année et la motorisation : plus la
fiche est complète, plus la liste est juste. Le numéro de série (VIN) se décode
automatiquement pour remplir le formulaire à votre place.

NE PLUS RIEN OUBLIER
Visite technique, assurance, vidange : indiquez les dates et le kilométrage, et
AutoParc vous prévient avant l'échéance. La page d'accueil met en avant le
véhicule qui réclame votre attention, et affiche en clair ce qui est dépassé.

VOUS NE TROUVEZ PAS ?
Décrivez ce que vous cherchez — un modèle précis, une pièce, un budget. La
demande arrive chez nous, et nous revenons vers vous quand nous l'avons.

AutoParc est utilisable sans compte pour consulter le catalogue. Un compte n'est
demandé qu'au moment d'enregistrer un véhicule, parce qu'un rappel a besoin d'un
destinataire. Il se supprime depuis l'application, à tout moment.
```

### Éléments graphiques

| Élément | Fichier | Contrainte |
|---|---|---|
| Icône | `assets/icon/play_icone_512.png` | 512×512, PNG 32 bits, sans transparence |
| Bandeau | `assets/icon/play_banniere_1024x500.png` | 1024×500 exactement |
| Captures téléphone | à produire | 2 minimum, 8 maximum, format 16:9 ou 9:16 |

Les captures manquent. Les plus parlantes, dans l'ordre : l'accueil avec un
véhicule et son échéance dépassée, la liste des pièces compatibles, la fiche
d'un véhicule, le formulaire d'ajout au garage.

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

Les autorisations `CAMERA` et `READ_MEDIA_IMAGES` existent pour que le personnel
photographie un véhicule ou une pièce. Aucun écran client n'y mène — le
téléversement n'est atteint que depuis les pages d'ajout de véhicule, de pièce
et d'accessoire, réservées au personnel.

Le formulaire raisonne néanmoins sur ce que l'application *peut faire*, pas sur
qui s'en sert. **Déclarer** est donc le choix prudent : c'est vrai, et cela évite
d'avoir à s'expliquer. Décocher ne serait défendable que si ces écrans
disparaissaient de l'application cliente.

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
