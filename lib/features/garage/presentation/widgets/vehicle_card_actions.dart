import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Secondary actions stack on small screens and with enlarged text.
class VehicleCardActions extends StatelessWidget {
  final VoidCallback onParts;
  final VoidCallback onMileage;

  const VehicleCardActions({
    super.key,
    required this.onParts,
    required this.onMileage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 380 ||
            MediaQuery.textScalerOf(context).scale(14) > 18;
        final parts = OutlinedButton.icon(
          onPressed: onParts,
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: Text(l10n.garageMatchingPartsTitle),
        );
        final mileage = OutlinedButton.icon(
          onPressed: onMileage,
          icon: const Icon(Icons.speed, size: 18),
          label: Text(l10n.garageUpdateAction),
        );
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [parts, const SizedBox(height: 8), mileage],
          );
        }
        return Row(
          children: [
            Expanded(flex: 3, child: parts),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: mileage),
          ],
        );
      },
    );
  }
}
