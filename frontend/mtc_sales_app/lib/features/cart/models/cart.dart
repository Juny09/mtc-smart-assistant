import 'package:json_annotation/json_annotation.dart';

part 'cart.g.dart';

@JsonSerializable()
class CartItem {
  final String productId;
  final String productName;
  final String productCode;
  final double price;
  final int quantity;
  final String imageUrl;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemToJson(this);
}

@JsonSerializable()
class Cart {
  final String id;
  final List<CartItem> items;
  final double totalAmount;

  Cart({
    required this.id,
    required this.items,
    required this.totalAmount,
  });

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
  Map<String, dynamic> toJson() => _$CartToJson(this);
}
