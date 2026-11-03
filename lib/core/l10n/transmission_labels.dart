import '../../l10n/app_localizations.dart';

/// Stable gearbox codes accepted by the vehicle and private-listing APIs.
const vehicleTransmissionCodes = [
  'manual',
  'automatic',
  'cvt',
  'dual_clutch',
  'single_speed',
];

/// A gearbox keeps its technical identity in forms, summaries and details.
/// Unknown server values remain readable rather than becoming "automatic".
String transmissionLabel(String code, AppLocalizations l10n) => switch (code) {
  'manual' => l10n.catalogTransmissionManual,
  'automatic' => l10n.catalogTransmissionAutomatic,
  'cvt' => l10n.catalogTransmissionCvt,
  'dual_clutch' => l10n.privateSalesTransmissionDualClutch,
  'single_speed' => l10n.privateSalesTransmissionSingleSpeed,
  _ => code,
};
