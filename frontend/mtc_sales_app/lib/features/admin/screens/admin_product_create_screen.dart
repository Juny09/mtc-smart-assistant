import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/core/api/api_client.dart';
import 'package:mtc_sales_app/features/product/models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';

import 'package:mtc_sales_app/features/product/models/category.dart';
import 'package:mtc_sales_app/features/product/models/brand.dart';
import 'package:mtc_sales_app/features/product/providers/product_repository.dart';

final adminProductProvider =
    StateNotifierProvider<AdminProductNotifier, AsyncValue<void>>((ref) {
      final apiClient = ref.read(apiClientProvider);
      return AdminProductNotifier(apiClient);
    });

class AdminProductNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiClient _apiClient;

  AdminProductNotifier(this._apiClient) : super(const AsyncValue.data(null));

  Future<void> createProduct(Product product, XFile? imageFile) async {
    state = const AsyncValue.loading();
    try {
      // 1. Create Product
      final response = await _apiClient.post(
        'product',
        data: {
          'code': product.code,
          'name': product.name,
          'description': product.description,
          'suggestedPrice': product.suggestedPrice,
          'costPrice': product.costPrice,
          'costCode': product.costCode,
          'imageUrl': product.imageUrl,
          'categoryId': product.categoryId,
          'brandId': product.brandId,
        },
      );

      // Get the created product ID from response
      // Assuming response.data is the ProductDto which has Id
      final productData = response.data;
      final productId = productData['id'];

      // 2. Upload Image if selected
      if (imageFile != null && productId != null) {
        String fileName = imageFile.name;

        MultipartFile multipartFile;
        if (kIsWeb) {
          final bytes = await imageFile.readAsBytes();
          multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
        } else {
          multipartFile = await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
          );
        }

        FormData formData = FormData.fromMap({'file': multipartFile});

        await _apiClient.post('product/$productId/images', data: formData);
      }

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
  int? _selectedCategoryId;
  int? _selectedBrandId;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await ref
                      .read(productRepositoryProvider)
                      .createCategory(controller.text);
                  // Refresh provider
                  ref.invalidate(categoriesProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add category: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddBrandDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Brand'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Brand Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                try {
                  await ref
                      .read(productRepositoryProvider)
                      .createBrand(controller.text);
                  // Refresh provider
                  ref.invalidate(brandsProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add brand: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
      imageUrl: '', // Will be updated by backend if image is uploaded
      categoryId: _selectedCategoryId,
      brandId: _selectedBrandId,
    );

    await ref
        .read(adminProductProvider.notifier)
        .createProduct(product, _selectedImage);

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
    final categoriesAsync = ref.watch(categoriesProvider);
    final brandsAsync = ref.watch(brandsProvider);
    final isLoading = state is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(
                                  _selectedImage!.path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_selectedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload image',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
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
              // Categories
              Row(
                children: [
                  Expanded(
                    child: categoriesAsync.when(
                      data: (categories) => DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategoryId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddCategoryDialog,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Brands
              Row(
                children: [
                  Expanded(
                    child: brandsAsync.when(
                      data: (brands) => DropdownButtonFormField<int>(
                        value: _selectedBrandId,
                        decoration: const InputDecoration(labelText: 'Brand'),
                        items: brands
                            .map(
                              (b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(b.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedBrandId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddBrandDialog,
                  ),
                ],
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
