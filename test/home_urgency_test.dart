import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/home/presentation/providers/home_providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quel véhicule l'accueil met en avant, et lesquels portent une pastille.
///
/// C'est le seul jugement que la page porte toute seule. Une première version
/// renvoyait la même valeur d'urgence pour tout ce qui était dépassé : deux
/// voitures en retard devenaient indiscernables, et l'application affichait
/// l'assurance dépassée de 2 jours plutôt que la visite technique dépassée de
/// 11. Le défaut ne s'est vu qu'à l'écran, avec trois véhicules réels.
OwnedVehicle _vehicule({
  required int id,
  required String nom,
  List<Map<String, dynamic>> echeances = const [],
}) =>
    OwnedVehicle.fromJson({
      'id': id,
      'designation': nom,
      'nickname': nom,
      'brand_id': 1,
      'vehicle_model_id': 1,
      'year': 2018,
      'identity': {'brand': 'Toyota', 'model': 'Corolla'},
      'deadlines': echeances,
    });

Map<String, dynamic> _echeance({
  required String label,
  int? joursRestants,
  bool depassee = false,
  String? detail,
}) => {
      'kind': 'insurance',
      'label': label,
      'due_on': null,
      'days_left': joursRestants,
      'overdue': depassee,
      'detail': detail,
    };

void main() {
  group('Ordre d\'urgence', () {
    test('la plus dépassée passe devant', () {
      final corolla = _vehicule(id: 1, nom: 'Ma Corolla', echeances: [
        _echeance(label: 'Visite technique', joursRestants: -11, depassee: true),
      ]);
      final seconde = _vehicule(id: 2, nom: 'Ma seconde voiture', echeances: [
        _echeance(label: 'Assurance', joursRestants: -2, depassee: true),
      ]);

      expect(urgencyOf(corolla), lessThan(urgencyOf(seconde)),
          reason: 'Onze jours de retard pressent plus que deux.');
    });

    test('ce qui est dépassé passe devant ce qui approche', () {
      final depasse = _vehicule(id: 1, nom: 'En retard', echeances: [
        _echeance(label: 'Assurance', joursRestants: -2, depassee: true),
      ]);
      final bientot = _vehicule(id: 2, nom: 'Bientôt', echeances: [
        _echeance(label: 'Visite technique', joursRestants: 4),
      ]);

      expect(urgencyOf(depasse), lessThan(urgencyOf(bientot)));
    });

    test('un véhicule sans échéance ferme la marche', () {
      final suivi = _vehicule(id: 1, nom: 'Suivi', echeances: [
        _echeance(label: 'Assurance', joursRestants: 357),
      ]);
      final sansRien = _vehicule(id: 2, nom: 'Sans échéance');

      expect(urgencyOf(suivi), lessThan(urgencyOf(sansRien)));
    });

    /// La vidange se compte en kilomètres : pas de `days_left` à comparer.
    test('une vidange dépassée passe devant ce qui est encore à venir', () {
      final vidange = _vehicule(id: 1, nom: 'Vidange due', echeances: [
        _echeance(label: 'Vidange', depassee: true, detail: 'Dépassée de 300 km'),
      ]);
      final aVenir = _vehicule(id: 2, nom: 'À venir', echeances: [
        _echeance(label: 'Assurance', joursRestants: 20),
      ]);
      final sansRien = _vehicule(id: 3, nom: 'Sans échéance');

      expect(urgencyOf(vidange), lessThan(urgencyOf(aVenir)));
      expect(urgencyOf(vidange), lessThan(urgencyOf(sansRien)));
    });

    test('trois véhicules se rangent dans le bon ordre', () {
      final vehicules = [
        _vehicule(id: 3, nom: 'Mazda3', echeances: [
          _echeance(label: 'Visite technique', joursRestants: 4),
        ]),
        _vehicule(id: 2, nom: 'Ma seconde voiture', echeances: [
          _echeance(label: 'Assurance', joursRestants: -2, depassee: true),
        ]),
        _vehicule(id: 1, nom: 'Ma Corolla', echeances: [
          _echeance(label: 'Visite technique', joursRestants: -11, depassee: true),
        ]),
      ]..sort((a, b) => urgencyOf(a).compareTo(urgencyOf(b)));

      expect(
        vehicules.map((v) => v.nickname),
        ['Ma Corolla', 'Ma seconde voiture', 'Mazda3'],
      );
    });
  });

  group('Pastille d\'alerte', () {
    /// Le seuil suit la fenêtre du rappel automatique (30 jours) : la pastille
    /// apparaît quand un rappel partirait.
    test('une échéance proche ou dépassée mérite la pastille', () {
      expect(
        needsAttention(_vehicule(id: 1, nom: 'x', echeances: [
          _echeance(label: 'Assurance', joursRestants: -2, depassee: true),
        ])),
        isTrue,
      );
      expect(
        needsAttention(_vehicule(id: 2, nom: 'y', echeances: [
          _echeance(label: 'Visite technique', joursRestants: 4),
        ])),
        isTrue,
      );
    });

    test('une échéance lointaine ne la mérite pas', () {
      expect(
        needsAttention(_vehicule(id: 3, nom: 'z', echeances: [
          _echeance(label: 'Assurance', joursRestants: 357),
        ])),
        isFalse,
      );
    });

    test('aucun suivi, aucune pastille', () {
      expect(needsAttention(_vehicule(id: 4, nom: 'w')), isFalse);
    });
  });
}
