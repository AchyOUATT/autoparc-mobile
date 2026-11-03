import '../../l10n/app_localizations.dart';
import '../../features/vehicles/data/models/catalog_refs.dart';

/// Presentation-only labels for the controlled vehicle references.
/// Unknown/custom references retain the exact server text. Stored values and IDs
/// always remain unchanged; brand, model, generation and trim names are not translated.
String referenceFuelLabel(String? code, String fallback, AppLocalizations l10n) =>
    l10n.localeName.startsWith('fr') ? fallback : switch (code ?? const {'Essence':'petrol', 'Diesel':'diesel', 'Électrique':'electric', 'Hybride':'hybrid'}[fallback]) {
    'petrol' => l10n.vehiclesReferenceFuelPetrol,
    'diesel' => l10n.vehiclesReferenceFuelDiesel,
    'electric' => l10n.vehiclesReferenceFuelElectric,
    'hybrid' => l10n.vehiclesReferenceFuelHybrid,
      _ => fallback,
    };

String referenceDrivetrainLabel(String? code, String fallback, AppLocalizations l10n) =>
    switch (code ?? const {
      'FWD': 'FWD',
      'RWD': 'RWD',
      'AWD': 'AWD',
      '4WD': '4WD',
      'Traction avant': 'FWD',
      'Propulsion arrière': 'RWD',
      'Transmission intégrale permanente': 'AWD',
      'Transmission intégrale (AWD)': 'AWD',
      'All-wheel drive (AWD)': 'AWD',
      '4x4 débrayable': '4WD',
      'Quatre roues motrices (4WD)': '4WD',
      'Four-wheel drive (4WD)': '4WD',
    }[fallback]) {
    'FWD' => l10n.vehiclesReferenceDriveFrontWheel,
    'RWD' => l10n.vehiclesReferenceDriveRearWheel,
    'AWD' => l10n.vehiclesReferenceDriveAllWheel,
    '4WD' => l10n.vehiclesReferenceDriveFourWheel,
      _ => fallback,
    };

/// Colours do not have a stable code in the API. Match only exact seeded names.
String referenceColourLabel(String name, AppLocalizations l10n) => switch (name) {
    'Blanc' => l10n.vehiclesReferenceColourWhite,
    'Blanc nacré' => l10n.vehiclesReferenceColourPearlWhite,
    'Gris clair' => l10n.vehiclesReferenceColourLightGrey,
    'Gris anthracite' => l10n.vehiclesReferenceColourAnthraciteGrey,
    'Gris titanium' => l10n.vehiclesReferenceColourTitaniumGrey,
    'Argent' => l10n.vehiclesReferenceColourSilver,
    'Noir' => l10n.vehiclesReferenceColourBlack,
    'Noir métallisé' => l10n.vehiclesReferenceColourMetallicBlack,
    'Rouge' => l10n.vehiclesReferenceColourRed,
    'Rouge métallisé' => l10n.vehiclesReferenceColourMetallicRed,
    'Bordeaux' => l10n.vehiclesReferenceColourBurgundy,
    'Bleu marine' => l10n.vehiclesReferenceColourNavyBlue,
    'Bleu métallisé' => l10n.vehiclesReferenceColourMetallicBlue,
    'Bleu ciel' => l10n.vehiclesReferenceColourSkyBlue,
    'Vert foncé' => l10n.vehiclesReferenceColourDarkGreen,
    'Vert olive' => l10n.vehiclesReferenceColourOliveGreen,
    'Beige' => l10n.vehiclesReferenceColourBeige,
    'Marron' => l10n.vehiclesReferenceColourBrown,
    'Or / Champagne' => l10n.vehiclesReferenceColourGoldChampagne,
    'Orange' => l10n.vehiclesReferenceColourOrange,
    'Jaune' => l10n.vehiclesReferenceColourYellow,
    'Violet' => l10n.vehiclesReferenceColourPurple,
      _ => name,
    };

/// English country names cover CountriesSeeder's ISO2 list (Node Intl/CLDR).
/// French and unrecognised ISO2 values keep the reference's server-provided name.
String referenceCountryLabel(String? iso2, String fallback, AppLocalizations l10n) {
  if (l10n.localeName.startsWith('fr')) return fallback;
  return switch (iso2?.toUpperCase()) {
    'BF' => l10n.vehiclesReferenceCountryBf,
    'CI' => l10n.vehiclesReferenceCountryCi,
    'SN' => l10n.vehiclesReferenceCountrySn,
    'ML' => l10n.vehiclesReferenceCountryMl,
    'NE' => l10n.vehiclesReferenceCountryNe,
    'TG' => l10n.vehiclesReferenceCountryTg,
    'BJ' => l10n.vehiclesReferenceCountryBj,
    'GW' => l10n.vehiclesReferenceCountryGw,
    'GN' => l10n.vehiclesReferenceCountryGn,
    'GH' => l10n.vehiclesReferenceCountryGh,
    'NG' => l10n.vehiclesReferenceCountryNg,
    'LR' => l10n.vehiclesReferenceCountryLr,
    'SL' => l10n.vehiclesReferenceCountrySl,
    'GM' => l10n.vehiclesReferenceCountryGm,
    'CV' => l10n.vehiclesReferenceCountryCv,
    'MR' => l10n.vehiclesReferenceCountryMr,
    'CM' => l10n.vehiclesReferenceCountryCm,
    'CF' => l10n.vehiclesReferenceCountryCf,
    'TD' => l10n.vehiclesReferenceCountryTd,
    'CG' => l10n.vehiclesReferenceCountryCg,
    'GA' => l10n.vehiclesReferenceCountryGa,
    'GQ' => l10n.vehiclesReferenceCountryGq,
    'CD' => l10n.vehiclesReferenceCountryCd,
    'ET' => l10n.vehiclesReferenceCountryEt,
    'KE' => l10n.vehiclesReferenceCountryKe,
    'TZ' => l10n.vehiclesReferenceCountryTz,
    'UG' => l10n.vehiclesReferenceCountryUg,
    'RW' => l10n.vehiclesReferenceCountryRw,
    'ZA' => l10n.vehiclesReferenceCountryZa,
    'AO' => l10n.vehiclesReferenceCountryAo,
    'MZ' => l10n.vehiclesReferenceCountryMz,
    'MA' => l10n.vehiclesReferenceCountryMa,
    'DZ' => l10n.vehiclesReferenceCountryDz,
    'TN' => l10n.vehiclesReferenceCountryTn,
    'EG' => l10n.vehiclesReferenceCountryEg,
    'LY' => l10n.vehiclesReferenceCountryLy,
    'JP' => l10n.vehiclesReferenceCountryJp,
    'KR' => l10n.vehiclesReferenceCountryKr,
    'DE' => l10n.vehiclesReferenceCountryDe,
    'FR' => l10n.vehiclesReferenceCountryFr,
    'GB' => l10n.vehiclesReferenceCountryGb,
    'NL' => l10n.vehiclesReferenceCountryNl,
    'BE' => l10n.vehiclesReferenceCountryBe,
    'IT' => l10n.vehiclesReferenceCountryIt,
    'ES' => l10n.vehiclesReferenceCountryEs,
    'SE' => l10n.vehiclesReferenceCountrySe,
    'CN' => l10n.vehiclesReferenceCountryCn,
    'IN' => l10n.vehiclesReferenceCountryIn,
    'US' => l10n.vehiclesReferenceCountryUs,
    'CA' => l10n.vehiclesReferenceCountryCa,
    'AU' => l10n.vehiclesReferenceCountryAu,
    'BR' => l10n.vehiclesReferenceCountryBr,
    'MX' => l10n.vehiclesReferenceCountryMx,
    'TR' => l10n.vehiclesReferenceCountryTr,
    'AE' => l10n.vehiclesReferenceCountryAe,
    'SA' => l10n.vehiclesReferenceCountrySa,
    'PK' => l10n.vehiclesReferenceCountryPk,
    'ID' => l10n.vehiclesReferenceCountryId,
    'TH' => l10n.vehiclesReferenceCountryTh,
    'MY' => l10n.vehiclesReferenceCountryMy,
    'SG' => l10n.vehiclesReferenceCountrySg,
    'ZW' => l10n.vehiclesReferenceCountryZw,
    'LB' => l10n.vehiclesReferenceCountryLb,
    'PT' => l10n.vehiclesReferenceCountryPt,
    'CH' => l10n.vehiclesReferenceCountryCh,
    'AT' => l10n.vehiclesReferenceCountryAt,
    'PL' => l10n.vehiclesReferenceCountryPl,
      _ => fallback,
    };
}

String? referenceModelYears(ModelRef model, AppLocalizations l10n) {
  final start = model.productionStart;
  if (start == null) return null;
  return model.productionEnd == null
      ? l10n.garageModelSinceYear(start.toString())
      : '$start–${model.productionEnd}';
}

String referenceModelDisplayName(ModelRef model, AppLocalizations l10n) {
  final years = referenceModelYears(model, l10n);
  final details = [if (model.generation != null) model.generation!, if (years != null) years];
  return details.isEmpty ? model.name : '${model.name} (${details.join(', ')})';
}
