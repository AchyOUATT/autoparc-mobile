import 'dart:async';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/contact/autoparc_contact_provider.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/settings/presentation/contact_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Api implements ApiClient {
  String phone = '+22670123456';
  Object? readError;
  Object? saveError;
  Completer<Map<String, dynamic>>? pendingRead;
  Completer<Map<String, dynamic>>? pendingSave;
  final reads = <String>[];
  final writes = <({String path, Map<String, dynamic>? data})>[];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    reads.add(path);
    if (readError != null) throw readError!;
    if (pendingRead != null) return pendingRead!.future;
    return {'phone': phone};
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    writes.add((path: path, data: data));
    if (saveError != null) throw saveError!;
    if (pendingSave != null) return pendingSave!.future;
    phone = data!['phone'] as String;
    return {'phone': phone};
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Cache extends AutoParcContactCache {
  AutoParcContact? value;
  bool unavailable = false;

  @override
  Future<AutoParcContact?> read() async {
    if (unavailable) throw StateError('Préférences indisponibles');
    return value;
  }

  @override
  Future<void> write(AutoParcContact contact) async {
    if (unavailable) throw StateError('Disque plein');
    value = contact;
  }
}

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

AuthState _staff(String role) => AuthState(
  type: AuthType.staff,
  staffUser: StaffUser(
    id: 1,
    name: 'Équipe',
    email: 'staff@example.test',
    role: role,
  ),
);

ProviderContainer _container(_Api api, _Cache cache) => ProviderContainer(
  overrides: [
    apiClientProvider.overrideWithValue(api),
    autoparcContactCacheProvider.overrideWithValue(cache),
  ],
);

Future<ProviderContainer> _open(
  WidgetTester tester,
  _Api api, {
  AuthState? auth,
  _Cache? cache,
}) async {
  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      autoparcContactCacheProvider.overrideWithValue(cache ?? _Cache()),
      authProvider.overrideWith((_) => _Auth(auth ?? _staff('manager'))),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ContactSettingsPage()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'un numéro unique fournit les liens d’appel et WhatsApp sans séparateurs',
    () {
      final contact = AutoParcContact.parse(' +226 (70) 12-34.56 ');
      expect(contact.phone, '+22670123456');
      expect(contact.phoneDisplay, '+226 70 12 34 56');
      expect(contact.phoneUri.toString(), 'tel:+22670123456');
      expect(contact.whatsappUri.toString(), 'https://wa.me/22670123456');
      final otherCountry = AutoParcContact.parse('+33123456789');
      expect(otherCountry.phoneDisplay, '+33123456789');
      expect(otherCountry.whatsappNumber, '33123456789');
    },
  );

  test('une réponse incorrecte ne peut devenir une cible de contact', () {
    for (final phone in [
      '',
      '70123456',
      '+012345678',
      '+2267000x000',
      '+2267',
      '+1234567890123456',
    ]) {
      expect(
        () => AutoParcContact.fromJson({'phone': phone}),
        throwsFormatException,
      );
    }
    expect(
      () => AutoParcContact.fromJson({'phone': null}),
      throwsFormatException,
    );
  });

  test(
    'hors connexion, le dernier numéro confirmé remplace le défaut et reste disponible',
    () async {
      final api = _Api()
        ..readError = const ApiException(
          message: 'Hors connexion',
          isNetworkFailure: true,
        );
      final cache = _Cache()..value = AutoParcContact.parse('+22670000001');
      final container = _container(api, cache);
      addTearDown(container.dispose);
      expect(container.read(autoparcContactProvider), AutoParcContact.fallback);
      expect(
        await container.read(autoparcContactProvider.notifier).refresh(),
        isFalse,
      );
      expect(container.read(autoparcContactProvider).phone, '+22670000001');
      expect(api.reads, ['/app/contact']);
    },
  );

  test(
    'sans cache et sans réseau, le numéro existant reste joignable',
    () async {
      final api = _Api()..readError = StateError('Réseau indisponible');
      final container = _container(api, _Cache()..unavailable = true);
      addTearDown(container.dispose);
      expect(
        await container.read(autoparcContactProvider.notifier).refresh(),
        isFalse,
      );
      expect(container.read(autoparcContactProvider), AutoParcContact.fallback);
    },
  );

  test(
    'le rafraîchissement remplace et conserve le numéro renvoyé par le serveur',
    () async {
      final api = _Api();
      final cache = _Cache();
      final container = _container(api, cache);
      addTearDown(container.dispose);
      expect(
        await container.read(autoparcContactProvider.notifier).refresh(),
        isTrue,
      );
      expect(container.read(autoparcContactProvider).phone, api.phone);
      expect(cache.value?.phone, api.phone);
    },
  );

  test(
    'la sauvegarde réussie actualise immédiatement le contact partagé',
    () async {
      final api = _Api();
      final cache = _Cache();
      final container = _container(api, cache);
      addTearDown(container.dispose);
      await container
          .read(autoparcContactProvider.notifier)
          .save('+226 76 00 00 02');
      expect(api.writes.single.path, '/settings/contact');
      expect(api.writes.single.data, {'phone': '+22676000002'});
      expect(
        container.read(autoparcContactProvider).whatsappNumber,
        '22676000002',
      );
      expect(cache.value?.phone, '+22676000002');
    },
  );

  test(
    'une sauvegarde refusée conserve le numéro confirmé et son cache',
    () async {
      final cache = _Cache()..value = AutoParcContact.parse('+22670000001');
      final api = _Api()
        ..saveError = const ApiException(
          statusCode: 503,
          message: 'Indisponible',
        );
      final container = _container(api, cache);
      addTearDown(container.dispose);
      final notifier = container.read(autoparcContactProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await expectLater(
        notifier.save('+22670000002'),
        throwsA(isA<ApiException>()),
      );
      expect(container.read(autoparcContactProvider).phone, '+22670000001');
      expect(cache.value?.phone, '+22670000001');
    },
  );

  test(
    'une ancienne lecture publique ne peut annuler une sauvegarde récente',
    () async {
      final staleRead = Completer<Map<String, dynamic>>();
      final api = _Api()..pendingRead = staleRead;
      final cache = _Cache();
      final container = _container(api, cache);
      addTearDown(container.dispose);
      final notifier = container.read(autoparcContactProvider.notifier);
      final refreshing = notifier.refresh();
      await Future<void>.delayed(Duration.zero);
      await notifier.save('+22670000002');
      staleRead.complete({'phone': '+22670000001'});
      expect(await refreshing, isFalse);
      expect(container.read(autoparcContactProvider).phone, '+22670000002');
      expect(cache.value?.phone, '+22670000002');
    },
  );

  test(
    'un échec du cache ne transforme pas une sauvegarde serveur réussie en échec',
    () async {
      final container = _container(_Api(), _Cache()..unavailable = true);
      addTearDown(container.dispose);
      await container
          .read(autoparcContactProvider.notifier)
          .save('+22670000002');
      expect(container.read(autoparcContactProvider).phone, '+22670000002');
    },
  );

  test(
    'le cache persistant permet de retrouver le numéro dans une nouvelle instance',
    () async {
      SharedPreferences.setMockInitialValues({});
      await AutoParcContactCache().write(AutoParcContact.parse('+22670000002'));
      expect((await AutoParcContactCache().read())?.phone, '+22670000002');
    },
  );

  for (final role in [
    'viewer',
    'sales',
    'warehouse',
    'mechanic',
    'partner',
    'unknown',
  ]) {
    testWidgets('$role ne peut pas charger ni modifier le paramètre', (
      tester,
    ) async {
      final api = _Api();
      await _open(tester, api, auth: _staff(role));
      expect(
        find.text('Accès réservé aux administrateurs et responsables.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('autoparc-contact-phone')), findsNothing);
      expect(api.reads, isEmpty);
      expect(api.writes, isEmpty);
    });
  }

  testWidgets('un visiteur ne peut pas accéder au formulaire', (tester) async {
    final api = _Api();
    await _open(tester, api, auth: const AuthState());
    expect(api.reads, isEmpty);
    expect(find.byKey(const Key('save-autoparc-contact')), findsNothing);
  });

  for (final role in ['admin', 'manager']) {
    testWidgets(
      '$role charge le paramètre protégé et modifie le numéro partagé',
      (tester) async {
        final api = _Api();
        final container = await _open(tester, api, auth: _staff(role));
        expect(api.reads, ['/settings/contact']);
        expect(find.text('+226 70 12 34 56'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('autoparc-contact-phone')),
          '+226 76 00 00 02',
        );
        await tester.tap(find.byKey(const Key('save-autoparc-contact')));
        await tester.pumpAndSettle();
        expect(api.writes.single.data, {'phone': '+22676000002'});
        expect(container.read(autoparcContactProvider).phone, '+22676000002');
        expect(
          find.text('Numéro de contact AutoParc enregistré.'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('un chargement échoué propose un réessai avant toute édition', (
    tester,
  ) async {
    final api = _Api()
      ..readError = const ApiException(
        statusCode: 503,
        message: 'Indisponible',
      );
    await _open(tester, api);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.byKey(const Key('save-autoparc-contact')), findsNothing);
    api.readError = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(api.reads, ['/settings/contact', '/settings/contact']);
    expect(find.byKey(const Key('autoparc-contact-phone')), findsOneWidget);
  });

  testWidgets('un numéro invalide n’est pas transmis au serveur', (
    tester,
  ) async {
    final api = _Api();
    await _open(tester, api);
    await tester.enterText(
      find.byKey(const Key('autoparc-contact-phone')),
      '70000000',
    );
    await tester.tap(find.byKey(const Key('save-autoparc-contact')));
    await tester.pumpAndSettle();
    expect(api.writes, isEmpty);
    expect(
      find.textContaining('Saisissez un numéro international valide'),
      findsOneWidget,
    );
  });

  testWidgets('pendant la sauvegarde, les doubles envois sont empêchés', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    final api = _Api()..pendingSave = pending;
    await _open(tester, api);
    await tester.enterText(
      find.byKey(const Key('autoparc-contact-phone')),
      '+22670000002',
    );
    await tester.tap(find.byKey(const Key('save-autoparc-contact')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('save-autoparc-contact')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('autoparc-contact-phone')),
          )
          .enabled,
      isFalse,
    );
    expect(api.writes, hasLength(1));
    pending.complete({'phone': '+22670000002'});
    await tester.pumpAndSettle();
  });

  testWidgets(
    'une sauvegarde échouée conserve la saisie et permet de réessayer',
    (tester) async {
      final api = _Api()
        ..saveError = const ApiException(
          statusCode: 503,
          message: 'Indisponible',
        );
      final container = await _open(tester, api);
      await tester.enterText(
        find.byKey(const Key('autoparc-contact-phone')),
        '+22670000002',
      );
      await tester.tap(find.byKey(const Key('save-autoparc-contact')));
      await tester.pumpAndSettle();
      expect(container.read(autoparcContactProvider).phone, '+22670123456');
      expect(find.text('+22670000002'), findsOneWidget);
      expect(find.text('Numéro de contact AutoParc enregistré.'), findsNothing);
      api.saveError = null;
      await tester.tap(find.byKey(const Key('save-autoparc-contact')));
      await tester.pumpAndSettle();
      expect(container.read(autoparcContactProvider).phone, '+22670000002');
    },
  );
}
