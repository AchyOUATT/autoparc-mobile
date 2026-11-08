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
      chassisType = value?.chassisType;

  final TextEditingController version,
      cab,
      axles,
      bodyUse,
      emission,
      ptac,
      ptra;
  String? chassisType;

  HeavyVehicleConfiguration toValue() => HeavyVehicleConfiguration(
    versionLabel: _optionalText(version.text),
    cabLabel: _optionalText(cab.text),
    axleConfiguration: _optionalText(axles.text),
    chassisType: _optionalText(chassisType),
    bodyUse: _optionalText(bodyUse.text),
    emissionStandard: _optionalText(emission.text),
    ptacKg: int.tryParse(ptac.text.trim()),
    ptraKg: int.tryParse(ptra.text.trim()),
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
        DropdownButtonFormField<String>(
          key: const ValueKey('heavy-chassis'),
          initialValue: c.chassisType,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.heavyConfigurationChassis,
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(l10n.heavyConfigurationUnspecified),
            ),
            for (final value in ['tractor', 'rigid', 'other'])
              DropdownMenuItem(
                value: value,
                child: Text(_chassisLabel(value, l10n)),
              ),
            // Preserve a future API value when an older app edits the vehicle.
            if (c.chassisType != null &&
                !const ['tractor', 'rigid', 'other'].contains(c.chassisType))
              DropdownMenuItem(
                value: c.chassisType,
                child: Text(c.chassisType!),
              ),
          ],
          onChanged: (value) => setState(() => c.chassisType = value),
        ),
        const SizedBox(height: 16),
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
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final fields = <(String, String?)>[
      (l10n.heavyConfigurationVersion, _optionalText(c.versionLabel)),
      (l10n.heavyConfigurationCab, _optionalText(c.cabLabel)),
      (l10n.heavyConfigurationAxles, _optionalText(c.axleConfiguration)),
      (
        l10n.heavyConfigurationChassis,
        c.chassisType == null ? null : _chassisLabel(c.chassisType!, l10n),
      ),
      (l10n.heavyConfigurationBodyUse, _optionalText(c.bodyUse)),
      (l10n.heavyConfigurationEmission, _optionalText(c.emissionStandard)),
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

String _chassisLabel(String value, AppLocalizations l10n) => switch (value) {
  'tractor' => l10n.heavyConfigurationTractor,
  'rigid' => l10n.heavyConfigurationRigid,
  'other' => l10n.heavyConfigurationOther,
  _ => value,
};
