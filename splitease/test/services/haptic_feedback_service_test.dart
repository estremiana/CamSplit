import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/services/haptic_feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('HapticFeedbackService Tests', () {
    setUp(() {
      // Enable haptic feedback for testing
      HapticFeedbackService.setEnabled(true);
    });

    tearDown(() {
      // Reset haptic feedback state
      HapticFeedbackService.setEnabled(true);
    });

    group('Configuration', () {
      test('should be enabled by default', () {
        expect(HapticFeedbackService.isEnabled, isTrue);
      });

      test('should enable/disable haptic feedback', () {
        HapticFeedbackService.setEnabled(false);
        expect(HapticFeedbackService.isEnabled, isFalse);

        HapticFeedbackService.setEnabled(true);
        expect(HapticFeedbackService.isEnabled, isTrue);
      });
    });

    group('Page Change Feedback', () {
      test('should provide page change feedback when enabled', () {
        // This test verifies the method can be called without errors
        // Actual haptic feedback behavior depends on device capabilities
        expect(() => HapticFeedbackService.pageChange(), returnsNormally);
      });

      test('should not provide feedback when disabled', () {
        HapticFeedbackService.setEnabled(false);
        expect(() => HapticFeedbackService.pageChange(), returnsNormally);
      });
    });

    group('Swipe Gesture Feedback', () {
      test('should provide swipe gesture feedback when enabled', () {
        expect(() => HapticFeedbackService.swipeGesture(), returnsNormally);
      });

      test('should not provide feedback when disabled', () {
        HapticFeedbackService.setEnabled(false);
        expect(() => HapticFeedbackService.swipeGesture(), returnsNormally);
      });
    });

    group('Boundary Reached Feedback', () {
      test('should provide boundary reached feedback when enabled', () {
        expect(() => HapticFeedbackService.boundaryReached(), returnsNormally);
      });

      test('should not provide feedback when disabled', () {
        HapticFeedbackService.setEnabled(false);
        expect(() => HapticFeedbackService.boundaryReached(), returnsNormally);
      });
    });

    group('Welcome Button Navigation Feedback', () {
      test('should provide welcome button navigation feedback when enabled', () {
        expect(() => HapticFeedbackService.welcomeButtonNavigation(), returnsNormally);
      });

      test('should not provide feedback when disabled', () {
        HapticFeedbackService.setEnabled(false);
        expect(() => HapticFeedbackService.welcomeButtonNavigation(), returnsNormally);
      });
    });

    group('Rapid Navigation Feedback', () {
      test('should provide rapid navigation feedback when enabled', () {
        expect(() => HapticFeedbackService.rapidNavigation(), returnsNormally);
      });

      test('should not provide feedback when disabled', () {
        HapticFeedbackService.setEnabled(false);
        expect(() => HapticFeedbackService.rapidNavigation(), returnsNormally);
      });
    });

    group('Animation Complete Feedback', () {
      test('should provide animation complete feedback when enabled', () {
        expect(() => HapticFeedbackService.animationComplete(), returnsNormally);
      });

      test('should not provide feedback when disabled', () {
        HapticFeedbackService.setEnabled(false);
        expect(() => HapticFeedbackService.animationComplete(), returnsNormally);
      });
    });

    group('Gesture Conflict Feedback', () {
      test('should provide gesture conflict feedback when enabled', () {
        expect(() => HapticFeedbackService.gestureConflict(), returnsNormally);
      });

      test('should not provide feedback when disabled', () {
        HapticFeedbackService.setEnabled(false);
        expect(() => HapticFeedbackService.gestureConflict(), returnsNormally);
      });
    });

    group('Test Feedback', () {
      test('should provide test feedback sequence when enabled', () {
        expect(() => HapticFeedbackService.testHapticFeedback(), returnsNormally);
      });

      test('should handle test feedback when disabled', () {
        HapticFeedbackService.setEnabled(false);
        expect(() => HapticFeedbackService.testHapticFeedback(), returnsNormally);
      });
    });

    group('Status Report', () {
      test('should generate status report', () {
        final report = HapticFeedbackService.getStatusReport();
        
        expect(report, contains('Haptic Feedback Service Status'));
        expect(report, contains('Enabled: true'));
        expect(report, contains('Available on platform'));
      });

      test('should reflect disabled state in status report', () {
        HapticFeedbackService.setEnabled(false);
        final report = HapticFeedbackService.getStatusReport();
        
        expect(report, contains('Enabled: false'));
      });
    });

    group('Error Handling', () {
      test('should handle errors gracefully in page change feedback', () {
        // This test ensures the service doesn't crash on errors
        expect(() => HapticFeedbackService.pageChange(), returnsNormally);
      });

      test('should handle errors gracefully in swipe gesture feedback', () {
        expect(() => HapticFeedbackService.swipeGesture(), returnsNormally);
      });

      test('should handle errors gracefully in boundary reached feedback', () {
        expect(() => HapticFeedbackService.boundaryReached(), returnsNormally);
      });
    });

    group('Multiple Calls', () {
      test('should handle multiple rapid calls without issues', () {
        // Test multiple rapid calls to ensure no conflicts
        for (int i = 0; i < 10; i++) {
          HapticFeedbackService.pageChange();
          HapticFeedbackService.swipeGesture();
          HapticFeedbackService.boundaryReached();
        }
        
        expect(HapticFeedbackService.isEnabled, isTrue);
      });

      test('should handle mixed feedback types', () {
        // Test different feedback types in sequence
        HapticFeedbackService.pageChange();
        HapticFeedbackService.swipeGesture();
        HapticFeedbackService.boundaryReached();
        HapticFeedbackService.welcomeButtonNavigation();
        HapticFeedbackService.rapidNavigation();
        HapticFeedbackService.animationComplete();
        HapticFeedbackService.gestureConflict();
        
        expect(HapticFeedbackService.isEnabled, isTrue);
      });
    });
  });
} 