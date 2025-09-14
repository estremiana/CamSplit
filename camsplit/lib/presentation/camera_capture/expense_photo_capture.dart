import 'dart:io';
import 'package:flutter/material.dart';

import 'flexible_camera_capture.dart';
import 'config/camera_capture_modes.dart';

/// Helper class for expense photo capture workflow
class ExpensePhotoCapture {
  /// Shows the camera interface for capturing/selecting a photo for expense creation
  /// Returns the image file path if successful, null if cancelled
  static Future<String?> showExpensePhotoCapture(BuildContext context) async {
    String? capturedImagePath;
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlexibleCameraCapture(
          config: CameraCaptureModes.expensePhotoMode(
            onImageCaptured: (File imageFile) async {
              // Return the image file path
              capturedImagePath = imageFile.path;
              Navigator.pop(context, imageFile.path);
            },
            onCancel: () => Navigator.pop(context),
            onError: (String error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Camera error: $error'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ),
      ),
    );
    
    return capturedImagePath;
  }
  
  /// Shows the camera interface and returns the result as a Map
  /// This maintains compatibility with the existing expense creation flow
  static Future<Map<String, dynamic>?> showExpensePhotoCaptureWithResult(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlexibleCameraCapture(
          config: CameraCaptureModes.expensePhotoMode(
            onImageCaptured: (File imageFile) async {
              // Return success result with image path
              Navigator.pop(context, {
                'success': true,
                'imagePath': imageFile.path,
                'imageFile': imageFile,
              });
            },
            onCancel: () => Navigator.pop(context),
            onError: (String error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Camera error: $error'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ),
      ),
    );
    
    return result as Map<String, dynamic>?;
  }
}
