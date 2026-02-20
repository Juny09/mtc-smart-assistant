import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/core/api/api_client.dart';
import 'package:mtc_sales_app/features/product/models/product.dart';
import 'package:mtc_sales_app/features/product/models/category.dart';
import 'package:mtc_sales_app/features/product/models/brand.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ProductRepository(apiClient);
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  return repository.getCategories();
});

final brandsProvider = FutureProvider<List<Brand>>((ref) async {
  final repository = ref.read(productRepositoryProvider);
  return repository.getBrands();
});

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository(this._apiClient);

  Future<List<Product>> searchProducts(String keyword) async {
    try {
      final response = await _apiClient.get(
        'product',
        queryParameters: {'keyword': keyword},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.get('category');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> createCategory(String name) async {
    try {
      await _apiClient.post('category', data: {'name': name});
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<List<Brand>> getBrands() async {
    try {
      final response = await _apiClient.get('brand');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Brand.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load brands');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> createBrand(String name) async {
    try {
      await _apiClient.post('brand', data: {'name': name});
    } catch (e) {
      throw Exception('Failed to create brand: $e');
    }
  }

  Future<double> getCostPrice(String code) async {
    try {
      final response = await _apiClient.post('product/$code/reveal-cost');

      if (response.statusCode == 200) {
        // Backend returns decimal, Dio parses it as double or int
        return (response.data as num).toDouble();
      } else {
        throw Exception('Failed to get cost price');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _apiClient.delete('product/$id');
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _apiClient.put(
        'product/${product.id}',
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
          'quantity': product.quantity,
        },
      );
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> batchDecreaseStock(List<Map<String, dynamic>> updates) async {
    try {
      await _apiClient.post('product/batch-decrease-stock', data: updates);
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }
}
