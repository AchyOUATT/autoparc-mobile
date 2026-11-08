import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/owned_vehicle.dart';

/// Identity and exact odometer value, kept separate from secondary metadata.
class VehicleCardHeader extends StatelessWidget {
  final OwnedVehicle vehicle;
  final Widget trailing;

  const VehicleCardHeader({
    super.key,
    required this.vehicle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final id = vehicle.identity;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: BrandLogo(slug: id.brandSlug, size: 36)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${id.fullName} · ${vehicle.year}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
          if (vehicle.plateNumber != null || vehicle.mileageKm != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 20,
                runSpacing: 12,
                children: [
                  if (vehicle.plateNumber != null)
                    _VehicleFact(
                      icon: Icons.badge_outlined,
                      value: vehicle.plateNumber!,
                    ),
                  if (vehicle.mileageKm != null)
                    _VehicleFact(
                      icon: Icons.speed,
                      value: AppLocalizations.of(context).garageMileageValue(
                        NumberFormat.decimalPattern(locale)
                            .format(vehicle.mileageKm!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VehicleFact extends StatelessWidget {
  final IconData icon;
  final String value;

  const _VehicleFact({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
