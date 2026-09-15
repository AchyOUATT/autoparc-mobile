import 'package:auto/features/garage/data/engine_data.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quand avertir que la compatibilité ne pourra pas être calculée.
///
/// Le serveur tranche sur `effective_engine_type_id ?? trim->default_engine_type_id`
/// ou sur le code moteur. L'avertissement affiché dans le formulaire doit dire
/// exactement la même chose : s'il se déclenche alors que le serveur, lui,
/// saura calculer, il devient un faux positif — et un avertissement qu'on voit
/// apparaître à tort cesse d'être lu, y compris quand il a raison.

const _essence = EngineTypeRef(
  id: 1,
  code: 'petrol',
  label: 'Essence',
  usesFuel: true,
  usesBattery: false,
);

/// Finition sans motorisation par défaut : elle n'apprend rien au serveur.
const _finitionMuette = TrimRef(id: 10, vehicleModelId: 5, name: 'Base');

/// Finition qui porte sa motorisation : la choisir suffit.
const _finitionParlante = TrimRef(
  id: 11,
  vehicleModelId: 5,
  name: 'GLI 1.8',
  defaultEngineTypeId: 1,
);

void main() {
  group('Motorisation résolue', () {
    test('rien de renseigné : le serveur ne pourra pas calculer', () {
      expect(motorisationResolue(), isFalse);
    });

    test('le carburant choisi suffit', () {
      expect(motorisationResolue(engineType: _essence), isTrue);
    });

    /// Le défaut que cette fonction existe pour éviter : juger sur le seul
    /// menu déroulant reprocherait une information déjà donnée.
    test('une finition qui porte sa motorisation suffit aussi', () {
      expect(motorisationResolue(trim: _finitionParlante), isTrue,
          reason: 'Le serveur retombe sur trim->default_engine_type_id.');
    });

    test('une finition sans motorisation par défaut ne suffit pas', () {
      expect(motorisationResolue(trim: _finitionMuette), isFalse);
    });

    test('le code moteur venu du VIN suffit', () {
      expect(motorisationResolue(engineCode: '1NZ'), isTrue);
    });

    /// Le décodage VIN peut renvoyer une chaîne vide plutôt que rien : la
    /// traiter comme une réponse ferait taire l'avertissement sans raison.
    test('un code moteur vide ou blanc ne compte pas', () {
      expect(motorisationResolue(engineCode: ''), isFalse);
      expect(motorisationResolue(engineCode: '   '), isFalse);
    });
  });
}
