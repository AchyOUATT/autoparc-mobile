import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/two_wheeler_configuration.dart';

class TwoWheelerConfigurationController extends ChangeNotifier {
  TwoWheelerConfigurationController();

  String? bodyType;
  String? stroke;
  String? cooling;
  String? starter;
  String? drive;
  String? transmission;

  void load(TwoWheelerConfiguration value) {
    bodyType = value.bodyType;
    stroke = value.stroke;
    cooling = value.cooling;
    starter = value.starter;
    drive = value.drive;
    transmission = value.transmission;
    notifyListeners();
  }

  void clear() {
    bodyType = stroke = cooling = starter = drive = transmission = null;
    notifyListeners();
  }

  void setBodyType(String? value) {
    bodyType = value;
    notifyListeners();
  }

  void setStroke(String? value) {
    stroke = value;
    notifyListeners();
  }

  void setCooling(String? value) {
    cooling = value;
    notifyListeners();
  }

  void setStarter(String? value) {
    starter = value;
    notifyListeners();
  }

  void setDrive(String? value) {
    drive = value;
    notifyListeners();
  }

  void setTransmission(String? value) {
    transmission = value;
    notifyListeners();
  }

  TwoWheelerConfiguration toValue() => TwoWheelerConfiguration(
    bodyType: bodyType,
    stroke: stroke,
    cooling: cooling,
    starter: starter,
    drive: drive,
    transmission: transmission,
  );
}

class TwoWheelerConfigurationFields extends StatelessWidget {
  const TwoWheelerConfigurationFields({super.key, required this.controller});

  final TwoWheelerConfigurationController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Column(
        children: [
          _Choice(
            key: const ValueKey('two-wheeler-body-type'),
            label: l10n.twoWheelerBodyType,
            value: controller.bodyType,
            items: [
              (null, l10n.heavyConfigurationUnspecified),
              ('motorcycle', l10n.twoWheelerBodyMotorcycle),
              ('scooter', l10n.twoWheelerBodyScooter),
              ('moped', l10n.twoWheelerBodyMoped),
              ('other', l10n.heavyConfigurationOther),
            ],
            onChanged: (value) {
              controller.setBodyType(value);
            },
          ),
          _Choice(
            label: l10n.twoWheelerStroke,
            value: controller.stroke,
            items: [
              (null, l10n.heavyConfigurationUnspecified),
              ('two_stroke', l10n.twoWheelerStrokeTwo),
              ('four_stroke', l10n.twoWheelerStrokeFour),
            ],
            onChanged: (value) {
              controller.setStroke(value);
            },
          ),
          _Choice(
            label: l10n.twoWheelerCooling,
            value: controller.cooling,
            items: [
              (null, l10n.heavyConfigurationUnspecified),
              ('air', l10n.twoWheelerCoolingAir),
              ('liquid', l10n.twoWheelerCoolingLiquid),
            ],
            onChanged: (value) {
              controller.setCooling(value);
            },
          ),
          _Choice(
            label: l10n.twoWheelerStarter,
            value: controller.starter,
            items: [
              (null, l10n.heavyConfigurationUnspecified),
              ('kick', l10n.twoWheelerStarterKick),
              ('electric', l10n.twoWheelerStarterElectric),
              ('both', l10n.twoWheelerStarterBoth),
            ],
            onChanged: (value) {
              controller.setStarter(value);
            },
          ),
          _Choice(
            label: l10n.twoWheelerDrive,
            value: controller.drive,
            items: [
              (null, l10n.heavyConfigurationUnspecified),
              ('chain', l10n.twoWheelerDriveChain),
              ('belt', l10n.twoWheelerDriveBelt),
              ('shaft', l10n.twoWheelerDriveShaft),
            ],
            onChanged: (value) {
              controller.setDrive(value);
            },
          ),
          _Choice(
            label: l10n.twoWheelerTransmission,
            value: controller.transmission,
            items: [
              (null, l10n.heavyConfigurationUnspecified),
              ('manual', l10n.twoWheelerTransmissionManual),
              ('semi_automatic', l10n.twoWheelerTransmissionSemiAutomatic),
              ('cvt', l10n.twoWheelerTransmissionCvt),
            ],
            onChanged: (value) {
              controller.setTransmission(value);
            },
          ),
        ],
      ),
    );
  }
}

class TwoWheelerConfigurationDetails extends StatelessWidget {
  const TwoWheelerConfigurationDetails({
    super.key,
    required this.configuration,
  });

  final TwoWheelerConfiguration configuration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (configuration.isEmpty) return const SizedBox.shrink();
    String label(String? code, Map<String, String> labels) => code == null
        ? l10n.heavyConfigurationUnspecified
        : (labels[code] ?? code);
    final rows = <(String, String)>[
      if (configuration.bodyType != null)
        (
          l10n.twoWheelerBodyType,
          label(configuration.bodyType, {
            'motorcycle': l10n.twoWheelerBodyMotorcycle,
            'scooter': l10n.twoWheelerBodyScooter,
            'moped': l10n.twoWheelerBodyMoped,
            'other': l10n.heavyConfigurationOther,
          }),
        ),
      if (configuration.stroke != null)
        (
          l10n.twoWheelerStroke,
          label(configuration.stroke, {
            'two_stroke': l10n.twoWheelerStrokeTwo,
            'four_stroke': l10n.twoWheelerStrokeFour,
          }),
        ),
      if (configuration.cooling != null)
        (
          l10n.twoWheelerCooling,
          label(configuration.cooling, {
            'air': l10n.twoWheelerCoolingAir,
            'liquid': l10n.twoWheelerCoolingLiquid,
          }),
        ),
      if (configuration.starter != null)
        (
          l10n.twoWheelerStarter,
          label(configuration.starter, {
            'kick': l10n.twoWheelerStarterKick,
            'electric': l10n.twoWheelerStarterElectric,
            'both': l10n.twoWheelerStarterBoth,
          }),
        ),
      if (configuration.drive != null)
        (
          l10n.twoWheelerDrive,
          label(configuration.drive, {
            'chain': l10n.twoWheelerDriveChain,
            'belt': l10n.twoWheelerDriveBelt,
            'shaft': l10n.twoWheelerDriveShaft,
          }),
        ),
      if (configuration.transmission != null)
        (
          l10n.twoWheelerTransmission,
          label(configuration.transmission, {
            'manual': l10n.twoWheelerTransmissionManual,
            'semi_automatic': l10n.twoWheelerTransmissionSemiAutomatic,
            'cvt': l10n.twoWheelerTransmissionCvt,
          }),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.twoWheelerConfigurationTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(child: Text(row.$1)),
                Text(row.$2, textAlign: TextAlign.end),
              ],
            ),
          ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<(String?, String)> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final item in items)
            DropdownMenuItem<String?>(value: item.$1, child: Text(item.$2)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
