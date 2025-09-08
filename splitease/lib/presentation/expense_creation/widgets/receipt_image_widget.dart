import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ReceiptImageWidget extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onAddImage;

  const ReceiptImageWidget({
    super.key,
    this.imageUrl,
    this.onAddImage,
  });

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  width: 90.w,
                  height: 80.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 2.h,
              right: 4.w,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If no image URL is provided, show small camera button
    if (imageUrl == null || imageUrl!.isEmpty) {
      return GestureDetector(
        onTap: onAddImage,
        child: Container(
          width: double.infinity,
          height: 12.h, // Much smaller height for empty state
          constraints: BoxConstraints(
            maxHeight: 12.h,
            minHeight: 10.h,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.dividerColor,
              width: 1,
            ),
            color: Colors.grey[50],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(2.w), // Smaller padding
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: CustomIconWidget(
                    iconName: 'photo_camera',
                    color: AppTheme.primaryLight,
                    size: 24, // Smaller icon
                  ),
                ),
                SizedBox(width: 3.w),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Receipt Photo',
                      style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Tap to capture or select from gallery',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If image URL is provided, show the image with zoom functionality
    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: Container(
        width: double.infinity,
        height: 25.h,
        constraints: BoxConstraints(
          maxHeight: 25.h,
          minHeight: 20.h,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.dividerColor,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              CustomImageWidget(
                imageUrl: imageUrl!,
                width: double.infinity,
                height: 25.h,
                fit: BoxFit.cover,
                errorWidget: Container(
                  width: double.infinity,
                  height: 25.h,
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Receipt Image',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 2.w,
                right: 2.w,
                child: Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomIconWidget(
                    iconName: 'zoom_in',
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              Positioned(
                bottom: 2.w,
                left: 2.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tap to view full receipt',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
