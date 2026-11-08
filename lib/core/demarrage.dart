import 'package:go_router/go_router.dart';

/// Les trois règles du premier lancement, HORS de `main.dart`.
///
/// `_buildRouter` est privé, le seul banc qui monte `AutoParcApp` est `skip`
/// (Firebase), et la version précédente de `premiere_utilisation_test.dart`
/// asservissait une RECOPIE de la règle de départ — `demoVue ? '/' :
/// '/onboarding'` réécrit à la main — qui serait restée verte le jour où
/// `main.dart` aurait dit autre chose. Ces fonctions sont pures, publiques,
/// appelées par le routeur ET par les bancs : il n'y a plus qu'une règle.

/// Où l'application s'ouvre.
///
/// Tant que la porte de première utilisation n'est pas passée, sur la QUESTION
/// — « Je cherche ou je vends ? » —, et non plus sur la démonstration : c'est
/// la première chose à demander, parce que la réponse décide de tout le
/// reste. Le vendeur part ouvrir son compte ; l'acheteur voit les trois
/// diapositives, qui sont les siennes.
String destinationDeDepart({required bool demoVue}) =>
    demoVue ? '/' : '/bienvenue';

/// Le chemin de l'inscription vendeur : la page partenaire, onglet
/// Inscription. Un paramètre de requête et non `extra`, pour que le chemin se
/// suffise — il est la cible de la question du premier lancement, de la carte
/// « Vous vendez ? » de l'accueil et de la tuile du tiroir.
const String cheminInscriptionVendeur = '/partner?inscription=1';

/// `/partner?inscription=1` demande l'onglet Inscription ; tout le reste, la
/// connexion, qui est le cas courant.
bool inscriptionDemandee(Uri uri) => uri.queryParameters['inscription'] == '1';

/// Envoie le vendeur ouvrir son compte, AVEC le catalogue dessous.
///
/// ── POURQUOI `go` PUIS `push`, ET PAS AUTRE CHOSE ─────────────────────────
///
/// `go('/partner?…')` seul, ou `pushReplacement` depuis `/bienvenue`, donnent
/// une pile sans `/` : le Retour quitterait l'application depuis le
/// formulaire d'inscription, au tout premier contact. `go('/')` suivi de
/// `push(...)` donne `[/, /partner?inscription=1]`, et le Retour mène au
/// catalogue.
///
/// ── L'INVARIANT QUI REND LES DEUX APPELS SÛRS ─────────────────────────────
///
/// `GoRouter.push` lit `routerDelegate.currentConfiguration` AVANT tout
/// `await` ; `go` la pose de façon SYNCHRONE tant que le routeur n'a ni
/// `redirect` ni `onExit` asynchrone — vérifié dans go_router 14.8.1 :
/// `parseRouteInformationWithDependencies` rend une `SynchronousFuture` quand
/// la redirection est synchrone, et `setNewRoutePath` est appelé avant le
/// premier `await` de la transaction. Un seul `redirect` ou `onExit` qui
/// rendrait une `Future` dans `_buildRouter` ferait lire au `push` la base
/// périmée `[/bienvenue]`, ET abandonnerait la transaction du `go` : pile
/// `[/bienvenue, /partner]`, Retour vers la question. Le banc
/// `test/demarrage_test.dart` tient cet invariant sur le vrai routeur.
void ouvrirInscriptionVendeur(GoRouter routeur) {
  routeur.go('/');
  routeur.push(cheminInscriptionVendeur);
}
