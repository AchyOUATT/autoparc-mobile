import 'package:auto/features/partner_accounts/data/partner_repository.dart';
import 'package:auto/features/partner_accounts/presentation/partner_listing_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository extends PartnerRepository {
  Map<String, dynamic>? saved;
  PartnerListingKind? savedKind;
  int? editedId;

  @override
  Future<PartnerReferences> references() async => const PartnerReferences(
    brands: [{'id': 1, 'name': 'Toyota'}],
    models: [
      {'id': 10, 'brand_id': 1, 'name': 'Corolla', 'generation': 'E180'},
      {'id': 11, 'brand_id': 1, 'name': 'Corolla', 'generation': 'E210'},
    ],
    engineTypes: [{'id': 20, 'label': 'Essence'}],
    partCategories: [{'id': 30, 'name': 'Filtration', 'children': [
      {'id': 31, 'name': 'Filtres à huile'},
    ]}],
    manufacturers: [],
  );

  @override
  Future<PartnerListingPage> listListings(PartnerListingKind kind, {
    int page = 1, String? query,
  }) async => const PartnerListingPage(
    items: [{'id': 41, 'designation': 'Corolla donneuse', 'reference': 'VEH-41'}],
    page: 1, lastPage: 1, total: 1,
  );

  @override
  Future<Map<String, dynamic>> saveListing(PartnerListingKind kind,
      Map<String, dynamic> data, {int? id}) async {
    saved = data;
    savedKind = kind;
    editedId = id;
    return {'id': id ?? 99, ...data};
  }
}

Future<void> _open(WidgetTester tester, _Repository repository,
    PartnerListingKind kind, {Map<String, dynamic>? listing}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [partnerRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(home: Builder(builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => PartnerListingFormPage(kind: kind, initialListing: listing),
        )),
        child: const Text('Ouvrir formulaire'),
      ),
    ))),
  ));
  await tester.tap(find.text('Ouvrir formulaire'));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, Finder dropdown, String text) async {
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

/// Choisit dans la liste portant ce LIBELLE.
///
/// Les bancs visaient `DropdownButtonFormField<String>` par son index. Ajouter
/// un champ en amont les faisait viser autre chose, en silence — c'est
/// exactement ce qui est arrivé en posant les questions de classification.
Future<void> _chooseLabeled(WidgetTester tester, String label, String text) =>
    _choose(tester, find.widgetWithText(DropdownButtonFormField<String>, label), text);

/// Les trois réponses que le formulaire exige désormais d'un véhicule.
///
/// Sans elles, aucune annonce ne part — et c'est le but : `vehicle_type` et
/// `registration_status` ont une valeur par défaut en base, de sorte qu'une
/// annonce muette était classée en silence, et possiblement à tort.
Future<void> _classer(WidgetTester tester, {
  String type = 'Voiture particulière',
  String situation = 'Non immatriculé (import)',
  String etat = 'Occasion',
}) async {
  await _chooseLabeled(tester, 'Type de véhicule', type);
  await _chooseLabeled(tester, 'Situation administrative', situation);
  await _chooseLabeled(tester, 'État', etat);
}

Future<void> _submit(WidgetTester tester, {bool editing = false}) async {
  final button = find.widgetWithText(FilledButton,
      editing ? 'Enregistrer les modifications' : 'Enregistrer le brouillon');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('une location mensuelle se crée sans tarif journalier', (tester) async {
    final repository = _Repository();
    await _open(tester, repository, PartnerListingKind.vehicles);
    await _choose(tester, find.byType(DropdownButtonFormField<int>).at(0), 'Toyota');
    await _choose(tester, find.byType(DropdownButtonFormField<int>).at(1), 'Corolla E180');
    await _choose(tester, find.byType(DropdownButtonFormField<int>).at(2), 'Essence');
    await _enter(tester, 'Année de fabrication', '2018');
    await _classer(tester);
    await _chooseLabeled(tester, 'Proposition', 'Location');
    await _enter(tester, 'Location par mois (FCFA)', '350000');
    await _submit(tester);

    expect(repository.savedKind, PartnerListingKind.vehicles);
    expect(repository.saved, containsPair('brand_id', 1));
    expect(repository.saved, containsPair('vehicle_model_id', 10));
    expect(repository.saved, containsPair('engine_type_id', 20));
    expect(repository.saved, containsPair('availability', 'rent'));
    expect(repository.saved, containsPair('rental_monthly_rate', 350000));
    expect(repository.saved, containsPair('rental_daily_rate', null));
    expect(find.text('Ouvrir formulaire'), findsOneWidget);
  });

  testWidgets('les identifiants et les deux prix sont préservés en édition mixte', (tester) async {
    final repository = _Repository();
    await _open(tester, repository, PartnerListingKind.vehicles, listing: {
      'id': 7, 'brand_id': 1, 'vehicle_model_id': 10, 'engine_type_id': 20,
      'identity': {'year': 2018},
      'vehicle_type': 'passenger',
      'registration_status': {'value': 'unregistered', 'label': 'Non immatriculé'},
      'commercial': {'condition': 'used', 'availability': 'both', 'sale_price': '4800000.00',
        'rental_daily_rate': null, 'rental_monthly_rate': '300000.00'},
    });
    await _enter(tester, 'Location par mois (FCFA)', '320000');
    await _submit(tester, editing: true);

    expect(repository.editedId, 7);
    expect(repository.saved, containsPair('vehicle_model_id', 10));
    expect(repository.saved, containsPair('sale_price', 4800000));
    expect(repository.saved, containsPair('rental_monthly_rate', 320000));
    expect(repository.saved, containsPair('availability', 'both'));
  });

  testWidgets('une location sans aucun tarif reste dans le formulaire', (tester) async {
    final repository = _Repository();
    await _open(tester, repository, PartnerListingKind.vehicles, listing: {
      'id': 7, 'brand_id': 1, 'vehicle_model_id': 10, 'engine_type_id': 20,
      'identity': {'year': 2018},
      'vehicle_type': 'passenger',
      'registration_status': {'value': 'unregistered', 'label': 'Non immatriculé'},
      'commercial': {'condition': 'used', 'availability': 'rent'},
    });
    await _submit(tester, editing: true);

    expect(repository.saved, isNull);
    expect(find.text('Indiquez au moins un tarif de location : par jour ou par mois.'), findsOneWidget);
  });

  testWidgets('changer de génération retire les anciens liens de l’annonce partenaire', (tester) async {
    final repository = _Repository();
    await _open(tester, repository, PartnerListingKind.vehicles, listing: {
      'id': 7, 'brand_id': 1, 'vehicle_model_id': 10, 'engine_type_id': 20,
      'trim_id': 55, 'drivetrain_id': 66,
      'identity': {'year': 2020},
      'vehicle_type': 'passenger',
      'registration_status': {'value': 'unregistered', 'label': 'Non immatriculé'},
      'commercial': {'condition': 'used', 'availability': 'rent', 'rental_monthly_rate': '300000.00'},
      'technical': {'engine_code': 'OLD-ENGINE'},
      'consumption': {'combined_l_100km': '8.5'},
    });

    await _choose(tester, find.byType(DropdownButtonFormField<int>).at(1), 'Corolla E210');
    await _choose(tester, find.byType(DropdownButtonFormField<int>).at(2), 'Essence');
    await _submit(tester, editing: true);

    expect(repository.saved, containsPair('vehicle_model_id', 11));
    expect(repository.saved, containsPair('trim_id', null));
    expect(repository.saved, containsPair('drivetrain_id', null));
    expect(repository.saved, containsPair('engine_code', null));
    expect(repository.saved, containsPair('consumption_combined', null));
    expect(repository.saved, containsPair('rental_monthly_rate', 300000));
  });

  // ── CE QUI REND L'ANNONCE TROUVABLE ────────────────────────────────────
  //
  // Le catalogue public filtre sur `vehicle_type`, `registration_status`,
  // `body_style`, `condition` et `mileage_max`. Le formulaire ne posait aucune
  // de ces questions : l'annonce partenaire était absente de ces filtres, et
  // pire pour les deux premiers — dont la colonne porte un défaut en base —
  // elle y figurait sous une classification FAUSSE.
  //
  // Le pendant côté serveur est `PartnerAnnonceTrouvableTest` dans
  // autoparc-backend : il prouve que ces réponses arrivent jusqu'aux filtres.
  // Ici on prouve que le formulaire les ENVOIE.

  Future<void> creerVehicule(WidgetTester tester, _Repository repository) async {
    await _open(tester, repository, PartnerListingKind.vehicles);
    await _choose(tester, find.byType(DropdownButtonFormField<int>).at(0), 'Toyota');
    await _choose(tester, find.byType(DropdownButtonFormField<int>).at(1), 'Corolla E180');
    await _choose(tester, find.byType(DropdownButtonFormField<int>).at(2), 'Essence');
    await _enter(tester, 'Année de fabrication', '2018');
  }

  testWidgets('la classification part avec l’annonce', (tester) async {
    final repository = _Repository();
    await creerVehicule(tester, repository);
    await _classer(tester, type: 'Utilitaire', situation: 'Déjà immatriculé', etat: 'Occasion');
    await _chooseLabeled(tester, 'Carrosserie', 'Fourgon');
    await _enter(tester, 'Kilométrage (km)', '120000');
    await _enter(tester, 'Prix de vente (FCFA)', '9500000');
    await _submit(tester);

    expect(repository.saved, containsPair('vehicle_type', 'utility'));
    expect(repository.saved, containsPair('registration_status', 'registered'));
    expect(repository.saved, containsPair('condition', 'used'));
    expect(repository.saved, containsPair('body_style', 'van'));

    // Le kilométrage va dans le bloc qui correspond au statut : le serveur
    // écrit l'un ou l'autre selon `registration_status`, et l'autre serait
    // ignoré en silence.
    expect(repository.saved!['registration'], containsPair('mileage_km', 120000));
    expect(repository.saved!.containsKey('import'), isFalse);
  });

  testWidgets('le kilométrage d’un import va dans le bloc import', (tester) async {
    final repository = _Repository();
    await creerVehicule(tester, repository);
    await _classer(tester, situation: 'Non immatriculé (import)');
    await _enter(tester, 'Kilométrage (km)', '80000');
    await _enter(tester, 'Prix de vente (FCFA)', '4500000');
    await _submit(tester);

    expect(repository.saved!['import'], containsPair('odometer_at_import_km', 80000));
    expect(repository.saved!.containsKey('registration'), isFalse);
  });

  /// Un kilométrage laissé vide veut dire « je ne touche pas », et non
  /// « efface ce qui est enregistré ». Aucun bloc ne part.
  testWidgets('un kilométrage vide n’envoie aucun bloc', (tester) async {
    final repository = _Repository();
    await creerVehicule(tester, repository);
    await _classer(tester);
    await _enter(tester, 'Prix de vente (FCFA)', '4500000');
    await _submit(tester);

    expect(repository.saved, isNotNull);
    expect(repository.saved!.containsKey('registration'), isFalse);
    expect(repository.saved!.containsKey('import'), isFalse);
  });

  /// LE BANC QUI EMPECHE LE RETOUR DU DEFAUT.
  ///
  /// Si ces trois questions redevenaient facultatives — ou pire,
  /// préselectionnées — l'annonce repartirait classée en silence. Rien ne doit
  /// pouvoir sortir du formulaire sans réponse.
  testWidgets('sans classification, rien ne part', (tester) async {
    final repository = _Repository();
    await creerVehicule(tester, repository);
    await _enter(tester, 'Prix de vente (FCFA)', '4500000');
    await _submit(tester);

    expect(repository.saved, isNull,
        reason: 'Une annonce est partie sans type, sans situation ni état.');
    expect(find.text('Choisissez une valeur.'), findsWidgets);
  });

  /// CHACUNE des trois, et pas seulement les trois ensemble.
  ///
  /// Le banc du dessus laisse les trois sans réponse, si bien que n'importe
  /// laquelle suffit à retenir l'annonce : rendre `vehicle_type` facultatif,
  /// ou le préselectionner, le passait au vert. Deux mutations ont survécu
  /// exactement comme ça. Ici chaque champ est omis À SON TOUR, les deux
  /// autres étant renseignés.
  for (final omis in const ['Type de véhicule', 'Situation administrative', 'État']) {
    testWidgets('sans « $omis », rien ne part', (tester) async {
      final repository = _Repository();
      await creerVehicule(tester, repository);

      for (final champ in const {
        'Type de véhicule': 'Voiture particulière',
        'Situation administrative': 'Non immatriculé (import)',
        'État': 'Occasion',
      }.entries) {
        if (champ.key != omis) {
          await _chooseLabeled(tester, champ.key, champ.value);
        }
      }

      await _enter(tester, 'Prix de vente (FCFA)', '4500000');
      await _submit(tester);

      expect(repository.saved, isNull,
          reason: 'Une annonce est partie sans « $omis » : elle sera donc '
              'classée par défaut, et possiblement à tort.');
    });
  }

  /// La carrosserie, elle, reste FACULTATIVE : la colonne est nullable, et un
  /// vendeur peut légitimement ne pas savoir qualifier un châssis.
  testWidgets('la carrosserie peut rester non renseignée', (tester) async {
    final repository = _Repository();
    await creerVehicule(tester, repository);
    await _classer(tester);
    await _enter(tester, 'Prix de vente (FCFA)', '4500000');
    await _submit(tester);

    expect(repository.saved, isNotNull);
    expect(repository.saved, containsPair('body_style', null));
  });

  testWidgets('l’édition reprend la classification enregistrée', (tester) async {
    final repository = _Repository();
    await _open(tester, repository, PartnerListingKind.vehicles, listing: {
      'id': 7, 'brand_id': 1, 'vehicle_model_id': 10, 'engine_type_id': 20,
      'identity': {'year': 2018},
      // Les formes que `VehicleResource` rend réellement : chaîne nue pour
      // `vehicle_type` et `body_style`, objet {value,label} pour
      // `registration_status`, `condition` sous `commercial`, kilométrage sous
      // `technical`.
      'vehicle_type': 'heavy',
      'registration_status': {'value': 'registered', 'label': 'Immatriculé'},
      'body_style': 'truck',
      'technical': {'mileage_km': 250000},
      'commercial': {'condition': 'damaged', 'availability': 'sale', 'sale_price': '12000000.00'},
    });
    await _submit(tester, editing: true);

    expect(repository.saved, containsPair('vehicle_type', 'heavy'),
        reason: 'Une modification de prix ne doit pas reclasser le véhicule.');
    expect(repository.saved, containsPair('registration_status', 'registered'));
    expect(repository.saved, containsPair('body_style', 'truck'));
    expect(repository.saved, containsPair('condition', 'damaged'));
    expect(repository.saved!['registration'], containsPair('mileage_km', 250000));
  });

  testWidgets('la pièce d’occasion transmet son propre véhicule donneur', (tester) async {
    final repository = _Repository();
    await _open(tester, repository, PartnerListingKind.parts);
    await _enter(tester, 'Nom de l’article', 'Filtre en bon état');
    await _choose(tester, find.byType(DropdownButtonFormField<int>).first, 'Filtres à huile');
    await _choose(tester, find.byType(DropdownButtonFormField<String>).at(1), 'D’occasion');
    await _choose(tester, find.byType(DropdownButtonFormField<int>).at(1), 'Corolla donneuse');
    await _enter(tester, 'Prix de vente (FCFA)', '2500');
    await _enter(tester, 'Quantité en stock', '3');
    await _submit(tester);

    expect(repository.savedKind, PartnerListingKind.parts);
    expect(repository.saved, containsPair('part_category_id', 31));
    expect(repository.saved, containsPair('condition', 'used'));
    expect(repository.saved, containsPair('donor_vehicle_id', 41));
    expect(repository.saved, containsPair('stock_quantity', 3));
  });

  testWidgets('un accessoire conserve sa catégorie et son stock en édition', (tester) async {
    final repository = _Repository();
    await _open(tester, repository, PartnerListingKind.accessories, listing: {
      'id': 17, 'name': 'Coussin de siège', 'category': {'value': 'confort'},
      'pricing': {'selling_price': '9000.00'}, 'stock': {'quantity': 4},
    });
    await _enter(tester, 'Prix de vente (FCFA)', '9500');
    await _submit(tester, editing: true);

    expect(repository.editedId, 17);
    expect(repository.savedKind, PartnerListingKind.accessories);
    expect(repository.saved, containsPair('category', 'confort'));
    expect(repository.saved, containsPair('stock_quantity', 4));
    expect(repository.saved, containsPair('selling_price', 9500));
  });
}
