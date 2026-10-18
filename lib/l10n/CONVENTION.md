# Les clés `.arb` — la convention, et ce qu'elle coûte de changer

Ce fichier existe parce que la convention de nommage est la décision du lot de
fondation qui coûtera le plus cher à défaire : au dernier comptage, **91 des 94
fichiers de `lib/` portent du français en dur**, pour un volume estimé entre
1 200 et 1 500 chaînes. Une clé renommée après coup, c'est un renommage dans
`app_fr.arb`, dans `app_en.arb`, dans le code appelant, et dans tout banc qui
l'assertait.

## La règle

    <zone><Rôle>        en lowerCamelCase, sans séparateur

- **`<zone>`** est le dossier de `lib/features/` (ou `shell` / `common`), en
  **anglais**, exactement comme le dossier : `home`, `catalog`, `garage`,
  `cart`, `needs`, `auth`, `partners`, `notifications`, `onboarding`,
  `vehicles`.
- **`<Rôle>`** décrit la FONCTION de la chaîne dans l'écran, pas son texte :
  `homeAddVehicleCta`, et non `homeAjouterMaVoiture`.

Exemples tels qu'ils existent aujourd'hui :

| clé | fr | en |
|---|---|---|
| `commonHome` | Accueil | Home |
| `commonCancel` | Annuler | Cancel |
| `shellExitTitle` | Quitter AutoParc ? | Quit AutoParc? |
| `shellContactDialerTarget` | le composeur | the phone app |
| `catalogPartListTitle` | Pièces détachées | Spare parts |
| `homeDealsSection` | Bonnes affaires | Good deals |
| `homeDeadlineOverdue` | {label} dépassée depuis {days, plural, …} | {label} overdue by {days, plural, …} |

Au terme de ce lot, `app_fr.arb` et `app_en.arb` portent **51 clés** chacun :
10 `common`, 22 `shell`, 16 `home`, 2 `update`, 1 `catalog`.

## Pourquoi celle-là

1. **La zone en préfixe, parce que le volume est le problème.** À 1 300 clés
   dans un espace de noms PLAT — `gen-l10n` ne connaît pas les sous-objets —,
   le préfixe est le seul mécanisme de cloisonnement disponible. Il donne
   aussi la direction inverse, qui est celle dont on se sert vraiment : devant
   `homeDealsSection` on sait ouvrir `lib/features/home/`, et un `grep '"home'`
   sur l'`.arb` rend l'inventaire d'un écran.

2. **La zone calquée sur le dossier, et pas sur l'écran.** Un écran est
   renommé, déplacé, scindé en deux ; le dossier de la fonctionnalité bouge
   beaucoup moins. `catalogVehicleListTitle` survit à un fichier renommé,
   `vehicleSearchPageTitle` ne survit pas à l'écran qui change de nom.

3. **Le rôle et jamais le texte.** C'est la règle qui rend la convention
   utile plus tard : `commonCancel` reste juste le jour où le français passe
   de « Annuler » à « Abandonner », alors qu'une clé `annuler` deviendrait un
   mensonge — et une clé mensongère dans un `.arb` n'est signalée par aucun
   outil.

4. **`common` est un privilège, pas un fourre-tout.** Une chaîne n'y entre
   qu'à **trois sites d'appel dans au moins deux zones**. La raison est le
   chemin de sortie : le jour où l'« Annuler » d'une boîte de dialogue doit
   devenir « Undo » et celui d'un formulaire rester « Cancel », scinder une clé
   partagée par quarante sites veut dire les auditer tous. En dessous de trois
   sites, la duplication coûte un doublon dans deux `.arb` ; au-dessus, elle
   coûte quarante relectures.

5. **Pas de `_` ni de `.`.** `gen-l10n` fabrique un getter Dart par clé :
   `home_title` donnerait `l10n.home_title` et un avertissement
   `non_constant_identifier_names` à chaque appel.

## Ce qui n'est PAS dans les `.arb`, et ne doit pas y entrer

Le serveur envoie du texte déjà libellé — `deal_label` (« Bonne affaire »),
les libellés d'échéance (« Visite technique »), les intitulés de carburant
(« Essence », « Électrique »), les noms de catégories. **Ces chaînes restent
en français quelle que soit la langue choisie**, parce qu'elles n'existent pas
dans l'application : c'est la vague serveur qui les traduira. Leur ajouter une
clé `.arb` ici ne les traduirait pas, cela dupliquerait seulement un texte que
le serveur continuerait d'écrire lui-même.
