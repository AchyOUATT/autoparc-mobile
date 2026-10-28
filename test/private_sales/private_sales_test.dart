import 'dart:io';
import 'dart:ui' as ui;

import 'package:auto/core/api/api_client.dart';
import 'package:auto/core/api/api_exception.dart';
import 'package:auto/features/auth/data/auth_repository.dart';
import 'package:auto/features/auth/presentation/providers/auth_provider.dart';
import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/private_sales/data/private_listing_repository.dart';
import 'package:auto/features/private_sales/presentation/private_listing_detail.dart';
import 'package:auto/features/private_sales/presentation/private_listing_form.dart';
import 'package:auto/features/private_sales/presentation/private_listings_page.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import 'package:auto/features/vehicles/presentation/widgets/vehicle_identity_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../support/polices.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAuth extends StateNotifier<AuthState> implements AuthNotifier {
  TestAuth(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const saleToyota = BrandRef(id: 3, name: 'Toyota', isActive: true);
const saleHonda = BrandRef(id: 4, name: 'Honda', isActive: true);
const saleOlderCorolla = ModelRef(
  id: 10,
  brandId: 3,
  name: 'Corolla',
  generation: 'E140',
  productionStart: 2006,
  productionEnd: 2012,
);
const saleCorolla = ModelRef(
  id: 11,
  brandId: 3,
  name: 'Corolla',
  generation: 'E180',
  productionStart: 2013,
  productionEnd: 2019,
);
const saleCivic = ModelRef(
  id: 12,
  brandId: 4,
  name: 'Civic',
  productionStart: 2010,
);
const saleTrim = TrimRef(id: 20, vehicleModelId: 11, name: 'LE');
const salePetrol = EngineTypeRef(
  id: 5,
  code: 'petrol',
  label: 'Essence',
  usesFuel: true,
  usesBattery: false,
);
const saleFwd = DrivetrainRef(id: 6, code: 'FWD', label: 'Traction avant');
const saleColor = ColorRef(id: 7, name: 'Blanc');
const saleRefs = CatalogRefs(
  brands: [saleToyota, saleHonda],
  vehicleModels: [saleOlderCorolla, saleCorolla, saleCivic],
  trims: [saleTrim],
  engineTypes: [salePetrol],
  drivetrains: [saleFwd],
  colors: [saleColor],
  features: [],
  locations: [],
);

OwnedVehicle garageSaleVehicle({bool freeModel = false}) => OwnedVehicle(
  id: 42,
  designation: 'Ancien libellé sans rapport avec les références',
  brandId: 3,
  vehicleModelId: freeModel ? null : 11,
  modelLibre: freeModel ? 'CX-9' : null,
  trimId: freeModel ? null : 20,
  engineTypeId: 5,
  drivetrainId: 6,
  colorId: 7,
  year: 2018,
  mileageKm: 85000,
  vin: 'PRIVATE-VIN-123456',
  plateNumber: 'PRIVATE-PLATE',
  engineCode: 'PRIVATE-ENGINE',
  identity: const OwnedVehicleIdentity(
    brand: 'Ancien nom',
    model: 'Ancien modèle',
  ),
  compatibilityReady: true,
);

Finder saleDropdown<T>() => find.byWidgetPredicate(
  (widget) => widget is DropdownButtonFormField<T>,
  skipOffstage: false,
);

T? saleSelected<T>(WidgetTester tester) {
  final finder = saleDropdown<T>();
  if (finder.evaluate().isEmpty) return null;
  return tester.state<FormFieldState<T>>(finder).value;
}

Future<void> chooseSale<T>(WidgetTester tester, T? value) async {
  tester.widget<DropdownButtonFormField<T>>(saleDropdown<T>()).onChanged!(
    value,
  );
  await tester.pumpAndSettle();
}

void saleViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder saleTextField(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
  skipOffstage: false,
);

Future<void> fillSaleCommercial(WidgetTester tester) async {
  for (final entry in {
    'Prix en FCFA': '6500000',
    'Ville': 'Ouagadougou',
    'État du véhicule et informations utiles':
        'Véhicule entretenu et disponible pour une visite.',
    'Nom affiché aux acheteurs': 'Vendeur particulier',
    // Le numéro que le personnel appellera : champ obligatoire du formulaire
    // depuis que la vérification ne passe plus par un SMS.
    'Téléphone avec indicatif': '+22670000000',
  }.entries) {
    await tester.ensureVisible(saleTextField(entry.key));
    await tester.enterText(saleTextField(entry.key), entry.value);
  }
}

Future<void> saveSaleDraft(WidgetTester tester) async {
  final save = find.text('Enregistrer le brouillon');
  final edit = find.text('Enregistrer les modifications');
  final button = save.evaluate().isNotEmpty ? save : edit;
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Map<String, dynamic> listingFields({
  int id = 1,
  String status = 'published',
  /// Un modérateur a-t-il déjà appelé ce vendeur ?
  bool appelPasse = true,
  /// Ce que le vendeur a saisi, vide pour l'annonce qui n'indique aucun numéro.
  String numeroSaisi = '+22670000000',
}) => {
  'id': id,
  'title': 'Toyota Corolla 2018',
  'brand_id': 3,
  'vehicle_model_id': 11,
  'model_libre': null,
  'trim_id': 20,
  'engine_type_id': 5,
  'drivetrain_id': 6,
  'color_id': 7,
  'transmission': 'cvt',
  'year': 2018,
  'mileage_km': 85000,
  'price': 6500000,
  'city': 'Ouagadougou',
  'seller_type': 'private',
  'seller_name': 'Vendeur de démonstration',
  // Les deux numeros du serveur, et ils ne disent pas la meme chose :
  // `phone` est le numero VERIFIE par un appel du personnel, `phone_claimed`
  // est celui que le vendeur a saisi. Une annonce publiee porte les deux.
  'phone': appelPasse ? numeroSaisi : '',
  'phone_claimed': numeroSaisi,
  'phone_verified_at': appelPasse ? '2026-10-28T10:00:00+00:00' : null,
  'phone_verified': appelPasse,
  'description':
      'Véhicule entretenu, climatisation fonctionnelle. Disponible pour une visite.',
  'whatsapp_enabled': false,
  'status': status,
  'revision': 4,
  'photos': <Map<String, dynamic>>[],
};

/// Ce que la liste PUBLIQUE sert réellement : tout, sauf le numéro.
///
/// `PrivateVehicleListingResource` pose `phone` derrière la présence du
/// paramètre de route : l'index n'en a pas, la fiche si. Sans cette aide, les
/// bancs mobiles mesureraient une liste plus bavarde que celle de production,
/// et la régression qu'ils doivent attraper leur échapperait.
Map<String, dynamic> sansNumeroPublic(Map<String, dynamic> fields) =>
    Map<String, dynamic>.from(fields)
      ..remove('phone')
      ..remove('phone_claimed')
      ..remove('phone_verified_at');

class FakeSalesApi implements ApiClient {
  final queries = <({String path, Map<String, dynamic>? params})>[];
  final commands = <({String path, Map<String, dynamic>? data})>[];
  bool fail = false, empty = false;
  bool appelPasse = true;
  String numeroSaisi = '+22670000000';
  String status = 'published';
  Map<String, dynamic>? saved;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    queries.add((path: path, params: params));
    if (fail) {
      throw const ApiException(
        message: 'Le serveur est momentanément indisponible.',
        statusCode: 503,
      );
    }
    // La FICHE rend un objet, la LISTE un tableau — et c'est la fiche, elle
    // seule, qui porte le numéro du vendeur depuis que la liste publique ne le
    // sert plus. Le chemin se termine par un identifiant.
    if (RegExp(r'/\d+$').hasMatch(path)) {
      return {
        'data': listingFields(
          id: 1,
          status: status,
          appelPasse: appelPasse,
          numeroSaisi: numeroSaisi,
        ),
      };
    }

    return {
      'data': empty
          ? []
          : [
              // Seule la liste PUBLIQUE est depouillee. Celle du vendeur et
              // celle du moderateur portent le numero : pour le serveur ces
              // deux lecteurs sont « prives ».
              if (path == '/private-listings')
                sansNumeroPublic(
                  listingFields(
                    id: params?['page'] as int? ?? 1,
                    status: status,
                    appelPasse: appelPasse,
                    numeroSaisi: numeroSaisi,
                  ),
                )
              else
                listingFields(
                  id: params?['page'] as int? ?? 1,
                  status: status,
                  appelPasse: appelPasse,
                  numeroSaisi: numeroSaisi,
                ),
            ],
      'meta': {'current_page': params?['page'] ?? 1, 'last_page': 2},
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    commands.add((path: path, data: data));
    if (fail) {
      throw const ApiException(
        message: 'La décision n’a pas été enregistrée.',
        statusCode: 503,
      );
    }
    if (path == '/my/private-listings') {
      saved = data;
      return {
        'data': {...listingFields(status: 'draft'), ...?data},
      };
    }
    empty = true;
    return {'data': listingFields(status: 'pending')};
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    commands.add((path: path, data: data));
    saved = data;
    return {
      'data': {...listingFields(status: 'draft'), ...?data},
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AuthState get manager => const AuthState(
  type: AuthType.staff,
  staffUser: StaffUser(
    id: 2,
    name: 'Responsable',
    email: 'manager@example.test',
    role: 'manager',
  ),
);

Future<void> open(
  WidgetTester tester,
  FakeSalesApi api,
  Widget screen, {
  AuthState auth = const AuthState(type: AuthType.client),
  GlobalKey? capture,
  Future<CatalogRefs> Function()? loadRefs,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        authProvider.overrideWith((_) => TestAuth(auth)),
        catalogRefsProvider.overrideWith(
          (_) async => loadRefs == null ? saleRefs : await loadRefs(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff18594a)),
        ),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: capture == null
            ? screen
            : RepaintBoundary(key: capture, child: screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> capture(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  final output = Platform.environment['PRIVATE_SALES_SCREENSHOTS'];
  if (output == null) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$output/$filename').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(chargerPolices);

  test(
    'repository keeps public, seller and moderation routes separate',
    () async {
      final api = FakeSalesApi();
      final repository = PrivateListingRepository(api);
      await repository.list(
        PrivateListingMode.browse,
        page: 2,
        search: 'Toyota',
      );
      await repository.list(PrivateListingMode.mine);
      await repository.list(PrivateListingMode.review, status: 'published');
      await repository.review(7, revision: 4);
      expect(api.queries.map((query) => query.path), [
        '/private-listings',
        '/my/private-listings',
        '/private-listing-reviews',
      ]);
      expect(api.queries.first.params, {'page': 2, 'search': 'Toyota'});
      expect(api.commands.single.data, {'revision': 4});
    },
  );

  test('listing accepts numeric ids and amounts as strings', () {
    final listing = PrivateListing({
      ...listingFields(),
      'id': '4',
      'price': '6500000',
    });
    expect(listing.id, 4);
    expect(listing.number('price'), 6500000);
    expect(listing.statusLabel, 'En ligne');
  });

  testWidgets('guest cannot load seller data', (tester) async {
    final api = FakeSalesApi();
    await open(
      tester,
      api,
      const PrivateListingsPage(mode: PrivateListingMode.mine),
      auth: const AuthState(),
    );
    expect(api.queries, isEmpty);
    expect(find.text('Se connecter pour gérer mes annonces'), findsOneWidget);
  });

  testWidgets('viewer cannot load or moderate announcements', (tester) async {
    final api = FakeSalesApi();
    await open(
      tester,
      api,
      const PrivateListingsPage(mode: PrivateListingMode.review),
      auth: const AuthState(
        type: AuthType.staff,
        staffUser: StaffUser(
          id: 3,
          name: 'Lecteur',
          email: 'viewer@example.test',
          role: 'viewer',
        ),
      ),
    );
    expect(api.queries, isEmpty);
    expect(find.text('Publier'), findsNothing);
  });

  testWidgets('seller list paginates and displays moderation status', (
    tester,
  ) async {
    final api = FakeSalesApi()..status = 'pending';
    await open(
      tester,
      api,
      const PrivateListingsPage(mode: PrivateListingMode.mine),
    );
    expect(find.text('En cours de validation'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(api.queries.last.params?['page'], 2);
    expect(api.queries.last.path, '/my/private-listings');
  });

  testWidgets('moderation publishes precisely the revision displayed', (
    tester,
  ) async {
    final api = FakeSalesApi()..status = 'pending';
    await open(
      tester,
      api,
      const PrivateListingsPage(mode: PrivateListingMode.review),
      auth: manager,
    );
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();
    expect(api.commands.single.path, '/private-listing-reviews/1/approve');
    expect(api.commands.single.data, {'revision': 4});
    expect(find.text('Aucune annonce à examiner.'), findsOneWidget);
  });

  /// L'acheteur peut appeler, même si la liste ne porte plus le numéro.
  ///
  /// C'est la moitié cliente d'une correction serveur : la liste publique ne
  /// sert plus le téléphone — elle était un annuaire de particuliers
  /// moissonnable d'un seul appel — et la fiche le sert. Or cet écran recevait
  /// son annonce de la liste et ne rechargeait jamais : sans la requête que ce
  /// banc mesure, les deux boutons disparaîtraient pour tous les acheteurs.
  testWidgets('la fiche publique charge le numéro que la liste ne donne plus', (
    tester,
  ) async {
    final api = FakeSalesApi();
    final depuisLaListe = PrivateListing(
      sansNumeroPublic(listingFields()),
    );
    expect(depuisLaListe.verifiedPhone, isEmpty, reason: 'La liste ne le donne pas.');

    await open(
      tester,
      api,
      PrivateListingDetail(listing: depuisLaListe),
    );
    await tester.pumpAndSettle();

    expect(api.queries.single.path, '/private-listings/1');
    expect(find.text('Appeler le vendeur'), findsOneWidget);
    expect(find.text('Téléphone vérifié'), findsOneWidget);
  });

  /// Le vendeur et le modérateur, eux, ne déclenchent aucune requête.
  ///
  /// Pour le serveur ils sont « privés » : leur liste porte déjà le numéro. Et
  /// la route publique rendrait 404 sur une annonce non publiée, donc charger
  /// serait non seulement inutile mais faux.
  testWidgets('la fiche du vendeur ne recharge rien', (tester) async {
    final api = FakeSalesApi();
    await open(
      tester,
      api,
      PrivateListingDetail(
        listing: PrivateListing(listingFields()),
        publicListing: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(api.queries, isEmpty);
    expect(find.text('Appeler le vendeur'), findsOneWidget);
  });

  /// Un numéro au format local est refusé SOUS LE CHAMP, pas par une exception.
  ///
  /// Le garde vivait dans `_sendCode` et levait un `StateError` dont
  /// `messageFor` jetait le texte : l'écran affichait « Une erreur est
  /// survenue » et le vendeur ne savait pas qu'il manquait « +226 ». Dans le
  /// `validator`, Material pose la phrase sous le champ fautif. C'est la forme
  /// que le serveur exige aussi : un numéro qu'on ne peut pas composer ne vaut
  /// rien à qui doit appeler.
  testWidgets('un numéro sans indicatif est refusé sous le champ', (
    tester,
  ) async {
    final api = FakeSalesApi();
    saleViewport(tester);
    await open(tester, api, const PrivateListingForm());
    await chooseSale<BrandRef>(tester, saleToyota);
    await chooseSale<ModelRef>(tester, saleCorolla);
    await tester.enterText(
      find.byKey(const ValueKey('private-sale-year')),
      '2018',
    );
    await tester.enterText(
      find.byKey(const ValueKey('private-sale-mileage')),
      '85000',
    );
    await fillSaleCommercial(tester);

    // Le format local, celui que le vendeur dit à l'oral.
    await tester.ensureVisible(saleTextField('Téléphone avec indicatif'));
    await tester.enterText(
      saleTextField('Téléphone avec indicatif'),
      '70000000',
    );
    await saveSaleDraft(tester);

    expect(api.commands, isEmpty, reason: 'Rien ne doit partir au serveur.');
    expect(find.textContaining('+22670000000'), findsWidgets);
    expect(find.text('Une erreur est survenue. Réessayez.'), findsNothing);
  });

  /// Le bouton d'envoi DIT ce qui l'empêche, au lieu d'être grisé en silence.
  ///
  /// La phrase prévue pour l'expliquer vivait dans `_submit`, derrière le même
  /// `_dirty` qui désactive le bouton qui appelle `_submit` : elle ne pouvait
  /// jamais s'afficher. Le vendeur devait devenir qu'il fallait d'abord
  /// enregistrer.
  ///
  /// Et le bouton « Ajouter des photos » n'est PLUS grisé par `_dirty` : un
  /// envoi de photo n'a besoin que de l'identifiant, et la sauvegarde n'envoie
  /// aucune révision.
  testWidgets('l’envoi grisé dit son premier obstacle', (tester) async {
    final api = FakeSalesApi();
    saleViewport(tester);
    await open(
      tester,
      api,
      PrivateListingForm(
        existing: PrivateListing(listingFields(status: 'draft')),
      ),
    );
    await tester.pumpAndSettle();

    // Sans photo : c'est le premier obstacle, et il est écrit.
    expect(find.text('Ajoutez au moins une photo.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Envoyer pour validation'),
          )
          .onPressed,
      isNull,
    );

    // Une frappe lève `_dirty` : l'obstacle change, et il le dit aussi.
    await tester.ensureVisible(saleTextField('Ville'));
    await tester.enterText(saleTextField('Ville'), 'Bobo-Dioulasso');
    await tester.pumpAndSettle();
    expect(
      find.text('Enregistrez vos modifications avant d’envoyer l’annonce.'),
      findsOneWidget,
    );

    // Et le bouton des photos reste utilisable malgré `_dirty`.
    final photos = find.widgetWithText(OutlinedButton, 'Ajouter des photos');
    expect(photos, findsOneWidget);
    expect(tester.widget<OutlinedButton>(photos).onPressed, isNotNull);
  });

  /// Refuser avec un motif trop court le DIT, au lieu de ne rien faire.
  ///
  /// Sous cinq signes, le bouton ne faisait rien : pas de message, pas de
  /// fermeture. Et le compteur de `maxLength` affichait « 4/2000 », ce qui
  /// disait l'inverse de la règle du serveur. C'est l'unique guichet de
  /// modération de cette boutique.
  testWidgets('un motif trop court est refusé en le disant', (tester) async {
    final api = FakeSalesApi()..status = 'pending';
    await open(
      tester,
      api,
      const PrivateListingsPage(mode: PrivateListingMode.review),
      auth: manager,
    );

    await tester.tap(find.text('Refuser / retirer'));
    await tester.pumpAndSettle();
    expect(find.text('Au moins 5 caractères.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, 'flou');
    await tester.tap(find.widgetWithText(FilledButton, 'Refuser / retirer'));
    await tester.pumpAndSettle();

    // Le message du VALIDATEUR, et non le `helperText` — celui-ci est
    // toujours affiché, donc le chercher ne distinguerait pas un refus dit
    // d'un refus muet. C'est la phrase longue qui prouve que le validateur
    // a tourné.
    expect(
      find.text(
        'Au moins 5 caractères : le vendeur doit comprendre quoi corriger.',
      ),
      findsOneWidget,
      reason: 'Le refus muet laissait le réviseur croire le bouton cassé.',
    );
    expect(api.commands, isEmpty);

    // Un motif suffisant, lui, passe.
    await tester.enterText(find.byType(TextFormField).last, 'Photos floues');
    await tester.tap(find.widgetWithText(FilledButton, 'Refuser / retirer'));
    await tester.pumpAndSettle();
    expect(api.commands.single.path, '/private-listing-reviews/1/reject');
    expect(api.commands.single.data?['reason'], 'Photos floues');
  });

  /// Publier un numéro jamais appelé exige l'appel, et le dit.
  ///
  /// C'est tout ce qui reste de la preuve de possession depuis que la
  /// vérification par SMS est abandonnée : le serveur refuse de publier sans
  /// l'affirmation, et cette boîte est l'endroit où elle est demandée. Le banc
  /// tient les trois points qui comptent — le numéro est affiché, la
  /// publication est impossible tant que la case n'est pas cochée, et la
  /// question à poser est à l'écran.
  testWidgets('publier un numéro jamais appelé exige l’appel', (tester) async {
    final api = FakeSalesApi()
      ..status = 'pending'
      ..appelPasse = false;
    await open(
      tester,
      api,
      const PrivateListingsPage(mode: PrivateListingMode.review),
      auth: manager,
    );

    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();

    // Rien n'est parti : la boîte attend.
    expect(api.commands, isEmpty);
    expect(find.text('+22670000000'), findsOneWidget);
    expect(find.textContaining('déposé cette annonce'), findsWidgets);

    // Le bouton de la boîte est mort tant que la case n'est pas cochée.
    final publier = find.widgetWithText(FilledButton, 'Publier').last;
    expect(tester.widget<FilledButton>(publier).onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Publier').last);
    await tester.pumpAndSettle();

    expect(api.commands.single.path, '/private-listing-reviews/1/approve');
    expect(api.commands.single.data, {'revision': 4, 'phone_verified': true});
  });

  /// Une annonce sans numéro ne peut pas être publiée, et on dit quoi faire.
  ///
  /// La colonne est nullable : une annonce déposée avant la bascule du SMS
  /// vers l'appel n'a aucun numéro. Le serveur la refuserait de toute façon ;
  /// ce banc tient que le modérateur l'apprend ici, au lieu de voir une erreur
  /// venue du serveur sans savoir qu'en faire.
  testWidgets('une annonce sans numéro n’offre pas de publier', (tester) async {
    final api = FakeSalesApi()
      ..status = 'pending'
      ..appelPasse = false
      ..numeroSaisi = '';
    await open(
      tester,
      api,
      const PrivateListingsPage(mode: PrivateListingMode.review),
      auth: manager,
    );

    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();

    expect(api.commands, isEmpty);
    expect(find.textContaining('n’indique aucun numéro'), findsOneWidget);
  });

  testWidgets('failed moderation stays visible with an actionable message', (
    tester,
  ) async {
    final api = FakeSalesApi()..status = 'pending';
    await open(
      tester,
      api,
      const PrivateListingsPage(mode: PrivateListingMode.review),
      auth: manager,
    );
    api.fail = true;
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();
    expect(find.text('La décision n’a pas été enregistrée.'), findsOneWidget);
    expect(find.text('Publier'), findsOneWidget);
  });

  testWidgets('selling form requires the normal client account', (
    tester,
  ) async {
    final api = FakeSalesApi();
    await open(
      tester,
      api,
      const PrivateListingForm(),
      auth: const AuthState(),
    );
    expect(find.text('Se connecter pour vendre'), findsOneWidget);
    expect(api.commands, isEmpty);
  });

  testWidgets('a valid form saves a draft without creating a partner account', (
    tester,
  ) async {
    final api = FakeSalesApi();
    saleViewport(tester);
    await open(tester, api, const PrivateListingForm());
    expect(find.byType(VehicleIdentityFields), findsOneWidget);
    await chooseSale<BrandRef>(tester, saleToyota);
    await chooseSale<ModelRef>(tester, saleCorolla);
    await tester.enterText(
      find.byKey(const ValueKey('private-sale-year')),
      '2018',
    );
    await tester.enterText(
      find.byKey(const ValueKey('private-sale-mileage')),
      '85000',
    );
    await fillSaleCommercial(tester);
    await saveSaleDraft(tester);
    expect(api.commands.single.path, '/my/private-listings');
    expect(api.saved?['brand_id'], 3);
    expect(api.saved?['vehicle_model_id'], 11);
    expect(api.saved?.containsKey('title'), false);
    expect(api.saved?.containsKey('fuel_type'), false);
    expect(api.saved?.containsKey('verified_phone'), false);
    expect(find.text('Brouillon'), findsOneWidget);
    expect(find.text('Ajouter des photos'), findsOneWidget);
  });

  testWidgets(
    'editing restores exact reference IDs instead of matching public labels',
    (tester) async {
      saleViewport(tester);
      final existing = PrivateListing({
        ...listingFields(status: 'draft'),
        'title': 'Ancien libellé public',
      });
      await open(
        tester,
        FakeSalesApi(),
        PrivateListingForm(existing: existing),
      );
      expect(saleSelected<BrandRef>(tester)?.id, 3);
      expect(saleSelected<ModelRef>(tester)?.id, 11);
      expect(saleSelected<TrimRef>(tester)?.id, 20);
      expect(saleSelected<EngineTypeRef>(tester)?.id, 5);
      expect(saleSelected<DrivetrainRef>(tester)?.id, 6);
      expect(saleSelected<ColorRef>(tester)?.id, 7);
      expect(saleTextField('Véhicule (marque et modèle)'), findsNothing);
    },
  );

  testWidgets(
    'garage prefill keeps reference IDs and never submits its private identifiers',
    (tester) async {
      saleViewport(tester);
      final api = FakeSalesApi();
      await open(tester, api, PrivateListingForm(vehicle: garageSaleVehicle()));
      expect(saleSelected<ModelRef>(tester)?.id, 11);
      expect(saleSelected<TrimRef>(tester)?.id, 20);
      expect(saleSelected<EngineTypeRef>(tester)?.id, 5);
      expect(saleSelected<DrivetrainRef>(tester)?.id, 6);
      expect(saleSelected<ColorRef>(tester)?.id, 7);
      await fillSaleCommercial(tester);
      await saveSaleDraft(tester);
      expect(api.saved?['owned_vehicle_id'], 42);
      expect(api.saved?['year'].toString(), '2018');
      expect(api.saved?['mileage_km'].toString(), '85000');
      for (final key in [
        'vin',
        'plate_number',
        'engine_code',
        'title',
        'fuel_type',
        'owner_partner_account_id',
        'partner_id',
        'location_id',
        'site',
        'rental_daily_rate',
        'rental_monthly_rate',
      ]) {
        expect(
          api.saved?.containsKey(key),
          false,
          reason: '$key must stay out of a private advertisement payload',
        );
      }
      expect(api.saved.toString(), isNot(contains('PRIVATE-')));
    },
  );

  testWidgets(
    'changing brand clears previous model and technical references on update',
    (tester) async {
      saleViewport(tester);
      final api = FakeSalesApi();
      await open(
        tester,
        api,
        PrivateListingForm(
          existing: PrivateListing(listingFields(status: 'draft')),
        ),
      );
      await chooseSale<BrandRef>(tester, saleHonda);
      expect(saleSelected<ModelRef>(tester), isNull);
      expect(saleSelected<TrimRef>(tester), isNull);
      expect(saleSelected<EngineTypeRef>(tester), isNull);
      expect(saleSelected<DrivetrainRef>(tester), isNull);
      await chooseSale<ModelRef>(tester, saleCivic);
      await saveSaleDraft(tester);
      expect(api.commands.single.path, '/my/private-listings/1');
      expect(api.saved?['brand_id'], 4);
      expect(api.saved?['vehicle_model_id'], 12);
      for (final key in ['trim_id', 'engine_type_id', 'drivetrain_id']) {
        expect(api.saved?.containsKey(key), true);
        expect(api.saved?[key], isNull);
      }
    },
  );

  testWidgets(
    'changing generation removes old trim and motorisation with explicit nulls',
    (tester) async {
      saleViewport(tester);
      final api = FakeSalesApi();
      await open(
        tester,
        api,
        PrivateListingForm(
          existing: PrivateListing(listingFields(status: 'draft')),
        ),
      );
      await chooseSale<ModelRef>(tester, saleOlderCorolla);
      await tester.enterText(
        find.byKey(const ValueKey('private-sale-year')),
        '2010',
      );
      await saveSaleDraft(tester);
      expect(api.saved?['vehicle_model_id'], 10);
      for (final key in ['trim_id', 'engine_type_id', 'drivetrain_id']) {
        expect(api.saved?.containsKey(key), true);
        expect(api.saved?[key], isNull);
      }
    },
  );

  testWidgets(
    'model outside the list uses free text and clears former catalogue relationships',
    (tester) async {
      saleViewport(tester);
      final api = FakeSalesApi();
      await open(
        tester,
        api,
        PrivateListingForm(
          existing: PrivateListing(listingFields(status: 'draft')),
        ),
      );
      await tester.ensureVisible(
        find.text('Mon modèle n’est pas dans la liste'),
      );
      await tester.tap(find.text('Mon modèle n’est pas dans la liste'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('private-sale-model-libre')),
        '  CX-9  ',
      );
      await saveSaleDraft(tester);
      expect(api.saved?['brand_id'], 3);
      expect(api.saved?['vehicle_model_id'], isNull);
      expect(api.saved?['model_libre'], 'CX-9');
      expect(api.saved?['trim_id'], isNull);
      expect(api.saved?['engine_type_id'], isNull);
      expect(api.saved?['drivetrain_id'], isNull);
    },
  );

  testWidgets(
    'a garage model outside the catalogue remains editable without inventing a model ID',
    (tester) async {
      saleViewport(tester);
      final api = FakeSalesApi();
      await open(
        tester,
        api,
        PrivateListingForm(vehicle: garageSaleVehicle(freeModel: true)),
      );
      expect(
        find.byKey(const ValueKey('private-sale-model-libre')),
        findsOneWidget,
      );
      final field = tester.widget<TextFormField>(
        find.byKey(const ValueKey('private-sale-model-libre')),
      );
      expect(field.controller?.text, 'CX-9');
      await fillSaleCommercial(tester);
      await saveSaleDraft(tester);
      expect(api.saved?['vehicle_model_id'], isNull);
      expect(api.saved?['model_libre'], 'CX-9');
    },
  );

  testWidgets(
    'missing vehicle identity stops creation before calling the API',
    (tester) async {
      saleViewport(tester);
      final api = FakeSalesApi();
      await open(tester, api, const PrivateListingForm());
      await tester.enterText(
        find.byKey(const ValueKey('private-sale-year')),
        '2018',
      );
      await tester.enterText(
        find.byKey(const ValueKey('private-sale-mileage')),
        '85000',
      );
      await fillSaleCommercial(tester);
      await saveSaleDraft(tester);
      expect(api.commands, isEmpty);
      expect(
        tester
            .state<FormFieldState<BrandRef>>(saleDropdown<BrandRef>())
            .hasError,
        true,
      );
    },
  );

  testWidgets(
    'reference loading failure offers retry without creating an announcement',
    (tester) async {
      final api = FakeSalesApi();
      var unavailable = true;
      await open(
        tester,
        api,
        const PrivateListingForm(),
        loadRefs: () async {
          if (unavailable) {
            throw const ApiException(
              message: 'Référentiel indisponible',
              statusCode: 503,
            );
          }
          return saleRefs;
        },
      );
      expect(find.text('Réessayer'), findsOneWidget);
      expect(api.commands, isEmpty);
      unavailable = false;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();
      expect(find.byType(VehicleIdentityFields), findsOneWidget);
      expect(api.commands, isEmpty);
    },
  );

  testWidgets('local captures of buyer, seller and moderation screens', (
    tester,
  ) async {
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    tester.view.physicalSize = const Size(420, 920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await open(
      tester,
      FakeSalesApi(),
      const PrivateListingsPage(),
      capture: key,
    );
    await capture(tester, key, 'annonces-particuliers.png');
    await open(
      tester,
      FakeSalesApi()..status = 'pending',
      const PrivateListingsPage(mode: PrivateListingMode.mine),
      capture: key,
    );
    await capture(tester, key, 'mes-annonces.png');
    await open(
      tester,
      FakeSalesApi()..status = 'pending',
      const PrivateListingsPage(mode: PrivateListingMode.review),
      auth: manager,
      capture: key,
    );
    await capture(tester, key, 'validation-annonces.png');
    await open(
      tester,
      FakeSalesApi(),
      const PrivateListingForm(),
      capture: key,
    );
    await capture(tester, key, 'vendre-ma-voiture.png');
    debugDisableShadows = true;
    expect(tester.takeException(), isNull);
  });
}
