import 'package:auto/core/utils/currency_format.dart';
import 'package:auto/features/catalog/data/models/vehicle.dart';
import 'package:auto/features/catalog/presentation/vehicle_price.dart';
import 'package:auto/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

VehicleCommercial offer({
  String availability = 'rent',
  double? sale,
  double? daily,
  double? monthly,
}) => VehicleCommercial(
  condition: 'used',
  status: 'in_stock',
  availability: availability,
  salePrice: sale,
  rentalDailyRate: daily,
  rentalMonthlyRate: monthly,
  currency: 'XOF',
  priceNegotiable: false,
);

void main() {
  setUp(() => definirLocaleMontants(const Locale('fr')));
  tearDown(() => definirLocaleMontants(const Locale('fr')));

  test('un forfait mensuel seul affiche son montant et son unité', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(
      vehicleHeadlinePrice(offer(monthly: 500000), l10n),
      '${formatXofShort(500000)}/mois',
    );
  });

  test('un tarif journalier seul conserve son unité', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(
      vehicleHeadlinePrice(offer(daily: 25000), l10n),
      '${formatXofShort(25000)}/j',
    );
  });

  test('les deux tarifs restent indépendants et le journalier porte la carte', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    final commercial = offer(daily: 25000, monthly: 500000);
    expect(vehicleRentalPriceLabels(commercial, l10n), [
      '${formatXofShort(25000)}/j',
      '${formatXofShort(500000)}/mois',
    ]);
    expect(vehicleHeadlinePrice(commercial, l10n), '${formatXofShort(25000)}/j');
  });

  test('une offre mixte garde la vente prioritaire et expose aussi ses tarifs locatifs', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    final commercial = offer(availability: 'both', sale: 8000000, monthly: 500000);
    expect(vehicleHeadlinePrice(commercial, l10n), formatXofShort(8000000));
    expect(vehicleRentalPriceLabels(commercial, l10n), ['${formatXofShort(500000)}/mois']);
  });

  test('un ancien prix de vente ne masque pas une location mensuelle', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(
      vehicleHeadlinePrice(offer(sale: 8000000, monthly: 500000), l10n),
      '${formatXofShort(500000)}/mois',
    );
    expect(vehicleRentalPriceLabels(offer(availability: 'sale', daily: 25000), l10n), isEmpty);
    expect(vehicleHeadlinePrice(offer(availability: 'sale', daily: 25000), l10n), isNull);
  });

  test('la période mensuelle est traduite en anglais', () async {
    definirLocaleMontants(const Locale('en'));
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      vehicleHeadlinePrice(offer(monthly: 500000), l10n),
      '${formatXofShort(500000)}/month',
    );
  });
}
