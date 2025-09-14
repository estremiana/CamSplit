import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_export.dart';
import '../../services/error_handler_service.dart';
import '../../widgets/error_dialog_widget.dart';
import './widgets/camera_controls_widget.dart';
import './widgets/receipt_preview_widget.dart';

class CameraReceiptCapture extends StatefulWidget {
  const CameraReceiptCapture({super.key});

  @override
  State<CameraReceiptCapture> createState() => _CameraReceiptCaptureState();
}

class _CameraReceiptCaptureState extends State<CameraReceiptCapture> with TickerProviderStateMixin {
  bool _isFlashOn = false;
  bool _isCapturing = false;
  bool _showPreview = false;
  String? _capturedImagePath;
  bool _isProcessing = false;

  // Camera service
  final CameraService _cameraService = CameraService.instance;
  final ApiService _apiService = ApiService.instance;
  final ErrorHandlerService _errorHandler = ErrorHandlerService.instance;
  bool _isCameraInitialized = false;
  String _cameraStatus = 'Initializing...';
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _cameraStatus = 'Initializing camera...';
        _isCameraInitialized = false;
      });
      
      print('Camera: Starting initialization...');
      
      // Force a fresh initialization
      await _cameraService.initializeWithRetry();
      
      if (mounted) {
        final isInitialized = _cameraService.isInitialized;
        final errorMessage = _cameraService.errorMessage;
        final controller = _cameraService.controller;
        
        print('Camera: Initialization complete. isInitialized: $isInitialized, error: $errorMessage');
        print('Camera: Controller: ${controller != null}, Controller initialized: ${controller?.value.isInitialized}');
        
        setState(() {
          _isCameraInitialized = isInitialized && (controller?.value.isInitialized ?? false);
          _cameraStatus = errorMessage ?? 'Camera Ready';
        });
      }
    } catch (e) {
      print('Camera: Initialization error: $e');
      if (mounted) {
        setState(() {
          _cameraStatus = 'Camera Error: ${e.toString()}';
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _refreshCamera() async {
    print('Camera: Refreshing camera...');
    setState(() {
      _cameraStatus = 'Refreshing camera...';
      _isCameraInitialized = false;
    });
    
    await _initializeCamera();
  }

  void _toggleFlash() async {
    HapticFeedback.lightImpact();
    
    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraService.setFlashMode(newFlashMode);
      
      if (mounted) {
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (e) {
      // Silently handle flash errors
    }
  }

  void _switchCamera() async {
    HapticFeedback.lightImpact();
    
    try {
      // Show loading while switching to avoid rendering disposed preview
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
      await _cameraService.switchCamera();
      // Rebuild with the new controller instance
      if (mounted) {
        final controller = _cameraService.controller;
        setState(() {
          _isCameraInitialized = controller?.value.isInitialized ?? false;
        });
      }
    } catch (e) {
      // Silently handle camera switch errors
    }
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
        
        // Animate the transition to preview
        _slideController.reverse();
        await Future.delayed(const Duration(milliseconds: 250));
        _slideController.forward();
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
      // Silently handle gallery selection errors
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

  void _usePhoto([File? imageOverride]) async {
    if (_isProcessing) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
    });

    try {
      if (_capturedImagePath != null || imageOverride != null) {
        final File imageFile = imageOverride ?? File(_capturedImagePath!);
        
        // Process the receipt image using OCR
        final ocrResponse = await _apiService.processReceipt(imageFile);
        
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.receiptOcrReview,
            arguments: {
              'ocrResult': ocrResponse,
              'imagePath': imageFile.path,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Show simple error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
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
    _fadeController.dispose();
    _slideController.dispose();
    // Dispose camera controller to free up image buffers
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          _handleBackButton();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Camera Preview Background
              _buildCameraPreview(),

              // Simple Camera Overlay (only show when camera is initialized and not in preview mode)
              if (_isCameraInitialized && !_showPreview)
                _buildSimpleOverlay(),

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
      ),
    );
  }

  void _handleBackButton() {
    HapticFeedback.lightImpact();
    
    if (_isProcessing) {
      return;
    }
    
    if (_showPreview) {
      _retakePhoto();
      return;
    }
    
    _closeCamera();
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_cameraStatus.contains('Error'))
                const CircularProgressIndicator(color: Colors.white)
              else
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 8.w,
                ),
              SizedBox(height: 2.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  _cameraStatus,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (_cameraStatus.contains('Error'))
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _cameraStatus = 'Initializing camera...';
                        _isCameraInitialized = false;
                      });
                      _initializeCamera();
                    },
                    child: const Text('Retry'),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    // Build a non-stretched preview that covers the screen while preserving aspect ratio
    final controller = _cameraService.controller!;
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    // controller.value.aspectRatio is landscape-based; invert in portrait
    final double cameraAspectRatio = controller.value.aspectRatio;
    final double previewAspectRatio = isPortrait ? (1 / cameraAspectRatio) : cameraAspectRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double calculatedHeight = screenWidth / previewAspectRatio;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: screenWidth,
                height: calculatedHeight,
                child: _cameraService.buildCameraPreview(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimpleOverlay() {
    return Positioned.fill(
      child: Center(
        child: Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
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

            // Camera Status
            if (!_isCameraInitialized)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _cameraStatus,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    if (_cameraStatus.contains('Error'))
                      GestureDetector(
                        onTap: _refreshCamera,
                        child: Container(
                          margin: EdgeInsets.only(left: 2.w),
                          padding: EdgeInsets.all(1.w),
                          child: Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
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
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CameraControlsWidget(
            isCapturing: _isCapturing,
            isFlashOn: _isFlashOn,
            canSwitchCamera: (_cameraService.cameras?.length ?? 0) > 1,
            hasFlash: _cameraService.hasFlash,
            onCapture: _capturePhoto,
            onGallery: _selectFromGallery,
            onFlashToggle: _toggleFlash,
            onSwitchCamera: _switchCamera,
          ),
        ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 3.h),
            Text(
              'Processing...',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
