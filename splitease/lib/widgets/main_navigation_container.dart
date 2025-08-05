import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';

import '../models/page_configuration.dart';
import '../models/navigation_page_configurations.dart';
import '../services/navigation_service.dart';
import '../services/performance_monitor.dart';
import '../services/haptic_feedback_service.dart';
import '../services/animation_service.dart';
import '../services/performance_optimizer.dart';
import '../services/accessibility_service.dart';
import '../interfaces/navigation_interface.dart';
import 'enhanced_bottom_navigation.dart';

/// Custom scroll direction enum for gesture boundary detection
enum _ScrollDirection {
  forward,  // Scrolling down/right
  reverse,  // Scrolling up/left
}

/// Main navigation container that provides slideable navigation between the three main pages
/// using PageView. This widget implements the MainNavigationContainerState interface
/// required by the NavigationService.
/// 
/// Accessibility Features:
/// - Semantic labels for screen readers
/// - Keyboard navigation support
/// - Focus management during page transitions
/// - Gesture alternatives for users with motor impairments
class MainNavigationContainer extends StatefulWidget {
  /// Initial page index (0=Dashboard, 1=Groups, 2=Profile)
  final int initialPage;
  
  const MainNavigationContainer({
    Key? key, 
    this.initialPage = 0,
  }) : super(key: key);

  @override
  State<MainNavigationContainer> createState() => MainNavigationContainerState();
}

/// State class that implements the interface required by NavigationService
class MainNavigationContainerState extends State<MainNavigationContainer>
    implements MainNavigationContainerStateInterface {
  
  // Animation configuration using enhanced animation service
  late final AnimationConfig _pageTransitionConfig;
  late final AnimationConfig _swipeGestureConfig;
  
  // PageView controller for managing page transitions
  late PageController _pageController;
  
  // Navigation state management using the new NavigationState model
  late NavigationState _navigationState;
  
  // Performance optimization: Cache for initialized page widgets
  final Map<int, Widget> _pageWidgetCache = {};
  
  // Performance optimization: Track viewport metrics for optimization
  double _viewportHeight = 0.0;
  bool _isViewportInitialized = false;
  
  // Gesture boundary detection state
  bool _isInternalScrolling = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  _ScrollDirection? _lastScrollDirection;

  // Accessibility: Focus management for keyboard navigation
  final FocusNode _pageViewFocusNode = FocusNode();
  final List<FocusNode> _pageFocusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];

  // Accessibility: Keyboard navigation state
  bool _isKeyboardNavigationMode = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation configurations
    _pageTransitionConfig = AnimationService.getAnimationConfig(AnimationScenario.pageTransition);
    _swipeGestureConfig = AnimationService.getAnimationConfig(AnimationScenario.swipeGesture);
    
    // Initialize navigation state using the NavigationState model
    _navigationState = NavigationState.initial(
      initialPageIndex: widget.initialPage,
      totalPages: NavigationPageConfigurations.totalPages,
    );
    
    // Initialize PageController with optimized configuration for performance
    _pageController = PageController(
      initialPage: _navigationState.currentPageIndex,
      keepPage: true, // Preserve page state
      viewportFraction: 1.0, // Optimize viewport for single page display
    );
    
    // Performance optimization: Pre-cache the initial page widget
    _precacheInitialPage();
    
    // Start performance monitoring
    PerformanceMonitor.startMonitoring();
    
    // Initialize performance optimizer
    PerformanceOptimizer.initialize();
    
    // Register this state with NavigationService
    NavigationService.registerNavigationState(this);

    // Accessibility: Set up focus listeners for keyboard navigation
    _setupFocusManagement();
  }

  @override
  void dispose() {
    // Clear any pending navigation requests to prevent memory leaks
    NavigationService.clearNavigationQueue();
    
    // Stop performance monitoring and cleanup
    PerformanceMonitor.stopMonitoring();
    PerformanceOptimizer.dispose();
    
    // Unregister from NavigationService
    NavigationService.unregisterNavigationState();
    
    // Performance optimization: Clear page widget cache to free memory
    _pageWidgetCache.clear();
    
    // Stop performance monitoring
    PerformanceMonitor.stopMonitoring();
    
    // Dispose PageController
    _pageController.dispose();

    // Accessibility: Dispose focus nodes
    _pageViewFocusNode.dispose();
    for (final focusNode in _pageFocusNodes) {
      focusNode.dispose();
    }
    
    super.dispose();
  }

  /// Set up focus management for accessibility and keyboard navigation
  void _setupFocusManagement() {
    // Listen for keyboard navigation mode changes
    _pageViewFocusNode.addListener(() {
      _isKeyboardNavigationMode = _pageViewFocusNode.hasFocus;
      if (_isKeyboardNavigationMode) {
        // Announce current page to screen readers when keyboard navigation is activated
        AccessibilityService.announceKeyboardNavigationMode();
        AccessibilityService.announcePageNavigation(_getCurrentPageName(), isCurrentPage: true);
      }
    });

    // Set up focus listeners for each page
    for (int i = 0; i < _pageFocusNodes.length; i++) {
      _pageFocusNodes[i].addListener(() {
        if (_pageFocusNodes[i].hasFocus) {
          // Announce page focus to screen readers
          AccessibilityService.announceFocusChange('${_getPageName(i)} page');
        }
      });
    }
  }

  /// Get the name of the current page for accessibility announcements
  String _getCurrentPageName() {
    return _getPageName(_navigationState.currentPageIndex);
  }

  /// Get the name of a page by index for accessibility announcements
  String _getPageName(int pageIndex) {
    switch (pageIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Groups';
      case 2:
        return 'Profile';
      default:
        return 'Unknown';
    }
  }

  /// Handle keyboard navigation for accessibility
  void _handleKeyboardNavigation(RawKeyEvent event) {
    final bool handled = AccessibilityService.handleKeyboardNavigation(
      event,
      _navigationState.currentPageIndex,
      NavigationPageConfigurations.totalPages,
      (pageIndex) {
        navigateToPage(pageIndex, animate: true);
        AccessibilityService.announcePageNavigation(_getPageName(pageIndex));
      },
    );

    if (!handled) {
      // Handle additional keyboard shortcuts if needed
      if (event is RawKeyDownEvent) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.keyH:
            // Help shortcut - announce accessibility instructions
            AccessibilityService.announceNavigation(
              AccessibilityService.getAccessibilityInstructions(),
            );
            break;
        }
      }
    }
  }

  /// Handle page changes from PageView (swipe gestures)
  void _onPageChanged(int pageIndex) {
    // Validate page index using NavigationPageConfigurations
    if (!NavigationPageConfigurations.isValidPageIndex(pageIndex)) {
      debugPrint('MainNavigationContainer: Invalid page index $pageIndex');
      return;
    }
    
    // Update navigation state
    setState(() {
      _navigationState = _navigationState.navigateToPage(pageIndex);
    });
    
    // Performance optimization: Preload adjacent pages for smoother future transitions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAdjacentPages();
    });
    
    // Enhanced haptic feedback for swipe gestures
    HapticFeedbackService.swipeGesture();
    
    debugPrint('MainNavigationContainer: Page changed to $pageIndex');
  }

  /// Navigate to a specific page programmatically
  /// This method implements the interface required by NavigationService
  @override
  void navigateToPage(int pageIndex, {bool animate = true}) {
    // Validate page index using NavigationPageConfigurations
    if (!NavigationPageConfigurations.isValidPageIndex(pageIndex)) {
      debugPrint('MainNavigationContainer: Invalid page index $pageIndex. Must be 0-${NavigationPageConfigurations.totalPages - 1}.');
      return;
    }
    
    // Check if already on the target page and not animating
    if (_navigationState.currentPageIndex == pageIndex && !_navigationState.isAnimating) {
      debugPrint('MainNavigationContainer: Already on page $pageIndex');
      return;
    }
    
    // Performance optimization: If animation is in progress, let NavigationService handle queuing
    if (_navigationState.isAnimating) {
      debugPrint('MainNavigationContainer: Animation in progress, request will be handled by NavigationService queue');
      return;
    }
    
    // Performance monitoring: Record navigation start time
    final navigationStartTime = DateTime.now();
    
    try {
      if (animate) {
        // Set animation state with optimized state update
        if (mounted) {
          setState(() {
            _navigationState = _navigationState.setAnimating(true);
          });
        }
        
        // Animate to page with enhanced animation configuration
        // Use optimized duration and curve for better user experience
        final animationFuture = _pageController.animateToPage(
          pageIndex,
          duration: _pageTransitionConfig.duration,
          curve: _pageTransitionConfig.curve,
        );
        
        // Handle animation completion with optimized state management and performance monitoring
        animationFuture.then((_) {
          if (mounted) {
            setState(() {
              _navigationState = _navigationState.setAnimating(false);
            });
            
            // Performance monitoring: Record animation duration
            final animationDuration = DateTime.now().difference(navigationStartTime);
            PerformanceMonitor.recordAnimationDuration('page_transition', animationDuration);
            
            // Performance optimization: Record animation duration for optimization
            PerformanceOptimizer.recordAnimationDuration(animationDuration.inMilliseconds);
            
            // Enhanced haptic feedback for animation completion
            HapticFeedbackService.animationComplete();
          }
        }).catchError((error) {
          // Enhanced error handling with recovery
          debugPrint('MainNavigationContainer: Animation error: $error');
          if (mounted) {
            setState(() {
              _navigationState = _navigationState.setAnimating(false);
            });
            
            // Attempt recovery by jumping to the target page
            try {
              _pageController.jumpToPage(pageIndex);
            } catch (recoveryError) {
              debugPrint('MainNavigationContainer: Recovery error: $recoveryError');
            }
          }
        });
      } else {
        // Jump to page without animation - more efficient for non-animated transitions
        _pageController.jumpToPage(pageIndex);
        
        // Performance monitoring: Record instant navigation latency
        final navigationLatency = DateTime.now().difference(navigationStartTime);
        PerformanceMonitor.recordNavigationLatency(navigationLatency);
      }
      
      debugPrint('MainNavigationContainer: Navigating to page $pageIndex (animate: $animate)');
    } catch (e) {
      debugPrint('MainNavigationContainer: Error navigating to page $pageIndex: $e');
      if (mounted) {
        setState(() {
          _navigationState = _navigationState.setAnimating(false);
        });
      }
    }
  }

  /// Get current page index (required by NavigationService interface)
  @override
  int get currentPageIndex => _navigationState.currentPageIndex;
  
  /// Get animation state (required by NavigationService interface)
  @override
  bool get isAnimating => _navigationState.isAnimating;

  // Public getters for testing
  NavigationState get navigationState => _navigationState;
  bool get internalScrolling => _isInternalScrolling;
  bool get canScrollLeft => _canScrollLeft;
  bool get canScrollRight => _canScrollRight;
  
  /// Performance optimization: Pre-cache the initial page widget to improve startup time
  void _precacheInitialPage() {
    final initialPageConfig = NavigationPageConfigurations.allPages[_navigationState.currentPageIndex];
    _pageWidgetCache[_navigationState.currentPageIndex] = initialPageConfig.page;
  }
  
  /// Performance optimization: Lazy load and cache page widgets
  /// This method ensures pages are only created when needed and cached for reuse
  Widget _getOrCreatePageWidget(int pageIndex) {
    // Return cached widget if available
    if (_pageWidgetCache.containsKey(pageIndex)) {
      return _pageWidgetCache[pageIndex]!;
    }
    
    // Create and cache the widget
    final pageConfiguration = NavigationPageConfigurations.allPages[pageIndex];
    final pageWidget = pageConfiguration.page;
    _pageWidgetCache[pageIndex] = pageWidget;
    
    debugPrint('MainNavigationContainer: Created and cached page widget for index $pageIndex');
    return pageWidget;
  }
  
  /// Performance optimization: Preload adjacent pages for smoother transitions
  void _preloadAdjacentPages() {
    final currentIndex = _navigationState.currentPageIndex;
    
    // Preload previous page if exists
    if (currentIndex > 0) {
      _getOrCreatePageWidget(currentIndex - 1);
    }
    
    // Preload next page if exists
    if (currentIndex < NavigationPageConfigurations.totalPages - 1) {
      _getOrCreatePageWidget(currentIndex + 1);
    }
  }
  
  /// Performance optimization: Initialize viewport metrics for better rendering
  void _initializeViewportMetrics(BuildContext context) {
    if (!_isViewportInitialized) {
      _viewportHeight = MediaQuery.of(context).size.height;
      _isViewportInitialized = true;
      
      // Schedule adjacent page preloading after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preloadAdjacentPages();
      });
    }
  }

  /// Handle scroll notifications from child widgets to detect scroll boundaries
  /// and prevent gesture conflicts as specified in requirements 1.5, 1.6, 5.4
  bool _handleScrollNotification(ScrollNotification notification) {
    // Only handle notifications from direct child scrollables, not nested ones
    if (notification.depth > 0) {
      return false;
    }

    final ScrollMetrics metrics = notification.metrics;
    final bool atLeftEdge = metrics.pixels <= metrics.minScrollExtent;
    final bool atRightEdge = metrics.pixels >= metrics.maxScrollExtent;
    
    // Determine scroll direction
    _ScrollDirection? currentDirection;
    if (notification is ScrollUpdateNotification) {
      final double delta = notification.scrollDelta ?? 0.0;
      if (delta > 0) {
        currentDirection = _ScrollDirection.forward; // Scrolling down/right
      } else if (delta < 0) {
        currentDirection = _ScrollDirection.reverse; // Scrolling up/left
      }
    }

    // Check if state actually changed to avoid unnecessary setState calls
    final bool wasInternalScrolling = _isInternalScrolling;
    final bool wasCanScrollLeft = _canScrollLeft;
    final bool wasCanScrollRight = _canScrollRight;
    final _ScrollDirection? wasLastScrollDirection = _lastScrollDirection;

    final bool newIsInternalScrolling = notification is ScrollStartNotification ||
        (notification is ScrollUpdateNotification && 
         notification.scrollDelta != null && 
         notification.scrollDelta!.abs() > 0);
    
    final bool newCanScrollLeft = !atLeftEdge;
    final bool newCanScrollRight = !atRightEdge;

    // Only update state if there are actual changes
    if (wasInternalScrolling != newIsInternalScrolling ||
        wasCanScrollLeft != newCanScrollLeft ||
        wasCanScrollRight != newCanScrollRight ||
        wasLastScrollDirection != currentDirection) {
      
      setState(() {
        _isInternalScrolling = newIsInternalScrolling;
        _canScrollLeft = newCanScrollLeft;
        _canScrollRight = newCanScrollRight;
        _lastScrollDirection = currentDirection;
      });

      // Only log significant state changes, not every scroll update
      if (notification is ScrollStartNotification || notification is ScrollEndNotification) {
        debugPrint('MainNavigationContainer: Scroll state changed - '
            'isInternalScrolling: $_isInternalScrolling, '
            'canScrollLeft: $_canScrollLeft, '
            'canScrollRight: $_canScrollRight');
      }
    }

    // Handle scroll end to reset internal scrolling state
    if (notification is ScrollEndNotification) {
      if (_isInternalScrolling) {
        setState(() {
          _isInternalScrolling = false;
          _lastScrollDirection = null;
        });
      }
    }

    return false; // Allow notification to continue bubbling
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: RawKeyboardListener(
          focusNode: _pageViewFocusNode,
          onKey: _handleKeyboardNavigation,
          child: _buildPageViewWithGestureHandling(),
        ),
      ),
      // Add the enhanced bottom navigation bar
      bottomNavigationBar: EnhancedBottomNavigation(
        currentPageIndex: _navigationState.currentPageIndex,
        isAnimating: _navigationState.isAnimating,
        onPageSelected: (index) {
          // Use the existing navigateToPage method for consistency
          navigateToPage(index, animate: true);
        },
      ),
    );
  }

  /// Builds PageView with custom gesture handling for boundary detection
  /// and conflict resolution as specified in requirements 1.5, 1.6, 5.4
  /// 
  /// Accessibility Features:
  /// - Semantic labels for screen readers
  /// - Keyboard navigation support
  /// - Focus management during page transitions
  Widget _buildPageViewWithGestureHandling() {
    return Semantics(
      label: 'Main navigation container with ${NavigationPageConfigurations.totalPages} pages',
      hint: 'Swipe left or right to navigate between pages, or use arrow keys for keyboard navigation',
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            () => PanGestureRecognizer(),
            (PanGestureRecognizer instance) {
              instance
                ..onStart = _handlePanStart
                ..onUpdate = _handlePanUpdate
                ..onEnd = _handlePanEnd;
            },
          ),
        },
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          // Always allow PageView physics to ensure proper page change callbacks
          physics: const ClampingScrollPhysics(),
          // Ensure pages snap to position as specified in requirements
          pageSnapping: true,
          // Allow page swiping as specified in requirements 1.1-1.6
          allowImplicitScrolling: false,
          // Performance optimization: Use builder for lazy loading
          itemCount: NavigationPageConfigurations.totalPages,
          // Performance optimization: Optimize viewport for better rendering
          padEnds: false,
          // Performance optimization: Use efficient item builder
          itemBuilder: (context, index) {
            final pageConfiguration = NavigationPageConfigurations.allPages[index];
            return _buildPageWrapper(
              pageIndex: index,
              pageConfiguration: pageConfiguration,
            );
          },
        ),
      ),
    );
  }

  /// Handle pan gesture start for custom gesture priority handling
  void _handlePanStart(DragStartDetails details) {
    // Reset gesture state for clean gesture handling
    setState(() {
      _isInternalScrolling = false;
    });
  }

  /// Handle pan gesture updates with boundary detection
  void _handlePanUpdate(DragUpdateDetails details) {
    final double deltaX = details.delta.dx;
    final bool isFirstPage = _navigationState.isFirstPage;
    final bool isLastPage = _navigationState.isLastPage;
    
    // Only provide haptic feedback for edge cases, let PageView handle the rest
    if (isFirstPage && deltaX > 0) {
      // On first page, provide haptic feedback for right swipe attempt
      HapticFeedbackService.boundaryReached();
    } else if (isLastPage && deltaX < 0) {
      // On last page, provide haptic feedback for left swipe attempt
      HapticFeedbackService.boundaryReached();
    }
  }

  /// Handle pan gesture end with enhanced haptic feedback
  void _handlePanEnd(DragEndDetails details) {
    // Enhanced haptic feedback for swipe gestures with sufficient velocity
    if (details.velocity.pixelsPerSecond.dx.abs() > 100) {
      HapticFeedbackService.swipeGesture();
    }
  }

  /// Wrapper for pages to handle state preservation and proper key management
  /// 
  /// This method ensures that each page has the proper PageStorageKey for state
  /// preservation as specified in requirements 6.1, 6.2, and 6.3.
  /// 
  /// Accessibility Features:
  /// - Semantic labels for each page
  /// - Focus management for keyboard navigation
  /// - Screen reader announcements for page content
  Widget _buildPageWrapper({
    required int pageIndex,
    required PageConfiguration pageConfiguration,
  }) {
    // Initialize the page when it's first accessed (lazy loading optimization)
    if (!_navigationState.isPageInitialized(pageIndex)) {
      // Mark page as initialized when it's about to be built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _navigationState = _navigationState.copyWith(
              pageInitialized: List<bool>.from(_navigationState.pageInitialized)
                ..[pageIndex] = true,
            );
          });
        }
      });
    }
    
    // Return the actual page widget with proper key for state preservation
    // The PageStorageKey ensures that scroll positions and form data are preserved
    // when navigating between pages as specified in requirements 6.1-6.3
    return Semantics(
      label: '${pageConfiguration.title} page',
      hint: 'Page ${pageIndex + 1} of ${NavigationPageConfigurations.totalPages}',
      child: Focus(
        focusNode: _pageFocusNodes[pageIndex],
        child: Container(
          key: PageStorageKey(pageConfiguration.pageKey),
          child: pageConfiguration.page,
        ),
      ),
    );
  }
}

