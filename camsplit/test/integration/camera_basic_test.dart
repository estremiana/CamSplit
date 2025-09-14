import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/services/camera_service.dart';

void main() {
  group('Camera Basic Tests', () {
    test('Camera service should be accessible', () {
      final cameraService = CameraService.instance;
      expect(cameraService, isNotNull);
    });

    test('Camera service should have initial state', () {
      final cameraService = CameraService.instance;
      expect(cameraService.isInitialized, false);
      expect(cameraService.hasPermission, false);
      expect(cameraService.errorMessage, isNull);
    });

    testWidgets('Camera preview should show loading state when not initialized', (WidgetTester tester) async {
      final cameraService = CameraService.instance;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cameraService.buildCameraPreview(),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing camera...'), findsOneWidget);
    });
  });
}
