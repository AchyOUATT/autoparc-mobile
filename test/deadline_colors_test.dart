import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Une échéance dépassée se lit en rouge, partout.
///
/// Elle s'affichait en gris dès qu'elle n'était pas la plus urgente des trois
/// — même encre qu'une vidange prévue dans 7 000 km. Une visite technique
/// expirée depuis douze jours se lisait alors comme une formalité à venir,
/// alors que c'est précisément l'information qui doit sauter aux yeux : c'est
/// pour elle qu'on ouvre l'application.
void main() {
  VehicleDeadline echeance({required bool depassee, int jours = -12}) =>
      VehicleDeadline(
        kind: 'technical_inspection',
        label: 'Visite technique',
        daysLeft: depassee ? jours : 35,
        overdue: depassee,
      );

  group('Résumé d\'une échéance', () {
    test('une échéance dépassée le dit en clair', () {
      expect(echeance(depassee: true).summary, 'Dépassée de 12 j');
    });

    test('une échéance à venir compte les jours', () {
      expect(echeance(depassee: false).summary, 'Dans 35 j');
    });

    test('le jour même ne se compte pas en jours restants', () {
      final aujourdhui = VehicleDeadline(
        kind: 'insurance',
        label: 'Assurance',
        daysLeft: 0,
        overdue: false,
      );

      expect(aujourdhui.summary, "Expire aujourd'hui");
    });
  });

  group('Couleur portée par l\'état', () {
    // La règle tient en une phrase : dépassée → rouge. Ce test la fixe sur le
    // modèle, que les deux écrans — accueil et garage — consultent pour
    // choisir leur encre.
    testWidgets('le rouge du thème est réservé à ce qui est dépassé',
        (tester) async {
      late ColorScheme cs;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              cs = Theme.of(context).colorScheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      Color encre(VehicleDeadline d) => d.overdue ? cs.error : cs.onSurfaceVariant;

      expect(encre(echeance(depassee: true)), cs.error);
      expect(encre(echeance(depassee: false)), isNot(cs.error));
    });
  });
}
