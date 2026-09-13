import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import 'models/cart_item.dart';
import '../../../core/api/api_exception.dart';

/// Soumission de commandes staff vers le backend Laravel.
class OrderRepository {
  const OrderRepository(this._client);
  final ApiClient _client;

  /// Crée une commande globale (accessoires + pièces).
  ///
  /// Retourne `null` si succès, ou un message d'erreur lisible.
  Future<String?> submitOrder({
    required String customerName,
    String? customerPhone,
    required List<CartItem> items,
  }) async {
    try {
      final payload = <String, dynamic>{
        'customer_name': customerName.trim(),
        if (customerPhone != null && customerPhone.trim().isNotEmpty)
          'customer_phone': customerPhone.trim(),
        'items': items
            .map((i) => {
                  'item_type': i.itemType.name, // 'accessory' | 'part'
                  'item_id':   i.id,
                  'quantity':  i.quantity,
                })
            .toList(),
      };
      await _client.post(Endpoints.staffOrders, data: payload);
      return null;
    } catch (e) {
      return messageFor(e);
    }
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) =>
    OrderRepository(ref.read(apiClientProvider)));
