import 'dart:async';
import 'dart:io';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/contact/autoparc_contact_provider.dart';
import 'package:auto/features/auth/data/password_recovery_repository.dart';
import 'package:auto/features/auth/presentation/pages/login_page.dart';
import 'package:auto/features/auth/presentation/pages/password_recovery_page.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/partner_accounts/partner_accounts.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/polices.dart';
import 'support/troncature.dart';

class _Client extends ApiClient {
  String? path;
  Map<String, dynamic>? body;
  Map<String, dynamic> response = const {'code': 'password_reset_requested'};

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    this.path = path;
    body = data;
    return response;
  }
}

class _Firebase implements FirebaseAuth {
  final calls = <String>[];
  Object? error;

  @override
  Future<void> setLanguageCode(String? code) async => calls.add('locale:$code');

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    calls.add('reset:$email');
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Unexpected auth/session operation: ${invocation.memberName}',
  );
}

class _Recovery extends PasswordRecoveryRepository {
  _Recovery() : super(_Client());
  PasswordRecoveryAccountType? accountType;
  String? email;
  String? languageCode;
  int calls = 0;
  Object? error;
  Completer<void>? pending;

  @override
  Future<void> request({
    required String email,
    required PasswordRecoveryAccountType accountType,
    required String languageCode,
  }) async {
    calls++;
    this.email = email;
    this.accountType = accountType;
    this.languageCode = languageCode;
    if (pending != null) await pending!.future;
    if (error != null) throw error!;
  }
}

class _Contact extends StateNotifier<AutoParcContact>
    implements AutoParcContactNotifier {
  _Contact() : super(AutoParcContact.parse('+33123456789'));
  void change(String phone) => state = AutoParcContact.parse(phone);
  @override
  Future<bool> refresh() async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(const AuthState());
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Recovery must not alter auth: ${invocation.memberName}',
  );
}

class _Partner extends StateNotifier<PartnerSession>
    implements PartnerSessionNotifier {
  _Partner() : super(const PartnerSession());
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Recovery must not alter partner: ${invocation.memberName}',
  );
}

Future<void> _open(
  WidgetTester tester,
  _Recovery recovery, {
  Widget page = const PasswordRecoveryPage(),
  String locale = 'fr',
  double textScale = 1,
  bool pushed = false,
  _Contact? contact,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        passwordRecoveryRepositoryProvider.overrideWithValue(recovery),
        autoparcContactProvider.overrideWith((_) => contact ?? _Contact()),
        authProvider.overrideWith((_) => _Auth()),
        partnerSessionProvider.overrideWith((_) => _Partner()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: pushed ? const Scaffold() : page,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (pushed) {
    Navigator.of(
      tester.element(find.byType(Scaffold)),
    ).push<void>(MaterialPageRoute(builder: (_) => page));
    await tester.pumpAndSettle();
  }
}

Future<void> _send(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('password-recovery-send')));
  await tester.tap(find.byKey(const Key('password-recovery-send')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => chargerPolices(exigerRoboto: false));

  group('recovery destinations and session isolation', () {
    test('client sends only Firebase reset in the selected language', () async {
      final client = _Client();
      final firebase = _Firebase();
      final repository = PasswordRecoveryRepository(
        client,
        firebaseAuth: firebase,
      );
      await repository.request(
        email: '  client@example.test ',
        accountType: PasswordRecoveryAccountType.client,
        languageCode: 'en',
      );
      expect(firebase.calls, ['locale:en', 'reset:client@example.test']);
      expect(client.path, isNull);
    });

    for (final code in ['user-not-found', 'user-disabled']) {
      test('Firebase $code keeps the same generic result', () async {
        final repository = PasswordRecoveryRepository(
          _Client(),
          firebaseAuth: _Firebase()..error = FirebaseAuthException(code: code),
        );
        await repository.request(
          email: 'absent@example.test',
          accountType: PasswordRecoveryAccountType.client,
          languageCode: 'fr',
        );
      });
    }

    test('Firebase outage does not trigger a staff reset', () async {
      final client = _Client();
      final repository = PasswordRecoveryRepository(
        client,
        firebaseAuth: _Firebase()
          ..error = FirebaseAuthException(code: 'network-request-failed'),
      );
      await expectLater(
        repository.request(
          email: 'client@example.test',
          accountType: PasswordRecoveryAccountType.client,
          languageCode: 'fr',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
      expect(client.path, isNull);
    });

    for (final type in [
      PasswordRecoveryAccountType.partner,
      PasswordRecoveryAccountType.staff,
    ]) {
      test('$type sends only the backend recovery request', () async {
        final client = _Client();
        final firebase = _Firebase();
        await PasswordRecoveryRepository(
          client,
          firebaseAuth: firebase,
        ).request(
          email: ' owner@example.test ',
          accountType: type,
          languageCode: 'en',
        );
        expect(client.path, '/auth/password/forgot');
        expect(client.body, {
          'email': 'owner@example.test',
          'account_type': type.name,
          'locale': 'en',
        });
        expect(firebase.calls, isEmpty);
      });
    }

    test(
      'an unrecognized response cannot claim a link was requested',
      () async {
        final client = _Client()..response = const {};
        await expectLater(
          PasswordRecoveryRepository(client).request(
            email: 'owner@example.test',
            accountType: PasswordRecoveryAccountType.partner,
            languageCode: 'fr',
          ),
          throwsFormatException,
        );
      },
    );
  });

  testWidgets('client is selected and the staff option routes separately', (
    tester,
  ) async {
    final recovery = _Recovery();
    await _open(
      tester,
      recovery,
      page: const PasswordRecoveryPage(initialEmail: 'staff@example.test'),
    );
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('password-recovery-client')))
          .selected,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('password-recovery-staff')));
    await _send(tester);
    expect(recovery.accountType, PasswordRecoveryAccountType.staff);
    expect(recovery.email, 'staff@example.test');
    expect(
      find.byKey(const Key('password-recovery-confirmation')),
      findsOneWidget,
    );
  });

  testWidgets(
    'partner is fixed and a phone number is not prefilled as an email',
    (tester) async {
      final recovery = _Recovery();
      await _open(
        tester,
        recovery,
        page: const PasswordRecoveryPage(
          partner: true,
          initialEmail: '+22670000000',
        ),
      );
      expect(find.byType(ChoiceChip), findsNothing);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('password-recovery-email')),
            )
            .controller!
            .text,
        isEmpty,
      );
      await _send(tester);
      expect(recovery.calls, 0);
      expect(find.text('Email invalide'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('password-recovery-email')),
        'partner@example.test',
      );
      await _send(tester);
      expect(recovery.accountType, PasswordRecoveryAccountType.partner);
    },
  );

  testWidgets('English client request and confirmation are localized', (
    tester,
  ) async {
    final recovery = _Recovery();
    await _open(
      tester,
      recovery,
      locale: 'en',
      page: const PasswordRecoveryPage(initialEmail: 'client@example.test'),
    );
    await _send(tester);
    expect(recovery.languageCode, 'en');
    expect(recovery.accountType, PasswordRecoveryAccountType.client);
    expect(find.text('Back to sign in'), findsOneWidget);
    expect(find.textContaining('If a matching account'), findsOneWidget);
    expect(find.textContaining('Continue with Google'), findsOneWidget);
  });

  for (final error in <Object>[
    const ApiException(statusCode: 503, message: 'secret delivery error'),
    const ApiException(statusCode: 429, message: 'secret throttling error'),
    const ApiException(
      message: 'technical network error',
      isNetworkFailure: true,
    ),
    FirebaseAuthException(code: 'too-many-requests'),
  ]) {
    testWidgets('failed request remains retryable and safe: $error', (
      tester,
    ) async {
      final recovery = _Recovery()..error = error;
      await _open(
        tester,
        recovery,
        page: const PasswordRecoveryPage(initialEmail: 'client@example.test'),
      );
      await _send(tester);
      expect(find.byKey(const Key('password-recovery-error')), findsOneWidget);
      expect(
        find.byKey(const Key('password-recovery-confirmation')),
        findsNothing,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('password-recovery-send')),
            )
            .onPressed,
        isNotNull,
      );
      recovery.error = null;
      await _send(tester);
      expect(
        find.byKey(const Key('password-recovery-confirmation')),
        findsOneWidget,
      );
    });
  }

  testWidgets('support links use the current configurable AutoParc number', (
    tester,
  ) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final launched = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'launch') {
            launched.add((call.arguments as Map)['url'] as String);
          }
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final contact = _Contact();
    await _open(
      tester,
      _Recovery(),
      contact: contact,
      page: const PasswordRecoveryPage(partner: true),
    );
    contact.change('+22670123456');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('password-recovery-call')));
    await tester.tap(find.byKey(const Key('password-recovery-call')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('password-recovery-whatsapp')),
    );
    await tester.tap(find.byKey(const Key('password-recovery-whatsapp')));
    await tester.pumpAndSettle();
    expect(launched, ['tel:+22670123456', 'https://wa.me/22670123456']);
  });

  testWidgets(
    'login entry preserves the email and never starts authentication',
    (tester) async {
      final recovery = _Recovery();
      await _open(tester, recovery, page: const LoginPage());
      await tester.enterText(
        find.byType(TextFormField).first,
        'client@example.test',
      );
      await tester.ensureVisible(find.byKey(const Key('forgot-password')));
      await tester.tap(find.byKey(const Key('forgot-password')));
      await tester.pumpAndSettle();
      await _send(tester);
      await tester.ensureVisible(find.text('Retour à la connexion'));
      await tester.tap(find.text('Retour à la connexion'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'client@example.test',
      );
    },
  );

  testWidgets(
    'partner login opens its fixed recovery and registration hides the link',
    (tester) async {
      await _open(tester, _Recovery(), page: const PartnerAccountPage());
      await tester.ensureVisible(
        find.byKey(const Key('partner-forgot-password')),
      );
      await tester.tap(find.byKey(const Key('partner-forgot-password')));
      await tester.pumpAndSettle();
      expect(find.text('Compte partenaire'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      Navigator.of(tester.element(find.byType(PasswordRecoveryPage))).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Inscription'));
      await tester.tap(find.text('Inscription'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('partner-forgot-password')), findsNothing);
    },
  );

  testWidgets('closing during delivery safely ignores the late result', (
    tester,
  ) async {
    final recovery = _Recovery()..pending = Completer<void>();
    await _open(tester, recovery, page: const LoginPage());
    await tester.ensureVisible(find.byKey(const Key('forgot-password')));
    await tester.tap(find.byKey(const Key('forgot-password')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('password-recovery-email')),
      'client@example.test',
    );
    await tester.tap(find.byKey(const Key('password-recovery-send')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('password-recovery-send')))
          .onPressed,
      isNull,
    );
    Navigator.of(tester.element(find.byType(PasswordRecoveryPage))).pop();
    await tester.pumpAndSettle();
    recovery.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final locale in ['fr', 'en']) {
    for (final textScale in [1.0, 1.5, 2.0]) {
      for (final partner in [false, true]) {
        testWidgets(
          'recovery remains usable on a narrow screen in $locale x$textScale partner=$partner',
          (tester) async {
            tester.view.physicalSize = const Size(320, 568);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final recovery = _Recovery();
            await _open(
              tester,
              recovery,
              locale: locale,
              textScale: textScale,
              pushed: true,
              page: PasswordRecoveryPage(
                partner: partner,
                initialEmail: 'partner@example.test',
              ),
            );
            aucuneTroncature(
              tester,
              racine: find.byType(PasswordRecoveryPage),
              ou: 'password recovery $locale x$textScale',
              echelle: textScale,
              valeursSansBorne: const {'partner@example.test'},
            );
            if (Platform.environment['CAPTURES'] == '1' &&
                textScale == 1 &&
                partner) {
              await expectLater(
                find.byType(MaterialApp),
                matchesGoldenFile(
                  '../build/captures/password-recovery-$locale.png',
                ),
              );
            }
            if (!partner) {
              await tester.ensureVisible(
                find.byKey(const Key('password-recovery-staff')),
              );
              await tester.tap(
                find.byKey(const Key('password-recovery-staff')),
              );
              await tester.pumpAndSettle();
            }
            await _send(tester);
            expect(
              recovery.accountType,
              partner
                  ? PasswordRecoveryAccountType.partner
                  : PasswordRecoveryAccountType.staff,
            );
            expect(
              find.byKey(const Key('password-recovery-confirmation')),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
