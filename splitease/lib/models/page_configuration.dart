import 'package:flutter/material.dart';

/// Configuration model for defining navigation pages in the slideable navigation system.
/// 
/// This model encapsulates all the necessary information for each page including
/// display properties, icons, and the actual page widget. It supports the
/// requirements for proper icon display and page management.
class PageConfiguration {
  /// Display title for the page
  final String title;
  
  /// Icon to display when the page is active/selected
  final IconData activeIcon;
  
  /// Icon to display when the page is inactive/unselected
  final IconData inactiveIcon;
  
  /// The actual page widget to display
  final Widget page;
  
  /// Unique identifier for the page (used for state preservation)
  final String pageKey;
  
  /// Whether this page should be kept alive when not visible
  final bool keepAlive;
  
  /// Creates a new page configuration
  /// 
  /// [title] - Display name for the page
  /// [activeIcon] - Icon shown when page is selected
  /// [inactiveIcon] - Icon shown when page is not selected
  /// [page] - The widget to display for this page
  /// [pageKey] - Unique identifier for state preservation
  /// [keepAlive] - Whether to preserve page state when not visible (default: true)
  const PageConfiguration({
    required this.title,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.page,
    required this.pageKey,
    this.keepAlive = true,
  });
  
  /// Creates a copy of this configuration with optional parameter overrides
  PageConfiguration copyWith({
    String? title,
    IconData? activeIcon,
    IconData? inactiveIcon,
    Widget? page,
    String? pageKey,
    bool? keepAlive,
  }) {
    return PageConfiguration(
      title: title ?? this.title,
      activeIcon: activeIcon ?? this.activeIcon,
      inactiveIcon: inactiveIcon ?? this.inactiveIcon,
      page: page ?? this.page,
      pageKey: pageKey ?? this.pageKey,
      keepAlive: keepAlive ?? this.keepAlive,
    );
  }
  
  /// Returns the appropriate icon based on whether the page is active
  /// 
  /// [isActive] - Whether the page is currently selected
  /// 
  /// Returns [activeIcon] if active, [inactiveIcon] otherwise
  IconData getIcon(bool isActive) {
    return isActive ? activeIcon : inactiveIcon;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PageConfiguration &&
        other.title == title &&
        other.activeIcon == activeIcon &&
        other.inactiveIcon == inactiveIcon &&
        other.pageKey == pageKey &&
        other.keepAlive == keepAlive;
  }
  
  @override
  int get hashCode {
    return title.hashCode ^
        activeIcon.hashCode ^
        inactiveIcon.hashCode ^
        pageKey.hashCode ^
        keepAlive.hashCode;
  }
  
  @override
  String toString() {
    return 'PageConfiguration(title: $title, pageKey: $pageKey, keepAlive: $keepAlive)';
  }
}

/// Navigation state model for tracking the current state of the slideable navigation system.
/// 
/// This model encapsulates the navigation state including current page, animation status,
/// and page initialization tracking as specified in requirements 2.4, 2.5, and 5.4.
class NavigationState {
  /// Current page index (0=Dashboard, 1=Groups, 2=Profile)
  final int currentPageIndex;
  
  /// Whether a navigation animation is currently in progress
  final bool isAnimating;
  
  /// Tracks which pages have been initialized (for lazy loading)
  final List<bool> pageInitialized;
  
  /// Total number of pages in the navigation system
  final int totalPages;
  
  /// Creates a new navigation state
  /// 
  /// [currentPageIndex] - The currently active page index
  /// [isAnimating] - Whether an animation is in progress
  /// [pageInitialized] - List tracking which pages have been initialized
  /// [totalPages] - Total number of pages (default: 3 for Dashboard, Groups, Profile)
  const NavigationState({
    required this.currentPageIndex,
    required this.isAnimating,
    required this.pageInitialized,
    this.totalPages = 3,
  });
  
  /// Creates the initial navigation state
  /// 
  /// [initialPageIndex] - The page to start on (default: 0 for Dashboard)
  /// [totalPages] - Total number of pages (default: 3)
  factory NavigationState.initial({
    int initialPageIndex = 0,
    int totalPages = 3,
  }) {
    // Validate initial page index
    final validatedIndex = initialPageIndex.clamp(0, totalPages - 1);
    
    // Create page initialization list with only the initial page marked as initialized
    final pageInitialized = List.generate(
      totalPages,
      (index) => index == validatedIndex,
    );
    
    return NavigationState(
      currentPageIndex: validatedIndex,
      isAnimating: false,
      pageInitialized: pageInitialized,
      totalPages: totalPages,
    );
  }
  
  /// Creates a copy of this state with optional parameter overrides
  NavigationState copyWith({
    int? currentPageIndex,
    bool? isAnimating,
    List<bool>? pageInitialized,
    int? totalPages,
  }) {
    return NavigationState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isAnimating: isAnimating ?? this.isAnimating,
      pageInitialized: pageInitialized ?? List<bool>.from(this.pageInitialized),
      totalPages: totalPages ?? this.totalPages,
    );
  }
  
  /// Updates the current page index and marks the page as initialized
  /// 
  /// [pageIndex] - The new page index to navigate to
  /// 
  /// Returns a new NavigationState with updated values
  NavigationState navigateToPage(int pageIndex) {
    // Validate page index
    final validatedIndex = pageIndex.clamp(0, totalPages - 1);
    
    // Create updated page initialization list
    final updatedPageInitialized = List<bool>.from(pageInitialized);
    updatedPageInitialized[validatedIndex] = true;
    
    return copyWith(
      currentPageIndex: validatedIndex,
      pageInitialized: updatedPageInitialized,
    );
  }
  
  /// Sets the animation state
  /// 
  /// [animating] - Whether an animation is in progress
  /// 
  /// Returns a new NavigationState with updated animation state
  NavigationState setAnimating(bool animating) {
    return copyWith(isAnimating: animating);
  }
  
  /// Checks if a specific page has been initialized
  /// 
  /// [pageIndex] - The page index to check
  /// 
  /// Returns true if the page has been initialized, false otherwise
  bool isPageInitialized(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pageInitialized.length) {
      return false;
    }
    return pageInitialized[pageIndex];
  }
  
  /// Checks if the current page is the first page
  bool get isFirstPage => currentPageIndex == 0;
  
  /// Checks if the current page is the last page
  bool get isLastPage => currentPageIndex == totalPages - 1;
  
  /// Checks if navigation to the left is possible
  bool get canNavigateLeft => !isFirstPage;
  
  /// Checks if navigation to the right is possible
  bool get canNavigateRight => !isLastPage;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NavigationState &&
        other.currentPageIndex == currentPageIndex &&
        other.isAnimating == isAnimating &&
        other.totalPages == totalPages &&
        _listEquals(other.pageInitialized, pageInitialized);
  }
  
  @override
  int get hashCode {
    return currentPageIndex.hashCode ^
        isAnimating.hashCode ^
        totalPages.hashCode ^
        pageInitialized.hashCode;
  }
  
  @override
  String toString() {
    return 'NavigationState(currentPageIndex: $currentPageIndex, isAnimating: $isAnimating, '
        'pageInitialized: $pageInitialized, totalPages: $totalPages)';
  }
  
  /// Helper method to compare two lists for equality
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}