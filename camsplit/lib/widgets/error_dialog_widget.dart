import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/app_export.dart';
import '../services/error_handler_service.dart';

class ErrorDialogWidget extends StatelessWidget {
  final ErrorInfo errorInfo;
  final VoidCallback? onRetry;
  final VoidCallback? onFallback;
  final VoidCallback? onSettings;
  final VoidCallback? onGoBack;
  final bool showTechnicalDetails;

  const ErrorDialogWidget({
    super.key,
    required this.errorInfo,
    this.onRetry,
    this.onFallback,
    this.onSettings,
    this.onGoBack,
    this.showTechnicalDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: _buildTitle(),
      content: _buildContent(),
      actions: _buildActions(context),
    );
  }

  Widget _buildTitle() {
    IconData icon;
    Color iconColor;

    switch (errorInfo.severity) {
      case ErrorSeverity.critical:
        icon = Icons.error_outline;
        iconColor = Colors.red;
        break;
      case ErrorSeverity.high:
        icon = Icons.warning_amber_outlined;
        iconColor = Colors.orange;
        break;
      case ErrorSeverity.medium:
        icon = Icons.info_outline;
        iconColor = Colors.blue;
        break;
      case ErrorSeverity.low:
        icon = Icons.lightbulb_outline;
        iconColor = Colors.green;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            _getTitleText(),
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _getTitleText() {
    switch (errorInfo.type) {
      case ErrorType.permission:
        return 'Permission Required';
      case ErrorType.camera:
        return 'Camera Error';
      case ErrorType.detection:
        return 'Detection Issue';
      case ErrorType.processing:
        return 'Processing Error';
      case ErrorType.network:
        return 'Network Error';
      case ErrorType.storage:
        return 'Storage Error';
      case ErrorType.memory:
        return 'Memory Issue';
      case ErrorType.unknown:
        return 'Error';
    }
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User-friendly message
        Text(
          errorInfo.userMessage ?? errorInfo.message,
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        
        // Technical details (if enabled and available)
        if (showTechnicalDetails && errorInfo.technicalDetails != null) ...[
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Technical Details:',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  errorInfo.technicalDetails!,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Suggestions based on error type
        if (_getSuggestions().isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            'Suggestions:',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 1.h),
          ...(_getSuggestions().map((suggestion) => Padding(
            padding: EdgeInsets.only(bottom: 0.5.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.green[600],
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    suggestion,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ))),
        ],
      ],
    );
  }

  List<String> _getSuggestions() {
    switch (errorInfo.type) {
      case ErrorType.permission:
        return [
          'Go to your device settings',
          'Find the app in the permissions list',
          'Enable camera access',
        ];
      
      case ErrorType.camera:
        return [
          'Close other camera apps',
          'Restart the app',
          'Check if camera is working in other apps',
        ];
      
      case ErrorType.network:
        return [
          'Check your internet connection',
          'Try switching between WiFi and mobile data',
          'Restart your router if using WiFi',
        ];
      
      case ErrorType.storage:
        return [
          'Free up space on your device',
          'Delete unnecessary files and apps',
          'Move photos to cloud storage',
        ];
      
      case ErrorType.memory:
        return [
          'Close other apps to free memory',
          'Restart your device',
          'Try again in a few moments',
        ];
      
      default:
        return [
          'Try again',
          'Restart the app if the problem persists',
        ];
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    // Primary action based on error severity and type
    if (errorInfo.canRetry && onRetry != null) {
      actions.add(
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
      );
    } else if (errorInfo.hasFallback && onFallback != null) {
      actions.add(
        ElevatedButton(
          onPressed: onFallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Continue'),
        ),
      );
    }

    // Secondary actions
    if (errorInfo.type == ErrorType.permission && onSettings != null) {
      actions.add(
        TextButton(
          onPressed: onSettings,
          child: const Text('Settings'),
        ),
      );
    }

    // Cancel/Go Back action
    if (onGoBack != null) {
      actions.add(
        TextButton(
          onPressed: onGoBack,
          child: const Text('Go Back'),
        ),
      );
    } else {
      actions.add(
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      );
    }

    return actions;
  }
}

// Convenience method to show error dialog
class ErrorDialogHelper {
  static Future<void> showErrorDialog({
    required BuildContext context,
    required dynamic error,
    ErrorType? errorType,
    VoidCallback? onRetry,
    VoidCallback? onFallback,
    VoidCallback? onSettings,
    VoidCallback? onGoBack,
    bool showTechnicalDetails = false,
  }) async {
    final errorHandler = ErrorHandlerService.instance;
    final errorInfo = errorHandler.handleError(error, errorType);

    return showDialog(
      context: context,
      barrierDismissible: errorInfo.severity != ErrorSeverity.critical,
      builder: (context) => ErrorDialogWidget(
        errorInfo: errorInfo,
        onRetry: onRetry,
        onFallback: onFallback,
        onSettings: onSettings,
        onGoBack: onGoBack,
        showTechnicalDetails: showTechnicalDetails,
      ),
    );
  }

  static Future<void> showPermissionErrorDialog({
    required BuildContext context,
    required PermissionStatus status,
    VoidCallback? onRetry,
    VoidCallback? onSettings,
    VoidCallback? onGoBack,
  }) async {
    final errorHandler = ErrorHandlerService.instance;
    final errorInfo = errorHandler.handlePermissionError(status);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialogWidget(
        errorInfo: errorInfo,
        onRetry: onRetry,
        onSettings: onSettings,
        onGoBack: onGoBack,
      ),
    );
  }

  static Future<void> showCameraErrorDialog({
    required BuildContext context,
    required dynamic error,
    VoidCallback? onRetry,
    VoidCallback? onFallback,
    VoidCallback? onGoBack,
  }) async {
    final errorHandler = ErrorHandlerService.instance;
    final errorInfo = errorHandler.handleCameraInitializationError(error);

    return showDialog(
      context: context,
      barrierDismissible: errorInfo.severity != ErrorSeverity.critical,
      builder: (context) => ErrorDialogWidget(
        errorInfo: errorInfo,
        onRetry: onRetry,
        onFallback: onFallback,
        onGoBack: onGoBack,
      ),
    );
  }

  static Future<void> showNetworkErrorDialog({
    required BuildContext context,
    required dynamic error,
    VoidCallback? onRetry,
    VoidCallback? onGoBack,
  }) async {
    final errorHandler = ErrorHandlerService.instance;
    final errorInfo = errorHandler.handleNetworkError(error);

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ErrorDialogWidget(
        errorInfo: errorInfo,
        onRetry: onRetry,
        onGoBack: onGoBack,
      ),
    );
  }

  static Future<void> showStorageErrorDialog({
    required BuildContext context,
    required dynamic error,
    VoidCallback? onRetry,
    VoidCallback? onGoBack,
  }) async {
    final errorHandler = ErrorHandlerService.instance;
    final errorInfo = errorHandler.handleStorageError(error);

    return showDialog(
      context: context,
      barrierDismissible: errorInfo.severity != ErrorSeverity.critical,
      builder: (context) => ErrorDialogWidget(
        errorInfo: errorInfo,
        onRetry: onRetry,
        onGoBack: onGoBack,
      ),
    );
  }
}
