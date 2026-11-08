import 'dart:async';

import 'package:auto/core/update/version_minimale.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/onboarding/data/profil_service.dart';
import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/faux_depot_partenaire.dart';

/// Le tiroir pendant une session partenaire — la troisième session, hors
/// d'`authProvider`, que le tiroir ignorait : il disait « Visiteur » à un
/// partenaire connecté et lui proposait de se connecter.
///
/// Le même montage que `indicateur_session_test.dart` : le VRAI tiroir, ouvert
/// par le geste.
class _FauxAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FauxAuth(super.etat);

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

void main() {
  Future<void> poserTiroir(
    WidgetTester tester, {
    required FauxDepotPartenaire depot,
    ProfilUtilisateur? profil,
    bool? espaceOuvert,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((_) => _FauxAuth(const AuthState(type: AuthType.none))),
          partnerRepositoryProvider.overrideWithValue(depot),
          profilInitialProvider.overrideWithValue(profil),
          // Nul : le serveur n'a pas répondu, ou pas encore — le drapeau est
          // alors FAUX, et c'est le cas du premier lancement à froid.
          plancherDeVersionProvider.overrideWith(
            (_) async => espaceOuvert == null
                ? null
                : PlancherDeVersion(espacePartenaireOuvert: espaceOuvert),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(drawer: AppDrawer(), body: SizedBox.shrink()),
        ),
      ),
    );

    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
  }

  group('Un partenaire connecté', () {
    testWidgets('lit son nom et « Partenaire », et le bloc PARTENAIRE', (tester) async {
      final depot = FauxDepotPartenaire()
        ..profilAuCoffre = profilDeBanc()
        ..nonLues = 4;
      await poserTiroir(tester, depot: depot);

      expect(find.text('Garage Exemple'), findsOneWidget);
      expect(find.text('Partenaire'), findsOneWidget);
      expect(find.text('Visiteur'), findsNothing);
      expect(find.text('Se connecter'), findsNothing,
          reason: 'Le bloc ANONYME ne s\'adresse pas à une session en cours.');
      expect(find.text('Tableau de bord'), findsOneWidget);
      expect(find.text('Mes annonces'), findsOneWidget);
      expect(find.text('Demandes clients'), findsOneWidget);
      expect(find.text('4'), findsOneWidget, reason: 'La pastille des non lues.');
      expect(find.text('Se déconnecter du compte partenaire'), findsOneWidget);
      expect(find.text('Espace partenaire'), findsNothing,
          reason: '« Mes annonces » y mène déjà ; l\'entrée générique ferait '
              'doublon.');
    });

    testWidgets('sans raison sociale, l\'en-tête porte le nom du responsable', (
      tester,
    ) async {
      await poserTiroir(
        tester,
        depot: FauxDepotPartenaire()..profilAuCoffre = profilDeBanc(company: null),
      );

      expect(find.text('Awa Exemple'), findsOneWidget);
      // L'initiale de l'avatar suit le même repli.
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('en attente, la seconde ligne le dit', (tester) async {
      await poserTiroir(
        tester,
        depot: FauxDepotPartenaire()..profilAuCoffre = profilDeBanc(status: 'pending'),
      );

      expect(find.text('Partenaire — en attente'), findsOneWidget);
    });

    testWidgets('tant que le serveur n\'a pas confirmé, « Session à confirmer… »', (
      tester,
    ) async {
      final depot = FauxDepotPartenaire()
        ..profilAuCoffre = profilDeBanc()
        ..porteGetMe = Completer<PartnerProfile>();
      await poserTiroir(tester, depot: depot);

      expect(find.text('Session à confirmer…'), findsOneWidget);
      expect(find.text('Partenaire'), findsNothing);

      depot.porteGetMe!.complete(profilDeBanc());
      await tester.pumpAndSettle();

      expect(find.text('Partenaire'), findsOneWidget);
    });

    testWidgets('« Se déconnecter » ferme la session partenaire', (tester) async {
      final depot = FauxDepotPartenaire()..profilAuCoffre = profilDeBanc();
      await poserTiroir(tester, depot: depot);

      await tester.tap(find.text('Se déconnecter du compte partenaire'));
      await tester.pumpAndSettle();

      expect(depot.appels, contains('logout'));
      // Le tiroir s'est refermé ; on le rouvre pour lire l'en-tête.
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Visiteur'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });
  });

  group('Personnel et partenaire sur le même téléphone', () {
    testWidgets('pas de tuile « Tableau de bord », et deux déconnexions qu\'on distingue', (
      tester,
    ) async {
      const employe = StaffUser(id: 1, name: 'Awa Traoré', email: 'awa@autoparc.bf', role: 'admin');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              (_) => _FauxAuth(const AuthState(type: AuthType.staff, staffUser: employe)),
            ),
            partnerRepositoryProvider.overrideWithValue(
              FauxDepotPartenaire()..profilAuCoffre = profilDeBanc(),
            ),
            plancherDeVersionProvider.overrideWith((_) async => null),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(drawer: AppDrawer(), body: SizedBox.shrink()),
          ),
        ),
      );
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      // Le bloc du personnel est long : le bloc PARTENAIRE est sous le pli.
      await tester.scrollUntilVisible(
        find.text('Se déconnecter du compte partenaire'),
        120,
        scrollable: find.descendant(of: find.byType(Drawer), matching: find.byType(Scrollable)),
      );

      expect(find.text('Mes annonces'), findsOneWidget,
          reason: 'Le bloc PARTENAIRE reste : ses annonces sont à un appui.');
      expect(find.text('Tableau de bord'), findsNothing,
          reason: '`/` rend l\'accueil du personnel (personnel > partenaire) : '
              'une tuile qui promettrait le tableau de bord mentirait.');
      expect(find.text('Se déconnecter'), findsOneWidget,
          reason: 'Celle du personnel.');
      expect(find.text('Se déconnecter du compte partenaire'), findsOneWidget);
    });
  });

  group('L\'entrée « Espace partenaire »', () {
    testWidgets('est là tant que le serveur n\'a pas dit fermé', (tester) async {
      await poserTiroir(tester, depot: FauxDepotPartenaire());

      expect(find.text('Espace partenaire'), findsOneWidget,
          reason: 'La question du premier lancement promet « vous pourrez '
              'changer d\'avis plus tard » ; une instance endormie le matin ne '
              'doit pas en faire un mensonge. La page sait expliquer un espace '
              'fermé.');
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('s\'ouvre quand le serveur a dit ouvert', (tester) async {
      await poserTiroir(tester, depot: FauxDepotPartenaire(), espaceOuvert: true);

      expect(find.text('Espace partenaire'), findsOneWidget);
    });

    testWidgets('un profil vendeur la voit TOUJOURS, même sans réponse du serveur', (
      tester,
    ) async {
      await poserTiroir(
        tester,
        depot: FauxDepotPartenaire(),
        profil: ProfilUtilisateur.vendeur,
      );

      expect(find.text('Espace partenaire'), findsOneWidget,
          reason: 'Le drapeau reste faux toute la session après un démarrage '
              'à froid ; une entrée qui apparaît un jour et pas le lendemain '
              'se lit comme un bogue. La page sait expliquer un espace fermé.');
    });

    testWidgets('un profil acheteur suit le drapeau', (tester) async {
      await poserTiroir(
        tester,
        depot: FauxDepotPartenaire(),
        profil: ProfilUtilisateur.acheteur,
        espaceOuvert: false,
      );

      expect(find.text('Espace partenaire'), findsNothing);
    });
  });
}
