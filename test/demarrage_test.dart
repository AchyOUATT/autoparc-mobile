import 'package:auto/core/demarrage.dart';
import 'package:auto/core/l10n/langue.dart';
import 'package:auto/features/onboarding/data/onboarding_service.dart';
import 'package:auto/features/onboarding/data/profil_service.dart';
import 'package:auto/features/onboarding/presentation/pages/choix_de_profil_page.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/main.dart' show routeurAutoParc;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La question du premier lancement, et ce qu'elle fait de la réponse.
///
/// ── CE QUE CE BANC FERME ──────────────────────────────────────────────────
///
/// Trois issues, trois effets chacune : le profil écrit (ou pas), la porte de
/// la démonstration marquée (ou pas), la destination. Les six mutations
/// évidentes — inverser acheteur et vendeur, oublier `markDone()` côté
/// vendeur, l'appeler côté acheteur, écrire un profil à « je ne sais pas »,
/// `go` au lieu de `go` puis `push`, et une pile sans le catalogue dessous —
/// tombent toutes ici.
///
/// La page est montée dans un routeur de BANC, dont les routes réutilisent
/// les fonctions de `core/demarrage.dart` : la destination lue est celle du
/// routeur, pas une recopie. Le VRAI routeur, lui, est construit (sans être
/// monté) dans le dernier groupe, pour tenir l'invariant dont dépend le double
/// saut du vendeur.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('inscriptionDemandee', () {
    test('seul `?inscription=1` demande l\'onglet Inscription', () {
      expect(inscriptionDemandee(Uri.parse('/partner?inscription=1')), isTrue);
      expect(inscriptionDemandee(Uri.parse('/partner')), isFalse);
      expect(inscriptionDemandee(Uri.parse('/partner?inscription=0')), isFalse);
      expect(
        inscriptionDemandee(Uri.parse('/partner?inscription=true')),
        isFalse,
      );
    });

    test('le chemin de l\'inscription vendeur le demande', () {
      expect(inscriptionDemandee(Uri.parse(cheminInscriptionVendeur)), isTrue);
    });
  });

  group('La question du premier lancement', () {
    late GoRouter routeur;
    late ProviderContainer conteneur;

    Future<void> poser(WidgetTester tester) async {
      routeur = GoRouter(
        initialLocation: destinationDeDepart(demoVue: false),
        routes: [
          GoRoute(
            path: '/bienvenue',
            builder: (_, _) => const ChoixDeProfilPage(),
          ),
          GoRoute(path: '/onboarding', builder: (_, _) => const Text('DEMO')),
          GoRoute(path: '/', builder: (_, _) => const Text('ACCUEIL')),
          GoRoute(
            path: '/partner',
            builder: (_, state) => Text(
              inscriptionDemandee(state.uri) ? 'INSCRIPTION' : 'CONNEXION',
            ),
          ),
        ],
      );
      addTearDown(routeur.dispose);

      final scope = ProviderScope(
        child: MaterialApp.router(
          routerConfig: routeur,
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpWidget(scope);
      await tester.pumpAndSettle();
      conteneur = ProviderScope.containerOf(
        tester.element(find.byType(ChoixDeProfilPage)),
      );
    }

    // Le chemin de la route DU DESSUS, et non `currentConfiguration.uri` :
    // mesuré, l'URI de la configuration reste celle du dernier `go` quand une
    // route est poussée par-dessus — `/` avec deux correspondances, et non
    // `/partner?…`. La profondeur dit si le catalogue est bien dessous.
    String destination() =>
        routeur.routerDelegate.currentConfiguration.last.matchedLocation;
    int profondeur() =>
        routeur.routerDelegate.currentConfiguration.matches.length;

    testWidgets('elle s\'ouvre sur la question, pas sur la démonstration', (
      tester,
    ) async {
      await poser(tester);

      expect(find.byType(ChoixDeProfilPage), findsOneWidget);
      expect(find.text('Bienvenue sur AutoParc'), findsOneWidget);
      expect(find.text('Je cherche'), findsOneWidget);
      expect(find.text('Je vends'), findsOneWidget);
      expect(find.text('Je ne sais pas encore'), findsOneWidget);
    });

    testWidgets(
      '« Je cherche » écrit acheteur, laisse la porte ouverte et montre la démonstration',
      (tester) async {
        await poser(tester);

        await tester.tap(find.byKey(const Key('profil-cherche')));
        await tester.pumpAndSettle();

        expect(destination(), '/onboarding');
        expect(find.text('DEMO'), findsOneWidget);
        expect(
          conteneur.read(profilUtilisateurProvider),
          ProfilUtilisateur.acheteur,
        );
        expect(
          await ProfilService.lire(),
          ProfilUtilisateur.acheteur,
          reason:
              'Le profil doit survivre au lancement suivant : c\'est lui '
              'qui décide de la carte « Vous vendez ? ».',
        );
        expect(
          await OnboardingService.isDone(),
          isFalse,
          reason:
              'C\'est la DÉMONSTRATION qui marque la porte, à sa dernière '
              'diapositive. La marquer ici ferait sauter les diapositives à '
              'un acheteur qui quitte l\'application au milieu.',
        );
      },
    );

    testWidgets(
      '« Je vends » écrit vendeur, marque la porte et ouvre l\'inscription SUR le catalogue',
      (tester) async {
        await poser(tester);

        await tester.tap(find.byKey(const Key('profil-vends')));
        await tester.pumpAndSettle();

        expect(destination(), '/partner');
        expect(
          find.text('INSCRIPTION'),
          findsOneWidget,
          reason:
              'L\'onglet Inscription est demandé par le chemin — c\'est '
              'le `?inscription=1` que la route du banc lit, comme la vraie.',
        );
        expect(
          profondeur(),
          2,
          reason:
              'Deux correspondances : le catalogue DESSOUS, l\'inscription '
              'dessus. Une seule voudrait dire `go` sans `push`, et le Retour '
              'quitterait l\'application depuis le formulaire.',
        );
        expect(
          conteneur.read(profilUtilisateurProvider),
          ProfilUtilisateur.vendeur,
        );
        expect(await ProfilService.lire(), ProfilUtilisateur.vendeur);
        expect(
          await OnboardingService.isDone(),
          isTrue,
          reason:
              'Le vendeur ne voit pas la démonstration, et rien d\'autre '
              'ne marquerait la porte : sans cela la question reviendrait à '
              'chaque lancement tant que l\'inscription n\'est pas finie.',
        );

        // Le Retour mène au catalogue, pas à la question.
        routeur.pop();
        await tester.pumpAndSettle();

        expect(destination(), '/');
        expect(find.text('ACCUEIL'), findsOneWidget);
      },
    );

    testWidgets(
      '« Je ne sais pas encore » n\'écrit RIEN et montre la démonstration',
      (tester) async {
        await poser(tester);

        // The optional buyer notice can move the last choice below the fold.
        await Scrollable.ensureVisible(
          tester.element(find.byKey(const Key('profil-indecis'))),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('profil-indecis')));
        await tester.pumpAndSettle();

        expect(destination(), '/onboarding');
        expect(
          conteneur.read(profilUtilisateurProvider),
          isNull,
          reason:
              'Un profil deviné vaut moins que pas de profil : le '
              'catalogue est le défaut universel, et le menu garde l\'espace '
              'partenaire.',
        );
        expect(await ProfilService.lire(), isNull);
        expect(await OnboardingService.isDone(), isFalse);
      },
    );

    testWidgets('le bouton de langue bascule la page dans l\'autre langue', (
      tester,
    ) async {
      await poser(tester);
      expect(
        find.text('English'),
        findsOneWidget,
        reason:
            'Sur l\'écran français, le bouton porte le nom de l\'AUTRE '
            'langue, dans sa propre graphie.',
      );

      await tester.tap(find.byKey(const Key('profil-langue')));
      await tester.pumpAndSettle();

      expect(conteneur.read(langueProvider), localeAnglais);
      expect(
        await LangueService.lire(),
        localeAnglais,
        reason: 'Le choix est écrit : l\'application rouvrira en anglais.',
      );
      // La page n'est PAS reconstruite par ce routeur de banc, dont le
      // `MaterialApp` ne suit pas `langueProvider` ; c'est `AutoParcApp` qui
      // porte `locale:` dans l'application. On vérifie donc l'état, pas le
      // rendu, et le rendu anglais est mesuré par `accueil_langues_test.dart`.
    });
  });

  /// Le vrai routeur, construit sans être monté.
  ///
  /// `ouvrirInscriptionVendeur` enchaîne `go('/')` et `push(...)` sans attendre
  /// entre les deux, et c'est sûr tant que `go` pose sa configuration de façon
  /// SYNCHRONE — c'est-à-dire tant qu'aucune route n'a d'`onExit` et qu'aucune
  /// redirection n'est asynchrone (voir le commentaire de la fonction). Les
  /// redirections sont donc NOMMÉES ici : en ajouter une est une décision à
  /// prendre en connaissance de cause, pas un effet de bord.
  group('Le vrai routeur', () {
    Iterable<GoRoute> toutes(List<RouteBase> routes) sync* {
      for (final route in routes) {
        if (route is GoRoute) yield route;
        yield* toutes(route.routes);
      }
    }

    test('ses routes du premier lancement existent', () {
      final routeur = routeurAutoParc(onboardingDone: false);
      addTearDown(routeur.dispose);
      final chemins = toutes(
        routeur.configuration.routes,
      ).map((r) => r.path).toSet();

      expect(
        chemins,
        containsAll([
          '/bienvenue',
          '/onboarding',
          '/',
          '/partner',
          '/partner/demandes',
        ]),
      );
    });

    test('il s\'ouvre là où la règle le dit', () {
      for (final demoVue in [false, true]) {
        final routeur = routeurAutoParc(onboardingDone: demoVue);
        addTearDown(routeur.dispose);

        expect(
          routeur.routeInformationProvider.value.uri.toString(),
          destinationDeDepart(demoVue: demoVue),
        );
      }
    });

    test('aucune route n\'a d\'onExit, et les redirections sont nommées', () {
      final routeur = routeurAutoParc(onboardingDone: false);
      addTearDown(routeur.dispose);
      final routes = toutes(routeur.configuration.routes).toList();

      expect(
        routes.where((r) => r.onExit != null).map((r) => r.path),
        isEmpty,
        reason:
            'Un `onExit` peut rendre une Future : `go` deviendrait '
            'asynchrone et le `push` qui le suit lirait une pile périmée.',
      );
      expect(
        routes.where((r) => r.redirect != null).map((r) => r.path).toList(),
        ['/partners/:id'],
        reason:
            'La seule redirection du routeur est synchrone, et elle est '
            'nommée ici. Une redirection de plus doit l\'être aussi — et '
            'rester synchrone.',
      );
    });
  });
}
