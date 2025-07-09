import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/camera_service.dart';
import '../../services/api_service.dart';
import './widgets/camera_controls_widget.dart';
import './widgets/camera_overlay_widget.dart';
import './widgets/receipt_preview_widget.dart';

class CameraReceiptCapture extends StatefulWidget {
  const CameraReceiptCapture({super.key});

  @override
  State<CameraReceiptCapture> createState() => _CameraReceiptCaptureState();
}

class _CameraReceiptCaptureState extends State<CameraReceiptCapture>
    with TickerProviderStateMixin {
  bool _isFlashOn = false;
  bool _isReceiptDetected = false;
  bool _isCapturing = false;
  bool _showPreview = false;
  String? _capturedImagePath;
  bool _isProcessing = false;
  late AnimationController _pulseController;
  late AnimationController _cornerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _cornerAnimation;

  // Camera service
  final CameraService _cameraService = CameraService.instance;
  final ApiService _apiService = ApiService.instance;
  bool _isCameraInitialized = false;
  bool _hasPermission = false;
  String _cameraStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _cornerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _cornerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cornerController,
      curve: Curves.elasticOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _initializeCamera() async {
    try {
      await _cameraService.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _hasPermission = true;
          _cameraStatus = 'Camera Ready';
        });
        _startReceiptDetection();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraStatus = 'Camera Error: ${e.toString()}';
        });
      }
    }
  }

  void _startReceiptDetection() {
    // Mock receipt detection with periodic updates
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isReceiptDetected = true;
        });
        _cornerController.forward();
      }
    });
  }

  void _toggleFlash() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  void _capturePhoto() async {
    if (_isCapturing || !_isCameraInitialized) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isCapturing = true;
    });

    try {
      final File? capturedImage = await _cameraService.captureImage();
      
      if (mounted && capturedImage != null) {
        setState(() {
          _isCapturing = false;
          _showPreview = true;
          _capturedImagePath = capturedImage.path;
        });
      } else {
        setState(() {
          _isCapturing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: ${e.toString()}')),
        );
      }
    }
  }

  void _selectFromGallery() async {
    HapticFeedback.lightImpact();
    
    try {
      final File? selectedImage = await _cameraService.pickImageFromGallery();
      
      if (mounted && selectedImage != null) {
        setState(() {
          _showPreview = true;
          _capturedImagePath = selectedImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: ${e.toString()}')),
        );
      }
    }
  }

  void _retakePhoto() {
    HapticFeedback.lightImpact();
    setState(() {
      _showPreview = false;
      _capturedImagePath = null;
      _isProcessing = false;
    });
  }

  void _usePhoto() async {
    if (_isProcessing) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
    });

    try {
      if (_capturedImagePath != null) {
        final File imageFile = File(_capturedImagePath!);
        // 1. Upload the image and get the URL
        final billResponse = await _apiService.uploadBill(imageFile);
        final imageUrl = billResponse['bill']['image_url'];
        // 2. Extract items using the image URL
        final ocrResponse = await _apiService.extractItems(imageUrl);
        // 3. Pass the OCR result and imageUrl to the next screen
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.receiptOcrReview,
            arguments: {
              'imageUrl': imageUrl,
              'ocrResult': ocrResponse,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: ${e.toString()}')),
        );
      }
    }
  }

  void _closeCamera() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cornerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview Background
            _buildCameraPreview(),

            // Camera Overlay
            if (!_showPreview) _buildCameraOverlay(),

            // Top Controls
            _buildTopControls(),

            // Bottom Controls
            if (!_showPreview) _buildBottomControls(),

            // Receipt Preview
            if (_showPreview) _buildReceiptPreview(),

            // Processing Overlay
            if (_isProcessing) _buildProcessingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      width: 100.w,
      height: 100.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[900]!,
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: _isCameraInitialized
          ? Center(
              child: Container(
                width: 90.w,
                height: 70.h,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'camera_alt',
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 48,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Camera Preview',
                        style:
                            AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _cameraStatus,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildCameraOverlay() {
    return CameraOverlayWidget(
      isReceiptDetected: _isReceiptDetected,
      pulseAnimation: _pulseAnimation,
      cornerAnimation: _cornerAnimation,
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 2.h,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close Button
            GestureDetector(
              onTap: _closeCamera,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Flash Toggle
            GestureDetector(
              onTap: _toggleFlash,
              child: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: _isFlashOn ? 'flash_on' : 'flash_off',
                    color: _isFlashOn ? Colors.yellow : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 8.h,
      left: 0,
      right: 0,
      child: CameraControlsWidget(
        isCapturing: _isCapturing,
        onCapture: _capturePhoto,
        onGallery: _selectFromGallery,
      ),
    );
  }

  Widget _buildReceiptPreview() {
    return ReceiptPreviewWidget(
      imagePath: _capturedImagePath!,
      onRetake: _retakePhoto,
      onUse: _usePhoto,
      isProcessing: _isProcessing,
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      width: 100.w,
      height: 100.h,
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          width: 80.w,
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 3.h),
              Text(
                'Processing Receipt...',
                style: AppTheme.lightTheme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                'Extracting items and amounts using OCR technology',
                style: AppTheme.lightTheme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
