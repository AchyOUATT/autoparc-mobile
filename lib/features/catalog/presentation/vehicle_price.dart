import '../../../core/utils/currency_format.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/vehicle.dart';

/// Rates retain their own period; no daily/monthly conversion is inferred.
List<String> vehicleRentalPriceLabels(
  VehicleCommercial commercial,
  AppLocalizations l10n,
) => !commercial.isForRent ? const [] : [
  if (commercial.rentalDailyRate != null)
    '${formatXofShort(commercial.rentalDailyRate)}${l10n.commonPerDaySuffix}',
  if (commercial.rentalMonthlyRate != null)
    '${formatXofShort(commercial.rentalMonthlyRate)}${l10n.commonPerMonthSuffix}',
];

String? vehicleHeadlinePrice(
  VehicleCommercial commercial,
  AppLocalizations l10n,
) {
  if (commercial.isForSale && commercial.salePrice != null) {
    return formatXofShort(commercial.salePrice);
  }

  return vehicleRentalPriceLabels(commercial, l10n).firstOrNull;
}
