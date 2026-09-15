import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un « modèle » est une génération, pas un nom commercial.
///
/// Trois Corolla coexistent — E210, E180, E140 — et le menu les affichait par
/// leur seul code constructeur, la plus récente en tête. Une voiture de 2016
/// s'est ainsi retrouvée sur une E210 produite à partir de 2019 : rien ne le
/// signalait, et le véhicule était ensuite apparié à des pièces qui ne vont pas
/// dessus, puisque celles d'une E210 ne montent pas sur une E180.

ModelRef _corolla(String gen, int? debut, int? fin) => ModelRef(
      id: gen.hashCode,
      brandId: 1,
      name: 'Corolla',
      generation: gen,
      productionStart: debut,
      productionEnd: fin,
    );

final _e210 = _corolla('E210', 2019, null);
final _e180 = _corolla('E180', 2013, 2019);
final _e140 = _corolla('E140', 2006, 2013);

/// La seule génération de Mazda3 longtemps presente en base.
const _mazda3bp = ModelRef(
  id: 152,
  brandId: 2,
  name: 'Mazda3',
  generation: 'BP',
  productionStart: 2018,
);

CatalogRefs _refs(List<ModelRef> modeles) => CatalogRefs(
      brands: const [],
      vehicleModels: modeles,
      trims: const [],
      engineTypes: const [],
      drivetrains: const [],
      colors: const [],
      features: const [],
      locations: const [],
    );

void main() {
  group('Libellé', () {
    test('les années accompagnent le code, qui ne dit rien à personne', () {
      expect(_e180.displayName, 'Corolla (E180, 2013–2019)');
    });

    test('une génération encore produite se dit « depuis »', () {
      expect(_e210.displayName, 'Corolla (E210, depuis 2019)');
    });

    test('sans années connues, le libellé reste celui d\'avant', () {
      const sansDates = ModelRef(id: 9, brandId: 1, name: 'Vios');
      expect(sansDates.displayName, 'Vios');

      const genSeule = ModelRef(id: 9, brandId: 1, name: 'Hilux', generation: 'AN120');
      expect(genSeule.displayName, 'Hilux (AN120)');
    });
  });

  group('Couverture d\'une année', () {
    test('le cas de la Corolla : 2016 n\'est pas une E210', () {
      expect(_e210.couvreAnnee(2016), isFalse);
      expect(_e180.couvreAnnee(2016), isTrue);
    });

    test('une génération en cours couvre tout depuis son début', () {
      expect(_e210.couvreAnnee(2019), isTrue);
      expect(_e210.couvreAnnee(2030), isTrue);
      expect(_e210.couvreAnnee(2018), isFalse);
    });

    /// Les millésimes de transition existent des deux côtés : 2013 est à la
    /// fois la dernière E140 et la première E180. Exclure une borne ferait
    /// crier à l'erreur sur une saisie parfaitement correcte.
    test('les bornes sont inclusives des deux côtés', () {
      expect(_e140.couvreAnnee(2013), isTrue);
      expect(_e180.couvreAnnee(2013), isTrue);
      expect(_e180.couvreAnnee(2019), isTrue);
    });

    /// On n'accuse jamais sur la foi d'une donnée absente : 33 modèles sur 161
    /// n'ont aucune année de production renseignée.
    test('sans années connues, aucune année n\'est refusée', () {
      const inconnue = ModelRef(id: 9, brandId: 1, name: 'Vios');
      expect(inconnue.couvreAnnee(1998), isTrue);
      expect(inconnue.couvreAnnee(2030), isTrue);
    });
  });

  group('Génération de remplacement', () {
    test('la bonne génération est proposée pour l\'année saisie', () {
      final refs = _refs([_e210, _e180, _e140]);

      final proposees = refs.generationsPour(_e210, 2016);

      expect(proposees, hasLength(1));
      expect(proposees.single.generation, 'E180');
    });

    test('un millésime de transition en propose deux, sans trancher', () {
      final refs = _refs([_e210, _e180, _e140]);

      final proposees = refs.generationsPour(_e210, 2013);

      expect(proposees.map((m) => m.generation), ['E180', 'E140'],
          reason: 'De la plus récente à la plus ancienne.');
    });

    test('la génération déjà choisie ne se propose pas elle-même', () {
      final refs = _refs([_e210, _e180, _e140]);

      expect(
        refs.generationsPour(_e180, 2016).map((m) => m.id),
        isNot(contains(_e180.id)),
      );
    });

    /// Le cas du Mazda3 de 2014 : le décodage VIN l'a rattaché à la BP faute
    /// d'autre chose. Il n'y a rien à proposer, et il faut le dire plutôt que
    /// laisser croire qu'un bon choix existe quelque part dans la liste.
    test('aucune proposition quand la base ne couvre pas l\'année', () {
      final refs = _refs([_mazda3bp]);

      expect(_mazda3bp.couvreAnnee(2014), isFalse);
      expect(refs.generationsPour(_mazda3bp, 2014), isEmpty);
    });

    test('un autre modèle de la même marque n\'est jamais propose', () {
      final refs = _refs([_e210, _e180, _mazda3bp.copyAvecMarque(1)]);

      expect(
        refs.generationsPour(_e210, 2016).map((m) => m.name),
        everyElement('Corolla'),
      );
    });
  });
}

extension on ModelRef {
  ModelRef copyAvecMarque(int brandId) => ModelRef(
        id: id,
        brandId: brandId,
        name: name,
        generation: generation,
        productionStart: productionStart,
        productionEnd: productionEnd,
      );
}
