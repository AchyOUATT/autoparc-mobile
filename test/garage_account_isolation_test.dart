import 'dart:async';

import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/garage/data/garage_repository.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _User extends Fake implements User {
  _User(this.uid);
  @override
  final String uid;
}

AuthState _client(String uid) =>
    AuthState(type: AuthType.client, firebaseUser: _User(uid));

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(super.state);
  void change(AuthState value) => state = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Garage extends Fake implements GarageRepository {
  final reads = <Completer<List<OwnedVehicle>>>[];
  final additions = <Completer<OwnedVehicle>>[];

  @override
  Future<List<OwnedVehicle>> getVehicles() {
    final result = Completer<List<OwnedVehicle>>();
    reads.add(result);
    return result.future;
  }

  @override
  Future<OwnedVehicle> addVehicle(Map<String, dynamic> payload) {
    final result = Completer<OwnedVehicle>();
    additions.add(result);
    return result.future;
  }
}

OwnedVehicle _vehicle(int id) => OwnedVehicle(
  id: id,
  designation: 'Vehicle $id',
  brandId: 1,
  year: 2020,
  identity: const OwnedVehicleIdentity(brand: 'Toyota', model: 'Corolla'),
  compatibilityReady: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Auth auth;
  late _Garage repository;
  late ProviderContainer container;

  setUp(() {
    auth = _Auth(_client('A'));
    repository = _Garage();
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((_) => auth),
        garageRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.listen(garageProvider, (_, _) {}, fireImmediately: true);
  });
  tearDown(() => container.dispose());

  Future<void> loadA() async {
    repository.reads.single.complete([_vehicle(1)]);
    await container.read(garageProvider.future);
  }

  test(
    'switching client UID clears previous vehicles and selected vehicle',
    () async {
      await loadA();
      container.read(selectedGarageVehicleProvider.notifier).state = _vehicle(
        1,
      );

      auth.change(_client('B'));
      await container.pump();

      expect(container.read(garageProvider).valueOrNull, isEmpty);
      expect(container.read(garageProvider).hasError, isFalse);
      expect(container.read(selectedGarageVehicleProvider), isNull);
      expect(repository.reads, hasLength(2));
      repository.reads.last.complete([_vehicle(2)]);
      expect(await container.read(garageProvider.future), [_vehicle(2)]);
    },
  );

  test(
    'a rejected account does not leave its error in the next garage',
    () async {
      final failed = expectLater(
        container.read(garageProvider.future),
        throwsA(isA<ApiException>()),
      );
      repository.reads.single.completeError(
        const ApiException(statusCode: 403, message: 'Account A rejected'),
      );
      await failed;
      expect(container.read(garageProvider).hasError, isTrue);

      auth.change(_client('B'));
      await container.pump();
      expect(container.read(garageProvider).hasError, isFalse);
      expect(container.read(garageProvider).valueOrNull, isEmpty);
      repository.reads.last.complete([_vehicle(2)]);
      expect(await container.read(garageProvider.future), [_vehicle(2)]);
    },
  );

  test(
    'signing out clears vehicles and selection without another API request',
    () async {
      await loadA();
      container.read(selectedGarageVehicleProvider.notifier).state = _vehicle(
        1,
      );

      auth.change(const AuthState());
      await container.pump();

      expect(await container.read(garageProvider.future), isEmpty);
      expect(container.read(selectedGarageVehicleProvider), isNull);
      expect(repository.reads, hasLength(1));
      await container.read(garageProvider.notifier).refresh();
      expect(repository.reads, hasLength(1));
    },
  );

  test(
    'a previous account initial response cannot replace the next account',
    () async {
      auth.change(_client('B'));
      await container.pump();
      repository.reads.last.complete([_vehicle(2)]);
      await container.read(garageProvider.future);

      repository.reads.first.complete([_vehicle(1)]);
      await container.pump();

      expect(container.read(garageProvider).requireValue, [_vehicle(2)]);
    },
  );

  test(
    'a previous account manual refresh error cannot replace the next garage',
    () async {
      await loadA();
      final refresh = container.read(garageProvider.notifier).refresh();
      final pending = repository.reads.last;

      auth.change(_client('B'));
      await container.pump();
      repository.reads.last.complete([_vehicle(2)]);
      await container.read(garageProvider.future);
      pending.completeError(
        const ApiException(statusCode: 403, message: 'Old session'),
      );
      await refresh;

      expect(container.read(garageProvider).requireValue, [_vehicle(2)]);
    },
  );

  test(
    'a previous account completed addition cannot enter the next garage',
    () async {
      await loadA();
      final addition = container.read(garageProvider.notifier).addVehicle({});

      auth.change(_client('B'));
      await container.pump();
      repository.reads.last.complete([_vehicle(2)]);
      await container.read(garageProvider.future);
      repository.additions.single.complete(_vehicle(3));
      await addition;

      expect(container.read(garageProvider).requireValue, [_vehicle(2)]);
    },
  );

  test(
    'a refresh started before sign-out cannot restore the old vehicles',
    () async {
      await loadA();
      final refresh = container.read(garageProvider.notifier).refresh();
      final pending = repository.reads.last;

      auth.change(const AuthState());
      await container.pump();
      pending.complete([_vehicle(1)]);
      await refresh;

      expect(container.read(garageProvider).requireValue, isEmpty);
      expect(repository.reads, hasLength(2));
    },
  );

  test(
    'refreshing an auth state for the same UID retains its garage',
    () async {
      await loadA();
      container.read(selectedGarageVehicleProvider.notifier).state = _vehicle(
        1,
      );
      auth.change(_client('A'));
      await container.pump();

      expect(repository.reads, hasLength(1));
      expect(container.read(garageProvider).requireValue, [_vehicle(1)]);
      expect(container.read(selectedGarageVehicleProvider), _vehicle(1));
    },
  );

  test(
    'client auth without a Firebase user remains usable with an injected repository',
    () async {
      await loadA();
      auth.change(const AuthState(type: AuthType.client));
      await container.pump();

      repository.reads.last.complete([_vehicle(4)]);
      expect(await container.read(garageProvider.future), [_vehicle(4)]);
    },
  );
}
