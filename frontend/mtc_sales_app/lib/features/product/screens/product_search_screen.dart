import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
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
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

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

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleProductSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedProducts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Products?'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} products?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(productRepositoryProvider);
        // Delete sequentially or in parallel. Parallel is faster.
        await Future.wait(
          _selectedIds.map((id) => repository.deleteProduct(id)),
        );

        ref.invalidate(productsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_selectedIds.length} products deleted')),
          );
          setState(() {
            _selectedIds.clear();
            _isSelectionMode = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always watch productsProvider to fetch data.
    // If query is empty, backend returns all products.
    final productsAsyncValue = ref.watch(productsProvider(_currentQuery));
    final userRole = ref.watch(userProvider).role;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              ),
              title: Text('${_selectedIds.length} Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedIds.isNotEmpty
                      ? _deleteSelectedProducts
                      : null,
                ),
              ],
            )
          : AppBar(
              title: const Text('MTC 商品查询'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _toggleSelectionMode,
                  tooltip: 'Select Multiple',
                ),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScanScreen()),
                    );
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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
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
                if (products.isEmpty) {
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
                          _currentQuery.isNotEmpty
                              ? '未找到 "$_currentQuery" 相关商品'
                              : '暂无商品数据',
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
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      isSelectionMode: _isSelectionMode,
                      isSelected:
                          product.id != null &&
                          _selectedIds.contains(product.id),
                      onToggleSelection: () {
                        if (product.id != null) {
                          _toggleProductSelection(product.id!);
                        }
                      },
                      onLongPress: () {
                        if (product.id != null) {
                          if (!_isSelectionMode) {
                            HapticFeedback.mediumImpact();
                            _toggleSelectionMode();
                            _toggleProductSelection(product.id!);
                          }
                        }
                      },
                    );
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
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onLongPress;

  const ProductCard({
    super.key,
    required this.product,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelection,
    this.onLongPress,
  });

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
    // If already visible, toggle it off
    if (_isCostVisible) {
      setState(() {
        _isCostVisible = false;
      });
      return;
    }

    final authService = ref.read(biometricServiceProvider);

    // Try biometric/device auth first
    bool authenticated = await authService.authenticate(reason: '请验证身份以查看成本价');

    // If failed (or on Web), fallback to manual PIN dialog
    if (!authenticated) {
      if (mounted) {
        authenticated = await _showPinDialog();
      }
    }

    if (authenticated) {
      try {
        // Fetch Real Cost from API
        final cost = await ref
            .read(productRepositoryProvider)
            .getCostPrice(widget.product.code);

        if (mounted) {
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
        }
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

  Future<bool> _showPinDialog() async {
    final pinController = TextEditingController();
    final focusNode = FocusNode();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('请输入安全 PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '请输入 6 位安全码验证身份',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Pinput(
              controller: pinController,
              focusNode: focusNode,
              length: 6,
              autofocus: true,
              obscureText: true,
              obscuringWidget: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              defaultPinTheme: PinTheme(
                width: 40,
                height: 48,
                textStyle: const TextStyle(
                  fontSize: 20,
                  color: Color.fromRGBO(30, 60, 87, 1),
                  fontWeight: FontWeight.w600,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromRGBO(234, 239, 243, 1),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 40,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onCompleted: (pin) {
                if (pin == '888888') {
                  Navigator.pop(context, true);
                } else {
                  pinController.clear();
                  focusNode.requestFocus();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('PIN 错误，请重试')));
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              '提示：开发环境默认 PIN 为 888888',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text(
          'Are you sure you want to delete "${widget.product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.product.id != null) {
      try {
        await ref
            .read(productRepositoryProvider)
            .deleteProduct(widget.product.id!);
        // Invalidate provider to refresh list
        ref.invalidate(productsProvider);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Product deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userProvider).role;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      onTap: widget.isSelectionMode ? widget.onToggleSelection : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        color: widget.isSelected ? Colors.blue.shade50 : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Checkbox(
                        value: widget.isSelected,
                        onChanged: (_) => widget.onToggleSelection?.call(),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!widget.isSelectionMode && userRole == 'admin') ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminProductCreateScreen(
                              product: widget.product,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _deleteProduct,
                    ),
                  ],
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
                        onTap: _revealCost,
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
              if (!widget.isSelectionMode)
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
      ),
    );
  }
}
