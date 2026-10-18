/// LES DEUX LISTES D'ÉCHELLES DE TEXTE, ET LA DÉCISION QUI LES SÉPARE.
///
/// ── LA RÈGLE, ÉCRITE UNE FOIS ET À UN SEUL ENDROIT ──────────────────────────
///
/// « On tient jusqu'à 1,5 et pas au-delà. »
///
/// L'application est IRRÉPROCHABLE jusqu'à l'échelle de texte 1,5 : rien de
/// tronqué, rien de rogné en silence, rien de caché. Au-delà — l'échelle 2,0,
/// le dernier cran d'Android — elle reste UTILISABLE et HONNÊTE, mais on cesse
/// d'optimiser pour ce cas et on cesse de compter ses défauts comme des échecs.
///
/// Cette décision vivait dans une conversation, et une décision qui ne vit que
/// là se fait re-arbitrer trois semaines plus tard par quelqu'un qui n'en
/// connaît pas le prix. Elle est donc ici, à l'endroit que les bancs lisent.
///
/// ── LA MESURE QUI L'A MOTIVÉE ───────────────────────────────────────────────
///
/// À 320 points de large avec le texte à 200 %, l'écran est déjà inutilisable
/// pour des raisons qui ne sont PAS les nôtres : le titre passe sur trois
/// lignes, le bouton flottant recouvre une carte entière, les libellés de
/// navigation se chevauchent. On voyait une annonce et demie.
///
/// Concevoir pour cette intersection — petit écran ancien ET dernier cran
/// d'Android — a déjà coûté TROIS CASES DE DENSITÉ POUR TOUT LE MONDE. Les
/// trois sont nommées dans `bandes_filtres_test.dart` : les pièces en 320×2,0
/// passent de 2 annonces entières à zéro, les accessoires en 411×2,0 de 4 à 2,
/// personnel comme client. Et `carte_geometrie_test.dart` en porte la trace
/// inverse : son tableau de densité rend 0 annonce entière en 320 dès
/// l'échelle 1,3, parce que la carte a été dessinée pour ne jamais tronquer au
/// dernier cran.
///
/// ── CE QUE CE N'EST PAS ─────────────────────────────────────────────────────
///
/// IL NE S'AGIT PAS DE BORNER L'ÉCHELLE DE TEXTE. On ne passe PAS outre le
/// réglage d'accessibilité de l'utilisateur :
/// `MediaQuery.withClampedTextScaling` et ses équivalents sont EXCLUS du code
/// de production comme des bancs. À 2,0 l'application reste intégralement
/// utilisable, défilable, et ne mentira pas. Elle est seulement moins dense et
/// moins belle.
///
/// La seule borne du dépôt est celle de `BarreNavigationPrincipale`, sur les
/// quatre intitulés de la barre du bas, et elle est antérieure à cette
/// décision — `navigation_bar_theme.dart` porte sa propre raison.
///
/// ── CE QUI RESTE NON NÉGOCIABLE À 2,0, ET C'EST LE POINT DÉLICAT ────────────
///
/// On continue de MESURER à 2,0 et d'IMPRIMER le relevé — cesser de regarder
/// est le seul moyen sûr de ne plus rien savoir. On n'y exige plus l'absence de
/// troncature ni de débordement. On y exige quatre choses :
///
///  1. L'ÉCRAN SE CONSTRUIT. Au moins un paragraphe peint : un banc qui mesure
///     un indicateur de chargement ne mesure rien.
///  2. RIEN NE JETTE. Aucune exception de mise en page, ni à la pose ni au
///     défilement — donc aucune bande rayée de `RenderFlex`.
///  3. ÇA DÉFILE. Ce qui ne tient pas sous le pli doit être ATTEIGNABLE. Un
///     écran moins dense reste utilisable ; un écran dont le bas est
///     inaccessible ne l'est pas.
///  4. AUCUNE INFORMATION N'EST RENDUE FAUSSE.
///
/// LE QUATRIÈME POINT DEMANDE SA DÉFINITION, parce que c'est lui qui distingue
/// une dégradation d'un mensonge. Un titre coupé est INCOMPLET : « Land Rover
/// Range Rov… » ne se lit pas comme le nom d'un autre véhicule, l'œil voit
/// qu'il manque quelque chose. Un NOMBRE coupé est FAUX : « 18 000 FC » se lit
/// comme un prix entier, et comme un AUTRE prix que celui du serveur. Rien ne
/// signale le manque, et la valeur lue est plausible.
///
/// Le critère retenu est donc celui-là, et non « c'est un prix » : un
/// paragraphe QUI PORTE UN CHIFFRE ne doit ni se déclarer tronqué, ni se
/// replier dans un segment insécable. Prix, kilométrage, compte de jours
/// restants, « +N » de la ligne de compatibilité : tous tombent sous la même
/// règle, et c'est voulu — « dépassée de 11 jours » rognée en « dépassée de
/// 1… » est du même défaut que le prix. Voir [porteUnNombre] dans
/// `mesures.dart`, qui est l'implémentation de cette phrase.
library;

/// L'échelle de texte jusqu'à laquelle l'application est tenue IRRÉPROCHABLE.
///
/// Le troisième cran des réglages Android. Le quatrième — 2,0 — est au-delà.
const double echelleTenue = 1.5;

/// Les échelles où l'absence de troncature et de débordement est ASSERTÉE.
///
/// 1,0 est le réglage par défaut, 1,3 le deuxième cran d'Android (« Grande
/// police »), 1,5 le troisième et le dernier que ce dépôt garantit.
const List<double> echellesAssertees = <double>[1.0, 1.3, echelleTenue];

/// Les échelles MESURÉES, relevé imprimé à chaque exécution.
///
/// 2,0 y est, et doit y rester : ne plus la mesurer serait cesser de regarder,
/// et personne ne saurait plus si une dégradation acceptée est devenue une
/// panne. Ce qu'on y asserte est la liste des quatre points en tête de ce
/// fichier, pas l'absence de défaut.
const List<double> echellesMesurees = <double>[1.0, 1.3, echelleTenue, 2.0];

/// Vrai quand [echelle] est dans le domaine où l'on EXIGE la perfection.
///
/// À écrire ainsi dans les bancs — `if (tenue(echelle)) { ... }` — plutôt que
/// `echelle <= 1.5` : la comparaison en dur se recopie, et le jour où le
/// propriétaire déplacera la frontière il faudra la retrouver partout.
bool tenue(double echelle) => echelle <= echelleTenue + 0.001;
