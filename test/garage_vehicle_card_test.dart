import 'dart:ui' show Tristate;

import 'package:auto/core/theme/app_theme.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/garage/data/models/fuel_fill.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/data/models/vehicle_check.dart';
import 'package:auto/features/garage/presentation/pages/garage_page.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/garage/presentation/widgets/garage_action_tiles.dart';
import 'package:auto/features/home/presentation/providers/home_providers.dart';
import 'package:auto/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/polices.dart';

/// La fiche d'un véhicule dans « Mon garage », présentée en tuiles.
///
/// Ce banc tient la promesse de la refonte : les mêmes fonctions qu'avant, les
/// mêmes destinations, et une présentation qui tient à 320 points avec le
/// texte agrandi, en clair comme en sombre, en français comme en anglais.

final _vehicule = OwnedVehicle(
  id: 42,
  designation: 'Toyota Corolla',
  nickname: 'Ma Corolla',
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
  ],
);

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth() : super(const AuthState(type: AuthType.client));
  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _Garage extends GarageNotifier {
  _Garage(this.vehicules);
  final List<OwnedVehicle> vehicules;
  @override
  Future<List<OwnedVehicle>> build() async => vehicules;
}

Widget _app({
  List<OwnedVehicle>? vehicules,
  String locale = 'fr',
  Brightness brightness = Brightness.light,
  double scale = 1,
}) {
  Widget destination(String nom) => Scaffold(body: Text('route:$nom'));
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const GaragePage()),
      GoRoute(
        path: '/garage/:id/check',
        builder: (_, s) => destination('check ${s.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/garage/:id/parts',
        builder: (_, s) => destination('parts ${s.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/garage/:id/edit',
        builder: (_, s) => destination('edit ${s.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/garage/:id/fuel',
        builder: (_, s) => destination('fuel ${s.pathParameters['id']}'),
      ),
      GoRoute(path: '/garage/add', builder: (_, _) => destination('add')),
      GoRoute(
        path: '/sell',
        builder: (_, s) =>
            destination('sell ${(s.extra as OwnedVehicle?)?.id}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((_) => _Auth()),
      garageProvider.overrideWith(() => _Garage(vehicules ?? [_vehicule])),
      unreadCountProvider.overrideWith((ref) async => 0),
    ],
    child: MaterialApp.router(
      routerConfig: router,
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
    ),
  );
}

Future<void> _taille(
  WidgetTester tester,
  double largeur, [
  double hauteur = 2400,
]) async {
  tester.view.physicalSize = Size(largeur, hauteur);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _tuile(String nom) => find.byKey(Key('garage-action-$nom-42'));

void main() {
  setUpAll(() async {
    await chargerPolices(exigerRoboto: false);
  });

  final tuiles = [
    'check',
    'parts',
    'mileage',
    'deadlines',
    'engine',
    if (privateSalesEnabled) 'sell',
  ];

  for (final locale in ['fr', 'en']) {
    for (final brightness in Brightness.values) {
      for (final largeur in [320.0, 390.0]) {
        for (final scale in [1.0, 1.3]) {
          testWidgets(
            'fiche $locale ${brightness.name} $largeur x$scale : toutes les '
            'actions, en tuiles de 48 points au moins, sans débordement',
            (tester) async {
              await _taille(tester, largeur);
              await tester.pumpWidget(
                _app(locale: locale, brightness: brightness, scale: scale),
              );
              await tester.pumpAndSettle();
              final l10n = await AppLocalizations.delegate.load(Locale(locale));

              expect(find.text('Ma Corolla'), findsOneWidget);
              expect(find.text('11 KM 4521'), findsOneWidget);
              expect(find.text('Toyota Corolla E210 · 2020'), findsOneWidget);
              expect(find.text(l10n.garageSectionMainActions), findsOneWidget);
              expect(find.text(l10n.garageSectionManage), findsOneWidget);
              expect(find.text(l10n.garageRepeatCheckAction), findsOneWidget);
              expect(find.text(l10n.garageMatchingPartsTitle), findsOneWidget);

              for (final nom in tuiles) {
                final rect = tester.getRect(_tuile(nom));
                expect(rect.height, greaterThanOrEqualTo(48), reason: nom);
                expect(rect.width, greaterThanOrEqualTo(48), reason: nom);
                expect(rect.right, lessThanOrEqualTo(largeur), reason: nom);
              }
              expect(
                _tuile('sell'),
                privateSalesEnabled ? findsOneWidget : findsNothing,
              );
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }

  testWidgets('les actions principales précèdent les autres et sont en '
      'pleine largeur', (tester) async {
    await _taille(tester, 390);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final check = tester.getRect(_tuile('check'));
    final parts = tester.getRect(_tuile('parts'));
    final mileage = tester.getRect(_tuile('mileage'));
    final deadlines = tester.getRect(_tuile('deadlines'));
    expect(parts.top, greaterThan(check.bottom));
    expect(parts.width, check.width);
    expect(mileage.top, greaterThan(parts.bottom));
    // Grille de deux colonnes à 390 points.
    expect(deadlines.top, mileage.top);
    expect(mileage.width, lessThan(check.width / 2 + 1));
  });

  for (final (nom, route) in [
    ('check', 'route:check 42'),
    ('parts', 'route:parts 42'),
    if (privateSalesEnabled) ('sell', 'route:sell 42'),
  ]) {
    testWidgets('la tuile $nom mène à la même destination qu’avant', (
      tester,
    ) async {
      await _taille(tester, 390);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.tap(_tuile(nom));
      await tester.pumpAndSettle();
      expect(find.text(route), findsOneWidget);
    });
  }

  testWidgets('la tuile Kilométrage ouvre la saisie du kilométrage', (
    tester,
  ) async {
    await _taille(tester, 390);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(_tuile('mileage'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('la tuile Échéances et le bouton Modifier ouvrent la saisie '
      'des échéances', (tester) async {
    await _taille(tester, 390);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

    await tester.tap(_tuile('deadlines'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text(l10n.garageMaintenanceTitle), findsNWidgets(2));
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);

    await tester.tap(find.text(l10n.garageDeadlinesEditAction));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('la tuile Moteur ouvre les détails du moteur', (tester) async {
    await _taille(tester, 390);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    // Insécable : « 140 ch » ne se coupe plus avant « ch ».
    expect(
      find.text(l10n.garageEnginePowerValue(140).replaceAll(' ', '\u00A0')),
      findsOneWidget,
    );
    await tester.tap(_tuile('engine'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('le menu garde Modifier et Retirer, avec une info-bulle', (
    tester,
  ) async {
    await _taille(tester, 390);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    await tester.tap(find.byTooltip(l10n.garageVehicleMoreActions));
    await tester.pumpAndSettle();
    expect(find.text(l10n.garageRemoveVehicleAction), findsOneWidget);
    await tester.tap(find.text(l10n.garageEditVehicleAction));
    await tester.pumpAndSettle();
    expect(find.text('route:edit 42'), findsOneWidget);
  });

  testWidgets('sans contrôle ni échéance, les tuiles proposent de commencer', (
    tester,
  ) async {
    await _taille(tester, 390);
    await tester.pumpWidget(
      _app(
        vehicules: [
          const OwnedVehicle(
            id: 42,
            designation: 'Toyota Corolla',
            brandId: 1,
            vehicleModelId: 1,
            year: 2020,
            identity: OwnedVehicleIdentity(brand: 'Toyota', model: 'Corolla'),
            compatibilityReady: false,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.garageCheckVehicleAction), findsOneWidget);
    expect(find.text(l10n.garageTileCheckSubtitle), findsOneWidget);
    expect(find.text(l10n.garageTileDeadlinesSubtitle), findsOneWidget);
    expect(find.text(l10n.garageTileEngineSubtitle), findsOneWidget);
    // Pas de section des échéances quand rien n'est suivi.
    expect(find.text(l10n.garageDeadlinesEditAction), findsNothing);
    expect(find.text(l10n.garagePreciseCompatibility), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('les titres de section sont annoncés comme des en-têtes', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _taille(tester, 390);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    for (final titre in [
      l10n.garageSectionMainActions,
      l10n.garageSectionManage,
      l10n.garageSectionConsumption,
    ]) {
      expect(
        tester.getSemantics(find.text(titre)).flagsCollection.isHeader,
        isTrue,
        reason: titre,
      );
    }
    final check = tester.getSemantics(_tuile('check'));
    expect(check.flagsCollection.isButton, isTrue);
    expect(check.label, contains(l10n.garageRepeatCheckAction));
    handle.dispose();
  });

  // ── Plusieurs véhicules ─────────────────────────────────────────────────

  OwnedVehicle autre(int id, String surnom, {bool enRetard = false}) =>
      OwnedVehicle(
        id: id,
        designation: 'Hyundai Tucson',
        nickname: surnom,
        brandId: 2,
        vehicleModelId: 2,
        year: 2018,
        plateNumber: '11 LP 0$id',
        identity: const OwnedVehicleIdentity(brand: 'Hyundai', model: 'Tucson'),
        compatibilityReady: false,
        deadlines: [
          if (enRetard)
            const VehicleDeadline(
              kind: 'insurance',
              label: 'Assurance',
              daysLeft: -12,
              overdue: true,
            ),
        ],
      );

  testWidgets('un seul véhicule : pas de sélecteur, la fiche seule', (
    tester,
  ) async {
    await _taille(tester, 390, 844);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.garageMyVehiclesCount('1')), findsNothing);
    expect(find.byKey(const Key('garage-vehicle-choice-42')), findsNothing);
    expect(find.text(l10n.garageAddVehicleAction), findsOneWidget);
  });

  for (final nombre in [2, 3]) {
    for (final largeur in [320.0, 390.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
          '$nombre véhicules en $largeur x$scale : un sélecteur, une seule '
          'fiche, et l’ajout toujours visible',
          (tester) async {
            final hauteur = largeur == 320 ? 640.0 : 844.0;
            await _taille(tester, largeur, hauteur);
            final vehicules = [
              _vehicule,
              autre(43, 'Le Tucson'),
              if (nombre == 3) autre(44, 'La camionnette'),
            ];
            await tester.pumpWidget(_app(vehicules: vehicules, scale: scale));
            await tester.pumpAndSettle();
            final l10n = await AppLocalizations.delegate.load(
              const Locale('fr'),
            );

            expect(
              find.text(l10n.garageMyVehiclesCount('$nombre')),
              findsOneWidget,
            );
            for (final v in vehicules) {
              final choix = find.byKey(Key('garage-vehicle-choice-${v.id}'));
              expect(choix, findsOneWidget);
              expect(tester.getSize(choix).height, greaterThanOrEqualTo(48));
            }
            // Une seule fiche : celle du véhicule choisi.
            expect(
              find.byWidgetPredicate(
                (w) =>
                    w.key is ValueKey<String> &&
                    (w.key! as ValueKey<String>).value.startsWith(
                      'garage-action-check-',
                    ),
              ),
              findsOneWidget,
            );

            // Le sélecteur et le haut de la fiche tiennent dans le premier
            // écran : les autres véhicules se voient sans défiler la fiche.
            final selecteur = tester.getRect(
              find.byKey(const Key('garage-vehicle-choice-42')),
            );
            expect(selecteur.bottom, lessThan(hauteur / 3));

            // L'ajout reste à portée.
            expect(find.text(l10n.garageAddVehicleAction), findsOneWidget);
            final fab = tester.getRect(find.byType(FloatingActionButton));
            expect(fab.bottom, lessThanOrEqualTo(hauteur));

            // Changer de véhicule change la fiche.
            await tester.tap(find.byKey(const Key('garage-vehicle-choice-43')));
            await tester.pumpAndSettle();
            expect(
              find.byKey(const Key('garage-action-check-43')),
              findsOneWidget,
            );
            expect(
              find.byKey(const Key('garage-action-check-42')),
              findsNothing,
            );

            // Le véhicule choisi est visible dans la rangée.
            final choisi = tester.getRect(
              find.byKey(const Key('garage-vehicle-choice-43')),
            );
            expect(choisi.left, greaterThanOrEqualTo(0));
            expect(choisi.right, lessThanOrEqualTo(largeur));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('sans choix, le garage affiche le véhicule le plus urgent, '
      'comme l’accueil, et le montre dans la rangée', (tester) async {
    await _taille(tester, 320, 640);
    await tester.pumpWidget(
      _app(
        vehicules: [
          autre(43, 'Le Tucson'),
          autre(44, 'La camionnette'),
          autre(45, 'Le pick-up', enRetard: true),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('garage-action-check-45')), findsOneWidget);
    final choisi = tester.getRect(
      find.byKey(const Key('garage-vehicle-choice-45')),
    );
    expect(choisi.left, greaterThanOrEqualTo(0));
    expect(choisi.right, lessThanOrEqualTo(320));
  });

  testWidgets('le choix fait dans le garage est celui de l’accueil', (
    tester,
  ) async {
    await _taille(tester, 390, 844);
    await tester.pumpWidget(
      _app(vehicules: [_vehicule, autre(43, 'Le Tucson')]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('garage-vehicle-choice-43')));
    await tester.pumpAndSettle();
    final conteneur = ProviderScope.containerOf(
      tester.element(find.byType(GaragePage)),
    );
    expect(conteneur.read(homeSelectedVehicleIdProvider), 43);
  });

  testWidgets('chaque véhicule de la rangée est un bouton, l’affiché est '
      'annoncé sélectionné, l’alerte est dite', (tester) async {
    final handle = tester.ensureSemantics();
    await _taille(tester, 390, 844);
    await tester.pumpWidget(
      _app(vehicules: [_vehicule, autre(43, 'Le Tucson', enRetard: true)]),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    final tucson = tester.getSemantics(
      find.byKey(const Key('garage-vehicle-choice-43')),
    );
    expect(tucson.flagsCollection.isButton, isTrue);
    expect(tucson.label, contains('Le Tucson'));
    expect(tucson.label, contains(l10n.garageVehicleNeedsAttention));
    // Le plus urgent est affiché par défaut : le Tucson en retard.
    expect(tucson.flagsCollection.isSelected, Tristate.isTrue);
    handle.dispose();
  });

  test('keepTogether ne garde que les « · » comme points de coupure', () {
    expect(keepTogether('1,8 L · 140 ch'), '1,8\u00A0L · 140\u00A0ch');
    expect(keepTogether('Dans 25 j'), 'Dans\u00A025\u00A0j');
  });
}
