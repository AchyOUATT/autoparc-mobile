import 'models/motorisation.dart';

bool consumptionCandidateEligible(Motorisation candidate) =>
    candidate.recommendationEligible &&
    candidate.consumption.referenceStatus != 'withdrawn';

/// A shared presentation of the server's best group, never a client-side score.
class ConsumptionRecommendationSelection {
  ConsumptionRecommendationSelection(List<Motorisation> options) {
    eligible = options.where(consumptionCandidateEligible).toList();
    final ranked = eligible
        .where((candidate) => candidate.recommendationRank != null)
        .toList();
    final bestRank = ranked.isEmpty
        ? null
        : ranked
              .map((candidate) => candidate.recommendationRank!)
              .reduce((a, b) => a < b ? a : b);
    closest = ranked.isEmpty
        ? eligible
        : ranked
              .where((candidate) => candidate.recommendationRank == bestRank)
              .toList();
    hasEvidence =
        ranked.isNotEmpty &&
        closest.any((candidate) => candidate.hasDiscriminatingMatch);
    shortlist = closest.take(3).toList();
  }

  late final List<Motorisation> eligible;
  late final List<Motorisation> closest;
  late final List<Motorisation> shortlist;
  late final bool hasEvidence;
}
