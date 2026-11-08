import 'package:auto/features/cart/presentation/pages/cart_page.dart';
import 'package:auto/features/needs/presentation/pages/client_needs_page.dart';
import 'package:auto/features/auth/presentation/pages/login_page.dart';
import 'package:auto/features/auth/presentation/pages/password_recovery_page.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/onboarding/presentation/pages/choix_de_profil_page.dart';
import 'package:auto/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth({bool client = false})
    : super(
        AuthState(
          type: client ? AuthType.client : AuthType.none,
          error:
              'La connexion a échoué. Vérifiez votre connexion et réessayez.',
          clientLoginRequiresPartner: true,
        ),
      );
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const sizes = [
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(640, 360),
  ];
  final pages = <String, Widget>{
    'login': const LoginPage(),
    'welcome': const ChoixDeProfilPage(),
    'onboarding': const OnboardingPage(),
    'recovery': const PasswordRecoveryPage(),
    'cart': const CartPage(),
    'needs': const ClientNeedsPage(),
  };
  for (final page in pages.entries) {
    for (final size in sizes) {
      for (final locale in [const Locale('fr'), const Locale('en')]) {
        for (final scale in [1.0, 1.3]) {
          for (final keyboard in [
            0.0,
            if (page.key == 'login' || page.key == 'recovery')
              size.width > size.height ? 200.0 : 280.0,
          ]) {
            testWidgets(
              '${page.key} $size $locale x$scale keyboard=$keyboard',
              (tester) async {
                tester.view.physicalSize = size;
                tester.view.devicePixelRatio = 1;
                tester.view.padding = const FakeViewPadding(
                  top: 24,
                  bottom: 24,
                );
                tester.view.viewPadding = const FakeViewPadding(
                  top: 24,
                  bottom: 24,
                );
                tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
                addTearDown(tester.view.reset);
                final router = GoRouter(
                  initialLocation: '/test',
                  routes: [
                    GoRoute(path: '/test', builder: (_, _) => page.value),
                    GoRoute(
                      path: '/parts',
                      builder: (_, _) =>
                          const Scaffold(body: Text('parts-destination')),
                    ),
                    GoRoute(
                      path: '/needs/new',
                      builder: (_, _) =>
                          const Scaffold(body: Text('need-destination')),
                    ),
                    GoRoute(
                      path: '/',
                      builder: (_, _) =>
                          const Scaffold(body: Text('catalog-destination')),
                    ),
                    GoRoute(
                      path: '/onboarding',
                      builder: (_, _) =>
                          const Scaffold(body: Text('onboarding-destination')),
                    ),
                    GoRoute(
                      path: '/partner',
                      builder: (_, _) =>
                          const Scaffold(body: Text('partner-destination')),
                    ),
                  ],
                );
                addTearDown(router.dispose);
                await tester.pumpWidget(
                  ProviderScope(
                    overrides: [
                      authProvider.overrideWith(
                        (_) => _Auth(
                          client: page.key == 'cart' || page.key == 'needs',
                        ),
                      ),
                    ],
                    child: MaterialApp.router(
                      routerConfig: router,
                      locale: locale,
                      localizationsDelegates:
                          AppLocalizations.localizationsDelegates,
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
                expect(tester.takeException(), isNull);
                final l10n = await AppLocalizations.delegate.load(locale);
                if (page.key == 'login') {
                  // The registration fields and their validation messages must
                  // share the same scroll area as the header/error feedback.
                  final register = find.text(l10n.authRegisterTab);
                  await Scrollable.ensureVisible(tester.element(register));
                  await tester.pumpAndSettle();
                  await tester.tap(register);
                  await tester.pumpAndSettle();
                  expect(find.byType(TextFormField), findsNWidgets(3));
                  final submit = find.widgetWithText(
                    FilledButton,
                    l10n.authCreateAccount,
                  );
                  await Scrollable.ensureVisible(
                    tester.element(submit),
                    alignment: 0.5,
                  );
                  await tester.pumpAndSettle();
                  expect(submit.hitTestable(), findsOneWidget);
                  expect(
                    tester.getRect(submit).bottom,
                    lessThanOrEqualTo(size.height - keyboard),
                  );
                  await tester.tap(submit);
                  await tester.pumpAndSettle();
                  expect(find.text(l10n.authEmailInvalid), findsOneWidget);
                  expect(find.text(l10n.authPasswordTooShort), findsOneWidget);
                  expect(tester.takeException(), isNull);
                }
                final target = switch (page.key) {
                  'login' => find.text(l10n.authBrowseWithoutAccount),
                  'welcome' => find.byKey(const Key('profil-indecis')),
                  'onboarding' => find.text(l10n.onboardingNext),
                  'cart' => find.text(l10n.commonParts),
                  'needs' => find.text(l10n.catalogNeedTooltip),
                  _ => find.byType(FilledButton),
                };
                await Scrollable.ensureVisible(
                  tester.element(target),
                  alignment: 0.5,
                );
                await tester.pumpAndSettle();
                expect(target.hitTestable(), findsOneWidget);
                expect(tester.takeException(), isNull);
                if (page.key == 'cart' || page.key == 'needs') {
                  expect(
                    tester.getRect(target).bottom,
                    lessThanOrEqualTo(size.height - 24),
                  );
                  await tester.tap(target);
                  await tester.pumpAndSettle();
                  expect(
                    find.text(
                      page.key == 'cart'
                          ? 'parts-destination'
                          : 'need-destination',
                    ),
                    findsOneWidget,
                  );
                }
                if (page.key == 'onboarding') {
                  for (var i = 0; i < 2; i++) {
                    await tester.tap(find.text(l10n.onboardingNext));
                    await tester.pumpAndSettle();
                    expect(tester.takeException(), isNull);
                  }
                  expect(
                    find.text(l10n.onboardingStart).hitTestable(),
                    findsOneWidget,
                  );
                  await tester.tap(find.text(l10n.onboardingStart));
                  await tester.pumpAndSettle();
                  expect(find.text('catalog-destination'), findsOneWidget);
                }
                if (page.key == 'login' || page.key == 'welcome') {
                  await tester.tap(target);
                  await tester.pumpAndSettle();
                  expect(
                    find.text(
                      page.key == 'login'
                          ? 'catalog-destination'
                          : 'onboarding-destination',
                    ),
                    findsOneWidget,
                  );
                }
              },
            );
          }
        }
      }
    }
  }
}
