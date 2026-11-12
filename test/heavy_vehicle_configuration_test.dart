import 'package:auto/features/vehicles/data/models/heavy_vehicle_configuration.dart';
import 'package:auto/features/vehicles/presentation/widgets/heavy_vehicle_configuration.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child, {String language = 'fr', double textScale = 1}) =>
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

const configuration = HeavyVehicleConfiguration(
  versionLabel: '460',
  cabLabel: 'Cabine haute',
  axleConfiguration: '6x2/4',
  chassisType: 'tractor',
  bodyUse: 'Transport longue distance',
  emissionStandard: 'Euro VI',
  ptacKg: 26000,
  ptraKg: 44000,
);

void main() {
  test('declared values round-trip without decoding commercial labels', () {
    final c = HeavyVehicleConfigurationController(value: configuration);
    addTearDown(c.dispose);
    expect(c.toValue().toJson(), configuration.toJson());
    c.version.text = '  460  ';
    c.axles.text = '  6x2*4  ';
    expect(c.toValue().versionLabel, '460');
    expect(c.toValue().axleConfiguration, '6x2*4');
    c.axles.text = '6x2/4';
    expect(c.toValue().axleConfiguration, '6x2/4');
    c.ptac.clear();
    c.ptra.clear();
    expect(c.toValue().ptacKg, isNull);
    expect(c.toValue().ptraKg, isNull);
    // A commercial number never supplies an undeclared mass or engine power.
    expect(c.toValue().toJson(), isNot(contains('power_hp')));
    for (final controller in [
      c.version,
      c.cab,
      c.axles,
      c.bodyUse,
      c.emission,
      c.usefulVolume,
      c.tankCapacity,
      c.payload,
    ]) {
      controller.text = '  ';
    }
    c.chassisType = null;
    c.bodyType = null;
    expect(c.toValue().isEmpty, isTrue);
  });

  testWidgets(
    'blank fields are optional; mass bounds and relation are checked',
    (tester) async {
      final c = HeavyVehicleConfigurationController();
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        app(
          Form(
            key: form,
            child: HeavyVehicleConfigurationFields(controller: c),
          ),
        ),
      );
      expect(form.currentState!.validate(), isTrue);
      expect(c.toValue().isEmpty, isTrue);

      for (final controller in [c.ptac, c.ptra]) {
        for (final invalid in ['0', '-1', '1.5', '1,5', '1000001', 'twenty']) {
          controller.text = invalid;
          expect(form.currentState!.validate(), isFalse, reason: invalid);
        }
        controller.text = '1000000';
        expect(form.currentState!.validate(), isTrue);
        controller.clear();
      }

      c.ptac.text = '26000';
      c.ptra.text = '25999';
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(
        find.text('Le PTRA doit être supérieur ou égal au PTAC.'),
        findsOneWidget,
      );
      c.ptra.text = '26000';
      expect(form.currentState!.validate(), isTrue);
      c.ptra.text = '44000';
      expect(form.currentState!.validate(), isTrue);
      c.ptra.clear();
      expect(form.currentState!.validate(), isTrue);
      c.ptac.clear();
      c.ptra.text = '44000';
      expect(form.currentState!.validate(), isTrue);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'declared labels have bounded lengths and chassis can be cleared',
    (tester) async {
      final c = HeavyVehicleConfigurationController(value: configuration);
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        app(
          Form(
            key: form,
            child: HeavyVehicleConfigurationFields(controller: c),
          ),
        ),
      );
      for (final (controller, max) in [
        (c.version, 100),
        (c.cab, 100),
        (c.axles, 40),
        (c.bodyUse, 100),
        (c.emission, 40),
      ]) {
        controller.text = 'a' * (max + 1);
        expect(form.currentState!.validate(), isFalse);
        controller.text = 'a' * max;
        expect(form.currentState!.validate(), isTrue);
      }
      final chassis = find.byKey(const ValueKey('heavy-chassis'));
      await tester.ensureVisible(chassis);
      await tester.tap(chassis);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Non renseigné').last);
      await tester.pumpAndSettle();
      expect(c.chassisType, isNull);
      expect(c.toValue().chassisType, isNull);
      expect(form.currentState!.validate(), isTrue);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets('details show only known data and the declared status in FR/EN', (
    tester,
  ) async {
    for (final (language, declared, version, chassis) in [
      ('fr', 'Données déclarées', 'Version commerciale', 'Tracteur routier'),
      ('en', 'Owner-declared details', 'Commercial version', 'Tractor unit'),
    ]) {
      await tester.pumpWidget(
        app(
          const HeavyVehicleConfigurationDetails(configuration: configuration),
          language: language,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(declared), findsOneWidget);
      expect(find.text(version), findsOneWidget);
      expect(find.text(chassis), findsOneWidget);
      expect(find.text('6x2/4'), findsOneWidget);
      expect(find.text('Euro VI'), findsOneWidget);
      expect(find.textContaining('kg'), findsNWidgets(4));

      await tester.pumpWidget(
        app(
          const HeavyVehicleConfigurationDetails(
            configuration: HeavyVehicleConfiguration(versionLabel: '460'),
          ),
          language: language,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(declared), findsOneWidget);
      expect(find.text('460'), findsOneWidget);
      expect(find.text(chassis), findsNothing);
      expect(find.textContaining('kg'), findsNothing);

      await tester.pumpWidget(
        app(
          const HeavyVehicleConfigurationDetails(
            configuration: HeavyVehicleConfiguration(),
          ),
          language: language,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(declared), findsNothing);
      expect(find.byType(Text), findsNothing);
    }
  });

  for (final language in ['fr', 'en']) {
    testWidgets('fields and details fit at 320px with large text ($language)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = HeavyVehicleConfigurationController(value: configuration);
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        app(
          Form(
            key: form,
            child: HeavyVehicleConfigurationFields(controller: c),
          ),
          language: language,
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final chassis = find.byKey(const ValueKey('heavy-chassis'));
      await tester.ensureVisible(chassis);
      await tester.tap(chassis);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.text(language == 'fr' ? 'Porteur' : 'Rigid truck').last,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      c.ptra.text = '1';
      expect(form.currentState!.validate(), isFalse);
      await tester.ensureVisible(find.byKey(const ValueKey('heavy-ptra')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        app(
          const HeavyVehicleConfigurationDetails(configuration: configuration),
          language: language,
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('6x2/4'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    });
  }

  test('19,32 and 19.32 are the same useful volume, tank stays tanker-only', () {
    final c = HeavyVehicleConfigurationController();
    addTearDown(c.dispose);
    c.usefulVolume.text = '19,32';
    expect(c.toValue().usefulVolumeM3, 19.32);
    c.usefulVolume.text = '19.32';
    expect(c.toValue().usefulVolumeM3, 19.32);
    c.tankCapacity.text = '45000';
    c.bodyType = 'tipper';
    expect(c.toValue().tankCapacityLiters, isNull);
    c.bodyType = 'tanker';
    expect(c.toValue().tankCapacityLiters, 45000);
    expect(
      HeavyVehicleConfiguration.fromJson({
        'useful_volume_m3': '19.32',
        'payload_kg': 60000,
        'body_type': 'tipper',
      }).toJson(),
      containsPair('useful_volume_m3', 19.32),
    );
  });

  testWidgets('tank capacity is offered only for a tanker body', (tester) async {
    final c = HeavyVehicleConfigurationController();
    addTearDown(c.dispose);
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      app(Form(key: form, child: HeavyVehicleConfigurationFields(controller: c))),
    );
    expect(find.byKey(const ValueKey('heavy-tank-capacity')), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey('heavy-body-type')));
    await tester.tap(find.byKey(const ValueKey('heavy-body-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Citerne').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('heavy-tank-capacity')), findsOneWidget);

    c.tankCapacity.text = '45000';
    c.usefulVolume.text = '19,32';
    c.payload.text = '60000';
    expect(form.currentState!.validate(), isTrue);
    expect(c.toValue().bodyType, 'tanker');
    expect(c.toValue().usefulVolumeM3, 19.32);
    expect(c.toValue().tankCapacityLiters, 45000);
    expect(c.toValue().payloadKg, 60000);

    await tester.tap(find.byKey(const ValueKey('heavy-body-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Benne').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('heavy-tank-capacity')), findsNothing);
    expect(c.toValue().bodyType, 'tipper');
    expect(c.toValue().tankCapacityLiters, isNull);
  });
}
