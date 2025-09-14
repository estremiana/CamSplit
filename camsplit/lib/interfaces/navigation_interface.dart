/// Interface that MainNavigationContainerState must implement
/// This is required by NavigationService to interact with the container
abstract class MainNavigationContainerStateInterface {
  /// Current page index (0=Dashboard, 1=Groups, 2=Profile)
  int get currentPageIndex;
  
  /// Whether a navigation animation is currently in progress
  bool get isAnimating;
  
  /// Navigate to a specific page with optional animation
  void navigateToPage(int pageIndex, {bool animate = true});
}