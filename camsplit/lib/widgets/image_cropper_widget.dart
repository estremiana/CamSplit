import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image/image.dart' as img;

import '../core/app_export.dart';

class ImageCropperWidget extends StatefulWidget {
  final File imageFile;
  final double aspectRatio;
  final Function(File) onCropComplete;
  final VoidCallback onCancel;

  const ImageCropperWidget({
    super.key,
    required this.imageFile,
    this.aspectRatio = 1.0, // Square by default
    required this.onCropComplete,
    required this.onCancel,
  });

  @override
  State<ImageCropperWidget> createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget> {
  late File _imageFile;
  late Size _imageSize;
  late Size _cropSize;
  Offset _cropOffset = Offset.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _imageFile = widget.imageFile;
    _initializeImage();
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
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: Text(
          'Crop Image',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _cropImage,
            child: Text(
              'Done',
              style: TextStyle(
                color: AppTheme.lightTheme.primaryColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: _buildCropArea(),
                  ),
                ),
                _buildControls(),
              ],
            ),
    );
  }

  Widget _buildCropArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight;
        
        // Calculate display size maintaining aspect ratio
        double displayWidth = _imageSize.width;
        double displayHeight = _imageSize.height;
        
        if (displayWidth > maxWidth) {
          displayWidth = maxWidth;
          displayHeight = (displayHeight * maxWidth) / _imageSize.width;
        }
        
        if (displayHeight > maxHeight) {
          displayHeight = maxHeight;
          displayWidth = (displayWidth * maxHeight) / _imageSize.height;
        }

        return Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.file(
                _imageFile,
                fit: BoxFit.contain,
              ),
            ),
            
            // Crop overlay
            Positioned.fill(
              child: CustomPaint(
                painter: CropOverlayPainter(
                  cropRect: _getCropRect(displayWidth, displayHeight),
                  imageSize: Size(displayWidth, displayHeight),
                ),
              ),
            ),
            
            // Crop handles
            ..._buildCropHandles(displayWidth, displayHeight),
          ],
        );
      },
    );
  }

  Rect _getCropRect(double displayWidth, double displayHeight) {
    final double cropWidth = displayWidth * 0.8;
    final double cropHeight = cropWidth / widget.aspectRatio;
    
    final double left = (displayWidth - cropWidth) / 2;
    final double top = (displayHeight - cropHeight) / 2;
    
    return Rect.fromLTWH(left, top, cropWidth, cropHeight);
  }

  List<Widget> _buildCropHandles(double displayWidth, double displayHeight) {
    final Rect cropRect = _getCropRect(displayWidth, displayHeight);
    final double handleSize = 20;
    
    return [
      // Top-left handle
      Positioned(
        left: cropRect.left - handleSize / 2,
        top: cropRect.top - handleSize / 2,
        child: _buildCropHandle(handleSize),
      ),
      // Top-right handle
      Positioned(
        right: displayWidth - cropRect.right - handleSize / 2,
        top: cropRect.top - handleSize / 2,
        child: _buildCropHandle(handleSize),
      ),
      // Bottom-left handle
      Positioned(
        left: cropRect.left - handleSize / 2,
        bottom: displayHeight - cropRect.bottom - handleSize / 2,
        child: _buildCropHandle(handleSize),
      ),
      // Bottom-right handle
      Positioned(
        right: displayWidth - cropRect.right - handleSize / 2,
        bottom: displayHeight - cropRect.bottom - handleSize / 2,
        child: _buildCropHandle(handleSize),
      ),
    ];
  }

  Widget _buildCropHandle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.black,
      child: Column(
        children: [
          Text(
            'Drag to adjust crop area',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAspectRatioButton('1:1', 1.0),
              _buildAspectRatioButton('4:3', 4/3),
              _buildAspectRatioButton('3:4', 3/4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAspectRatioButton(String label, double ratio) {
    final bool isSelected = widget.aspectRatio == ratio;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          // Update aspect ratio
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightTheme.primaryColor : Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _cropImage() async {
    try {
      // Read original image
      final Uint8List bytes = await _imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate crop dimensions
      final Rect cropRect = _getCropRect(_imageSize.width, _imageSize.height);
      
      // Crop image
      final img.Image cropped = img.copyCrop(
        image,
        x: cropRect.left.toInt(),
        y: cropRect.top.toInt(),
        width: cropRect.width.toInt(),
        height: cropRect.height.toInt(),
      );

      // Save cropped image
      final String tempPath = '${_imageFile.parent.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File croppedFile = File(tempPath);
      await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));

      widget.onCropComplete(croppedFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to crop image: $e'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;
  final Size imageSize;

  CropOverlayPainter({
    required this.cropRect,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw overlay
    canvas.drawRect(Offset.zero & size, overlayPaint);
    
    // Clear crop area
    canvas.drawRect(cropRect, Paint()..blendMode = BlendMode.clear);
    
    // Draw crop border
    canvas.drawRect(cropRect, borderPaint);
    
    // Draw grid lines
    _drawGridLines(canvas, cropRect);
  }

  void _drawGridLines(Canvas canvas, Rect rect) {
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Vertical lines
    canvas.drawLine(
      Offset(rect.left + rect.width / 3, rect.top),
      Offset(rect.left + rect.width / 3, rect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left + 2 * rect.width / 3, rect.top),
      Offset(rect.left + 2 * rect.width / 3, rect.bottom),
      gridPaint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(rect.left, rect.top + rect.height / 3),
      Offset(rect.right, rect.top + rect.height / 3),
      gridPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top + 2 * rect.height / 3),
      Offset(rect.right, rect.top + 2 * rect.height / 3),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 