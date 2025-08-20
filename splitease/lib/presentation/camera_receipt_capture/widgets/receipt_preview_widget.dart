import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/receipt_detection_service.dart';
import 'receipt_image_cropper_widget.dart';

class ReceiptPreviewWidget extends StatefulWidget {
  final String imagePath;
  final VoidCallback onRetake;
  final VoidCallback onUse;
  final bool isProcessing;
  final DetectionResult? detectionResult;

  const ReceiptPreviewWidget({
    super.key,
    required this.imagePath,
    required this.onRetake,
    required this.onUse,
    required this.isProcessing,
    this.detectionResult,
  });

  @override
  State<ReceiptPreviewWidget> createState() => _ReceiptPreviewWidgetState();
}

class _ReceiptPreviewWidgetState extends State<ReceiptPreviewWidget> {
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
      color: Colors.black,
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
            color: Colors.white,
            size: 24,
          ),
          SizedBox(width: 3.w),
          Text(
            'Receipt Preview',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.successLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.successLight.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.successLight,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Captured',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.successLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
                      Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Analyzing Receipt...',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Extracting items and amounts',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Detection Status Indicator (if available)
            if (!widget.isProcessing && widget.detectionResult != null)
              _buildDetectionStatusIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionStatusIndicator() {
    final detectionResult = widget.detectionResult!;
    
    return Positioned(
      top: 2.h,
      right: 2.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: _getDetectionColor(detectionResult).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: _getDetectionIcon(detectionResult),
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 1.w),
            Text(
              _getDetectionText(detectionResult),
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (detectionResult.confidence > 0.0) ...[
              SizedBox(width: 1.w),
              Text(
                '${(detectionResult.confidence * 100).toInt()}%',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDetectionColor(DetectionResult result) {
    if (result.isDetected) {
      final confidence = result.confidence;
      if (confidence >= 0.8) return Colors.green;
      if (confidence >= 0.6) return Colors.orange;
      return Colors.red;
    }
    return Colors.grey;
  }

  String _getDetectionIcon(DetectionResult result) {
    if (result.isDetected) {
      final confidence = result.confidence;
      if (confidence >= 0.8) return 'check_circle';
      if (confidence >= 0.6) return 'warning';
      return 'error';
    }
    return 'search';
  }

  String _getDetectionText(DetectionResult result) {
    if (result.isDetected) {
      final confidence = result.confidence;
      if (confidence >= 0.8) return 'Detected';
      if (confidence >= 0.6) return 'Possible';
      return 'Low Confidence';
    }
    return 'Not Detected';
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          // Instructions
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
                    'Review your receipt image. You can crop it or proceed with processing.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 3.h),
          
          // Action Buttons
          Row(
            children: [
              // Retake Button
              Expanded(
                child: OutlinedButton(
                  onPressed: (widget.isProcessing || _isCropping) ? null : _handleRetake,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
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
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Retake',
                        style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 3.w),

              // Crop Button
              Expanded(
                child: OutlinedButton(
                  onPressed: (widget.isProcessing || _isCropping) ? null : _handleCrop,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
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
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Crop',
                        style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: 3.w),

              // Use Photo Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (widget.isProcessing || _isCropping) ? null : _handleUsePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
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
                          'Processing...',
                          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
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
                          'Use Photo',
                          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
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
            detectionResult: widget.detectionResult,
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
    widget.onUse();
  }
}
