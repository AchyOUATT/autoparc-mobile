import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog_repository.dart';
import '../../data/models/accessory.dart';
import '../providers/catalog_providers.dart';
import '../../../../shared/models/paged_state.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/cart/presentation/pages/cart_page.dart';
import '../../../../features/notifications/presentation/widgets/notification_icon_button.dart';
import '../../../../features/vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../../../core/providers/shell_scaffold_provider.dart';

const _categories = [
  (value: 'esthetique',  label: 'Esthétique',  icon: Icons.auto_awesome),
  (value: 'confort',     label: 'Confort',      icon: Icons.airline_seat_recline_normal),
  (value: 'securite',    label: 'Sécurité',     icon: Icons.shield),
  (value: 'multimedia',  label: 'Multimédia',   icon: Icons.speaker),
  (value: 'utilitaire',  label: 'Utilitaire',   icon: Icons.build),
];

class AccessoryListPage extends ConsumerStatefulWidget {
  const AccessoryListPage({super.key});

  @override
  ConsumerState<AccessoryListPage> createState() => _AccessoryListPageState();
}

class _AccessoryListPageState extends ConsumerState<AccessoryListPage> {
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
      ref.read(accessoryListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paged   = ref.watch(accessoryListProvider);
    final filter  = ref.watch(accessoryFilterProvider);
    final cities  = ref.watch(catalogRefsProvider).valueOrNull?.cities ?? const <String>[];
    final isStaff = ref.watch(authProvider).isStaff;

    return Scaffold(
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/accessories/new');
                ref.read(accessoryListProvider.notifier).refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouvel accessoire'),
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
        title: const Text('Accessoires'),
        actions: [
          const NotificationIconButton(),
          if (!isStaff) ...[
            IconButton(
              icon: const Icon(Icons.inbox_outlined),
              tooltip: 'Exprimer un besoin',
              onPressed: () => context.push('/needs/new?type=accessory'),
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
              hintText: 'Nom ou SKU…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(accessoryFilterProvider.notifier)
                          .state = filter.copyWith(clearSearch: true);
                    },
                  ),
              ],
              onChanged: (q) => ref.read(accessoryFilterProvider.notifier)
                  .state = filter.copyWith(search: q.isEmpty ? null : q),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          _FilterBar(filter: filter, cities: cities),
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
  final PagedState<Accessory> paged;
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
        onRetry: () => ref.read(accessoryListProvider.notifier).refresh(),
      );
    }
    if (paged.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(accessoryListProvider.notifier).refresh(),
      child: _AccessoryList(
        accessories: paged.items,
        total: paged.total,
        hasMore: paged.hasMore,
        isLoadingMore: paged.isLoadingMore,
        scrollCtrl: scrollCtrl,
      ),
    );
  }
}

// ── Barre de filtres ─────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  final AccessoryFilter filter;
  final List<String> cities;
  const _FilterBar({required this.filter, required this.cities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(AccessoryFilter Function(AccessoryFilter) fn) {
      ref.read(accessoryFilterProvider.notifier).state =
          fn(ref.read(accessoryFilterProvider));
    }

    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        children: [
          // Chips de catégorie
          ..._categories.map((cat) {
            final selected = filter.category == cat.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(cat.icon, size: 16),
                label: Text(cat.label),
                selected: selected,
                onSelected: (_) => update((f) => f.copyWith(
                  category:      selected ? null : cat.value,
                  clearCategory: selected,
                )),
              ),
            );
          }),
          // Chips de ville
          if (cities.isNotEmpty)
            const VerticalDivider(width: 16, indent: 8, endIndent: 8),
          for (final city in cities)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: const Icon(Icons.location_on_outlined, size: 14),
                label: Text(city),
                selected: filter.city == city,
                onSelected: (_) => update((f) => f.copyWith(
                  city:          f.city == city ? null : city,
                  clearCity:     f.city == city,
                  clearLocation: f.city == city,
                )),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Liste d'accessoires ──────────────────────────────────────────

class _AccessoryList extends StatelessWidget {
  final List<Accessory> accessories;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollCtrl;
  const _AccessoryList({
    required this.accessories,
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
          itemCount: accessories.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (_, i) => _AccessoryTile(accessory: accessories[i]),
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
        if (!hasMore && accessories.isNotEmpty)
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

class _AccessoryTile extends ConsumerStatefulWidget {
  final Accessory accessory;
  const _AccessoryTile({required this.accessory});

  @override
  ConsumerState<_AccessoryTile> createState() => _AccessoryTileState();
}

class _AccessoryTileState extends ConsumerState<_AccessoryTile> {
  bool _toggling = false;

  Future<void> _toggle() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ref
          .read(catalogRepositoryProvider)
          .toggleAccessoryAvailability(widget.accessory.id);
      ref.read(accessoryListProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final isStaff   = ref.watch(authProvider).isStaff;
    final accessory = widget.accessory;
    final p         = accessory.pricing;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        child: Text(
          accessory.categoryValue[0].toUpperCase(),
          style: TextStyle(color: cs.onPrimaryContainer),
        ),
      ),
      title: Text(accessory.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          accessory.manufacturer,
          accessory.categoryLabel,
        ].where((s) => s != null).join(' · '),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatXofShort(p.sellingPrice),
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
          ),
          const SizedBox(height: 4),
          _toggling
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : GestureDetector(
                  onTap: isStaff ? _toggle : null,
                  child: _AvailabilityBadge(
                      isAvailable: accessory.stock.isAvailable),
                ),
        ],
      ),
      onTap: () =>
          context.push('/accessories/${accessory.id}', extra: accessory),
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
            ? Colors.green.withOpacity(0.12)
            : cs.surfaceVariant,
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

// ── États vide / erreur ─────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        const Text('Aucun accessoire trouvé'),
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
