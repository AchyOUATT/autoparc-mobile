import 'package:auto/features/garage/data/models/owned_vehicle.dart';
import 'package:auto/features/garage/presentation/providers/garage_provider.dart';
import 'package:auto/features/garage/presentation/widgets/engine_details.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const vehicle = OwnedVehicle(
  id: 1,
  designation: 'Toyota Corolla',
  brandId: 1,
  year: 2015,
  vehicleModelId: 2,
  identity: OwnedVehicleIdentity(),
  compatibilityReady: false,
  engineDisplacementL: 1.8,
  engineDisplacementCc: 1798,
  cylinders: 4,
  engineLayout: 'inline',
  powerHp: 140,
  engineCode: '2ZR-FE',
);

class SavingGarage extends GarageNotifier {
  Map<String, dynamic>? saved;
  @override
  Future<List<OwnedVehicle>> build() async => [vehicle];
  @override
  Future<String?> updateVehicle(int id, Map<String, dynamic> payload) async {
    saved = payload;
    return null;
  }
}

Widget app(Widget child, {String language = 'fr'}) => MaterialApp(
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('commercial litres do not invent exact cc and can be cleared', () {
    final c = EngineDetailsController();
    addTearDown(c.dispose);
    c.litres.text = '1,6';
    expect(c.toPayload()['engine_displacement_l'], 1.6);
    expect(c.toPayload()['engine_displacement_cc'], isNull);
    c.code.text = ' 2zr-fe ';
    expect(c.toPayload()['engine_code'], '2ZR-FE');
    c.litres.clear();
    c.code.clear();
    expect(c.toPayload().values, everyElement(isNull));
  });

  test('API details round-trip, legacy responses stay optional', () {
    final json = <String, dynamic>{
      'id': 1,
      'designation': 'Toyota',
      'brand_id': 1,
      'year': 2015,
      'identity': <String, dynamic>{},
      'compatibility_ready': false,
    };
    expect(OwnedVehicle.fromJson(json).engineDisplacementL, isNull);
    final parsed = OwnedVehicle.fromJson({
      ...json,
      'engine_displacement_l': '1.800',
      'engine_displacement_cc': 1798,
      'cylinders': 4,
      'engine_layout': 'inline',
      'power_hp': 140,
    });
    expect(parsed.engineDisplacementL, 1.8);
    expect(parsed.engineDisplacementCc, 1798);
    expect(parsed.cylinders, 4);
    expect(parsed.engineLayout, 'inline');
    expect(parsed.powerHp, 140);
    expect(parsed.compatibilityReady, isFalse);
  });

  testWidgets(
    'optional fields accept blanks and comma litres, reject invalid numbers',
    (tester) async {
      final c = EngineDetailsController();
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        app(
          Form(
            key: form,
            child: EngineDetailsFields(controller: c),
          ),
        ),
      );
      expect(form.currentState!.validate(), isTrue);
      await tester.enterText(
        find.byKey(const ValueKey('engine-litres')),
        '1,8',
      );
      expect(form.currentState!.validate(), isTrue);
      await tester.enterText(find.byKey(const ValueKey('engine-cc')), '1.8');
      expect(form.currentState!.validate(), isFalse);
      await tester.enterText(find.byKey(const ValueKey('engine-cc')), '1798');
      expect(form.currentState!.validate(), isTrue);
      await tester.enterText(
        find.byKey(const ValueKey('engine-cylinders')),
        '0',
      );
      expect(form.currentState!.validate(), isFalse);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('engine editor remains usable at 320px with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: EngineDetailsTile(vehicle: vehicle),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EngineDetailsTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('engine-power')));
    await tester.pumpAndSettle();
    expect(find.byType(FilledButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final lang in ['fr', 'en']) {
    testWidgets('edit existing details and explicitly clear them in $lang', (
      tester,
    ) async {
      final garage = SavingGarage();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [garageProvider.overrideWith(() => garage)],
          child: app(const EngineDetailsTile(vehicle: vehicle), language: lang),
        ),
      );
      await tester.tap(find.byType(EngineDetailsTile));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('engine-cc')))
            .controller!
            .text,
        '1798',
      );
      for (final key in [
        'engine-litres',
        'engine-cc',
        'engine-cylinders',
        'engine-code',
        'engine-power',
      ]) {
        final field = find.byKey(ValueKey(key));
        await tester.ensureVisible(field);
        await tester.enterText(field, '');
      }
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('engine-layout')),
      );
      dropdown.onChanged!(null);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(garage.saved, isNotNull);
      expect(garage.saved!.values, everyElement(isNull));
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
