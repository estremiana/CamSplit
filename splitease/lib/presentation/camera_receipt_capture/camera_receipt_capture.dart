import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_export.dart';
import '../../services/receipt_detection_service.dart';
import '../../services/error_handler_service.dart';
import '../../utils/loading_overlay.dart';
import '../../widgets/error_dialog_widget.dart';
import './widgets/camera_controls_widget.dart';
import './widgets/camera_overlay_widget.dart';
import './widgets/receipt_detection_overlay.dart';
import './widgets/receipt_preview_widget.dart';
import './widgets/collapsible_tips_widget.dart';

class CameraReceiptCapture extends StatefulWidget {
  const CameraReceiptCapture({super.key});

  @override
  State<CameraReceiptCapture> createState() => _CameraReceiptCaptureState();
}

class _CameraReceiptCaptureState extends State<CameraReceiptCapture>
    with TickerProviderStateMixin {
  bool _isFlashOn = false;
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
  final ReceiptDetectionService _detectionService = ReceiptDetectionService.instance;
  final ApiService _apiService = ApiService.instance;
  final LoadingOverlayManager _loadingManager = LoadingOverlayManager();
  final ErrorHandlerService _errorHandler = ErrorHandlerService.instance;
  bool _isCameraInitialized = false;
  String _cameraStatus = 'Initializing...';
  
  // Detection state
  DetectionResult? _currentDetectionResult;
  bool _isDetecting = false;
  StreamSubscription<DetectionResult>? _detectionSubscription;
  
  // Tips widget state
  bool _isTipsExpanded = false;
  
  // Performance monitoring
  bool _isLowEndDevice = false;
  bool _isHighEndDevice = false;
  
  // Error handling state
  bool _hasDetectionError = false;
  bool _hasProcessingError = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _detectDeviceCapabilities();
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

  void _detectDeviceCapabilities() {
    // Simple device capability detection
    // In a real implementation, you would use device_info_plus package
    // to get actual device specifications
    
    // For now, we'll use screen size as a rough indicator
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenArea = screenWidth * screenHeight;
    
    if (screenArea < 2000000) { // Small screen area
      _isLowEndDevice = true;
    } else if (screenArea > 4000000) { // Large screen area
      _isHighEndDevice = true;
    }
    
    // Set device capabilities in camera service
    _cameraService.setDeviceCapability(_isLowEndDevice, _isHighEndDevice);
  }

  void _initializeCamera() async {
    try {
      setState(() {
        _cameraStatus = 'Initializing camera...';
        _isCameraInitialized = false;
      });
      
      // Show loading overlay for camera initialization
      _loadingManager.show(
        context: context,
        message: 'Initializing camera...',
        customIndicator: Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.w / 2),
          ),
          child: Icon(
            Icons.camera_alt,
            color: AppTheme.lightTheme.primaryColor,
            size: 4.w,
          ),
        ),
        onCancel: () {
          _loadingManager.hide();
          Navigator.pop(context);
        },
      );
      
      await _cameraService.initializeWithRetry();
      
      if (mounted) {
        _loadingManager.hide();
        setState(() {
          _isCameraInitialized = _cameraService.isInitialized;
          _cameraStatus = _cameraService.errorMessage ?? 'Camera Ready';
        });
        
        if (_isCameraInitialized) {
          _startReceiptDetection();
        }
      }
    } catch (e) {
      if (mounted) {
        _loadingManager.hide();
        setState(() {
          _cameraStatus = 'Camera Error: ${e.toString()}';
          _isCameraInitialized = false;
        });
        
        // Show comprehensive error dialog
        await _showComprehensiveErrorDialog(e);
      }
    }
  }

  Future<void> _showComprehensiveErrorDialog(dynamic error) async {
    ErrorInfo errorInfo;
    
    if (error is ErrorInfo) {
      errorInfo = error;
    } else {
      errorInfo = _errorHandler.handleError(error, ErrorType.camera);
    }
    
    await ErrorDialogHelper.showErrorDialog(
      context: context,
      error: error,
      errorType: errorInfo.type,
      onRetry: () {
        Navigator.pop(context); // Close dialog
        _initializeCamera();
      },
      onFallback: () {
        Navigator.pop(context); // Close dialog
        _enableFallbackMode();
      },
      onSettings: () {
        Navigator.pop(context); // Close dialog
        _openAppSettings();
      },
      onGoBack: () {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Go back to previous screen
      },
      showTechnicalDetails: errorInfo.severity == ErrorSeverity.high ||
                           errorInfo.severity == ErrorSeverity.critical,
    );
  }

  void _enableFallbackMode() {
    // Enable gallery-only mode when camera is not available
    setState(() {
      _cameraStatus = 'Gallery mode available';
      _isCameraInitialized = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera unavailable. You can still select images from gallery.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open settings. Please manually enable camera permissions.'),
        ),
      );
    }
  }

  void _startReceiptDetection() {
    if (!_isCameraInitialized || _cameraService.controller == null) return;

    setState(() {
      _isDetecting = true;
      _hasDetectionError = false;
    });

    try {
      _detectionService.startDetection();

      // Subscribe to detection results
      _detectionSubscription = _detectionService
          .detectReceipt()
          .listen(
            (result) {
              if (mounted) {
                setState(() {
                  _currentDetectionResult = result;
                  
                  // Trigger corner animation when receipt is detected
                  if (result.isDetected && result.confidence > 0.7) {
                    _cornerController.forward();
                  }
                });
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _hasDetectionError = true;
                });
                
                // Show detection error dialog
                _showDetectionErrorDialog(error);
              }
            },
          );
    } catch (e) {
      setState(() {
        _hasDetectionError = true;
      });
      
      _showDetectionErrorDialog(e);
    }
  }

  Future<void> _showDetectionErrorDialog(dynamic error) async {
    await ErrorDialogHelper.showErrorDialog(
      context: context,
      error: error,
              errorType: ErrorType.detection,
      onRetry: () {
        Navigator.pop(context); // Close dialog
        _startReceiptDetection();
      },
      onFallback: () {
        Navigator.pop(context); // Close dialog
        // Continue without detection
        setState(() {
          _hasDetectionError = true;
        });
      },
      showTechnicalDetails: false,
    );
  }

  void _stopReceiptDetection() {
    _detectionSubscription?.cancel();
    _detectionSubscription = null;
    _detectionService.stopDetection();
    
    if (mounted) {
      setState(() {
        _isDetecting = false;
        _currentDetectionResult = null;
      });
    }
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
      if (mounted) {
        await ErrorDialogHelper.showErrorDialog(
          context: context,
          error: e,
          errorType: ErrorType.camera,
          onRetry: () {
            Navigator.pop(context);
            _toggleFlash();
          },
          showTechnicalDetails: false,
        );
      }
    }
  }

  void _switchCamera() async {
    HapticFeedback.lightImpact();
    
    try {
      // Show loading overlay for camera switching
      _loadingManager.show(
        context: context,
        message: 'Switching camera...',
        customIndicator: Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.w / 2),
          ),
          child: Icon(
            Icons.switch_camera,
            color: AppTheme.lightTheme.primaryColor,
            size: 4.w,
          ),
        ),
      );
      
      await _cameraService.switchCamera();
      
      if (mounted) {
        _loadingManager.hide();
        setState(() {
          // Camera switched successfully
        });
      }
    } catch (e) {
      if (mounted) {
        _loadingManager.hide();
        await ErrorDialogHelper.showErrorDialog(
          context: context,
          error: e,
          errorType: ErrorType.camera,
          onRetry: () {
            Navigator.pop(context);
            _switchCamera();
          },
          showTechnicalDetails: false,
        );
      }
    }
  }

  void _capturePhoto() async {
    if (_isCapturing || !_isCameraInitialized) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isCapturing = true;
    });

    try {
      // Show image compression overlay
      _loadingManager.show(
        context: context,
        message: 'Capturing and optimizing image...',
        customIndicator: Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.w / 2),
          ),
          child: Icon(
            Icons.camera,
            color: AppTheme.lightTheme.primaryColor,
            size: 4.w,
          ),
        ),
      );
      
      final File? capturedImage = await _cameraService.captureImage();
      
      if (mounted && capturedImage != null) {
        _loadingManager.hide();
        setState(() {
          _isCapturing = false;
          _showPreview = true;
          _capturedImagePath = capturedImage.path;
        });
        
        // Stop detection when showing preview
        _stopReceiptDetection();
      } else {
        _loadingManager.hide();
        setState(() {
          _isCapturing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _loadingManager.hide();
        setState(() {
          _isCapturing = false;
        });
        
        await ErrorDialogHelper.showErrorDialog(
          context: context,
          error: e,
          errorType: ErrorType.processing,
          onRetry: () {
            Navigator.pop(context);
            _capturePhoto();
          },
          onFallback: () {
            Navigator.pop(context);
            // Try gallery selection as fallback
            _selectFromGallery();
          },
          showTechnicalDetails: false,
        );
      }
    }
  }

  void _selectFromGallery() async {
    HapticFeedback.lightImpact();
    
    try {
      // Show loading overlay for gallery selection
      _loadingManager.show(
        context: context,
        message: 'Processing selected image...',
        customIndicator: Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.w / 2),
          ),
          child: Icon(
            Icons.photo_library,
            color: AppTheme.lightTheme.primaryColor,
            size: 4.w,
          ),
        ),
      );
      
      final File? selectedImage = await _cameraService.pickImageFromGallery();
      
      if (mounted && selectedImage != null) {
        _loadingManager.hide();
        setState(() {
          _showPreview = true;
          _capturedImagePath = selectedImage.path;
        });
        
        // Stop detection when showing preview
        _stopReceiptDetection();
      } else {
        _loadingManager.hide();
      }
    } catch (e) {
      if (mounted) {
        _loadingManager.hide();
        await ErrorDialogHelper.showErrorDialog(
          context: context,
          error: e,
          errorType: ErrorType.processing,
          onRetry: () {
            Navigator.pop(context);
            _selectFromGallery();
          },
          showTechnicalDetails: false,
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
      _hasProcessingError = false;
    });
    
    // Restart detection when returning to camera
    _startReceiptDetection();
    
    // Ensure camera is active and ready for capture
    if (_isCameraInitialized && _cameraService.controller != null) {
      // Reset any camera state if needed
      _cameraService.controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    }
  }

  void _usePhoto() async {
    if (_isProcessing) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
      _hasProcessingError = false;
    });

    try {
      if (_capturedImagePath != null) {
        final File imageFile = File(_capturedImagePath!);
        
        // Show receipt processing overlay
        _loadingManager.show(
          context: context,
          message: 'Processing receipt with OCR...',
          customIndicator: Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.w / 2),
            ),
            child: Icon(
              Icons.receipt_long,
              color: AppTheme.lightTheme.primaryColor,
              size: 4.w,
            ),
          ),
        );
        
        // Process the receipt image using OCR without group context
        final ocrResponse = await _apiService.processReceipt(imageFile);
        
        if (mounted) {
          _loadingManager.hide();
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.receiptOcrReview,
            arguments: {
              'ocrResult': ocrResponse,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _loadingManager.hide();
        setState(() {
          _isProcessing = false;
          _hasProcessingError = true;
        });
        
        await ErrorDialogHelper.showErrorDialog(
          context: context,
          error: e,
          errorType: ErrorType.network,
          onRetry: () {
            Navigator.pop(context);
            _usePhoto();
          },
          onGoBack: () {
            Navigator.pop(context);
            _retakePhoto();
          },
          showTechnicalDetails: false,
        );
      }
    }
  }

  void _closeCamera() {
    HapticFeedback.lightImpact();
    
    // Stop detection and cleanup
    _stopReceiptDetection();
    
    // Reset state to prevent issues when returning
    setState(() {
      _showPreview = false;
      _capturedImagePath = null;
      _isProcessing = false;
      _hasProcessingError = false;
    });
    
    // Navigate back to previous screen
    Navigator.pop(context);
  }

  void _toggleTips() {
    HapticFeedback.lightImpact();
    setState(() {
      _isTipsExpanded = !_isTipsExpanded;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cornerController.dispose();
    _detectionSubscription?.cancel();
    _detectionService.dispose();
    _loadingManager.hide();
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

              // Receipt Detection Overlay
              if (!_showPreview) _buildReceiptDetectionOverlay(),

              // Camera Overlay (guidelines, etc.)
              if (!_showPreview) _buildCameraOverlay(),

              // Collapsible Tips Widget
              if (!_showPreview) _buildCollapsibleTips(),

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

  // Handle back button press with proper navigation behavior
  void _handleBackButton() {
    HapticFeedback.lightImpact();
    
    if (_isProcessing) {
      // Don't allow back navigation while processing
      return;
    }
    
    if (_showPreview) {
      // If showing preview, retake photo instead of going back
      _retakePhoto();
      return;
    }
    
    // If on camera screen, close camera and return to previous screen
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
              const CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 2.h),
              Text(
                _cameraStatus,
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (_cameraStatus.contains('Error'))
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: ElevatedButton(
                    onPressed: _initializeCamera,
                    child: const Text('Retry'),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    // Return real camera preview that occupies majority of screen space
    return Container(
      width: 100.w,
      height: 100.h,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: _cameraService.buildCameraPreview(),
        ),
      ),
    );
  }

  Widget _buildReceiptDetectionOverlay() {
    return ReceiptDetectionOverlay(
      detectionResult: _currentDetectionResult,
      isDetecting: _isDetecting,
      pulseAnimation: _pulseAnimation,
      cornerAnimation: _cornerAnimation,
    );
  }

  Widget _buildCameraOverlay() {
    return CameraOverlayWidget(
      detectionResult: _currentDetectionResult,
      isDetecting: _isDetecting,
      pulseAnimation: _pulseAnimation,
      cornerAnimation: _cornerAnimation,
    );
  }

  Widget _buildCollapsibleTips() {
    return CollapsibleTipsWidget(
      isExpanded: _isTipsExpanded,
      onToggle: _toggleTips,
      detectionResult: _currentDetectionResult,
      tips: [
        'Place receipt flat and fully visible',
        'Ensure good lighting',
        'Avoid shadows and glare',
        'Keep camera steady',
      ],
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

            // Camera Status (optional - can be removed if not needed)
            if (!_isCameraInitialized)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _cameraStatus,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
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
        isFlashOn: _isFlashOn,
        canSwitchCamera: (_cameraService.cameras?.length ?? 0) > 1,
        hasFlash: _cameraService.hasFlash,
        onCapture: _capturePhoto,
        onGallery: _selectFromGallery,
        onFlashToggle: _toggleFlash,
        onSwitchCamera: _switchCamera,
      ),
    );
  }

  Widget _buildReceiptPreview() {
    return ReceiptPreviewWidget(
      imagePath: _capturedImagePath!,
      onRetake: _retakePhoto,
      onUse: _usePhoto,
      isProcessing: _isProcessing,
      detectionResult: _currentDetectionResult,
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
