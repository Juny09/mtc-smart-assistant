import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/features/cart/providers/cart_provider.dart';
import 'package:mtc_sales_app/features/cart/screens/cart_share_screen.dart';
import 'package:mtc_sales_app/features/product/providers/product_repository.dart';
import 'package:mtc_sales_app/features/cart/models/cart.dart';

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
                            ? Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                              )
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
                        onPressed: () async {
                          final cart = cartAsyncValue.value;
                          if (cart == null || cart.items.isEmpty) return;

                          // Show confirmation dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('确认结算'),
                              content: Text(
                                '这将从库存中扣除 ${cart.items.length} 件商品。确定吗？',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          try {
                            // 1. Prepare updates for batch stock decrease
                            final updates = cart.items
                                .map(
                                  (item) => {
                                    'productId': item.productId,
                                    'quantity': item.quantity,
                                  },
                                )
                                .toList();

                            // 2. Call API to decrease stock
                            await ref
                                .read(productRepositoryProvider)
                                .batchDecreaseStock(updates);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('结算成功，库存已更新'),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // Optional: Clear cart or refresh
                              // For now, we just refresh the cart to reflect any changes if needed,
                              // but since the backend doesn't auto-clear, we might want to do it manually.
                              // However, the user request was just "inventory decrease".
                              // Ideally, we should empty the cart.
                              // Let's create a new empty cart or reset it.
                              // ref.refresh(cartProvider); // This re-fetches.
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('结算失败: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
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
