import 'dart:async';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/pages/login_page.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class TestFirebaseUser extends Fake implements User {
  TestFirebaseUser(this.uid);
  @override
  final String uid;
  @override
  String get email => '$uid@example.test';
  @override
  String get displayName => uid;
}

const partnerRefusal = ApiException(
  statusCode: 403,
  code: 'client_account_requires_partner_login',
  message: 'A partner account cannot use client Firebase login.',
);
const staffRefusal = ApiException(
  statusCode: 403,
  code: 'client_account_requires_staff_login',
  message: 'Use staff login.',
);

class ClientSessionRepository extends AuthRepository {
  ClientSessionRepository() : super(ApiClient());
  final stream = StreamController<User?>.broadcast();
  User? current;
  Object? refusal;
  Future<void> Function()? validation;
  int validated = 0;
  int signedOut = 0;
  int staffLogins = 0;

  @override
  Stream<User?> get firebaseAuthStream => stream.stream;
  @override
  User? get utilisateurCourant => current;
  Future<User> login() async {
    final user = current ?? TestFirebaseUser('client');
    current = user;
    stream.add(user);
    return user;
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) =>
      login();
  @override
  Future<User> signInWithGoogle() => login();
  @override
  Future<User> registerWithEmailAndPassword(String email, String password) =>
      login();
  @override
  Future<void> verifyClientSession() async {
    validated++;
    if (validation != null) await validation!();
    if (refusal != null) throw refusal!;
  }

  @override
  Future<void> signOutClient() async {
    signedOut++;
    current = null;
    stream.add(null);
  }

  @override
  Future<StaffUser> loginStaff(String email, String password) async {
    staffLogins++;
    return const StaffUser(
      id: 1,
      name: 'Manager',
      email: 'manager@example.test',
      role: 'manager',
    );
  }
}

class ProfileApi extends ApiClient {
  ProfileApi(this.response);
  final Map<String, dynamic> response;
  String? requestedPath;
  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    requestedPath = path;
    return response;
  }
}

class RestoredStreamRepository extends ClientSessionRepository {
  @override
  Stream<User?> get firebaseAuthStream async* {
    yield current;
    yield* stream.stream;
  }
}

Future<AuthNotifier> notifier(ClientSessionRepository repository) async {
  final auth = AuthNotifier(repository);
  addTearDown(() async {
    auth.dispose();
    await repository.stream.close();
  });
  await Future<void>.delayed(Duration.zero);
  return auth;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  test('client validation checks the dedicated account endpoint', () async {
    final api = ProfileApi({
      'data': {
        'id': 1,
        'role': 'client',
        'name': 'Client',
        'email': 'client@example.test',
      },
    });
    await AuthRepository(api).verifyClientSession();
    expect(api.requestedPath, '/my/account');
  });

  for (final role in ['partner', 'admin']) {
    test('even a 200 response cannot confirm a $role as a client', () async {
      final api = ProfileApi({
        'data': {
          'id': 1,
          'role': role,
          'name': 'Account',
          'email': 'account@example.test',
        },
      });
      await expectLater(
        AuthRepository(api).verifyClientSession(),
        throwsA(isA<ApiException>()),
      );
    });
  }

  for (final response in <Map<String, dynamic>>[
    {},
    {'data': 'invalid'},
    {
      'data': {'role': 'client'},
    },
    {
      'data': {'id': 1, 'name': 'Unknown', 'email': 'a@b.test'},
    },
  ]) {
    test(
      'a malformed profile cannot authenticate a client: $response',
      () async {
        await expectLater(
          AuthRepository(ProfileApi(response)).verifyClientSession(),
          throwsFormatException,
        );
      },
    );
  }

  final flows = <String, Future<void> Function(AuthNotifier)>{
    'Google': (auth) => auth.signInWithGoogle(),
    'email': (auth) => auth.signInClientEmail('partner@example.test', 'secret'),
    'unified': (auth) => auth.signIn('partner@example.test', 'secret'),
    'registration': (auth) =>
        auth.registerClient('partner@example.test', 'secret'),
  };
  for (final flow in flows.entries) {
    test(
      'Firebase success never opens a partner garage through ${flow.key}',
      () async {
        final repository = ClientSessionRepository()..refusal = partnerRefusal;
        final auth = await notifier(repository);
        final seen = <AuthState>[];
        auth.addListener(seen.add, fireImmediately: false);

        await flow.value(auth);
        await Future<void>.delayed(Duration.zero);

        expect(repository.validated, 1);
        expect(repository.signedOut, 1);
        expect(repository.staffLogins, 0);
        expect(seen.any((state) => state.isClient), isFalse);
        expect(auth.state.isAuthenticated, isFalse);
        expect(auth.state.clientLoginRequiresPartner, isTrue);
        expect(auth.state.isLoading, isFalse);
      },
    );
  }

  test(
    'a genuine client opens its garage only after server confirmation',
    () async {
      final gate = Completer<void>();
      final repository = ClientSessionRepository()
        ..validation = () => gate.future;
      final auth = await notifier(repository);
      final signingIn = auth.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      expect(auth.state.isClient, isFalse);
      gate.complete();
      await signingIn;
      expect(auth.state.isClient, isTrue);
      expect(repository.signedOut, 0);
    },
  );

  test(
    'a restored partner identity is rejected before client state is emitted',
    () async {
      final repository = ClientSessionRepository()
        ..current = TestFirebaseUser('partner')
        ..refusal = partnerRefusal;
      final auth = await notifier(repository);
      await Future<void>.delayed(Duration.zero);
      expect(auth.state.isClient, isFalse);
      expect(auth.state.clientLoginRequiresPartner, isTrue);
      expect(repository.signedOut, 1);
    },
  );

  test(
    'a late Firebase restore event also requires the server role check',
    () async {
      final repository = ClientSessionRepository()..refusal = partnerRefusal;
      final auth = await notifier(repository);
      repository.stream.add(TestFirebaseUser('partner'));
      await Future<void>.delayed(Duration.zero);
      expect(auth.state.isClient, isFalse);
      expect(auth.state.clientLoginRequiresPartner, isTrue);
    },
  );

  test('an initial Firebase stream refusal survives SDK sign-out and initialization', () async {
    final repository = RestoredStreamRepository()
      ..current = TestFirebaseUser('partner')
      ..refusal = partnerRefusal;
    final auth = await notifier(repository);
    await Future<void>.delayed(Duration.zero);
    expect(auth.state.isClient, isFalse);
    expect(auth.state.clientLoginRequiresPartner, isTrue);
    expect(repository.signedOut, 1);
  });

  test(
    'Google staff refusal closes Firebase and explains the staff login',
    () async {
      final repository = ClientSessionRepository()..refusal = staffRefusal;
      final auth = await notifier(repository);
      await auth.signInWithGoogle();
      expect(auth.state.isAuthenticated, isFalse);
      expect(auth.state.error, contains('personnel'));
      expect(repository.signedOut, 1);
    },
  );

  for (final refusal in [
    const ApiException(statusCode: 401, message: 'Token refused'),
    const ApiException(
      statusCode: 403,
      code: 'account_disabled',
      message: 'Account disabled',
    ),
  ]) {
    test(
      'a definitive account refusal ${refusal.code ?? refusal.statusCode} closes Firebase',
      () async {
        final repository = ClientSessionRepository()..refusal = refusal;
        final auth = await notifier(repository);
        await auth.signInWithGoogle();
        expect(auth.state.isClient, isFalse);
        expect(repository.signedOut, 1);
      },
    );
  }

  test(
    'unified staff login falls back after Firebase identity succeeds',
    () async {
      final repository = ClientSessionRepository()..refusal = staffRefusal;
      final auth = await notifier(repository);
      await auth.signIn('manager@example.test', 'secret');
      expect(auth.state.isStaff, isTrue);
      expect(repository.signedOut, 1);
      expect(repository.staffLogins, 1);
    },
  );

  test(
    'network failure keeps SDK credentials without confirming a new client',
    () async {
      final repository = ClientSessionRepository()
        ..refusal = const ApiException(
          message: 'Network failure',
          isNetworkFailure: true,
        );
      final auth = await notifier(repository);
      await auth.signInWithGoogle();
      expect(auth.state.isClient, isFalse);
      expect(repository.current, isNotNull);
      expect(repository.signedOut, 0);
      expect(repository.staffLogins, 0);
    },
  );

  test(
    'a previously confirmed client can remain offline without losing SDK login',
    () async {
      final repository = ClientSessionRepository();
      final auth = await notifier(repository);
      await auth.signInWithGoogle();
      repository.refusal = const ApiException(
        message: 'Offline',
        isNetworkFailure: true,
      );
      auth.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(auth.state.isClient, isTrue);
      expect(auth.state.verified, isFalse);
      expect(repository.signedOut, 0);
    },
  );

  test('late validation cannot reopen a signed-out client', () async {
    final gate = Completer<void>();
    final repository = ClientSessionRepository()
      ..validation = () => gate.future;
    final auth = await notifier(repository);
    final signingIn = auth.signInWithGoogle();
    await Future<void>.delayed(Duration.zero);
    await auth.signOut();
    gate.complete();
    await signingIn;
    expect(auth.state.isAuthenticated, isFalse);
  });

  test(
    'late refusal for account A cannot overwrite newly validated account B',
    () async {
      final gate = Completer<void>();
      final repository = ClientSessionRepository()
        ..validation = () async {
          await gate.future;
          throw partnerRefusal;
        };
      final auth = await notifier(repository);
      final first = auth.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      repository.current = TestFirebaseUser('second-client');
      repository.validation = null;
      await auth.signInWithGoogle();
      gate.complete();
      await first;
      expect(auth.state.firebaseUser?.uid, 'second-client');
      expect(auth.state.isClient, isTrue);
      expect(repository.signedOut, 0);
    },
  );

  for (final language in ['fr', 'en']) {
    testWidgets(
      'partner refusal is translated and opens the partner space in $language',
      (tester) async {
        final repository = ClientSessionRepository()..refusal = partnerRefusal;
        final auth = AuthNotifier(repository);
        addTearDown(() async {
          if (auth.mounted) auth.dispose();
          await repository.stream.close();
        });
        await tester.pump();
        await auth.signInWithGoogle();
        final router = GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
            GoRoute(
              path: '/partner',
              builder: (_, _) => const Scaffold(body: Text('Partner space')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authProvider.overrideWith((ref) => auth)],
            child: MaterialApp.router(
              routerConfig: router,
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = lookupAppLocalizations(Locale(language));
        expect(find.text(l10n.authErrorPartnerAccount), findsOneWidget);
        await tester.tap(find.text(l10n.authOpenPartnerSpace));
        await tester.pumpAndSettle();
        expect(find.text('Partner space'), findsOneWidget);
      },
    );
  }
}
