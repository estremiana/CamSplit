import 'package:flutter/material.dart';
import '../interfaces/navigation_interface.dart';
import 'haptic_feedback_service.dart';

/// Global navigation service for managing page transitions in the slideable navigation system.
/// 
/// This service provides static methods to control navigation between the main pages
/// (Dashboard, Groups, Profile) with smooth animations. It acts as a bridge between
/// external widgets (like the welcome button) and the MainNavigationContainer.
class NavigationService {
  /// Internal reference to the MainNavigationContainer state
  static MainNavigationContainerStateInterface? _navigationState;
  
  /// Animation duration for page transitions (300ms as specified in design)
  static const Duration _animationDuration = Duration(milliseconds: 300);
  
  /// Animation curve for smooth transitions
  static const Curve _animationCurve = Curves.easeInOut;
  
  /// Queue for pending navigation requests during animations
  static final List<_NavigationRequest> _navigationQueue = [];
  
  /// Flag to track if queue processing is in progress
  static bool _isProcessingQueue = false;
  
  /// Page indices for the main navigation pages
  static const int dashboardPageIndex = 0;
  static const int groupsPageIndex = 1;
  static const int profilePageIndex = 2;
  
  /// Initialize the navigation service
  static void initialize() {
    debugPrint('NavigationService: Initializing navigation service');
    _navigationState = null;
    _navigationQueue.clear();
    _isProcessingQueue = false;
  }
  
  /// Registers the MainNavigationContainer state with the service
  static void registerNavigationState(MainNavigationContainerStateInterface state) {
    _navigationState = state;
  }
  
  /// Unregisters the MainNavigationContainer state from the service
  static void unregisterNavigationState() {
    _navigationState = null;
  }
  
  /// Gets the animation duration for consistent timing across the app
  static Duration get animationDuration => _animationDuration;
  
  /// Gets the animation curve for consistent transitions
  static Curve get animationCurve => _animationCurve;
  
  /// Navigates to a specific page by index with optional animation
  /// 
  /// [pageIndex] - The target page index (0=Dashboard, 1=Groups, 2=Profile)
  /// [animate] - Whether to animate the transition (default: true)
  /// 
  /// Returns true if navigation was successful, false if the navigation state
  /// is not available or the page index is invalid
  static bool navigateToPage(int pageIndex, {bool animate = true}) {
    // Validate page index
    if (pageIndex < 0 || pageIndex > 2) {
      debugPrint('NavigationService: Invalid page index $pageIndex. Must be 0-2.');
      return false;
    }
    
    // Check if navigation state is available
    if (_navigationState == null) {
      debugPrint('NavigationService: Navigation state not available. MainNavigationContainer may not be initialized.');
      return false;
    }
    
    // If currently animating, queue the request for later processing
    if (_navigationState!.isAnimating) {
      debugPrint('NavigationService: Animation in progress, queuing navigation to page $pageIndex');
      _queueNavigationRequest(pageIndex, animate);
      return true;
    }
    
    try {
      _navigationState!.navigateToPage(pageIndex, animate: animate);
      
      // Process any queued requests after a delay to allow current animation to complete
      if (animate) {
        _scheduleQueueProcessing();
      }
      
      return true;
    } catch (e) {
      debugPrint('NavigationService: Error navigating to page $pageIndex: $e');
      return false;
    }
  }
  
  /// Convenience method to navigate to the Dashboard page
  /// 
  /// [animate] - Whether to animate the transition (default: true)
  /// 
  /// Returns true if navigation was successful
  static bool navigateToDashboard({bool animate = true}) {
    return navigateToPage(dashboardPageIndex, animate: animate);
  }
  
  /// Convenience method to navigate to the Groups page
  /// 
  /// [animate] - Whether to animate the transition (default: true)
  /// 
  /// Returns true if navigation was successful
  static bool navigateToGroups({bool animate = true}) {
    return navigateToPage(groupsPageIndex, animate: animate);
  }
  
  /// Convenience method to navigate to the Profile page
  /// 
  /// This method is specifically designed for the welcome button navigation
  /// as specified in requirement 3.1 and 3.2
  /// 
  /// [animate] - Whether to animate the transition (default: true)
  /// 
  /// Returns true if navigation was successful
  static bool navigateToProfile({bool animate = true}) {
    // Enhanced haptic feedback for welcome button navigation
    HapticFeedbackService.welcomeButtonNavigation();
    
    return navigateToPage(profilePageIndex, animate: animate);
  }
  
  /// Gets the current page index if available
  /// 
  /// Returns the current page index or null if navigation is not available
  static int? getCurrentPageIndex() {
    return _navigationState?.currentPageIndex;
  }
  
  /// Checks if the navigation system is available and ready
  /// 
  /// Returns true if MainNavigationContainer is initialized and ready
  static bool get isNavigationAvailable {
    return _navigationState != null;
  }
  
  /// Checks if a navigation animation is currently in progress
  /// 
  /// Returns true if an animation is in progress, false otherwise
  static bool get isAnimating {
    return _navigationState?.isAnimating ?? false;
  }
  
  /// Queues a navigation request for later processing
  /// 
  /// [pageIndex] - The target page index
  /// [animate] - Whether to animate the transition
  static void _queueNavigationRequest(int pageIndex, bool animate) {
    // Remove any existing request for the same page to avoid duplicates
    _navigationQueue.removeWhere((request) => request.pageIndex == pageIndex);
    
    // Add the new request to the queue
    _navigationQueue.add(_NavigationRequest(pageIndex, animate));
    
    debugPrint('NavigationService: Queued navigation to page $pageIndex (queue size: ${_navigationQueue.length})');
  }
  
  /// Schedules queue processing after the current animation completes
  static void _scheduleQueueProcessing() {
    if (_isProcessingQueue) return;
    
    // Schedule processing after animation duration plus a small buffer
    Future.delayed(_animationDuration + const Duration(milliseconds: 50), () {
      _processNavigationQueue();
    });
  }
  
  /// Processes queued navigation requests
  static void _processNavigationQueue() {
    if (_isProcessingQueue || _navigationQueue.isEmpty || _navigationState == null) {
      return;
    }
    
    _isProcessingQueue = true;
    
    try {
      // Process the most recent request (latest takes priority)
      final request = _navigationQueue.last;
      _navigationQueue.clear();
      
      debugPrint('NavigationService: Processing queued navigation to page ${request.pageIndex}');
      
      // Execute the navigation if not currently animating
      if (!_navigationState!.isAnimating) {
        _navigationState!.navigateToPage(request.pageIndex, animate: request.animate);
        
        // If this was an animated request, schedule another queue check
        if (request.animate) {
          _scheduleQueueProcessing();
        }
      }
    } catch (e) {
      debugPrint('NavigationService: Error processing navigation queue: $e');
    } finally {
      _isProcessingQueue = false;
    }
  }
  
  /// Clears the navigation queue (useful for testing and cleanup)
  static void clearNavigationQueue() {
    _navigationQueue.clear();
    _isProcessingQueue = false;
  }
  
  /// Gets the current queue size (useful for testing and debugging)
  static int get queueSize => _navigationQueue.length;
}

/// Internal class to represent a queued navigation request
class _NavigationRequest {
  final int pageIndex;
  final bool animate;
  
  const _NavigationRequest(this.pageIndex, this.animate);
  
  @override
  String toString() => '_NavigationRequest(pageIndex: $pageIndex, animate: $animate)';
}

