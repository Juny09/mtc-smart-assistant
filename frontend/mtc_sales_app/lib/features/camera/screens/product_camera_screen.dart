import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtc_sales_app/core/api/api_client.dart';
import 'package:mtc_sales_app/features/product/models/product.dart';
import 'package:mtc_sales_app/main.dart'; // to access cameras list

class ProductCameraScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductCameraScreen({super.key, required this.product});

  @override
  ConsumerState<ProductCameraScreen> createState() => _ProductCameraScreenState();
}

class _ProductCameraScreenState extends ConsumerState<ProductCameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cameras available')),
        );
      }
      return;
    }

    // Use the first camera (usually back)
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isInitialized || _controller == null || _controller!.value.isTakingPicture) {
      return;
    }

    try {
      setState(() => _isUploading = true);
      
      final XFile image = await _controller!.takePicture();
      
      // Upload
      await _uploadImage(image);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _uploadImage(XFile image) async {
    final apiClient = ref.read(apiClientProvider);
    
    // Create FormData
    // Note: web doesn't support path, but mobile does. Assuming mobile.
    String fileName = image.path.split('/').last;
    
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path, filename: fileName),
    });

    try {
      await apiClient.post(
        'product/${widget.product.id}/images',
        data: formData,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Collect Data: ${widget.product.code}')),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_controller!),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : FloatingActionButton(
                        onPressed: _takePicture,
                        child: const Icon(Icons.camera_alt),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
