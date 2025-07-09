import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CameraOverlayWidget extends StatelessWidget {
  final bool isReceiptDetected;
  final Animation<double> pulseAnimation;
  final Animation<double> cornerAnimation;

  const CameraOverlayWidget({
    super.key,
    required this.isReceiptDetected,
    required this.pulseAnimation,
    required this.cornerAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Viewfinder Frame
          Center(
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isReceiptDetected ? 1.0 : pulseAnimation.value,
                  child: Container(
                    width: 80.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isReceiptDetected
                            ? AppTheme.successLight
                            : Colors.white.withValues(alpha: 0.8),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // Corner Indicators
                        _buildCornerIndicators(),

                        // Center Guidelines
                        _buildGuidelines(),

                        // Detection Status
                        _buildDetectionStatus(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Instructions Overlay
          _buildInstructionsOverlay(),
        ],
      ),
    );
  }

  Widget _buildCornerIndicators() {
    return AnimatedBuilder(
      animation: cornerAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Top Left Corner
            Positioned(
              top: -2,
              left: -2,
              child: Transform.scale(
                scale: cornerAnimation.value,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isReceiptDetected
                            ? AppTheme.successLight
                            : Colors.white,
                        width: 4,
                      ),
                      left: BorderSide(
                        color: isReceiptDetected
                            ? AppTheme.successLight
                            : Colors.white,
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top Right Corner
            Positioned(
              top: -2,
              right: -2,
              child: Transform.scale(
                scale: cornerAnimation.value,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isReceiptDetected
                            ? AppTheme.successLight
                            : Colors.white,
                        width: 4,
                      ),
                      right: BorderSide(
                        color: isReceiptDetected
                            ? AppTheme.successLight
                            : Colors.white,
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Left Corner
            Positioned(
              bottom: -2,
              left: -2,
              child: Transform.scale(
                scale: cornerAnimation.value,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isReceiptDetected
                            ? AppTheme.successLight
                            : Colors.white,
                        width: 4,
                      ),
                      left: BorderSide(
                        color: isReceiptDetected
                            ? AppTheme.successLight
                            : Colors.white,
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Right Corner
            Positioned(
              bottom: -2,
              right: -2,
              child: Transform.scale(
                scale: cornerAnimation.value,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isReceiptDetected
                            ? AppTheme.successLight
                            : Colors.white,
                        width: 4,
                      ),
                      right: BorderSide(
                        color: isReceiptDetected
                            ? AppTheme.successLight
                            : Colors.white,
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuidelines() {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(
          painter: GuidelinesPainter(
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionStatus() {
    return Positioned(
      bottom: 2.h,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isReceiptDetected
                ? AppTheme.successLight.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: isReceiptDetected ? 'check_circle' : 'search',
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 2.w),
              Text(
                isReceiptDetected
                    ? 'Receipt Detected'
                    : 'Position receipt in frame',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionsOverlay() {
    return Positioned(
      top: 15.h,
      left: 4.w,
      right: 4.w,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Tips for best results:',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildTip('Place receipt flat and fully visible'),
            _buildTip('Ensure good lighting'),
            _buildTip('Avoid shadows and glare'),
            _buildTip('Keep camera steady'),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1.w,
            height: 1.w,
            margin: EdgeInsets.only(top: 1.5.w, right: 3.w),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GuidelinesPainter extends CustomPainter {
  final Color color;

  GuidelinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Horizontal guidelines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );

    // Vertical guidelines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
