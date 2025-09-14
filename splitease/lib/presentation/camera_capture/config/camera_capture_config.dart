import 'dart:io';
import 'package:flutter/material.dart';
import 'camera_capture_mode.dart';
import 'camera_capture_theme.dart';

typedef ImageProcessingCallback = Future<void> Function(File imageFile);
typedef ErrorHandlerCallback = void Function(String error);

class CameraCaptureConfig {
  final String title;
  final String? subtitle;
  final CameraCaptureMode mode;
  final ImageProcessingCallback? onImageCaptured;
  final VoidCallback? onCancel;
  final ErrorHandlerCallback? onError;
  
  // Feature toggles
  final bool enableCrop;
  final bool enableGallery;
  final bool enableFlash;
  final bool enableCameraSwitch;
  final bool showInstructions;
  
  // UI customization
  final CameraCaptureTheme theme;
  
  // Custom actions
  final List<CameraAction> customActions;
  
  const CameraCaptureConfig({
    required this.title,
    this.subtitle,
    required this.mode,
    this.onImageCaptured,
    this.onCancel,
    this.onError,
    this.enableCrop = true,
    this.enableGallery = true,
    this.enableFlash = true,
    this.enableCameraSwitch = true,
    this.showInstructions = true,
    this.theme = const CameraCaptureTheme(),
    this.customActions = const [],
  });
}

class CameraAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  
  const CameraAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });
}
