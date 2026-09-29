import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../shared/models/paginated_response.dart';
import '../../catalog/data/models/part.dart';
import 'models/motorisation.dart';
import 'models/owned_vehicle.dart';
import 'models/garage_compatibility.dart';
import 'models/vehicle_check.dart';
import 'models/vin_decode_result.dart';

final garageRepositoryProvider = Provider<GarageRepository>(
  (ref) => GarageRepository(ref.read(apiClientProvider)),
);

class GarageRepository {
  final ApiClient _client;
  const GarageRepository(this._client);

  /// Liste des véhicules du garage de l'utilisateur connecté.
  Future<List<OwnedVehicle>> getVehicles() async {
    final json = await _client.get(Endpoints.myVehicles, params: {'per_page': 100});
    final page = PaginatedResponse.fromJson(json, OwnedVehicle.fromJson);
    return page.data;
  }

  /// Ajoute un véhicule au garage.
  Future<OwnedVehicle> addVehicle(Map<String, dynamic> payload) async {
    final json = await _client.post(Endpoints.myVehicles, data: payload);
    return OwnedVehicle.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Met à jour un véhicule du garage (kilométrage, surnom…).
  Future<OwnedVehicle> updateVehicle(int id, Map<String, dynamic> payload) async {
    final json = await _client.put('${Endpoints.myVehicles}/$id', data: payload);
    return OwnedVehicle.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Motorisations connues pour un modèle, avec leur cote officielle.
  ///
  /// L'année sert à classer : le serveur remonte d'abord les millésimes les
  /// plus proches, puis élague les doublons. Une liste vide signifie qu'aucune
  /// source publique ne couvre ce modèle — le cas des Fortuner, Prado et
  /// autres véhicules vendus ni en Amérique du Nord ni en Europe.
  Future<List<Motorisation>> motorisations({
    required int vehicleModelId,
    int? year,
  }) async {
    final json = await _client.get(Endpoints.catalogMotorisations, params: {
      'vehicle_model_id': vehicleModelId,
      if (year != null) 'year': year,
    });

    return (json['data'] as List)
        .map((m) => Motorisation.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Les points à vérifier avant un voyage, composés pour ce véhicule.
  ///
  /// La distance change la liste : la climatisation et les provisions
  /// n'apparaissent qu'au-delà d'un certain trajet, et une vidange à 200 km de
  /// son terme devient un défaut si le trajet en fait 360.
  Future<CheckTemplate> checkTemplate(
    int ownedVehicleId, {
    int? tripDistanceKm,
    String reason = 'trip',
  }) async {
    final json = await _client.get(
      Endpoints.myCheckTemplate(ownedVehicleId),
      params: {
        'reason': reason,
        if (tripDistanceKm != null) 'trip_distance_km': tripDistanceKm,
      },
    );

    return CheckTemplate.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Enregistre un contrôle et renvoie son verdict.
  ///
  /// La charge porte une `client_reference` : un contrôle se remplit capot
  /// ouvert, souvent sans réseau, et l'envoi sera rejoué. Le serveur retrouve
  /// alors le passage au lieu d'en créer un second.
  Future<VehicleCheck> submitCheck(int ownedVehicleId, Map<String, dynamic> payload) async {
    final json = await _client.post(Endpoints.myChecks(ownedVehicleId), data: payload);
    return VehicleCheck.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// Historique des contrôles d'un véhicule, du plus récent au plus ancien.
  Future<List<VehicleCheck>> checkHistory(int ownedVehicleId) async {
    final json = await _client.get(Endpoints.myChecks(ownedVehicleId));
    final page = PaginatedResponse.fromJson(json, VehicleCheck.fromJson);
    return page.data;
  }

  /// Retire un véhicule du garage.
  Future<void> deleteVehicle(int id) async {
    await _client.delete('${Endpoints.myVehicles}/$id');
  }

  /// Pièces compatibles avec un véhicule du garage (matching précis).
  ///
  /// [categoryId] restreint à une catégorie et à ses sous-catégories : c'est le
  /// chemin qu'emprunte un point de contrôle en défaut. Sans lui, un pneu usé
  /// ouvrirait cinq cents pièces.
  Future<List<Part>> compatibleParts(int ownedVehicleId, {int? categoryId}) async {
    final json = await _client.get(
      Endpoints.myCompatibleParts(ownedVehicleId),
      params: {if (categoryId != null) 'category_id': categoryId},
    );
    final page = PaginatedResponse.fromJson(json, Part.fromJson);
    return page.data;
  }

  /// IDs de toutes les pièces compatibles avec un véhicule (per_page élevé).
  ///
  /// Utilisé pour badger les tuiles de la liste sans requête par pièce.
  /// Retourne un [Set] pour des recherches O(1).
  Future<Set<int>> compatiblePartIds(int ownedVehicleId) async {
    final json = await _client.get(
      Endpoints.myCompatibleParts(ownedVehicleId),
      params: {'per_page': 500},
    );
    final page = PaginatedResponse.fromJson(json, Part.fromJson);
    return page.data.map((p) => p.id).toSet();
  }

  /// Compatibilité d'une pièce avec chaque véhicule du garage du client.
  ///
  /// Retourne une entrée par véhicule du garage, avec [GarageCompatibility.compatible]
  /// à `true` si la pièce a au moins un fitment qui correspond au véhicule.
  Future<List<GarageCompatibility>> checkPartCompatibility(int partId) async {
    final json = await _client.get(Endpoints.garageCompatibility(partId));
    return (json['data'] as List<dynamic>)
        .map((e) => GarageCompatibility.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Décode un VIN via l'API publique (/catalog/vin-decode/{vin}).
  /// Retourne toujours un résultat (valid=false si le VIN est mal formé).
  Future<VinDecodeResult> decodeVin(String vin) async {
    final json = await _client.get(Endpoints.vinDecode(vin.toUpperCase().trim()));
    return VinDecodeResult.fromJson(json);
  }
}
