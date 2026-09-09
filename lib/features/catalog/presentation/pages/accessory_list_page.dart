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

// ── Grille décalée ───────────────────────────────────────────────

// Hauteur unique : voir la note identique sur la page des pieces.
const _imgHeight = 118.0;

// Icônes par catégorie d'accessoire
const _categoryIcons = <String, IconData>{
  'esthetique':  Icons.auto_awesome,
  'confort':     Icons.airline_seat_recline_normal,
  'securite':    Icons.shield_outlined,
  'multimedia':  Icons.speaker_outlined,
  'utilitaire':  Icons.build_outlined,
};

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
        SliverToBoxAdapter(
          child: _StaggeredAccessoryGrid(accessories: accessories),
        ),
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
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

class _StaggeredAccessoryGrid extends StatelessWidget {
  final List<Accessory> accessories;
  const _StaggeredAccessoryGrid({required this.accessories});

  @override
  Widget build(BuildContext context) {
    final left  = <(Accessory, double)>[];
    final right = <(Accessory, double)>[];
    for (int i = 0; i < accessories.length; i++) {
      const h = _imgHeight;
      if (i.isEven) left.add((accessories[i], h));
      else          right.add((accessories[i], h));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(children: left.map((e) =>
                _AccessoryCard(accessory: e.$1, imageHeight: e.$2)).toList()),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(children: right.map((e) =>
                _AccessoryCard(accessory: e.$1, imageHeight: e.$2)).toList()),
          ),
        ],
      ),
    );
  }
}

class _AccessoryCard extends ConsumerStatefulWidget {
  final Accessory accessory;
  final double imageHeight;
  const _AccessoryCard({required this.accessory, required this.imageHeight});

  @override
  ConsumerState<_AccessoryCard> createState() => _AccessoryCardState();
}

class _AccessoryCardState extends ConsumerState<_AccessoryCard> {
  bool _toggling = false;

  Future<void> _toggle() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ref.read(catalogRepositoryProvider)
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.hardEdge,
      elevation: 1.5,
      shadowColor: cs.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/accessories/${accessory.id}', extra: accessory),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Zone image ─────────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: widget.imageHeight,
                  width: double.infinity,
                  child: accessory.coverUrl != null
                      ? Image.network(accessory.coverUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _AccessoryPlaceholder(accessory: accessory, cs: cs))
                      : _AccessoryPlaceholder(accessory: accessory, cs: cs),
                ),
                if (isStaff)
                  Positioned(
                    top: 6, right: 6,
                    child: _toggling
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : GestureDetector(
                            onTap: _toggle,
                            child: _SmallAvailabilityBadge(
                                isAvailable: accessory.stock.isAvailable),
                          ),
                  ),
              ],
            ),

            // ── Infos ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(accessory.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  if (accessory.categoryLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(accessory.categoryLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: cs.outline),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    formatXofShort(accessory.pricing.sellingPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      fontSize: 13,
                    ),
                  ),
                  if (!isStaff) ...[
                    const SizedBox(height: 4),
                    _AvailabilityBadge(isAvailable: accessory.stock.isAvailable),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder dégradé pour accessoire sans photo.
class _AccessoryPlaceholder extends StatelessWidget {
  final Accessory accessory;
  final ColorScheme cs;
  const _AccessoryPlaceholder({required this.accessory, required this.cs});

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcons[accessory.categoryValue] ?? Icons.inventory_2_outlined;
    return Container(
      // `tertiary` est le lavande que Material derive du seed bleu ardoise :
      // il n'appartient pas a la gamme de la marque. On reste sur les surfaces
      // neutres, qui laissent l'icone et le texte porter l'information.
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest,
            cs.surfaceContainerHigh,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // La categorie figure deja en sous-titre de la carte : la repeter
            // ici affichait « Securite » sous « Securite ». Seule l'icone reste.
            Icon(icon, size: 30, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Petit badge vert/rouge en overlay (staff).
class _SmallAvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _SmallAvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: (isAvailable ? Colors.green : Colors.red).withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      isAvailable ? '✓' : '✗',
      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );
}

/// Badge "Disponible" / "Indisponible" — tappable pour le staff.
class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    // Une information portee par 100 % des cartes n'en est plus une : seule
    // l'indisponibilite merite d'etre signalee.
    if (isAvailable) return const SizedBox.shrink();

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
