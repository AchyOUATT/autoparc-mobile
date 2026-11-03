import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/fault_declaration.dart';
import 'vehicle_fault_labels.dart';

/// Public seller statements. Nothing here creates or implies an inspection.
class DeclaredFaultsSection extends StatelessWidget {
  final FaultDeclaration declaration;
  const DeclaredFaultsSection({super.key, required this.declaration});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.faultDeclarationTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        if (declaration.state == 'none')
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 6),
                  Flexible(child: Text(l.faultDeclarationNoneSeller)),
                ],
              ),
            ),
          )
        else
          Text(
            declaration.state == 'has_faults'
                ? l.faultDeclarationHasFaults
                : l.faultDeclarationUnknown,
          ),
        if (declaration.declaredAt != null) ...[
          const SizedBox(height: 4),
          Text(
            l.faultDeclarationDate(
              DateFormat.yMMMd(
                Localizations.localeOf(context).languageCode,
              ).format(declaration.declaredAt!.toLocal()),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 6),
        Text(
          l.faultDeclarationSellerNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (declaration.state == 'has_faults' ||
            declaration.faults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l.faultDeclarationUnresolvedCount(declaration.unresolvedCount),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (declaration.faults.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.faultDeclarationDetailsUnavailable),
            ),
          for (final fault in declaration.faults)
            DeclaredFaultCard(fault: fault),
        ],
      ],
    );
  }
}

/// Shared visual vocabulary for public declarations and the controlled editor.
/// There is deliberately no shield/checkmark or green "healthy" state.
class DeclaredFaultCard extends StatelessWidget {
  final DeclaredVehicleFault fault;
  final Widget? actions;
  const DeclaredFaultCard({super.key, required this.fault, this.actions});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final severe = fault.severity == 'critical' || fault.isSafetyCritical;
    final color = severe
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(fault.title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(vehicleFaultCategoryLabel(fault.category, l)),
                Text(
                  vehicleFaultSeverityLabel(fault.severity, l),
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                Text(vehicleFaultStatusLabel(fault.status, l)),
                if (fault.isUnresolved) Text(l.faultDeclarationUnrepaired),
              ],
            ),
            if (fault.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(fault.description!),
            ],
            if (fault.affectsDrivability || fault.isSafetyCritical) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [
                  if (fault.affectsDrivability)
                    _Flag(
                      Icons.directions_car_outlined,
                      l.vehiclesFaultDrivingAffected,
                      color,
                    ),
                  if (fault.isSafetyCritical)
                    _Flag(
                      Icons.warning_amber_outlined,
                      l.vehiclesFaultSafetyCritical,
                      theme.colorScheme.error,
                    ),
                ],
              ),
            ],
            if (actions != null) ...[const SizedBox(height: 8), actions!],
          ],
        ),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Flag(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Text(label, style: TextStyle(color: color)),
      ),
    ],
  );
}
