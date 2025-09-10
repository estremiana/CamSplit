import 'package:flutter/material.dart';

class CameraCaptureTheme {
  final String captureButtonText;
  final String retakeButtonText;
  final String cropButtonText;
  final String usePhotoButtonText;
  final String processingText;
  final String? instructionText;
  
  final Color primaryColor;
  final Color backgroundColor;
  final Color overlayColor;
  final Color textColor;
  final Color buttonColor;
  
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? buttonStyle;
  final TextStyle? instructionStyle;
  
  final double borderRadius;
  final double buttonHeight;
  final EdgeInsets buttonPadding;
  
  const CameraCaptureTheme({
    this.captureButtonText = 'Capture',
    this.retakeButtonText = 'Retake',
    this.cropButtonText = 'Crop',
    this.usePhotoButtonText = 'Use Photo',
    this.processingText = 'Processing...',
    this.instructionText,
    this.primaryColor = const Color(0xFF2196F3),
    this.backgroundColor = Colors.black,
    this.overlayColor = const Color(0x80000000),
    this.textColor = Colors.white,
    this.buttonColor = Colors.white,
    this.titleStyle,
    this.subtitleStyle,
    this.buttonStyle,
    this.instructionStyle,
    this.borderRadius = 12.0,
    this.buttonHeight = 48.0,
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });
  
  // Predefined themes
  static const CameraCaptureTheme receipt = CameraCaptureTheme(
    captureButtonText: 'Capture Receipt',
    usePhotoButtonText: 'Use Photo',
    processingText: 'Processing...',
    instructionText: 'Position the receipt within the frame and capture',
    primaryColor: Color(0xFF4CAF50),
  );
  
  static const CameraCaptureTheme document = CameraCaptureTheme(
    captureButtonText: 'Capture Document',
    usePhotoButtonText: 'Save Document',
    processingText: 'Processing document...',
    instructionText: 'Ensure the document is clearly visible',
    primaryColor: Color(0xFF2196F3),
  );
  
  static const CameraCaptureTheme general = CameraCaptureTheme(
    captureButtonText: 'Take Photo',
    usePhotoButtonText: 'Use Photo',
    processingText: 'Processing...',
    instructionText: 'Tap to capture your photo',
    primaryColor: Color(0xFF9C27B0),
  );
}
