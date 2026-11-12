import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/heavy_vehicle_configuration.dart';

/// Keeps declared labels intact; no technical fact is inferred from a version.
class HeavyVehicleConfigurationController {
  HeavyVehicleConfigurationController({HeavyVehicleConfiguration? value})
    : version = TextEditingController(text: value?.versionLabel ?? ''),
      cab = TextEditingController(text: value?.cabLabel ?? ''),
      axles = TextEditingController(text: value?.axleConfiguration ?? ''),
      bodyUse = TextEditingController(text: value?.bodyUse ?? ''),
      emission = TextEditingController(text: value?.emissionStandard ?? ''),
      ptac = TextEditingController(text: value?.ptacKg?.toString() ?? ''),
      ptra = TextEditingController(text: value?.ptraKg?.toString() ?? ''),
      usefulVolume = TextEditingController(
        text: value?.usefulVolumeM3 == null
            ? ''
            : _formatVolumeInput(value!.usefulVolumeM3!),
      ),
      tankCapacity = TextEditingController(
        text: value?.tankCapacityLiters?.toString() ?? '',
      ),
      payload = TextEditingController(text: value?.payloadKg?.toString() ?? ''),
      chassisType = value?.chassisType,
      bodyType = value?.bodyType;

  final TextEditingController version,
      cab,
      axles,
      bodyUse,
      emission,
      ptac,
      ptra,
      usefulVolume,
      tankCapacity,
      payload;
  String? chassisType;
  String? bodyType;

  HeavyVehicleConfiguration toValue() => HeavyVehicleConfiguration(
    versionLabel: _optionalText(version.text),
    cabLabel: _optionalText(cab.text),
    axleConfiguration: _optionalText(axles.text),
    chassisType: _optionalText(chassisType),
    bodyType: _optionalText(bodyType),
    bodyUse: _optionalText(bodyUse.text),
    emissionStandard: _optionalText(emission.text),
    ptacKg: int.tryParse(ptac.text.trim()),
    ptraKg: int.tryParse(ptra.text.trim()),
    usefulVolumeM3: _parseVolume(usefulVolume.text),
    tankCapacityLiters: bodyType == 'tanker'
        ? int.tryParse(tankCapacity.text.trim())
        : null,
    payloadKg: int.tryParse(payload.text.trim()),
  );

  void dispose() {
    for (final controller in [
      version,
      cab,
      axles,
      bodyUse,
      emission,
      ptac,
      ptra,
      usefulVolume,
      tankCapacity,
      payload,
    ]) {
      controller.dispose();
    }
  }
}

class HeavyVehicleConfigurationFields extends StatefulWidget {
  const HeavyVehicleConfigurationFields({super.key, required this.controller});

  final HeavyVehicleConfigurationController controller;

  @override
  State<HeavyVehicleConfigurationFields> createState() =>
      _HeavyVehicleConfigurationFieldsState();
}

class _HeavyVehicleConfigurationFieldsState
    extends State<HeavyVehicleConfigurationFields> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = widget.controller;

    Widget textField(
      String key,
      String label,
      TextEditingController controller,
      int maxLength, {
      String? helper,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey(key),
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 4,
          errorMaxLines: 4,
        ),
        validator: (raw) => (raw?.trim().length ?? 0) > maxLength
            ? l10n.heavyConfigurationTextTooLong(maxLength)
            : null,
      ),
    );

    Widget massField(
      String key,
      String label,
      String helper,
      TextEditingController controller, {
      bool totalTrain = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey(key),
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 4,
          errorMaxLines: 4,
        ),
        validator: (raw) {
          final text = (raw ?? '').trim();
          if (text.isEmpty) return null;
          final value = _validMass(text);
          if (value == null) return l10n.heavyConfigurationMassInvalid;
          final ptac = _validMass(c.ptac.text.trim());
          if (totalTrain && ptac != null && value < ptac) {
            return l10n.heavyConfigurationTrainMassTooSmall;
          }
          return null;
        },
      ),
    );

    Widget codeDropdown({
      required String key,
      required String label,
      required String? value,
      required List<String> values,
      required String Function(String) labelFor,
      required ValueChanged<String?> onChanged,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey(key),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(l10n.heavyConfigurationUnspecified),
          ),
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(labelFor(item))),
          if (value != null && !values.contains(value))
            DropdownMenuItem(value: value, child: Text(value)),
        ],
        onChanged: onChanged,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.heavyConfigurationHelp),
        const SizedBox(height: 16),
        textField(
          'heavy-version',
          l10n.heavyConfigurationVersion,
          c.version,
          100,
        ),
        textField('heavy-cab', l10n.heavyConfigurationCab, c.cab, 100),
        textField(
          'heavy-axles',
          l10n.heavyConfigurationAxles,
          c.axles,
          40,
          helper: l10n.heavyConfigurationAxlesHelp,
        ),
        codeDropdown(
          key: 'heavy-chassis',
          label: l10n.heavyConfigurationChassis,
          value: c.chassisType,
          values: const ['tractor', 'rigid', 'other'],
          labelFor: (value) => _chassisLabel(value, l10n),
          onChanged: (value) => setState(() => c.chassisType = value),
        ),
        codeDropdown(
          key: 'heavy-body-type',
          label: l10n.heavyConfigurationBodyType,
          value: c.bodyType,
          values: HeavyVehicleConfiguration.bodyTypes,
          labelFor: (value) => _bodyTypeLabel(value, l10n),
          onChanged: (value) => setState(() {
            c.bodyType = value;
            if (value != 'tanker') c.tankCapacity.clear();
          }),
        ),
        textField(
          'heavy-body-use',
          l10n.heavyConfigurationBodyUse,
          c.bodyUse,
          100,
        ),
        textField(
          'heavy-emission',
          l10n.heavyConfigurationEmission,
          c.emission,
          40,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            key: const ValueKey('heavy-useful-volume'),
            controller: c.usefulVolume,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.heavyConfigurationVolume,
              helperText: l10n.heavyConfigurationVolumeHelp,
              suffixText: 'm³',
              helperMaxLines: 4,
              errorMaxLines: 4,
            ),
            validator: (raw) {
              final text = (raw ?? '').trim();
              if (text.isEmpty) return null;
              return _parseVolume(text) == null
                  ? l10n.heavyConfigurationVolumeInvalid
                  : null;
            },
          ),
        ),
        if (c.bodyType == 'tanker')
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              key: const ValueKey('heavy-tank-capacity'),
              controller: c.tankCapacity,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.heavyConfigurationTankCapacity,
                helperText: l10n.heavyConfigurationTankCapacityHelp,
                suffixText: 'L',
                helperMaxLines: 4,
                errorMaxLines: 4,
              ),
              validator: (raw) {
                final text = (raw ?? '').trim();
                if (text.isEmpty) return null;
                final value = int.tryParse(text);
                if (value == null ||
                    value < HeavyVehicleConfiguration.tankCapacityMin ||
                    value > HeavyVehicleConfiguration.tankCapacityMax) {
                  return l10n.heavyConfigurationTankInvalid;
                }
                return null;
              },
            ),
          ),
        massField(
          'heavy-payload',
          l10n.heavyConfigurationPayload,
          l10n.heavyConfigurationPayloadHelp,
          c.payload,
        ),
        massField(
          'heavy-ptac',
          l10n.heavyConfigurationPtac,
          l10n.heavyConfigurationPtacHelp,
          c.ptac,
        ),
        massField(
          'heavy-ptra',
          l10n.heavyConfigurationPtra,
          l10n.heavyConfigurationPtraHelp,
          c.ptra,
          totalTrain: true,
        ),
      ],
    );
  }
}

class HeavyVehicleConfigurationDetails extends StatelessWidget {
  const HeavyVehicleConfigurationDetails({
    super.key,
    required this.configuration,
  });

  final HeavyVehicleConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    if (configuration.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final c = configuration;
    final locale = Localizations.localeOf(context).toString();
    final number = NumberFormat.decimalPattern(locale);
    final volume = NumberFormat('0.##', locale);
    final fields = <(String, String?)>[
      (l10n.heavyConfigurationVersion, _optionalText(c.versionLabel)),
      (l10n.heavyConfigurationCab, _optionalText(c.cabLabel)),
      (l10n.heavyConfigurationAxles, _optionalText(c.axleConfiguration)),
      (
        l10n.heavyConfigurationChassis,
        c.chassisType == null ? null : _chassisLabel(c.chassisType!, l10n),
      ),
      (
        l10n.heavyConfigurationBodyType,
        c.bodyType == null ? null : _bodyTypeLabel(c.bodyType!, l10n),
      ),
      (l10n.heavyConfigurationBodyUse, _optionalText(c.bodyUse)),
      (l10n.heavyConfigurationEmission, _optionalText(c.emissionStandard)),
      (
        l10n.heavyConfigurationVolume,
        c.usefulVolumeM3 == null ? null : '${volume.format(c.usefulVolumeM3)} m³',
      ),
      (
        l10n.heavyConfigurationTankCapacity,
        c.tankCapacityLiters == null
            ? null
            : '${number.format(c.tankCapacityLiters)} L',
      ),
      (
        l10n.heavyConfigurationPayload,
        c.payloadKg == null ? null : '${number.format(c.payloadKg)} kg',
      ),
      (
        l10n.heavyConfigurationPtac,
        c.ptacKg == null ? null : '${number.format(c.ptacKg)} kg',
      ),
      (
        l10n.heavyConfigurationPtra,
        c.ptraKg == null ? null : '${number.format(c.ptraKg)} kg',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.heavyConfigurationDetailsTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.heavyConfigurationDeclared,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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

String? _optionalText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

int? _validMass(String text) {
  if (!RegExp(r'^\d+$').hasMatch(text)) return null;
  final value = int.tryParse(text);
  return value != null && value > 0 && value <= 1000000 ? value : null;
}

double? _parseVolume(String text) {
  final parsed = double.tryParse(text.trim().replaceAll(',', '.'));
  if (parsed == null ||
      parsed < HeavyVehicleConfiguration.usefulVolumeMin ||
      parsed > HeavyVehicleConfiguration.usefulVolumeMax) {
    return null;
  }
  return (parsed * 100).round() / 100;
}

String _formatVolumeInput(double value) {
  final rounded = (value * 100).round() / 100;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toString();
}

String _chassisLabel(String value, AppLocalizations l10n) => switch (value) {
  'tractor' => l10n.heavyConfigurationTractor,
  'rigid' => l10n.heavyConfigurationRigid,
  'other' => l10n.heavyConfigurationOther,
  _ => value,
};

String _bodyTypeLabel(String value, AppLocalizations l10n) => switch (value) {
  'tanker' => l10n.heavyConfigurationBodyTanker,
  'tipper' => l10n.heavyConfigurationBodyTipper,
  'tractor_unit' => l10n.heavyConfigurationBodyTractorUnit,
  'flatbed' => l10n.heavyConfigurationBodyFlatbed,
  'box' => l10n.heavyConfigurationBodyBox,
  'mixer' => l10n.heavyConfigurationBodyMixer,
  'other' => l10n.heavyConfigurationOther,
  _ => value,
};
