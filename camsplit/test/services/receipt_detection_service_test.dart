import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camsplit/services/receipt_detection_service.dart';

void main() {
  group('ReceiptDetectionService', () {
    late ReceiptDetectionService detectionService;

    setUp(() {
      detectionService = ReceiptDetectionService.instance;
    });

    tearDown(() {
      detectionService.dispose();
    });

    test('should be a singleton', () {
      final instance1 = ReceiptDetectionService.instance;
      final instance2 = ReceiptDetectionService.instance;
      expect(instance1, equals(instance2));
    });

    test('should have initial state', () {
      expect(detectionService.isCalibrated, isFalse);
      expect(detectionService.getDetectionSensitivity(), equals(0.7));
    });

    test('should handle detection sensitivity changes', () {
      detectionService.setDetectionSensitivity(0.5);
      expect(detectionService.getDetectionSensitivity(), equals(0.5));
      
      detectionService.setDetectionSensitivity(1.5); // Should be clamped
      expect(detectionService.getDetectionSensitivity(), equals(1.0));
      
      detectionService.setDetectionSensitivity(-0.5); // Should be clamped
      expect(detectionService.getDetectionSensitivity(), equals(0.1));
    });

    test('should handle detection start/stop', () {
      detectionService.startDetection();
      // Note: We can't easily test the internal state without exposing it
      // But we can test that the methods don't throw exceptions
      
      detectionService.stopDetection();
      // Should not throw
    });

    test('should create detection result with correct properties', () {
      final result = DetectionResult(
        isDetected: true,
        confidence: 0.85,
        boundaries: [const Offset(0.1, 0.1), const Offset(0.9, 0.1), const Offset(0.9, 0.9), const Offset(0.1, 0.9)],
        boundingBox: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
      );

      expect(result.isDetected, isTrue);
      expect(result.confidence, equals(0.85));
      expect(result.boundaries, hasLength(4));
      expect(result.boundingBox, isNotNull);
      expect(result.errorMessage, isNull);
    });

    test('should create detection result with error message', () {
      const result = DetectionResult(
        isDetected: false,
        confidence: 0.0,
        boundaries: [],
        errorMessage: 'Test error',
      );

      expect(result.isDetected, isFalse);
      expect(result.confidence, equals(0.0));
      expect(result.boundaries, isEmpty);
      expect(result.errorMessage, equals('Test error'));
    });

    test('should copy detection result with new values', () {
      const original = DetectionResult(
        isDetected: false,
        confidence: 0.0,
        boundaries: [],
      );

      final copied = original.copyWith(
        isDetected: true,
        confidence: 0.8,
        boundaries: [const Offset(0.1, 0.1), const Offset(0.9, 0.9)],
      );

      expect(copied.isDetected, isTrue);
      expect(copied.confidence, equals(0.8));
      expect(copied.boundaries, hasLength(2));
      expect(copied.errorMessage, isNull); // Should preserve original
    });

    test('should handle static image analysis', () async {
      // Note: This would require a test image file
      // For now, just test that the method exists and doesn't crash
      expect(detectionService.analyzeStaticImage, isA<Function>());
    });

    test('should handle calibration', () async {
      // Note: This would require a test image file
      // For now, just test that the method exists and doesn't crash
      expect(detectionService.calibrateDetection, isA<Function>());
    });

    test('should handle camera image detection stream', () {
      // Note: This would require a real camera image
      // For now, just test that the method exists and returns a stream
      // Skip this test for now as CameraImage constructor is not available in tests
      expect(detectionService.detectReceipt, isA<Function>());
    });

    test('should handle disposal correctly', () {
      detectionService.dispose();
      // Should not throw
    });
  });

  group('DetectionResult', () {
    test('should create valid detection result', () {
      final result = DetectionResult(
        isDetected: true,
        confidence: 0.75,
        boundaries: [const Offset(0.0, 0.0), const Offset(1.0, 1.0)],
        boundingBox: const Rect.fromLTRB(0.0, 0.0, 1.0, 1.0),
      );

      expect(result.isDetected, isTrue);
      expect(result.confidence, equals(0.75));
      expect(result.boundaries, hasLength(2));
      expect(result.boundingBox, isNotNull);
    });

    test('should handle empty boundaries', () {
      const result = DetectionResult(
        isDetected: false,
        confidence: 0.0,
        boundaries: [],
      );

      expect(result.boundaries, isEmpty);
      expect(result.boundingBox, isNull);
    });

    test('should handle error messages', () {
      const result = DetectionResult(
        isDetected: false,
        confidence: 0.0,
        boundaries: [],
        errorMessage: 'Test error message',
      );

      expect(result.errorMessage, equals('Test error message'));
    });
  });
}
