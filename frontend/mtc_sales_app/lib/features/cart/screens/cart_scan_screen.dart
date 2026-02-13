import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mtc_sales_app/features/cart/providers/cart_provider.dart';

class CartScanScreen extends ConsumerStatefulWidget {
  const CartScanScreen({super.key});

  @override
  ConsumerState<CartScanScreen> createState() => _CartScanScreenState();
}

class _CartScanScreenState extends ConsumerState<CartScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫描购物车二维码')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) async {
          if (_isProcessing) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null && code.isNotEmpty) {
              setState(() {
                _isProcessing = true;
              });
              
              try {
                // Assuming the QR code contains just the Cart ID (UUID)
                await ref.read(cartProvider.notifier).setCartId(code);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('购物车已同步成功！'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('同步失败: $e'), 
                      backgroundColor: Colors.red
                    ),
                  );
                  // Allow scanning again after delay
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) {
                    setState(() {
                      _isProcessing = false;
                    });
                  }
                }
              }
              break; // Only process first valid code
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
