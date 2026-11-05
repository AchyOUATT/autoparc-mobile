import 'package:auto/core/l10n/reference_labels.dart';
import 'package:auto/features/catalog/presentation/widgets/fitments_section.dart';
import 'package:auto/features/garage/presentation/garage_labels.dart';
import 'package:auto/features/vehicles/data/models/catalog_refs.dart';
import 'package:auto/features/vehicles/presentation/widgets/vehicle_reference_dropdown.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _model({Object? aliases}) => {
  'id': 81,
  'brand_id': 12,
  'name': 'Cerato',
  'generation': 'BD',
  'production_start': 2018,
  'aliases': ?aliases,
};

void main() {
  test(
    'old API responses and malformed optional aliases keep the original name',
    () {
      for (final value in [null, 'Forte', 3, <Object?>[]]) {
        final model = ModelRef.fromJson(_model(aliases: value));
        expect(model.aliases, isEmpty);
        expect(model.commercialName, 'Cerato');
        expect(model.displayName, 'Cerato (BD, depuis 2018)');
      }
    },
  );

  test(
    'aliases are normalized without replacing identity or technical data',
    () {
      final model = ModelRef.fromJson(
        _model(
          aliases: [
            ' Forte ',
            'forte',
            '',
            '  ',
            ' CERATO ',
            null,
            42,
            'Regional name',
          ],
        ),
      );
      expect(model.aliases, ['Forte', 'Regional name']);
      expect(model.name, 'Cerato');
      expect(model.id, 81);
      expect(model.brandId, 12);
      expect(model.generation, 'BD');
      expect(model.commercialName, 'Cerato / Forte / Regional name');
      expect(model.defaultTransmission, isNull);
      expect(model.defaultPowerHp, isNull);
      expect(() => model.aliases.add('extra'), throwsUnsupportedError);
    },
  );

  for (final language in ['fr', 'en']) {
    test(
      'reference, garage and fitment labels show market names in $language',
      () async {
        final l10n = await AppLocalizations.delegate.load(Locale(language));
        final model = ModelRef.fromJson(_model(aliases: ['Forte']));
        final expected =
            'Cerato / Forte (BD, ${language == 'fr' ? 'depuis' : 'since'} 2018)';
        expect(referenceModelDisplayName(model, l10n), expected);
        expect(garageModelDisplayName(l10n, model), expected);
        final fitment = FitmentEntry.saisie(
          brand: const BrandRef(id: 12, name: 'Kia', isActive: true),
          model: model,
        );
        expect(fitment.labelDans(l10n), contains(expected));
      },
    );

    testWidgets(
      'selecting the regional name returns the original model ID in $language',
      (tester) async {
        final model = ModelRef.fromJson(_model(aliases: ['Forte']));
        ModelRef? selected;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return VehicleReferenceDropdown<ModelRef>(
                    label: 'Model',
                    items: [model],
                    value: null,
                    itemLabel: (m) => referenceModelDisplayName(m, l10n),
                    onChanged: (m) => selected = m,
                  );
                },
              ),
            ),
          ),
        );
        await tester.tap(find.byType(DropdownButtonFormField<ModelRef>));
        await tester.pumpAndSettle();
        final option = find.textContaining('Cerato / Forte');
        expect(option, findsWidgets);
        await tester.tap(option.last);
        await tester.pumpAndSettle();
        expect(selected, same(model));
        expect(selected!.id, 81);
        expect(selected!.name, 'Cerato');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
