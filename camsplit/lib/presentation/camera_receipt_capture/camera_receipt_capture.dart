import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../camera_capture/flexible_camera_capture.dart';
import '../camera_capture/config/camera_capture_modes.dart';

/// Legacy wrapper for backward compatibility
/// This maintains the existing API while using the new flexible system internally
class CameraReceiptCapture extends StatelessWidget {
  const CameraReceiptCapture({super.key});

  @override
  Widget build(BuildContext context) {
    return FlexibleCameraCapture(
      config: CameraCaptureModes.receiptMode(
        onImageCaptured: (File imageFile) async {
          // Maintain the original hardcoded behavior
          final ocrResponse = await ApiService.instance.processReceipt(imageFile);
          
          if (context.mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.receiptOcrReview,
            arguments: {
              'ocrResult': ocrResponse,
              'imagePath': imageFile.path,
            },
          );
        }
        },
        onCancel: () => Navigator.pop(context),
        onError: (String error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to process image: $error'),
            duration: const Duration(seconds: 3),
          ),
        );
        },
      ),
    );
  }
}

