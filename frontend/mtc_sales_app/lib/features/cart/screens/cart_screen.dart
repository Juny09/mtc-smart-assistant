import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/features/cart/providers/cart_provider.dart';
import 'package:mtc_sales_app/features/cart/screens/cart_share_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsyncValue = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('购物车'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final cart = cartAsyncValue.value;
              if (cart != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CartShareScreen(cartId: cart.id),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: cartAsyncValue.when(
        data: (cart) {
          if (cart == null || cart.items.isEmpty) {
            return const Center(child: Text('购物车是空的'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade200,
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(item.imageUrl, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))
                            : const Icon(Icons.image),
                      ),
                      title: Text(item.productName),
                      subtitle: Text(item.productCode),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('x${item.quantity}'),
                          const SizedBox(width: 16),
                          Text(
                            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: \$${cart.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Checkout
                        },
                        child: const Text('结算'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
