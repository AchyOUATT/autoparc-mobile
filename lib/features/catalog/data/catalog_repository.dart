import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../shared/models/paginated_response.dart';
import 'models/vehicle.dart';
import 'models/accessory.dart';
import 'models/part.dart';
import 'models/part_category.dart';
import 'models/manufacturer.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.read(apiClientProvider)),
);

/// Accès aux données du catalogue public (pas d'auth requise).
class CatalogRepository {
  final ApiClient _client;
  const CatalogRepository(this._client);

  // ── Véhicules ────────────────────────────────────────────────────

  Future<PaginatedResponse<Vehicle>> getVehicles({
    int page = 1,
    int perPage = 20,
    String? search,
    String? availability, // 'sale' | 'rent' | null (tous)
    String? vehicleType,  // 'passenger' | 'utility' | 'heavy' | null (tous)
    String? bodyStyle,    // 'sedan' | 'suv' | 'pickup' | 'minibus' | 'bus' | … | null
    String? brandId,
    int? yearMin,
    int? yearMax,
    double? priceMax,
    String? condition, // 'new' | 'used' | 'damaged'
    String? originCountryId,
    String? city,       // filtre par ville
    int? locationId,    // filtre par agence précise
    bool? customsCleared, // true = uniquement les importés dédouanés
    bool? deal,           // true = uniquement les véhicules mis en avant
  }) async {
    final params = <String, dynamic>{
      'page':     page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'q': search,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (bodyStyle   != null) 'body_style':   bodyStyle,
      if (brandId != null) 'brand_id': brandId,
      if (yearMin != null) 'year_min': yearMin,
      if (yearMax != null) 'year_max': yearMax,
      if (priceMax != null) 'price_max': priceMax.toInt(),
      if (condition != null) 'condition': condition,
      if (originCountryId != null) 'origin_country_id': originCountryId,
      if (city != null) 'city': city,
      if (locationId != null) 'location_id': locationId,
      // L'API n'applique ce filtre que lorsqu'il est vrai (request->boolean),
      // d'où l'absence de cas « non dédouané ».
      if (customsCleared == true) 'customs_cleared': '1',
      if (deal == true) 'deal': '1',
      // 'availability' n'est pas un filtre direct dans l'API — on utilise available_for_rent
      if (availability == 'rent') 'available_for_rent': '1',
      if (availability == 'sale') 'availability': 'sale',
    };

    final json = await _client.get(Endpoints.catalogVehicles, params: params);
    return PaginatedResponse.fromJson(json, Vehicle.fromJson);
  }

  Future<Vehicle> getVehicle(int id) async {
    final json = await _client.get('${Endpoints.catalogVehicles}/$id');
    return Vehicle.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ── Accessoires ──────────────────────────────────────────────────

  Future<PaginatedResponse<Accessory>> getAccessories({
    int page = 1,
    int perPage = 20,
    String? search,
    String? category, // 'esthetique' | 'confort' | 'securite' | 'multimedia' | 'utilitaire'
    String? manufacturerId,
    double? priceMax,
    int? vehicleModelId, // filtre compatibilité
    String? city,
    int? locationId,
  }) async {
    final params = <String, dynamic>{
      'page':     page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'q': search,
      if (category != null) 'category': category,
      if (manufacturerId != null) 'manufacturer_id': manufacturerId,
      if (priceMax != null) 'price_max': priceMax.toInt(),
      if (vehicleModelId != null) 'vehicle_model_id': vehicleModelId,
      if (city != null) 'city': city,
      if (locationId != null) 'location_id': locationId,
    };

    final json = await _client.get(Endpoints.catalogAccessories, params: params);
    return PaginatedResponse.fromJson(json, Accessory.fromJson);
  }

  Future<Accessory> getAccessory(int id) async {
    final json = await _client.get(Endpoints.accessoryDetail(id));
    return Accessory.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Part> getPart(int id) async {
    final json = await _client.get(Endpoints.partDetail(id));
    return Part.fromJson(json['data'] as Map<String, dynamic>);
  }

  // ── Référentiels (pour les formulaires staff) ─────────────────────

  Future<List<PartCategory>> getPartCategories() async {
    final list = await _client.getList(Endpoints.catalogPartCategories);
    return list.map((e) => PartCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Manufacturer>> getManufacturers() async {
    final list = await _client.getList(Endpoints.catalogManufacturers);
    return list.map((e) => Manufacturer.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Création (staff) ─────────────────────────────────────────────

  Future<Part> createPart(Map<String, dynamic> data) async {
    final json = await _client.post(Endpoints.staffParts, data: data);
    return Part.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Part> updatePart(int id, Map<String, dynamic> data) async {
    final json = await _client.put(Endpoints.staffPartDetail(id), data: data);
    return Part.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deletePart(int id) async {
    await _client.delete(Endpoints.staffPartDetail(id));
  }

  Future<Accessory> createAccessory(Map<String, dynamic> data) async {
    final json = await _client.post(Endpoints.staffAccessories, data: data);
    return Accessory.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<Accessory> updateAccessory(int id, Map<String, dynamic> data) async {
    final json = await _client.put(Endpoints.staffAccessoryDetail(id), data: data);
    return Accessory.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAccessory(int id) async {
    await _client.delete(Endpoints.staffAccessoryDetail(id));
  }

  /// Bascule la disponibilité d'une pièce (staff).
  Future<bool> togglePartAvailability(int id) async {
    final json = await _client.patch(Endpoints.partAvailability(id));
    return json['is_available'] as bool;
  }

  /// Bascule la disponibilité d'un accessoire (staff).
  Future<bool> toggleAccessoryAvailability(int id) async {
    final json = await _client.patch(Endpoints.accessoryAvailability(id));
    return json['is_available'] as bool;
  }

  // ── Pièces détachées ─────────────────────────────────────────────

  Future<PaginatedResponse<Part>> getParts({
    int page = 1,
    int perPage = 20,
    String? search,
    String? oem,
    int? categoryId,
    String? type,
    String? condition,
    bool inStockOnly = false,
    double? priceMax,
    // Recherche par critères véhicule
    int? vehicleModelId,
    int? year,
    String? city,       // filtre par ville
    int? locationId,    // filtre par agence précise
  }) async {
    final params = <String, dynamic>{
      'page':     page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'q': search,
      if (oem != null) 'oem': oem,
      if (categoryId != null) 'category_id': categoryId,
      if (type != null) 'type': type,
      if (condition != null) 'condition': condition,
      if (inStockOnly) 'in_stock': '1',
      if (priceMax != null) 'price_max': priceMax.toInt(),
      if (vehicleModelId != null) 'vehicle_model_id': vehicleModelId,
      if (year != null) 'year': year,
      if (city != null) 'city': city,
      if (locationId != null) 'location_id': locationId,
    };

    // Si on cherche par critères véhicule, on utilise la route compatible-parts
    final path = vehicleModelId != null
        ? Endpoints.compatibleParts
        : Endpoints.catalogParts;

    final json = await _client.get(path, params: params);
    return PaginatedResponse.fromJson(json, Part.fromJson);
  }
}
