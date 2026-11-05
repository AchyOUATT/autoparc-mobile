import 'package:flutter/material.dart';

import '../../../../core/l10n/consumption_labels.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/consumption_recommendation_selection.dart';
import '../../data/models/motorisation.dart';
import '../garage_labels.dart';
import 'consumption_reference_details.dart';

/// Null [onSelect] is read-only: opening a source never changes the vehicle.
class ConsumptionRecommendationCard extends StatelessWidget {
  const ConsumptionRecommendationCard({
    super.key,
    required this.candidate,
    required this.vehicleYear,
    this.selected = false,
    this.onSelect,
  });

  final Motorisation candidate;
  final int? vehicleYear;
  final bool selected;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reference = candidate.consumption;
    final eligible = consumptionCandidateEligible(candidate);
    final onTap = onSelect == null
        ? () => showConsumptionReferenceDetails(
            context,
            reference,
            vehicleYear: vehicleYear,
          )
        : eligible
        ? onSelect
        : null;
    final color = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall;
    final value = reference.sourceCombinedL100km;
    final matching = _criteria(candidate.matchedCriteria, l10n);
    final missing = _criteria(candidate.missingCriteria, l10n);
    final conflicts = _criteria(candidate.conflictingCriteria, l10n);

    return Card(
      key: ValueKey('consumption-recommendation-option-${candidate.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        button: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selected)
                  Text(
                    l10n.garageConsumptionRecommendationCurrent,
                    style: style?.copyWith(color: color.primary),
                  ),
                if (reference.sourceModel?.isNotEmpty == true)
                  Text(
                    reference.sourceModel!,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                Text(
                  consumptionEngineLabel(
                    candidate.label,
                    l10n,
                    engineL: candidate.engineL,
                    cylinders: candidate.cylinders,
                    transmissionCode: candidate.transmissionCode,
                  ),
                ),
                if (value != null)
                  Text(
                    l10n.garageConsumptionSourceValue(
                      garageDecimal(l10n, value),
                    ),
                  ),
                if (reference.powerKw != null)
                  Text(
                    '${garageDecimal(l10n, reference.powerKw!)} kW',
                    style: style,
                  ),
                if (candidate.fuel != null)
                  Text(
                    consumptionFuelLabel(
                      candidate.fuel!,
                      l10n,
                      code: candidate.fuelCode,
                    ),
                    style: style,
                  ),
                Text(consumptionMatchLabel(l10n, reference), style: style),
                if (!candidate.recommendationEligible)
                  Text(
                    conflicts.isEmpty
                        ? l10n.garageConsumptionRecommendationConflictGeneric
                        : l10n.garageConsumptionRecommendationConflict(
                            conflicts,
                          ),
                    style: style?.copyWith(color: color.error),
                  ),
                if (eligible && matching.isNotEmpty)
                  Text(
                    l10n.garageConsumptionRecommendationBasedOn(matching),
                    style: style,
                  ),
                if (missing.isNotEmpty)
                  Text(
                    l10n.garageConsumptionRecommendationMissing(missing),
                    style: style,
                  ),
                Text(consumptionYearLabel(l10n, reference), style: style),
                Text(
                  reference.market?.trim().isNotEmpty == true
                      ? l10n.garageConsumptionMarket(reference.market!)
                      : l10n.garageConsumptionMarketUnknown,
                  style: style,
                ),
                if (reference.source.isNotEmpty)
                  Text(
                    l10n.garageConsumptionSource(
                      consumptionSourceLabel(
                        reference.source,
                        l10n,
                        code: reference.sourceCode,
                      ),
                    ),
                    style: style,
                  ),
                if (reference.cycle.isNotEmpty)
                  Text(
                    l10n.garageConsumptionProtocol(
                      consumptionCycleLabel(
                        reference.cycle,
                        l10n,
                        code: reference.cycleCode,
                      ),
                    ),
                    style: style,
                  ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: IconButton(
                    key: ValueKey(
                      'consumption-recommendation-details-${candidate.id}',
                    ),
                    tooltip: l10n.garageConsumptionDetails,
                    onPressed: () => showConsumptionReferenceDetails(
                      context,
                      reference,
                      vehicleYear: vehicleYear,
                    ),
                    icon: const Icon(Icons.info_outline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _criteria(List<String> values, AppLocalizations l10n) => values
    .map(
      (value) => switch (value) {
        'engine_code' => l10n.garageConsumptionRecommendationEngineCode,
        'engine_l' ||
        'engine_displacement_l' ||
        'engine_displacement_cc' ||
        'displacement' => l10n.garageConsumptionRecommendationDisplacement,
        'cylinders' => l10n.garageConsumptionRecommendationCylinders,
        'power_kw' ||
        'power_hp' ||
        'power' => l10n.garageConsumptionRecommendationPower,
        'fuel' ||
        'fuel_code' ||
        'engine_type' ||
        'engine_type_id' ||
        'fuel_type' => l10n.garageConsumptionRecommendationFuel,
        'drivetrain' ||
        'drivetrain_id' => l10n.garageConsumptionRecommendationDrive,
        'trim' || 'trim_id' => l10n.garageConsumptionRecommendationTrim,
        'model_year' => l10n.garageConsumptionRecommendationModelYear,
        'market' ||
        'specification_market' => l10n.garageConsumptionRecommendationMarket,
        'transmission' ||
        'transmission_code' => l10n.garageConsumptionRecommendationTransmission,
        _ => l10n.garageConsumptionRecommendationVersion,
      },
    )
    .toSet()
    .join(', ');
