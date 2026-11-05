import '../../../l10n/app_localizations.dart';
import '../data/models/owned_vehicle.dart';
import '../../vehicles/data/models/catalog_refs.dart';
import 'package:intl/intl.dart';

String garageDecimal(AppLocalizations l10n, num value, {int decimals = 1}) =>
    NumberFormat(
      decimals == 0 ? '0' : '0.${List.filled(decimals, '0').join()}',
      l10n.localeName,
    ).format(value);

String garageInteger(AppLocalizations l10n, num value) =>
    NumberFormat.decimalPattern(
      l10n.localeName,
    ).format(value.round()).replaceAll('\u202f', '\u00a0');

String garageDate(AppLocalizations l10n, DateTime value) =>
    DateFormat.yMMMd(l10n.localeName).format(value);

String? garageModelYears(AppLocalizations l10n, ModelRef model) {
  final start = model.productionStart;
  if (start == null) return null;
  return model.productionEnd == null
      ? l10n.garageModelSinceYear(start.toString())
      : '$start–${model.productionEnd}';
}

String garageModelDisplayName(AppLocalizations l10n, ModelRef model) {
  final details = [
    if (model.generation != null) model.generation!,
    if (garageModelYears(l10n, model) != null) garageModelYears(l10n, model)!,
  ];
  return details.isEmpty
      ? model.commercialName
      : '${model.commercialName} (${details.join(', ')})';
}

String? fuelExclusionLabel(AppLocalizations l10n, String? code) =>
    switch (code) {
      'trop_long' => l10n.garageRefillMissing,
      'invraisemblable' => l10n.garageRefillImplausible,
      'anormalement_bas' => l10n.garageRefillTooLow,
      _ => null,
    };

String garageDeadlineLabel(AppLocalizations l10n, VehicleDeadline deadline) =>
    switch (deadline.kind) {
      'technical_inspection' => l10n.garageInspectionLabel,
      'insurance' => l10n.garageInsuranceLabel,
      'service' => l10n.garageOilChangeLabel,
      _ => deadline.label,
    };

String garageDeadlineSummary(AppLocalizations l10n, VehicleDeadline deadline) {
  if (deadline.detail != null) return deadline.detail!;
  final days = deadline.daysLeft;
  if (days == null) return garageDeadlineLabel(l10n, deadline);
  if (deadline.overdue) return l10n.garageDeadlineOverdue(days.abs());
  if (days == 0) return l10n.garageDeadlineToday;
  return l10n.garageDeadlineInDays(days);
}
