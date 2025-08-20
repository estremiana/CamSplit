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
  ResolutionPreset _currentResolution = ResolutionPreset.medium;
  bool _isLowEndDevice = false;
  bool _isHighEndDevice = false;
  static const int _maxImageSize = 1920; // Maximum image size for processing
  static const int _compressionQuality = 85; // JPEG compression quality
  
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
      // Check camera permissions first
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        _hasPermission = false;
        _errorMessage = 'Camera permission denied';
        throw _errorHandler.handlePermissionError(status);
      }
      
      _hasPermission = true;
      
      if (_cameras != null && _isInitialized) return;
      
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _errorMessage = 'No cameras available';
        throw _errorHandler.handleError('No cameras available', ErrorType.camera);
      }
      
      // Determine optimal resolution based on device capabilities
      _determineOptimalResolution();
      
      _controller = CameraController(
        _cameras![0],
        _currentResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      _isInitialized = true;
      _errorMessage = null;
      _initializationRetryCount = 0; // Reset retry count on success
      
      // Set initial flash mode
      await _controller!.setFlashMode(_currentFlashMode);
      
    } catch (e) {
      _isInitialized = false;
      _errorMessage = e.toString();
      
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
        
        if (_initializationRetryCount >= _maxRetryAttempts) {
          // Max retries reached, throw the error
          throw e;
        }
        
        // Wait before retrying
        await Future.delayed(_retryDelay);
      }
    }
  }
  
  // Performance optimization methods
  void _determineOptimalResolution() {
    // This is a simplified device capability detection
    // In a real implementation, you would use device_info_plus package
    // to get actual device specifications
    
    // For now, we'll use a conservative approach
    if (_isLowEndDevice) {
      _currentResolution = ResolutionPreset.low;
    } else if (_isHighEndDevice) {
      _currentResolution = ResolutionPreset.high;
    } else {
      _currentResolution = ResolutionPreset.medium;
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
      final XFile image = await _controller!.takePicture();
      final File originalFile = File(image.path);
      
      // Compress and optimize the captured image
      final File optimizedFile = await _compressAndOptimizeImage(originalFile);
      
      return optimizedFile;
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
    if (!_isInitialized || _controller == null) {
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
    
    // Return real camera preview with proper aspect ratio handling
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: CameraPreview(_controller!),
    );
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
  
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _initializationRetryCount = 0;
  }
} 