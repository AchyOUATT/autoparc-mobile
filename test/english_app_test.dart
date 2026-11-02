import 'dart:async';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/l10n/langue.dart';
import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/notifications/data/models/app_notification.dart';
import 'package:auto/features/notifications/data/notifications_repository.dart';
import 'package:auto/features/notifications/presentation/pages/notifications_page.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart';
import 'package:auto/features/partner_accounts/presentation/partner_account_page.dart';
import 'package:auto/features/partner_accounts/presentation/partner_applications_page.dart';
import 'package:auto/features/partner_accounts/presentation/partner_notifications_page.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/l10n/app_localizations_en.dart';
import 'package:auto/l10n/app_localizations_fr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/polices.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

const _admin = AuthState(
  type: AuthType.staff,
  staffUser: StaffUser(
    id: 1,
    name: 'Staff member',
    email: 'staff@example.test',
    role: 'admin',
  ),
);

class _PartnerRepository extends PartnerRepository {
  Future<List<Map<String, dynamic>>> Function()? fetchNotifications;
  int notificationReads = 0;
  @override
  Future<PartnerSessionStockee?> sessionStockee() async => null;
  @override
  Future<List<Map<String, dynamic>>> notifications() async {
    ++notificationReads;
    return fetchNotifications == null ? [] : fetchNotifications!();
  }

  @override
  Future<int> notificationsNonLues() async => 1;
}

class _ApplicationsApi implements ApiClient {
  final commands = <({String path, Map<String, dynamic>? data})>[];
  bool reviewed = false;
  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    expect(path, '/partner-applications');
    return {
      'data': reviewed
          ? []
          : [
              {
                'id': 4,
                'company_name': 'Example Garage',
                'contact_name': 'Casey Seller',
                'phone': '+22670000000',
                'status': 'pending',
              },
            ],
      'meta': {'current_page': 1, 'last_page': 1, 'total': reviewed ? 0 : 1},
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    commands.add((path: path, data: data));
    reviewed = true;
    return {'data': {}};
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Notifications implements NotificationsRepository {
  final broadcasts = <({String title, String body})>[];
  @override
  Future<List<AppNotification>> getNotifications() async => [];
  @override
  Future<int> getUnreadCount() async => 0;
  @override
  Future<void> broadcastTip({
    required String title,
    required String body,
  }) async {
    broadcasts.add((title: title, body: body));
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _LanguageApp extends ConsumerWidget {
  const _LanguageApp(this.home);
  final Widget home;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(langueProvider);
    definirLocaleMontants(locale);
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: themeAutoParc(Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.5)),
        child: child!,
      ),
      home: home,
    );
  }
}

Future<ProviderContainer> _open(
  WidgetTester tester,
  Widget home, {
  Locale locale = const Locale('en'),
  _PartnerRepository? partner,
  _ApplicationsApi? applications,
  _Notifications? notifications,
  AuthState auth = _admin,
}) async {
  tester.view.physicalSize = const Size(360, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      localeInitialeProvider.overrideWithValue(locale),
      authProvider.overrideWith((_) => _Auth(auth)),
      if (partner != null) partnerRepositoryProvider.overrideWithValue(partner),
      if (applications != null)
        apiClientProvider.overrideWithValue(applications),
      if (notifications != null)
        notificationsRepositoryProvider.overrideWithValue(notifications),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: _LanguageApp(home)),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  tester.testTextInput.hide();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(chargerPolices);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => definirLocaleMontants(localeFrancais));

  testWidgets(
    'partner registration keeps its draft and mode when switching to English',
    (tester) async {
      final fr = AppLocalizationsFr();
      final en = AppLocalizationsEn();
      final container = await _open(
        tester,
        const PartnerAccountPage(),
        locale: localeFrancais,
        partner: _PartnerRepository(),
      );
      await _tapVisible(tester, find.text(fr.partnerAccountsRegisterTab));
      await tester.ensureVisible(find.byKey(const Key('partner-company')));
      await tester.enterText(
        find.byKey(const Key('partner-company')),
        'Garage draft',
      );
      await tester.ensureVisible(find.byKey(const Key('partner-contact')));
      await tester.enterText(
        find.byKey(const Key('partner-contact')),
        'Casey Seller',
      );
      await tester.ensureVisible(find.byKey(const Key('partner-phone')));
      await tester.enterText(
        find.byKey(const Key('partner-phone')),
        '+22670000000',
      );
      await tester.ensureVisible(find.byKey(const Key('partner-password')));
      await tester.enterText(find.byKey(const Key('partner-password')), 'weak');

      await container.read(langueProvider.notifier).definir(localeAnglais);
      await tester.pumpAndSettle();
      expect(find.text(en.partnerAccountsSpaceTitle), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('partner-company')))
            .controller!
            .text,
        'Garage draft',
      );
      expect(
      tester.widget<TextField>(find.descendant(
        of: find.byKey(const Key('partner-contact')),
        matching: find.byType(TextField),
      )).decoration!.labelText,
        en.partnerAccountsContactName,
      );
      await _tapVisible(tester, find.byKey(const Key('partner-submit')));
      expect(find.text(en.partnerAccountsPasswordInvalid), findsOneWidget);
      expect(find.text(en.partnerAccountsRequestAccount), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'English admin rejection validates its reason and preserves the API action',
    (tester) async {
      final en = AppLocalizationsEn();
      final api = _ApplicationsApi();
      await _open(tester, const PartnerApplicationsPage(), applications: api);
      expect(find.text(en.partnerAccountsApplicationsTitle), findsOneWidget);
      await _tapVisible(tester, find.text(en.partnerAccountsReject));
      await _tapVisible(tester, find.text(en.partnerAccountsConfirm));
      expect(find.text(en.partnerAccountsReviewReasonRequired), findsOneWidget);
      expect(api.commands, isEmpty);
      await tester.enterText(
        find.byType(TextFormField),
        'Please verify the contact number.',
      );
      await _tapVisible(tester, find.text(en.partnerAccountsConfirm));
      expect(api.commands.single.path, '/partner-applications/4/reject');
      expect(api.commands.single.data, {
        'review_reason': 'Please verify the contact number.',
      });
      expect(find.text(en.partnerAccountsDecisionSaved), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('English staff notification form validates before broadcasting', (
    tester,
  ) async {
    final en = AppLocalizationsEn();
    final notifications = _Notifications();
    await _open(
      tester,
      const NotificationsPage(),
      notifications: notifications,
    );
    expect(find.text(en.notificationsEmptyTitle), findsOneWidget);
    await _tapVisible(tester, find.byTooltip(en.notificationsBroadcastTooltip));
    expect(find.text(en.notificationsBroadcastTitle), findsOneWidget);
    await _tapVisible(tester, find.text(en.notificationsBroadcastAction));
    expect(find.text(en.notificationsTitleBodyRequired), findsOneWidget);
    expect(notifications.broadcasts, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'partner inbox reloads in English and ignores an older French response',
    (tester) async {
      final oldFrench = Completer<List<Map<String, dynamic>>>();
      final partner = _PartnerRepository();
      partner.fetchNotifications = () => partner.notificationReads == 1
          ? oldFrench.future
          : Future.value([
              {
                'id': 2,
                'type': 'tip',
                'title': 'English update',
                'body': 'The server supplied this message in English.',
                'read_at': null,
              },
            ]);
      // The first response intentionally stays pending, so do not wait for settling.
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [
          localeInitialeProvider.overrideWithValue(localeFrancais),
          partnerRepositoryProvider.overrideWithValue(partner),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const _LanguageApp(PartnerNotificationsPage()),
        ),
      );
      await tester.pump();
      await container.read(langueProvider.notifier).definir(localeAnglais);
      await tester.pumpAndSettle();
      expect(partner.notificationReads, 2);
      expect(
        find.text(AppLocalizationsEn().partnerAccountsCustomerRequests),
        findsOneWidget,
      );
      expect(find.text('English update'), findsOneWidget);
      oldFrench.complete([
        {
          'id': 1,
          'type': 'tip',
          'title': 'Ancienne réponse française',
          'body': 'Cette réponse est périmée.',
          'read_at': null,
        },
      ]);
      await tester.pumpAndSettle();
      expect(find.text('English update'), findsOneWidget);
      expect(find.text('Ancienne réponse française'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
