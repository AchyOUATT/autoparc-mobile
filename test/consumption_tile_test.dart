import 'package:auto/features/garage/data/models/motorisation.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/widgets/consumption_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// La consommation affichée au propriétaire.
///
/// La fiche du garage ne porte que le chiffre : la motorisation, la boîte et
/// la provenance de la cote appartiennent au dialogue de choix, où elles
/// éclairent la décision. Sur une carte qui doit se lire d'un coup d'œil,
/// entre le kilométrage et les échéances, elles encombraient.
///
/// Et tant qu'aucune motorisation n'est choisie, l'application ne devine pas :
/// elle demande. Le catalogue connaît le modèle, mais rien ne dit lequel des
/// moteurs se trouve sous le capot.
void main() {
  OwnedVehicle vehicule({VehicleConsumption? conso, int? motorisationId}) =>
      OwnedVehicle(
        id: 1,
        designation: 'Toyota Camry 2013',
        brandId: 1,
        vehicleModelId: 7,
        year: 2013,
        identity: const OwnedVehicleIdentity(brand: 'Toyota', model: 'Camry'),
        compatibilityReady: true,
        motorisationId: motorisationId,
        consumption: conso,
      );

  const cote = VehicleConsumption(
    label: '2,5 l 4 cyl. boîte auto. 6',
    fuel: 'Essence ordinaire',
    cityL100km: 9.5,
    highwayL100km: 6.6,
    combinedL100km: 8.2,
    source: 'Ressources naturelles Canada',
    cycle: 'essai canadien, cinq cycles',
  );

  Widget ecran(OwnedVehicle v) => ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ConsumptionTile(vehicle: v)),
        ),
      );

  group('Consommation du véhicule', () {
    testWidgets('la fiche porte le chiffre, et lui seul', (tester) async {
      await tester.pumpWidget(ecran(vehicule(conso: cote)));

      expect(find.textContaining('8,2 l/100 km'), findsOneWidget);
      expect(find.textContaining('ville 9,5'), findsOneWidget);

      // La motorisation, la boîte et la provenance restent dans le dialogue
      // de choix : sur la fiche, elles encombrent une carte qui doit se lire
      // d'un coup d'œil.
      expect(find.textContaining('4 cyl.'), findsNothing);
      expect(find.textContaining('Ressources naturelles Canada'), findsNothing);
      expect(find.textContaining('cinq cycles'), findsNothing);
    });

    testWidgets('la virgule décimale est celle du français', (tester) async {
      await tester.pumpWidget(ecran(vehicule(conso: cote)));

      expect(find.textContaining('8.2'), findsNothing);
    });

    testWidgets('sans motorisation choisie, l\'application demande',
        (tester) async {
      await tester.pumpWidget(ecran(vehicule()));

      expect(find.text('Quelle est ma consommation ?'), findsOneWidget);
      expect(find.textContaining('l/100 km'), findsNothing,
          reason: 'Aucune estimation inventée en attendant le choix.');
    });
  });

  group('Lecture des motorisations', () {
    test('une motorisation se lit depuis la réponse du serveur', () {
      final m = Motorisation.fromJson({
        'id': 12,
        'label': '3,5 l 6 cyl. boîte auto. 6',
        'model_year': 2013,
        'fuel': 'Essence ordinaire',
        // Laravel sérialise les décimaux en chaînes : c'est ce qui avait
        // cassé tout le catalogue la première fois.
        'engine_l': '3.5',
        'cylinders': 6,
        'consumption': {
          'city_l_100km': '11.0',
          'highway_l_100km': '7.5',
          'combined_l_100km': '9.4',
        },
        'source': {
          'code': 'nrcan',
          'label': 'Ressources naturelles Canada',
          'cycle': 'essai canadien, cinq cycles',
        },
      });

      expect(m.id, 12);
      expect(m.engineL, 3.5);
      expect(m.consumption.combinedL100km, 9.4);
      expect(m.consumption.source, 'Ressources naturelles Canada');
    });

    test('un véhicule sans cote se lit sans erreur', () {
      final v = OwnedVehicle.fromJson({
        'id': 3,
        'designation': 'Toyota Fortuner 2022',
        'brand_id': 1,
        'vehicle_model_id': 9,
        'year': 2022,
        'identity': {'brand': 'Toyota', 'model': 'Fortuner'},
        'compatibility_ready': true,
        'motorisation_id': null,
        'consumption': null,
      });

      expect(v.consumption, isNull);
      expect(v.motorisationId, isNull);
    });
  });
}
