import '../../l10n/app_localizations.dart';

/// Gearbox families shared by stock, partner and private vehicle forms.
/// Wheel drive (FWD, RWD, AWD, 4WD) is a separate reference.
const transmissionCodes = [
  'manual',
  'automatic',
  'automated_manual',
  'dual_clutch',
  'cvt',
  'e_cvt',
  'single_speed',
];

/// The simple form choice preserves the stored gearbox family as a detail.
String? transmissionGroup(String? code) {
  if (code == 'manual') return 'manual';
  if (transmissionCodes.contains(code)) return 'automatic';
  return null;
}

String transmissionLabel(String code, AppLocalizations l10n) => switch (code) {
  'manual' => l10n.catalogTransmissionManual,
  'automatic' => l10n.catalogTransmissionAutomatic,
  'automated_manual' => l10n.catalogTransmissionAutomatedManual,
  'dual_clutch' => l10n.privateSalesTransmissionDualClutch,
  'cvt' => l10n.catalogTransmissionCvt,
  'e_cvt' => l10n.catalogTransmissionECvt,
  'single_speed' => l10n.privateSalesTransmissionSingleSpeed,
  // An unrecognised saved value must not turn into "automatic" on display.
  _ => code,
};
