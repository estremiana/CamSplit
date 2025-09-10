enum CameraCaptureMode {
  receipt,    // Receipt scanning with OCR
  document,   // Document scanning
  general,    // General photo capture
  custom,     // Fully customizable
}

extension CameraCaptureModeExtension on CameraCaptureMode {
  String get displayName {
    switch (this) {
      case CameraCaptureMode.receipt:
        return 'Receipt Capture';
      case CameraCaptureMode.document:
        return 'Document Capture';
      case CameraCaptureMode.general:
        return 'Photo Capture';
      case CameraCaptureMode.custom:
        return 'Custom Capture';
    }
  }
  
  bool get requiresProcessing {
    switch (this) {
      case CameraCaptureMode.receipt:
      case CameraCaptureMode.document:
        return true;
      case CameraCaptureMode.general:
      case CameraCaptureMode.custom:
        return false;
    }
  }
}
