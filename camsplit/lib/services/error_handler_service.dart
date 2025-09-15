import 'package:permission_handler/permission_handler.dart';

// Error types for categorization
enum ErrorType {
  permission,
  camera,
  detection,
  processing,
  network,
  storage,
  memory,
  unknown,
}

// Error severity levels
enum ErrorSeverity {
  low,      // Non-critical, can continue
  medium,   // Affects functionality but recoverable
  high,     // Critical, requires user intervention
  critical, // Fatal, cannot continue
}

// Error information structure
class ErrorInfo {
  final ErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String? userMessage;
  final String? technicalDetails;
  final bool canRetry;
  final bool hasFallback;
  final Duration? retryDelay;

  const ErrorInfo({
    required this.type,
    required this.severity,
    required this.message,
    this.userMessage,
    this.technicalDetails,
    this.canRetry = false,
    this.hasFallback = false,
    this.retryDelay,
  });
}

class ErrorHandlerService {
  static ErrorHandlerService? _instance;
  ErrorHandlerService._();

  static ErrorHandlerService get instance {
    _instance ??= ErrorHandlerService._();
    return _instance!;
  }

  // Handle camera permission errors
  ErrorInfo handlePermissionError(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.denied:
        return const ErrorInfo(
          type: ErrorType.permission,
          severity: ErrorSeverity.high,
          message: 'Camera permission denied',
          userMessage: 'Camera access is required to capture receipts. Please grant camera permission in your device settings.',
          canRetry: true,
          hasFallback: true,
        );
      
      case PermissionStatus.permanentlyDenied:
        return const ErrorInfo(
          type: ErrorType.permission,
          severity: ErrorSeverity.critical,
          message: 'Camera permission permanently denied',
          userMessage: 'Camera access has been permanently denied. Please enable it in your device settings to use this feature.',
          canRetry: false,
          hasFallback: true,
        );
      
      case PermissionStatus.restricted:
        return const ErrorInfo(
          type: ErrorType.permission,
          severity: ErrorSeverity.critical,
          message: 'Camera permission restricted',
          userMessage: 'Camera access is restricted on your device. Please check your device settings or contact support.',
          canRetry: false,
          hasFallback: true,
        );
      
      default:
        return const ErrorInfo(
          type: ErrorType.permission,
          severity: ErrorSeverity.medium,
          message: 'Camera permission error',
          userMessage: 'There was an issue with camera permissions. Please try again.',
          canRetry: true,
          hasFallback: true,
        );
    }
  }

  // Handle camera initialization errors
  ErrorInfo handleCameraInitializationError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('no cameras available')) {
      return const ErrorInfo(
        type: ErrorType.camera,
        severity: ErrorSeverity.critical,
        message: 'No cameras available',
        userMessage: 'No camera was found on your device. Please check your device hardware.',
        canRetry: false,
        hasFallback: true,
      );
    }
    
    if (errorString.contains('camera in use')) {
      return const ErrorInfo(
        type: ErrorType.camera,
        severity: ErrorSeverity.medium,
        message: 'Camera in use by another application',
        userMessage: 'The camera is being used by another app. Please close other camera apps and try again.',
        canRetry: true,
        hasFallback: true,
        retryDelay: Duration(seconds: 2),
      );
    }
    
    if (errorString.contains('timeout')) {
      return const ErrorInfo(
        type: ErrorType.camera,
        severity: ErrorSeverity.medium,
        message: 'Camera initialization timeout',
        userMessage: 'Camera initialization took too long. Please try again.',
        canRetry: true,
        hasFallback: true,
        retryDelay: Duration(seconds: 3),
      );
    }
    
    if (errorString.contains('permission')) {
      return handlePermissionError(PermissionStatus.denied);
    }
    
    return ErrorInfo(
      type: ErrorType.camera,
      severity: ErrorSeverity.high,
      message: 'Camera initialization failed: $error',
      userMessage: 'Failed to initialize camera. Please try again or restart the app.',
      technicalDetails: error.toString(),
      canRetry: true,
      hasFallback: true,
    );
  }

  // Handle detection service errors
  ErrorInfo handleDetectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('memory')) {
      return const ErrorInfo(
        type: ErrorType.memory,
        severity: ErrorSeverity.medium,
        message: 'Detection memory error',
        userMessage: 'Low memory detected. Receipt detection has been disabled to improve performance.',
        canRetry: false,
        hasFallback: true,
      );
    }
    
    if (errorString.contains('processing')) {
      return const ErrorInfo(
        type: ErrorType.processing,
        severity: ErrorSeverity.low,
        message: 'Detection processing error',
        userMessage: 'Receipt detection is temporarily unavailable. You can still capture photos manually.',
        canRetry: true,
        hasFallback: true,
        retryDelay: Duration(seconds: 5),
      );
    }
    
    return ErrorInfo(
      type: ErrorType.detection,
      severity: ErrorSeverity.low,
      message: 'Detection error: $error',
      userMessage: 'Receipt detection encountered an issue. You can still capture photos manually.',
      technicalDetails: error.toString(),
      canRetry: true,
      hasFallback: true,
    );
  }

  // Handle image processing errors
  ErrorInfo handleImageProcessingError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('storage')) {
      return const ErrorInfo(
        type: ErrorType.storage,
        severity: ErrorSeverity.high,
        message: 'Storage error during image processing',
        userMessage: 'Unable to save image due to storage issues. Please check your device storage.',
        canRetry: true,
        hasFallback: false,
      );
    }
    
    if (errorString.contains('memory')) {
      return const ErrorInfo(
        type: ErrorType.memory,
        severity: ErrorSeverity.medium,
        message: 'Memory error during image processing',
        userMessage: 'Low memory detected. Image quality has been reduced to continue.',
        canRetry: false,
        hasFallback: true,
      );
    }
    
    if (errorString.contains('format')) {
      return const ErrorInfo(
        type: ErrorType.processing,
        severity: ErrorSeverity.medium,
        message: 'Unsupported image format',
        userMessage: 'The image format is not supported. Please try a different image.',
        canRetry: true,
        hasFallback: true,
      );
    }
    
    return ErrorInfo(
      type: ErrorType.processing,
      severity: ErrorSeverity.medium,
      message: 'Image processing error: $error',
      userMessage: 'Failed to process image. Please try again.',
      technicalDetails: error.toString(),
      canRetry: true,
      hasFallback: true,
    );
  }

  // Handle network errors
  ErrorInfo handleNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout')) {
      return const ErrorInfo(
        type: ErrorType.network,
        severity: ErrorSeverity.medium,
        message: 'Network timeout',
        userMessage: 'Network request timed out. Please check your internet connection and try again.',
        canRetry: true,
        hasFallback: false,
        retryDelay: Duration(seconds: 5),
      );
    }
    
    if (errorString.contains('connection')) {
      return const ErrorInfo(
        type: ErrorType.network,
        severity: ErrorSeverity.high,
        message: 'No network connection',
        userMessage: 'No internet connection available. Please check your network settings.',
        canRetry: true,
        hasFallback: false,
      );
    }
    
    return ErrorInfo(
      type: ErrorType.network,
      severity: ErrorSeverity.medium,
      message: 'Network error: $error',
      userMessage: 'Network error occurred. Please try again.',
      technicalDetails: error.toString(),
      canRetry: true,
      hasFallback: false,
    );
  }

  // Handle storage errors
  ErrorInfo handleStorageError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('full')) {
      return const ErrorInfo(
        type: ErrorType.storage,
        severity: ErrorSeverity.critical,
        message: 'Storage full',
        userMessage: 'Your device storage is full. Please free up some space and try again.',
        canRetry: false,
        hasFallback: false,
      );
    }
    
    if (errorString.contains('permission')) {
      return const ErrorInfo(
        type: ErrorType.storage,
        severity: ErrorSeverity.high,
        message: 'Storage permission denied',
        userMessage: 'Storage permission is required to save images. Please grant permission in settings.',
        canRetry: true,
        hasFallback: false,
      );
    }
    
    return ErrorInfo(
      type: ErrorType.storage,
      severity: ErrorSeverity.high,
      message: 'Storage error: $error',
      userMessage: 'Failed to access storage. Please check your device settings.',
      technicalDetails: error.toString(),
      canRetry: true,
      hasFallback: false,
    );
  }

  // Generic error handler
  ErrorInfo handleGenericError(dynamic error) {
    return ErrorInfo(
      type: ErrorType.unknown,
      severity: ErrorSeverity.medium,
      message: 'Unknown error: $error',
      userMessage: 'An unexpected error occurred. Please try again.',
      technicalDetails: error.toString(),
      canRetry: true,
      hasFallback: true,
    );
  }

  // Main error handling method
  ErrorInfo handleError(dynamic error, ErrorType? expectedType) {
    try {
      // Handle specific error types
      if (expectedType == ErrorType.permission && error is PermissionStatus) {
        return handlePermissionError(error);
      }
      
      if (expectedType == ErrorType.camera) {
        return handleCameraInitializationError(error);
      }
      
      if (expectedType == ErrorType.detection) {
        return handleDetectionError(error);
      }
      
      if (expectedType == ErrorType.processing) {
        return handleImageProcessingError(error);
      }
      
      if (expectedType == ErrorType.network) {
        return handleNetworkError(error);
      }
      
      if (expectedType == ErrorType.storage) {
        return handleStorageError(error);
      }
      
      // Auto-detect error type based on error message
      final errorString = error.toString().toLowerCase();
      
      if (errorString.contains('permission')) {
        return handlePermissionError(PermissionStatus.denied);
      }
      
      if (errorString.contains('camera') || errorString.contains('initialization')) {
        return handleCameraInitializationError(error);
      }
      
      if (errorString.contains('detection') || errorString.contains('processing')) {
        return handleDetectionError(error);
      }
      
      if (errorString.contains('network') || errorString.contains('connection')) {
        return handleNetworkError(error);
      }
      
      if (errorString.contains('storage') || errorString.contains('file')) {
        return handleStorageError(error);
      }
      
      if (errorString.contains('memory')) {
        return handleImageProcessingError(error);
      }
      
      // Default to generic error handler
      return handleGenericError(error);
      
    } catch (e) {
      // Fallback to generic error handler if error handling itself fails
      return handleGenericError(error);
    }
  }

  // Get appropriate action for error
  String getActionForError(ErrorInfo errorInfo) {
    if (errorInfo.canRetry) {
      return 'Retry';
    }
    
    if (errorInfo.hasFallback) {
      return 'Continue';
    }
    
    switch (errorInfo.severity) {
      case ErrorSeverity.critical:
        return 'Go Back';
      case ErrorSeverity.high:
        return 'Settings';
      case ErrorSeverity.medium:
        return 'OK';
      case ErrorSeverity.low:
        return 'Continue';
    }
  }

  // Check if error should show technical details
  bool shouldShowTechnicalDetails(ErrorInfo errorInfo) {
    return errorInfo.technicalDetails != null && 
           (errorInfo.severity == ErrorSeverity.high || 
            errorInfo.severity == ErrorSeverity.critical);
  }

  // Get retry delay for error
  Duration? getRetryDelay(ErrorInfo errorInfo) {
    return errorInfo.retryDelay ?? const Duration(seconds: 2);
  }
}
