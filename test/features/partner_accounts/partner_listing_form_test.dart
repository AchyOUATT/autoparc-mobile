import 'package:auto/features/partner_accounts/data/partner_repository.dart';
import 'package:auto/features/partner_accounts/presentation/partner_listing_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le formulaire d'annonce de l'espace partenaire — PIECES ET ACCESSOIRES.
///
/// Les vehicules n'y passent plus : ils ouvrent `VehicleRegisterPage` en mode
/// partenaire, le meme ecran que le personnel moins les trois champs que le
/// serveur refuse a un partenaire. C'est
/// `test/formulaire_vehicule_partenaire_test.dart` qui tient ce chemin.
///
/// Douze bancs vivaient ici sur la branche vehicule de cet ecran apres son
/// retrait de la navigation. Ils passaient — sur du code que plus aucun
/// vendeur ne traversait. Une suite verte sur du code mort ne mesure rien, et
/// laisse croire que le chemin reel est tenu.
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
  /// L'ASSERTION QUI EMPÊCHE DE RECONSTITUER LA BRANCHE MORTE.
  ///
  /// Sans elle, un `kind: vehicles` distrait afficherait un formulaire de
  /// pièce — nom d'article, SKU, stock — sous le titre « Ajouter un
  /// véhicule », sans qu'un mot ne soit dit. C'est exactement le retour en
  /// arrière silencieux que ce lot supprime.
  testWidgets('ouvrir cet écran pour un véhicule est refusé', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [partnerRepositoryProvider.overrideWithValue(_Repository())],
      child: const MaterialApp(
        home: PartnerListingFormPage(kind: PartnerListingKind.vehicles),
      ),
    ));

    expect(tester.takeException(), isAssertionError,
        reason: 'Un véhicule partenaire passe par VehicleRegisterPage : cet '
            'écran ne sait plus en décrire un.');
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
