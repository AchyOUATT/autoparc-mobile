import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../garage/presentation/providers/garage_provider.dart';

/// A non-blocking invitation only when the signed-in client's garage is known
/// to be empty. Unknown, loading and failed sessions never imply an empty garage.
class GarageRegistrationPrompt extends ConsumerWidget {
  const GarageRegistrationPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.isClient || !auth.verified) return const SizedBox.shrink();

    final garage = ref.watch(garageProvider);
    if (garage.isLoading ||
        garage.hasError ||
        garage.valueOrNull == null ||
        garage.valueOrNull!.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.catalogGarageInviteBody,
              style: theme.textTheme.bodyMedium,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () => context.push('/garage/add'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.garageAddVehicleAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
