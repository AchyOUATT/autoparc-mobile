import 'dart:io';

import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/garage/data/models/fuel_fill.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/data/models/vehicle_check.dart';
import 'package:auto/features/garage/presentation/pages/garage_page.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/polices.dart';

/// Captures de la fiche d'un véhicule dans « Mon garage ».
///
/// Les PNG ne sont écrits que sur demande, pour la même raison que les autres
/// bancs de capture : un golden dépend de la plateforme de rendu.
///
///   CAPTURES=1 flutter test test/captures_garage_vehicule_test.dart \
///     --update-goldens --dart-define=ENABLE_PRIVATE_SALES=true
///
/// Hors de ce mode, le test rend les mêmes écrans et vérifie qu'ils tiennent.
/// Données fictives.
final vehiculeCapture = OwnedVehicle(
  id: 900001,
  designation: 'Toyota Corolla Touring Sports',
  nickname: 'Ma Corolla familiale',
  brandId: 1,
  vehicleModelId: 1,
  year: 2020,
  plateNumber: '11 KM 4521',
  mileageKm: 97432,
  identity: const OwnedVehicleIdentity(
    brand: 'Toyota',
    brandSlug: 'toyota',
    model: 'Corolla',
    trim: 'E210',
    engineType: 'Essence',
    engineTypeCode: 'petrol',
    color: 'Blanc',
  ),
  compatibilityReady: true,
  engineDataProvided: true,
  engineDisplacementL: 1.8,
  cylinders: 4,
  powerHp: 140,
  fuelTracking: const FuelTracking(),
  lastCheck: LastCheck(
    id: 1,
    performedAt: DateTime.now().subtract(const Duration(days: 3)),
    verdict: 'watch',
    verdictLabel: 'À surveiller',
    blockingCount: 0,
    watchCount: 2,
  ),
  deadlines: const [
    VehicleDeadline(
      kind: 'insurance',
      label: 'Assurance',
      daysLeft: 25,
      overdue: false,
    ),
    VehicleDeadline(
      kind: 'technical_inspection',
      label: 'Visite technique',
      daysLeft: 140,
      overdue: false,
    ),
    VehicleDeadline(
      kind: 'service',
      label: 'Vidange',
      detail: 'Dans 568 km',
      overdue: false,
    ),
  ],
);

/// Deux autres véhicules, pour les captures d'un garage qui en compte
/// plusieurs. Fictifs eux aussi.
const vehiculeCapture2 = OwnedVehicle(
  id: 900002,
  designation: 'Hyundai Tucson',
  nickname: 'Le Tucson',
  brandId: 2,
  vehicleModelId: 2,
  year: 2018,
  plateNumber: '11 LP 0937',
  mileageKm: 154200,
  identity: OwnedVehicleIdentity(
    brand: 'Hyundai',
    brandSlug: 'hyundai',
    model: 'Tucson',
    engineType: 'Diesel',
    engineTypeCode: 'diesel',
  ),
  compatibilityReady: true,
  engineDataProvided: true,
  deadlines: [
    VehicleDeadline(
      kind: 'insurance',
      label: 'Assurance',
      daysLeft: -12,
      overdue: true,
    ),
  ],
);

const vehiculeCapture3 = OwnedVehicle(
  id: 900003,
  designation: 'Yamaha Crypton',
  brandId: 3,
  vehicleModelId: 3,
  vehicleType: 'two_wheeler',
  year: 2022,
  plateNumber: '11 AB 2210',
  mileageKm: 8300,
  identity: OwnedVehicleIdentity(
    brand: 'Yamaha',
    brandSlug: 'yamaha',
    model: 'Crypton',
    engineType: 'Essence',
    engineTypeCode: 'petrol',
  ),
  compatibilityReady: false,
  engineDataProvided: true,
);

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(const AuthState(type: AuthType.client));
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Garage extends GarageNotifier {
  _Garage(this.nombre);
  final int nombre;
  @override
  Future<List<OwnedVehicle>> build() async => [
    vehiculeCapture,
    vehiculeCapture2,
    vehiculeCapture3,
  ].take(nombre).toList();
}

Widget ecranGarage({
  Brightness brightness = Brightness.light,
  String locale = 'fr',
  double scale = 1,
  int vehicules = 1,
}) => ProviderScope(
  overrides: [
    authProvider.overrideWith((_) => _Auth()),
    garageProvider.overrideWith(() => _Garage(vehicules)),
    unreadCountProvider.overrideWith((ref) async => 0),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: themeAutoParc(brightness),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const GaragePage(),
  ),
);

void main() {
  final ecrire = Platform.environment['CAPTURES'] == '1';
  final suffixe = Platform.environment['CAPTURES_SUFFIXE'] ?? 'apres';

  setUpAll(() async {
    await chargerPolices(exigerRoboto: false);
  });

  for (final largeur in [390.0, 320.0]) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 1.3]) {
        final nom =
            'garage-vehicule-$suffixe-${largeur.toInt()}-${brightness.name}'
            '${scale == 1 ? '' : '-x13'}';
        testWidgets(nom, (tester) async {
          tester.view.physicalSize = Size(largeur, scale == 1 ? 1500 : 2100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ecranGarage(brightness: brightness, scale: scale),
          );
          await tester.pumpAndSettle();

          expect(find.text('Ma Corolla familiale'), findsOneWidget);
          expect(tester.takeException(), isNull);

          if (ecrire) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('../build/captures/$nom.png'),
            );
          }
        });
      }
    }
  }

  // ── Plusieurs véhicules, sur un écran de téléphone réel ──────────────
  //
  // Hauteur d'écran vraie (844 et 640) : c'est ce que voit le propriétaire en
  // ouvrant son garage, donc ce qui dit s'il retrouve ses autres véhicules.
  for (final (largeur, hauteur) in [(390.0, 844.0), (320.0, 640.0)]) {
    for (final nombre in [2, 3]) {
      for (final scale in [1.0, 1.3]) {
        final nom =
            'garage-${nombre}vehicules-$suffixe-${largeur.toInt()}-light'
            '${scale == 1 ? '' : '-x13'}';
        testWidgets(nom, (tester) async {
          tester.view.physicalSize = Size(largeur, hauteur);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(ecranGarage(scale: scale, vehicules: nombre));
          await tester.pumpAndSettle();

          expect(find.text('Ma Corolla familiale'), findsWidgets);
          expect(tester.takeException(), isNull);

          if (ecrire) {
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('../build/captures/$nom.png'),
            );
          }
        });
      }
    }
  }
}
