import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog_repository.dart';
import '../../data/models/part.dart';
import '../providers/catalog_providers.dart';
import '../../../../shared/models/paged_state.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/cart/presentation/pages/cart_page.dart';
import '../../../../features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../../../features/notifications/presentation/widgets/notification_icon_button.dart';
import '../../../../features/garage/data/models/owned_vehicle.dart';
import '../../../../features/garage/presentation/providers/garage_provider.dart';
import '../../../../core/providers/shell_scaffold_provider.dart';

// ── Labels des types/conditions ─────────────────────────────────────

const _typeLabels = {
  'oem':         'OEM',
  'oes':         'OES',
  'aftermarket': 'Aftermarket',
  'salvage':     'Occasion',
};

const _conditionColors = {
  'new':         Colors.green,
  'refurbished': Colors.orange,
  'used':        Colors.grey,
};

// ════════════════════════════════════════════════════════════════════
// Page principale
// ════════════════════════════════════════════════════════════════════

class PartListPage extends ConsumerStatefulWidget {
  const PartListPage({super.key});

  @override
  ConsumerState<PartListPage> createState() => _PartListPageState();
}

class _PartListPageState extends ConsumerState<PartListPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(partListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paged   = ref.watch(partListProvider);
    final filter  = ref.watch(partFilterProvider);
    final cities  = ref.watch(catalogRefsProvider).valueOrNull?.cities ?? const <String>[];
    final isStaff = ref.watch(authProvider).isStaff;

    return Scaffold(
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/parts/new');
                ref.read(partListProvider.notifier).refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle pièce'),
            )
          : null,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () =>
              ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: const Text('Pièces détachées'),
        actions: [
          const NotificationIconButton(),
          if (!isStaff) ...[
            IconButton(
              icon: const Icon(Icons.inbox_outlined),
              tooltip: 'Exprimer un besoin',
              onPressed: () => context.push('/needs/new?type=part'),
            ),
            const CartIconButton(),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Nom, SKU, référence OEM…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(partFilterProvider.notifier)
                          .state = filter.copyWith(search: null);
                    },
                  ),
              ],
              onChanged: (q) => ref.read(partFilterProvider.notifier)
                  .state = filter.copyWith(search: q.isEmpty ? null : q),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          _FilterBar(filter: filter, cities: cities),
          // Filtre "pour mon véhicule" — visible uniquement pour les clients connectés.
          if (!isStaff) const _GarageFilterBanner(),
          Expanded(
            child: _Body(paged: paged, scrollCtrl: _scrollCtrl),
          ),
        ],
      ),
    );
  }
}

// ── Corps principal ──────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final PagedState<Part> paged;
  final ScrollController scrollCtrl;
  const _Body({required this.paged, required this.scrollCtrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (paged.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (paged.hasError) {
      return _ErrorView(
        error: paged.error.toString(),
        onRetry: () => ref.read(partListProvider.notifier).refresh(),
      );
    }
    if (paged.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(partListProvider.notifier).refresh(),
      child: _PartList(
        parts: paged.items,
        total: paged.total,
        hasMore: paged.hasMore,
        isLoadingMore: paged.isLoadingMore,
        scrollCtrl: scrollCtrl,
      ),
    );
  }
}

// ── Barre de filtres ─────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  final PartFilter filter;
  final List<String> cities;
  const _FilterBar({required this.filter, required this.cities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(PartFilter Function(PartFilter) fn) {
      ref.read(partFilterProvider.notifier).state =
          fn(ref.read(partFilterProvider));
    }

    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        children: [
          // Chips de ville
          for (final city in cities)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: const Icon(Icons.location_on_outlined, size: 14),
                label: Text(city),
                selected: filter.city == city,
                onSelected: (_) => update((f) => f.copyWith(
                  city: f.city == city ? null : city,
                  clearCity: f.city == city,
                  clearLocation: f.city == city,
                )),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Liste ─────────────────────────────────────────────────────────────

class _PartList extends StatelessWidget {
  final List<Part> parts;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollCtrl;
  const _PartList({
    required this.parts,
    required this.total,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollCtrl,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Text(
              '$total résultat${total > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        SliverList.separated(
          itemCount: parts.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
          itemBuilder: (_, i) => _PartTile(part: parts[i]),
        ),
        // Spinner "chargement suivant"
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        // Message "tout chargé"
        if (!hasMore && parts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '— $total résultat${total > 1 ? 's' : ''} au total —',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PartTile extends ConsumerStatefulWidget {
  final Part part;
  const _PartTile({required this.part});

  @override
  ConsumerState<_PartTile> createState() => _PartTileState();
}

class _PartTileState extends ConsumerState<_PartTile> {
  bool _toggling = false;

  Future<void> _toggle() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ref
          .read(catalogRepositoryProvider)
          .togglePartAvailability(widget.part.id);
      ref.read(partListProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final isStaff   = ref.watch(authProvider).isStaff;
    final part      = widget.part;
    final typeLabel = _typeLabels[part.type] ?? part.type.toUpperCase();
    final condColor = _conditionColors[part.condition] ?? Colors.grey;

    // Compatibilité avec le véhicule du garage sélectionné.
    // Sentinel -1 → retourne un Set vide immédiatement (pas d'appel API).
    final selectedVehicle = ref.watch(selectedGarageVehicleProvider);
    final idsAsync = ref.watch(
      compatiblePartIdsProvider(selectedVehicle?.id ?? -1),
    );
    final isCompatible = selectedVehicle != null &&
        (idsAsync.valueOrNull?.contains(part.id) ?? false);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: part.isOem ? cs.primaryContainer : cs.secondaryContainer,
        child: Text(
          typeLabel.substring(0, 1),
          style: TextStyle(
            color: part.isOem ? cs.onPrimaryContainer : cs.onSecondaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(part.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text.rich(
        TextSpan(
          children: [
            if (part.sku != null)
              TextSpan(
                text: part.sku,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            if (part.categoryName != null) ...[
              const TextSpan(text: ' · '),
              TextSpan(text: part.categoryName!),
            ],
          ],
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: cs.outline),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatXofShort(part.pricing.sellingPrice),
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge compatibilité garage (visible uniquement si compatible)
              if (isCompatible) ...[
                Icon(Icons.check_circle, size: 12, color: Colors.green),
                const SizedBox(width: 3),
              ],
              // Pastille état (neuf / reconditionné / occasion)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: condColor,
                  shape: BoxShape.circle,
                ),
              ),
              // Badge disponibilité (tappable pour le staff)
              _toggling
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : GestureDetector(
                      onTap: isStaff ? _toggle : null,
                      child: _AvailabilityBadge(isAvailable: part.stock.isAvailable),
                    ),
            ],
          ),
        ],
      ),
      onTap: () => context.push('/parts/${part.id}', extra: part),
    );
  }
}

/// Badge "Disponible" / "Indisponible" — tappable pour le staff.
class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withValues(alpha: 0.12)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAvailable ? 'Disponible' : 'Indisponible',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isAvailable ? Colors.green.shade700 : cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Bannière "Filtrer pour mon véhicule" ─────────────────────────────

/// Affichée pour les clients connectés ayant au moins un véhicule au garage.
/// Permet de sélectionner un véhicule et d'accéder directement à ses pièces
/// compatibles via [CompatiblePartsPage].
class _GarageFilterBanner extends ConsumerStatefulWidget {
  const _GarageFilterBanner();

  @override
  ConsumerState<_GarageFilterBanner> createState() =>
      _GarageFilterBannerState();
}

class _GarageFilterBannerState extends ConsumerState<_GarageFilterBanner> {
  OwnedVehicle? _selected;

  @override
  void initState() {
    super.initState();
    // Initialise le provider au premier véhicule après le premier frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vehicles = ref.read(garageProvider).valueOrNull;
      if (vehicles != null && vehicles.isNotEmpty) {
        final v = vehicles.first;
        setState(() => _selected = v);
        ref.read(selectedGarageVehicleProvider.notifier).state = v;
      }
    });
  }

  @override
  void dispose() {
    // Efface le filtre actif quand on quitte la page des pièces.
    ref.read(selectedGarageVehicleProvider.notifier).state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs          = Theme.of(context).colorScheme;
    final garageAsync = ref.watch(garageProvider);
    final vehicles    = garageAsync.valueOrNull;

    // Ne rien afficher si le garage est vide, en erreur (non connecté) ou en chargement.
    if (vehicles == null || vehicles.isEmpty) return const SizedBox.shrink();

    // Resync local state si le véhicule sélectionné a été supprimé du garage.
    if (_selected == null || !vehicles.any((v) => v.id == _selected!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final v = vehicles.first;
        setState(() => _selected = v);
        ref.read(selectedGarageVehicleProvider.notifier).state = v;
      });
      return const SizedBox.shrink(); // évite le flash d'un état incohérent
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.directions_car_outlined, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<OwnedVehicle>(
                  value: _selected,
                  isExpanded: true,
                  style: Theme.of(context).textTheme.bodyMedium,
                  items: vehicles
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v.displayName,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selected = v);
                    ref.read(selectedGarageVehicleProvider.notifier).state = v;
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => context.push('/garage/${_selected!.id}/parts'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Pièces compatibles'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── États vide / erreur ──────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.settings_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        const Text('Aucune pièce trouvée'),
      ],
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off, size: 48),
        const SizedBox(height: 12),
        Text(error, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    ),
  );
}
