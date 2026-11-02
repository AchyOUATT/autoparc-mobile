import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import 'reference_labels.dart';

/// Official-consumption reference values are controlled by Motorisation.php.
/// Prefer their stable codes; exact legacy labels support older API payloads.
/// Unknown source, fuel and cycle values keep their server text.
String consumptionSourceLabel(
  String fallback,
  AppLocalizations l10n, {
  String? code,
}) {
  if (l10n.localeName.startsWith('fr')) return fallback;
  return switch (code ??
      const {
        'Ressources naturelles Canada': 'nrcan',
        "Agence europeenne pour l'environnement": 'eea',
      }[fallback]) {
    'nrcan' => l10n.garageConsumptionSourceCanada,
    'eea' => l10n.garageConsumptionSourceEurope,
    _ => fallback,
  };
}

String consumptionCycleLabel(
  String fallback,
  AppLocalizations l10n, {
  String? code,
}) {
  if (code == '5-cycle' ||
      (code == null && fallback == 'essai canadien, cinq cycles')) {
    return l10n.garageConsumptionCycleCanadianFive;
  }
  if (l10n.localeName.startsWith('fr')) return fallback;
  return switch (code ??
      const {
        'essai canadien, cinq cycles': '5-cycle',
        'essai canadien, deux cycles': '2-cycle',
        'norme WLTP': 'wltp',
        'ancienne norme NEDC': 'nedc',
      }[fallback]) {
    '5-cycle' => l10n.garageConsumptionCycleCanadianFive,
    '2-cycle' => l10n.garageConsumptionCycleCanadianTwo,
    'wltp' => l10n.garageConsumptionCycleWltp,
    'nedc' => l10n.garageConsumptionCycleNedc,
    _ => fallback,
  };
}

String consumptionFuelLabel(
  String fallback,
  AppLocalizations l10n, {
  String? code,
}) {
  if (code == 'H') return l10n.garageConsumptionFuelHybridUnspecified;
  if (l10n.localeName.startsWith('fr')) return fallback;
  return switch (code ??
      const {
        'Essence ordinaire': 'X',
        'Essence super': 'Z',
        'Diesel': 'D',
        'Ethanol (E85)': 'E',
        'Gaz naturel': 'N',
        'GPL': 'L',
        'Electrique': 'B',
        'Hybride rechargeable': 'phev',
        'Hybride (type à préciser)': 'H',
        'Hybride': 'H',
      }[fallback]) {
    'X' => l10n.garageConsumptionFuelRegularPetrol,
    'Z' => l10n.garageConsumptionFuelPremiumPetrol,
    'D' => referenceFuelLabel('diesel', fallback, l10n),
    'E' => l10n.garageConsumptionFuelEthanol,
    'N' => l10n.garageConsumptionFuelNaturalGas,
    'L' => l10n.garageConsumptionFuelLpg,
    'B' => referenceFuelLabel('electric', fallback, l10n),
    'H' => l10n.garageConsumptionFuelHybridUnspecified,
    'phev' => l10n.garageConsumptionFuelPlugInHybrid,
    _ => referenceFuelLabel(code, fallback, l10n),
  };
}

String consumptionRange(double min, double max, AppLocalizations l10n) {
  final number = NumberFormat('0.0', l10n.localeName);
  return (max - min).abs() < 0.05
      ? l10n.catalogUnitConsumption(number.format(min))
      : l10n.garageConsumptionRange(number.format(min), number.format(max));
}

/// Rebuild only known generated engine labels; custom/unknown labels are intact.
String consumptionEngineLabel(
  String fallback,
  AppLocalizations l10n, {
  double? engineL,
  int? cylinders,
  String? transmissionCode,
}) {
  if (l10n.localeName.startsWith('fr')) return fallback;

  var code = transmissionCode;
  if (code == null) {
    // This is Motorisation::getLibelleAttribute's complete legacy grammar,
    // rather than replacements within arbitrary names or user descriptions.
    final legacy = RegExp(
      r'^(?:(\d+[,.]\d+) l ?)?(?:(\d+) cyl\. ?)?(?:(boîte à variation continue|boîte auto\.|boîte robotisée|boîte manuelle)(?: (\d+))?)?$',
    ).firstMatch(fallback);
    if (legacy == null || fallback.isEmpty) return fallback;
    engineL = legacy.group(1) == null
        ? null
        : double.tryParse(legacy.group(1)!.replaceAll(',', '.'));
    cylinders = int.tryParse(legacy.group(2) ?? '');
    final family = switch (legacy.group(3)) {
      'boîte à variation continue' => 'AV',
      'boîte auto.' => 'A',
      'boîte robotisée' => 'AM',
      'boîte manuelle' => 'M',
      _ => '',
    };
    code = '$family${legacy.group(4) ?? ''}';
  }

  final transmission = RegExp(r'^(AV|AS|AM|A|M)(\d+)?$').firstMatch(code);
  if (transmission == null && code.isNotEmpty) return fallback;
  final parts = <String>[
    if (engineL != null)
      '${NumberFormat('0.0', l10n.localeName).format(engineL)} L',
    if (cylinders != null) '$cylinders cyl.',
  ];
  if (transmission != null) {
    final name = switch (transmission.group(1)) {
      'AV' => l10n.garageEngineCvt,
      'AM' => l10n.garageEngineAutomatedManual,
      'M' => l10n.garageEngineManual,
      _ => l10n.garageEngineAutomatic,
    };
    final gears = int.tryParse(transmission.group(2) ?? '');
    parts.add(
      gears == null ? name : l10n.garageEngineTransmissionGears(name, gears),
    );
  }
  return parts.isEmpty ? fallback : parts.join(' ');
}
