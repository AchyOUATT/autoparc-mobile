import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_detail_page.dart';
import 'package:auto/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le dédouanement n'a que deux états : fait, ou non.
///
/// La fiche montrait « ⏳ En attente » quand `customs_cleared` était faux.
/// Ce libellé décrivait une procédure en cours, alors qu'un véhicule est
/// dédouané ou ne l'est pas. Ce banc tient le libellé binaire sur la fiche,
/// et le parsing d'une valeur inconnue — y compris un reliquat textuel
/// « en cours » — qui doit tomber sur non dédouané sans faire échouer la
/// fiche entière.

class _Invite extends StateNotifier<AuthState> implements AuthNotifier {
  _Invite() : super(const AuthState());

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

Vehicle _importe({Object? customsCleared = false}) {
  return Vehicle.fromJson({
    'id': 18,
    'reference': 'IMP-0018',
    'designation': 'Toyota Corolla',
    'registration_status': {
      'value': 'unregistered',
      'label': 'Non immatricule',
    },
    'vehicle_type': 'passenger',
    'identity': {'brand': 'Toyota', 'model': 'Corolla', 'year': 2016},
    'technical': {'mileage_km': 85000},
    'commercial': {
      'condition': 'used',
      'status': 'in_stock',
      'availability': 'sale',
      'sale_price': 6500000,
    },
    'import': {
      'origin_country': 'Japon',
      'origin_country_iso2': 'JP',
      'customs_cleared': customsCleared,
    },
  });
}

Future<void> _ouvrir(WidgetTester tester, Vehicle vehicule) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((_) => _Invite()),
        vehicleDetailProvider(vehicule.id).overrideWith((_) async => vehicule),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: VehicleDetailPage(vehicleId: vehicule.id),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('une valeur inconnue de dédouanement se lit comme non dédouané', () {
    expect(
      VehicleImport.fromJson({'customs_cleared': true}).customsCleared,
      isTrue,
    );
    expect(
      VehicleImport.fromJson({'customs_cleared': false}).customsCleared,
      isFalse,
    );
    expect(VehicleImport.fromJson({}).customsCleared, isFalse);
    expect(
      VehicleImport.fromJson({'customs_cleared': 1}).customsCleared,
      isTrue,
    );
    expect(
      VehicleImport.fromJson({'customs_cleared': 0}).customsCleared,
      isFalse,
    );
    expect(
      VehicleImport.fromJson({'customs_cleared': 'en cours'}).customsCleared,
      isFalse,
    );
    expect(
      VehicleImport.fromJson({'customs_cleared': 'pending'}).customsCleared,
      isFalse,
    );
    expect(
      VehicleImport.fromJson({'customs_cleared': 'in_progress'}).customsCleared,
      isFalse,
    );
  });

  testWidgets('la fiche d’un importé non dédouané dit Non, pas En attente', (
    tester,
  ) async {
    await _ouvrir(tester, _importe());
    final l10n = AppLocalizations.of(
      tester.element(find.byType(VehicleDetailPage)),
    );

    expect(find.text(l10n.catalogCustomsCleared), findsOneWidget);
    expect(find.text(l10n.catalogCustomsNo), findsOneWidget);
    expect(find.text('✗ Non'), findsOneWidget);
    expect(find.text('⏳ En attente'), findsNothing);
    expect(find.text('En cours'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la fiche d’un importé dédouané dit Oui', (tester) async {
    await _ouvrir(tester, _importe(customsCleared: true));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(VehicleDetailPage)),
    );

    expect(find.text(l10n.catalogCustomsYes), findsOneWidget);
    expect(find.text('✓ Oui'), findsOneWidget);
    expect(find.text(l10n.catalogCustomsNo), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
