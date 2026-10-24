import 'dart:convert';
import 'dart:io';

import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// « Immatriculé » se déclare à l'enregistrement.
///
/// ── CE QUI MANQUAIT, ET OÙ ─────────────────────────────────────────────────
///
/// Le propriétaire demandait de pouvoir marquer un véhicule immatriculé sans
/// fournir sa plaque. Le correctif serveur l'a permis — `store()` ne déduit
/// plus le statut que lorsque le champ est absent — mais le FORMULAIRE
/// continuait de tout dériver de `hasPlate` :
///
///   - `registration_status` n'était jamais envoyé ;
///   - avec plaque, le kilométrage partait dans `registration` ;
///   - sans plaque, dans `import.odometer_at_import_km` ;
///   - et le champ « pays d'origine » n'apparaissait que sans plaque.
///
/// Ouvrir la porte côté serveur ne changeait donc rien à la saisie : le
/// client reproduisait l'ancienne règle de son côté. C'est le même défaut de
/// périmètre que le filtre `is_active`, corrigé sur une route que
/// l'application n'utilisait pas.
///
/// ── CE QUE CE BANC TIENT ───────────────────────────────────────────────────
///
/// Le commutateur existe, part à faux en création, se coche quand on saisit
/// une plaque, et — le cas qui compte — se retrouve coché quand on MODIFIE un
/// véhicule déjà immatriculé. Sans cette dernière ligne, rouvrir une fiche
/// immatriculée pour corriger un prix la renverrait « non immatriculé », la
/// charge utile déclarant désormais le statut explicitement.

Map<String, dynamic> _gabarit() =>
    (jsonDecode(File('test/fixtures/vehicles_list.json').readAsStringSync())
            as Map<String, dynamic>)['data'][0] as Map<String, dynamic>;

Vehicle _vehicule({required bool immatricule}) {
  final json = jsonDecode(jsonEncode(_gabarit())) as Map<String, dynamic>;
  json['registration_status'] = <String, dynamic>{
    'value': immatricule ? 'registered' : 'unregistered',
    'label': immatricule ? 'Deja immatricule' : 'Non immatricule',
  };
  return Vehicle.fromJson(json);
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
      overrides: [
        catalogRefsProvider.overrideWith((_) async => _refs),
      ],
      child: MaterialApp(home: VehicleRegisterPage(existing: existant)),
    );

/// L'état du commutateur « Véhicule immatriculé », lu sur le widget rendu.
bool _commutateur(WidgetTester tester) {
  final tuile = tester.widget<SwitchListTile>(
    find.widgetWithText(SwitchListTile, 'Véhicule immatriculé'),
  );
  return tuile.value;
}

void main() {
  testWidgets('le commutateur existe et part à faux en création', (tester) async {
    await tester.pumpWidget(_ecran());
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(SwitchListTile, 'Véhicule immatriculé'),
      findsOneWidget,
      reason: 'Sans ce commutateur, « immatriculé » ne peut que se déduire '
          'de la plaque — ce qui est exactement le défaut corrigé.',
    );
    expect(_commutateur(tester), isFalse);
  });

  testWidgets('saisir une plaque déclare le véhicule immatriculé', (tester) async {
    await tester.pumpWidget(_ecran());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Plaque d\'immatriculation (optionnel)'),
      'AA 1234 BF',
    );
    await tester.pump();

    expect(
      _commutateur(tester),
      isTrue,
      reason: 'Une plaque saisie est le sens courant de « immatriculé » : '
          'ne pas le cocher obligerait à dire deux fois la même chose.',
    );
  });

  testWidgets('modifier un véhicule immatriculé retrouve son statut', (tester) async {
    // LE CAS QUI COMPTE. Le formulaire déclare désormais le statut
    // explicitement : un commutateur parti à faux renverrait « non
    // immatriculé » à la première correction de prix, et ferait basculer la
    // fiche du côté import.
    await tester.pumpWidget(_ecran(existant: _vehicule(immatricule: true)));
    await tester.pumpAndSettle();

    expect(
      _commutateur(tester),
      isTrue,
      reason: 'Rouvrir une fiche immatriculée pour corriger un prix la '
          'renverrait « non immatriculé ».',
    );
  });

  testWidgets('modifier un importé le laisse non immatriculé', (tester) async {
    await tester.pumpWidget(_ecran(existant: _vehicule(immatricule: false)));
    await tester.pumpAndSettle();

    expect(_commutateur(tester), isFalse);
  });
}
