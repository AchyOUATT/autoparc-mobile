import 'dart:convert';
import 'dart:io';

import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les photos d'un véhicule déjà enregistré doivent rester joignables.
///
/// ── CE QUI MANQUAIT ────────────────────────────────────────────────────────
///
/// L'écran des médias ne s'ouvrait que par le `pushReplacement` qui suit une
/// CRÉATION — « Véhicule enregistré, ajoutez des photos ! ». Une modification
/// se contentait de refermer l'écran. Passé ce premier instant, plus aucun
/// chemin de l'application ne menait aux photos d'un véhicule : ni depuis
/// l'écran de modification, ni depuis la fiche détaillée.
///
/// L'asymétrie saute aux yeux une fois cherchée : la pièce et l'accessoire
/// ont DEUX accès chacun — un bouton sur leur écran de modification, un autre
/// sur leur fiche. Le véhicule n'en avait aucun, alors que c'est l'article
/// dont les photos comptent le plus et qui en porte le plus.
///
/// ── POURQUOI UN TEST DE PRÉSENCE SUFFIT ICI ───────────────────────────────
///
/// Le défaut n'était pas que le bouton marchait mal : c'est qu'il n'existait
/// pas. Ce que ce banc garde, c'est le chemin — et son absence à la création,
/// où le véhicule n'a pas encore d'identifiant auquel rattacher une photo.

Vehicle _vehicule() {
  final json =
      (jsonDecode(File('test/fixtures/vehicles_list.json').readAsStringSync())
              as Map<String, dynamic>)['data'][0] as Map<String, dynamic>;
  return Vehicle.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
}

const _refs = CatalogRefs(
  brands: [],
  vehicleModels: [],
  trims: [],
  engineTypes: [],
  drivetrains: [],
  colors: [],
  features: [],
  locations: [],
);

Widget _ecran({Vehicle? existant}) => ProviderScope(
      overrides: [catalogRefsProvider.overrideWith((_) async => _refs)],
      child: MaterialApp(home: VehicleRegisterPage(existing: existant)),
    );

Finder get _boutonPhotos => find.byTooltip('Photos');

void main() {
  testWidgets('un véhicule enregistré donne accès à ses photos', (tester) async {
    await tester.pumpWidget(_ecran(existant: _vehicule()));
    await tester.pumpAndSettle();

    expect(
      _boutonPhotos,
      findsOneWidget,
      reason: 'Sans ce bouton, les photos d’un véhicule déjà enregistré sont '
          'injoignables : l’écran des médias ne s’ouvrait qu’une fois, juste '
          'après la création.',
    );
  });

  testWidgets('à la création, le bouton n’a pas lieu d’être', (tester) async {
    // Le véhicule n'a pas encore d'identifiant auquel rattacher une photo —
    // l'écran des médias s'ouvre de lui-même juste après l'enregistrement.
    // Même condition que sur l'écran d'une pièce.
    await tester.pumpWidget(_ecran());
    await tester.pumpAndSettle();

    expect(_boutonPhotos, findsNothing);
  });
}
