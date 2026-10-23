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
    await _choose(tester, find.byType(DropdownButtonFormField<String>).first, 'Location');
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
      'commercial': {'availability': 'both', 'sale_price': '4800000.00',
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
      'identity': {'year': 2018}, 'commercial': {'availability': 'rent'},
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
      'commercial': {'availability': 'rent', 'rental_monthly_rate': '300000.00'},
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
