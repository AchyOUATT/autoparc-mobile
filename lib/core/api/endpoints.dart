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

  /// URL de l'API.
  ///
  /// Par défaut l'émulateur Android, pour que le développement quotidien ne
  /// demande aucun réglage. Un build destiné à quelqu'un d'autre — TestFlight,
  /// App Store, Play Store — fournit l'URL à la compilation :
  ///
  ///   flutter build ipa --dart-define=API_BASE_URL=$_render
  ///
  /// Sans cela, une version distribuée pointerait sur 10.0.2.2, adresse qui
  /// n'existe que dans l'émulateur — et qu'iOS refuserait de toute façon,
  /// n'acceptant pas le HTTP en clair. Cet oubli ne compile plus : voir
  /// [garde], qui arrête le build de release au lieu de le laisser sortir.
  ///
  /// Des constantes ci-dessus, _emulator, _device et _ngrok servent à cette
  /// vérification — ce sont les trois adresses qu'un paquet distribué ne doit
  /// pas porter. _render n'y sert pas : elle reste l'aide-mémoire de l'adresse
  /// de production, celle que les workflows passent en clair.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _emulator,
  );

  /// Vrai quand `API_BASE_URL` a été passé à la compilation.
  ///
  /// `hasEnvironment` sépare « valeur fournie » de « valeur par défaut », ce
  /// que [baseUrl] seul ne dit pas : l'émulateur passé exprès et l'émulateur
  /// pris par défaut donnent la même chaîne.
  static const bool urlFournieALaCompilation =
      bool.hasEnvironment('API_BASE_URL');

  /// Vrai quand [baseUrl] est l'une des adresses de développement.
  ///
  /// Les trois sont inertes chez un tiers : 10.0.2.2 n'existe que dans
  /// l'émulateur, 192.168.30.75 que sur le WiFi du bureau, et un tunnel ngrok
  /// meurt avec la session qui l'a ouvert. _render en est volontairement
  /// absente — la production n'est pas forcément Render, et exiger cette
  /// chaîne-là interdirait une préproduction.
  ///
  /// Comparaisons écrites une à une : `List.contains` n'est pas une opération
  /// constante, et cette valeur doit être calculable à la compilation pour
  /// servir à [garde].
  static const bool urlDeDeveloppement =
      baseUrl == _emulator || baseUrl == _device || baseUrl == _ngrok;

  /// Vrai quand [baseUrl] peut partir dans les mains de quelqu'un d'autre.
  static const bool adressePubliable =
      urlFournieALaCompilation && !urlDeDeveloppement;

  /// Ce que Flutter positionne pour un build de release, et rien d'autre.
  ///
  /// C'est la définition même de `kReleaseMode`
  /// (`foundation/constants.dart` : `const bool kReleaseMode =
  /// bool.fromEnvironment('dart.vm.product')`). Recopiée au lieu d'importer
  /// `package:flutter/foundation.dart` pour que ce fichier ne dépende de rien :
  /// `dart compile kernel` peut alors le compiler seul, ce dont
  /// `test/garde_adresse_release_test.dart` se sert pour éprouver [garde] pour
  /// de vrai, sans construire un APK.
  static const bool _modeRelease = bool.fromEnvironment('dart.vm.product');

  /// Le garde-fou : un build de release qui ne porte pas d'adresse publiable
  /// ne compile pas.
  ///
  /// `flutter build apk --release` lancé à la main, hors du workflow, ne
  /// passait pas le `--dart-define` et sortait un paquet d'apparence normale
  /// qui parlait à 10.0.2.2. Tant que l'application se contentait d'appeler
  /// l'API, cela se voyait au premier écran. Depuis que le partage compose ses
  /// liens à partir de cette racine (`kSiteUrl`), un tel build EXPÉDIE
  /// `http://10.0.2.2:8000/v/12` dans les conversations WhatsApp de vrais
  /// clients : le lien est inerte chez le destinataire, et rien, côté
  /// expéditeur, ne le signale.
  ///
  /// Mesuré, pas supposé : un `assert` ordinaire ne sert à rien ici, le
  /// compilateur AOT de release les supprime. Celui-ci est dans un
  /// constructeur `const`, et l'évaluation des constantes a lieu à la
  /// compilation dans tous les modes — `dart compile kernel
  /// -Ddart.vm.product=true` échoue sur ce fichier sans `API_BASE_URL`, et
  /// réussit avec.
  static const GardeAdresseRelease garde =
      GardeAdresseRelease.verifiee(!_modeRelease || adressePubliable);

  // ── Auth ────────────────────────────────────────────────────────
  static const String login  = '/login';
  static const String me     = '/me';
  static const String logout = '/logout';

  // ── Plancher de version (public) ─────────────────────────────────
  /// Le versionCode minimal encore accepté, servi par le serveur.
  ///
  /// Route publique et volontairement sans authentification : le contrôle a
  /// lieu au démarrage, avant que l'on sache qui est connecté, et une version
  /// périmée doit être arrêtée même chez un visiteur sans compte.
  static const String appVersion = '/app/version';

  // ── Contact AutoParc ─────────────────────────────────────────────
  static const String appContact = '/app/contact';
  static const String contactSettings = '/settings/contact';

  // ── Catalogue public ────────────────────────────────────────────
  static const String catalogVehicles       = '/catalog/vehicles';
  static const String catalogParts          = '/catalog/parts';
  static const String catalogAccessories    = '/catalog/accessories';
  static const String catalogSync           = '/catalog/sync';
  static const String catalogBrands         = '/catalog/brands';
  static const String catalogCountries      = '/catalog/countries';
  static const String catalogPartCategories = '/catalog/part-categories';

  /// Les catégories d'accessoires qui portent au moins un article en vente.
  /// Les libellés et icônes restent côté application : l'API ne rend que des
  /// valeurs.
  static const String catalogAccessoryCategories = '/catalog/accessory-categories';
  static const String catalogManufacturers  = '/catalog/manufacturers';
  static const String compatibleParts       = '/catalog/compatible-parts';
  static const String catalogMotorisations  = '/catalog/motorisations';

  // ── Back-office stock (staff) ───────────────────────────────────
  static const String staffParts       = '/parts';
  static const String staffAccessories = '/accessories';

  // ── Mon garage (client Firebase) ────────────────────────────────
  static const String myVehicles = '/my/vehicles';
  static String myCompatibleParts(int ownedVehicleId) =>
      '/my/vehicles/$ownedVehicleId/compatible-parts';

  /// Liste des points à vérifier avant un voyage.
  ///
  /// Composée par le serveur pour ce véhicule-là : ses échéances, son
  /// millésime, son kilométrage, sa carrosserie et la distance annoncée. Ce
  /// n'est pas une liste figée que l'application pourrait embarquer.
  static String myCheckTemplate(int ownedVehicleId) =>
      '/my/vehicles/$ownedVehicleId/check-template';

  /// Historique des contrôles (GET) et enregistrement d'un passage (POST).
  static String myChecks(int ownedVehicleId) =>
      '/my/vehicles/$ownedVehicleId/checks';

  /// Passages à la pompe d'un véhicule : historique (GET) et enregistrement
  /// d'un passage (POST), comme [myChecks].
  ///
  /// Le calcul de consommation reste entier côté serveur : il trie les pleins
  /// par kilométrage, pas par date, pour qu'un passage saisi en retard
  /// s'insère au bon endroit de la chaîne. Refaire ce tri ici donnerait deux
  /// chiffres pour la même voiture.
  static String myFuelFills(int ownedVehicleId) =>
      '/my/vehicles/$ownedVehicleId/fuel-fills';

  /// Suppression d'un passage, hors de la route du véhicule : une saisie
  /// fautive doit pouvoir disparaître pour que la moyenne redevienne juste.
  static String myFuelFill(int fuelFillId) => '/my/fuel-fills/$fuelFillId';

  /// Suppression du compte et de toutes ses données.
  ///
  /// Google Play l'exige de toute application qui permet d'en créer un : la
  /// demande doit pouvoir partir de l'application elle-même.
  static const String myAccount  = '/my/account';

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

/// Porteur du seul `assert` que Dart évalue à la compilation.
///
/// Un `assert` de corps de fonction ne vit qu'en debug et en profil : le
/// compilateur de release les retire, et un garde-fou écrit ainsi n'aurait
/// jamais arrêté le build fautif. Un `assert` dans la liste d'initialisation
/// d'un constructeur `const` est, lui, évalué pendant l'évaluation des
/// constantes, qui a lieu quel que soit le mode. D'où cette classe : elle
/// n'existe que pour offrir ce constructeur à [Endpoints.garde].
///
/// Mesure à l'appui : `dart compile kernel -Ddart.vm.product=true` sur un
/// fichier qui porte cette construction s'arrête sur « This assertion failed
/// with message », et le même sans `-Ddart.vm.product` passe. Le test
/// `test/garde_adresse_release_test.dart` relance ces deux compilations.
class GardeAdresseRelease {
  /// Refuse la compilation quand [adressePubliable] est faux.
  ///
  /// Le message nomme la commande à taper, parce que l'erreur tombe au milieu
  /// d'une trace de compilation Dart où rien d'autre ne dit quoi faire.
  const GardeAdresseRelease.verifiee(bool adressePubliable)
      : assert(adressePubliable, _message);

  static const String _message =
      'Build de RELEASE sans adresse de production : API_BASE_URL n\'a pas été '
      'passé à la compilation, ou vaut une adresse de développement '
      '(émulateur, WiFi du bureau, tunnel ngrok). Un tel paquet expédierait '
      'des liens de partage inertes dans les conversations des clients. '
      'Ajouter : --dart-define=API_BASE_URL=https://autoparc-backend.onrender.com/api '
      '(la valeur employée par .github/workflows/build-apk.yml).';
}
