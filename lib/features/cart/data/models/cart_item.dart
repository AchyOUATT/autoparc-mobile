import 'package:equatable/equatable.dart';

import '../../../../features/catalog/data/models/accessory.dart';
import '../../../../features/catalog/data/models/part.dart';

enum CartItemType { accessory, part }

/// Article dans le panier local (accessoire ou pièce détachée).
/// Stocké en mémoire — aucune persistance côté backend tant que
/// la commande n'est pas confirmée.
class CartItem extends Equatable {
  final int          id;
  final String?      sku;
  final String       name;
  final double       unitPriceHt;
  final double       unitPriceTtc;
  final String       currency;
  final CartItemType itemType;
  final int          quantity;

  const CartItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.unitPriceHt,
    required this.unitPriceTtc,
    required this.currency,
    required this.itemType,
    this.quantity = 1,
  });

  factory CartItem.fromAccessory(Accessory a) => CartItem(
    id:           a.id,
    sku:          a.sku,
    name:         a.name,
    unitPriceHt:  a.pricing.sellingPrice,
    unitPriceTtc: a.pricing.priceIncludingVat,
    currency:     a.pricing.currency,
    itemType:     CartItemType.accessory,
  );

  factory CartItem.fromPart(Part p) => CartItem(
    id:           p.id,
    sku:          p.sku,
    name:         p.name,
    unitPriceHt:  p.pricing.sellingPrice,
    unitPriceTtc: p.pricing.priceIncludingVat,
    currency:     p.pricing.currency,
    itemType:     CartItemType.part,
  );

  CartItem copyWith({int? quantity}) => CartItem(
    id:           id,
    sku:          sku,
    name:         name,
    unitPriceHt:  unitPriceHt,
    unitPriceTtc: unitPriceTtc,
    currency:     currency,
    itemType:     itemType,
    quantity:     quantity ?? this.quantity,
  );

  double get lineTotalHt  => unitPriceHt  * quantity;
  double get lineTotalTtc => unitPriceTtc * quantity;
  double get lineVat      => lineTotalTtc - lineTotalHt;

  @override
  List<Object?> get props => [id, itemType];
}
