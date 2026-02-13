import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/core/api/api_client.dart';

class PriceCalculatorScreen extends ConsumerStatefulWidget {
  const PriceCalculatorScreen({super.key});

  @override
  ConsumerState<PriceCalculatorScreen> createState() => _PriceCalculatorScreenState();
}

class _PriceCalculatorScreenState extends ConsumerState<PriceCalculatorScreen> {
  final _priceController = TextEditingController();
  final _codeController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _priceController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _encode() async {
    final price = _priceController.text;
    if (price.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('product/price-code/encode', queryParameters: {'price': price});
      setState(() {
        _result = 'Code: ${response.data['code']}';
        _codeController.text = response.data['code'];
      });
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _decode() async {
    final code = _codeController.text;
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('product/price-code/decode', queryParameters: {'code': code});
      setState(() {
        _result = 'Price: \$${response.data['price']}';
        _priceController.text = response.data['price'].toString();
      });
    } catch (e) {
      setState(() => _result = 'Error: Invalid Code');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Price Code Calculator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Price to Code', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$ ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _encode,
                      child: const Text('Encode ->'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Code to Price', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Enter Code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _decode,
                      child: const Text('<- Decode'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Text(
                _result,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            const SizedBox(height: 16),
            const Text(
              'Cipher Key: M A C H I N E R Y S (1-9, 0)',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
