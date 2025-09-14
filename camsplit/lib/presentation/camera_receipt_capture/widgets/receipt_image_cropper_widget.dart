import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:image/image.dart' as img;

import '../../../core/app_export.dart';


class ReceiptImageCropperWidget extends StatefulWidget {
  final File imageFile;
  final Function(File croppedImage) onCropComplete;
  final VoidCallback onCancel;

  const ReceiptImageCropperWidget({
    super.key,
    required this.imageFile,
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
  ui.Image? _uiImage;
  Rect _cropRect = Rect.zero;
  bool _isLoading = true;
  bool _isCropping = false;
  static const double _minCropSize = 80.0;
  static const double _handleTouchRadius = 28.0;
  _ActiveHandle _activeHandle = _ActiveHandle.none;
  
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
        final uiImage = await decodeImageFromList(bytes);
        setState(() {
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          _uiImage = uiImage;
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
    // Initialize to full image area
    _cropRect = Rect.fromLTWH(0, 0, _imageSize.width, _imageSize.height);
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
        ],
      ),
    );
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Size displaySize = Size(constraints.maxWidth, constraints.maxHeight);
                // Keep latest display size for gesture mapping
                _displaySize = displaySize;
                return CustomPaint(
                  painter: ReceiptCropPainter(
                    image: _uiImage,
                    cropRect: _cropRect,
                    imageSize: _imageSize,
                    displaySize: displaySize,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.localPosition;
    _dragStartRect = _cropRect;
    _activeHandle = _detectActiveHandle(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStart == null || _dragStartRect == null) return;

    // Map gesture delta from display space to image space
    final mapping = _computeDisplayMapping(_displaySize);
    final Offset deltaDisplay = details.localPosition - _dragStart!;
    final Offset deltaImage = Offset(deltaDisplay.dx * mapping.scaleX, deltaDisplay.dy * mapping.scaleY);

    Rect updated = _dragStartRect!;
    switch (_activeHandle) {
      case _ActiveHandle.move:
        updated = updated.translate(deltaImage.dx, deltaImage.dy);
        break;
      case _ActiveHandle.topLeft:
        updated = Rect.fromLTRB(
          (updated.left + deltaImage.dx),
          (updated.top + deltaImage.dy),
          updated.right,
          updated.bottom,
        );
        break;
      case _ActiveHandle.topRight:
        updated = Rect.fromLTRB(
          updated.left,
          (updated.top + deltaImage.dy),
          (updated.right + deltaImage.dx),
          updated.bottom,
        );
        break;
      case _ActiveHandle.bottomLeft:
        updated = Rect.fromLTRB(
          (updated.left + deltaImage.dx),
          updated.top,
          updated.right,
          (updated.bottom + deltaImage.dy),
        );
        break;
      case _ActiveHandle.bottomRight:
        updated = Rect.fromLTRB(
          updated.left,
          updated.top,
          (updated.right + deltaImage.dx),
          (updated.bottom + deltaImage.dy),
        );
        break;
      case _ActiveHandle.none:
        updated = updated.translate(deltaImage.dx, deltaImage.dy);
        break;
    }

    // Normalize rect to ensure left<right, top<bottom
    updated = Rect.fromLTRB(
      updated.left,
      updated.top,
      updated.right,
      updated.bottom,
    );

    // Enforce minimum size by clamping the dragged edges only
    switch (_activeHandle) {
      case _ActiveHandle.topLeft:
        if (updated.width < _minCropSize) {
          updated = Rect.fromLTRB(updated.right - _minCropSize, updated.top, updated.right, updated.bottom);
        }
        if (updated.height < _minCropSize) {
          updated = Rect.fromLTRB(updated.left, updated.bottom - _minCropSize, updated.right, updated.bottom);
        }
        break;
      case _ActiveHandle.topRight:
        if (updated.width < _minCropSize) {
          updated = Rect.fromLTRB(updated.left, updated.top, updated.left + _minCropSize, updated.bottom);
        }
        if (updated.height < _minCropSize) {
          updated = Rect.fromLTRB(updated.left, updated.bottom - _minCropSize, updated.right, updated.bottom);
        }
        break;
      case _ActiveHandle.bottomLeft:
        if (updated.width < _minCropSize) {
          updated = Rect.fromLTRB(updated.right - _minCropSize, updated.top, updated.right, updated.bottom);
        }
        if (updated.height < _minCropSize) {
          updated = Rect.fromLTRB(updated.left, updated.top, updated.right, updated.top + _minCropSize);
        }
        break;
      case _ActiveHandle.bottomRight:
        if (updated.width < _minCropSize) {
          updated = Rect.fromLTRB(updated.left, updated.top, updated.left + _minCropSize, updated.bottom);
        }
        if (updated.height < _minCropSize) {
          updated = Rect.fromLTRB(updated.left, updated.top, updated.right, updated.top + _minCropSize);
        }
        break;
      case _ActiveHandle.move:
      case _ActiveHandle.none:
        // handled below
        break;
    }

    // Constrain within image bounds by clamping the dragged edges only
    switch (_activeHandle) {
      case _ActiveHandle.move:
      case _ActiveHandle.none: {
        final double left = updated.left.clamp(0, _imageSize.width - updated.width);
        final double top = updated.top.clamp(0, _imageSize.height - updated.height);
        updated = Rect.fromLTWH(left, top, updated.width, updated.height);
        break;
      }
      case _ActiveHandle.topLeft: {
        final double left = updated.left.clamp(0, updated.right - _minCropSize);
        final double top = updated.top.clamp(0, updated.bottom - _minCropSize);
        updated = Rect.fromLTRB(left, top, updated.right, updated.bottom);
        break;
      }
      case _ActiveHandle.topRight: {
        final double right = updated.right.clamp(updated.left + _minCropSize, _imageSize.width);
        final double top = updated.top.clamp(0, updated.bottom - _minCropSize);
        updated = Rect.fromLTRB(updated.left, top, right, updated.bottom);
        break;
      }
      case _ActiveHandle.bottomLeft: {
        final double left = updated.left.clamp(0, updated.right - _minCropSize);
        final double bottom = updated.bottom.clamp(updated.top + _minCropSize, _imageSize.height);
        updated = Rect.fromLTRB(left, updated.top, updated.right, bottom);
        break;
      }
      case _ActiveHandle.bottomRight: {
        final double right = updated.right.clamp(updated.left + _minCropSize, _imageSize.width);
        final double bottom = updated.bottom.clamp(updated.top + _minCropSize, _imageSize.height);
        updated = Rect.fromLTRB(updated.left, updated.top, right, bottom);
        break;
      }
    }
    setState(() {
      _cropRect = updated;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _dragStart = null;
    _dragStartRect = null;
    _activeHandle = _ActiveHandle.none;
  }

  _DisplayMapping _computeDisplayMapping(Size canvasSize) {
    // Compute displayRect as in painter (contain)
    final double imageAspect = _imageSize.width / _imageSize.height;
    final double canvasAspect = canvasSize.width / canvasSize.height;
    Rect displayRect;
    if (canvasAspect > imageAspect) {
      final double drawWidth = canvasSize.height * imageAspect;
      displayRect = Rect.fromLTWH(
        (canvasSize.width - drawWidth) / 2,
        0,
        drawWidth,
        canvasSize.height,
      );
    } else {
      final double drawHeight = canvasSize.width / imageAspect;
      displayRect = Rect.fromLTWH(
        0,
        (canvasSize.height - drawHeight) / 2,
        canvasSize.width,
        drawHeight,
      );
    }
    final double scaleX = _imageSize.width / displayRect.width;
    final double scaleY = _imageSize.height / displayRect.height;
    return _DisplayMapping(displayRect: displayRect, scaleX: scaleX, scaleY: scaleY);
  }

  _ActiveHandle _detectActiveHandle(Offset localPos) {
    final mapping = _computeDisplayMapping(_displaySize);
    // Map crop corners to display space
    final double scaleDisplayX = mapping.displayRect.width / _imageSize.width;
    final double scaleDisplayY = mapping.displayRect.height / _imageSize.height;
    final Offset topLeft = Offset(
      mapping.displayRect.left + _cropRect.left * scaleDisplayX,
      mapping.displayRect.top + _cropRect.top * scaleDisplayY,
    );
    final Offset topRight = Offset(
      mapping.displayRect.left + _cropRect.right * scaleDisplayX,
      mapping.displayRect.top + _cropRect.top * scaleDisplayY,
    );
    final Offset bottomLeft = Offset(
      mapping.displayRect.left + _cropRect.left * scaleDisplayX,
      mapping.displayRect.top + _cropRect.bottom * scaleDisplayY,
    );
    final Offset bottomRight = Offset(
      mapping.displayRect.left + _cropRect.right * scaleDisplayX,
      mapping.displayRect.top + _cropRect.bottom * scaleDisplayY,
    );

    double d(Offset a) => (a - localPos).distance;
    final distances = {
      _ActiveHandle.topLeft: d(topLeft),
      _ActiveHandle.topRight: d(topRight),
      _ActiveHandle.bottomLeft: d(bottomLeft),
      _ActiveHandle.bottomRight: d(bottomRight),
    };
    final entry = distances.entries.reduce((a, b) => a.value < b.value ? a : b);
    if (entry.value <= _handleTouchRadius) {
      return entry.key;
    }
    return _ActiveHandle.move;
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
  final ui.Image? image;
  final Rect cropRect;
  final Size imageSize;
  final Size displaySize;

  ReceiptCropPainter({
    required this.image,
    required this.cropRect,
    required this.imageSize,
    required this.displaySize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final backgroundPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    // If image is not ready, nothing to draw yet
    if (image == null) {
      return;
    }

    // Compute destination rect preserving aspect ratio (contain)
    final double imageAspect = imageSize.width / imageSize.height;
    final double canvasAspect = size.width / size.height;
    Rect displayRect;
    if (canvasAspect > imageAspect) {
      final double drawWidth = size.height * imageAspect;
      displayRect = Rect.fromLTWH(
        (size.width - drawWidth) / 2,
        0,
        drawWidth,
        size.height,
      );
    } else {
      final double drawHeight = size.width / imageAspect;
      displayRect = Rect.fromLTWH(
        0,
        (size.height - drawHeight) / 2,
        size.width,
        drawHeight,
      );
    }

    // Draw the image scaled into displayRect
    paintImage(
      canvas: canvas,
      rect: displayRect,
      image: image!,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

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

    // Draw semi-transparent overlay outside crop rect
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    // Top
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, displayCropRect.top), overlayPaint);
    // Bottom
    canvas.drawRect(Rect.fromLTWH(0, displayCropRect.bottom, size.width, size.height - displayCropRect.bottom), overlayPaint);
    // Left
    canvas.drawRect(Rect.fromLTWH(0, displayCropRect.top, displayCropRect.left, displayCropRect.height), overlayPaint);
    // Right
    canvas.drawRect(Rect.fromLTWH(displayCropRect.right, displayCropRect.top, size.width - displayCropRect.right, displayCropRect.height), overlayPaint);

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

    // Add filled circles as touch handles at corners
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    const double handleRadius = 6.0;
    canvas.drawCircle(Offset(cropRect.left, cropRect.top), handleRadius, handlePaint);
    canvas.drawCircle(Offset(cropRect.right, cropRect.top), handleRadius, handlePaint);
    canvas.drawCircle(Offset(cropRect.left, cropRect.bottom), handleRadius, handlePaint);
    canvas.drawCircle(Offset(cropRect.right, cropRect.bottom), handleRadius, handlePaint);
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



  @override
  bool shouldRepaint(ReceiptCropPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect || oldDelegate.image != image || oldDelegate.displaySize != displaySize;
  }
}

class _DisplayMapping {
  final Rect displayRect;
  final double scaleX;
  final double scaleY;
  _DisplayMapping({required this.displayRect, required this.scaleX, required this.scaleY});
}

enum _ActiveHandle { none, move, topLeft, topRight, bottomLeft, bottomRight }

