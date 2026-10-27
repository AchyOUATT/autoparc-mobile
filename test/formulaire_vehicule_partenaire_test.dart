import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/core/local/catalog_local_cache.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as espace;
import 'package:auto/features/partners/data/models/partner.dart';
import 'package:auto/features/partners/data/partner_repository.dart'
    as annuaire;
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/data/vehicle_admin_repository.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_form_mode.dart';
import 'package:auto/features/vehicles/presentation/pages/vehicle_register_page.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/shared/models/paginated_response.dart';

/// Le formulaire unifié, vu du côté PARTENAIRE.
///
/// ── POURQUOI CE BANC EXISTE ────────────────────────────────────────────────
///
/// L'espace partenaire avait son propre formulaire de véhicule : 441 lignes
/// contre 1521, et neuf champs que le personnel renseignait sans que le
/// partenaire puisse même les voir. Il a été remplacé par le formulaire du
/// personnel en mode partenaire, et ce mode retire TROIS champs que le serveur
/// refuse à un partenaire (`missing` dans `Partner\AuthorizesPartnerCatalog`) :
/// `deal_type`, `location_id`, `partner_id`.
///
/// Ce retrait n'avait AUCUN banc. Le mode partenaire n'était éprouvé nulle
/// part, alors que les douze bancs de l'ancien formulaire continuaient de
/// passer sur du code que plus personne ne traversait — une suite verte sur
/// une branche morte. Les voici portés sur le chemin réel.
///
/// Ce qui est tenu ici, et pourquoi chaque point compte :
///   — les trois champs refusés ne partent pas, sinon le serveur répond 422 ;
///   — ils ne s'AFFICHENT pas non plus, sinon le partenaire remplit un champ
///     qui sera ignoré ou refusé ;
///   — le contraste en mode personnel, sans lequel le premier point passerait
///     aussi bien si les champs avaient disparu pour tout le monde ;
///   — le kilométrage part dans le bloc qui correspond au statut ;
///   — et la bascule « immatriculé → importé » annonce ce qu'elle supprime.

Map<String, dynamic> _fixture() =>
    jsonDecode(File('test/fixtures/vehicle_detail.json').readAsStringSync())
        as Map<String, dynamic>;

/// Le véhicule de départ, dont on règle les deux faits qui comptent ici.
///
/// `condition` passe à « occasion » parce que le champ kilométrage n'existe
/// que là : sur un véhicule neuf, le formulaire le masque et le vide.
Vehicle _vehicule({bool immatricule = true, String condition = 'used'}) {
  final json = jsonDecode(jsonEncode(_fixture()['data'])) as Map<String, dynamic>;
  json['registration_status'] = <String, dynamic>{
    'value': immatricule ? 'registered' : 'unregistered',
    'label': immatricule ? 'Deja immatricule' : 'Non immatricule',
  };
  (json['commercial'] as Map<String, dynamic>)['condition'] = condition;
  json.addAll(<String, dynamic>{
    'brand_id': _marque.id,
    'vehicle_model_id': _modele.id,
    'engine_type_id': _motorisation.id,
  });
  (json['identity'] as Map<String, dynamic>)['year'] = 2016;
  return Vehicle.fromJson(json);
}

const _agence = LocationRef(id: 7, name: 'Showroom Nord', city: 'Ouagadougou');
const _marque = BrandRef(id: 3, name: 'Toyota', isActive: true);
const _modele = ModelRef(id: 11, brandId: 3, name: 'Corolla', generation: 'E180');
const _motorisation = EngineTypeRef(
  id: 5, code: 'petrol', label: 'Essence', usesFuel: true, usesBattery: false,
);

/// Marque, modèle et motorisation sont EXIGÉS par les étapes 2 et 3 : sans
/// eux, le `Stepper` s'arrête avant la soumission et la charge reste nulle.
const _refs = CatalogRefs(
  brands: [_marque],
  vehicleModels: [_modele],
  trims: [],
  engineTypes: [_motorisation],
  drivetrains: [],
  colors: [],
  features: [],
  // Une agence au moins : sans elle, le menu « Agence / Showroom » ne serait
  // pas rendu même en mode personnel, et le contraste ne prouverait rien.
  locations: [_agence],
);

class _DepotPartenaire extends espace.PartnerRepository {

  Map<String, dynamic>? charge;
  int? identifiant;

  @override
  Future<Map<String, dynamic>> saveListing(
    espace.PartnerListingKind kind,
    Map<String, dynamic> data, {
    int? id,
  }) async {
    charge = Map<String, dynamic>.from(data);
    identifiant = id;
    return {'id': id ?? 99};
  }
}

class _DepotPersonnel extends VehicleAdminRepository {
  _DepotPersonnel() : super(ApiClient(), CatalogLocalCache());

  Map<String, dynamic>? charge;

  @override
  Future<Vehicle> updateVehicle(int id, Map<String, dynamic> data) async {
    charge = Map<String, dynamic>.from(data);
    // On capture la charge réelle sans laisser la page naviguer : l'écran
    // reste monté, donc ce qu'il affiche reste observable.
    throw const ApiException(message: 'Charge capturée', statusCode: 422);
  }
}

class _Annuaire extends annuaire.PartnerRepository {
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

Future<void> _ouvrir(
  WidgetTester tester, {
  required VehicleFormMode mode,
  required _DepotPartenaire partenaire,
  required _DepotPersonnel personnel,
  Vehicle? existant,
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      catalogRefsProvider.overrideWith((_) async => _refs),
      countriesProvider.overrideWith((_) async => <CountryRef>[]),
      espace.partnerRepositoryProvider.overrideWithValue(partenaire),
      vehicleAdminRepositoryProvider.overrideWithValue(personnel),
      annuaire.partnerRepositoryProvider.overrideWithValue(_Annuaire()),
    ],
    child: MaterialApp(
      home: VehicleRegisterPage(mode: mode, existing: existant),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Le formulaire est un `Stepper` : on avance jusqu'au bout, et la dernière
/// continuation enregistre.
Future<void> _enregistrer(WidgetTester tester) async {
  for (var etape = 0; etape < 4; etape++) {
    tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
    await tester.pumpAndSettle();
  }
}

/// Le commutateur « Véhicule immatriculé », pour le basculer comme un vendeur.
void _basculerImmatriculation(WidgetTester tester, bool valeur) {
  tester
      .widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Véhicule immatriculé'),
      )
      .onChanged!(valeur);
}

void _saisirKilometrage(WidgetTester tester, String valeur) {
  final champ = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == 'Kilométrage',
    skipOffstage: false,
  );
  tester.widget<TextField>(champ).controller!.text = valeur;
}

void main() {
  late _DepotPartenaire partenaire;
  late _DepotPersonnel personnel;

  setUp(() {
    partenaire = _DepotPartenaire();
    personnel = _DepotPersonnel();
  });

  // ── LES TROIS CHAMPS QUE LE SERVEUR REFUSE A UN PARTENAIRE ───────────────

  testWidgets('la charge partenaire ne porte ni promotion, ni agence, ni fournisseur',
      (tester) async {
    await _ouvrir(tester,
        mode: VehicleFormMode.partenaire,
        partenaire: partenaire,
        personnel: personnel,
        existant: _vehicule());
    await _enregistrer(tester);

    expect(partenaire.charge, isNotNull,
        reason: 'Rien n’a été enregistré : le reste du banc ne mesurerait rien.');
    for (final champ in ['deal_type', 'location_id', 'partner_id']) {
      expect(partenaire.charge!.containsKey(champ), isFalse,
          reason: 'Le serveur REFUSE « $champ » à un partenaire : l’envoyer '
              'vaut 422, et l’annonce ne part pas du tout.');
    }
  });

  /// LE CONTRASTE, sans lequel le banc précédent passerait aussi bien si le
  /// champ avait disparu pour tout le monde.
  testWidgets('en mode personnel la promotion part bien', (tester) async {
    await _ouvrir(tester,
        mode: VehicleFormMode.personnel,
        partenaire: partenaire,
        personnel: personnel,
        existant: _vehicule());
    await _enregistrer(tester);

    expect(personnel.charge, isNotNull);
    expect(personnel.charge!.containsKey('deal_type'), isTrue,
        reason: 'La vitrine est à la boutique : le personnel doit pouvoir y '
            'placer un véhicule, et l’en retirer.');
  });

  testWidgets('l’écran partenaire ne montre pas les champs de la boutique',
      (tester) async {
    await _ouvrir(tester,
        mode: VehicleFormMode.partenaire,
        partenaire: partenaire,
        personnel: personnel,
        existant: _vehicule());

    for (final libelle in [
      'Mise en avant',
      'Agence / Showroom',
      'Fournisseur / Partenaire source',
    ]) {
      expect(find.text(libelle, skipOffstage: false), findsNothing,
          reason: 'Montrer « $libelle » à un partenaire lui fait remplir un '
              'champ que le serveur refusera.');
    }
  });

  testWidgets('l’écran du personnel les montre', (tester) async {
    await _ouvrir(tester,
        mode: VehicleFormMode.personnel,
        partenaire: partenaire,
        personnel: personnel,
        existant: _vehicule());

    for (final libelle in [
      'Mise en avant',
      'Agence / Showroom',
      'Fournisseur / Partenaire source',
    ]) {
      expect(find.text(libelle, skipOffstage: false), findsWidgets,
          reason: 'Si « $libelle » manquait aussi au personnel, le banc '
              'd’en face ne prouverait rien.');
    }
  });

  // ── LE KILOMETRAGE VA DANS LE BLOC QUI CORRESPOND AU STATUT ──────────────
  //
  // Le serveur écrit l'un ou l'autre selon `registration_status`
  // (`syncTypeSpecificDetails`) : un bloc envoyé sur le mauvais statut est
  // ignoré en silence, et le filtre public `?mileage_max=` ne trouve rien.

  testWidgets('le compteur d’un importé part dans import', (tester) async {
    await _ouvrir(tester,
        mode: VehicleFormMode.partenaire,
        partenaire: partenaire,
        personnel: personnel,
        existant: _vehicule(immatricule: false));
    _saisirKilometrage(tester, '85000');
    await _enregistrer(tester);

    expect(partenaire.charge!['import'], {'odometer_at_import_km': 85000});
    expect(partenaire.charge!.containsKey('registration'), isFalse);
  });

  testWidgets('le kilométrage d’un immatriculé part dans registration',
      (tester) async {
    await _ouvrir(tester,
        mode: VehicleFormMode.partenaire,
        partenaire: partenaire,
        personnel: personnel,
        existant: _vehicule());
    _saisirKilometrage(tester, '85000');
    await _enregistrer(tester);

    expect(partenaire.charge!['registration'], {'mileage_km': 85000});
    expect(partenaire.charge!.containsKey('import'), isFalse);
  });

  testWidgets('un kilométrage vide n’envoie aucun bloc', (tester) async {
    await _ouvrir(tester,
        mode: VehicleFormMode.partenaire,
        partenaire: partenaire,
        personnel: personnel,
        existant: _vehicule());
    await _enregistrer(tester);

    expect(partenaire.charge!.containsKey('registration'), isFalse,
        reason: 'Un champ vide veut dire « je ne touche pas », et non '
            '« efface ce qui est enregistré ».');
    expect(partenaire.charge!.containsKey('import'), isFalse);
  });

  // ── CE QUE LA BASCULE SUPPRIME, DIT AVANT L'ENREGISTREMENT ───────────────
  //
  // `syncTypeSpecificDetails` supprime le carnet d'immatriculation dès qu'il
  // écrit un bloc IMPORT sur un véhicule déclaré non immatriculé. Et ce bloc
  // part dès que le formulaire a quelque chose à y mettre : un compteur OU un
  // pays d'origine. Décocher puis choisir un pays suffisait donc à effacer
  // l'immatriculation, sans qu'aucun écran ne l'annonce.

  const annonce = 'ses informations d’immatriculation seront supprimées';

  testWidgets('déclarer importé un véhicule immatriculé annonce la suppression',
      (tester) async {
    await _ouvrir(tester,
        mode: VehicleFormMode.partenaire,
        partenaire: partenaire,
        personnel: personnel,
        existant: _vehicule());

    expect(find.textContaining(annonce, skipOffstage: false), findsNothing,
        reason: 'Rien n’a encore basculé : l’avertissement serait du bruit.');

    _basculerImmatriculation(tester, false);
    await tester.pumpAndSettle();

    expect(find.textContaining(annonce, skipOffstage: false), findsOneWidget,
        reason: 'Le serveur SUPPRIME le carnet d’immatriculation : le vendeur '
            'doit l’apprendre avant d’enregistrer, et non après.');
  });

  testWidgets('revenir à immatriculé retire l’avertissement', (tester) async {
    await _ouvrir(tester,
        mode: VehicleFormMode.partenaire,
        partenaire: partenaire,
        personnel: personnel,
        existant: _vehicule());

    _basculerImmatriculation(tester, false);
    await tester.pumpAndSettle();
    _basculerImmatriculation(tester, true);
    await tester.pumpAndSettle();

    expect(find.textContaining(annonce, skipOffstage: false), findsNothing);
  });

  /// Rien à supprimer sur un véhicule qui n'était pas immatriculé, ni sur une
  /// création : l'avertissement y serait faux.
  testWidgets('un importé qui le reste ne déclenche aucun avertissement',
      (tester) async {
    await _ouvrir(tester,
        mode: VehicleFormMode.partenaire,
        partenaire: partenaire,
        personnel: personnel,
        existant: _vehicule(immatricule: false));

    expect(find.textContaining(annonce, skipOffstage: false), findsNothing);
  });

  testWidgets('une création n’annonce aucune suppression', (tester) async {
    await _ouvrir(tester,
        mode: VehicleFormMode.partenaire,
        partenaire: partenaire,
        personnel: personnel);

    expect(find.textContaining(annonce, skipOffstage: false), findsNothing);
  });
}
