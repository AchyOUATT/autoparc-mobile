import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cart_item.dart';

// ── Notifier ──────────────────────────────────────────────────────────

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  /// Ajoute l'article au panier (incrémente la quantité si déjà présent).
  void add(CartItem item) {
    final idx = _indexOf(item.id, item.itemType);
    if (idx >= 0) {
      _update(idx, state[idx].quantity + 1);
    } else {
      state = [...state, item];
    }
  }

  void increment(CartItem item) => add(item);

  void decrement(CartItem item) {
    final idx = _indexOf(item.id, item.itemType);
    if (idx < 0) return;
    if (state[idx].quantity <= 1) {
      remove(item);
    } else {
      _update(idx, state[idx].quantity - 1);
    }
  }

  void remove(CartItem item) {
    state = state
        .where((i) => !(i.id == item.id && i.itemType == item.itemType))
        .toList();
  }

  void clear() => state = const [];

  bool contains(int id, CartItemType type) => _indexOf(id, type) >= 0;

  int quantityOf(int id, CartItemType type) {
    final idx = _indexOf(id, type);
    return idx >= 0 ? state[idx].quantity : 0;
  }

  // ── Privé ─────────────────────────────────────────────────────────

  int _indexOf(int id, CartItemType type) =>
      state.indexWhere((i) => i.id == id && i.itemType == type);

  void _update(int idx, int qty) {
    final updated = [...state];
    updated[idx] = updated[idx].copyWith(quantity: qty);
    state = updated;
  }
}

// ── Providers ─────────────────────────────────────────────────────────

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

/// Nombre total d'articles dans le panier (pour le badge).
final cartCountProvider = Provider<int>((ref) =>
    ref.watch(cartProvider).fold(0, (sum, i) => sum + i.quantity));
