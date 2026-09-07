/// URLs de l'API AutoParc.
///
/// Émulateur Android : 10.0.2.2 → localhost de la machine hôte.
/// Device physique   : IP locale de la machine sur le même réseau WiFi.
class Endpoints {
  Endpoints._();

  // ignore: dead_code
  static const String _emulator  = 'http://10.0.2.2:8000/api';
  // ignore: dead_code
  static const String _device    = 'http://192.168.30.75:8000/api';
  // ignore: dead_code
  static const String _ngrok     = 'https://jujitsu-platinum-glimpse.ngrok-free.dev/api';
  /// URL de production Railway — mettre à jour après déploiement.
  // ignore: dead_code
  static const String _render   = 'https://autoparc-backend.onrender.com/api';

  /// ⚠ Basculer selon le contexte :
  ///   _emulator → émulateur Android (dev local)
  ///   _device   → device physique sur le même WiFi
  ///   _ngrok    → test distant via tunnel temporaire
  ///   _railway  → production Railway (test/prod)
  static const String baseUrl = _render;

  // ── Auth ────────────────────────────────────────────────────────
  static const String login  = '/login';
  static const String me     = '/me';
  static const String logout = '/logout';

  // ── Catalogue public ────────────────────────────────────────────
  static const String catalogVehicles       = '/catalog/vehicles';
  static const String catalogParts          = '/catalog/parts';
  static const String catalogAccessories    = '/catalog/accessories';
  static const String catalogSync           = '/catalog/sync';
  static const String catalogBrands         = '/catalog/brands';
  static const String catalogCountries      = '/catalog/countries';
  static const String catalogPartCategories = '/catalog/part-categories';
  static const String catalogManufacturers  = '/catalog/manufacturers';
  static const String compatibleParts       = '/catalog/compatible-parts';

  // ── Back-office stock (staff) ───────────────────────────────────
  static const String staffParts       = '/parts';
  static const String staffAccessories = '/accessories';

  // ── Mon garage (client Firebase) ────────────────────────────────
  static const String myVehicles = '/my/vehicles';
  static String myCompatibleParts(int ownedVehicleId) =>
      '/my/vehicles/$ownedVehicleId/compatible-parts';

  // ── Décodage VIN (public) ────────────────────────────────────────
  static String vinDecode(String vin) => '/catalog/vin-decode/$vin';

  // ── Compatibilité garage (Firebase auth) ─────────────────────────
  /// Retourne la compatibilité d'une pièce avec chaque véhicule du garage.
  static String garageCompatibility(int partId) =>
      '/my/parts/$partId/garage-compatibility';

  // ── OEM ─────────────────────────────────────────────────────────
  static String oemVehicles(String number)         => '/oem/$number/vehicles';
  static String oemModels(String number)           => '/oem/$number/models';
  static String oemCrossRefs(String number)        => '/oem/$number/cross-references';

  // ── Accessoires ─────────────────────────────────────────────────
  static String accessoryDetail(int id)            => '/catalog/accessories/$id';

  // ── Pièces détachées ─────────────────────────────────────────────
  static String partDetail(int id)                 => '/catalog/parts/$id';

  // ── Véhicules (staff) ─────────────────────────────────────────────
  static const String staffVehicles                = '/vehicles';
  static String staffVehicleDetail(int id)         => '/vehicles/$id';
  static String vehicleFeatures(int id)            => '/vehicles/$id/features';

  // ── Commandes (staff) ─────────────────────────────────────────────
  static const String staffOrders                  = '/orders';
  static const String staffCustomers               = '/customers';

  // ── CRUD staff pièces / accessoires ──────────────────────────────
  static String staffPartDetail(int id)        => '/parts/$id';
  static String staffAccessoryDetail(int id)   => '/accessories/$id';

  // ── Disponibilité (staff) ─────────────────────────────────────────
  static String partAvailability(int id)       => '/parts/$id/availability';
  static String accessoryAvailability(int id)  => '/accessories/$id/availability';

  // ── Partenaires (staff) ───────────────────────────────────────────
  static const String partners                    = '/partners';
  static String partnerDetail(int id)             => '/partners/$id';
  static String partPartners(int id)              => '/parts/$id/partners';
  static String partPartnerDetach(int pId, int rId) => '/parts/$pId/partners/$rId';
  static String accessoryPartners(int id)         => '/accessories/$id/partners';
  static String accessoryPartnerDetach(int aId, int rId) => '/accessories/$aId/partners/$rId';
  static String vehiclePartners(int id)           => '/vehicles/$id/partners';
  static String vehiclePartnerDetach(int vId, int rId) => '/vehicles/$vId/partners/$rId';

  // ── Médias (staff) ────────────────────────────────────────────────
  static String vehicleMedia(int id)       => '/vehicles/$id/media';
  static String partMedia(int id)          => '/parts/$id/media';
  static String accessoryMedia(int id)     => '/accessories/$id/media';
  static String vehicleMediaReorder(int id)    => '/vehicles/$id/media/reorder';
  static String partMediaReorder(int id)       => '/parts/$id/media/reorder';
  static String accessoryMediaReorder(int id)  => '/accessories/$id/media/reorder';
  static String mediaItem(int id)          => '/media/$id';
  static String mediaSetCover(int id)      => '/media/$id/cover';
}
