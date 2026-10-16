import 'package:equatable/equatable.dart';

/// Accessoire (esthétique, confort, sécurité, multimédia, utilitaire).
class Accessory extends Equatable {
  final int     id;
  final String? sku;
  final String  name;
  final String? description;
  final String  categoryValue;
  final String  categoryLabel;
  final int?    manufacturerId;
  final String? manufacturer;
  final AccessoryPricing pricing;
  final AccessoryStock   stock;
  final int?    warrantyMonths;
  final bool    isActive;
  final String? coverUrl; // URL de la photo de couverture (null si aucune photo)

  /// Toutes les photos, couverture en tête. Voir `Part.photoUrls` : même
  /// raisonnement, même format, et jamais `null`.
  final List<String> photoUrls;

  /// Voir `Part.fitments` : `null` signifie « la réponse ne le dit pas », pas
  /// « aucune compatibilité ». La liste des accessoires ne charge pas cette
  /// relation.
  final List<Map<String, dynamic>>? fitments;

  const Accessory({
    required this.id,
    this.sku,
    required this.name,
    this.description,
    required this.categoryValue,
    required this.categoryLabel,
    this.manufacturerId,
    this.manufacturer,
    required this.pricing,
    required this.stock,
    this.warrantyMonths,
    required this.isActive,
    this.coverUrl,
    this.photoUrls = const [],
    this.fitments,
  });

  factory Accessory.fromJson(Map<String, dynamic> json) {
    final category  = json['category'] as Map<String, dynamic>;
    final mediaList = json['media'] as List?;
    String? cover;
    var photos = const <String>[];
    if (mediaList != null && mediaList.isNotEmpty) {
      final coverItem = mediaList.firstWhere(
        (m) => m['is_cover'] == true,
        orElse: () => mediaList.first,
      );
      cover = coverItem['url'] as String?;

      // Couverture en tête, le reste par `position`. Voir Part.fromJson pour
      // le choix de l'identité plutôt que de l'URL.
      final autres = mediaList.where((m) => !identical(m, coverItem)).toList()
        ..sort((a, b) => ((a['position'] as int?) ?? 0)
            .compareTo((b['position'] as int?) ?? 0));

      photos = <String>[
        ?cover,
        ...autres.map((m) => m['url'] as String?).whereType<String>(),
      ];
    }
    return Accessory(
      id:             json['id']              as int,
      sku:            json['sku']             as String?,
      name:           json['name']            as String,
      description:    json['description']     as String?,
      categoryValue:  category['value']       as String,
      categoryLabel:  category['label']       as String,
      manufacturerId: json['manufacturer_id'] as int?,
      manufacturer:   json['manufacturer']    as String?,
      pricing:        AccessoryPricing.fromJson(json['pricing'] as Map<String, dynamic>),
      stock:          AccessoryStock.fromJson(json['stock']     as Map<String, dynamic>),
      warrantyMonths: json['warranty_months'] as int?,
      isActive:       json['is_active']       as bool? ?? true,
      coverUrl:       cover,
      photoUrls:      photos,
      fitments: (json['fitments'] as List?)
          ?.cast<Map<String, dynamic>>()
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [id, sku];
}

// Laravel sérialise decimal:2 en String ("26500.00") — ce helper accepte les deux.
double _d(dynamic v) => v is num ? v.toDouble() : double.parse(v.toString());
double? _dq(dynamic v) => v == null ? null : _d(v);

class AccessoryPricing extends Equatable {
  final double sellingPrice;
  final String currency;
  final double vatRate;
  final double priceIncludingVat;

  const AccessoryPricing({
    required this.sellingPrice,
    required this.currency,
    required this.vatRate,
    required this.priceIncludingVat,
  });

  factory AccessoryPricing.fromJson(Map<String, dynamic> json) => AccessoryPricing(
    sellingPrice:      _d(json['selling_price']),
    currency:          json['currency'] as String? ?? 'XOF',
    vatRate:           _d(json['vat_rate']),
    priceIncludingVat: _d(json['price_including_vat']),
  );

  @override
  List<Object?> get props => [sellingPrice, currency];
}

class AccessoryStock extends Equatable {
  final bool isAvailable;
  final int quantity;
  final int alertThreshold;
  final bool isLow;
  final String? location;

  const AccessoryStock({
    this.isAvailable = true,
    required this.quantity,
    required this.alertThreshold,
    required this.isLow,
    this.location,
  });

  factory AccessoryStock.fromJson(Map<String, dynamic> json) => AccessoryStock(
    isAvailable:    json['is_available']    as bool? ?? true,
    quantity:       json['quantity']        as int,
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
  List<Object?> get props => [isAvailable, quantity, isLow];
}
