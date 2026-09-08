import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog_repository.dart';
import '../../data/models/vehicle.dart';
import '../../data/models/accessory.dart';
import '../../data/models/part.dart';
import '../../data/models/part_category.dart';
import '../../data/models/manufacturer.dart';
import '../../../../features/garage/data/garage_repository.dart';
import '../../../../features/garage/data/models/garage_compatibility.dart';
import '../../../../shared/models/paged_state.dart';

// ════════════════════════════════════════════════════════════════
// FILTRES
// ════════════════════════════════════════════════════════════════

class VehicleFilter {
  final String? search;
  final String? availability; // null | 'sale' | 'rent'
  final String? condition;
  final String? vehicleType;  // null | 'passenger' | 'utility' | 'heavy'
  final String? bodyStyle;    // null | 'sedan' | 'suv' | 'pickup' | 'minibus' | 'bus' | …
  final int? yearMin;
  final int? yearMax;
  final double? priceMax;
  final String? city;
  final int? locationId;
  final bool? customsCleared; // true = uniquement les importés dédouanés

  const VehicleFilter({
    this.search,
    this.availability,
    this.condition,
    this.vehicleType,
    this.bodyStyle,
    this.yearMin,
    this.yearMax,
    this.priceMax,
    this.city,
    this.locationId,
    this.customsCleared,
  });

  VehicleFilter copyWith({
    String? search,
    String? availability,
    String? condition,
    String? vehicleType,
    String? bodyStyle,
    int? yearMin,
    int? yearMax,
    double? priceMax,
    String? city,
    int? locationId,
    bool? customsCleared,
    bool clearSearch = false,
    bool clearAvailability = false,
    bool clearCondition = false,
    bool clearVehicleType = false,
    bool clearBodyStyle = false,
    bool clearYearMin = false,
    bool clearYearMax = false,
    bool clearPriceMax = false,
    bool clearCity = false,
    bool clearLocation = false,
    bool clearCustomsCleared = false,
  }) =>
      VehicleFilter(
        search:         clearSearch         ? null : (search       ?? this.search),
        availability:   clearAvailability   ? null : (availability ?? this.availability),
        condition:      clearCondition      ? null : (condition    ?? this.condition),
        vehicleType:    clearVehicleType    ? null : (vehicleType  ?? this.vehicleType),
        bodyStyle:      clearBodyStyle      ? null : (bodyStyle    ?? this.bodyStyle),
        yearMin:        clearYearMin        ? null : (yearMin      ?? this.yearMin),
        yearMax:        clearYearMax        ? null : (yearMax      ?? this.yearMax),
        priceMax:       clearPriceMax       ? null : (priceMax     ?? this.priceMax),
        city:           clearCity           ? null : (city         ?? this.city),
        locationId:     clearLocation       ? null : (locationId   ?? this.locationId),
        customsCleared: clearCustomsCleared ? null : (customsCleared ?? this.customsCleared),
      );
}

final vehicleFilterProvider =
    StateProvider<VehicleFilter>((ref) => const VehicleFilter());

// ─────────────────────────────────────────────────────────────────

class AccessoryFilter {
  final String? search;
  final String? category;
  final double? priceMax;
  final String? city;
  final int?    locationId;

  const AccessoryFilter({
    this.search,
    this.category,
    this.priceMax,
    this.city,
    this.locationId,
  });

  AccessoryFilter copyWith({
    String? search,
    String? category,
    double? priceMax,
    String? city,
    int?    locationId,
    bool clearSearch   = false,
    bool clearCategory = false,
    bool clearCity     = false,
    bool clearLocation = false,
  }) =>
      AccessoryFilter(
        search:     clearSearch   ? null : (search     ?? this.search),
        category:   clearCategory ? null : (category   ?? this.category),
        priceMax:   priceMax      ?? this.priceMax,
        city:       clearCity     ? null : (city       ?? this.city),
        locationId: clearLocation ? null : (locationId ?? this.locationId),
      );
}

final accessoryFilterProvider =
    StateProvider<AccessoryFilter>((ref) => const AccessoryFilter());

// ─────────────────────────────────────────────────────────────────

class PartFilter {
  final String? search;
  final String? oem;
  final int? categoryId;
  final bool inStockOnly;
  final int? vehicleModelId;
  final String? city;
  final int? locationId;

  const PartFilter({
    this.search,
    this.oem,
    this.categoryId,
    this.inStockOnly = false,
    this.vehicleModelId,
    this.city,
    this.locationId,
  });

  PartFilter copyWith({
    String? search,
    String? oem,
    int? categoryId,
    bool? inStockOnly,
    int? vehicleModelId,
    String? city,
    int? locationId,
    bool clearCity = false,
    bool clearLocation = false,
  }) =>
      PartFilter(
        search:        search        ?? this.search,
        oem:           oem           ?? this.oem,
        categoryId:    categoryId    ?? this.categoryId,
        inStockOnly:   inStockOnly   ?? this.inStockOnly,
        vehicleModelId:vehicleModelId?? this.vehicleModelId,
        city:          clearCity     ? null : (city       ?? this.city),
        locationId:    clearLocation ? null : (locationId ?? this.locationId),
      );
}

final partFilterProvider = StateProvider<PartFilter>((ref) => const PartFilter());

// ════════════════════════════════════════════════════════════════
// NOTIFIERS PAGINÉS
// ════════════════════════════════════════════════════════════════

// ── Véhicules ────────────────────────────────────────────────────

final vehicleListProvider =
    AutoDisposeNotifierProvider<VehicleListNotifier, PagedState<Vehicle>>(
  VehicleListNotifier.new,
);

class VehicleListNotifier extends AutoDisposeNotifier<PagedState<Vehicle>> {
  static const _perPage = 20;
  int _page = 0;
  bool _fetching = false;

  @override
  PagedState<Vehicle> build() {
    // Se reconstruit (reset) à chaque changement de filtre
    ref.watch(vehicleFilterProvider);
    _page = 0;
    _fetching = false;
    Future.microtask(_fetchNext);
    return const PagedState.loading();
  }

  Future<void> _fetchNext() async {
    if (_fetching) return;
    _fetching = true;
    final nextPage = _page + 1;
    final isFirst  = nextPage == 1;

    state = state.copyWith(
      isLoading:     isFirst,
      isLoadingMore: !isFirst,
      clearError:    true,
    );

    try {
      final filter = ref.read(vehicleFilterProvider);
      final resp   = await ref.read(catalogRepositoryProvider).getVehicles(
        page:         nextPage,
        perPage:      _perPage,
        search:       filter.search,
        availability: filter.availability,
        condition:    filter.condition,
        vehicleType:  filter.vehicleType,
        bodyStyle:    filter.bodyStyle,
        yearMin:      filter.yearMin,
        yearMax:      filter.yearMax,
        priceMax:     filter.priceMax,
        city:         filter.city,
        locationId:   filter.locationId,
        customsCleared: filter.customsCleared,
      );
      _page = nextPage;
      state = state.copyWith(
        items:         isFirst ? resp.data : [...state.items, ...resp.data],
        total:         resp.total,
        hasMore:       resp.hasNextPage,
        isLoading:     false,
        isLoadingMore: false,
        clearError:    true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:     false,
        isLoadingMore: false,
        error:         e,
      );
    } finally {
      _fetching = false;
    }
  }

  /// Charge la page suivante (appelé quand l'utilisateur approche du bas).
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    await _fetchNext();
  }

  /// Recharge depuis la page 1.
  Future<void> refresh() async {
    _page = 0;
    _fetching = false;
    state = const PagedState.loading();
    await _fetchNext();
  }
}

// ── Accessoires ──────────────────────────────────────────────────

final accessoryListProvider =
    AutoDisposeNotifierProvider<AccessoryListNotifier, PagedState<Accessory>>(
  AccessoryListNotifier.new,
);

class AccessoryListNotifier extends AutoDisposeNotifier<PagedState<Accessory>> {
  static const _perPage = 20;
  int _page = 0;
  bool _fetching = false;

  @override
  PagedState<Accessory> build() {
    ref.watch(accessoryFilterProvider);
    _page = 0;
    _fetching = false;
    Future.microtask(_fetchNext);
    return const PagedState.loading();
  }

  Future<void> _fetchNext() async {
    if (_fetching) return;
    _fetching = true;
    final nextPage = _page + 1;
    final isFirst  = nextPage == 1;

    state = state.copyWith(
      isLoading:     isFirst,
      isLoadingMore: !isFirst,
      clearError:    true,
    );

    try {
      final filter = ref.read(accessoryFilterProvider);
      final resp   = await ref.read(catalogRepositoryProvider).getAccessories(
        page:       nextPage,
        perPage:    _perPage,
        search:     filter.search,
        category:   filter.category,
        priceMax:   filter.priceMax,
        city:       filter.city,
        locationId: filter.locationId,
      );
      _page = nextPage;
      state = state.copyWith(
        items:         isFirst ? resp.data : [...state.items, ...resp.data],
        total:         resp.total,
        hasMore:       resp.hasNextPage,
        isLoading:     false,
        isLoadingMore: false,
        clearError:    true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:     false,
        isLoadingMore: false,
        error:         e,
      );
    } finally {
      _fetching = false;
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    await _fetchNext();
  }

  Future<void> refresh() async {
    _page = 0;
    _fetching = false;
    state = const PagedState.loading();
    await _fetchNext();
  }
}

// ── Pièces détachées ─────────────────────────────────────────────

final partListProvider =
    AutoDisposeNotifierProvider<PartListNotifier, PagedState<Part>>(
  PartListNotifier.new,
);

class PartListNotifier extends AutoDisposeNotifier<PagedState<Part>> {
  static const _perPage = 20;
  int _page = 0;
  bool _fetching = false;

  @override
  PagedState<Part> build() {
    ref.watch(partFilterProvider);
    _page = 0;
    _fetching = false;
    Future.microtask(_fetchNext);
    return const PagedState.loading();
  }

  Future<void> _fetchNext() async {
    if (_fetching) return;
    _fetching = true;
    final nextPage = _page + 1;
    final isFirst  = nextPage == 1;

    state = state.copyWith(
      isLoading:     isFirst,
      isLoadingMore: !isFirst,
      clearError:    true,
    );

    try {
      final filter = ref.read(partFilterProvider);
      final resp   = await ref.read(catalogRepositoryProvider).getParts(
        page:          nextPage,
        perPage:       _perPage,
        search:        filter.search,
        oem:           filter.oem,
        categoryId:    filter.categoryId,
        inStockOnly:   filter.inStockOnly,
        vehicleModelId:filter.vehicleModelId,
        city:          filter.city,
        locationId:    filter.locationId,
      );
      _page = nextPage;
      state = state.copyWith(
        items:         isFirst ? resp.data : [...state.items, ...resp.data],
        total:         resp.total,
        hasMore:       resp.hasNextPage,
        isLoading:     false,
        isLoadingMore: false,
        clearError:    true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading:     false,
        isLoadingMore: false,
        error:         e,
      );
    } finally {
      _fetching = false;
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    await _fetchNext();
  }

  Future<void> refresh() async {
    _page = 0;
    _fetching = false;
    state = const PagedState.loading();
    await _fetchNext();
  }
}

// ════════════════════════════════════════════════════════════════
// PROVIDERS DÉTAIL (inchangés)
// ════════════════════════════════════════════════════════════════

final vehicleDetailProvider =
    FutureProvider.autoDispose.family<Vehicle, int>((ref, id) async {
  return ref.read(catalogRepositoryProvider).getVehicle(id);
});

final accessoryDetailProvider =
    FutureProvider.autoDispose.family<Accessory, int>((ref, id) async {
  return ref.read(catalogRepositoryProvider).getAccessory(id);
});

final partDetailProvider =
    FutureProvider.autoDispose.family<Part, int>((ref, id) async {
  return ref.read(catalogRepositoryProvider).getPart(id);
});

/// Catégories de pièces — chargées une fois.
final partCategoriesProvider =
    FutureProvider<List<PartCategory>>((ref) async {
  return ref.read(catalogRepositoryProvider).getPartCategories();
});

/// Fabricants — chargés une fois.
final manufacturersProvider =
    FutureProvider<List<Manufacturer>>((ref) async {
  return ref.read(catalogRepositoryProvider).getManufacturers();
});

/// IDs des pièces compatibles avec un véhicule du garage — chargés une seule
/// fois et partagés par toutes les tuiles de la liste grâce au cache family.
///
/// Passer [vehicleId] = -1 court-circuite l'appel API et retourne un ensemble vide
/// (évite le watch conditionnel dans les tuiles).
final compatiblePartIdsProvider = FutureProvider.autoDispose
    .family<Set<int>, int>((ref, vehicleId) async {
  if (vehicleId == -1) return const <int>{};
  return ref.read(garageRepositoryProvider).compatiblePartIds(vehicleId);
});

/// Compatibilité d'une pièce avec les véhicules du garage du client connecté.
///
/// Auto-dispose : recalculé à chaque ouverture de la fiche pièce.
/// Erreur silencieuse pour les utilisateurs non connectés (Firebase 401).
final garageCompatibilityProvider = FutureProvider.autoDispose
    .family<List<GarageCompatibility>, int>((ref, partId) async {
  return ref.read(garageRepositoryProvider).checkPartCompatibility(partId);
});
