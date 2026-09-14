import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalog_repository.dart';
import '../../data/models/part.dart';
import '../../data/models/part_category.dart';
import '../providers/catalog_providers.dart';
import '../../../../shared/models/paged_state.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../../core/widgets/catalog_image.dart';
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
    final auth    = ref.watch(authProvider);
    final isStaff = auth.isStaff;

    return Scaffold(
      // Un magasinier ou un observateur n'a pas le droit de creer une fiche :
      // le bouton disparait plutot que de renvoyer un 403.
      floatingActionButton: auth.canManageCatalog
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

    // La barre ne contenait que des villes. Aucune n'etant renseignee, elle
    // s'affichait vide — 48 dp de rien — alors que la page presente 200
    // references sans aucun moyen de les trier par nature. Les accessoires,
    // eux, ont leurs categories pour seulement 80 articles.
    //
    // Seules les racines sont proposées : l'arbre compte 89 entrées sur trois
    // niveaux, une barre de 89 puces serait interminable. Le serveur inclut
    // les descendantes dans le filtre, donc « Freinage » couvre bien disques,
    // plaquettes et flexibles — auxquels les pièces sont réellement rattachées.
    final categories = (ref.watch(partCategoriesProvider).valueOrNull ??
            const <PartCategory>[])
        .where((c) => c.isRoot)
        .toList();

    if (categories.isEmpty && cities.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 48,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        children: [
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c.name),
                selected: filter.categoryId == c.id,
                onSelected: (_) => update((f) => f.categoryId == c.id
                    ? f.copyWith(clearCategory: true)
                    : f.copyWith(categoryId: c.id)),
              ),
            ),

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

// ── Grille décalée ───────────────────────────────────────────────────

// Hauteurs d'image qui alternent pour l'effet masonry
// Hauteur unique : des vignettes de tailles differentes decalaient les deux
// colonnes, si bien que les prix ne s'alignaient jamais d'une carte a l'autre.
// Sur un catalogue ou l'on compare des prix, c'est une gene, pas un effet.
const _imgHeight = 118.0;

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
        SliverToBoxAdapter(
          child: _StaggeredPartsGrid(parts: parts),
        ),
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
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

class _StaggeredPartsGrid extends StatelessWidget {
  final List<Part> parts;
  const _StaggeredPartsGrid({required this.parts});

  @override
  Widget build(BuildContext context) {
    final left  = <(Part, double)>[];
    final right = <(Part, double)>[];
    for (int i = 0; i < parts.length; i++) {
      const h = _imgHeight;
      if (i.isEven) left.add((parts[i], h));
      else          right.add((parts[i], h));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(children: left.map((e) =>
                _PartCard(part: e.$1, imageHeight: e.$2)).toList()),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(children: right.map((e) =>
                _PartCard(part: e.$1, imageHeight: e.$2)).toList()),
          ),
        ],
      ),
    );
  }
}

class _PartCard extends ConsumerStatefulWidget {
  final Part part;
  final double imageHeight;
  const _PartCard({required this.part, required this.imageHeight});

  @override
  ConsumerState<_PartCard> createState() => _PartCardState();
}

class _PartCardState extends ConsumerState<_PartCard> {
  bool _toggling = false;

  Future<void> _toggle() async {
    if (_toggling) return;
    setState(() => _toggling = true);
    try {
      await ref.read(catalogRepositoryProvider).togglePartAvailability(widget.part.id);
      ref.read(partListProvider.notifier).refresh();
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final auth      = ref.watch(authProvider);
    final isStaff   = auth.isStaff;
    final part      = widget.part;
    final typeLabel = _typeLabels[part.type] ?? part.type.toUpperCase();

    final selectedVehicle = ref.watch(selectedGarageVehicleProvider);
    final idsAsync = ref.watch(compatiblePartIdsProvider(selectedVehicle?.id ?? -1));
    final isCompatible = selectedVehicle != null &&
        (idsAsync.valueOrNull?.contains(part.id) ?? false);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.hardEdge,
      elevation: 1.5,
      shadowColor: cs.shadow.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/parts/${part.id}', extra: part),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Zone image ─────────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: widget.imageHeight,
                  width: double.infinity,
                  child: part.coverUrl != null
                      ? CatalogImage(
                          url: part.coverUrl!,
                          fallback: _PartPlaceholder(
                              type: typeLabel, isOem: part.isOem, cs: cs),
                        )
                      : _PartPlaceholder(type: typeLabel, isOem: part.isOem, cs: cs),
                ),
                // Bascule de disponibilite : reservee aux roles qui tiennent le
                // stock (direction et magasin), pas a tout le personnel.
                if (auth.canManageStock)
                  Positioned(
                    top: 6, right: 6,
                    child: _toggling
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : GestureDetector(
                            onTap: _toggle,
                            child: _SmallAvailabilityBadge(isAvailable: part.stock.isAvailable),
                          ),
                  ),
                if (isCompatible)
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
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
                  Text(part.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  if (part.categoryName != null) ...[
                    const SizedBox(height: 2),
                    Text(part.categoryName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: cs.outline),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    formatXofShort(part.pricing.sellingPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      fontSize: 13,
                    ),
                  ),
                  if (!isStaff) ...[
                    const SizedBox(height: 4),
                    _AvailabilityBadge(isAvailable: part.stock.isAvailable),
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

/// Placeholder dégradé pour pièce sans photo.
class _PartPlaceholder extends StatelessWidget {
  final String type;
  final bool isOem;
  final ColorScheme cs;
  const _PartPlaceholder({required this.type, required this.isOem, required this.cs});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isOem
          ? [cs.primaryContainer, cs.primary.withValues(alpha: 0.45)]
          : [cs.secondaryContainer, cs.secondary.withValues(alpha: 0.35)],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_outlined, size: 30,
              color: isOem ? cs.onPrimaryContainer : cs.onSecondaryContainer),
          const SizedBox(height: 4),
          Text(type,
            style: TextStyle(
              color: isOem ? cs.onPrimaryContainer : cs.onSecondaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Petit badge disponibilité en overlay (staff).
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

  /// Restreint la liste aux pièces compatibles avec le véhicule choisi.
  ///
  /// Le filtrage est fait par le serveur : `getParts` bascule sur la route
  /// des pièces compatibles dès qu'un `vehicleModelId` lui est passé. Filtrer
  /// localement la page courante donnerait des pages de deux résultats et une
  /// pagination incohérente.
  bool _onlyCompatible = false;

  void _applyCompatibleFilter(bool on) {
    setState(() => _onlyCompatible = on);

    final filter = ref.read(partFilterProvider);
    ref.read(partFilterProvider.notifier).state = on && _selected != null
        ? filter.copyWith(vehicleModelId: _selected!.vehicleModelId)
        : filter.copyWith(clearVehicleModel: true);
  }

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
    // Efface le filtre actif quand on quitte la page des pièces — sans quoi
    // on retrouverait la liste silencieusement restreinte à un véhicule.
    ref.read(selectedGarageVehicleProvider.notifier).state = null;
    ref.read(partFilterProvider.notifier).state =
        ref.read(partFilterProvider).copyWith(clearVehicleModel: true);
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
                    // Changer de véhicule alors que le filtre est actif doit
                    // relancer la recherche sur le nouveau, pas conserver
                    // silencieusement les pièces du précédent.
                    if (_onlyCompatible) _applyCompatibleFilter(true);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Filtrer sur place plutôt qu'ouvrir un second écran : le véhicule
            // est déjà choisi ici, et la liste sait déjà quelles pièces lui
            // correspondent. Partir ailleurs faisait perdre la recherche, la
            // catégorie et la ville déjà saisies.
            FilterChip(
              label: const Text('Compatibles'),
              selected: _onlyCompatible,
              onSelected: (on) => _applyCompatibleFilter(on),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// ── États vide / erreur ──────────────────────────────────────────────

/// Aucun résultat — en nommant les filtres qui l'expliquent.
///
/// « Aucune pièce trouvée » laissait chercher lequel des quatre critères
/// actifs est de trop. Le catalogue compte 200 pièces : quand l'écran est
/// vide, c'est presque toujours un filtre, pas un catalogue vide.
class _EmptyView extends ConsumerWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs      = Theme.of(context).colorScheme;
    final filtre  = ref.watch(partFilterProvider);
    final actifs  = <String>[
      if (filtre.search?.isNotEmpty == true) '« ${filtre.search} »',
      if (filtre.oem?.isNotEmpty == true)    'référence OEM',
      if (filtre.categoryId != null)         'une catégorie',
      if (filtre.vehicleModelId != null)     'compatibilité véhicule',
      if (filtre.city != null)               filtre.city!,
      if (filtre.inStockOnly)                'en stock',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.settings_outlined, size: 56, color: cs.outline),
            const SizedBox(height: 14),
            Text(
              'Aucune pièce trouvée',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (actifs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Filtres actifs : ${actifs.join(', ')}.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(partFilterProvider.notifier).state = const PartFilter(),
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Tout effacer'),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Le catalogue ne contient aucune pièce pour le moment.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            TextButton.icon(
              onPressed: () => context.push('/needs/new?type=part'),
              icon: const Icon(Icons.inbox_outlined, size: 18),
              label: const Text('Dites-nous ce que vous cherchez'),
            ),
          ],
        ),
      ),
    );
  }
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
