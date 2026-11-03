import 'package:flutter/material.dart';

import '../../../../core/l10n/transmission_labels.dart';
import '../../../../l10n/app_localizations.dart';

/// Two everyday choices; a known automatic gearbox keeps its precise code.
class TransmissionSelector extends StatelessWidget {
  const TransmissionSelector({
    super.key,
    this.value,
    required this.onChanged,
    this.enabled = true,
    required this.label,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final group = transmissionGroup(value);
    final hasValue = value != null && value!.isNotEmpty;
    final automaticCodes = transmissionCodes.where((code) => code != 'manual');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final code in ['manual', 'automatic'])
              ChoiceChip(
                key: ValueKey('transmission-$code'),
                label: Text(transmissionLabel(code, l10n)),
                selected: group == code,
                onSelected: enabled
                    ? (selected) {
                        if (selected && group != code) onChanged(code);
                      }
                    : null,
              ),
          ],
        ),
        if (group == 'automatic') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('transmission-detail-$value'),
            initialValue: value,
            isExpanded: true,
            itemHeight: null,
            decoration: InputDecoration(
              labelText: l10n.vehiclesAutomaticTypeOptional,
            ),
            items: [
              for (final code in automaticCodes)
                DropdownMenuItem(
                  value: code,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      code == 'automatic'
                          ? l10n.vehiclesAutomaticTypeUnspecified
                          : transmissionLabel(code, l10n),
                    ),
                  ),
                ),
            ],
            onChanged: enabled ? onChanged : null,
          ),
        ],
        if (hasValue && group == null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.vehiclesSavedTransmissionType(value!),
            key: const ValueKey('transmission-unknown'),
          ),
        ],
        if (hasValue)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('transmission-clear'),
              onPressed: enabled ? () => onChanged(null) : null,
              child: Text(l10n.privateSalesClearTransmission),
            ),
          ),
      ],
    );
  }
}
