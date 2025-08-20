import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/receipt_detection_service.dart';

class ReceiptDetectionOverlay extends StatelessWidget {
  final DetectionResult? detectionResult;
  final bool isDetecting;
  final Animation<double>? pulseAnimation;
  final Animation<double>? cornerAnimation;

  const ReceiptDetectionOverlay({
    super.key,
    this.detectionResult,
    this.isDetecting = false,
    this.pulseAnimation,
    this.cornerAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Detection boundaries overlay - only show when actually detected with high confidence
        if (_shouldShowDetectionBoundaries())
          _buildDetectionBoundaries(),
        
        // Corner indicators - only show when actually detected with high confidence
        if (_shouldShowCornerIndicators())
          _buildCornerIndicators(),
        
        // Detection status indicator - only show when actively detecting or when there's a real result
        if (isDetecting || _hasValidDetectionResult())
          _buildDetectionStatus(),
      ],
    );
  }

  bool _shouldShowDetectionBoundaries() {
    return detectionResult?.isDetected == true && 
           detectionResult?.boundaries.isNotEmpty == true &&
           detectionResult!.confidence >= 0.6; // Only show for medium confidence and above
  }

  bool _shouldShowCornerIndicators() {
    return detectionResult?.isDetected == true && 
           detectionResult?.boundingBox != null &&
           detectionResult!.confidence >= 0.7; // Only show for high confidence
  }

  bool _hasValidDetectionResult() {
    return detectionResult != null && 
           (detectionResult!.isDetected || detectionResult!.errorMessage != null);
  }

  Widget _buildDetectionBoundaries() {
    final boundaries = detectionResult!.boundaries;
    if (boundaries.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      painter: DetectionBoundaryPainter(
        boundaries: boundaries,
        confidence: detectionResult!.confidence,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildCornerIndicators() {
    final boundingBox = detectionResult!.boundingBox;
    if (boundingBox == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Top-left corner
        Positioned(
          left: boundingBox.left * 100.w - 15,
          top: boundingBox.top * 100.h - 15,
          child: _buildCornerIndicator(_getCornerColor()),
        ),
        // Top-right corner
        Positioned(
          right: (1 - boundingBox.right) * 100.w - 15,
          top: boundingBox.top * 100.h - 15,
          child: _buildCornerIndicator(_getCornerColor()),
        ),
        // Bottom-left corner
        Positioned(
          left: boundingBox.left * 100.w - 15,
          bottom: (1 - boundingBox.bottom) * 100.h - 15,
          child: _buildCornerIndicator(_getCornerColor()),
        ),
        // Bottom-right corner
        Positioned(
          right: (1 - boundingBox.right) * 100.w - 15,
          bottom: (1 - boundingBox.bottom) * 100.h - 15,
          child: _buildCornerIndicator(_getCornerColor()),
        ),
      ],
    );
  }

  Color _getCornerColor() {
    final confidence = detectionResult!.confidence;
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildCornerIndicator(Color color) {
    return AnimatedBuilder(
      animation: cornerAnimation ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: cornerAnimation?.value ?? 1.0,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.crop_free,
              color: Colors.white,
              size: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetectionStatus() {
    return Positioned(
      top: 15.h,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusIcon(),
              SizedBox(width: 2.w),
              Text(
                _getStatusText(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_shouldShowConfidence()) ...[
                SizedBox(width: 2.w),
                Text(
                  '${(detectionResult!.confidence * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10.sp,
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
        return Icon(
          Icons.check_circle,
          color: Colors.white,
          size: 16,
        );
      } else if (confidence >= 0.6) {
        return Icon(
          Icons.warning,
          color: Colors.white,
          size: 16,
        );
      } else {
        return Icon(
          Icons.error,
          color: Colors.white,
          size: 16,
        );
      }
    }

    if (detectionResult?.errorMessage != null) {
      return Icon(
        Icons.error_outline,
        color: Colors.white,
        size: 16,
      );
    }

    return Icon(
      Icons.search,
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
        return Colors.green;
      } else if (confidence >= 0.6) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }
    
    if (detectionResult?.errorMessage != null) {
      return Colors.red;
    }
    
    return Colors.grey;
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
    
    return 'No Receipt Found';
  }
}

class DetectionBoundaryPainter extends CustomPainter {
  final List<Offset> boundaries;
  final double confidence;

  DetectionBoundaryPainter({
    required this.boundaries,
    required this.confidence,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (boundaries.isEmpty) return;

    final paint = Paint()
      ..color = _getBoundaryColor()
      ..strokeWidth = _getStrokeWidth()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    
    // Convert normalized coordinates to screen coordinates
    final screenBoundaries = boundaries.map((offset) {
      return Offset(
        offset.dx * size.width,
        offset.dy * size.height,
      );
    }).toList();

    if (screenBoundaries.isNotEmpty) {
      path.moveTo(screenBoundaries.first.dx, screenBoundaries.first.dy);
      
      for (int i = 1; i < screenBoundaries.length; i++) {
        path.lineTo(screenBoundaries[i].dx, screenBoundaries[i].dy);
      }
      
      // Close the path
      path.close();
    }

    canvas.drawPath(path, paint);

    // Draw confidence indicator only for high confidence detections
    if (confidence >= 0.7) {
      _drawConfidenceIndicator(canvas, size);
    }
  }

  double _getStrokeWidth() {
    if (confidence >= 0.8) {
      return 4.0; // Thicker line for high confidence
    } else if (confidence >= 0.6) {
      return 3.0; // Medium line for medium confidence
    } else {
      return 2.0; // Thinner line for low confidence
    }
  }

  Color _getBoundaryColor() {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  void _drawConfidenceIndicator(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _getBoundaryColor().withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(10, 10, 100, 30);
    final roundedRect = RRect.fromRectAndRadius(rect, const Radius.circular(15));
    
    canvas.drawRRect(roundedRect, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(confidence * 100).toInt()}%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(20, 20));
  }

  @override
  bool shouldRepaint(DetectionBoundaryPainter oldDelegate) {
    return oldDelegate.boundaries != boundaries ||
           oldDelegate.confidence != confidence;
  }
}
