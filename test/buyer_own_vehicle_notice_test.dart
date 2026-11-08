import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/onboarding/data/profil_service.dart';
import 'package:auto/features/onboarding/presentation/pages/choix_de_profil_page.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _mount(
  WidgetTester tester, {
  required Locale locale,
  Brightness brightness = Brightness.light,
  double scale = 1,
}) async {
  final router = GoRouter(
    initialLocation: '/bienvenue',
    routes: [
      GoRoute(path: '/bienvenue', builder: (_, _) => const ChoixDeProfilPage()),
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const Scaffold(body: Text('buyer-onboarding')),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('catalog')),
      ),
      GoRoute(
        path: '/partner',
        builder: (_, _) => const Scaffold(body: Text('seller-signup')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        theme: themeAutoParc(brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(ChoixDeProfilPage)),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final locale in [const Locale('fr'), const Locale('en')]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'buyer notice $locale $brightness scale=$scale follows sale availability',
          (tester) async {
            tester.view.physicalSize = const Size(320, 640);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await _mount(
              tester,
              locale: locale,
              brightness: brightness,
              scale: scale,
            );
            final l10n = await AppLocalizations.delegate.load(locale);
            final buyerCard = find.byKey(const Key('profil-cherche'));
            expect(
              find.descendant(
                of: buyerCard,
                matching: find.textContaining(
                  l10n.onboardingProfileBuyOwnVehicleNotice,
                ),
              ),
              privateSalesEnabled ? findsOneWidget : findsNothing,
            );
            expect(
              find.descendant(
                of: buyerCard,
                matching: find.textContaining(l10n.onboardingProfileBuyBody),
              ),
              findsOneWidget,
            );
            expect(find.text(l10n.onboardingProfileSellBody), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets(
      'notice does not change the buyer path or grant a seller profile $locale',
      (tester) async {
        final container = await _mount(tester, locale: locale);
        final buyer = find.byKey(const Key('profil-cherche'));
        await Scrollable.ensureVisible(tester.element(buyer), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(buyer);
        await tester.pumpAndSettle();
        expect(find.text('buyer-onboarding'), findsOneWidget);
        expect(
          container.read(profilUtilisateurProvider),
          ProfilUtilisateur.acheteur,
        );
        expect(await ProfilService.lire(), ProfilUtilisateur.acheteur);
        expect(find.text('seller-signup'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
