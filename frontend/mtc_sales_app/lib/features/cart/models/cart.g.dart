// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartItem _$CartItemFromJson(Map<String, dynamic> json) => CartItem(
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  productCode: json['productCode'] as String,
  price: (json['price'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  imageUrl: json['imageUrl'] as String,
);

Map<String, dynamic> _$CartItemToJson(CartItem instance) => <String, dynamic>{
  'productId': instance.productId,
  'productName': instance.productName,
  'productCode': instance.productCode,
  'price': instance.price,
  'quantity': instance.quantity,
  'imageUrl': instance.imageUrl,
};

Cart _$CartFromJson(Map<String, dynamic> json) => Cart(
  id: json['id'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
);

Map<String, dynamic> _$CartToJson(Cart instance) => <String, dynamic>{
  'id': instance.id,
  'items': instance.items,
  'totalAmount': instance.totalAmount,
};
