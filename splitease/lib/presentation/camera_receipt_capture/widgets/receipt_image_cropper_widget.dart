import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:image/image.dart' as img;

import '../../../core/app_export.dart';
import '../../../services/receipt_detection_service.dart';

class ReceiptImageCropperWidget extends StatefulWidget {
  final File imageFile;
  final DetectionResult? detectionResult;
  final Function(File croppedImage) onCropComplete;
  final VoidCallback onCancel;

  const ReceiptImageCropperWidget({
    super.key,
    required this.imageFile,
    this.detectionResult,
    required this.onCropComplete,
    required this.onCancel,
  });

  @override
  State<ReceiptImageCropperWidget> createState() => _ReceiptImageCropperWidgetState();
}

class _ReceiptImageCropperWidgetState extends State<ReceiptImageCropperWidget>
    with TickerProviderStateMixin {
  late File _imageFile;
  late Size _imageSize;
  late Size _displaySize;
  Rect _cropRect = Rect.zero;
  bool _isLoading = true;
  bool _isCropping = false;
  
  // Gesture handling
  Offset? _dragStart;
  Rect? _dragStartRect;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _imageFile = widget.imageFile;
    _initializeAnimations();
    _initializeImage();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _initializeImage() async {
    try {
      final Uint8List bytes = await _imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image != null) {
        setState(() {
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          _isLoading = false;
        });
        
        // Initialize crop rect based on detection result or default
        _initializeCropRect();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load image: $e');
    }
  }

  void _initializeCropRect() {
    if (widget.detectionResult?.boundingBox != null && 
        widget.detectionResult!.confidence >= 0.6) {
      // Use detection result to set initial crop area
      final boundingBox = widget.detectionResult!.boundingBox!;
      _cropRect = Rect.fromLTWH(
        boundingBox.left * _imageSize.width,
        boundingBox.top * _imageSize.height,
        boundingBox.width * _imageSize.width,
        boundingBox.height * _imageSize.height,
      );
    } else {
      // Default crop area (80% of image with center alignment)
      final margin = 0.1;
      _cropRect = Rect.fromLTWH(
        _imageSize.width * margin,
        _imageSize.height * margin,
        _imageSize.width * (1 - 2 * margin),
        _imageSize.height * (1 - 2 * margin),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Image Cropper Area
            Expanded(
              child: _buildCropperArea(),
            ),
            
            // Controls
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onCancel,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: 'close',
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            'Crop Receipt',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (widget.detectionResult?.isDetected == true)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: _getDetectionColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getDetectionColor().withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'auto_fix_high',
                    color: _getDetectionColor(),
                    size: 16,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Auto-detected',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: _getDetectionColor(),
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

  Color _getDetectionColor() {
    if (widget.detectionResult?.confidence == null) return Colors.grey;
    
    final confidence = widget.detectionResult!.confidence;
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCropperArea() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 2.h),
            Text(
              'Loading image...',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              painter: ReceiptCropPainter(
                imageFile: _imageFile,
                cropRect: _cropRect,
                imageSize: _imageSize,
                displaySize: _displaySize,
                detectionResult: widget.detectionResult,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.localPosition;
    _dragStartRect = _cropRect;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStart == null || _dragStartRect == null) return;

    final delta = details.localPosition - _dragStart!;
    final newRect = _dragStartRect!.translate(delta.dx, delta.dy);
    
    // Constrain to image bounds
    final constrainedRect = Rect.fromLTWH(
      newRect.left.clamp(0, _imageSize.width - newRect.width),
      newRect.top.clamp(0, _imageSize.height - newRect.height),
      newRect.width,
      newRect.height,
    );

    setState(() {
      _cropRect = constrainedRect;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStart = null;
    _dragStartRect = null;
  }

  Widget _buildControls() {
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
                    'Drag to adjust crop area. Ensure the entire receipt is included.',
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
              // Cancel Button
              Expanded(
                child: OutlinedButton(
                  onPressed: _isCropping ? null : widget.onCancel,
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
                  child: Text(
                    'Cancel',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 4.w),

              // Crop Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isCropping ? null : _performCrop,
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
                      if (_isCropping) ...[
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
                          'Cropping...',
                          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ] else ...[
                        CustomIconWidget(
                          iconName: 'crop',
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Crop & Continue',
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

  Future<void> _performCrop() async {
    if (_isCropping) return;

    setState(() {
      _isCropping = true;
    });

    try {
      HapticFeedback.mediumImpact();
      
      // Read original image
      final Uint8List bytes = await _imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Ensure crop rect is within bounds
      final constrainedRect = Rect.fromLTWH(
        _cropRect.left.clamp(0, image.width - 1),
        _cropRect.top.clamp(0, image.height - 1),
        _cropRect.width.clamp(1, image.width - _cropRect.left),
        _cropRect.height.clamp(1, image.height - _cropRect.top),
      );

      // Crop image
      final img.Image cropped = img.copyCrop(
        image,
        x: constrainedRect.left.toInt(),
        y: constrainedRect.top.toInt(),
        width: constrainedRect.width.toInt(),
        height: constrainedRect.height.toInt(),
      );

      // Save cropped image
      final String tempPath = '${_imageFile.parent.path}/cropped_receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File croppedFile = File(tempPath);
      await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));

      // Call completion callback
      widget.onCropComplete(croppedFile);
      
    } catch (e) {
      setState(() {
        _isCropping = false;
      });
      _showErrorSnackBar('Failed to crop image: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class ReceiptCropPainter extends CustomPainter {
  final File imageFile;
  final Rect cropRect;
  final Size imageSize;
  final Size displaySize;
  final DetectionResult? detectionResult;

  ReceiptCropPainter({
    required this.imageFile,
    required this.cropRect,
    required this.imageSize,
    required this.displaySize,
    this.detectionResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate display dimensions
    final aspectRatio = imageSize.width / imageSize.height;
    final displayWidth = size.width;
    final displayHeight = displayWidth / aspectRatio;
    
    final displayRect = Rect.fromLTWH(
      (size.width - displayWidth) / 2,
      (size.height - displayHeight) / 2,
      displayWidth,
      displayHeight,
    );

    // Draw background
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // Draw image placeholder
    final imagePaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;
    canvas.drawRect(displayRect, imagePaint);

    // Draw crop overlay
    _drawCropOverlay(canvas, displayRect, size);
  }

  void _drawCropOverlay(Canvas canvas, Rect displayRect, Size size) {
    // Calculate crop rect in display coordinates
    final scaleX = displayRect.width / imageSize.width;
    final scaleY = displayRect.height / imageSize.height;
    
    final displayCropRect = Rect.fromLTWH(
      displayRect.left + cropRect.left * scaleX,
      displayRect.top + cropRect.top * scaleY,
      cropRect.width * scaleX,
      cropRect.height * scaleY,
    );

    // Draw semi-transparent overlay
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, overlayPaint);

    // Clear crop area
    canvas.drawRect(displayCropRect, Paint()..blendMode = BlendMode.clear);

    // Draw crop border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(displayCropRect, borderPaint);

    // Draw corner indicators
    _drawCornerIndicators(canvas, displayCropRect);

    // Draw grid lines
    _drawGridLines(canvas, displayCropRect);

    // Draw detection indicator if available
    if (detectionResult?.isDetected == true) {
      _drawDetectionIndicator(canvas, displayCropRect);
    }
  }

  void _drawCornerIndicators(Canvas canvas, Rect cropRect) {
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const cornerSize = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cornerSize),
      Offset(cropRect.left, cropRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top),
      Offset(cropRect.left + cornerSize, cropRect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(cropRect.right - cornerSize, cropRect.top),
      Offset(cropRect.right, cropRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.right, cropRect.top),
      Offset(cropRect.right, cropRect.top + cornerSize),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cropRect.left, cropRect.bottom - cornerSize),
      Offset(cropRect.left, cropRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.bottom),
      Offset(cropRect.left + cornerSize, cropRect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(cropRect.right - cornerSize, cropRect.bottom),
      Offset(cropRect.right, cropRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.right, cropRect.bottom - cornerSize),
      Offset(cropRect.right, cropRect.bottom),
      cornerPaint,
    );
  }

  void _drawGridLines(Canvas canvas, Rect cropRect) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Vertical lines
    canvas.drawLine(
      Offset(cropRect.left + cropRect.width / 3, cropRect.top),
      Offset(cropRect.left + cropRect.width / 3, cropRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.top),
      Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.bottom),
      gridPaint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cropRect.height / 3),
      Offset(cropRect.right, cropRect.top + cropRect.height / 3),
      gridPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top + cropRect.height * 2 / 3),
      Offset(cropRect.right, cropRect.top + cropRect.height * 2 / 3),
      gridPaint,
    );
  }

  void _drawDetectionIndicator(Canvas canvas, Rect cropRect) {
    final confidence = detectionResult!.confidence;
    final color = confidence >= 0.8 ? Colors.green : 
                  confidence >= 0.6 ? Colors.orange : Colors.red;

    final indicatorPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final indicatorRect = Rect.fromLTWH(
      cropRect.left + 10,
      cropRect.top + 10,
      80,
      30,
    );

    final roundedRect = RRect.fromRectAndRadius(
      indicatorRect,
      const Radius.circular(15),
    );

    canvas.drawRRect(roundedRect, indicatorPaint);

    // Draw text
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
    textPainter.paint(
      canvas,
      Offset(indicatorRect.left + 10, indicatorRect.top + 8),
    );
  }

  @override
  bool shouldRepaint(ReceiptCropPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
           oldDelegate.detectionResult != detectionResult;
  }
}
