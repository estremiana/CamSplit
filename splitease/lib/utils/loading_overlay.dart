import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;
  final double? progress;
  final bool showProgress;
  final bool isIndeterminate;
  final Widget? customIndicator;
  final VoidCallback? onCancel;

  const LoadingOverlay({
    super.key,
    this.message = 'Processing...',
    this.progress,
    this.showProgress = false,
    this.isIndeterminate = true,
    this.customIndicator,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 5.w),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom indicator or default
              if (customIndicator != null)
                customIndicator!
              else
                _buildDefaultIndicator(),
              
              SizedBox(height: 3.h),
              
              // Message
              Text(
                message,
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Progress bar
              if (showProgress) ...[
                SizedBox(height: 2.h),
                _buildProgressBar(),
              ],
              
              // Cancel button
              if (onCancel != null) ...[
                SizedBox(height: 2.h),
                _buildCancelButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIndicator() {
    if (isIndeterminate) {
      return SizedBox(
        width: 8.w,
        height: 8.w,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.lightTheme.primaryColor,
          ),
        ),
      );
    } else {
      return SizedBox(
        width: 8.w,
        height: 8.w,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          value: progress ?? 0.0,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.lightTheme.primaryColor,
          ),
        ),
      );
    }
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.lightTheme.primaryColor,
          ),
        ),
        SizedBox(height: 1.h),
        if (progress != null)
          Text(
            '${(progress! * 100).toInt()}%',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: onCancel,
      child: Text(
        'Cancel',
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.lightTheme.primaryColor,
        ),
      ),
    );
  }
}

// Loading overlay manager for global access
class LoadingOverlayManager {
  static final LoadingOverlayManager _instance = LoadingOverlayManager._internal();
  factory LoadingOverlayManager() => _instance;
  LoadingOverlayManager._internal();

  OverlayEntry? _currentOverlay;
  bool _isShowing = false;

  void show({
    required BuildContext context,
    String message = 'Processing...',
    double? progress,
    bool showProgress = false,
    bool isIndeterminate = true,
    Widget? customIndicator,
    VoidCallback? onCancel,
  }) {
    if (_isShowing) {
      hide();
    }

    _currentOverlay = OverlayEntry(
      builder: (context) => LoadingOverlay(
        message: message,
        progress: progress,
        showProgress: showProgress,
        isIndeterminate: isIndeterminate,
        customIndicator: customIndicator,
        onCancel: onCancel ?? hide,
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
    _isShowing = true;
  }

  void updateProgress(double progress) {
    if (_isShowing && _currentOverlay != null) {
      _currentOverlay!.markNeedsBuild();
    }
  }

  void updateMessage(String message) {
    if (_isShowing && _currentOverlay != null) {
      _currentOverlay!.markNeedsBuild();
    }
  }

  void hide() {
    if (_isShowing && _currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
      _isShowing = false;
    }
  }

  bool get isShowing => _isShowing;
}

// Specific loading overlays for different operations
class ReceiptProcessingOverlay extends StatelessWidget {
  final double? progress;
  final VoidCallback? onCancel;

  const ReceiptProcessingOverlay({
    super.key,
    this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      message: 'Processing receipt...',
      progress: progress,
      showProgress: progress != null,
      isIndeterminate: progress == null,
      customIndicator: _buildReceiptIndicator(),
      onCancel: onCancel,
    );
  }

  Widget _buildReceiptIndicator() {
    return Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.w / 2),
      ),
      child: Icon(
        Icons.receipt_long,
        color: AppTheme.lightTheme.primaryColor,
        size: 4.w,
      ),
    );
  }
}

class ImageCompressionOverlay extends StatelessWidget {
  final double? progress;
  final VoidCallback? onCancel;

  const ImageCompressionOverlay({
    super.key,
    this.progress,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      message: 'Optimizing image...',
      progress: progress,
      showProgress: progress != null,
      isIndeterminate: progress == null,
      customIndicator: _buildCompressionIndicator(),
      onCancel: onCancel,
    );
  }

  Widget _buildCompressionIndicator() {
    return Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.w / 2),
      ),
      child: Icon(
        Icons.compress,
        color: AppTheme.lightTheme.primaryColor,
        size: 4.w,
      ),
    );
  }
}

class CameraInitializationOverlay extends StatelessWidget {
  final String status;
  final VoidCallback? onRetry;

  const CameraInitializationOverlay({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      message: status,
      customIndicator: _buildCameraIndicator(),
      onCancel: onRetry,
    );
  }

  Widget _buildCameraIndicator() {
    return Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.w / 2),
      ),
      child: Icon(
        Icons.camera_alt,
        color: AppTheme.lightTheme.primaryColor,
        size: 4.w,
      ),
    );
  }
} 