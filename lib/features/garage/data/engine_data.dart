import '../../vehicles/data/models/catalog_refs.dart';

/// Le véhicule saisi permettra-t-il de calculer la compatibilité des pièces ?
///
/// Reproduit `OwnedVehicle::hasPreciseEngineData()` côté serveur :
///
/// ```php
/// return $this->effective_engine_type_id !== null
///     || $this->effective_engine_code !== null;
/// ```
///
/// avec `effective_engine_type_id = engine_type_id ?? trim?->default_engine_type_id`.
///
/// Le piège est la finition : elle porte une motorisation par défaut. Juger sur
/// le seul menu déroulant annoncerait « information manquante » à quelqu'un qui
/// a choisi une finition — et qui a donc renseigné sa motorisation sans le
/// savoir. Un avertissement qui se déclenche à tort n'est plus lu.
///
/// Une fois le véhicule enregistré, on ne recalcule plus rien : le serveur
/// renvoie `compatibility_ready`, qui fait autorité. Cette fonction ne sert
/// qu'avant l'enregistrement, quand il n'y a encore rien à interroger.
bool motorisationResolue({
  EngineTypeRef? engineType,
  TrimRef? trim,
  String? engineCode,
}) =>
    engineType != null ||
    trim?.defaultEngineTypeId != null ||
    (engineCode?.trim().isNotEmpty ?? false);
