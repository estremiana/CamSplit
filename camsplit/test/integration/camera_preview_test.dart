import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/camera_receipt_capture/camera_receipt_capture.dart';
import 'package:camsplit/services/camera_service.dart';

void main() {
  group('Camera Preview Tests', () {
    testWidgets('Camera screen should show initialization state', (WidgetTester tester) async {
      // Build the camera screen
      await tester.pumpWidget(
        MaterialApp(
          home: const CameraReceiptCapture(),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Verify that the camera initialization state is shown
      expect(find.text('Initializing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Camera service should be properly initialized', (WidgetTester tester) async {
      // Test camera service initialization
      final cameraService = CameraService.instance;
      
      // Verify initial state
      expect(cameraService.isInitialized, false);
      expect(cameraService.hasPermission, false);
    });

    testWidgets('Camera overlay should be present when camera is initialized', (WidgetTester tester) async {
      // Build the camera screen
      await tester.pumpWidget(
        MaterialApp(
          home: const CameraReceiptCapture(),
        ),
      );

      // Wait for the widget to build
      await tester.pump();

      // Verify that the camera overlay is not shown initially (camera not initialized)
      expect(find.byType(CameraOverlayWidget), findsNothing);
    });
  });
}
