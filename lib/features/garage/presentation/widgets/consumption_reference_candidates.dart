import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/consumption_recommendation_selection.dart';
import '../../data/models/motorisation.dart';
import 'consumption_recommendation_card.dart';

/// Source comparisons on a public listing remain read-only and separate from
/// the seller's declared consumption. Ranking never assigns a value to the car.
class ConsumptionReferenceCandidates extends StatefulWidget {
  const ConsumptionReferenceCandidates({
    super.key,
    required this.references,
    required this.vehicleYear,
  });

  final List<Motorisation> references;
  final int? vehicleYear;

  @override
  State<ConsumptionReferenceCandidates> createState() =>
      _ConsumptionReferenceCandidatesState();
}

class _ConsumptionReferenceCandidatesState
    extends State<ConsumptionReferenceCandidates> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    if (widget.references.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final selection = ConsumptionRecommendationSelection(widget.references);
    final shown = selection.shortlist.map((candidate) => candidate.id).toSet();
    final others = widget.references
        .where((candidate) => !shown.contains(candidate.id))
        .toList();
    final heading = !selection.hasEvidence
        ? l10n.garageConsumptionRecommendationNeedsDetails
        : selection.closest.length == 1
        ? l10n.garageConsumptionRecommendationClosest
        : l10n.garageConsumptionRecommendationTied;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.catalogConsumptionReferences,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(heading, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.catalogConsumptionComparisonNotice),
          const SizedBox(height: 4),
          Text(
            selection.eligible.isEmpty
                ? l10n.garageConsumptionRecommendationNoEligible
                : selection.hasEvidence
                ? l10n.garageConsumptionRecommendationNotice
                : l10n.garageConsumptionRecommendationProvisional,
          ),
          if (selection.hasEvidence && selection.closest.length > 3) ...[
            const SizedBox(height: 8),
            Text(
              l10n.garageConsumptionRecommendationTieCount(
                selection.closest.length,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Column(
            key: const ValueKey('consumption-listing-shortlist'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final candidate in selection.shortlist)
                ConsumptionRecommendationCard(
                  candidate: candidate,
                  vehicleYear: widget.vehicleYear,
                ),
            ],
          ),
          if (others.isNotEmpty) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                key: const ValueKey('consumption-listing-show-all'),
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
              for (final candidate in others)
                ConsumptionRecommendationCard(
                  candidate: candidate,
                  vehicleYear: widget.vehicleYear,
                ),
            ],
          ],
        ],
      ),
    );
  }
}
