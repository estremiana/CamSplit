import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Haptic feedback service for providing tactile feedback during navigation interactions.
/// 
/// This service centralizes haptic feedback management and provides consistent
/// feedback patterns across the navigation system.
class HapticFeedbackService {
  static const String _tag = 'HapticFeedbackService';
  
  /// Whether haptic feedback is enabled
  static bool _isEnabled = true;
  
  /// Counter for tracking feedback usage
  static int _feedbackCount = 0;
  
  /// Initialize the haptic feedback service
  static void initialize() {
    debugPrint('HapticFeedbackService: Initializing haptic feedback service');
    _isEnabled = true;
    _feedbackCount = 0;
  }
  
  /// Feedback intensity levels
  static const double _lightIntensity = 0.5;
  static const double _mediumIntensity = 0.7;
  static const double _heavyIntensity = 1.0;
  
  /// Enable or disable haptic feedback
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (kDebugMode) {
      debugPrint('HapticFeedbackService: Haptic feedback ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Check if haptic feedback is enabled
  static bool get isEnabled => _isEnabled;
  
  /// Provide haptic feedback for page changes (bottom navigation taps)
  /// 
  /// Uses selectionClick() for a subtle, responsive feel that indicates
  /// successful navigation selection.
  static void pageChange() {
    if (!_isEnabled) return;
    
    try {
      HapticFeedback.selectionClick();
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Page change feedback triggered');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Error providing page change feedback: $e');
      }
    }
  }
  
  /// Provide haptic feedback for swipe gestures
  /// 
  /// Uses lightImpact() for a gentle tactile response that follows the user's
  /// finger movement during swipe gestures.
  static void swipeGesture() {
    if (!_isEnabled) return;
    
    try {
      HapticFeedback.lightImpact();
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Swipe gesture feedback triggered');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Error providing swipe feedback: $e');
      }
    }
  }
  
  /// Provide haptic feedback for boundary conditions (edge swipes)
  /// 
  /// Uses mediumImpact() to indicate that the user has reached a navigation boundary
  /// and cannot swipe further in that direction.
  static void boundaryReached() {
    if (!_isEnabled) return;
    
    try {
      HapticFeedback.mediumImpact();
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Boundary reached feedback triggered');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Error providing boundary feedback: $e');
      }
    }
  }
  
  /// Provide haptic feedback for welcome button navigation
  /// 
  /// Uses selectionClick() for consistency with other navigation actions.
  static void welcomeButtonNavigation() {
    if (!_isEnabled) return;
    
    try {
      HapticFeedback.selectionClick();
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Welcome button navigation feedback triggered');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Error providing welcome button feedback: $e');
      }
    }
  }
  
  /// Provide haptic feedback for rapid navigation (when multiple actions occur quickly)
  /// 
  /// Uses lightImpact() to provide subtle feedback without being overwhelming.
  static void rapidNavigation() {
    if (!_isEnabled) return;
    
    try {
      HapticFeedback.lightImpact();
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Rapid navigation feedback triggered');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Error providing rapid navigation feedback: $e');
      }
    }
  }
  
  /// Provide haptic feedback for animation completion
  /// 
  /// Uses selectionClick() to indicate that a navigation animation has completed
  /// and the user is now on the target page.
  static void animationComplete() {
    if (!_isEnabled) return;
    
    try {
      HapticFeedback.selectionClick();
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Animation complete feedback triggered');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Error providing animation complete feedback: $e');
      }
    }
  }
  
  /// Provide haptic feedback for gesture conflicts (when internal scrolling prevents navigation)
  /// 
  /// Uses mediumImpact() to indicate that the gesture was recognized but could not
  /// be completed due to internal scrolling.
  static void gestureConflict() {
    if (!_isEnabled) return;
    
    try {
      HapticFeedback.mediumImpact();
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Gesture conflict feedback triggered');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('HapticFeedbackService: Error providing gesture conflict feedback: $e');
      }
    }
  }
  
  /// Test haptic feedback functionality
  /// 
  /// This method can be used for testing or debugging haptic feedback.
  static void testHapticFeedback() {
    if (!_isEnabled) {
      debugPrint('HapticFeedbackService: Haptic feedback is disabled');
      return;
    }
    
    try {
      // Test different feedback types
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.mediumImpact();
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        HapticFeedback.heavyImpact();
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        HapticFeedback.selectionClick();
      });
      
      debugPrint('HapticFeedbackService: Test feedback sequence completed');
    } catch (e) {
      debugPrint('HapticFeedbackService: Error during test feedback: $e');
    }
  }
  
  /// Get haptic feedback status information
  static String getStatusReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Haptic Feedback Service Status ===');
    buffer.writeln('Enabled: $_isEnabled');
    buffer.writeln('Available on platform: true'); // Haptic feedback is generally available on mobile platforms
    buffer.writeln();
    
    return buffer.toString();
  }
} 