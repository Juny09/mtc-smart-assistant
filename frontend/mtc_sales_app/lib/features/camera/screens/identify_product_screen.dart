import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/core/api/api_client.dart';
import 'package:mtc_sales_app/main.dart';

import 'package:flutter/services.dart';

class IdentifyProductScreen extends ConsumerStatefulWidget {
  const IdentifyProductScreen({super.key});

  @override
  ConsumerState<IdentifyProductScreen> createState() =>
      _IdentifyProductScreenState();
}

class _IdentifyProductScreenState extends ConsumerState<IdentifyProductScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No cameras available')));
      }
      return;
    }

    _controller = CameraController(cameras[0], ResolutionPreset.medium);

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _identify() async {
    if (!_isInitialized ||
        _controller == null ||
        _controller!.value.isTakingPicture) {
      return;
    }

    try {
      setState(() => _isAnalyzing = true);

      final XFile image = await _controller!.takePicture();
      await _uploadAndAnalyze(image);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _uploadAndAnalyze(XFile image) async {
    final apiClient = ref.read(apiClientProvider);

    String fileName = image.path.split('/').last;
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path, filename: fileName),
    });

    try {
      final response = await apiClient.post('ai/identify', data: formData);

      final data = response.data;
      final productName = data['productName'];
      final productCode = data['productCode'];
      final confidence = (data['confidence'] * 100).toStringAsFixed(1);

      if (mounted) {
        // Show result dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('AI Identification'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detected: $productName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Code: $productCode'),
                Text('Confidence: $confidence%'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: productCode));
                  Navigator.pop(context);
                  Navigator.pop(
                    context,
                    productCode,
                  ); // Return result to previous screen if possible
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied $productCode to clipboard')),
                  );
                },
                child: const Text('Copy Code'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Identification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AI Identify')),
      body: Column(
        children: [
          Expanded(child: CameraPreview(_controller!)),
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isAnalyzing
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Analyzing...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : FloatingActionButton.extended(
                        onPressed: _identify,
                        icon: const Icon(Icons.search),
                        label: const Text('Identify'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
