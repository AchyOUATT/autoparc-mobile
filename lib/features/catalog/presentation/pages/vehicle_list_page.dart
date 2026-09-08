import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/vehicle.dart';
import '../providers/catalog_providers.dart';
import '../../../../shared/models/paged_state.dart';
import '../../../../core/utils/currency_format.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/presentation/providers/vehicle_refs_provider.dart';
import '../../../notifications/presentation/widgets/notification_icon_button.dart';
import '../../../../core/providers/shell_scaffold_provider.dart';

class VehicleListPage extends ConsumerStatefulWidget {
  const VehicleListPage({super.key});

  @override
  ConsumerState<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends ConsumerState<VehicleListPage> {
  final _searchCtrl  = TextEditingController();
  final _scrollCtrl  = ScrollController();

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
      ref.read(vehicleListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paged   = ref.watch(vehicleListProvider);
    final filter  = ref.watch(vehicleFilterProvider);
    final cities  = ref.watch(catalogRefsProvider).valueOrNull?.cities ?? const <String>[];
    final isStaff = ref.watch(authProvider).isStaff;

    return Scaffold(
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              onPressed: () async {
                final added = await context.push<bool>('/vehicles/new');
                if (added == true) {
                  ref.read(vehicleListProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
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
        title: const Text('Véhicules'),
        actions: [
          const NotificationIconButton(),
          if (!isStaff)
            IconButton(
              icon: const Icon(Icons.inbox_outlined),
              tooltip: 'Exprimer un besoin',
              onPressed: () => context.push('/needs/new?type=vehicle'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Marque, modèle, référence…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(vehicleFilterProvider.notifier)
                          .state = filter.copyWith(clearSearch: true);
                    },
                  ),
              ],
              onChanged: (q) => ref.read(vehicleFilterProvider.notifier)
                  .state = filter.copyWith(search: q.isEmpty ? null : q),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          _FilterChips(filter: filter, cities: cities),
          _BodyStyleChips(filter: filter),
          Expanded(
            child: _Body(paged: paged, scrollCtrl: _scrollCtrl),
          ),
        ],
      ),
    );
  }
}

// ── Corps principal ─────────────────────────────────────────────

class _Body extends ConsumerWidget {
  final PagedState<Vehicle> paged;
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
        onRetry: () => ref.read(vehicleListProvider.notifier).refresh(),
      );
    }
    if (paged.isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(vehicleListProvider.notifier).refresh(),
      child: _VehicleGrid(
        vehicles: paged.items,
        total: paged.total,
        hasMore: paged.hasMore,
        isLoadingMore: paged.isLoadingMore,
        scrollCtrl: scrollCtrl,
      ),
    );
  }
}

// ── Chips filtre (Vente / Location / Ville) ──────────────────────

class _FilterChips extends ConsumerWidget {
  final VehicleFilter filter;
  final List<String> cities;
  const _FilterChips({required this.filter, required this.cities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(VehicleFilter Function(VehicleFilter) fn) {
      ref.read(vehicleFilterProvider.notifier).state =
          fn(ref.read(vehicleFilterProvider));
    }

    return _ChipRow(
      children: [
        const _GroupLabel('Offre'),
        FilterChip(
          label: const Text('À vendre'),
          selected: filter.availability == 'sale',
          onSelected: (_) => update((f) => f.copyWith(
            availability: f.availability == 'sale' ? null : 'sale',
            clearAvailability: f.availability == 'sale',
          )),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('À louer'),
          selected: filter.availability == 'rent',
          onSelected: (_) => update((f) => f.copyWith(
            availability: f.availability == 'rent' ? null : 'rent',
            clearAvailability: f.availability == 'rent',
          )),
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('Neuf'),
          selected: filter.condition == 'new',
          onSelected: (_) => update((f) => f.condition == 'new'
              ? f.copyWith(clearCondition: true)
              : f.copyWith(condition: 'new')),
        ),
        const SizedBox(width: 20),
        const _GroupLabel('Type'),
        FilterChip(
          avatar: const Icon(Icons.airport_shuttle_outlined, size: 14),
          label: const Text('Utilitaire'),
          selected: filter.vehicleType == 'utility',
          onSelected: (_) => update((f) => f.copyWith(
            vehicleType: f.vehicleType == 'utility' ? null : 'utility',
            clearVehicleType: f.vehicleType == 'utility',
          )),
        ),
        const SizedBox(width: 8),
        FilterChip(
          avatar: const Icon(Icons.local_shipping_outlined, size: 14),
          label: const Text('Poids lourd'),
          selected: filter.vehicleType == 'heavy',
          onSelected: (_) => update((f) => f.copyWith(
            vehicleType: f.vehicleType == 'heavy' ? null : 'heavy',
            clearVehicleType: f.vehicleType == 'heavy',
          )),
        ),
        if (cities.isNotEmpty) ...[
          const SizedBox(width: 20),
          const _GroupLabel('Ville'),
          for (final city in cities) ...[
            FilterChip(
              avatar: const Icon(Icons.location_on_outlined, size: 14),
              label: Text(city),
              selected: filter.city == city,
              onSelected: (_) => update((f) => f.copyWith(
                city: f.city == city ? null : city,
                clearCity: f.city == city,
                clearLocation: f.city == city,
              )),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ],
    );
  }
}

/// Rangée de puces défilante horizontalement.
///
/// Le dégradé sur les bords remplace la coupe nette : une puce à moitié
/// estompée se lit comme « ça continue », pas comme un défaut d'affichage.
class _ChipRow extends StatelessWidget {
  final List<Widget> children;
  const _ChipRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0, 0.03, 0.92, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          scrollDirection: Axis.horizontal,
          children: children,
        ),
      ),
    );
  }
}

/// Intitulé d'un groupe de filtres — distingue les taxonomies
/// (offre commerciale, type de véhicule, ville, carrosserie) que le
/// style uniforme des puces confondait.
class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    ),
  );
}

// ── Chips carrosserie ────────────────────────────────────────────

const _bodyStyles = [
  (value: 'sedan',       label: 'Berline',     icon: Icons.directions_car),
  (value: 'suv',         label: 'SUV / 4×4',   icon: Icons.directions_car_filled),
  (value: 'hatchback',   label: 'Citadine',    icon: Icons.directions_car_outlined),
  (value: 'pickup',      label: 'Pickup',      icon: Icons.fire_truck),
  (value: 'minibus',     label: 'Minibus',     icon: Icons.airport_shuttle),
  (value: 'bus',         label: 'Bus / Car',   icon: Icons.directions_bus),
  (value: 'van',         label: 'Fourgon',     icon: Icons.local_shipping),
  (value: 'estate',      label: 'Break',       icon: Icons.drive_eta),
  (value: 'truck',       label: 'Camion',      icon: Icons.local_shipping_outlined),
  (value: 'convertible', label: 'Cabriolet',   icon: Icons.wb_sunny_outlined),
  (value: 'coupe',       label: 'Coupé',       icon: Icons.speed),
];

class _BodyStyleChips extends ConsumerWidget {
  final VehicleFilter filter;
  const _BodyStyleChips({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChipRow(
      children: [
        const _GroupLabel('Carrosserie'),
        ..._bodyStyles.map((s) {
          final selected = filter.bodyStyle == s.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(s.icon, size: 14),
              label: Text(s.label),
              selected: selected,
              onSelected: (_) {
                ref.read(vehicleFilterProvider.notifier).state =
                    filter.copyWith(
                      bodyStyle: selected ? null : s.value,
                      clearBodyStyle: selected,
                    );
              },
            ),
          );
        }),
      ],
    );
  }
}

// ── Grille de véhicules ─────────────────────────────────────────

class _VehicleGrid extends StatelessWidget {
  final List<Vehicle> vehicles;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollCtrl;
  const _VehicleGrid({
    required this.vehicles,
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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
          sliver: SliverToBoxAdapter(
            child: Text(
              '$total résultat${total > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              // 0.92 au lieu de 0.72 : sans photos réelles, le placeholder
              // mangeait la moitié de l'écran pour une icône générique.
              childAspectRatio: 0.92,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: vehicles.length,
            itemBuilder: (_, i) => _VehicleCard(vehicle: vehicles[i]),
          ),
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
        if (!hasMore && vehicles.isNotEmpty)
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
        // Dégage la dernière rangée de la barre de navigation et du FAB.
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

// ── Carte véhicule ──────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final c  = vehicle.commercial;
    final id = vehicle.identity;
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/vehicles/${vehicle.id}', extra: vehicle),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  vehicle.mediaUrls.isEmpty
                      ? Container(
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.directions_car, size: 40, color: cs.outline),
                        )
                      : Image.network(vehicle.mediaUrls.first, fit: BoxFit.cover),

                  Positioned(
                    top: 8, left: 8,
                    child: _AvailabilityBadge(vehicle: vehicle),
                  ),

                  if (vehicle.isImported && vehicle.import_ != null)
                    Positioned(
                      top: 8, right: 8,
                      // Statut douanier : information d'une autre nature que
                      // la disponibilité commerciale. Style ajouré plutôt que
                      // plein, pour ne pas se confondre avec le badge de
                      // gauche quand les deux cohabitent sur une même carte.
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: vehicle.import_!.customsCleared
                                ? const Color(0xFF2E6F6B)
                                : const Color(0xFFB26A00),
                          ),
                        ),
                        child: Text(
                          vehicle.import_!.customsCleared ? 'Dédouané' : 'En attente',
                          style: TextStyle(
                            color: vehicle.import_!.customsCleared
                                ? const Color(0xFF2E6F6B)
                                : const Color(0xFFB26A00),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Textes d'identification. Les deux lignes secondaires
                    // occupent une hauteur fixe même vides : sinon une fiche
                    // sans finition ou sans ville remonte son prix et se
                    // désaligne de la carte voisine.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          id.fullName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height: 16,
                          child: id.trim == null
                              ? null
                              : Text(
                                  id.trim!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: cs.outline),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        SizedBox(
                          height: 16,
                          child: c.locationLabel == null
                              ? null
                              : Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 12, color: cs.outline),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        c.locationLabel!,
                                        style: Theme.of(context).textTheme.bodySmall
                                            ?.copyWith(color: cs.outline),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                    // Prix toujours en bas
                    _PriceRow(commercial: c),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final Vehicle vehicle;
  const _AvailabilityBadge({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final c  = vehicle.commercial;
    final cs = Theme.of(context).colorScheme;
    // Palette explicite plutôt que les rôles du ColorScheme : le thème naît
    // d'un seed bleu ardoise, dont Material dérive un `secondary` désaturé
    // (le badge se lisait comme « indisponible ») et un `tertiary` lavande
    // étranger à la marque. Ces trois tons sont profonds et désaturés comme
    // le bleu de marque, et restent distincts entre eux.
    final (label, bg) = switch (c.availability) {
      'both' => ('Vente & Location', const Color(0xFF2E6F6B)), // sarcelle
      'sale' => ('À vendre',         const Color(0xFF1F5C7A)), // ardoise
      'rent' => ('À louer',          const Color(0xFFB26A00)), // ocre
      _      => ('Indisponible',     cs.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final VehicleCommercial commercial;
  const _PriceRow({required this.commercial});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.primary,
    );
    if (commercial.isForSale && commercial.salePrice != null) {
      return Text(formatXofShort(commercial.salePrice), style: style);
    }
    if (commercial.isForRent && commercial.rentalDailyRate != null) {
      return Text('${formatXofShort(commercial.rentalDailyRate)}/j', style: style);
    }
    return Text('Prix non communiqué',
      style: Theme.of(context).textTheme.bodySmall);
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
        Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        const Text('Aucun véhicule trouvé'),
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
