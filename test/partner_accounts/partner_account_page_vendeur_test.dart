import 'package:auto/core/update/version_minimale.dart';
import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/faux_depot_partenaire.dart';

/// La page partenaire par le chemin du premier lancement, et l'espace fermé.
///
/// ── CE QUE CE BANC FERME ──────────────────────────────────────────────────
///
/// `?inscription=1` ouvre sur l'onglet Inscription avec une intro qui parle au
/// vendeur, pas à une entreprise ; le français de l'autre chemin ne bouge pas.
///
/// L'espace fermé est un ÉCRAN, pas une ligne rouge : par le drapeau quand le
/// serveur a répondu fermé, par le 503 quand il n'avait pas encore répondu.
/// Et « inconnu » n'est pas « fermé » : sans réponse, le formulaire s'affiche.
void main() {
  late GoRouter routeur;

  Future<void> ouvrir(
    WidgetTester tester, {
    required FauxDepotPartenaire depot,
    bool inscription = false,
    bool? espaceOuvert,
  }) async {
    routeur = GoRouter(
      initialLocation: inscription ? '/partner?inscription=1' : '/partner',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('ACCUEIL')),
        GoRoute(
          path: '/partner',
          builder: (_, state) => PartnerAccountPage(
            inscription: state.uri.queryParameters['inscription'] == '1',
          ),
        ),
      ],
    );
    addTearDown(routeur.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partnerRepositoryProvider.overrideWithValue(depot),
          plancherDeVersionProvider.overrideWith(
            (_) => Stream.value(espaceOuvert == null
                ? null
                : PlancherDeVersion(espacePartenaireOuvert: espaceOuvert)),
          ),
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

  group('Par le premier lancement', () {
    testWidgets('l\'onglet Inscription est ouvert, et l\'intro parle au vendeur', (
      tester,
    ) async {
      await ouvrir(tester, depot: FauxDepotPartenaire(), inscription: true);

      expect(find.byKey(const Key('partner-company')), findsOneWidget,
          reason: 'Le champ entreprise n\'existe que sur l\'onglet Inscription.');
      expect(find.text('Créez votre compte vendeur'), findsOneWidget);
      expect(find.text('Vous pourrez publier dès que votre compte est validé.'), findsOneWidget);
      expect(find.text('Présentez votre entreprise'), findsNothing);
    });

    testWidgets('par le tiroir, rien ne change : connexion d\'abord, intro historique', (
      tester,
    ) async {
      await ouvrir(tester, depot: FauxDepotPartenaire());

      expect(find.byKey(const Key('partner-company')), findsNothing);
      expect(find.text('Créez votre compte vendeur'), findsNothing);

      await tester.tap(find.text('Inscription'));
      await tester.pumpAndSettle();

      expect(find.text('Présentez votre entreprise'), findsOneWidget,
          reason: 'Le français existant ne bouge pas.');
      expect(find.text('Créez votre compte vendeur'), findsNothing);
    });
  });

  group('L\'espace fermé', () {
    testWidgets('quand le serveur a dit fermé : un panneau, pas un formulaire', (
      tester,
    ) async {
      await ouvrir(tester, depot: FauxDepotPartenaire(), inscription: true, espaceOuvert: false);

      expect(find.byKey(const Key('partner-espace-ferme')), findsOneWidget);
      expect(find.text('L\x27espace vendeur est fermé pour le moment'), findsOneWidget);
      expect(find.byKey(const Key('partner-company')), findsNothing);
      expect(find.text('Parcourir le catalogue'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('quand on ne sait rien : le formulaire, et c\'est le 503 qui tranche', (
      tester,
    ) async {
      final depot = FauxDepotPartenaire()
        ..reponseLogin = () async => throw const PartnerApiException(
              'L\'inscription des vendeurs n\'est pas encore ouverte. Revenez bientôt.',
              statusCode: 503,
            );
      await ouvrir(tester, depot: depot);
      expect(find.byKey(const Key('partner-espace-ferme')), findsNothing,
          reason: '« Inconnu » n\'est pas « fermé » : sans réponse, le '
              'formulaire s\'affiche.');

      await tester.enterText(find.byKey(const Key('partner-email')), '+22670000000');
      await tester.enterText(find.byKey(const Key('partner-password')), 'Partenaire12345');
      await tester.tap(find.byKey(const Key('partner-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('partner-espace-ferme')), findsOneWidget);
      expect(find.text('L\x27espace vendeur est fermé pour le moment'), findsOneWidget);
      expect(
        find.text('L\'inscription des vendeurs n\'est pas encore ouverte. Revenez bientôt.'),
        findsNothing,
        reason: 'Le motif brut du serveur n\'est plus une ligne rouge sous '
            'un formulaire rempli.',
      );

      // « Réessayer » efface le verdict du 503 : le formulaire revient.
      await tester.tap(find.byKey(const Key('partner-ferme-reessayer')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('partner-espace-ferme')), findsNothing);
      expect(find.byKey(const Key('partner-submit')), findsOneWidget);
    });

    testWidgets('« Parcourir le catalogue » rend la main à l\'accueil', (tester) async {
      await ouvrir(tester, depot: FauxDepotPartenaire(), espaceOuvert: false);

      await tester.tap(find.byKey(const Key('partner-ferme-catalogue')));
      await tester.pumpAndSettle();

      expect(find.text('ACCUEIL'), findsOneWidget);
    });

    testWidgets('une session révoquée par un 401 nu se lit « fermée », pas « reçue »', (
      tester,
    ) async {
      final depot = FauxDepotPartenaire()
        ..profilAuCoffre = profilDeBanc()
        ..reponseGetMe = () async => throw const PartnerApiException(
              'Unauthenticated.',
              statusCode: 401,
            );
      await ouvrir(tester, depot: depot);

      expect(find.text('Votre session vendeur a été fermée'), findsOneWidget);
      expect(find.text('Inscription reçue'), findsNothing,
          reason: 'Le repli du `switch` annonçait une inscription en attente '
              'à un compte que le serveur venait de fermer.');
    });

    testWidgets('un autre refus reste une ligne sous le formulaire', (tester) async {
      final depot = FauxDepotPartenaire()
        ..reponseLogin = () async => throw const PartnerApiException(
              'Identifiants incorrects.',
              statusCode: 422,
            );
      await ouvrir(tester, depot: depot);

      await tester.enterText(find.byKey(const Key('partner-email')), '+22670000000');
      await tester.enterText(find.byKey(const Key('partner-password')), 'Partenaire12345');
      await tester.tap(find.byKey(const Key('partner-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('partner-espace-ferme')), findsNothing);
      expect(find.byKey(const Key('partner-submit')), findsOneWidget);
    });
  });
}
