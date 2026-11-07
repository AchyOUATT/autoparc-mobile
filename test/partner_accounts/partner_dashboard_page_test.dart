import 'dart:async';

import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:auto/features/partner_accounts/presentation/partner_dashboard_page.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/faux_depot_partenaire.dart';

/// Le tableau de bord partenaire, l'accueil d'un vendeur connecté.
///
/// ── CE QUE CE BANC FERME ──────────────────────────────────────────────────
///
/// Les compteurs viennent du serveur en un appel et peuvent MANQUER : la page
/// reste navigable, dit « compteurs indisponibles » avec un tiret, et ne
/// montre jamais le texte brut d'un 404 (« The route … could not be found »),
/// qui n'est pas pour l'utilisateur. Seul le 503 — l'espace fermé — porte un
/// motif lisible.
///
/// La liste « À faire » est bornée à trois lignes et classée : la mutation
/// `take(3)` → `take(4)` tombe ici, comme l'inversion de deux priorités.
///
/// Un compte en attente ouvre ici aussi, avec ses trois réponses (qui examine,
/// comment on le saura, quoi faire en attendant) et un moyen de joindre la
/// boutique.
/// Le formulaire de création, ouvert par le « + », part chercher ses
/// références ; sans cette réponse, il irait au réseau et laisserait un
/// délai en suspens à la fin du banc.
class _DepotAvecReferences extends FauxDepotPartenaire {
  @override
  Future<PartnerReferences> references() async => const PartnerReferences(
    brands: [],
    models: [],
    engineTypes: [],
    partCategories: [],
    manufacturers: [],
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'tableau_de_bord_presente': true}));

  Future<void> ouvrir(WidgetTester tester, FauxDepotPartenaire depot) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [partnerRepositoryProvider.overrideWithValue(depot)],
        child: const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PartnerDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// La page est une `ListView` : ce qui est sous le pli du banc (600 points)
  /// n'est pas construit tant qu'on n'y défile pas. Chercher un texte du bas
  /// sans défiler mesure un viewport, pas la page.
  Future<void> defilerJusqua(WidgetTester tester, Finder cible) async {
    // `scrollUntilVisible` s'arrête dès que la cible est CONSTRUITE — dans la
    // marge de cache de la liste, donc parfois encore sous le bord de
    // l'écran, où un appui ne la touche pas. `ensureVisible` finit le geste.
    await tester.scrollUntilVisible(cible, 160, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(cible);
    await tester.pumpAndSettle();
  }

  FauxDepotPartenaire approuve() => _DepotAvecReferences()
    ..profilAuCoffre = profilDeBanc()
    ..nonLues = 3
    ..tableauDeBord = tableauDeBordDeBanc(
      vehicules: const PartnerDashboardCounts(
        total: 1234,
        published: 999,
        drafts: 235,
        withoutPhoto: 2,
      ),
      pieces: const PartnerDashboardCounts(
        total: 7,
        published: 6,
        drafts: 1,
        outOfStock: 2,
        lowStock: 1,
      ),
      nonLues: 3,
    );

  group('Un compte approuvé', () {
    testWidgets('lit son nom, son statut et ses trois inventaires chiffrés', (
      tester,
    ) async {
      await ouvrir(tester, approuve());

      expect(find.text('Garage Exemple'), findsOneWidget);
      expect(find.text('Compte approuvé'), findsOneWidget);
      expect(find.text('1234 annonces'), findsOneWidget);
      expect(find.text('999 publiées · 235 brouillons'), findsOneWidget);
      expect(find.text('6 publiées · 1 brouillon'), findsOneWidget);
      expect(find.text('Aucune annonce'), findsOneWidget,
          reason: 'Les accessoires sont à zéro : une ligne qui le dit, pas '
              '« 0 publiées · 0 brouillons ».');
      expect(find.text('—'), findsNothing);
      expect(find.text('Compteurs indisponibles'), findsNothing);
    });

    testWidgets('la liste « À faire » est classée et bornée à trois lignes', (
      tester,
    ) async {
      await ouvrir(tester, approuve());

      expect(find.text('À faire'), findsOneWidget);
      expect(find.text('2 annonces publiées sans photo'), findsOneWidget);
      expect(find.text('2 articles publiés en rupture'), findsOneWidget);
      expect(find.text('236 brouillons jamais publiés'), findsOneWidget,
          reason: 'Les brouillons s\'additionnent sur les trois inventaires : '
              '235 véhicules et 1 pièce.');
      expect(find.text('1 article en stock faible'), findsNothing,
          reason: 'Quatrième par priorité, donc hors des trois lignes. Un '
              'stock faible attend ; une rupture publiée fait venir pour rien.');
    });

    testWidgets('sans rien à faire, pas de liste', (tester) async {
      final depot = approuve()
        ..tableauDeBord = tableauDeBordDeBanc(
          vehicules: const PartnerDashboardCounts(total: 3, published: 3),
        );
      await ouvrir(tester, depot);

      expect(find.text('À faire'), findsNothing,
          reason: 'Un titre « À faire » sans ligne apprendrait à ne plus '
              'regarder.');
    });

    testWidgets('la pastille des demandes porte le nombre de non lues', (
      tester,
    ) async {
      await ouvrir(tester, approuve());
      await defilerJusqua(tester, find.byKey(const Key('partner-dashboard-demandes')));

      expect(find.byKey(const Key('partner-dashboard-demandes-pastille')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('la rangée de recherche de l\'accueil est là, en dernier', (
      tester,
    ) async {
      await ouvrir(tester, approuve());
      await defilerJusqua(tester, find.text('Rechercher dans le catalogue'));

      expect(find.text('Rechercher dans le catalogue'), findsOneWidget);
      expect(find.text('Véhicules'), findsWidgets);
      expect(find.text('Accessoires'), findsWidgets);
      expect(find.text('Pièces'), findsOneWidget);
    });

    testWidgets('une carte ouvre SON inventaire', (tester) async {
      await ouvrir(tester, approuve());

      await tester.tap(find.byKey(const Key('partner-dashboard-carte-parts')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<PartnerListingsPage>(find.byType(PartnerListingsPage)).kind,
        PartnerListingKind.parts,
      );
    });

    testWidgets('le « + » d\'une carte ouvre le formulaire de SON inventaire', (
      tester,
    ) async {
      await ouvrir(tester, approuve());

      await defilerJusqua(tester, find.byKey(const Key('partner-dashboard-creer-accessories')));
      await tester.tap(find.byKey(const Key('partner-dashboard-creer-accessories')));
      // Deux trames : la route est poussée à la première, construite à la
      // seconde. Pas de `pumpAndSettle` : le formulaire part chercher ses
      // références, et ce banc ne les lui donne pas.
      await tester.pumpAndSettle();

      expect(
        tester.widget<PartnerListingFormPage>(find.byType(PartnerListingFormPage)).kind,
        PartnerListingKind.accessories,
      );
    });
  });

  group('Quand les compteurs manquent', () {
    testWidgets('un 404 donne un tiret et « indisponibles », jamais le texte du serveur', (
      tester,
    ) async {
      final depot = approuve()
        ..reponseTableauDeBord = () async => throw const PartnerApiException(
              'The route api/partner/dashboard could not be found.',
              statusCode: 404,
            );
      await ouvrir(tester, depot);

      expect(find.text('—'), findsNWidgets(3));
      expect(find.text('Compteurs indisponibles'), findsNWidgets(3));
      expect(find.textContaining('could not be found'), findsNothing);
      expect(find.text('À faire'), findsNothing);
      expect(find.byKey(const Key('partner-dashboard-carte-parts')), findsOneWidget,
          reason: 'Les cartes restent navigables : seul le chiffre manque.');
    });

    testWidgets('« Réessayer » relit les compteurs', (tester) async {
      final depot = approuve()
        ..reponseTableauDeBord = () async => throw const PartnerApiException(
              'Connexion impossible.',
              statusCode: null,
            );
      await ouvrir(tester, depot);
      expect(find.text('—'), findsNWidgets(3));

      // Le serveur répond, et le vendeur appuie.
      depot.reponseTableauDeBord = null;
      await tester.tap(find.byKey(const Key('partner-dashboard-reessayer')));
      await tester.pumpAndSettle();

      expect(find.text('1234 annonces'), findsOneWidget);
      expect(find.text('—'), findsNothing);
      expect(depot.appels.where((a) => a == 'dashboard').length, 2);
    });

    testWidgets('un 503 montre le motif du serveur', (tester) async {
      final depot = approuve()
        ..reponseTableauDeBord = () async => throw const PartnerApiException(
              'L\'inscription des vendeurs n\'est pas encore ouverte. Revenez bientôt.',
              statusCode: 503,
            );
      await ouvrir(tester, depot);

      expect(
        find.text('L\'inscription des vendeurs n\'est pas encore ouverte. Revenez bientôt.'),
        findsNWidgets(3),
      );
      expect(find.text('Compteurs indisponibles'), findsNothing);
    });
  });

  group('Un compte en attente', () {
    testWidgets('lit les trois réponses, peut vérifier et nous joindre', (
      tester,
    ) async {
      final depot = FauxDepotPartenaire()..profilAuCoffre = profilDeBanc(status: 'pending');
      await ouvrir(tester, depot);

      expect(find.text('Votre demande est en cours d\'examen'), findsOneWidget);
      expect(find.text('Partenaire — en attente'), findsOneWidget);
      expect(find.text('Vérifier mon statut'), findsOneWidget);
      expect(find.text('Nous contacter'), findsOneWidget);
      expect(find.byKey(const Key('partner-dashboard-carte-parts')), findsNothing,
          reason: 'Rien à compter tant que le compte n\'est pas approuvé.');
      await defilerJusqua(tester, find.text('Rechercher dans le catalogue'));
      expect(find.byKey(const Key('partner-dashboard-demandes')), findsOneWidget,
          reason: 'La boîte aux lettres reste : c\'est par elle qu\'il '
              'apprendra son approbation.');
      expect(find.text('Rechercher dans le catalogue'), findsOneWidget);
      expect(depot.appels.where((a) => a == 'dashboard'), isEmpty,
          reason: 'Un compte en attente ne demande pas ses compteurs : le '
              'serveur lui répondrait 403.');

      await defilerJusqua(tester, find.byKey(const Key('partner-dashboard-verifier')));
      await tester.tap(find.byKey(const Key('partner-dashboard-verifier')));
      await tester.pumpAndSettle();

      expect(depot.appels.where((a) => a == 'getMe').length, 2,
          reason: 'La restauration, puis la vérification demandée.');
    });

    testWidgets('un compte refusé lit le motif', (tester) async {
      final depot = FauxDepotPartenaire()
        ..profilAuCoffre = profilDeBanc(status: 'rejected', reviewReason: 'Téléphone injoignable');
      await ouvrir(tester, depot);

      expect(find.text('Demande refusée'), findsOneWidget);
      expect(find.text('Motif : Téléphone injoignable'), findsOneWidget);
      expect(find.text('Vérifier mon statut'), findsOneWidget);
    });
  });

  group('Le démarrage optimiste', () {
    testWidgets('annonce un statut à confirmer tant que le serveur n\'a pas répondu', (
      tester,
    ) async {
      final depot = approuve()..porteGetMe = Completer<PartnerProfile>();
      await ouvrir(tester, depot);

      expect(find.text('Statut à confirmer…'), findsOneWidget);
      expect(find.text('Compte approuvé'), findsNothing);
      expect(find.text('1234 annonces'), findsOneWidget,
          reason: 'Les compteurs ne dépendent pas de la confirmation.');

      depot.porteGetMe!.complete(profilDeBanc());
      await tester.pumpAndSettle();

      expect(find.text('Compte approuvé'), findsOneWidget);
      expect(find.text('Statut à confirmer…'), findsNothing);
    });
  });

  group('La ligne de bienvenue', () {
    testWidgets('s\'affiche une fois, et « OK » l\'écrit', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await ouvrir(tester, approuve());

      expect(find.byKey(const Key('partner-dashboard-notice')), findsOneWidget);

      await tester.tap(find.byKey(const Key('partner-dashboard-notice-ok')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('partner-dashboard-notice')), findsNothing);
      expect(await NoticeTableauDeBord.estVue(), isTrue);
    });

    testWidgets('ne revient pas une fois vue', (tester) async {
      await ouvrir(tester, approuve());

      expect(find.byKey(const Key('partner-dashboard-notice')), findsNothing);
    });
  });
}
