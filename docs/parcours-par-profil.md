# Parcours par profil : « je cherche » ou « je vends »

Livré le 7 novembre 2026, avec `GET /api/partner/dashboard` côté backend
(`autoparc-backend`, commits `4fd3926` à `147e00f`).

## Ce qui change pour qui

| Qui | Avant | Après |
|---|---|---|
| Installation neuve | La démonstration (trois diapositives), puis l'accueil. | La **question** d'abord : « Je cherche » ou « Je vends » (`/bienvenue`). L'acheteur voit ensuite la démonstration ; le vendeur part ouvrir son compte, le catalogue dessous pour le Retour. « Je ne sais pas encore » prend le chemin de l'acheteur sans rien écrire. |
| Partenaire connecté | L'accueil acheteur ; son espace derrière le menu. | Son **tableau de bord** en page d'accueil (`/`) : nom et statut, « À faire », trois inventaires chiffrés avec un « + », demandes clients, et la rangée de recherche de l'accueil en bas. Les quatre onglets du bas restent : il cherche comme tout le monde. |
| Partenaire en attente | Un écran de statut dans l'espace partenaire. | Le même tableau de bord, qui répond à trois questions — qui examine, comment on le saura, quoi faire en attendant — avec « Vérifier mon statut » et « Nous contacter ». Une notification est écrite à l'issue de l'examen ; il la lit sous « Demandes clients » s'il est approuvé, et apprend un refus par la réponse de connexion (ses jetons sont révoqués). |
| Vendeur déclaré sans compte | — | Sur l'accueil acheteur, la carte « Vous vendez ? » à la place de « Enregistrez votre véhicule » : « Ouvrir mon compte », « J'ai déjà un compte », « Pas maintenant » (qui écrit le profil acheteur). |
| Session vendeur rejetée ou suspendue | Retour à « Visiteur » sans un mot. | Une carte en tête de l'accueil, avec le statut et le motif, « Se reconnecter » et « J'ai compris ». |
| Installations existantes | — | Rien de nouveau pour les acheteurs ; les partenaires voient une ligne, une fois : « Votre accueil est maintenant votre tableau de bord ». La question n'est jamais posée après coup. |

## Ce qui ne bouge pas

- Les trois sessions restent indépendantes : personnel (`authProvider`), client Firebase, partenaire (`partnerSessionProvider`). Le profil déclaré n'est **pas** un rôle : une déclaration, qui ne donne aucun droit.
- Priorité à l'accueil, écrite dans `AccueilSelonProfil` : personnel, puis partenaire, puis acheteur.
- Le français existant ne bouge pas (`lib/l10n/CONVENTION.md`). Les textes du chemin « premier lancement » sont des clés **nouvelles** (`onboardingProfile*`, `partnerAccountsSellerIntro*`), lues seulement par ce chemin.
- L'application publiée (version 116) lit le serveur déployé sans rien perdre : la route du tableau de bord est additive, aucun champ n'est retiré.

## Mécanique

- **Première trame juste.** `main()` lit, avant `runApp`, la porte de la démonstration, la langue, le profil déclaré (`ProfilService`) et la session partenaire au coffre (`sessionPartenaireAuDemarrage`, délai de deux secondes, puis « on ne sait pas encore »). Le notifier partenaire part de cet état et vérifie ensuite.
- **Jamais d'écran vide.** L'accueil ne branche que sur `profile`, jamais sur `loading`, qui a quatre producteurs et peut durer soixante secondes sur une instance qui se réveille.
- **Le double saut du vendeur** — `go('/')` puis `push('/partner?inscription=1')` — est sûr tant que le routeur n'a ni `onExit` ni redirection asynchrone. `test/demarrage_test.dart` tient cet invariant sur le vrai routeur (construit, non monté) et nomme la seule redirection existante.
- **L'espace fermé est un écran.** Quand `GET /api/app/version` a répondu fermé (`espacePartenaireFermeProvider`), ou quand un appel partenaire rend 503 (`PartnerSession.espaceFerme`), la page partenaire remplace son formulaire par un panneau. « Inconnu » n'est pas « fermé » : sans réponse, le formulaire s'affiche.
- **Les compteurs peuvent manquer, la page non.** Un serveur antérieur à la route (404) ou un réseau coupé donnent un tiret et « Compteurs indisponibles », jamais le texte brut du serveur ; seul le 503 porte un motif lisible. Les cartes restent navigables.
- **Le drapeau serveur et l'entrée du tiroir.** L'entrée « Espace partenaire » est là tant que le serveur n'a pas dit *fermé* (`espacePartenaireFermeProvider`), et toujours pour un profil vendeur : l'inconnu n'est plus un refus, puisque la page sait expliquer un espace fermé et encaisser un 503. C'est ce qui tient la promesse du sous-titre de la question — « vous pourrez changer d'avis plus tard » — même quand l'instance dort le matin.
- **Par-dessus la coque.** Le tableau de bord vit dans la coque (`ShellRoute`) : ce qu'il ouvre — formulaires, inventaires, feuille de contact — passe par le Navigator racine (`rootNavigator: true`), sans quoi la barre du bas restait visible et touchable sous le formulaire, et un appui sur un onglet le détruisait. `test/partner_accounts/tableau_de_bord_dans_la_coque_test.dart` le tient.
- **Le refus réel est un 401 nu.** Quand le personnel refuse ou suspend un compte, ses jetons sont révoqués et `/partner/me` répond 401 sans statut : la session connue est alors marquée `revoked`, et l'accueil dit « votre session vendeur a été fermée » ; le motif vient à la reconnexion. Un 503 sur une session connue donne une carte « espace fermé » sur le tableau de bord, pas le texte brut du serveur.

## Bancs

`test/premiere_utilisation_test.dart` (porte, profil, règle de départ), `test/demarrage_test.dart` (les trois issues, le vrai routeur), `test/accueil_selon_profil_test.dart` (priorité, première trame injectée, carte vendeur et ses trois boutons, session fermée — 403 garni et 401 nu —, jamais d'écran vide), `test/partner_accounts/partner_dashboard_page_test.dart` (compteurs, pluriel de zéro, « À faire », compteurs manquants, 503), `test/partner_accounts/tableau_de_bord_dans_la_coque_test.dart` (par-dessus la coque), `test/partner_accounts/session_au_demarrage_test.dart` (lecture du coffre avant la première trame, ligne de bienvenue), `test/partner_accounts/partner_account_page_vendeur_test.dart` (intro vendeur, espace fermé, session révoquée), `test/tiroir_partenaire_test.dart`, `test/l10n_parite_test.dart`, et les poses de géométrie de `test/accueil_langues_test.dart` (320–411 points, texte ×1,0 à ×2,0, fr et en) pour la question, le tableau de bord et l'accueil vendeur. Le faux dépôt partagé vit dans `test/support/faux_depot_partenaire.dart`. Vingt-deux mutations ont été tuées, une par garde.

## À décider par le propriétaire

- Le délai d'examen annoncé au vendeur en attente (le texte dit « vous appelle si besoin », sans délai).
- Qui, dans l'équipe, appelle les vendeurs et approuve les comptes au quotidien.
- Le push vers les partenaires : aucune route partenaire n'enregistre de jeton FCM aujourd'hui ; la notification d'examen est lisible dans l'application seulement.
