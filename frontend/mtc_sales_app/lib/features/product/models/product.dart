import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable()
class Product {
  final String? id; // Backend might send ID or not depending on DTO
  final String code;
  final String name;
  final String description;
  final double suggestedPrice;
  final double? costPrice; // Nullable, fetched only after auth
  final String? costCode;
  final String? imageUrl;
  final int? categoryId;
  final int? brandId;
  final String? categoryName;
  final String? brandName;
  final int quantity;

  Product({
    this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.suggestedPrice,
    this.costPrice,
    this.costCode,
    this.imageUrl,
    this.categoryId,
    this.brandId,
    this.categoryName,
    this.brandName,
    this.quantity = 0,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}
