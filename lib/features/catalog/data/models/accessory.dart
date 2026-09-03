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
  });

  factory Accessory.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>;
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
    location:       json['location']        as String?,
  );

  @override
  List<Object?> get props => [isAvailable, quantity, isLow];
}
