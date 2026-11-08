import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/reference_labels.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../catalog/data/models/vehicle.dart';

/// A machine's declared measurements, with no reference-model certification.
class EquipmentDetailsSection extends StatelessWidget {
  const EquipmentDetailsSection({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    if (!vehicle.isEquipment) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final d = vehicle.equipmentDetails;
    final type = vehicle.equipmentType;
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    )..maximumFractionDigits = 6;
    String? measurement(num? value, String unit) =>
        value == null ? null : '${number.format(value)} $unit';
    String? date(String? value) {
      if (value == null) return null;
      final parsed = DateTime.tryParse(value);
      return parsed == null
          ? value
          : DateFormat.yMd(
              Localizations.localeOf(context).toString(),
            ).format(parsed);
    }

    final fields = <(String, String?)>[
      (l.equipmentTypeLabel, equipmentTypeLabel(type, l)),
      (l.equipmentBrand, _text(d.brandLabel) ?? _text(vehicle.identity.brand)),
      (l.equipmentModel, _text(d.modelLabel) ?? _text(vehicle.identity.model)),
      if (vehicle.identity.year != null)
        (l.catalogFieldYear, '${vehicle.identity.year}'),
      if (_text(vehicle.identity.engineType) != null)
        (
          l.equipmentFuelLabel,
          referenceFuelLabel(
            vehicle.identity.engineTypeCode,
            vehicle.identity.engineType!,
            l,
          ),
        ),
      (l.equipmentSerialNumber, _text(d.serialNumber)),
      (l.equipmentRegistrationNumber, _text(d.registrationNumber)),
      (l.equipmentParkNumber, _text(d.parkNumber)),
      (l.equipmentOperatingHours, measurement(d.operatingHours, 'h')),
      (l.equipmentHourReadingDate, date(d.hourReadingDate)),
      (l.equipmentOdometerKm, measurement(d.odometerKm, 'km')),
      (l.equipmentPowerKw, measurement(d.powerKw, 'kW')),
      (
        l.equipmentTransmission,
        d.transmission == null
            ? null
            : equipmentTransmissionLabel(d.transmission!, l),
      ),
      // Preserve visibility of all declared values, including after a type change.
      (l.equipmentRatedLoadKg, measurement(d.ratedLoadKg, 'kg')),
      (l.equipmentWorkingHeightM, measurement(d.workingHeightM, 'm')),
      (l.equipmentOutreachM, measurement(d.outreachM, 'm')),
      (l.equipmentLiftHeightM, measurement(d.liftHeightM, 'm')),
      (l.equipmentOperatingWeightKg, measurement(d.operatingWeightKg, 'kg')),
      (l.equipmentBucketCapacityM3, measurement(d.bucketCapacityM3, 'm³')),
      (l.equipmentPtoRpm, measurement(d.ptoRpm, 'rpm')),
      (
        l.equipmentCabin,
        d.cabin == null ? null : equipmentCabinLabel(d.cabin!, l),
      ),
      (
        l.equipmentQuickCoupler,
        d.quickCoupler == null
            ? null
            : d.quickCoupler!
            ? l.equipmentYes
            : l.equipmentNo,
      ),
      (l.equipmentAttachments, _text(d.attachments)),
      (l.equipmentEngineSerialNumber, _text(d.engineSerialNumber)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.equipmentDetailsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(l.equipmentDeclared, style: Theme.of(context).textTheme.bodySmall),
        for (final (label, value) in fields)
          if (value != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  Text(value),
                ],
              ),
            ),
      ],
    );
  }
}

String equipmentTypeLabel(String? type, AppLocalizations l) => switch (type) {
  'agricultural_tractor' => l.equipmentTypeAgriculturalTractor,
  'aerial_platform' => l.equipmentTypeAerialPlatform,
  'excavator' => l.equipmentTypeExcavator,
  'backhoe_loader' => l.equipmentTypeBackhoeLoader,
  'loader' => l.equipmentTypeLoader,
  'telehandler' => l.equipmentTypeTelehandler,
  'forklift' => l.equipmentTypeForklift,
  'generator' => l.equipmentTypeGenerator,
  'other' => l.equipmentTypeOther,
  null => l.equipmentUnknown,
  _ => type,
};

String equipmentTransmissionLabel(String value, AppLocalizations l) =>
    switch (value) {
      'mechanical' => l.equipmentTransmissionMechanical,
      'hydrostatic' => l.equipmentTransmissionHydrostatic,
      'powershift' => l.equipmentTransmissionPowershift,
      'electric' => l.equipmentTransmissionElectric,
      'other' => l.equipmentTransmissionOther,
      _ => value,
    };

String equipmentCabinLabel(String value, AppLocalizations l) => switch (value) {
  'open' => l.equipmentCabinOpen,
  'closed' => l.equipmentCabinClosed,
  'air_conditioned' => l.equipmentCabinAirConditioned,
  _ => value,
};

String? _text(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
