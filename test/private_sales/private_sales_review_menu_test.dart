import 'package:auto/core/update/version_minimale.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/polices.dart';

class MenuAuth extends StateNotifier<AuthState> implements AuthNotifier {
  MenuAuth(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthState staff(String role) => AuthState(
  type: AuthType.staff,
  staffUser: StaffUser(
    id: 1,
    name: 'Staff',
    email: 'staff@example.test',
    role: role,
  ),
);

Future<void> openMenu(
  WidgetTester tester,
  AuthState auth,
  Locale locale,
) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) =>
            const Scaffold(drawer: AppDrawer(), body: Text('catalogue')),
      ),
      GoRoute(
        path: '/private-listing-reviews',
        builder: (_, __) => const Scaffold(body: Text('moderation-screen')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => MenuAuth(auth)),
        unreadCountProvider.overrideWith((_) async => 0),
        espacePartenaireOuvertProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolices);
  for (final locale in [const Locale('fr'), const Locale('en')]) {
    final title = locale.languageCode == 'fr'
        ? 'Valider les annonces'
        : 'Review listings';
    for (final entry in {
      'admin': staff('admin'),
      'viewer': staff('viewer'),
      'client': const AuthState(type: AuthType.client),
      'visitor': const AuthState(),
    }.entries) {
      testWidgets(
        'review menu ${entry.key} in $locale follows flag and permission',
        (tester) async {
          await openMenu(tester, entry.value, locale);
          expect(
            find.text(title),
            privateSalesEnabled && entry.key == 'admin'
                ? findsOneWidget
                : findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
    if (privateSalesEnabled) {
      testWidgets('staff can still open moderation from the menu in $locale', (
        tester,
      ) async {
        await openMenu(tester, staff('admin'), locale);
        await tester.ensureVisible(find.text(title));
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        expect(find.text('moderation-screen'), findsOneWidget);
      });
    }
  }
}
