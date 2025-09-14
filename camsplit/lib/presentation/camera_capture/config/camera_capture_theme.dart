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
    primaryColor: Color(0xFF2563EB), // Using app's primary blue color
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
  
  // CopyWith method for creating modified themes
  CameraCaptureTheme copyWith({
    String? captureButtonText,
    String? retakeButtonText,
    String? cropButtonText,
    String? usePhotoButtonText,
    String? processingText,
    String? instructionText,
    Color? primaryColor,
    Color? backgroundColor,
    Color? overlayColor,
    Color? textColor,
    Color? buttonColor,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    TextStyle? buttonStyle,
    TextStyle? instructionStyle,
    double? borderRadius,
    double? buttonHeight,
    EdgeInsets? buttonPadding,
  }) {
    return CameraCaptureTheme(
      captureButtonText: captureButtonText ?? this.captureButtonText,
      retakeButtonText: retakeButtonText ?? this.retakeButtonText,
      cropButtonText: cropButtonText ?? this.cropButtonText,
      usePhotoButtonText: usePhotoButtonText ?? this.usePhotoButtonText,
      processingText: processingText ?? this.processingText,
      instructionText: instructionText ?? this.instructionText,
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      overlayColor: overlayColor ?? this.overlayColor,
      textColor: textColor ?? this.textColor,
      buttonColor: buttonColor ?? this.buttonColor,
      titleStyle: titleStyle ?? this.titleStyle,
      subtitleStyle: subtitleStyle ?? this.subtitleStyle,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      instructionStyle: instructionStyle ?? this.instructionStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      buttonPadding: buttonPadding ?? this.buttonPadding,
    );
  }
}
