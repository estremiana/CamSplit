import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:splitease/services/navigation_service.dart';
import 'package:splitease/interfaces/navigation_interface.dart';

/// Test version of MainNavigationContainer that uses simple mock widgets
/// instead of the complex page widgets that require Sizer initialization
class TestMainNavigationContainer extends StatefulWidget {
  final int initialPage;
  
  const TestMainNavigationContainer({
    Key? key, 
    this.initialPage = 0,
  }) : super(key: key);

  @override
  State<TestMainNavigationContainer> createState() => _TestMainNavigationContainerState();
}

class _TestMainNavigationContainerState extends State<TestMainNavigationContainer>
    implements MainNavigationContainerStateInterface {
  
  // Animation constants as specified in requirements (300ms, Curves.easeInOut)
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Curve _animationCurve = Curves.easeInOut;
  
  // PageView controller for managing page transitions
  late PageController _pageController;
  
  // Current page tracking
  int _currentPageIndex = 0;
  
  // Animation state tracking to prevent conflicts
  bool _isAnimating = false;
  
  // Page initialization tracking
  final List<bool> _pageInitialized = [false, false, false];

  @override
  void initState() {
    super.initState();
    
    // Initialize PageController with proper configuration
    _currentPageIndex = widget.initialPage.clamp(0, 2);
    _pageController = PageController(
      initialPage: _currentPageIndex,
      keepPage: true, // Preserve page state
    );
    
    // Mark initial page as initialized
    _pageInitialized[_currentPageIndex] = true;
    
    // Register this state with NavigationService
    NavigationService.registerNavigationState(this);
  }

  @override
  void dispose() {
    // Unregister from NavigationService
    NavigationService.unregisterNavigationState();
    
    // Dispose PageController
    _pageController.dispose();
    
    super.dispose();
  }

  /// Handle page changes from PageView (swipe gestures)
  void _onPageChanged(int pageIndex) {
    // Validate page index
    if (pageIndex < 0 || pageIndex > 2) {
      debugPrint('TestMainNavigationContainer: Invalid page index $pageIndex');
      return;
    }
    
    // Update current page index
    setState(() {
      _currentPageIndex = pageIndex;
      _pageInitialized[pageIndex] = true;
    });
    
    // Add haptic feedback for page changes as specified in requirements
    HapticFeedback.selectionClick();
    
    debugPrint('TestMainNavigationContainer: Page changed to $pageIndex');
  }

  /// Navigate to a specific page programmatically
  /// This method implements the interface required by NavigationService
  @override
  void navigateToPage(int pageIndex, {bool animate = true}) {
    // Validate page index
    if (pageIndex < 0 || pageIndex > 2) {
      debugPrint('TestMainNavigationContainer: Invalid page index $pageIndex. Must be 0-2.');
      return;
    }
    
    // Check if already on the target page
    if (_currentPageIndex == pageIndex && !_isAnimating) {
      debugPrint('TestMainNavigationContainer: Already on page $pageIndex');
      return;
    }
    
    // Check if animation is in progress
    if (_isAnimating) {
      debugPrint('TestMainNavigationContainer: Animation in progress, queuing navigation to page $pageIndex');
      // TODO: Implement animation queuing in future iterations
      return;
    }
    
    try {
      if (animate) {
        // Set animation state
        setState(() {
          _isAnimating = true;
        });
        
        // Animate to page with specified duration and curve
        _pageController.animateToPage(
          pageIndex,
          duration: _animationDuration,
          curve: _animationCurve,
        ).then((_) {
          // Clear animation state when complete
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        }).catchError((error) {
          // Handle animation errors
          debugPrint('TestMainNavigationContainer: Animation error: $error');
          if (mounted) {
            setState(() {
              _isAnimating = false;
            });
          }
        });
      } else {
        // Jump to page without animation
        _pageController.jumpToPage(pageIndex);
      }
      
      debugPrint('TestMainNavigationContainer: Navigating to page $pageIndex (animate: $animate)');
    } catch (e) {
      debugPrint('TestMainNavigationContainer: Error navigating to page $pageIndex: $e');
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    }
  }

  /// Get current page index (required by NavigationService interface)
  @override
  int get currentPageIndex => _currentPageIndex;
  
  /// Get animation state (required by NavigationService interface)
  @override
  bool get isAnimating => _isAnimating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        // Configure PageView physics for smooth scrolling
        physics: const ClampingScrollPhysics(),
        // Ensure pages snap to position
        pageSnapping: true,
        children: [
          // Dashboard page (index 0)
          _buildPageWrapper(
            pageIndex: 0,
            child: const MockDashboard(),
          ),
          
          // Groups page (index 1)
          _buildPageWrapper(
            pageIndex: 1,
            child: const MockGroups(),
          ),
          
          // Profile page (index 2)
          _buildPageWrapper(
            pageIndex: 2,
            child: const MockProfile(),
          ),
        ],
      ),
    );
  }

  /// Wrapper for pages to handle lazy loading and state preservation
  Widget _buildPageWrapper({
    required int pageIndex,
    required Widget child,
  }) {
    // Only build the page if it has been initialized (lazy loading)
    if (!_pageInitialized[pageIndex]) {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Return the actual page widget
    return child;
  }
}

// Mock page widgets for testing
class MockDashboard extends StatelessWidget {
  const MockDashboard({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Dashboard')));
}

class MockGroups extends StatelessWidget {
  const MockGroups({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Groups')));
}

class MockProfile extends StatelessWidget {
  const MockProfile({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Profile')));
}