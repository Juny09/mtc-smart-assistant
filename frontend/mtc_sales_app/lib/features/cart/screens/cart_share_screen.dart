import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CartShareScreen extends StatelessWidget {
  final String cartId;

  const CartShareScreen({super.key, required this.cartId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分享购物车')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '请扫描下方二维码加载购物车',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: QrImageView(
                data: cartId,
                version: QrVersions.auto,
                size: 250.0,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              'Cart ID: $cartId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
