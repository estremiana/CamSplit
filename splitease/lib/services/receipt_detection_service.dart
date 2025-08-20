import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class DetectionResult {
  final bool isDetected;
  final double confidence;
  final List<Offset> boundaries;
  final Rect? boundingBox;
  final String? errorMessage;

  const DetectionResult({
    required this.isDetected,
    required this.confidence,
    required this.boundaries,
    this.boundingBox,
    this.errorMessage,
  });

  DetectionResult copyWith({
    bool? isDetected,
    double? confidence,
    List<Offset>? boundaries,
    Rect? boundingBox,
    String? errorMessage,
  }) {
    return DetectionResult(
      isDetected: isDetected ?? this.isDetected,
      confidence: confidence ?? this.confidence,
      boundaries: boundaries ?? this.boundaries,
      boundingBox: boundingBox ?? this.boundingBox,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ReceiptDetectionService {
  static ReceiptDetectionService? _instance;
  StreamController<DetectionResult>? _detectionController;
  bool _isDetecting = false;
  bool _isCalibrated = false;
  double _detectionSensitivity = 0.7;
  Timer? _detectionTimer;
  int _frameCount = 0;
  
  // Performance optimization variables
  static const int _initialFrameSkip = 10; // Process every 10th frame initially
  static const int _maxFrameSkip = 20; // Maximum frame skip for low-end devices
  static const int _minFrameSkip = 5; // Minimum frame skip for high-end devices
  int _currentFrameSkip = _initialFrameSkip;
  int _consecutiveDetections = 0;
  int _consecutiveNoDetections = 0;
  DateTime _lastProcessingTime = DateTime.now();
  static const Duration _minProcessingInterval = Duration(milliseconds: 200);
  
  // Memory management
  static const int _maxCachedResults = 5;
  final List<DetectionResult> _cachedResults = [];
  bool _isLowMemoryMode = false;

  ReceiptDetectionService._();

  static ReceiptDetectionService get instance {
    _instance ??= ReceiptDetectionService._();
    return _instance!;
  }

  // Enhanced methods for better user experience
  Future<void> calibrateDetection(File sampleImage) async {
    try {
      final result = await analyzeStaticImage(sampleImage);
      if (result.isDetected && result.confidence > 0.8) {
        _isCalibrated = true;
        // Adjust sensitivity based on successful detection
        _detectionSensitivity = (result.confidence * 0.8).clamp(0.5, 0.9);
        // Optimize frame skip based on device performance
        _optimizeFrameSkip();
      }
    } catch (e) {
      _isCalibrated = false;
      throw Exception('Calibration failed: $e');
    }
  }

  double getDetectionSensitivity() => _detectionSensitivity;

  void setDetectionSensitivity(double sensitivity) {
    _detectionSensitivity = sensitivity.clamp(0.1, 1.0);
  }

  bool get isCalibrated => _isCalibrated;

  // Performance optimization methods
  void _optimizeFrameSkip() {
    // Adjust frame skip based on detection patterns
    if (_consecutiveDetections > 3) {
      // If we're consistently detecting, we can process less frequently
      _currentFrameSkip = math.min(_currentFrameSkip + 2, _maxFrameSkip);
    } else if (_consecutiveNoDetections > 5) {
      // If we're not detecting anything, process more frequently
      _currentFrameSkip = math.max(_currentFrameSkip - 1, _minFrameSkip);
    }
  }

  void _updateDetectionCounters(DetectionResult result) {
    if (result.isDetected && result.confidence > _detectionSensitivity) {
      _consecutiveDetections++;
      _consecutiveNoDetections = 0;
    } else {
      _consecutiveNoDetections++;
      _consecutiveDetections = 0;
    }
    
    _optimizeFrameSkip();
  }

  void _checkMemoryUsage() {
    // Simple memory management - clear cache if it gets too large
    if (_cachedResults.length > _maxCachedResults) {
      _cachedResults.removeRange(0, _cachedResults.length - _maxCachedResults);
    }
    
    // Check if we should enable low memory mode
    if (_cachedResults.length >= _maxCachedResults) {
      _isLowMemoryMode = true;
      _currentFrameSkip = _maxFrameSkip; // Process less frequently
    } else {
      _isLowMemoryMode = false;
    }
  }

  Stream<DetectionResult> detectReceipt() {
    if (_detectionController == null) {
      _detectionController = StreamController<DetectionResult>.broadcast();
    }
    return _detectionController!.stream;
  }

  Future<DetectionResult> analyzeStaticImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final img.Image? decodedImage = img.decodeImage(bytes);
      
      if (decodedImage == null) {
        return const DetectionResult(
          isDetected: false,
          confidence: 0.0,
          boundaries: [],
          errorMessage: 'Failed to decode image',
        );
      }

      return _detectReceiptInImage(decodedImage);
    } catch (e) {
      return DetectionResult(
        isDetected: false,
        confidence: 0.0,
        boundaries: [],
        errorMessage: 'Analysis failed: $e',
      );
    }
  }

  void startDetection() {
    if (_isDetecting) return;
    
    _isDetecting = true;
    _frameCount = 0;
    _consecutiveDetections = 0;
    _consecutiveNoDetections = 0;
    _currentFrameSkip = _initialFrameSkip;
    _isLowMemoryMode = false;
    _cachedResults.clear();
    
    // Start periodic detection updates with adaptive timing
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isDetecting) {
        timer.cancel();
      }
    });
  }

  void stopDetection() {
    _isDetecting = false;
    _detectionTimer?.cancel();
    _detectionTimer = null;
    _cachedResults.clear();
  }

  void _processImageFrame(CameraImage image) async {
    if (!_isDetecting) return;

    // Frame rate limiting with adaptive processing
    _frameCount++;
    if (_frameCount % _currentFrameSkip != 0) return;

    // Check processing interval to prevent overwhelming the system
    final now = DateTime.now();
    if (now.difference(_lastProcessingTime) < _minProcessingInterval) return;
    _lastProcessingTime = now;

    try {
      final result = await _detectReceiptInCameraFrame(image);
      
      // Update detection counters for adaptive processing
      _updateDetectionCounters(result);
      
      // Cache result for memory management
      _cachedResults.add(result);
      _checkMemoryUsage();
      
      _detectionController?.add(result);
    } catch (e) {
      final errorResult = DetectionResult(
        isDetected: false,
        confidence: 0.0,
        boundaries: [],
        errorMessage: 'Frame processing failed: $e',
      );
      _detectionController?.add(errorResult);
    }
  }

  Future<DetectionResult> _detectReceiptInCameraFrame(CameraImage image) async {
    try {
      // Convert CameraImage to processable format with optimization
      final img.Image? decodedImage = await _cameraImageToImage(image);
      
      if (decodedImage == null) {
        return const DetectionResult(
          isDetected: false,
          confidence: 0.0,
          boundaries: [],
          errorMessage: 'Failed to convert camera frame',
        );
      }

      return _detectReceiptInImage(decodedImage);
    } catch (e) {
      return DetectionResult(
        isDetected: false,
        confidence: 0.0,
        boundaries: [],
        errorMessage: 'Camera frame detection failed: $e',
      );
    }
  }

  Future<img.Image?> _cameraImageToImage(CameraImage cameraImage) async {
    try {
      // Optimize image processing based on memory mode
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in cameraImage.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());
      final Rect imageRect = Rect.fromLTWH(0, 0, imageSize.width, imageSize.height);

      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder, imageRect);
      final Paint paint = Paint()..color = Colors.white;
      canvas.drawRect(imageRect, paint);

      final ui.Picture picture = pictureRecorder.endRecording();
      
      // Optimize image size for processing
      final int targetWidth = _isLowMemoryMode 
          ? (imageSize.width * 0.5).toInt() 
          : imageSize.width.toInt();
      final int targetHeight = _isLowMemoryMode 
          ? (imageSize.height * 0.5).toInt() 
          : imageSize.height.toInt();
      
      final ui.Image uiImage = await picture.toImage(targetWidth, targetHeight);
      final ByteData? byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        return img.decodeImage(byteData.buffer.asUint8List());
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  DetectionResult _detectReceiptInImage(img.Image image) {
    try {
      // Step 1: Convert to grayscale
      final img.Image grayscale = img.grayscale(image);
      
      // Step 2: Apply Gaussian blur to reduce noise (optimized for performance)
      final int blurRadius = _isLowMemoryMode ? 1 : 2;
      final img.Image blurred = img.gaussianBlur(grayscale, radius: blurRadius);
      
      // Step 3: Apply edge detection (Canny-like algorithm)
      final img.Image edges = _detectEdges(blurred);
      
      // Step 4: Find contours
      final List<List<Point>> contours = _findContours(edges);
      
      // Step 5: Analyze contours for rectangular shapes
      final DetectionResult result = _analyzeContours(contours, image.width, image.height);
      
      return result;
    } catch (e) {
      return DetectionResult(
        isDetected: false,
        confidence: 0.0,
        boundaries: [],
        errorMessage: 'Detection algorithm failed: $e',
      );
    }
  }

  img.Image _detectEdges(img.Image image) {
    // Simple Sobel edge detection
    final img.Image result = img.Image.from(image);
    
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        // Sobel kernels
        double gx = 0, gy = 0;
        
        // Gx kernel
        gx += img.getLuminance(image.getPixel(x - 1, y - 1)) * -1;
        gx += img.getLuminance(image.getPixel(x - 1, y)) * -2;
        gx += img.getLuminance(image.getPixel(x - 1, y + 1)) * -1;
        gx += img.getLuminance(image.getPixel(x + 1, y - 1)) * 1;
        gx += img.getLuminance(image.getPixel(x + 1, y)) * 2;
        gx += img.getLuminance(image.getPixel(x + 1, y + 1)) * 1;
        
        // Gy kernel
        gy += img.getLuminance(image.getPixel(x - 1, y - 1)) * -1;
        gy += img.getLuminance(image.getPixel(x, y - 1)) * -2;
        gy += img.getLuminance(image.getPixel(x + 1, y - 1)) * -1;
        gy += img.getLuminance(image.getPixel(x - 1, y + 1)) * 1;
        gy += img.getLuminance(image.getPixel(x, y + 1)) * 2;
        gy += img.getLuminance(image.getPixel(x + 1, y + 1)) * 1;
        
        final magnitude = math.sqrt(gx * gx + gy * gy);
        final threshold = 50.0;
        
        if (magnitude > threshold) {
          result.setPixel(x, y, img.ColorRgb8(255, 255, 255));
        } else {
          result.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
    }
    
    return result;
  }

  List<List<Point>> _findContours(img.Image image) {
    // Simplified contour detection
    final List<List<Point>> contours = [];
    final Set<String> visited = {};
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = img.getLuminance(image.getPixel(x, y));
        final key = '$x,$y';
        
        if (pixel > 0 && !visited.contains(key)) {
          final contour = _traceContour(image, x, y, visited);
          if (contour.length > 10) { // Minimum contour size
            contours.add(contour);
          }
        }
      }
    }
    
    return contours;
  }

  List<Point> _traceContour(img.Image image, int startX, int startY, Set<String> visited) {
    final List<Point> contour = [];
    final List<Point> stack = [Point(startX, startY)];
    
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      final key = '${current.x},${current.y}';
      
      if (visited.contains(key)) continue;
      
      visited.add(key);
      contour.add(current);
      
      // Check 8-connected neighbors
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          
          final nx = current.x + dx;
          final ny = current.y + dy;
          
          if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
            final pixel = img.getLuminance(image.getPixel(nx, ny));
            if (pixel > 0) {
              stack.add(Point(nx, ny));
            }
          }
        }
      }
    }
    
    return contour;
  }

  DetectionResult _analyzeContours(List<List<Point>> contours, int imageWidth, int imageHeight) {
    if (contours.isEmpty) {
      return const DetectionResult(
        isDetected: false,
        confidence: 0.0,
        boundaries: [],
      );
    }

    // Find the largest contour (most likely to be a receipt)
    List<Point> largestContour = contours.reduce((a, b) => a.length > b.length ? a : b);
    
    // Convert contour to boundary points
    final List<Offset> boundaries = largestContour.map((point) {
      return Offset(
        point.x / imageWidth,
        point.y / imageHeight,
      );
    }).toList();

    // Calculate bounding box
    final double minX = boundaries.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
    final double maxX = boundaries.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final double minY = boundaries.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
    final double maxY = boundaries.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

    final boundingBox = Rect.fromLTRB(minX, minY, maxX, maxY);

    // Calculate confidence based on rectangularity and size
    final double confidence = _calculateConfidence(largestContour, boundingBox, imageWidth, imageHeight);
    
    final bool isDetected = confidence >= _detectionSensitivity;

    return DetectionResult(
      isDetected: isDetected,
      confidence: confidence,
      boundaries: boundaries,
      boundingBox: boundingBox,
    );
  }

  double _calculateConfidence(List<Point> contour, Rect boundingBox, int imageWidth, int imageHeight) {
    // Calculate rectangularity (how close the shape is to a rectangle)
    final double contourArea = _calculateContourArea(contour);
    final double boundingBoxArea = boundingBox.width * boundingBox.height;
    final double rectangularity = contourArea / boundingBoxArea;

    // Calculate size factor (receipts should be reasonably sized)
    final double imageArea = imageWidth.toDouble() * imageHeight.toDouble();
    final double sizeFactor = boundingBoxArea / imageArea;
    
    // Ideal size for a receipt is between 20% and 80% of the image
    final double sizeScore = sizeFactor >= 0.2 && sizeFactor <= 0.8 ? 1.0 : 0.5;

    // Calculate aspect ratio (receipts are typically rectangular)
    final double aspectRatio = boundingBox.width / boundingBox.height;
    final double aspectScore = aspectRatio >= 0.5 && aspectRatio <= 2.0 ? 1.0 : 0.3;

    // Combine scores
    final double confidence = (rectangularity * 0.4 + sizeScore * 0.3 + aspectScore * 0.3);
    
    return confidence.clamp(0.0, 1.0);
  }

  double _calculateContourArea(List<Point> contour) {
    // Shoelace formula for polygon area
    double area = 0.0;
    for (int i = 0; i < contour.length; i++) {
      final j = (i + 1) % contour.length;
      area += contour[i].x * contour[j].y;
      area -= contour[j].x * contour[i].y;
    }
    return (area / 2.0).abs();
  }

  void dispose() {
    stopDetection();
    _detectionController?.close();
    _detectionController = null;
  }
}

class Point {
  final int x;
  final int y;
  
  const Point(this.x, this.y);
}
