// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: json['id'] as String?,
  code: json['code'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  suggestedPrice: (json['suggestedPrice'] as num).toDouble(),
  costPrice: (json['costPrice'] as num?)?.toDouble(),
  costCode: json['costCode'] as String?,
  imageUrl: json['imageUrl'] as String?,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  brandId: (json['brandId'] as num?)?.toInt(),
  categoryName: json['categoryName'] as String?,
  brandName: json['brandName'] as String?,
  quantity: (json['quantity'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'description': instance.description,
  'suggestedPrice': instance.suggestedPrice,
  'costPrice': instance.costPrice,
  'costCode': instance.costCode,
  'imageUrl': instance.imageUrl,
  'categoryId': instance.categoryId,
  'brandId': instance.brandId,
  'categoryName': instance.categoryName,
  'brandName': instance.brandName,
  'quantity': instance.quantity,
};
