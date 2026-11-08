import 'package:auto/features/partner_accounts/data/partner_repository.dart'
    as espace;
import 'package:auto/features/vehicles/presentation/pages/vehicle_form_mode.dart';
import 'package:auto/features/partner_accounts/presentation/partner_session.dart';
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
import 'package:auto/l10n/app_localizations.dart';

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
const _modele = ModelRef(
  id: 11,
  brandId: 3,
  name: 'Corolla',
  generation: 'E180',
);
const _motorisation = EngineTypeRef(
  id: 5,
  code: 'petrol',
  label: 'Essence',
  usesFuel: true,
  usesBattery: false,
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
Vehicle _vehicule({
  Map<String, dynamic> Function(Map<String, dynamic>)? retouche,
}) {
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

class _DepotPartenaire extends espace.PartnerRepository {
  @override
  Future<Map<String, dynamic>> listing(
    espace.PartnerListingKind kind,
    int id,
  ) async => {
    'fault_declaration': {'state': 'unknown', 'faults': []},
  };
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
    data: [],
    currentPage: 1,
    lastPage: 1,
    total: 0,
    perPage: 50,
  );
}

class _SessionVide extends StateNotifier<PartnerSession>
    implements PartnerSessionNotifier {
  _SessionVide() : super(const PartnerSession());
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _ouvrir(
  WidgetTester tester,
  _Depot depot,
  Vehicle? existant, {
  Locale locale = const Locale('fr'),
  VehicleFormMode mode = VehicleFormMode.personnel,
  CatalogRefs references = _refs,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        partnerSessionProvider.overrideWith((_) => _SessionVide()),
        espace.partnerRepositoryProvider.overrideWithValue(_DepotPartenaire()),
        catalogRefsProvider.overrideWith((_) async => references),
        countriesProvider.overrideWith((_) async => <CountryRef>[]),
        vehicleAdminRepositoryProvider.overrideWithValue(depot),
        partnerRepositoryProvider.overrideWithValue(_Annuaire()),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: VehicleRegisterPage(existing: existant, mode: mode),
      ),
    ),
  );
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
  testWidgets('disposing during a step transition cancels framing safely', (
    tester,
  ) async {
    await _ouvrir(tester, _Depot(), _vehicule());
    tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final mode in VehicleFormMode.values) {
    for (final locale in [const Locale('fr'), const Locale('en')]) {
      testWidgets(
        'model defaults respect category and payload: $mode $locale',
        (tester) async {
          const suv = ModelRef(
            id: 11,
            brandId: 3,
            name: 'SUV example',
            bodyType: 'suv',
            defaultVehicleType: 'passenger',
          );
          const contradictory = ModelRef(
            id: 12,
            brandId: 3,
            name: 'Legacy example',
            bodyType: 'sedan',
            defaultVehicleType: 'heavy',
          );
          const bus = ModelRef(
            id: 13,
            brandId: 3,
            name: 'Bus example',
            bodyType: 'bus',
            defaultVehicleType: 'heavy',
          );
          const references = CatalogRefs(
            brands: [_marque],
            vehicleModels: [suv, contradictory, bus],
            trims: [],
            engineTypes: [_motorisation],
            drivetrains: [],
            colors: [],
            features: [],
            locations: [],
          );
          final depot = _Depot();
          await _ouvrir(
            tester,
            depot,
            _vehicule(),
            mode: mode,
            locale: locale,
            references: references,
          );
          final l = await AppLocalizations.delegate.load(locale);
          final body = find.byWidgetPredicate(
            (w) =>
                w is DropdownButtonFormField<String> &&
                w.decoration.labelText == l.vehiclesBodyStyleLabel,
            skipOffstage: false,
          );
          final model = find.byWidgetPredicate(
            (w) => w is DropdownButtonFormField<ModelRef>,
            skipOffstage: false,
          );
          tester
              .widget<ChoiceChip>(
                find.byWidgetPredicate(
                  (w) =>
                      w is ChoiceChip &&
                      w.label is Text &&
                      (w.label as Text).data == l.vehiclesTypeHeavy,
                ),
              )
              .onSelected!(true);
          await tester.pumpAndSettle();
          expect(tester.state<FormFieldState<String>>(body).value, isNull);
          expect(tester.state<FormFieldState<ModelRef>>(model).value, isNull);
          tester.widget<DropdownButtonFormField<ModelRef>>(model).onChanged!(
            suv,
          );
          await tester.pumpAndSettle();
          expect(tester.state<FormFieldState<ModelRef>>(model).value, isNull);
          expect(find.text(l.vehiclesModelTypeMismatch), findsOneWidget);
          tester.widget<DropdownButtonFormField<ModelRef>>(model).onChanged!(
            contradictory,
          );
          await tester.pumpAndSettle();
          expect(tester.state<FormFieldState<String>>(body).value, isNull);
          expect(find.text(l.vehiclesBodyStyleReselect), findsOneWidget);
          tester.widget<DropdownButtonFormField<ModelRef>>(model).onChanged!(
            bus,
          );
          await tester.pumpAndSettle();
          expect(tester.state<FormFieldState<String>>(body).value, 'bus');
          expect(tester.state<FormFieldState<ModelRef>>(model).value, bus);
          expect(find.text(l.vehiclesBodyStyleReselect), findsNothing);
          tester
              .widget<DropdownButtonFormField<EngineTypeRef>>(
                find.byWidgetPredicate(
                  (w) => w is DropdownButtonFormField<EngineTypeRef>,
                  skipOffstage: false,
                ),
              )
              .onChanged!(_motorisation);
          await tester.pumpAndSettle();
          if (mode == VehicleFormMode.personnel) {
            await _enregistrer(tester);
            expect(depot.charge?['vehicle_type'], 'heavy');
            expect(depot.charge?['body_style'], 'bus');
            expect(depot.charge?['vehicle_model_id'], bus.id);
          }
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'body options follow category and explain reselection: $mode $locale',
        (tester) async {
          await _ouvrir(tester, _Depot(), null, mode: mode, locale: locale);
          final l = await AppLocalizations.delegate.load(locale);
          Finder field() => find.byWidgetPredicate(
            (w) =>
                w is DropdownButtonFormField<String> &&
                w.decoration.labelText == l.vehiclesBodyStyleLabel,
            skipOffstage: false,
          );
          DropdownButtonFormField<String> body() => tester.widget(field());
          Future<void> type(String label) async {
            tester
                .widget<ChoiceChip>(
                  find.byWidgetPredicate(
                    (w) =>
                        w is ChoiceChip &&
                        w.label is Text &&
                        (w.label as Text).data == label,
                  ),
                )
                .onSelected!(true);
            await tester.pumpAndSettle();
          }

          List<String?> options() => tester
              .widget<DropdownButton<String>>(
                find.descendant(
                  of: field(),
                  matching: find.byWidgetPredicate(
                    (w) => w is DropdownButton<String>,
                  ),
                  skipOffstage: false,
                ),
              )
              .items!
              .map((item) => item.value)
              .toList();
          expect(options(), [
            'sedan',
            'hatchback',
            'suv',
            'estate',
            'coupe',
            'convertible',
            'other',
          ]);
          await type(l.vehiclesTypeUtility);
          expect(options(), ['pickup', 'van', 'minibus', 'other']);
          body().onChanged!('van');
          await tester.pumpAndSettle();
          await type(l.vehiclesTypeHeavy);
          expect(options(), ['bus', 'truck', 'other']);
          expect(
            body().decoration.hintText,
            '${l.catalogBodyLabelBus}, ${l.catalogBodyLabelTruck}',
          );
          expect(tester.state<FormFieldState<String>>(field()).value, isNull);
          expect(find.text(l.vehiclesBodyStyleReselect), findsOneWidget);
          tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
          await tester.pumpAndSettle();
          expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 0);
          expect(
            find.textContaining(l.vehiclesBodyStyleRequired),
            findsWidgets,
          );
          body().onChanged!('bus');
          await tester.pumpAndSettle();
          expect(tester.state<FormFieldState<String>>(field()).value, 'bus');
          expect(find.text(l.vehiclesBodyStyleReselect), findsNothing);
          await type(l.vehiclesTypePassenger);
          expect(options(), [
            'sedan',
            'hatchback',
            'suv',
            'estate',
            'coupe',
            'convertible',
            'other',
          ]);
          expect(tester.state<FormFieldState<String>>(field()).value, isNull);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'historical body stays until category changes: $mode $locale',
        (tester) async {
          final depot = _Depot();
          final existing = _vehicule(
            retouche: (j) => j
              ..['vehicle_type'] = 'heavy'
              ..['body_style'] = 'sedan',
          );
          await _ouvrir(tester, depot, existing, mode: mode, locale: locale);
          final l = await AppLocalizations.delegate.load(locale);
          final field = find.byWidgetPredicate(
            (w) =>
                w is DropdownButtonFormField<String> &&
                w.decoration.labelText == l.vehiclesBodyStyleLabel,
            skipOffstage: false,
          );
          expect(tester.state<FormFieldState<String>>(field).value, 'sedan');
          expect(
            tester
                .widget<DropdownButton<String>>(
                  find.descendant(
                    of: field,
                    matching: find.byWidgetPredicate(
                      (w) => w is DropdownButton<String>,
                    ),
                    skipOffstage: false,
                  ),
                )
                .items!
                .map((i) => i.value),
            containsAll(['sedan', 'bus', 'truck', 'other']),
          );
          tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
          await tester.pumpAndSettle();
          expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 1);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'keyboard closes on change; refused validation keeps viewport: $mode $locale',
        (tester) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await _ouvrir(
            tester,
            _Depot(),
            _vehicule(),
            mode: mode,
            locale: locale,
          );
          final l = await AppLocalizations.delegate.load(locale);
          final vin = _champ(l.vehiclesVinOptional);
          final beforeVin = tester.widget<TextField>(vin).controller!.text;
          await Scrollable.ensureVisible(tester.element(vin));
          await tester.showKeyboard(vin);
          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          await tester.pumpAndSettle();
          tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
          await tester.pump();
          expect(tester.testTextInput.isVisible, isFalse);
          tester.view.viewInsets = const FakeViewPadding(bottom: 120);
          await tester.pump(const Duration(milliseconds: 50));
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          final stepper = tester.widget<Stepper>(find.byType(Stepper));
          final form = find.byKey(stepper.steps[1].content.key!);
          expect(stepper.currentStep, 1);
          expect(
            tester.getTopLeft(form).dy,
            closeTo(tester.getTopLeft(find.byType(Stepper)).dy, 1),
          );
          expect(tester.widget<TextField>(vin).controller!.text, beforeVin);
          await tester.drag(find.byType(Stepper), const Offset(0, -60));
          await tester.pumpAndSettle();
          _ecrire(tester, l.vehiclesManufactureYearLabel, '1900');
          final next = find
              .descendant(
                of: find
                    .ancestor(of: form, matching: find.byType(Column))
                    .first,
                matching: find.byType(FilledButton),
              )
              .first;
          await Scrollable.ensureVisible(tester.element(next));
          await tester.pumpAndSettle();
          final position = Scrollable.of(tester.element(form)).position;
          final before = position.pixels;
          expect(before, greaterThan(144));
          tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
          await tester.pumpAndSettle();
          expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 1);
          expect(position.pixels, closeTo(before, 1));
          expect(find.byType(SnackBar), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final mode in VehicleFormMode.values) {
    for (final editing in [false, true]) {
      testWidgets('step viewport starts at new content: $mode edit=$editing', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _ouvrir(
          tester,
          _Depot(),
          editing ? _vehicule() : null,
          mode: mode,
        );
        final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
        if (!editing) {
          tester
              .widget<DropdownButtonFormField<String>>(
                find.byWidgetPredicate(
                  (w) =>
                      w is DropdownButtonFormField<String> &&
                      w.decoration.labelText == l10n.vehiclesBodyStyleLabel,
                  skipOffstage: false,
                ),
              )
              .onChanged!('sedan');
          await tester.pumpAndSettle();
        }
        Future<void> control(bool next) async {
          await tester.drag(find.byType(Stepper), const Offset(0, -60));
          await tester.pumpAndSettle();
          final current = tester.widget<Stepper>(find.byType(Stepper));
          final form = find.byKey(
            current.steps[current.currentStep].content.key!,
          );
          final button = find.descendant(
            of: find.ancestor(of: form, matching: find.byType(Column)).first,
            matching: find.byType(FilledButton),
          );
          // Stepper controls are siblings of the Form, in its enclosing Column.
          await Scrollable.ensureVisible(
            tester.element(button.first),
            alignment: 0.8,
          );
          await tester.pumpAndSettle();
          final position = Scrollable.of(tester.element(form)).position;
          if (current.steps[current.currentStep].content.key !=
                  current.steps[0].content.key ||
              next) {
            expect(position.maxScrollExtent, greaterThan(0));
          }
          if (next) {
            current.onStepContinue!();
          } else {
            current.onStepCancel!();
          }
          await tester.pumpAndSettle();
          final changed = tester.widget<Stepper>(find.byType(Stepper));
          expect(changed.currentStep, current.currentStep + (next ? 1 : -1));
          final start = tester
              .getTopLeft(
                find.byKey(changed.steps[changed.currentStep].content.key!),
              )
              .dy;
          final viewport = tester.getRect(find.byType(Stepper));
          expect(start, greaterThanOrEqualTo(viewport.top - 1));
          expect(start, lessThanOrEqualTo(viewport.top + 24));
          expect(tester.takeException(), isNull);
        }

        await control(true);
        if (editing) {
          await control(true);
          await control(true);
        }
        while (tester.widget<Stepper>(find.byType(Stepper)).currentStep > 0) {
          await control(false);
        }
      });
    }
  }
  for (final locale in [const Locale('fr'), const Locale('en')]) {
    for (final mode in VehicleFormMode.values) {
      testWidgets('blocked next explains every current error: $locale $mode', (
        tester,
      ) async {
        final depot = _Depot();
        await _ouvrir(tester, depot, null, locale: locale, mode: mode);
        final l10n = await AppLocalizations.delegate.load(locale);
        _ecrire(tester, l10n.vehiclesVinOptional, 'SHORT');
        final next = find.widgetWithText(FilledButton, l10n.vehiclesNext).first;
        await Scrollable.ensureVisible(tester.element(next), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 0);
        final snack = find.byType(SnackBar);
        for (final reason in [
          l10n.vehiclesBodyStyleRequired,
          l10n.vehiclesVinLengthError,
        ]) {
          expect(
            find.descendant(of: snack, matching: find.textContaining(reason)),
            findsOneWidget,
          );
        }
        expect(depot.charge, isNull);
        // The feedback is ephemeral; the field errors remain available.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byWidgetPredicate(
                (w) =>
                    w is DropdownButtonFormField<String> &&
                    w.decoration.labelText == l10n.vehiclesBodyStyleLabel,
                skipOffstage: false,
              ),
            )
            .onChanged!('sedan');
        _ecrire(tester, l10n.vehiclesVinOptional, '');
        await tester.pumpAndSettle();
        await Scrollable.ensureVisible(tester.element(next), alignment: 0.5);
        await tester.pumpAndSettle();
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 1);
        expect(find.byType(SnackBar), findsNothing);
        // Empty later steps never block the preceding valid one.
        tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
        await tester.pumpAndSettle();
        expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 1);
        for (final reason in [
          l10n.vehiclesBrandRequired,
          l10n.vehiclesModelRequired,
          l10n.vehiclesYearRequired,
        ]) {
          expect(
            find.descendant(
              of: find.byType(SnackBar),
              matching: find.textContaining(reason),
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('correcting a field clears repeated stale feedback $locale', (
      tester,
    ) async {
      final depot = _Depot();
      await _ouvrir(tester, depot, _vehicule(), locale: locale);
      final l10n = await AppLocalizations.delegate.load(locale);
      _ecrire(tester, l10n.vehiclesVinOptional, 'SHORT');
      tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
      await tester.pumpAndSettle();
      // Retry while the previous snackbar is still reversing, not only after
      // its animation has settled. Each retry must replace the whole queue.
      for (var attempt = 0; attempt < 3; attempt++) {
        tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.byType(SnackBar), findsOneWidget);
      _ecrire(tester, l10n.vehiclesVinOptional, '');
      tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
      await tester.pumpAndSettle();
      expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 1);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('final validation explains an earlier invalid field $locale', (
      tester,
    ) async {
      final depot = _Depot();
      await _ouvrir(tester, depot, _vehicule(), locale: locale);
      final l10n = await AppLocalizations.delegate.load(locale);
      for (var step = 0; step < 3; step++) {
        tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
        await tester.pumpAndSettle();
      }
      _ecrire(tester, l10n.vehiclesVinOptional, 'SHORT');
      tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
      await tester.pumpAndSettle();
      expect(tester.widget<Stepper>(find.byType(Stepper)).currentStep, 0);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining(l10n.vehiclesVinLengthError),
        ),
        findsOneWidget,
      );
      expect(depot.charge, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  // ── LES DEUX RÈGLES QUI NE PROTÉGEAIENT RIEN ────────────────────────────

  /// LE BANC QUI COMPTE LE PLUS.
  ///
  /// Sans carrosserie, le véhicule prend le défaut de la colonne et le filtre
  /// public `?body_style=` ne le trouve jamais. L'astérisque du libellé était
  /// une promesse que rien ne tenait.
  testWidgets('sans carrosserie, rien ne part', (tester) async {
    final depot = _Depot();
    await _ouvrir(
      tester,
      depot,
      _vehicule(
        retouche: (json) {
          json['body_style'] = null;

          return json;
        },
      ),
    );

    await _enregistrer(tester);

    expect(
      depot.charge,
      isNull,
      reason:
          'Un vehicule sans carrosserie est introuvable par le filtre '
          'public, ou range sous une carrosserie que personne n a choisie.',
    );
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
    expect(
      find.text('Le VIN doit faire exactement 17 caractères.'),
      findsOneWidget,
    );
  });

  testWidgets('un VIN vide reste accepté', (tester) async {
    final depot = _Depot();
    await _ouvrir(tester, depot, _vehicule());

    _ecrire(tester, 'VIN (optionnel)', '');

    await _enregistrer(tester);

    expect(
      depot.charge,
      isNotNull,
      reason: 'Le VIN est facultatif : on ne l a pas toujours sous la main.',
    );
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
    expect(find.textContaining('Année invalide'), findsNWidgets(2));
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
    await _ouvrir(
      tester,
      depot,
      _vehicule(
        retouche: (json) {
          json['body_style'] = null;

          return json;
        },
      ),
    );

    tester.widget<Stepper>(find.byType(Stepper)).onStepContinue!();
    await tester.pumpAndSettle();

    expect(
      tester.widget<Stepper>(find.byType(Stepper)).currentStep,
      0,
      reason:
          'Laisser avancer ferait decouvrir la faute trois etapes plus '
          'loin, apres tout le reste de la saisie.',
    );
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

    expect(
      depot.charge,
      isNull,
      reason:
          'Une etape anterieure fautive doit arreter l enregistrement, '
          'meme si ce n est pas celle qu on regarde.',
    );
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
