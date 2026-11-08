import 'dart:async';

import 'package:auto/core/demarrage.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/home/presentation/pages/accueil_selon_profil.dart';
import 'package:auto/features/home/presentation/pages/home_page.dart';
import 'package:auto/features/home/presentation/providers/home_providers.dart';
import 'package:auto/features/onboarding/data/profil_service.dart';
import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:auto/features/partner_accounts/presentation/partner_dashboard_page.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/faux_depot_partenaire.dart';

/// Ce que la route `/` affiche, selon qui tient le téléphone.
///
/// ── CE QUE CE BANC FERME ──────────────────────────────────────────────────
///
/// La priorité écrite — personnel, puis partenaire, puis acheteur — et les
/// deux cas où l'accueil acheteur doit PARLER : une session vendeur rejetée,
/// un coffre qui n'a pas pu être confirmé. Et la carte « Vous vendez ? » : à
/// qui elle s'adresse, et comment elle s'en va.
///
/// Chaque groupe porte un cas POSITIF (le tableau de bord ou la carte sont
/// TROUVÉS) : un banc uniquement négatif resterait vert le jour où l'accueil
/// rendrait toujours `HomePage`.
///
/// L'écran ne doit JAMAIS être vide : un coffre d'avant le profil enregistré,
/// avec un serveur qui ne répond pas, rend l'accueil acheteur — pas un blanc
/// jusqu'au délai réseau de soixante secondes. C'est le dernier test.
class _FauxAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FauxAuth(super.etat);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'tableau_de_bord_presente': true}));

  Future<void> ouvrir(
    WidgetTester tester, {
    required FauxDepotPartenaire depot,
    AuthState session = const AuthState(type: AuthType.none),
    ProfilUtilisateur? profil,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((_) => _FauxAuth(session)),
          partnerRepositoryProvider.overrideWithValue(depot),
          profilInitialProvider.overrideWithValue(profil),
          homeDealsProvider.overrideWith((_) async => const []),
        ],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccueilSelonProfil(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const employe = StaffUser(id: 1, name: 'Awa Traoré', email: 'awa@autoparc.bf', role: 'admin');

  group('La priorité', () {
    testWidgets('sans session partenaire : l\'accueil acheteur', (tester) async {
      await ouvrir(tester, depot: FauxDepotPartenaire());

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(PartnerDashboardPage), findsNothing);
      expect(find.byKey(const Key('accueil-carte-vendeur')), findsNothing);
    });

    testWidgets('avec une session partenaire : le tableau de bord', (tester) async {
      await ouvrir(tester, depot: FauxDepotPartenaire()..profilAuCoffre = profilDeBanc());

      expect(find.byType(PartnerDashboardPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(find.text('Garage Exemple'), findsOneWidget);
    });

    testWidgets('en attente d\'approbation aussi : le tableau de bord', (tester) async {
      await ouvrir(tester, depot: FauxDepotPartenaire()..profilAuCoffre = profilDeBanc(status: 'pending'));

      expect(find.byType(PartnerDashboardPage), findsOneWidget);
      expect(find.text('Votre demande est en cours d\'examen'), findsOneWidget);
    });

    testWidgets('le personnel passe devant le partenaire', (tester) async {
      await ouvrir(
        tester,
        depot: FauxDepotPartenaire()..profilAuCoffre = profilDeBanc(),
        session: const AuthState(type: AuthType.staff, staffUser: employe),
      );

      expect(find.byType(HomePage), findsOneWidget,
          reason: 'Un employé qui a aussi un compte partenaire d\'essai garde '
              'son accueil : le tableau de bord reste à un appui du tiroir.');
      expect(find.byType(PartnerDashboardPage), findsNothing);
    });
  });

  group('La carte « Vous vendez ? »', () {
    testWidgets('s\'adresse au profil vendeur sans session, À LA PLACE de la carte garage', (
      tester,
    ) async {
      await ouvrir(tester, depot: FauxDepotPartenaire(), profil: ProfilUtilisateur.vendeur);

      expect(find.byKey(const Key('accueil-carte-vendeur')), findsOneWidget);
      expect(find.text('Vous vendez ?'), findsOneWidget);
      expect(find.text('Ouvrir mon compte'), findsOneWidget);
      expect(find.text('J\'ai déjà un compte'), findsOneWidget);
      expect(find.text('Enregistrez votre véhicule'), findsNothing,
          reason: 'Deux cartes d\'appel empilées repousseraient les bonnes '
              'affaires sous le pli à 320 points.');
    });

    testWidgets('ne s\'adresse pas à l\'acheteur, ni à qui n\'a rien dit', (
      tester,
    ) async {
      for (final profil in [ProfilUtilisateur.acheteur, null]) {
        await ouvrir(tester, depot: FauxDepotPartenaire(), profil: profil);

        expect(find.byKey(const Key('accueil-carte-vendeur')), findsNothing,
            reason: 'profil = $profil');
        expect(find.byKey(const Key('accueil-carte-vendeur')), findsNothing);
      }
    });

    testWidgets('« Pas maintenant » écrit le profil acheteur, et la carte s\'en va', (
      tester,
    ) async {
      await ouvrir(tester, depot: FauxDepotPartenaire(), profil: ProfilUtilisateur.vendeur);

      await tester.ensureVisible(find.byKey(const Key('accueil-vendeur-pas-maintenant')));
      await tester.tap(find.byKey(const Key('accueil-vendeur-pas-maintenant')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('accueil-carte-vendeur')), findsNothing);
      expect(find.byKey(const Key('accueil-carte-vendeur')), findsNothing);
      expect(await ProfilService.lire(), ProfilUtilisateur.acheteur,
          reason: 'C\'est le chemin promis pour changer d\'avis : il doit '
              'tenir au lancement suivant.');
    });
  });

  group('Une session vendeur qui n\'a pas tenu', () {
    testWidgets('rejetée par le serveur : l\'accueil acheteur le dit, avec le motif', (
      tester,
    ) async {
      final depot = FauxDepotPartenaire()
        ..profilAuCoffre = profilDeBanc()
        ..reponseGetMe = () async => throw const PartnerApiException(
              'Votre compte partenaire a été suspendu.',
              statusCode: 403,
              accountStatus: 'suspended',
              reviewReason: 'Annonces trompeuses',
              code: 'account_disabled',
            );
      await ouvrir(tester, depot: depot);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byKey(const Key('accueil-session-vendeur-fermee')), findsOneWidget);
      expect(find.text('Votre session vendeur a été fermée'), findsOneWidget);
      expect(find.text('Compte suspendu'), findsOneWidget);
      expect(find.text('Motif : Annonces trompeuses'), findsOneWidget);
      expect(find.text('Se reconnecter'), findsOneWidget);
      expect(find.text('Visiteur'), findsNothing);

      await tester.tap(find.byKey(const Key('accueil-session-vendeur-compris')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('accueil-session-vendeur-fermee')), findsNothing);
    });

    testWidgets('un coffre d\'avant le profil, non confirmé : un bandeau et « Réessayer »', (
      tester,
    ) async {
      final depot = FauxDepotPartenaire()
        ..coffre = const PartnerSessionStockee(token: 'jeton-d-avant')
        ..reponseGetMe = () async => throw const PartnerApiException(
              'Erreur du serveur.',
              statusCode: 500,
            );
      await ouvrir(tester, depot: depot);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byKey(const Key('accueil-session-vendeur-a-confirmer')), findsOneWidget);
      expect(find.text('Session vendeur à confirmer'), findsOneWidget);

      final avant = depot.appels.where((a) => a == 'coffre').length;
      await tester.tap(find.byKey(const Key('accueil-session-vendeur-reessayer')));
      await tester.pumpAndSettle();

      expect(depot.appels.where((a) => a == 'coffre').length, avant + 1,
          reason: '« Réessayer » relance la lecture du coffre, puis la '
              'vérification.');
    });

    testWidgets('un coffre d\'avant le profil, serveur muet : JAMAIS un écran vide', (
      tester,
    ) async {
      final depot = FauxDepotPartenaire()
        ..coffre = const PartnerSessionStockee(token: 'jeton-d-avant')
        ..porteGetMe = Completer<PartnerProfile>();
      await ouvrir(tester, depot: depot);

      expect(find.byType(HomePage), findsOneWidget,
          reason: 'Cet état dure jusqu\'au délai réseau — soixante secondes '
              'sur une instance qui se réveille. Un accueil, pas un blanc.');
      expect(find.byKey(const Key('accueil-carte-vendeur')), findsNothing);
    });

    /// LE CHEMIN RÉEL D'UN REFUS. Quand le personnel refuse ou suspend un
    /// compte, il révoque ses jetons : `/partner/me` répond 401 NU, sans
    /// statut ni motif. Le banc précédent, avec un 403 garni, ne passait pas
    /// par là — et la carte ne s'affichait donc jamais en production.
    testWidgets('révoquée par un 401 nu : la carte s\'affiche quand même, sans statut', (
      tester,
    ) async {
      final depot = FauxDepotPartenaire()
        ..profilAuCoffre = profilDeBanc()
        ..reponseGetMe = () async => throw const PartnerApiException(
              'Unauthenticated.',
              statusCode: 401,
            );
      await ouvrir(tester, depot: depot);

      expect(find.byKey(const Key('accueil-session-vendeur-fermee')), findsOneWidget);
      expect(find.text('Votre session vendeur a été fermée'), findsOneWidget);
      expect(find.text('Reconnectez-vous pour connaître l\'état de votre compte.'), findsOneWidget);
      expect(find.text('Compte suspendu'), findsNothing);
      expect(find.text('Demande refusée'), findsNothing);
      expect(find.text('Visiteur'), findsNothing);
    });

    testWidgets('un 401 sans session connue n\'est pas une session fermée', (tester) async {
      // Un jeton seul au coffre, d'avant le profil enregistré, et le serveur
      // le refuse : il n'y a rien à annoncer comme « fermé », on ne savait
      // rien de cette session.
      final depot = FauxDepotPartenaire()
        ..coffre = const PartnerSessionStockee(token: 'jeton-d-avant')
        ..reponseGetMe = () async => throw const PartnerApiException(
              'Unauthenticated.',
              statusCode: 401,
            );
      await ouvrir(tester, depot: depot);

      expect(find.byKey(const Key('accueil-session-vendeur-fermee')), findsNothing);
    });
  });

  /// La PREMIÈRE trame : c'est l'injection de `main()` qui décide, pas la
  /// lecture asynchrone du coffre. Le coffre de ce groupe ne répond que quand
  /// le banc l'ouvre, pour que la différence soit visible.
  group('La première trame', () {
    testWidgets('avec la session injectée par main() : le tableau de bord tout de suite', (
      tester,
    ) async {
      final depot = _CoffreLent()..profilAuCoffre = profilDeBanc();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((_) => _FauxAuth(const AuthState(type: AuthType.none))),
            partnerRepositoryProvider.overrideWithValue(depot),
            sessionPartenaireInitialeProvider.overrideWithValue(
              PartnerSession(profile: profilDeBanc(), verified: false),
            ),
            homeDealsProvider.overrideWith((_) async => const []),
          ],
          child: const MaterialApp(
            locale: Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AccueilSelonProfil(),
          ),
        ),
      );

      expect(find.byType(PartnerDashboardPage), findsOneWidget,
          reason: 'Sans l\'injection, l\'accueil acheteur s\'afficherait le '
              'temps de la lecture du coffre — et paierait ses requêtes — '
              'à CHAQUE lancement.');
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('sans injection : l\'accueil acheteur jusqu\'à la lecture du coffre', (
      tester,
    ) async {
      final depot = _CoffreLent()..profilAuCoffre = profilDeBanc();
      await ouvrir(tester, depot: depot);

      expect(find.byType(HomePage), findsOneWidget,
          reason: 'C\'est la preuve que c\'est bien l\'injection qui décide de '
              'la première trame, et non la lecture du coffre.');

      depot.porteCoffre.complete(depot.coffre);
      await tester.pumpAndSettle();

      expect(find.byType(PartnerDashboardPage), findsOneWidget);
    });
  });

  /// Les trois boutons et leurs destinations, lues sur un routeur de banc
  /// dont la route `/partner` dit quel onglet le chemin demande.
  group('Les boutons de l\'accueil vendeur', () {
    late GoRouter routeur;

    Future<void> ouvrirAvecRouteur(
      WidgetTester tester, {
      required FauxDepotPartenaire depot,
      ProfilUtilisateur? profil,
    }) async {
      routeur = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const AccueilSelonProfil()),
          GoRoute(
            path: '/partner',
            builder: (_, state) => Text(
              inscriptionDemandee(state.uri) ? 'INSCRIPTION' : 'CONNEXION',
            ),
          ),
        ],
      );
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((_) => _FauxAuth(const AuthState(type: AuthType.none))),
            partnerRepositoryProvider.overrideWithValue(depot),
            profilInitialProvider.overrideWithValue(profil),
            homeDealsProvider.overrideWith((_) async => const []),
          ],
          child: MaterialApp.router(
            routerConfig: routeur,
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('« Ouvrir mon compte » demande l\'onglet Inscription', (tester) async {
      await ouvrirAvecRouteur(tester, depot: FauxDepotPartenaire(), profil: ProfilUtilisateur.vendeur);

      await tester.tap(find.byKey(const Key('accueil-vendeur-ouvrir')));
      await tester.pumpAndSettle();

      expect(find.text('INSCRIPTION'), findsOneWidget);
      expect(routeur.routerDelegate.currentConfiguration.matches.length, 2,
          reason: 'Poussé par-dessus l\'accueil : le Retour y ramène.');
    });

    testWidgets('« J\'ai déjà un compte » demande la Connexion', (tester) async {
      await ouvrirAvecRouteur(tester, depot: FauxDepotPartenaire(), profil: ProfilUtilisateur.vendeur);

      await tester.ensureVisible(find.byKey(const Key('accueil-vendeur-connexion')));
      await tester.tap(find.byKey(const Key('accueil-vendeur-connexion')));
      await tester.pumpAndSettle();

      expect(find.text('CONNEXION'), findsOneWidget,
          reason: 'Un vendeur qui a un compte envoyé à l\'inscription en '
              'créerait un second.');
    });

    testWidgets('« Se reconnecter » efface la notice et demande la Connexion', (
      tester,
    ) async {
      final depot = FauxDepotPartenaire()
        ..profilAuCoffre = profilDeBanc()
        ..reponseGetMe = () async => throw const PartnerApiException(
              'Votre compte partenaire a été suspendu.',
              statusCode: 403,
              accountStatus: 'suspended',
              code: 'account_disabled',
            );
      await ouvrirAvecRouteur(tester, depot: depot);
      expect(find.byKey(const Key('accueil-session-vendeur-fermee')), findsOneWidget);

      await tester.tap(find.byKey(const Key('accueil-session-vendeur-reconnexion')));
      await tester.pumpAndSettle();

      expect(find.text('CONNEXION'), findsOneWidget);
      final conteneur = ProviderScope.containerOf(tester.element(find.text('CONNEXION')));
      expect(conteneur.read(partnerSessionProvider).deniedStatus, isNull,
          reason: 'La carte a déjà dit le statut et le motif : la page '
              'partenaire doit s\'ouvrir sur la connexion, pas répéter '
              'l\'écran de statut.');
    });
  });
}

/// Un coffre qui ne répond que quand le banc l'ouvre : c'est ce qui rend la
/// première trame observable, avant la lecture asynchrone.
class _CoffreLent extends FauxDepotPartenaire {
  final porteCoffre = Completer<PartnerSessionStockee?>();

  @override
  Future<PartnerSessionStockee?> sessionStockee() {
    appels.add('coffre');

    return porteCoffre.future;
  }
}
