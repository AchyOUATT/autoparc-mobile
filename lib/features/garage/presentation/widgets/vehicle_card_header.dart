import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/owned_vehicle.dart';

/// Identity and exact odometer value, kept separate from secondary metadata.
///
/// [tags] (fuel, colour, compatibility) sit under the facts, so the whole
/// identity of the vehicle reads as one block before any action.
class VehicleCardHeader extends StatelessWidget {
  final OwnedVehicle vehicle;
  final Widget trailing;
  final List<Widget> tags;

  const VehicleCardHeader({
    super.key,
    required this.vehicle,
    required this.trailing,
    this.tags = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final id = vehicle.identity;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
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
                    Semantics(
                      header: true,
                      child: Text(
                        vehicle.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${id.fullName} · ${vehicle.year}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (vehicle.isTwoWheeler) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.two_wheeler_outlined,
                            size: 16,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _twoWheelerLabel(
                                AppLocalizations.of(context),
                                vehicle,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              trailing,
            ],
          ),
          if (vehicle.plateNumber != null || vehicle.mileageKm != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(right: 8),
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
                    _PlateFact(value: vehicle.plateNumber!),
                  if (vehicle.mileageKm != null)
                    _VehicleFact(
                      icon: Icons.speed,
                      value: AppLocalizations.of(context).garageMileageValue(
                        NumberFormat.decimalPattern(
                          locale,
                        ).format(vehicle.mileageKm!),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Wrap(spacing: 6, runSpacing: 6, children: tags),
            ),
          ],
        ],
      ),
    );
  }
}

/// The plate, drawn as a plate: it is the fact people look for first.
class _PlateFact extends StatelessWidget {
  final String value;

  const _PlateFact({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.badge_outlined, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: cs.outline),
            ),
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ],
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

String _twoWheelerLabel(AppLocalizations l10n, OwnedVehicle vehicle) {
  final body = switch (vehicle.twoWheelerConfiguration.bodyType) {
    'motorcycle' => l10n.twoWheelerBodyMotorcycle,
    'scooter' => l10n.twoWheelerBodyScooter,
    'moped' => l10n.twoWheelerBodyMoped,
    'other' => l10n.heavyConfigurationOther,
    _ => null,
  };
  return body == null
      ? l10n.vehiclesTypeTwoWheeler
      : '${l10n.vehiclesTypeTwoWheeler} · $body';
}
