import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/core/api/api_client.dart';
import 'package:mtc_sales_app/features/cart/models/cart.dart';
import 'package:shared_preferences/shared_preferences.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return CartRepository(apiClient);
});

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<Cart?>>((
  ref,
) {
  final repo = ref.read(cartRepositoryProvider);
  return CartNotifier(repo);
});

class CartRepository {
  final ApiClient _apiClient;
  static const _cartIdKey = 'current_cart_id';

  CartRepository(this._apiClient);

  Future<String?> getStoredCartId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cartIdKey);
  }

  Future<void> storeCartId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartIdKey, id);
  }

  Future<Cart> getCart(String id) async {
    final response = await _apiClient.get('cart/$id');
    return Cart.fromJson(response.data);
  }

  Future<Cart> createCart() async {
    final response = await _apiClient.post('cart');
    final cart = Cart.fromJson(response.data);
    await storeCartId(cart.id);
    return cart;
  }

  Future<Cart> addToCart(String cartId, String productId, int quantity) async {
    final response = await _apiClient.post(
      'cart/$cartId/items',
      data: {'productId': productId, 'quantity': quantity},
    );
    return Cart.fromJson(response.data);
  }
}

class CartNotifier extends StateNotifier<AsyncValue<Cart?>> {
  final CartRepository _repository;

  CartNotifier(this._repository) : super(const AsyncValue.loading()) {
    _initCart();
  }

  Future<void> _initCart() async {
    try {
      final cartId = await _repository.getStoredCartId();
      if (cartId != null) {
        final cart = await _repository.getCart(cartId);
        state = AsyncValue.data(cart);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // If cart not found (e.g. server reset), create new one
      state = const AsyncValue.data(null);
    }
  }

  Future<void> setCartId(String cartId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.storeCartId(cartId);
      final cart = await _repository.getCart(cartId);
      state = AsyncValue.data(cart);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    try {
      Cart? currentCart = state.value;

      if (currentCart == null) {
        // Create new cart first
        currentCart = await _repository.createCart();
      }

      final updatedCart = await _repository.addToCart(
        currentCart.id,
        productId,
        quantity,
      );
      state = AsyncValue.data(updatedCart);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
