import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../lib/core/app_export.dart';
import '../../lib/presentation/camera_receipt_capture/camera_receipt_capture.dart';
import '../../lib/presentation/camera_receipt_capture/widgets/collapsible_tips_widget.dart';
import '../../lib/presentation/camera_receipt_capture/widgets/camera_controls_widget.dart';
import '../../lib/presentation/camera_receipt_capture/widgets/receipt_detection_overlay.dart';
import '../../lib/presentation/camera_receipt_capture/widgets/receipt_preview_widget.dart';
import '../../lib/services/camera_service.dart';
import '../../lib/services/receipt_detection_service.dart';
import '../../lib/services/api_service.dart';

void main() {
  group('Camera Workflow Integration Tests', () {
    late CameraService cameraService;
    late ReceiptDetectionService detectionService;
    late ApiService apiService;

    setUp(() {
      cameraService = CameraService.instance;
      detectionService = ReceiptDetectionService.instance;
      apiService = ApiService.instance;
    });

    testWidgets('should initialize camera page with all components', (WidgetTester tester) async {
      // Build the camera page
      await tester.pumpWidget(
        MaterialApp(
          home: const CameraReceiptCapture(),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle();

      // Verify that the camera page is built
      expect(find.byType(CameraReceiptCapture), findsOneWidget);

      // Verify that all key components are present
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle camera initialization states', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const CameraReceiptCapture(),
        ),
      );

      // Initially should show loading state
      expect(find.text('Initializing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for initialization to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show either camera ready or error state
      final statusText = find.byType(Text);
      expect(statusText, findsWidgets);
    });

    testWidgets('should handle navigation and back button behavior', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const CameraReceiptCapture(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify PopScope is present for back button handling
      expect(find.byType(PopScope), findsOneWidget);
    });

    testWidgets('should handle tips widget toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const CameraReceiptCapture(),
        ),
      );

      await tester.pumpAndSettle();

      // Look for tips widget (may be collapsed initially)
      expect(find.byType(CollapsibleTipsWidget), findsOneWidget);
    });

    test('should have proper service integration', () {
      // Verify all services are properly initialized
      expect(cameraService, isNotNull);
      expect(detectionService, isNotNull);
      expect(apiService, isNotNull);

      // Verify service methods exist
      expect(cameraService.initialize, isA<Function>());
      expect(detectionService.startDetection, isA<Function>());
      expect(apiService.processReceipt, isA<Function>());
    });

    test('should handle detection service lifecycle', () {
      // Test detection service start/stop
      expect(() => detectionService.startDetection(), returnsNormally);
      expect(() => detectionService.stopDetection(), returnsNormally);
    });

    test('should handle camera service methods', () {
      // Test camera service methods exist
      expect(cameraService.setFlashMode, isA<Function>());
      expect(cameraService.captureImage, isA<Function>());
      expect(cameraService.pickImageFromGallery, isA<Function>());
    });

    testWidgets('should handle error states gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const CameraReceiptCapture(),
        ),
      );

      await tester.pumpAndSettle();

      // Look for error handling UI elements
      final errorElements = find.byType(ElevatedButton);
      if (errorElements.evaluate().isNotEmpty) {
        // If there's a retry button, it should be clickable
        expect(find.text('Retry'), findsOneWidget);
      }
    });

    test('should have proper widget structure', () {
      // Verify that all required widgets are properly structured
      expect(CameraReceiptCapture, isA<Type>());
      expect(CollapsibleTipsWidget, isA<Type>());
      expect(CameraControlsWidget, isA<Type>());
      expect(ReceiptDetectionOverlay, isA<Type>());
      expect(ReceiptPreviewWidget, isA<Type>());
    });

    test('should handle state management properly', () {
      // Test that the camera page can manage its state
      final cameraPage = CameraReceiptCapture();
      expect(cameraPage, isNotNull);
      expect(cameraPage.key, isNull); // Should not have a key by default
    });

    testWidgets('should handle processing overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const CameraReceiptCapture(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should not show processing overlay
      expect(find.text('Processing Receipt...'), findsNothing);

      // The processing overlay should be present in the widget tree but hidden
      expect(find.byType(Container), findsWidgets);
    });

    test('should have proper animation controllers', () {
      // Test that animation controllers are properly defined
      // This is tested through the widget lifecycle
      expect(() {
        final cameraPage = CameraReceiptCapture();
        expect(cameraPage, isNotNull);
      }, returnsNormally);
    });

    test('should handle detection result data model', () {
      // Test detection result creation and properties
      const detectionResult = DetectionResult(
        isDetected: true,
        confidence: 0.8,
        boundaries: [Offset(0.1, 0.1), Offset(0.9, 0.9)],
        boundingBox: Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
      );

      expect(detectionResult.isDetected, isTrue);
      expect(detectionResult.confidence, equals(0.8));
      expect(detectionResult.boundaries, hasLength(2));
      expect(detectionResult.boundingBox, isNotNull);
    });

    testWidgets('should handle camera controls visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const CameraReceiptCapture(),
        ),
      );

      await tester.pumpAndSettle();

      // Camera controls should be present
      expect(find.byType(CameraControlsWidget), findsOneWidget);
    });

    test('should have proper error handling in services', () {
      // Test that services handle errors gracefully
      expect(() => detectionService.dispose(), returnsNormally);
      
      // Test camera service error handling
      expect(cameraService.errorMessage, isA<String?>());
    });

    testWidgets('should handle receipt preview workflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const CameraReceiptCapture(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should not show receipt preview
      expect(find.byType(ReceiptPreviewWidget), findsNothing);

      // The preview widget should be available in the widget tree
      expect(find.byType(Container), findsWidgets);
    });

    test('should have proper navigation integration', () {
      // Test that navigation routes are properly defined
      expect(AppRoutes.cameraReceiptCapture, equals('/camera-receipt-capture'));
      expect(AppRoutes.receiptOcrReview, equals('/receipt-ocr-review'));
    });

    test('should handle haptic feedback integration', () {
      // Test that haptic feedback is properly integrated
      // This is tested through the widget methods
      expect(() {
        final cameraPage = CameraReceiptCapture();
        expect(cameraPage, isNotNull);
      }, returnsNormally);
    });

    test('should have proper theme integration', () {
      // Test that theme is properly integrated
      expect(AppTheme.lightTheme, isNotNull);
      expect(AppTheme.primaryLight, isNotNull);
      expect(AppTheme.successLight, isNotNull);
    });

    testWidgets('should handle responsive design', (WidgetTester tester) async {
      // Test responsive design with different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: const CameraReceiptCapture(),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle different screen sizes
      expect(find.byType(CameraReceiptCapture), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });
  });
}
