import 'package:flutter/material.dart';

/// Animation service for providing enhanced animation curves and visual feedback
/// during page transitions and navigation interactions.
class AnimationService {
  static const String _tag = 'AnimationService';
  
  /// Enhanced animation curves for natural feel
  /// 
  /// These curves provide smooth, responsive animations that feel natural
  /// and provide good visual feedback to users.
  static const Curve _pageTransitionCurve = Curves.easeInOutCubic;
  static const Curve _swipeGestureCurve = Curves.easeOutQuart;
  static const Curve _bounceBackCurve = Curves.elasticOut;
  static const Curve _quickTransitionCurve = Curves.easeInOut;
  
  /// Animation durations optimized for different interaction types
  static const Duration _pageTransitionDuration = Duration(milliseconds: 350);
  static const Duration _swipeGestureDuration = Duration(milliseconds: 300);
  static const Duration _quickTransitionDuration = Duration(milliseconds: 250);
  static const Duration _bounceBackDuration = Duration(milliseconds: 400);
  
  /// Visual feedback animation settings
  static const Duration _visualFeedbackDuration = Duration(milliseconds: 150);
  static const Curve _visualFeedbackCurve = Curves.easeOut;
  
  /// Initialize the animation service
  static void initialize() {
    debugPrint('AnimationService: Initializing animation service');
  }
  
  /// Get animation curve for page transitions
  /// 
  /// Returns a smooth curve that provides natural feel for page-to-page navigation.
  static Curve get pageTransitionCurve => _pageTransitionCurve;
  
  /// Get animation curve for swipe gestures
  /// 
  /// Returns a responsive curve that follows user finger movement naturally.
  static Curve get swipeGestureCurve => _swipeGestureCurve;
  
  /// Get animation curve for bounce-back animations (boundary conditions)
  /// 
  /// Returns an elastic curve that provides clear feedback when reaching boundaries.
  static Curve get bounceBackCurve => _bounceBackCurve;
  
  /// Get animation curve for quick transitions
  /// 
  /// Returns a fast curve for rapid navigation actions.
  static Curve get quickTransitionCurve => _quickTransitionCurve;
  
  /// Get duration for page transitions
  /// 
  /// Returns a duration that balances smoothness with responsiveness.
  static Duration get pageTransitionDuration => _pageTransitionDuration;
  
  /// Get duration for swipe gestures
  /// 
  /// Returns a duration optimized for gesture-based navigation.
  static Duration get swipeGestureDuration => _swipeGestureDuration;
  
  /// Get duration for quick transitions
  /// 
  /// Returns a shorter duration for rapid navigation actions.
  static Duration get quickTransitionDuration => _quickTransitionDuration;
  
  /// Get duration for bounce-back animations
  /// 
  /// Returns a longer duration for boundary feedback animations.
  static Duration get bounceBackDuration => _bounceBackDuration;
  
  /// Get duration for visual feedback animations
  /// 
  /// Returns a short duration for subtle visual feedback.
  static Duration get visualFeedbackDuration => _visualFeedbackDuration;
  
  /// Get curve for visual feedback animations
  /// 
  /// Returns a curve optimized for quick visual feedback.
  static Curve get visualFeedbackCurve => _visualFeedbackCurve;
  
  /// Create an animation controller for page transitions
  /// 
  /// [vsync] - The TickerProvider for the animation
  /// [duration] - Optional custom duration (defaults to page transition duration)
  /// 
  /// Returns an AnimationController configured for page transitions.
  static AnimationController createPageTransitionController(
    TickerProvider vsync, {
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? _pageTransitionDuration,
      vsync: vsync,
    );
  }
  
  /// Create an animation controller for swipe gestures
  /// 
  /// [vsync] - The TickerProvider for the animation
  /// [duration] - Optional custom duration (defaults to swipe gesture duration)
  /// 
  /// Returns an AnimationController configured for swipe gestures.
  static AnimationController createSwipeGestureController(
    TickerProvider vsync, {
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? _swipeGestureDuration,
      vsync: vsync,
    );
  }
  
  /// Create an animation controller for visual feedback
  /// 
  /// [vsync] - The TickerProvider for the animation
  /// [duration] - Optional custom duration (defaults to visual feedback duration)
  /// 
  /// Returns an AnimationController configured for visual feedback.
  static AnimationController createVisualFeedbackController(
    TickerProvider vsync, {
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? _visualFeedbackDuration,
      vsync: vsync,
    );
  }
  
  /// Create a curved animation for page transitions
  /// 
  /// [controller] - The animation controller
  /// [curve] - Optional custom curve (defaults to page transition curve)
  /// 
  /// Returns a CurvedAnimation configured for page transitions.
  static CurvedAnimation createPageTransitionAnimation(
    AnimationController controller, {
    Curve? curve,
  }) {
    return CurvedAnimation(
      parent: controller,
      curve: curve ?? _pageTransitionCurve,
    );
  }
  
  /// Create a curved animation for swipe gestures
  /// 
  /// [controller] - The animation controller
  /// [curve] - Optional custom curve (defaults to swipe gesture curve)
  /// 
  /// Returns a CurvedAnimation configured for swipe gestures.
  static CurvedAnimation createSwipeGestureAnimation(
    AnimationController controller, {
    Curve? curve,
  }) {
    return CurvedAnimation(
      parent: controller,
      curve: curve ?? _swipeGestureCurve,
    );
  }
  
  /// Create a curved animation for visual feedback
  /// 
  /// [controller] - The animation controller
  /// [curve] - Optional custom curve (defaults to visual feedback curve)
  /// 
  /// Returns a CurvedAnimation configured for visual feedback.
  static CurvedAnimation createVisualFeedbackAnimation(
    AnimationController controller, {
    Curve? curve,
  }) {
    return CurvedAnimation(
      parent: controller,
      curve: curve ?? _visualFeedbackCurve,
    );
  }
  
  /// Get animation configuration for different navigation scenarios
  /// 
  /// [scenario] - The navigation scenario type
  /// 
  /// Returns an AnimationConfig with appropriate duration and curve.
  static AnimationConfig getAnimationConfig(AnimationScenario scenario) {
    switch (scenario) {
      case AnimationScenario.pageTransition:
        return AnimationConfig(
          duration: _pageTransitionDuration,
          curve: _pageTransitionCurve,
        );
      case AnimationScenario.swipeGesture:
        return AnimationConfig(
          duration: _swipeGestureDuration,
          curve: _swipeGestureCurve,
        );
      case AnimationScenario.quickTransition:
        return AnimationConfig(
          duration: _quickTransitionDuration,
          curve: _quickTransitionCurve,
        );
      case AnimationScenario.bounceBack:
        return AnimationConfig(
          duration: _bounceBackDuration,
          curve: _bounceBackCurve,
        );
      case AnimationScenario.visualFeedback:
        return AnimationConfig(
          duration: _visualFeedbackDuration,
          curve: _visualFeedbackCurve,
        );
    }
  }
  
  /// Check if an animation duration meets performance requirements
  /// 
  /// [duration] - The animation duration to check
  /// 
  /// Returns true if the duration is within acceptable performance bounds.
  static bool isPerformanceAcceptable(Duration duration) {
    // Animation should be between 200-400ms for optimal performance
    return duration.inMilliseconds >= 200 && duration.inMilliseconds <= 400;
  }
  
  /// Get animation performance rating
  /// 
  /// [duration] - The animation duration to rate
  /// 
  /// Returns a performance rating from 1-5 (5 being optimal).
  static int getPerformanceRating(Duration duration) {
    final milliseconds = duration.inMilliseconds;
    
    if (milliseconds >= 200 && milliseconds <= 300) return 5; // Optimal
    if (milliseconds > 300 && milliseconds <= 350) return 4; // Good
    if (milliseconds > 350 && milliseconds <= 400) return 3; // Acceptable
    if (milliseconds > 400 && milliseconds <= 500) return 2; // Slow
    return 1; // Very slow
  }
  
  /// Get animation service status information
  static String getStatusReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Animation Service Status ===');
    buffer.writeln('Page Transition Duration: ${_pageTransitionDuration.inMilliseconds}ms');
    buffer.writeln('Swipe Gesture Duration: ${_swipeGestureDuration.inMilliseconds}ms');
    buffer.writeln('Quick Transition Duration: ${_quickTransitionDuration.inMilliseconds}ms');
    buffer.writeln('Bounce Back Duration: ${_bounceBackDuration.inMilliseconds}ms');
    buffer.writeln('Visual Feedback Duration: ${_visualFeedbackDuration.inMilliseconds}ms');
    buffer.writeln();
    
    // Performance ratings
    buffer.writeln('Performance Ratings:');
    buffer.writeln('  Page Transition: ${getPerformanceRating(_pageTransitionDuration)}/5');
    buffer.writeln('  Swipe Gesture: ${getPerformanceRating(_swipeGestureDuration)}/5');
    buffer.writeln('  Quick Transition: ${getPerformanceRating(_quickTransitionDuration)}/5');
    buffer.writeln('  Bounce Back: ${getPerformanceRating(_bounceBackDuration)}/5');
    buffer.writeln('  Visual Feedback: ${getPerformanceRating(_visualFeedbackDuration)}/5');
    
    return buffer.toString();
  }
}

/// Animation configuration data class
class AnimationConfig {
  final Duration duration;
  final Curve curve;
  
  const AnimationConfig({
    required this.duration,
    required this.curve,
  });
}

/// Animation scenario types
enum AnimationScenario {
  pageTransition,
  swipeGesture,
  quickTransition,
  bounceBack,
  visualFeedback,
} 