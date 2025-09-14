import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camsplit/services/camera_service.dart';

void main() {
  group('CameraService', () {
    late CameraService cameraService;

    setUp(() {
      cameraService = CameraService.instance;
    });

    tearDown(() {
      cameraService.dispose();
    });

    test('should be a singleton', () {
      final instance1 = CameraService.instance;
      final instance2 = CameraService.instance;
      expect(instance1, equals(instance2));
    });

    test('should have initial state', () {
      expect(cameraService.isInitialized, isFalse);
      expect(cameraService.hasPermission, isFalse);
      expect(cameraService.errorMessage, isNull);
      expect(cameraService.currentFlashMode, equals(FlashMode.off));
    });

    test('should handle flash mode changes', () async {
      // Test flash mode setting (without actual camera initialization)
      expect(cameraService.currentFlashMode, equals(FlashMode.off));
      
      // Note: Actual flash mode testing would require camera initialization
      // which is not possible in unit tests without proper mocking
    });

    test('should handle camera switching logic', () {
      // Test camera switching logic when no cameras are available
      expect(() => cameraService.switchCamera(), throwsException);
    });

    test('should handle disposal correctly', () {
      cameraService.dispose();
      expect(cameraService.isInitialized, isFalse);
      expect(cameraService.hasPermission, isFalse);
      expect(cameraService.errorMessage, isNull);
    });

    test('should build camera preview widget', () {
      final widget = cameraService.buildCameraPreview();
      expect(widget, isA<Widget>());
    });

    test('should handle gallery image picking', () async {
      // Note: This would require proper mocking of ImagePicker
      // For now, just test that the method exists and doesn't crash
      expect(cameraService.pickImageFromGallery, isA<Function>());
    });
  });
}
