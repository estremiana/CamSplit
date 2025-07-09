import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  static CameraService? _instance;
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  
  CameraService._();
  
  static CameraService get instance {
    _instance ??= CameraService._();
    return _instance!;
  }
  
  Future<void> initialize() async {
    if (_cameras != null) return;
    
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
    }
  }
  
  CameraController? get controller => _controller;
  List<CameraDescription>? get cameras => _cameras;
  
  Future<File?> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }
    
    try {
      final XFile image = await _controller!.takePicture();
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }
  
  Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }
  
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
} 