import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../config/camera_capture_config.dart';
import '../../camera_receipt_capture/widgets/receipt_image_cropper_widget.dart';

class FlexibleReceiptPreviewWidget extends StatefulWidget {
  final CameraCaptureConfig config;
  final String imagePath;
  final VoidCallback onRetake;
  final Function(File imageFile) onUse;
  final bool isProcessing;

  const FlexibleReceiptPreviewWidget({
    super.key,
    required this.config,
    required this.imagePath,
    required this.onRetake,
    required this.onUse,
    required this.isProcessing,
  });

  @override
  State<FlexibleReceiptPreviewWidget> createState() => _FlexibleReceiptPreviewWidgetState();
}

class _FlexibleReceiptPreviewWidgetState extends State<FlexibleReceiptPreviewWidget> {
  File? _currentImageFile;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _currentImageFile = File(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.w,
      height: 100.h,
      color: widget.config.theme.backgroundColor,
      child: Column(
        children: [
          // Preview Header
          _buildPreviewHeader(),

          // Image Preview
          Expanded(
            child: _buildImagePreview(),
          ),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'photo_camera',
            color: widget.config.theme.textColor,
            size: 24,
          ),
          SizedBox(width: 3.w),
          Text(
            'Receipt Preview',
            style: widget.config.theme.titleStyle?.copyWith(
              color: widget.config.theme.textColor,
            ) ?? AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: widget.config.theme.textColor,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Receipt Image
            CustomImageWidget(
              imageUrl: _currentImageFile?.path ?? widget.imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
            ),

            // Processing Overlay
            if (widget.isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: widget.config.theme.primaryColor),
                      SizedBox(height: 3.h),
                      Text(
                        widget.config.theme.processingText,
                        style: widget.config.theme.titleStyle?.copyWith(
                          color: widget.config.theme.textColor,
                        ) ?? AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: widget.config.theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          // Instructions
          if (widget.config.showInstructions && widget.config.theme.instructionText != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      widget.config.theme.instructionText!,
                      style: widget.config.theme.instructionStyle?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ) ?? AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          if (widget.config.showInstructions && widget.config.theme.instructionText != null)
            SizedBox(height: 3.h),
          
          // Action Buttons
          Row(
            children: [
              // Retake Button
              Expanded(
                child: OutlinedButton(
                  onPressed: (widget.isProcessing || _isCropping) ? null : _handleRetake,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.config.theme.textColor,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'refresh',
                        color: widget.config.theme.textColor,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        widget.config.theme.retakeButtonText,
                        style: widget.config.theme.buttonStyle?.copyWith(
                          color: widget.config.theme.textColor,
                        ) ?? AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: widget.config.theme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 3.w),

              // Crop Button (if enabled)
              if (widget.config.enableCrop) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: (widget.isProcessing || _isCropping) ? null : _handleCrop,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.config.theme.textColor,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'crop',
                          color: widget.config.theme.textColor,
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          widget.config.theme.cropButtonText,
                          style: widget.config.theme.buttonStyle?.copyWith(
                            color: widget.config.theme.textColor,
                          ) ?? AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                            color: widget.config.theme.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 3.w),
              ],

              // Use Photo Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (widget.isProcessing || _isCropping) ? null : _handleUsePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.config.theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isProcessing) ...[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          widget.config.theme.processingText,
                          style: widget.config.theme.buttonStyle?.copyWith(
                            color: Colors.white,
                          ) ?? AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ] else ...[
                        CustomIconWidget(
                          iconName: 'check',
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          widget.config.theme.usePhotoButtonText,
                          style: widget.config.theme.buttonStyle?.copyWith(
                            color: Colors.white,
                          ) ?? AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleRetake() {
    HapticFeedback.lightImpact();
    widget.onRetake();
  }

  void _handleCrop() async {
    if (_currentImageFile == null) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isCropping = true;
    });

    try {
      final File? croppedImage = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptImageCropperWidget(
            imageFile: _currentImageFile!,
            onCropComplete: (File croppedFile) {
              Navigator.pop(context, croppedFile);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        ),
      );

      if (croppedImage != null) {
        setState(() {
          _currentImageFile = croppedImage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to crop image: $e'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    } finally {
      setState(() {
        _isCropping = false;
      });
    }
  }

  void _handleUsePhoto() {
    HapticFeedback.mediumImpact();
    if (_currentImageFile != null) {
      widget.onUse(_currentImageFile!);
    }
  }
}
