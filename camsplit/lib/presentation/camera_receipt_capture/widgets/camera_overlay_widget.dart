import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/receipt_detection_service.dart';

class CameraOverlayWidget extends StatelessWidget {
  final DetectionResult? detectionResult;
  final bool isDetecting;
  final Animation<double> pulseAnimation;
  final Animation<double> cornerAnimation;

  const CameraOverlayWidget({
    super.key,
    this.detectionResult,
    this.isDetecting = false,
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
                  scale: _shouldShowStaticFrame() ? 1.0 : pulseAnimation.value,
                  child: Container(
                    width: 80.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _getFrameColor(),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // Corner Indicators - only show when not detecting or when detection is active
                        if (!isDetecting || _hasValidDetectionResult())
                          _buildCornerIndicators(),

                        // Center Guidelines
                        _buildGuidelines(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Detection Status - only show when actively detecting or when there's a real result
          if (isDetecting || _hasValidDetectionResult())
            _buildDetectionStatus(),
        ],
      ),
    );
  }

  bool _shouldShowStaticFrame() {
    return detectionResult?.isDetected == true && 
           detectionResult!.confidence >= 0.7;
  }

  bool _hasValidDetectionResult() {
    return detectionResult != null && 
           (detectionResult!.isDetected || detectionResult!.errorMessage != null);
  }

  Color _getFrameColor() {
    if (detectionResult?.isDetected == true) {
      final confidence = detectionResult!.confidence;
      if (confidence >= 0.8) {
        return AppTheme.successLight;
      } else if (confidence >= 0.6) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }
    
    return Colors.white.withValues(alpha: 0.8);
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
                scale: _shouldAnimateCorner() ? cornerAnimation.value : 1.0,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: _getFrameColor(),
                        width: 4,
                      ),
                      left: BorderSide(
                        color: _getFrameColor(),
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
                scale: _shouldAnimateCorner() ? cornerAnimation.value : 1.0,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: _getFrameColor(),
                        width: 4,
                      ),
                      right: BorderSide(
                        color: _getFrameColor(),
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
                scale: _shouldAnimateCorner() ? cornerAnimation.value : 1.0,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _getFrameColor(),
                        width: 4,
                      ),
                      left: BorderSide(
                        color: _getFrameColor(),
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
                scale: _shouldAnimateCorner() ? cornerAnimation.value : 1.0,
                child: Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _getFrameColor(),
                        width: 4,
                      ),
                      right: BorderSide(
                        color: _getFrameColor(),
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

  bool _shouldAnimateCorner() {
    return detectionResult?.isDetected == true && 
           detectionResult!.confidence >= 0.7;
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
            color: _getStatusColor().withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusIcon(),
              SizedBox(width: 2.w),
              Text(
                _getStatusText(),
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_shouldShowConfidence()) ...[
                SizedBox(width: 2.w),
                Text(
                  '${(detectionResult!.confidence * 100).toInt()}%',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowConfidence() {
    return detectionResult?.confidence != null && 
           detectionResult!.confidence > 0.0 &&
           detectionResult!.isDetected;
  }

  Widget _buildStatusIcon() {
    if (isDetecting) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (detectionResult?.isDetected == true) {
      final confidence = detectionResult!.confidence;
      if (confidence >= 0.8) {
        return CustomIconWidget(
          iconName: 'check_circle',
          color: Colors.white,
          size: 16,
        );
      } else if (confidence >= 0.6) {
        return CustomIconWidget(
          iconName: 'warning',
          color: Colors.white,
          size: 16,
        );
      } else {
        return CustomIconWidget(
          iconName: 'error',
          color: Colors.white,
          size: 16,
        );
      }
    }

    if (detectionResult?.errorMessage != null) {
      return CustomIconWidget(
        iconName: 'error_outline',
        color: Colors.white,
        size: 16,
      );
    }

    return CustomIconWidget(
      iconName: 'search',
      color: Colors.white,
      size: 16,
    );
  }

  Color _getStatusColor() {
    if (isDetecting) {
      return Colors.blue;
    }
    
    if (detectionResult?.isDetected == true) {
      final confidence = detectionResult!.confidence;
      if (confidence >= 0.8) {
        return AppTheme.successLight;
      } else if (confidence >= 0.6) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }
    
    if (detectionResult?.errorMessage != null) {
      return Colors.red;
    }
    
    return Colors.black.withValues(alpha: 0.7);
  }

  String _getStatusText() {
    if (isDetecting) {
      return 'Detecting...';
    }
    
    if (detectionResult?.isDetected == true) {
      final confidence = detectionResult!.confidence;
      if (confidence >= 0.8) {
        return 'Receipt Detected';
      } else if (confidence >= 0.6) {
        return 'Possible Receipt';
      } else {
        return 'Low Confidence';
      }
    }
    
    if (detectionResult?.errorMessage != null) {
      return 'Detection Error';
    }
    
    return 'Position receipt in frame';
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
