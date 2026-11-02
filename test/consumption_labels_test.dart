import 'package:auto/core/l10n/consumption_labels.dart';
import 'package:auto/l10n/app_localizations_en.dart';
import 'package:auto/l10n/app_localizations_fr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an ambiguous H code never claims that the hybrid is rechargeable', () {
    final fr = AppLocalizationsFr();
    final en = AppLocalizationsEn();
    expect(
      consumptionFuelLabel('Hybride rechargeable', fr, code: 'H'),
      fr.garageConsumptionFuelHybridUnspecified,
    );
    expect(
      consumptionFuelLabel('Hybride (type à préciser)', en, code: 'H'),
      en.garageConsumptionFuelHybridUnspecified,
    );
    expect(
      consumptionFuelLabel('Hybride rechargeable', en),
      en.garageConsumptionFuelPlugInHybrid,
      reason:
          'An explicit legacy label remains readable without inferring it from H.',
    );
  });

  test(
    'the five-cycle protocol does not claim a new test for adjusted ratings',
    () {
      for (final locale in [AppLocalizationsFr(), AppLocalizationsEn()]) {
        final label = consumptionCycleLabel(
          'essai canadien, cinq cycles',
          locale,
          code: '5-cycle',
        );
        expect(label, locale.garageConsumptionCycleCanadianFive);
        expect(label.toLowerCase(), isNot(contains('test')));
        expect(label.toLowerCase(), isNot(contains('essai')));
        expect(
          consumptionCycleLabel('essai canadien, cinq cycles', locale),
          label,
        );
      }
    },
  );
}
