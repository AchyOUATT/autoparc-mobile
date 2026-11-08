import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:auto/features/partner_accounts/presentation/partner_dashboard_page.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/faux_depot_partenaire.dart';

/// Le tableau de bord vit DANS la coque ; ce qu'il ouvre doit passer PAR-DESSUS.
///
/// ── LE DÉFAUT QUE CE BANC A REPRODUIT ────────────────────────────────────
///
/// La route `/` est une route de la coque (`ShellRoute`) : son Navigator est
/// imbriqué, et la barre du bas est son frère. `Navigator.of(context).push`
/// depuis le tableau de bord empilait donc le formulaire SOUS la barre,
/// toujours visible et touchable. Un appui sur « Pièces » remplaçait la page
/// `/` de la coque, et Flutter achevait les routes sans page accrochées à
/// cette page : dix champs remplis, formulaire disparu, sans confirmation.
///
/// Le banc du tableau de bord seul (`partner_dashboard_page_test.dart`) monte
/// la page dans un `MaterialApp` nu : le défaut y était invisible. Celui-ci
/// la monte sous une coque, comme l'application.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'tableau_de_bord_presente': true}));

  late GoRouter routeur;

  Future<void> ouvrir(WidgetTester tester, FauxDepotPartenaire depot) async {
    routeur = GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => Scaffold(
            key: const Key('coque'),
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: state.uri.path == '/parts' ? 1 : 0,
              onDestinationSelected: (i) => context.go(i == 0 ? '/' : '/parts'),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Accueil'),
                NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Pièces'),
              ],
            ),
          ),
          routes: [
            GoRoute(path: '/', builder: (_, _) => const PartnerDashboardPage()),
            GoRoute(path: '/parts', builder: (_, _) => const Text('PIECES')),
          ],
        ),
      ],
    );
    addTearDown(routeur.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [partnerRepositoryProvider.overrideWithValue(depot)],
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

  Future<void> defilerJusqua(WidgetTester tester, Finder cible) async {
    await tester.scrollUntilVisible(cible, 160, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(cible);
    await tester.pumpAndSettle();
  }

  /// Vrai si [cible] est posé SOUS la coque — donc dans son Navigator
  /// imbriqué, avec la barre du bas visible dessous.
  bool dansLaCoque(Finder cible) =>
      find.descendant(of: find.byKey(const Key('coque')), matching: cible).evaluate().isNotEmpty;

  testWidgets('le « + » ouvre le formulaire PAR-DESSUS la coque, et un onglet ne le détruit pas', (
    tester,
  ) async {
    await ouvrir(tester, FauxDepotPartenaire()..profilAuCoffre = profilDeBanc());
    expect(find.byType(NavigationBar), findsOneWidget);

    await defilerJusqua(tester, find.byKey(const Key('partner-dashboard-creer-accessories')));
    await tester.tap(find.byKey(const Key('partner-dashboard-creer-accessories')));
    await tester.pumpAndSettle();

    final formulaire = find.byType(PartnerListingFormPage);
    expect(formulaire, findsOneWidget);
    expect(dansLaCoque(formulaire), isFalse,
        reason: 'Le formulaire doit vivre dans le Navigator RACINE : sous la '
            'coque, la barre du bas resterait touchable sous lui.');

    // Ce qui arrivait : la coque change de page, et emportait le formulaire.
    routeur.go('/parts');
    await tester.pumpAndSettle();

    expect(find.byType(PartnerListingFormPage), findsOneWidget,
        reason: 'Un changement d\'onglet de la coque ne doit pas achever une '
            'route posée par-dessus elle : dix champs remplis seraient perdus '
            'sans un mot.');
  });

  testWidgets('une carte ouvre son inventaire par-dessus la coque', (tester) async {
    await ouvrir(tester, FauxDepotPartenaire()..profilAuCoffre = profilDeBanc());

    await tester.tap(find.byKey(const Key('partner-dashboard-carte-parts')));
    await tester.pumpAndSettle();

    final liste = find.byType(PartnerListingsPage);
    expect(liste, findsOneWidget);
    expect(dansLaCoque(liste), isFalse);
  });

  testWidgets('« Nous contacter » ouvre sa feuille par-dessus la coque', (tester) async {
    await ouvrir(tester, FauxDepotPartenaire()..profilAuCoffre = profilDeBanc(status: 'pending'));

    await defilerJusqua(tester, find.byKey(const Key('partner-dashboard-contact')));
    await tester.tap(find.byKey(const Key('partner-dashboard-contact')));
    await tester.pumpAndSettle();

    final feuille = find.byType(BottomSheet);
    expect(feuille, findsOneWidget);
    expect(dansLaCoque(feuille), isFalse,
        reason: 'Dans le Navigator imbriqué, la feuille et sa barrière '
            'laisseraient la barre du bas visible et touchable sous elles.');
  });
}
