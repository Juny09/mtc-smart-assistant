import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/core/api/api_client.dart';
import 'package:mtc_sales_app/features/product/models/product.dart';

final adminProductProvider =
    StateNotifierProvider<AdminProductNotifier, AsyncValue<void>>((ref) {
      final apiClient = ref.read(apiClientProvider);
      return AdminProductNotifier(apiClient);
    });

class AdminProductNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiClient _apiClient;

  AdminProductNotifier(this._apiClient) : super(const AsyncValue.data(null));

  Future<void> createProduct(Product product) async {
    state = const AsyncValue.loading();
    try {
      await _apiClient.post(
        'product',
        data: {
          'code': product.code,
          'name': product.name,
          'description': product.description,
          'suggestedPrice': product.suggestedPrice,
          'costPrice': product.costPrice,
          'costCode': product.costCode,
          'imageUrl': product.imageUrl,
          'categoryId': 1, // Default for MVP
        },
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

class AdminProductCreateScreen extends ConsumerStatefulWidget {
  const AdminProductCreateScreen({super.key});

  @override
  ConsumerState<AdminProductCreateScreen> createState() =>
      _AdminProductCreateScreenState();
}

class _AdminProductCreateScreenState
    extends ConsumerState<AdminProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _costCodeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _costCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      code: _codeController.text,
      name: _nameController.text,
      description: _descController.text,
      suggestedPrice: double.tryParse(_priceController.text) ?? 0,
      costPrice: double.tryParse(_costController.text),
      costCode: _costCodeController.text.isNotEmpty
          ? _costCodeController.text
          : null,
      imageUrl: 'https://placehold.co/400x300/png?text=New+Product',
    );

    await ref.read(adminProductProvider.notifier).createProduct(product);

    if (mounted) {
      final state = ref.read(adminProductProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${state.error}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product Created!')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProductProvider);
    final isLoading = state is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Product Code (Unique)',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Suggested Price',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price (Secret)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Cost Code (Optional)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
