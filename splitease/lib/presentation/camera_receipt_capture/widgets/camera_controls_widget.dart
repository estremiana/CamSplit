import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CameraControlsWidget extends StatelessWidget {
  final bool isCapturing;
  final VoidCallback onCapture;
  final VoidCallback onGallery;

  const CameraControlsWidget({
    super.key,
    required this.isCapturing,
    required this.onCapture,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery Button
          _buildGalleryButton(),

          // Capture Button
          _buildCaptureButton(),

          // Placeholder for symmetry
          SizedBox(width: 16.w),
        ],
      ),
    );
  }

  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: onGallery,
      child: Container(
        width: 16.w,
        height: 16.w,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Mock gallery preview
            Container(
              margin: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'photo_library',
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: isCapturing ? null : onCapture,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 20.w,
        height: 20.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.all(isCapturing ? 2.w : 1.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCapturing ? AppTheme.primaryLight : Colors.white,
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: isCapturing
              ? Center(
                  child: SizedBox(
                    width: 6.w,
                    height: 6.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Center(
                  child: Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
