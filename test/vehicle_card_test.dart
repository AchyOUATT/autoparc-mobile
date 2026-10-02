import 'dart:convert';
import 'dart:io';

import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/pages/vehicle_list_page.dart';
import 'package:auto/shared/models/paginated_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tenue des fiches dans la grille de recherche.
///
/// La grille impose la hauteur des cartes : `maxCrossAxisExtent: 220` et
/// `childAspectRatio: 0.82`. Sur un écran de 411 dp, cela donne deux colonnes
/// de 188,7 dp de large et 230,1 dp de haut.
///
/// Le bloc de texte occupait deux cinquièmes de cette hauteur, soit 82 dp,
/// pour un contenu qui en demandait 87 : chaque carte visible débordait de
/// 5,2 px et affichait le bandeau rayé. Le texte dicte maintenant sa hauteur,
/// la photo prend ce qui reste.
///
/// Les deux hauteurs sont éprouvées. Celle d'aujourd'hui, parce que c'est elle
/// que l'écran affiche ; et l'ancienne, 205,1 dp, parce qu'un ratio se règle au
/// jugé et qu'il reviendra peut-être en arrière — une carte qui tient dans la
/// case la plus serrée des deux tient dans les deux.
void main() {
  final page = PaginatedResponse.fromJson(
    jsonDecode(File('test/fixtures/vehicles_list.json').readAsStringSync())
        as Map<String, dynamic>,
    Vehicle.fromJson,
  );

  /// Largeur et hauteur d'une case de la grille, telles que le délégué les
  /// calcule sur un téléphone courant.
  const largeur = 188.7;

  /// La hauteur du jour, et la plus serrée jamais utilisée.
  const hauteurs = {'0.82 (actuel)': 230.1, '0.92 (ancien)': 205.1};
  const hauteur = 205.1;

  Widget carte(Vehicle vehicule, {double echelleTexte = 1.0, double? boite}) => ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(echelleTexte)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: largeur,
                  height: boite ?? hauteur,
                  child: VehicleCard(vehicle: vehicule),
                ),
              ),
            ),
          ),
        ),
      );

  group('Fiche de la grille', () {
    testWidgets('aucune fiche du catalogue ne déborde de sa case',
        (tester) async {
      for (final entree in hauteurs.entries) {
        for (final vehicule in page.data) {
          await tester.pumpWidget(carte(vehicule, boite: entree.value));
          await tester.pump();

          expect(tester.takeException(), isNull,
              reason: 'La fiche ${vehicule.reference} déborde de sa case '
                  'au ratio ${entree.key}.');
        }
      }
    });

    testWidgets('elle tient aussi quand le texte du téléphone est agrandi',
        (tester) async {
      // Réglage « grande police » d'Android : les deux lignes secondaires
      // avaient une hauteur figée à 16 px, que le texte agrandi dépassait.
      await tester.pumpWidget(carte(page.data.first, echelleTexte: 1.3));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
