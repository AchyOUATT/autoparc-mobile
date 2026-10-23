import 'package:equatable/equatable.dart';

import 'compatibility_summary.dart';
import '../../../../shared/models/product_seller.dart';

/// Pièce détachée (OEM / aftermarket / occasion).
class Part extends Equatable {
  final int     id;
  final String? sku;
  final String  name;
  final String? description;
  final String  type;       // 'oem' | 'oes' | 'aftermarket' | 'salvage'
  final String  condition;  // 'new' | 'refurbished' | 'used'
  final int?    categoryId;
  final String? categoryName;
  final int?    manufacturerId;
  final String? manufacturer;
  final PartPricing pricing;
  final PartStock   stock;
  final int?    warrantyMonths;
  final bool    isActive;
  final ProductSeller? seller;

  /// Le marqueur de version que l'adresse de partage porte en `?m=`, `null`
  /// quand la réponse ne le dit pas.
  ///
  /// Même champ et même rôle que `Vehicle.shareVersion` : une chaîne opaque
  /// recopiée telle quelle, jamais lue ici. `adresseArticle` porte le pourquoi,
  /// y compris celui du repli sur l'adresse nue quand ce champ est nul.
  final String? shareVersion;

  /// La photo de couverture, `null` si la pièce n'a aucune photo **utilisable**.
  ///
  /// Le premier élément de [photoUrls], et rien d'autre. Ce n'était pas le cas :
  /// la couverture était lue directement sur le média (`coverItem['url']`) et
  /// échappait au filtre des adresses vides, si bien qu'un média de couverture
  /// sans URL rendait `coverUrl == ''`. Or les écrans qui montrent la vignette
  /// — `part_list_page`, la section des pièces compatibles de l'accueil, et
  /// `accessory_list_page` pour le modèle jumeau — testent `coverUrl != null`,
  /// vrai pour la chaîne vide : ils affichaient le carré gris de repli alors
  /// que la vraie photo suivait dans la liste. Voir [photoUrls].
  final String? coverUrl;

  /// Toutes les photos de l'article, couverture en tête.
  ///
  /// `coverUrl` est simplement le premier élément de cette liste : la carte
  /// n'a besoin que de lui, la fiche les montre toutes. L'API les renvoyait
  /// déjà — `fromJson` les lisait pour en extraire la couverture, puis jetait
  /// le reste. Les photos existaient donc sans qu'aucun écran ne puisse les
  /// atteindre.
  ///
  /// Jamais `null`, contrairement à `fitments` : une liste vide dit « aucune
  /// photo », et c'est vrai aussi bien dans la liste que sur la fiche.
  final List<String> photoUrls;

  /// Les compatibilités véhicules, telles que l'API les rend.
  ///
  /// `null` ne veut pas dire « aucune » : `whenLoaded('fitments')` retire la
  /// clé de la réponse quand le contrôleur n'a pas chargé la relation, et
  /// toutes les routes ne la chargent pas. `CompatibilityService` ne charge que
  /// `category`, `manufacturer` et `oemNumbers` — donc les pièces compatibles
  /// de l'accueil et celles de la page du garage arrivent SANS la clé. La
  /// distinction est vitale pour l'écran de modification : confondre « je ne
  /// sais pas » avec « il n'y en a pas » revient à effacer la liste à
  /// l'enregistrement.
  ///
  /// Les lignes restent sous forme brute à dessein : tout modèle intermédiaire
  /// qui oublierait une clé la viderait silencieusement au premier
  /// enregistrement, puisque le `PUT` remplace la liste entière.
  final List<Map<String, dynamic>>? fitments;

  /// Le résumé des modèles compatibles, pour la LIGNE DE LA CARTE.
  ///
  /// `null` comme [fitments], et pour la même raison : le serveur rend les deux
  /// sous le même `whenLoaded('fitments')`. La liste du catalogue la charge —
  /// `PartController::index` fait `with('fitments.vehicleModel.brand')`, vérifié
  /// dans autoparc-backend — donc la clé est présente sur `/catalog/parts`,
  /// qui est la route de la grille, et la ligne de la carte s'affiche. Sur les
  /// pièces compatibles de l'accueil elle vaut `null`, et la ligne disparaît :
  /// c'est le bon comportement, ces tuiles-là n'ont pas la place et la liste
  /// répond déjà à la question.
  ///
  /// POURQUOI UN RÉSUMÉ À CÔTÉ DE [fitments], QUI PORTE DÉJÀ TOUT. Parce que
  /// `fitments` porte les identifiants et non les NOMS composés : un
  /// `vehicle_model` y est `full_name` quand la relation imbriquée a été
  /// chargée, et la déduplication « un modèle par moteur » se fait côté
  /// serveur. Recomposer la ligne depuis `fitments` voudrait dire refaire ce
  /// `unique()` ici, sur une liste que le serveur n'envoie pas toujours
  /// entière.
  final CompatibilitySummary? compatibility;

  const Part({
    required this.id,
    this.sku,
    required this.name,
    this.description,
    required this.type,
    required this.condition,
    this.categoryId,
    this.categoryName,
    this.manufacturerId,
    this.manufacturer,
    required this.pricing,
    required this.stock,
    this.warrantyMonths,
    required this.isActive,
    this.seller,
    this.shareVersion,
    this.coverUrl,
    this.photoUrls = const [],
    this.fitments,
    this.compatibility,
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    final mediaList = json['media'] as List?;
    var photos = const <String>[];
    if (mediaList != null && mediaList.isNotEmpty) {
      // Priorité : is_cover = true, sinon premier élément
      final coverItem = mediaList.firstWhere(
        (m) => m['is_cover'] == true,
        orElse: () => mediaList.first,
      );

      // La couverture d'abord, puis les autres par `position`. On écarte la
      // couverture par identité et non par URL : deux médias peuvent porter
      // la même adresse — le catalogue en a eu deux pointant sur « /0 » après
      // une panne de stockage — et un filtre par URL les aurait tous perdus.
      final autres = mediaList.where((m) => !identical(m, coverItem)).toList()
        ..sort((a, b) => ((a['position'] as int?) ?? 0)
            .compareTo((b['position'] as int?) ?? 0));

      // Le filtre des adresses vides s'applique à la couverture comme au
      // reste, et c'est tout le correctif : elle était lue à part, avant le
      // filtre, et une couverture sans URL donnait `coverUrl == ''` plus un
      // premier élément vide dans la galerie. Aligné sur `Vehicle.fromJson`,
      // qui faisait déjà exactement ceci.
      photos = <dynamic>[coverItem, ...autres]
          .map((m) => m['url'] as String? ?? '')
          .where((u) => u.isNotEmpty)
          .toList(growable: false);
    }
    return Part(
      id:             json['id']              as int,
      sku:            json['sku']             as String?,
      name:           json['name']            as String,
      description:    json['description']     as String?,
      type:           json['type']            as String,
      condition:      json['condition']       as String,
      categoryId:     json['category_id']     as int?,
      categoryName:   (json['category'] as Map<String, dynamic>?)?['name'] as String?,
      manufacturerId: json['manufacturer_id'] as int?,
      manufacturer:   json['manufacturer']   as String?,
      pricing:        PartPricing.fromJson(json['pricing'] as Map<String, dynamic>),
      stock:          PartStock.fromJson(json['stock']     as Map<String, dynamic>),
      warrantyMonths: json['warranty_months'] as int?,
      isActive:       json['is_active']       as bool? ?? true,
      seller: json['seller'] is Map<String, dynamic>
          ? ProductSeller.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
      // Clef absente → `null`, et le partage repart sur l'adresse nue. Pas de
      // `?? ''` : « absent » et « vide » doivent arriver distinctement à
      // `adresseArticle`, qui les traite déjà tous les deux.
      shareVersion:   json['share_version']   as String?,
      // Le même premier élément, nommé : les deux ne peuvent plus diverger.
      coverUrl:       photos.isEmpty ? null : photos.first,
      photoUrls:      photos,
      // Clé absente → null, c'est-à-dire « la réponse ne le dit pas ».
      fitments: (json['fitments'] as List?)
          ?.cast<Map<String, dynamic>>()
          .toList(growable: false),
      // Même règle, et le `?` compte : la clé absente doit rester `null` et non
      // devenir un résumé vide. Un résumé vide dit « aucun modèle compatible »,
      // ce qui est une affirmation que la réponse n'a pas faite.
      compatibility: (json['compatibility'] as Map<String, dynamic>?) == null
          ? null
          : CompatibilitySummary.fromJson(
              json['compatibility'] as Map<String, dynamic>,
            ),
    );
  }

  /// Vrai quand `/p/{id}` répond, c'est-à-dire quand cette pièce est
  /// partageable. Voir `Vehicle.aUnePagePublique` pour le pourquoi.
  ///
  /// `is_active` SEUL, et c'est bien l'alignement sur le serveur :
  /// `ArticleController::piece` n'a qu'un `abort_if(! $part->is_active)`. Le
  /// stock n'y entre pas, parce que le catalogue des pièces montre les ruptures
  /// — `is_available` n'y est qu'un filtre optionnel — là où celui des
  /// accessoires les masque. D'où une condition ici et deux chez
  /// `Accessory`.
  bool get aUnePagePublique => isActive;

  bool get isOem         => type == 'oem';
  bool get isAftermarket => type == 'aftermarket';
  bool get isNew         => condition == 'new';

  bool get isAvailableForSale => seller != null
      ? stock.isAvailable && (!stock.hasQuantity || stock.quantity > 0)
      : stock.quantity > 0;

  @override
  List<Object?> get props => [id, sku, seller];
}

// Laravel sérialise decimal:2 en String ("5000.00") — ce helper accepte les deux.
double _d(dynamic v) => v is num ? v.toDouble() : double.parse(v.toString());

class PartPricing extends Equatable {
  final double sellingPrice;
  final String currency;
  final double vatRate;
  final double priceIncludingVat;

  const PartPricing({
    required this.sellingPrice,
    required this.currency,
    required this.vatRate,
    required this.priceIncludingVat,
  });

  factory PartPricing.fromJson(Map<String, dynamic> json) => PartPricing(
    sellingPrice:      _d(json['selling_price']),
    currency:          json['currency'] as String? ?? 'XOF',
    vatRate:           _d(json['vat_rate']),
    priceIncludingVat: _d(json['price_including_vat']),
  );

  @override
  List<Object?> get props => [sellingPrice, currency];
}

class PartStock extends Equatable {
  final bool isAvailable;
  final int quantity;
  final int alertThreshold;
  final bool isLow;
  final bool hasQuantity;
  final String? location;

  const PartStock({
    this.isAvailable = true,
    required this.quantity,
    required this.alertThreshold,
    required this.isLow,
    this.hasQuantity = true,
    this.location,
  });

  factory PartStock.fromJson(Map<String, dynamic> json) => PartStock(
    isAvailable:    json['is_available']    as bool? ?? true,
    hasQuantity:    json['quantity'] != null,
    // Tolerant, comme alert_threshold juste dessous. Laravel ne rafraichit pas
    // le modele apres create() : un champ absent de la requete reste null en
    // memoire, meme quand la colonne porte un default(0) que la base applique.
    // La reponse de creation rendait donc quantity: null, le cast levait un
    // _TypeError — ni ApiException ni DioException —, et l'ecran affichait
    // « Une erreur est survenue » sur un enregistrement pourtant reussi.
    // Reproduit en test le 2026-10-16.
    quantity:       json['quantity']        as int? ?? 0,
    alertThreshold: json['alert_threshold'] as int? ?? 0,
    isLow:          json['is_low']          as bool? ?? false,
    // Le texte libre du formulaire d'abord — c'est lui que l'ecran de saisie
    // ecrit, sous la cle "storage_location". Tout le monde relisait "location",
    // qui est la localite liee : un OBJET {id, name, city}, et seulement quand
    // la relation est chargee. Resultat, l'emplacement saisi n'etait jamais
    // reaffiche, ni sur la fiche, ni au pre-remplissage de l'edition — et le
    // jour ou une localite aurait ete liee, le cast en String aurait leve.
    location:       (json['storage_location'] as String?)
                    ?? ((json['location'] as Map<String, dynamic>?)?['name'] as String?),
  );

  @override
  List<Object?> get props => [isAvailable, quantity, isLow, hasQuantity];
}
