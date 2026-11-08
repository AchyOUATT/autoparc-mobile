import '../../data/consumption_recommendation_selection.dart';
import 'consumption_recommendation_card.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/motorisation.dart';
import '../../data/models/owned_vehicle.dart';
import 'consumption_reference_details.dart';

/// Presents the server's closest group without manufacturing a probability.
/// Rank ties stay ties, and choosing a source remains an explicit action.
class ConsumptionRecommendationsDialog extends StatefulWidget {
  const ConsumptionRecommendationsDialog({
    super.key,
    required this.vehicle,
    required this.options,
    this.onRefine,
  });

  final OwnedVehicle vehicle;
  final List<Motorisation> options;
  final VoidCallback? onRefine;

  @override
  State<ConsumptionRecommendationsDialog> createState() =>
      _ConsumptionRecommendationsDialogState();
}

class _ConsumptionRecommendationsDialogState
    extends State<ConsumptionRecommendationsDialog> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selection = ConsumptionRecommendationSelection(widget.options);
    final eligible = selection.eligible;
    final closest = selection.closest;
    final hasEvidence = selection.hasEvidence;
    final shortlist = selection.shortlist;
    final shortlistIds = shortlist.map((candidate) => candidate.id).toSet();
    final current = widget.options
        .where((candidate) => candidate.id == widget.vehicle.motorisationId)
        .firstOrNull;
    final currentOutside =
        current != null && !shortlistIds.contains(current.id);
    final retainedReference = current == null
        ? widget.vehicle.consumption
        : null;
    final otherCandidates = widget.options
        .where(
          (candidate) =>
              !shortlistIds.contains(candidate.id) &&
              !(currentOutside && candidate.id == current.id),
        )
        .toList();
    final title = !hasEvidence
        ? l10n.garageConsumptionRecommendationNeedsDetails
        : closest.length == 1
        ? l10n.garageConsumptionRecommendationClosest
        : l10n.garageConsumptionRecommendationTied;

    return AlertDialog(
      scrollable: true,
      title: Text(
        l10n.garageConsumptionVersionTitle(
          widget.vehicle.identity.model ?? widget.vehicle.designation,
        ),
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              eligible.isEmpty
                  ? l10n.garageConsumptionRecommendationNoEligible
                  : !hasEvidence
                  ? l10n.garageConsumptionRecommendationProvisional
                  : l10n.garageConsumptionRecommendationNotice,
            ),
            if (hasEvidence && closest.length > 3) ...[
              const SizedBox(height: 8),
              Text(
                l10n.garageConsumptionRecommendationTieCount(closest.length),
              ),
            ],
            const SizedBox(height: 12),
            Column(
              key: const ValueKey('consumption-recommendation-shortlist'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final candidate in shortlist) _card(context, candidate),
              ],
            ),
            if (currentOutside || retainedReference != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.garageConsumptionRecommendationCurrent,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (currentOutside)
                _card(context, current)
              else
                ConsumptionReferenceSummary(
                  reference: retainedReference!,
                  vehicleYear: widget.vehicle.year,
                ),
            ],
            if (otherCandidates.isNotEmpty) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: const ValueKey('consumption-recommendation-show-all'),
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll
                        ? l10n.garageConsumptionRecommendationShowLess
                        : l10n.garageConsumptionRecommendationShowAll,
                  ),
                ),
              ),
              if (_showAll) ...[
                Text(
                  l10n.garageConsumptionRecommendationOther,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final candidate in otherCandidates)
                  _card(context, candidate),
              ],
            ],
            if (widget.onRefine != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const ValueKey('consumption-recommendation-refine'),
                  onPressed: widget.onRefine,
                  icon: const Icon(Icons.tune),
                  label: Text(l10n.garageConsumptionRecommendationRefine),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, Motorisation candidate) =>
      ConsumptionRecommendationCard(
        candidate: candidate,
        vehicleYear: widget.vehicle.year,
        selected: candidate.id == widget.vehicle.motorisationId,
        onSelect: () => Navigator.pop(context, candidate),
      );
}
