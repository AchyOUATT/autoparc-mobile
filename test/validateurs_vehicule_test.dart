import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/partners/data/models/partner.dart';
import 'package:auto/features/partners/data/partner_repository.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/vehicle_admin_repository.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/shared/models/paginated_response.dart';

/// Les règles du formulaire véhicule s'appliquent VRAIMENT.
///
/// ── LE DÉFAUT QUE CE BANC FERME ────────────────────────────────────────────
///
/// La page déclarait `_formKey = GlobalKey<FormState>()`, le posait sur un
/// `Form` autour du `Stepper`… et n'appelait `validate()` nulle part. Pas
/// d'`autovalidateMode` non plus. Les DIX `validator:` du fichier ne
/// s'exécutaient donc jamais.
///
/// Six étaient heureusement redits à la main par une liste de conditions —
/// marque, modèle, année, motorisation, prix de vente, tarifs. Deux ne
/// l'étaient pas, et ne protégeaient donc rien :
///
///   — « Carrosserie * » portait son astérisque sans être exigée. Un véhicule
///     sans carrosserie prend le défaut de la colonne, et le filtre public
///     `?body_style=` ne le trouve jamais — ou le range sous une carrosserie
///     que personne n'a choisie. C'est exactement la classe de défaut que
///     l'unification des formulaires avait corrigée côté partenaire.
///   — « Le VIN doit faire exactement 17 caractères » n'était jamais
///     appliqué : un VIN de cinq caractères partait au serveur.
///
/// ── POURQUOI LA CORRECTION N'EST PAS « APPELER validate() » ────────────────
///
/// Le `Stepper` monte les QUATRE étapes, pas seulement la courante. Un `Form`
/// unique les validerait donc toutes à la fois, et avancer de la première
/// exigerait un prix de vente qui n'a pas encore été demandé. D'où un `Form`
/// par étape.

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/vehicle_detail.json').readAsStringSync())
        as Map<String, dynamic>;

const _marque = BrandRef(id: 3, name: 'Toyota', isActive: true);
const _modele = ModelRef(id: 11, brandId: 3, name: 'Corolla', generation: 'E180');
const _motorisation = EngineTypeRef(
  id: 5, code: 'petrol', label: 'Essence', usesFuel: true, usesBattery: false,
);

const _refs = CatalogRefs(
  brands: [_marque],
  vehicleModels: [_modele],
  trims: [],
  engineTypes: [_motorisation],
  drivetrains: [],
  colors: [],
  features: [],
  locations: [],
);

/// Un véhicule complet, dont on retire ce qu'on veut éprouver.
Vehicle _vehicule({Map<String, dynamic> Function(Map<String, dynamic>)? retouche}) {
  var json = Map<String, dynamic>.from(
    jsonDecode(jsonEncode(_fixture()['data'])) as Map<String, dynamic>,
  );
  json.addAll(<String, dynamic>{
    'brand_id': _marque.id,
    'vehicle_model_id': _modele.id,
    'engine_type_id': _motorisation.id,
  });
  (json['identity'] as Map<String, dynamic>)['year'] = 2016;
  (json['commercial'] as Map<String, dynamic>)['availability'] = 'sale';

  if (retouche != null) json = retouche(json);

  return Vehicle.fromJson(json);
}

class _Depot extends VehicleAdminRepository {
  _Depot() : super(ApiClient(), CatalogLocalCache());

  Map<String, dynamic>? charge;

  @override
  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> data) async {
    charge = Map<String, dynamic>.from(data);
    // On capture la charge sans laisser la page naviguer : l'écran reste
    // monté, donc ce qu'il affiche reste observable.
    throw const ApiException(message: 'Charge capturée', statusCode: 422);
  }
}

class _Annuaire extends PartnerRepository {
  _Annuaire() : super(ApiClient());

  @override
  Future<PaginatedResponse<Partner>> getPartners({
    int page = 1,
    int perPage = 50,
    String? search,
    bool includeInactive = false,
  }) async => const PaginatedResponse(
    data: [], currentPage: 1, lastPage: 1, total: 0, perPage: 50,
  );
}

Future<void> _ouvrir(WidgetTester tester, _Depot depot, Vehicle existant) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      catalogRefsProvider.overrideWith((_) async => _refs),
      countriesProvider.overrideWith((_) async => <CountryRef>[]),
      vehicleAdminRepositoryProvider.overrideWithValue(depot),
      partnerRepositoryProvider.overrideWithValue(_Annuaire()),
    ],
    child: MaterialApp(home: VehicleRegisterPage(existing: existant)),
  ));
  await tester.pumpAndSettle();
}

/// Le `Stepper` ne valide qu'une étape à la fois : on va jusqu'au bout.
Future<void> _enregistrer(WidgetTester tester) async {
  for (var etape = 0; etape < 4; etape++) {
    tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
    await tester.pumpAndSettle();
  }
}

/// Le champ visé, où qu'il soit — les étapes non courantes sont montées mais
/// masquées, et `find` ne les voit pas sans `skipOffstage: false`.
Finder _champ(String libelle) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == libelle,
      skipOffstage: false,
    );

/// Écrit dans un champ en passant par son CONTRÔLEUR.
///
/// `tester.enterText` passe par le clavier, et ne mord pas sur un champ d'une
/// étape masquée — celle du prix de vente l'est tant qu'on n'y est pas. Le
/// contrôleur, lui, est le même objet quelle que soit l'étape affichée, et
/// c'est déjà la technique de `vehicle_classification_test.dart`.
void _ecrire(WidgetTester tester, String libelle, String valeur) {
  tester.widget<TextField>(_champ(libelle)).controller!.text = valeur;
}

void main() {
  // ── LES DEUX RÈGLES QUI NE PROTÉGEAIENT RIEN ────────────────────────────

  /// LE BANC QUI COMPTE LE PLUS.
  ///
  /// Sans carrosserie, le véhicule prend le défaut de la colonne et le filtre
  /// public `?body_style=` ne le trouve jamais. L'astérisque du libellé était
  /// une promesse que rien ne tenait.
  testWidgets('sans carrosserie, rien ne part', (tester) async {
    final depot = _Depot();
    await _ouvrir(tester, depot, _vehicule(retouche: (json) {
      json['body_style'] = null;

      return json;
    }));

    await _enregistrer(tester);

    expect(depot.charge, isNull,
        reason: 'Un vehicule sans carrosserie est introuvable par le filtre '
            'public, ou range sous une carrosserie que personne n a choisie.');
    expect(find.text('Sélectionne un type de carrosserie'), findsOneWidget);
  });

  testWidgets('avec une carrosserie, l’enregistrement passe', (tester) async {
    final depot = _Depot();
    await _ouvrir(tester, depot, _vehicule());

    await _enregistrer(tester);

    expect(depot.charge, isNotNull);
    expect(depot.charge!['body_style'], 'estate');
  });

  /// Un VIN a exactement dix-sept caractères, et cette règle existait depuis
  /// toujours — sans jamais s'appliquer.
  testWidgets('un VIN trop court est refusé', (tester) async {
    final depot = _Depot();
    await _ouvrir(tester, depot, _vehicule());

    _ecrire(tester, 'VIN (optionnel)', 'ABC12');

    await _enregistrer(tester);

    expect(depot.charge, isNull);
    expect(find.text('Le VIN doit faire exactement 17 caractères.'), findsOneWidget);
  });

  testWidgets('un VIN vide reste accepté', (tester) async {
    final depot = _Depot();
    await _ouvrir(tester, depot, _vehicule());

    _ecrire(tester, 'VIN (optionnel)', '');

    await _enregistrer(tester);

    expect(depot.charge, isNotNull,
        reason: 'Le VIN est facultatif : on ne l a pas toujours sous la main.');
  });

  // ── LES RÈGLES QUI ÉTAIENT REDITES À LA MAIN ────────────────────────────
  //
  // Elles tenaient déjà, par une liste de conditions parallèle aux
  // `validator:`. Elles doivent tenir encore, maintenant que cette liste a
  // disparu et que ce sont les champs qui portent la règle.

  testWidgets('une année hors bornes est refusée', (tester) async {
    final depot = _Depot();
    await _ouvrir(tester, depot, _vehicule());

    _ecrire(tester, 'Année de fabrication *', '1920');

    await _enregistrer(tester);

    expect(depot.charge, isNull);
    expect(find.textContaining('Année invalide'), findsOneWidget);
  });

  testWidgets('un prix de vente vide est refusé', (tester) async {
    final depot = _Depot();
    await _ouvrir(tester, depot, _vehicule());

    _ecrire(tester, 'Prix de vente *', '');

    await _enregistrer(tester);

    expect(depot.charge, isNull);
    expect(find.text('Prix de vente obligatoire'), findsOneWidget);
  });

  // ── LE REFUS ARRIVE TOUT DE SUITE, ET NON TROIS ÉTAPES PLUS LOIN ───────

  /// La faute se dit AU MOMENT où l'on quitte l'étape.
  ///
  /// L'enregistrement final rattraperait de toute façon — mais trois étapes
  /// plus tard, après que le vendeur a saisi la motorisation, le prix et les
  /// photos. Lui rendre la main au premier écran fautif est la seule raison
  /// d'éprouver chaque étape à la sortie.
  testWidgets('une étape fautive n’avance pas', (tester) async {
    final depot = _Depot();
    await _ouvrir(tester, depot, _vehicule(retouche: (json) {
      json['body_style'] = null;

      return json;
    }));

    tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
    await tester.pumpAndSettle();

    expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 0,
        reason: 'Laisser avancer ferait decouvrir la faute trois etapes plus '
            'loin, apres tout le reste de la saisie.');
    expect(find.text('Sélectionne un type de carrosserie'), findsOneWidget);
  });

  // ── CE QUI SE PASSE QUAND LA FAUTE EST SUR UNE AUTRE ÉTAPE ──────────────

  /// Une faute sur une étape ANTÉRIEURE ramène à cette étape.
  ///
  /// ── CE QUE CE CAS EST, ET CE QU'IL N'EST PAS ─────────────────────────
  ///
  /// Chaque passage « Suivant » éprouve l'étape qu'on quitte, donc les trois
  /// premières sont valides quand on atteint la dernière. L'enregistrement les
  /// réépreuve quand même, et ce banc atteint ce chemin en modifiant un champ
  /// d'une étape antérieure APRÈS l'avoir quittée — ce qu'aucun geste de
  /// l'écran ne fait aujourd'hui, mais que n'importe quel code futur fera : un
  /// champ calculé, une valeur remise à zéro par un choix plus loin.
  ///
  /// Et sans le RETOUR à l'étape fautive, le refus serait muet : le message
  /// est sous un champ qui n'est pas à l'écran.
  testWidgets('une faute sur une étape antérieure y ramène', (tester) async {
    final depot = _Depot();
    await _ouvrir(tester, depot, _vehicule());

    // On avance jusqu'à la dernière étape avec un véhicule valide.
    for (var etape = 0; etape < 3; etape++) {
      tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
      await tester.pumpAndSettle();
    }
    expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 3);

    // Puis l'étape 1 devient fautive, sans qu'on y retourne.
    _ecrire(tester, 'VIN (optionnel)', 'ABC12');

    tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
    await tester.pumpAndSettle();

    expect(depot.charge, isNull,
        reason: 'Une etape anterieure fautive doit arreter l enregistrement, '
            'meme si ce n est pas celle qu on regarde.');
    expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 0);
    expect(find.textContaining('étape 1'), findsOneWidget);
  });
  /// Et avancer d'une étape n'exige QUE cette étape : les suivantes sont
  /// montées mais vides, et les exiger ici interdirait d'avancer.
  testWidgets('avancer n’exige pas les étapes suivantes', (tester) async {
    final depot = _Depot();
    await _ouvrir(tester, depot, _vehicule());

    _ecrire(tester, 'Prix de vente *', '');

    // Une seule continuation : on passe de l'étape 0 à l'étape 1, bien que le
    // prix de vente — étape 3 — soit vide.
    tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
    await tester.pumpAndSettle();

    expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 1);
  });
}
