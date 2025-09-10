import 'dart:io';
import 'package:flutter/material.dart';
import 'camera_capture_config.dart';
import 'camera_capture_theme.dart';
import 'camera_capture_mode.dart';

class CameraCaptureModes {
  static CameraCaptureConfig receiptMode({
    required ImageProcessingCallback onImageCaptured,
    VoidCallback? onCancel,
    ErrorHandlerCallback? onError,
  }) {
    return CameraCaptureConfig(
      title: 'Receipt Capture',
      subtitle: 'Position the receipt within the frame',
      mode: CameraCaptureMode.receipt,
      onImageCaptured: onImageCaptured,
      onCancel: onCancel,
      onError: onError,
      enableCrop: true,
      enableGallery: true,
      enableFlash: true,
      enableCameraSwitch: true,
      showInstructions: true,
      theme: CameraCaptureTheme.receipt,
    );
  }
  
  static CameraCaptureConfig documentMode({
    required ImageProcessingCallback onImageCaptured,
    VoidCallback? onCancel,
    ErrorHandlerCallback? onError,
  }) {
    return CameraCaptureConfig(
      title: 'Document Capture',
      subtitle: 'Ensure the document is clearly visible',
      mode: CameraCaptureMode.document,
      onImageCaptured: onImageCaptured,
      onCancel: onCancel,
      onError: onError,
      enableCrop: true,
      enableGallery: true,
      enableFlash: false,
      enableCameraSwitch: false,
      showInstructions: true,
      theme: CameraCaptureTheme.document,
    );
  }
  
  static CameraCaptureConfig generalMode({
    required ImageProcessingCallback onImageCaptured,
    VoidCallback? onCancel,
    ErrorHandlerCallback? onError,
  }) {
    return CameraCaptureConfig(
      title: 'Take Photo',
      subtitle: 'Tap to capture your photo',
      mode: CameraCaptureMode.general,
      onImageCaptured: onImageCaptured,
      onCancel: onCancel,
      onError: onError,
      enableCrop: false,
      enableGallery: true,
      enableFlash: true,
      enableCameraSwitch: true,
      showInstructions: false,
      theme: CameraCaptureTheme.general,
    );
  }
}
