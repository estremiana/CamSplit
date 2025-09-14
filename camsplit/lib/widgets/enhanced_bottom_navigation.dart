import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

import '../core/app_export.dart';
import '../models/navigation_page_configurations.dart';
import '../services/navigation_service.dart';
import '../services/haptic_feedback_service.dart';
import '../services/accessibility_service.dart';

/// Enhanced bottom navigation bar component that synchronizes with the PageView
/// in MainNavigationContainer and provides smooth navigation between pages.
/// 
/// This component addresses the requirements for:
/// - Synchronization with PageView current page (Requirements 2.4, 2.5)
/// - Tap handlers that trigger PageController.animateToPage() (Requirements 2.1, 2.2, 2.3)
/// - Proper icon state management (Requirements 4.1, 4.2, 4.3, 4.4)
/// - Fixed icon loading without placeholders (Requirement 4.5)
/// 
/// Accessibility Features:
/// - Semantic labels for screen readers
/// - Keyboard navigation support
/// - Focus management for navigation items
/// - Screen reader announcements for navigation actions
class EnhancedBottomNavigation extends StatelessWidget {
  /// Current page index (0=Dashboard, 1=Groups, 2=Profile)
  final int currentPageIndex;
  
  /// Callback function called when a navigation item is tapped
  /// 
  /// This callback should trigger the PageController.animateToPage() method
  /// in the MainNavigationContainer to ensure smooth sliding transitions.
  final Function(int index) onPageSelected;
  
  /// Whether navigation animations are currently in progress
  /// 
  /// When true, tap interactions may be disabled to prevent conflicts
  final bool isAnimating;
  
  /// Creates an enhanced bottom navigation bar
  /// 
  /// [currentPageIndex] - The currently active page index
  /// [onPageSelected] - Callback for when a navigation item is tapped
  /// [isAnimating] - Whether navigation animations are in progress
  const EnhancedBottomNavigation({
    Key? key,
    required this.currentPageIndex,
    required this.onPageSelected,
    this.isAnimating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Bottom navigation bar',
      hint: 'Navigate between Dashboard, Groups, and Profile pages',
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardLight,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowLight,
              blurRadius: 8.0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: currentPageIndex,
            onTap: _handleNavigationTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.cardLight,
            selectedItemColor: AppTheme.primaryLight,
            unselectedItemColor: AppTheme.textSecondaryLight,
            elevation: 0, // We handle elevation with container shadow
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: _buildNavigationItems(),
          ),
        ),
      ),
    );
  }

  /// Builds the navigation items from the page configurations
  /// 
  /// This method creates BottomNavigationBarItem widgets for each page
  /// configuration, ensuring proper icon display and state management.
  List<BottomNavigationBarItem> _buildNavigationItems() {
    return NavigationPageConfigurations.allPages
        .asMap()
        .entries
        .map((entry) => _buildNavigationItem(
              pageIndex: entry.key,
              configuration: entry.value,
            ))
        .toList();
  }

  /// Builds a single navigation item for the specified page
  /// 
  /// [pageIndex] - The index of the page (0=Dashboard, 1=Groups, 2=Profile)
  /// [configuration] - The page configuration containing icons and title
  /// 
  /// Returns a BottomNavigationBarItem with proper icon state management
  /// and accessibility features
  BottomNavigationBarItem _buildNavigationItem({
    required int pageIndex,
    required configuration,
  }) {
    final bool isActive = pageIndex == currentPageIndex;
    final String pageName = configuration.title;
    final bool isEnabled = !isAnimating;

    final String accessibilityLabel = AccessibilityService.generateNavigationLabel(
      pageName,
      isSelected: isActive,
      isEnabled: isEnabled,
    );
    
    final String accessibilityHint = AccessibilityService.generateNavigationHint(
      pageName,
      isSelected: isActive,
      isEnabled: isEnabled,
    );

    return BottomNavigationBarItem(
      // Inactive icon - uses CustomIconWidget to ensure immediate loading
      icon: AccessibilityService.createSemanticWrapper(
        label: accessibilityLabel,
        hint: accessibilityHint,
        isButton: true,
        isSelected: isActive,
        isEnabled: isEnabled,
        child: _buildNavigationIcon(
          configuration: configuration,
          isActive: false, // Always show inactive state for base icon
          pageIndex: pageIndex,
        ),
      ),
      // Active icon - shown when this page is selected
      activeIcon: AccessibilityService.createSemanticWrapper(
        label: accessibilityLabel,
        hint: accessibilityHint,
        isButton: true,
        isSelected: isActive,
        isEnabled: isEnabled,
        child: _buildNavigationIcon(
          configuration: configuration,
          isActive: true,
          pageIndex: pageIndex,
        ),
      ),
      label: pageName,
    );
  }

  /// Builds a navigation icon widget with proper state management
  /// 
  /// This method creates icons that load immediately without placeholders,
  /// addressing requirement 4.5 for proper icon display.
  /// 
  /// [configuration] - The page configuration
  /// [isActive] - Whether this is the active state icon
  /// [pageIndex] - The page index for debugging
  Widget _buildNavigationIcon({
    required configuration,
    required bool isActive,
    required int pageIndex,
  }) {
    // Get the appropriate icon name based on active state
    final iconName = _getIconName(configuration, isActive);
    
    // Determine the color based on active state and current page
    final iconColor = _getIconColor(isActive, pageIndex);
    
    return CustomIconWidget(
      iconName: iconName,
      size: 24,
      color: iconColor,
    );
  }

  /// Gets the appropriate icon name for the given state
  /// 
  /// This method maps the Flutter IconData to the corresponding string name
  /// used by CustomIconWidget, ensuring proper icon display without placeholders.
  /// 
  /// Note: This fixes the icon loading issue (requirement 4.5) by using only
  /// icon names that actually exist in the CustomIconWidget map.
  String _getIconName(configuration, bool isActive) {
    if (isActive) {
      // Map active icons to their string names (filled versions)
      if (configuration.activeIcon == Icons.dashboard) {
        return 'dashboard';
      } else if (configuration.activeIcon == Icons.groups) {
        return 'groups';
      } else if (configuration.activeIcon == Icons.person) {
        return 'person';
      }
    } else {
      // Map inactive icons to their string names
      // Updated to match the corrected PageConfiguration icons
      if (configuration.inactiveIcon == Icons.dashboard) {
        return 'dashboard'; // Same icon, different color for inactive state
      } else if (configuration.inactiveIcon == Icons.group) {
        return 'group'; // Use 'group' for inactive groups state
      } else if (configuration.inactiveIcon == Icons.person_outline) {
        return 'person_outline'; // This exists in CustomIconWidget
      }
    }
    
    // Fallback to a default icon if mapping fails
    return 'help_outline'; // Use an icon that definitely exists
  }

  /// Gets the appropriate icon color based on state
  /// 
  /// [isActive] - Whether this is the active state icon
  /// [pageIndex] - The page index to check against current page
  Color _getIconColor(bool isActive, int pageIndex) {
    // For active icons, always use primary color
    if (isActive && pageIndex == currentPageIndex) {
      return AppTheme.primaryLight;
    }
    
    // For inactive icons or non-current pages, use secondary color
    return AppTheme.textSecondaryLight;
  }

  /// Handles navigation item tap events
  /// 
  /// This method processes tap events and triggers the appropriate navigation
  /// action through the onPageSelected callback, which should animate to the
  /// selected page using PageController.animateToPage().
  /// 
  /// Accessibility Features:
  /// - Screen reader announcements for navigation actions
  /// - Haptic feedback for navigation confirmation
  /// 
  /// [index] - The index of the tapped navigation item
  void _handleNavigationTap(int index) {
    // Validate the page index
    if (!NavigationPageConfigurations.isValidPageIndex(index)) {
      debugPrint('EnhancedBottomNavigation: Invalid page index $index');
      AccessibilityService.announceNavigationError('Invalid page index: $index');
      return;
    }
    
    // Don't process taps if already on the selected page
    if (index == currentPageIndex) {
      debugPrint('EnhancedBottomNavigation: Already on page $index');
      AccessibilityService.announcePageNavigation(_getPageName(index), isCurrentPage: true);
      return;
    }
    
    // Don't process taps if animation is in progress
    if (isAnimating) {
      debugPrint('EnhancedBottomNavigation: Animation in progress, ignoring tap');
      AccessibilityService.announceNavigation('Navigation in progress, please wait');
      return;
    }
    
    // Enhanced haptic feedback for page changes
    HapticFeedbackService.pageChange();
    
    // Announce navigation to screen reader
    final String targetPageName = _getPageName(index);
    AccessibilityService.announcePageNavigation(targetPageName);
    
    // Trigger the navigation callback
    try {
      onPageSelected(index);
      debugPrint('EnhancedBottomNavigation: Navigating to page $index');
    } catch (e) {
      debugPrint('EnhancedBottomNavigation: Error navigating to page $index: $e');
      AccessibilityService.announceNavigationError('Navigation failed, please try again');
    }
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
}

/// Extension to provide convenient access to navigation functionality
/// 
/// This extension allows easy integration with the MainNavigationContainer
/// by providing methods that work directly with the NavigationService.
extension EnhancedBottomNavigationExtension on EnhancedBottomNavigation {
  /// Creates an enhanced bottom navigation that automatically integrates
  /// with the NavigationService for seamless page transitions.
  /// 
  /// This factory method creates a bottom navigation bar that:
  /// - Automatically gets the current page index from NavigationService
  /// - Uses NavigationService.navigateToPage() for smooth transitions
  /// - Handles animation state management
  /// 
  /// Returns null if NavigationService is not available
  static Widget? createWithNavigationService() {
    // Check if NavigationService is available
    if (!NavigationService.isNavigationAvailable) {
      debugPrint('EnhancedBottomNavigation: NavigationService not available');
      return null;
    }
    
    // Get current state from NavigationService
    final currentPageIndex = NavigationService.getCurrentPageIndex() ?? 0;
    final isAnimating = NavigationService.isAnimating;
    
    return EnhancedBottomNavigation(
      currentPageIndex: currentPageIndex,
      isAnimating: isAnimating,
      onPageSelected: (index) {
        // Use NavigationService for smooth page transitions
        NavigationService.navigateToPage(index, animate: true);
      },
    );
  }
}