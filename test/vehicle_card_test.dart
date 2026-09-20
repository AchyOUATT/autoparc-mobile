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
/// `childAspectRatio: 0.92`. Sur un écran de 411 dp, cela donne deux colonnes
/// de 188,7 dp de large et 205,1 dp de haut — les valeurs reprises ici.
///
/// Le bloc de texte occupait deux cinquièmes de cette hauteur, soit 82 dp,
/// pour un contenu qui en demandait 87 : chaque carte visible débordait de
/// 5,2 px et affichait le bandeau rayé. Le texte dicte maintenant sa hauteur,
/// la photo prend ce qui reste.
void main() {
  final page = PaginatedResponse.fromJson(
    jsonDecode(File('test/fixtures/vehicles_list.json').readAsStringSync())
        as Map<String, dynamic>,
    Vehicle.fromJson,
  );

  /// Largeur et hauteur d'une case de la grille, telles que le délégué les
  /// calcule sur un téléphone courant.
  const largeur = 188.7;
  const hauteur = 205.1;

  Widget carte(Vehicle vehicule, {double echelleTexte = 1.0}) => ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(echelleTexte)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: largeur,
                  height: hauteur,
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
      for (final vehicule in page.data) {
        await tester.pumpWidget(carte(vehicule));
        await tester.pump();

        expect(tester.takeException(), isNull,
            reason: 'La fiche ${vehicule.reference} déborde de sa case.');
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
