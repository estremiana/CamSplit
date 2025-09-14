import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'snackbar_utils.dart';

/// Utility class for handling error recovery and retry mechanisms
/// This class provides standardized error handling, retry logic, and user feedback
class ErrorRecovery {
  static const int _defaultMaxRetries = 3;
  static const Duration _defaultRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(seconds: 30);

  /// Retry configuration for different types of operations
  static const Map<String, RetryConfig> _retryConfigs = {
    'network': RetryConfig(maxRetries: 3, baseDelay: Duration(seconds: 1)),
    'api': RetryConfig(maxRetries: 2, baseDelay: Duration(seconds: 2)),
    'database': RetryConfig(maxRetries: 1, baseDelay: Duration(seconds: 1)),
    'file': RetryConfig(maxRetries: 2, baseDelay: Duration(seconds: 3)),
  };

  /// Execute an operation with automatic retry mechanism
  /// [operation] - The async operation to execute
  /// [context] - BuildContext for showing user feedback
  /// [operationName] - Human-readable name of the operation
  /// [retryType] - Type of retry configuration to use
  /// [onRetry] - Optional callback before each retry attempt
  /// [onSuccess] - Optional callback on successful completion
  /// [onFinalFailure] - Optional callback when all retries are exhausted
  static Future<T?> executeWithRetry<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    required String operationName,
    String retryType = 'network',
    Function(int retryCount, int maxRetries)? onRetry,
    Function(T result)? onSuccess,
    Function(dynamic error, int retryCount)? onFinalFailure,
  }) async {
    final config = _retryConfigs[retryType] ?? RetryConfig();
    int retryCount = 0;
    Duration retryDelay = config.baseDelay;

    while (retryCount <= config.maxRetries) {
      try {
        final result = await operation();
        
        if (onSuccess != null) {
          onSuccess(result);
        }
        
        return result;
      } catch (e) {
        retryCount++;
        
        if (retryCount > config.maxRetries) {
          // All retries exhausted
          _handleFinalFailure(context, operationName, e, retryCount - 1, onFinalFailure);
          return null;
        }
        
        // Show retry attempt to user
        _showRetryAttempt(context, operationName, retryCount, config.maxRetries);
        
        if (onRetry != null) {
          onRetry(retryCount, config.maxRetries);
        }
        
        // Wait before retry with exponential backoff
        await Future.delayed(retryDelay);
        retryDelay = Duration(
          seconds: (retryDelay.inSeconds * 2).clamp(1, _maxRetryDelay.inSeconds)
        );
      }
    }
    
    return null;
  }

  /// Handle different types of errors with appropriate user feedback
  /// [context] - BuildContext for showing user feedback
  /// [error] - The error that occurred
  /// [operationName] - Human-readable name of the operation
  /// [showRetryButton] - Whether to show a retry button
  /// [onRetry] - Optional retry callback
  static void handleError(
    BuildContext context,
    dynamic error,
    String operationName, {
    bool showRetryButton = true,
    VoidCallback? onRetry,
  }) {
    final errorMessage = _getUserFriendlyMessage(error, operationName);
    
    if (showRetryButton && onRetry != null) {
      _showErrorWithRetry(context, errorMessage, onRetry);
    } else {
      SnackBarUtils.showError(context, errorMessage);
    }
  }

  /// Show a dialog with error details and recovery options
  /// [context] - BuildContext for showing the dialog
  /// [error] - The error that occurred
  /// [operationName] - Human-readable name of the operation
  /// [recoveryOptions] - List of recovery options to show
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error,
    String operationName,
    List<RecoveryOption> recoveryOptions,
  ) async {
    final errorMessage = _getUserFriendlyMessage(error, operationName);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Operation Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage),
              if (kDebugMode) ...[
                SizedBox(height: 16),
                Text(
                  'Debug Info:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  error.toString(),
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
          actions: [
            ...recoveryOptions.map((option) => TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                option.onPressed();
              },
              child: Text(option.label),
            )),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Get user-friendly error message based on error type
  static String _getUserFriendlyMessage(dynamic error, String operationName) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'The operation timed out. Please try again.';
    } else if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Your session has expired. Please log in again.';
    } else if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'You don\'t have permission to perform this action.';
    } else if (errorString.contains('not found') || errorString.contains('404')) {
      return 'The requested resource was not found.';
    } else if (errorString.contains('validation') || errorString.contains('422')) {
      return 'Please check your input and try again.';
    } else if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error occurred. Please try again later.';
    } else {
      return 'Failed to $operationName. Please try again.';
    }
  }

  /// Show retry attempt notification
  static void _showRetryAttempt(
    BuildContext context,
    String operationName,
    int retryCount,
    int maxRetries,
  ) {
    SnackBarUtils.showInfo(
      context,
      'Retrying $operationName... (${retryCount}/$maxRetries)',
    );
  }

  /// Handle final failure after all retries
  static void _handleFinalFailure(
    BuildContext context,
    String operationName,
    dynamic error,
    int retryCount,
    Function(dynamic error, int retryCount)? onFinalFailure,
  ) {
    final message = 'Failed to $operationName after ${retryCount + 1} attempts.';
    SnackBarUtils.showError(context, message);
    
    if (onFinalFailure != null) {
      onFinalFailure(error, retryCount);
    }
  }

  /// Show error with retry button
  static void _showErrorWithRetry(BuildContext context, String message, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }

  /// Check if an error is recoverable
  static bool isRecoverableError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors are usually recoverable
    if (errorString.contains('network') || 
        errorString.contains('connection') || 
        errorString.contains('timeout')) {
      return true;
    }
    
    // Server errors might be temporary
    if (errorString.contains('server') || errorString.contains('500')) {
      return true;
    }
    
    // Client errors are usually not recoverable
    if (errorString.contains('unauthorized') || 
        errorString.contains('forbidden') || 
        errorString.contains('not found') ||
        errorString.contains('validation')) {
      return false;
    }
    
    return true;
  }

  /// Get recommended retry delay for an error
  static Duration getRecommendedRetryDelay(dynamic error, int retryCount) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('rate limit') || errorString.contains('429')) {
      // Rate limiting - longer delay
      return Duration(seconds: (retryCount + 1) * 5);
    } else if (errorString.contains('server') || errorString.contains('500')) {
      // Server errors - moderate delay
      return Duration(seconds: (retryCount + 1) * 2);
    } else {
      // Network errors - shorter delay
      return Duration(seconds: retryCount + 1);
    }
  }
}

/// Configuration for retry behavior
class RetryConfig {
  static const int _defaultMaxRetries = 3;
  static const Duration _defaultRetryDelay = Duration(seconds: 1);
  
  final int maxRetries;
  final Duration baseDelay;

  const RetryConfig({
    this.maxRetries = _defaultMaxRetries,
    this.baseDelay = _defaultRetryDelay,
  });
}

/// Recovery option for error dialogs
class RecoveryOption {
  final String label;
  final VoidCallback onPressed;

  const RecoveryOption({
    required this.label,
    required this.onPressed,
  });
}

/// Predefined recovery options
class RecoveryOptions {
  static RecoveryOption retry(VoidCallback onPressed) => RecoveryOption(
    label: 'Retry',
    onPressed: onPressed,
  );
  
  static RecoveryOption goBack(VoidCallback onPressed) => RecoveryOption(
    label: 'Go Back',
    onPressed: onPressed,
  );
  
  static RecoveryOption refresh(VoidCallback onPressed) => RecoveryOption(
    label: 'Refresh',
    onPressed: onPressed,
  );
  
  static RecoveryOption contactSupport(VoidCallback onPressed) => RecoveryOption(
    label: 'Contact Support',
    onPressed: onPressed,
  );
} 