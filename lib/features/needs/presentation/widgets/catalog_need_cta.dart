import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Question et bouton « Émettre un besoin », pour l'écran vide d'une liste.
///
/// Masqué pour le personnel, qui traite les besoins au lieu d'en déposer.
class CatalogNeedEmptyPrompt extends ConsumerWidget {
  final VoidCallback onEmit;

  const CatalogNeedEmptyPrompt({super.key, required this.onEmit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authProvider).isStaff) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      key: const Key('catalog-need-empty-cta'),
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 36, color: cs.primary),
          const SizedBox(height: 12),
          Text(
            l10n.catalogNeedNotFoundPrompt,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onEmit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l10n.catalogNeedEmitAction),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              visualDensity: VisualDensity.standard,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte discrète en fin de liste, une fois la dernière page chargée.
///
/// Masquée pour le personnel, comme [CatalogNeedEmptyPrompt].
class CatalogNeedEndOfListCard extends ConsumerWidget {
  final VoidCallback onEmit;

  const CatalogNeedEndOfListCard({super.key, required this.onEmit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authProvider).isStaff) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      key: const Key('catalog-need-end-cta'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.inbox_outlined, size: 20, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.catalogNeedNotFoundPrompt,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: onEmit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.catalogNeedEmitAction),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    visualDensity: VisualDensity.standard,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
