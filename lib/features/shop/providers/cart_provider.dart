import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/cart_model.dart';

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addItem(CartItem item) {
    final idx = state.indexWhere((e) => e.variantId == item.variantId);
    if (idx >= 0) {
      state = [
        ...state.sublist(0, idx),
        state[idx].copyWith(quantity: state[idx].quantity + item.quantity),
        ...state.sublist(idx + 1),
      ];
    } else {
      state = [...state, item];
    }
  }

  void setQuantity(int variantId, int quantity) {
    if (quantity <= 0) {
      remove(variantId);
      return;
    }
    state = state
        .map((e) => e.variantId == variantId ? e.copyWith(quantity: quantity) : e)
        .toList();
  }

  void remove(int variantId) {
    state = state.where((e) => e.variantId != variantId).toList();
  }

  void clear() => state = [];

  double get total => state.fold(0.0, (s, e) => s + e.subtotal);
  int get itemCount => state.fold(0, (s, e) => s + e.quantity);
}
