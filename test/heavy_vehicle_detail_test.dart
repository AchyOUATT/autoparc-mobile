import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_detail_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/vehicles/presentation/widgets/heavy_vehicle_configuration.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _GuestAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _GuestAuth() : super(const AuthState());

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

Vehicle vehicle(String type, {Map<String, dynamic>? configuration}) =>
    Vehicle.fromJson({
      'id': 71,
      'reference': 'VH-HEAVY',
      'designation': 'Véhicule de démonstration',
      'vehicle_type': type,
      'registration_status': 'registered',
      'identity': {'brand': 'MAN', 'model': 'TGX', 'year': 2020},
      'commercial': {
        'condition': 'used',
        'status': 'in_stock',
        'availability': 'sale',
      },
      'technical': {'heavy_configuration': configuration},
      'seller': {
        'id': 27,
        'company_name': 'Garage du vendeur',
        'phone': '+226 70 00 22 44',
      },
    });

Future<void> mount(WidgetTester tester, Vehicle value) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => _GuestAuth()),
        vehicleDetailProvider(value.id).overrideWith((_) async => value),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: VehicleDetailPage(vehicleId: value.id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('heavy detail displays declared configuration with exact axles', (
    tester,
  ) async {
    await mount(
      tester,
      vehicle(
        'heavy',
        configuration: {
          'version_label': '460',
          'axle_configuration': '6x2*4',
          'chassis_type': 'tractor',
          'ptac_kg': 26000,
          'ptra_kg': 44000,
        },
      ),
    );
    expect(find.byType(VehicleDetailPage), findsOneWidget);
    expect(find.byType(HeavyVehicleConfigurationDetails), findsOneWidget);
    await tester.ensureVisible(find.text('Configuration poids lourd'));
    await tester.pumpAndSettle();
    expect(find.text('Données déclarées'), findsOneWidget);
    expect(find.text('460'), findsOneWidget);
    expect(find.text('6x2*4'), findsOneWidget);
    expect(find.text('6x2/4'), findsNothing);
    expect(find.text('Tracteur routier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('heavy detail with no declared configuration hides the section', (
    tester,
  ) async {
    await mount(tester, vehicle('heavy'));
    expect(find.byType(VehicleDetailPage), findsOneWidget);
    expect(find.byType(HeavyVehicleConfigurationDetails), findsNothing);
    expect(find.text('Configuration poids lourd'), findsNothing);
    expect(find.text('Données déclarées'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('passenger detail hides inherited heavy configuration', (
    tester,
  ) async {
    final passenger = vehicle(
      'passenger',
      configuration: {'version_label': '460', 'axle_configuration': '6x2/4'},
    );
    expect(passenger.heavyConfiguration.isEmpty, isFalse);
    await mount(tester, passenger);
    expect(find.byType(VehicleDetailPage), findsOneWidget);
    expect(find.byType(HeavyVehicleConfigurationDetails), findsNothing);
    expect(find.text('Configuration poids lourd'), findsNothing);
    expect(find.text('Données déclarées'), findsNothing);
    expect(find.text('6x2/4'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('heavy detail shows typed volume, tank, payload and body type', (
    tester,
  ) async {
    await mount(
      tester,
      vehicle(
        'heavy',
        configuration: {
          'body_type': 'tanker',
          'useful_volume_m3': 19.32,
          'tank_capacity_liters': 45000,
          'payload_kg': 60000,
        },
      ),
    );
    expect(find.byType(HeavyVehicleConfigurationDetails), findsOneWidget);
    await tester.ensureVisible(find.text('Citerne'));
    await tester.pumpAndSettle();
    expect(find.text('Citerne'), findsOneWidget);
    expect(find.text('19,32 m³'), findsOneWidget);
    expect(find.text('45 000 L'), findsOneWidget);
    expect(find.text('60 000 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
