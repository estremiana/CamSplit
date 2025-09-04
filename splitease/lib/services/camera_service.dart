import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'dart:math' as math;

import 'error_handler_service.dart';

class CameraService {
  static CameraService? _instance;
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _hasPermission = false;
  String? _errorMessage;
  FlashMode _currentFlashMode = FlashMode.off;
  
  // Performance optimization variables
  ResolutionPreset _currentResolution = ResolutionPreset.high;
  bool _isLowEndDevice = false;
  bool _isHighEndDevice = false;
  static const int _maxImageSize = 3840; // Maximum image size for processing (4K)
  static const int _compressionQuality = 95; // JPEG compression quality (higher for better quality)
  
  // Error handling and retry variables
  final ErrorHandlerService _errorHandler = ErrorHandlerService.instance;
  int _initializationRetryCount = 0;
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  CameraService._();
  
  static CameraService get instance {
    _instance ??= CameraService._();
    return _instance!;
  }
  
  Future<void> initialize() async {
    try {
      print('CameraService: Starting initialization...');
      
      // Check camera permissions first
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        _hasPermission = false;
        _errorMessage = 'Camera permission denied';
        print('CameraService: Permission denied - $status');
        throw _errorHandler.handlePermissionError(status);
      }
      
      _hasPermission = true;
      print('CameraService: Permission granted');
      
      if (_cameras != null && _isInitialized && _controller != null && _controller!.value.isInitialized) {
        print('CameraService: Already initialized, skipping...');
        return;
      }
      
      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _errorMessage = 'No cameras available';
        print('CameraService: No cameras available');
        throw _errorHandler.handleError('No cameras available', ErrorType.camera);
      }
      
      print('CameraService: Found ${_cameras!.length} cameras');
      
      // Determine optimal resolution based on device capabilities
      _determineOptimalResolution();
      
      // Dispose existing controller if any
      if (_controller != null) {
        print('CameraService: Disposing existing controller');
        await _controller!.dispose();
        _controller = null;
      }
      
      // Create controller with optimized settings
      _controller = CameraController(
        _cameras![0],
        _currentResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      print('CameraService: Controller created, initializing...');
      
      // Initialize with timeout
      await _controller!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('CameraService: Initialization timeout');
          throw _errorHandler.handleError('Camera initialization timeout', ErrorType.camera);
        },
      );
      
      _isInitialized = true;
      _errorMessage = null;
      _initializationRetryCount = 0; // Reset retry count on success
      
      print('CameraService: Initialization successful');
      print('CameraService: Controller value isInitialized: ${_controller!.value.isInitialized}');
      
      // Set initial flash mode (non-blocking)
      _controller!.setFlashMode(_currentFlashMode).catchError((e) {
        print('CameraService: Flash mode setting failed: $e');
        // Silently handle flash errors
      });
      
    } catch (e) {
      _isInitialized = false;
      _errorMessage = e.toString();
      
      print('CameraService: Initialization failed: $e');
      
      // Clean up on error
      if (_controller != null) {
        try {
          await _controller!.dispose();
        } catch (disposeError) {
          print('CameraService: Error disposing controller: $disposeError');
        }
        _controller = null;
      }
      
      // Handle specific error types
      if (e is ErrorInfo) {
        throw e;
      }
      
      throw _errorHandler.handleError(e, ErrorType.camera);
    }
  }
  
  // Enhanced initialization with retry mechanism
  Future<void> initializeWithRetry() async {
    _initializationRetryCount = 0;
    
    while (_initializationRetryCount < _maxRetryAttempts) {
      try {
        await initialize();
        return; // Success
      } catch (e) {
        _initializationRetryCount++;
        
        // Clean up on error
        _controller?.dispose();
        _controller = null;
        _isInitialized = false;
        
        if (_initializationRetryCount >= _maxRetryAttempts) {
          // Max retries reached, throw the error
          throw e;
        }
        
        // Wait before retrying with exponential backoff
        final delay = Duration(seconds: _retryDelay.inSeconds * _initializationRetryCount);
        await Future.delayed(delay);
      }
    }
  }
  
  // Performance optimization methods
  void _determineOptimalResolution() {
    // Use high resolution by default for better image quality
    // Only use lower resolution for very low-end devices
    if (_isLowEndDevice) {
      _currentResolution = ResolutionPreset.medium;
    } else {
      _currentResolution = ResolutionPreset.high;
    }
  }
  
  void setDeviceCapability(bool isLowEnd, bool isHighEnd) {
    _isLowEndDevice = isLowEnd;
    _isHighEndDevice = isHighEnd;
    
    // Re-initialize with optimal resolution if already initialized
    if (_isInitialized) {
      _reinitializeWithOptimalResolution();
    }
  }
  
  Future<void> _reinitializeWithOptimalResolution() async {
    try {
      if (_controller != null) {
        await _controller!.dispose();
      }
      
      _determineOptimalResolution();
      
      _controller = CameraController(
        _cameras![0],
        _currentResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      await _controller!.setFlashMode(_currentFlashMode);
    } catch (e) {
      throw _errorHandler.handleError(e, ErrorType.camera);
    }
  }
  
  Future<File?> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw _errorHandler.handleError('Camera not initialized', ErrorType.camera);
    }
    
    try {
      // Capture image with timeout
      final XFile image = await _controller!.takePicture().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw _errorHandler.handleError('Image capture timeout', ErrorType.camera);
        },
      );
      
      final File originalFile = File(image.path);
      
      // For better performance, return the original file immediately
      // and let the UI handle optimization if needed
      return originalFile;
      
    } catch (e) {
      throw _errorHandler.handleError(e, ErrorType.processing);
    }
  }
  
  Future<File> _compressAndOptimizeImage(File originalFile) async {
    try {
      // Read the original image
      final Uint8List bytes = await originalFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw _errorHandler.handleError('Failed to decode captured image', ErrorType.processing);
      }
      
      // Resize image if it's too large for processing
      img.Image processedImage = image;
      if (image.width > _maxImageSize || image.height > _maxImageSize) {
        final double scale = _maxImageSize / math.max(image.width, image.height);
        final int newWidth = (image.width * scale).toInt();
        final int newHeight = (image.height * scale).toInt();
        
        processedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );
      }
      
      // Compress the image
      final Uint8List compressedBytes = img.encodeJpg(
        processedImage,
        quality: _compressionQuality,
      );
      
      // Save to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      // If compression fails, return the original file
      if (e is ErrorInfo) {
        throw e;
      }
      
      // Check if it's a storage error
      if (e.toString().toLowerCase().contains('storage') || 
          e.toString().toLowerCase().contains('file')) {
        throw _errorHandler.handleError(e, ErrorType.storage);
      }
      
      // Check if it's a memory error
      if (e.toString().toLowerCase().contains('memory')) {
        throw _errorHandler.handleError(e, ErrorType.memory);
      }
      
      // Default to processing error
      throw _errorHandler.handleError(e, ErrorType.processing);
    }
  }
  
  Future<void> setFlashMode(FlashMode mode) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw _errorHandler.handleError('Camera not initialized', ErrorType.camera);
    }
    
    try {
      await _controller!.setFlashMode(mode);
      _currentFlashMode = mode;
    } catch (e) {
      throw _errorHandler.handleError(e, ErrorType.camera);
    }
  }
  
  Future<FlashMode> getFlashMode() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return _currentFlashMode;
    }
    
    try {
      return _controller!.value.flashMode;
    } catch (e) {
      return _currentFlashMode;
    }
  }
  
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      throw _errorHandler.handleError('No additional cameras available', ErrorType.camera);
    }
    
    if (_controller == null) {
      throw _errorHandler.handleError('Camera not initialized', ErrorType.camera);
    }
    
    try {
      // Dispose current controller
      await _controller!.dispose();
      
      // Switch to next camera
      final currentIndex = _cameras!.indexWhere((camera) => camera.name == _controller!.description.name);
      final nextIndex = (currentIndex + 1) % _cameras!.length;
      
      _controller = CameraController(
        _cameras![nextIndex],
        _currentResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      await _controller!.setFlashMode(_currentFlashMode);
    } catch (e) {
      throw _errorHandler.handleError(e, ErrorType.camera);
    }
  }
  
  Widget buildCameraPreview() {
    print('CameraService: buildCameraPreview called');
    print('CameraService: _isInitialized: $_isInitialized');
    print('CameraService: _controller: ${_controller != null}');
    
    if (!_isInitialized || _controller == null) {
      print('CameraService: Not initialized or no controller');
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Initializing camera...',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    // Check if controller is properly initialized
    print('CameraService: Controller value isInitialized: ${_controller!.value.isInitialized}');
    if (!_controller!.value.isInitialized) {
      print('CameraService: Controller not initialized');
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Camera controller initializing...',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    print('CameraService: Returning CameraPreview');
    // Return camera preview directly
    return CameraPreview(_controller!);
  }
  
  Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxImageSize.toDouble(),
        maxHeight: _maxImageSize.toDouble(),
        imageQuality: _compressionQuality,
      );
      
      if (image != null) {
        final File originalFile = File(image.path);
        // Compress and optimize the selected image
        return await _compressAndOptimizeImage(originalFile);
      }
      
      return null;
    } catch (e) {
      throw _errorHandler.handleError(e, ErrorType.processing);
    }
  }
  
  // Enhanced error handling methods
  Future<void> handlePermissionError() async {
    final status = await Permission.camera.status;
    if (status == PermissionStatus.permanentlyDenied) {
      // Open app settings
      await openAppSettings();
    } else {
      // Request permission again
      await Permission.camera.request();
    }
  }
  
  Future<void> handleStorageError() async {
    // Check available storage
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = tempDir.listSync();
      
      // Clean up old temporary files if storage is low
      if (files.length > 100) {
        for (int i = 0; i < files.length - 50; i++) {
          try {
            await files[i].delete();
          } catch (e) {
            // Ignore deletion errors
          }
        }
      }
    } catch (e) {
      // Ignore storage check errors
    }
  }
  
  // Getters for performance monitoring
  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;
  CameraController? get controller => _controller;
  ResolutionPreset get currentResolution => _currentResolution;
  bool get isLowEndDevice => _isLowEndDevice;
  bool get isHighEndDevice => _isHighEndDevice;
  int get initializationRetryCount => _initializationRetryCount;
  int get maxRetryAttempts => _maxRetryAttempts;
  
  // Additional getters for camera properties
  List<CameraDescription>? get cameras => _cameras;
  bool get hasFlash => _controller?.value.flashMode != FlashMode.off || _currentFlashMode != FlashMode.off;
  
  // Performance monitoring
  bool get isPerformanceOptimized => _isInitialized && _controller?.value.isInitialized == true;
  String get performanceStatus {
    if (!_isInitialized) return 'Not initialized';
    if (_controller?.value.isInitialized != true) return 'Controller not ready';
    return 'Optimized';
  }
  
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _initializationRetryCount = 0;
    _cameras = null;
    _errorMessage = null;
  }
} 