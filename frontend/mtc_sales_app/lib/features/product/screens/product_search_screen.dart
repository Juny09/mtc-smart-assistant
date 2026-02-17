import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/core/auth/biometric_service.dart';
import 'package:mtc_sales_app/features/cart/providers/cart_provider.dart';
import 'package:mtc_sales_app/features/cart/screens/cart_screen.dart';
import 'package:mtc_sales_app/features/cart/screens/cart_scan_screen.dart';
import 'package:mtc_sales_app/features/product/models/product.dart';
import 'package:mtc_sales_app/features/product/providers/product_repository.dart';
import 'package:mtc_sales_app/features/camera/screens/identify_product_screen.dart';
import 'package:mtc_sales_app/features/camera/screens/product_camera_screen.dart';
import 'package:mtc_sales_app/features/tools/screens/price_calculator_screen.dart';
import 'package:mtc_sales_app/core/auth/auth_service.dart';
import 'package:mtc_sales_app/core/auth/login_screen.dart';
import 'package:mtc_sales_app/features/admin/screens/admin_product_create_screen.dart';

final productsProvider =
    StateNotifierProvider.family<
      ProductNotifier,
      AsyncValue<List<Product>>,
      String
    >((ref, query) {
      return ProductNotifier(ref.watch(productRepositoryProvider), query);
    });

class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductRepository _repository;
  final String _query;

  ProductNotifier(this._repository, this._query)
    : super(const AsyncValue.loading()) {
    _searchProducts();
  }

  Future<void> _searchProducts() async {
    try {
      final products = await _repository.searchProducts(_query);
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class ProductSearchScreen extends ConsumerStatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  ConsumerState<ProductSearchScreen> createState() =>
      _ProductSearchScreenState();
}

class _ProductSearchScreenState extends ConsumerState<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _currentQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _currentQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsyncValue = _currentQuery.isEmpty
        ? const AsyncValue.data(<Product>[])
        : ref.watch(productsProvider(_currentQuery));
    final userRole = ref.watch(userProvider).role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MTC 商品查询'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PriceCalculatorScreen(),
                ),
              );
            },
          ),
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminProductCreateScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CartScanScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_weak),
            tooltip: 'Identify Product',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const IdentifyProductScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CartScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '输入代码、名称或用途...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          Expanded(
            child: productsAsyncValue.when(
              data: (products) {
                if (products.isEmpty && _currentQuery.isNotEmpty) {
                  return Center(
                    child: Text(
                      '未找到 "$_currentQuery" 相关商品',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                } else if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '请输入商品代码或关键词开始查询',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: products.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends ConsumerStatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isCostVisible = false;
  double? _fetchedCostPrice;

  Future<void> _addToCart() async {
    try {
      // Note: In real app we should check if product.id is null
      await ref
          .read(cartProvider.notifier)
          .addToCart(widget.product.id ?? "", 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已加入购物车'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入购物车失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _revealCost() async {
    final authService = ref.read(biometricServiceProvider);

    // In production, we would call the backend here AFTER auth
    final authenticated = await authService.authenticate(reason: '请验证身份以查看成本价');

    if (authenticated) {
      try {
        // Fetch Real Cost from API
        final cost = await ref
            .read(productRepositoryProvider)
            .getCostPrice(widget.product.code);

        setState(() {
          _isCostVisible = true;
          _fetchedCostPrice = cost;
        });

        // Auto-hide after 10 seconds
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _isCostVisible = false;
            });
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('获取原价失败: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('验证失败，无法查看成本价')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    widget.product.code,
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.product.description,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (widget.product.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.product.categoryName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                if (widget.product.brandName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.product.brandName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '建议售价',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '\$${widget.product.suggestedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      tooltip: 'Train Model',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductCameraScreen(product: widget.product),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _isCostVisible ? null : _revealCost,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isCostVisible
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isCostVisible
                                ? Colors.red.shade200
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '成本价 (Hidden)',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isCostVisible
                                    ? Colors.red.shade700
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isCostVisible
                                  ? '\$${_fetchedCostPrice?.toStringAsFixed(2) ?? "..."}'
                                  : '******',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isCostVisible
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('加入购物车'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
