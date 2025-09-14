import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:camsplit/presentation/camera_capture/flexible_camera_capture.dart';
import 'package:camsplit/presentation/camera_capture/config/camera_capture_config.dart';
import 'package:camsplit/presentation/camera_capture/config/camera_capture_modes.dart';
import 'package:camsplit/presentation/camera_capture/config/camera_capture_mode.dart';
import 'package:camsplit/presentation/camera_capture/config/camera_capture_theme.dart';

void main() {
  group('FlexibleCameraCapture', () {
    testWidgets('should display correct title from config', (WidgetTester tester) async {
      const config = CameraCaptureConfig(
        title: 'Test Camera',
        mode: CameraCaptureMode.general,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlexibleCameraCapture(config: config),
        ),
      );

      expect(find.text('Test Camera'), findsOneWidget);
    });

    testWidgets('should call onCancel when close button is tapped', (WidgetTester tester) async {
      bool onCancelCalled = false;
      
      final config = CameraCaptureConfig(
        title: 'Test Camera',
        mode: CameraCaptureMode.general,
        onCancel: () => onCancelCalled = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlexibleCameraCapture(config: config),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(onCancelCalled, isTrue);
    });

    testWidgets('should respect enableGallery configuration', (WidgetTester tester) async {
      final config = CameraCaptureConfig(
        title: 'Test Camera',
        mode: CameraCaptureMode.general,
        enableGallery: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlexibleCameraCapture(config: config),
        ),
      );

      // Gallery button should not be present
      expect(find.byIcon(Icons.photo_library), findsNothing);
    });

    testWidgets('should respect enableFlash configuration', (WidgetTester tester) async {
      final config = CameraCaptureConfig(
        title: 'Test Camera',
        mode: CameraCaptureMode.general,
        enableFlash: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlexibleCameraCapture(config: config),
        ),
      );

      // Flash button should not be present
      expect(find.byIcon(Icons.flash_on), findsNothing);
    });

    testWidgets('should use custom theme colors', (WidgetTester tester) async {
      final config = CameraCaptureConfig(
        title: 'Test Camera',
        mode: CameraCaptureMode.general,
        theme: CameraCaptureTheme(
          primaryColor: Colors.red,
          backgroundColor: Colors.blue,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlexibleCameraCapture(config: config),
        ),
      );

      // Check if theme colors are applied
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.blue));
    });
  });

  group('CameraCaptureModes', () {
    test('receiptMode should have correct default configuration', () {
      final config = CameraCaptureModes.receiptMode(
        onImageCaptured: (File image) async {},
      );

      expect(config.title, equals('Receipt Capture'));
      expect(config.mode, equals(CameraCaptureMode.receipt));
      expect(config.enableCrop, isTrue);
      expect(config.enableGallery, isTrue);
      expect(config.enableFlash, isTrue);
      expect(config.enableCameraSwitch, isTrue);
    });

    test('documentMode should have correct default configuration', () {
      final config = CameraCaptureModes.documentMode(
        onImageCaptured: (File image) async {},
      );

      expect(config.title, equals('Document Capture'));
      expect(config.mode, equals(CameraCaptureMode.document));
      expect(config.enableFlash, isFalse);
      expect(config.enableCameraSwitch, isFalse);
    });

    test('generalMode should have correct default configuration', () {
      final config = CameraCaptureModes.generalMode(
        onImageCaptured: (File image) async {},
      );

      expect(config.title, equals('Take Photo'));
      expect(config.mode, equals(CameraCaptureMode.general));
      expect(config.enableCrop, isFalse);
      expect(config.showInstructions, isFalse);
    });
  });
}
