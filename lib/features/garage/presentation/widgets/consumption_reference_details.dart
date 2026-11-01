import 'package:flutter/material.dart';

import '../../../../../core/utils/lien_externe.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../data/models/owned_vehicle.dart';

/// A reference is separate from the consumption measured at the fuel pump.
/// Unknown applicability keeps the source number in details only.
class ConsumptionReferenceSummary extends StatelessWidget {
  final VehicleConsumption reference;
  final int? vehicleYear;
  final VoidCallback? onChange;

  const ConsumptionReferenceSummary({
    super.key,
    required this.reference,
    required this.vehicleYear,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = reference.primaryCombinedL100km;
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(consumptionMatchLabel(l10n, reference), style: style),
        if (value != null)
          Text(
            l10n.garageConsumptionValue(_number(context, value)),
            style: style,
          ),
        Text(consumptionYearLabel(l10n, reference), style: style),
        if (vehicleYear != null &&
            vehicleYear! > 0 &&
            (reference.modelYear != vehicleYear ||
                reference.yearKind != 'model_year'))
          Text(l10n.garageConsumptionVehicleYear(vehicleYear!), style: style),
        Text(_marketLabel(l10n, reference), style: style),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => showConsumptionReferenceDetails(
                context,
                reference,
                vehicleYear: vehicleYear,
              ),
              child: Text(l10n.garageConsumptionDetails),
            ),
            if (onChange != null)
              TextButton(
                onPressed: onChange,
                child: Text(l10n.garageConsumptionChange),
              ),
          ],
        ),
      ],
    );
  }
}

String consumptionMatchLabel(
  AppLocalizations l10n,
  VehicleConsumption reference,
) {
  if (reference.referenceStatus == 'withdrawn')
    return l10n.garageConsumptionWithdrawn;
  if (reference.referenceStatus == 'legacy')
    return l10n.garageConsumptionLegacy;
  return switch (reference.matchLevel) {
    'corresponding' => l10n.garageConsumptionCorresponding,
    'approximate' => l10n.garageConsumptionApproximate,
    _ => l10n.garageConsumptionIncomplete,
  };
}

String consumptionYearLabel(
  AppLocalizations l10n,
  VehicleConsumption reference,
) {
  final year = reference.modelYear;
  if (year == null || year <= 0) return l10n.garageConsumptionYearMissing;
  return switch (reference.yearKind) {
    'model_year' => l10n.garageConsumptionModelYear(year),
    'registration_year' => l10n.garageConsumptionRegistrationYear(year),
    _ => l10n.garageConsumptionUnknownYear(year),
  };
}

String _marketLabel(AppLocalizations l10n, VehicleConsumption reference) =>
    reference.market?.trim().isNotEmpty == true
    ? l10n.garageConsumptionMarket(reference.market!)
    : l10n.garageConsumptionMarketUnknown;

String _methodLabel(AppLocalizations l10n, String method) => switch (method) {
  'test' => l10n.garageConsumptionMethodTest,
  'adjustment' => l10n.garageConsumptionMethodAdjustment,
  'aggregation' => l10n.garageConsumptionMethodAggregation,
  'transcription' => l10n.garageConsumptionMethodTranscription,
  _ => l10n.garageConsumptionMethodUnknown,
};

String _reasonLabel(AppLocalizations l10n, String reason) => switch (reason) {
  'legacy_reference' => l10n.garageConsumptionReasonLegacy,
  'withdrawn_reference' => l10n.garageConsumptionWithdrawn,
  'model_year_mismatch' => l10n.garageConsumptionReasonYear,
  'market_unknown' => l10n.garageConsumptionReasonMarket,
  'aggregation' => l10n.garageConsumptionReasonAggregation,
  'configuration_unverified' ||
  'source_unverified' => l10n.garageConsumptionReasonUnverified,
  'model_mismatch' ||
  'fuel_mismatch' ||
  'engine_mismatch' ||
  'drivetrain_mismatch' ||
  'hybrid_mismatch' ||
  'trim_mismatch' ||
  'market_mismatch' => l10n.garageConsumptionReasonContradiction,
  'method_unknown' => l10n.garageConsumptionMethodUnknown,
  'revision_superseded' => l10n.garageConsumptionReasonRevision,
  _ => l10n.garageConsumptionReasonIncomplete,
};

Future<void> showConsumptionReferenceDetails(
  BuildContext context,
  VehicleConsumption reference, {
  required int? vehicleYear,
}) async {
  final l10n = AppLocalizations.of(context);
  final provenance = reference.provenance;
  final uri = reference.sourceUri;
  String? field(List<String> names) {
    for (final name in names) {
      final value = provenance[name];
      if (value is String && value.trim().isNotEmpty) return value;
      if (value is num) return value.toString();
    }
    return null;
  }

  final imported = field(['imported_at']);
  final retrieved = field(['retrieved_at']);
  final published = field(['published_at', 'publication_date']);
  final revision = field(['revision', 'resource_revision']);
  final resource = field(['resource_id', 'record_id', 'row_id']);
  final hash = field(['file_sha256', 'sha256', 'file_hash']);
  final count = field([
    'observation_count',
    'sample_size',
    'count',
    'records_count',
    'record_count',
  ]);
  final sourceRecord = field(['source_record']);
  final originalUnit = field(['original_unit']);
  final license = field(['license_title', 'license_id']);
  final sourceValue = reference.sourceCombinedL100km;
  final lines = <String>[
    consumptionMatchLabel(l10n, reference),
    if (reference.sourceModel?.isNotEmpty == true) reference.sourceModel!,
    if (reference.label.isNotEmpty) reference.label,
    if (reference.powerKw != null) '${reference.powerKw} kW',
    l10n.garageConsumptionSelectionNotice,
    if (vehicleYear != null && vehicleYear > 0)
      l10n.garageConsumptionVehicleYear(vehicleYear),
    consumptionYearLabel(l10n, reference),
    _marketLabel(l10n, reference),
    reference.source.isEmpty
        ? l10n.garageConsumptionSourceUnknown
        : l10n.garageConsumptionSource(reference.source),
    reference.cycle.isEmpty
        ? l10n.garageConsumptionCycleUnknown
        : l10n.garageConsumptionProtocol(reference.cycle),
    _methodLabel(l10n, reference.method),
    if (sourceValue != null)
      l10n.garageConsumptionSourceValue(_number(context, sourceValue)),
    if ((reference.referenceCityL100km ?? reference.cityL100km) != null)
      l10n.garageConsumptionSourceCity(
        _number(
          context,
          reference.referenceCityL100km ?? reference.cityL100km!,
        ),
      ),
    if ((reference.referenceHighwayL100km ?? reference.highwayL100km) != null)
      l10n.garageConsumptionSourceHighway(
        _number(
          context,
          reference.referenceHighwayL100km ?? reference.highwayL100km!,
        ),
      ),
    if (reference.verifiedAt != null)
      l10n.garageConsumptionVerified(reference.verifiedAt!)
    else
      l10n.garageConsumptionNotVerified,
    ...reference.matchReasons
        .map((reason) => _reasonLabel(l10n, reason))
        .toSet(),
    if (revision != null) l10n.garageConsumptionRevision(revision),
    if (resource != null) l10n.garageConsumptionResource(resource),
    if (sourceRecord != null) l10n.garageConsumptionSourceRecord(sourceRecord),
    if (originalUnit != null) l10n.garageConsumptionOriginalUnit(originalUnit),
    if (license != null) l10n.garageConsumptionLicense(license),
    if (published != null) l10n.garageConsumptionPublished(published),
    if (retrieved != null) l10n.garageConsumptionRetrieved(retrieved),
    if (imported != null) l10n.garageConsumptionImported(imported),
    if (hash != null) l10n.garageConsumptionHash(hash),
    if (count != null) l10n.garageConsumptionRecords(count),
    if (provenance['truncated'] == true || provenance['sample_limited'] == true)
      l10n.garageConsumptionLimitedSample,
    l10n.garageConsumptionMissingDetails,
  ];
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.garageConsumptionDetails),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectableText(line),
                ),
              if (uri != null) ...[
                SelectableText(uri.toString()),
                TextButton.icon(
                  onPressed: () => ouvrirLien(
                    dialogContext,
                    uri,
                    valeurACopier: uri.toString(),
                    ceQuiNePeutPasSOuvrir: l10n.garageConsumptionSourceTarget,
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.garageConsumptionOpenSource),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(MaterialLocalizations.of(dialogContext).closeButtonLabel),
        ),
      ],
    ),
  );
}

String _number(BuildContext context, double value) =>
    Localizations.localeOf(context).languageCode == 'fr'
    ? value.toStringAsFixed(1).replaceAll('.', ',')
    : value.toStringAsFixed(1);

/// A listing may suggest several references without attributing one to the car.
/// No range is computed across engines, markets, sources or protocols.
class ConsumptionReferenceCandidates extends StatelessWidget {
  final List<VehicleConsumption> references;
  final int? vehicleYear;

  const ConsumptionReferenceCandidates({
    super.key,
    required this.references,
    required this.vehicleYear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(l10n.catalogConsumptionReferences),
      subtitle: Text(l10n.catalogConsumptionComparisonNotice),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: references.length,
            itemBuilder: (context, index) {
              final reference = references[index];
              final value = reference.sourceCombinedL100km;
              return ListTile(
                title: Text(
                  [
                    if (reference.sourceModel?.isNotEmpty == true)
                      reference.sourceModel!,
                    reference.label,
                    if (reference.powerKw != null) '${reference.powerKw} kW',
                  ].join(' · '),
                ),
                subtitle: Text(
                  [
                    consumptionMatchLabel(l10n, reference),
                    consumptionYearLabel(l10n, reference),
                    _marketLabel(l10n, reference),
                    if (reference.fuel != null) reference.fuel!,
                    if (reference.source.isNotEmpty) reference.source,
                    if (reference.cycle.isNotEmpty) reference.cycle,
                    if (value != null)
                      l10n.garageConsumptionSourceValue(
                        _number(context, value),
                      ),
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.info_outline),
                onTap: () => showConsumptionReferenceDetails(
                  context,
                  reference,
                  vehicleYear: vehicleYear,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
