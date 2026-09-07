import 'package:equatable/equatable.dart';

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
  final String? coverUrl; // URL de la photo de couverture (null si aucune photo)

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
    this.coverUrl,
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    final mediaList = json['media'] as List?;
    String? cover;
    if (mediaList != null && mediaList.isNotEmpty) {
      // Priorité : is_cover = true, sinon premier élément
      final coverItem = mediaList.firstWhere(
        (m) => m['is_cover'] == true,
        orElse: () => mediaList.first,
      );
      cover = coverItem['url'] as String?;
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
      coverUrl:       cover,
    );
  }

  bool get isOem         => type == 'oem';
  bool get isAftermarket => type == 'aftermarket';
  bool get isNew         => condition == 'new';

  @override
  List<Object?> get props => [id, sku];
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
  final String? location;

  const PartStock({
    this.isAvailable = true,
    required this.quantity,
    required this.alertThreshold,
    required this.isLow,
    this.location,
  });

  factory PartStock.fromJson(Map<String, dynamic> json) => PartStock(
    isAvailable:    json['is_available']    as bool? ?? true,
    quantity:       json['quantity']        as int,
    alertThreshold: json['alert_threshold'] as int? ?? 0,
    isLow:          json['is_low']          as bool? ?? false,
    location:       json['location']        as String?,
  );

  @override
  List<Object?> get props => [isAvailable, quantity, isLow];
}
