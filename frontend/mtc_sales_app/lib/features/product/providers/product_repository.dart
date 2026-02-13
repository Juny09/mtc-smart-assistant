import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/core/api/api_client.dart';
import 'package:mtc_sales_app/features/product/models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ProductRepository(apiClient);
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
}
