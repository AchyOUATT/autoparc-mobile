import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_detail_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/features/vehicles/presentation/widgets/two_wheeler_configuration.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _GuestAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _GuestAuth() : super(const AuthState());

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

Vehicle vehicle() => Vehicle.fromJson({
  'id': 91,
  'reference': 'VH-MOTO',
  'designation': 'Yamaha YBR125E',
  'vehicle_type': 'two_wheeler',
  'registration_status': 'registered',
  'identity': {'brand': 'Yamaha', 'model': 'YBR125E', 'year': 2024},
  'commercial': {
    'condition': 'used',
    'status': 'in_stock',
    'availability': 'sale',
  },
  'technical': {
    'engine_displacement_cc': 125,
    'two_wheeler_configuration': {
      'body_type': 'motorcycle',
      'stroke': 'four_stroke',
      'cooling': 'air',
      'starter': 'electric',
      'drive': 'chain',
      'transmission': 'manual',
    },
  },
  'seller': {
    'id': 27,
    'company_name': 'Garage du vendeur',
    'phone': '+226 70 00 22 44',
  },
});

void main() {
  testWidgets('two-wheeler detail shows declared configuration in French', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((_) => _GuestAuth()),
          vehicleDetailProvider(91).overrideWith((_) async => vehicle()),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const VehicleDetailPage(vehicleId: 91),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TwoWheelerConfigurationDetails), findsOneWidget);
    await tester.ensureVisible(find.text('Configuration deux-roues'));
    await tester.pumpAndSettle();
    expect(find.text('Moto'), findsOneWidget);
    expect(find.text('4 temps'), findsOneWidget);
    expect(find.text('Air'), findsOneWidget);
    expect(find.text('Électrique'), findsOneWidget);
    expect(find.text('Chaîne'), findsOneWidget);
    expect(find.text('Manuelle'), findsOneWidget);
    expect(find.textContaining('125'), findsWidgets);
  });
}
