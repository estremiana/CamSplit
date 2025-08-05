import 'package:flutter/material.dart';

import '../presentation/expense_dashboard/expense_dashboard.dart';
import '../presentation/group_management/group_management.dart';
import '../presentation/profile_settings/profile_settings.dart';
import 'page_configuration.dart';

/// Predefined page configurations for the main navigation pages in the slideable navigation system.
/// 
/// This class provides static configurations for the three main pages: Dashboard, Groups, and Profile.
/// Each configuration includes the appropriate icons, titles, and page widgets as specified in the
/// requirements for proper icon display and navigation functionality.
class NavigationPageConfigurations {
  /// Configuration for the Dashboard page (index 0)
  /// 
  /// Uses dashboard icons and displays the ExpenseDashboard widget.
  /// This is the default landing page for users.
  static const PageConfiguration dashboard = PageConfiguration(
    title: 'Dashboard',
    activeIcon: Icons.dashboard,
    inactiveIcon: Icons.dashboard, // Use same icon with different color since dashboard_outlined doesn't exist
    page: ExpenseDashboard(showBottomNavigation: false),
    pageKey: 'dashboard_page',
    keepAlive: true,
  );
  
  /// Configuration for the Groups page (index 1)
  /// 
  /// Uses group/people icons and displays the GroupManagement widget.
  /// This page allows users to manage their expense groups.
  static const PageConfiguration groups = PageConfiguration(
    title: 'Groups',
    activeIcon: Icons.groups,
    inactiveIcon: Icons.group, // Use Icons.group for inactive state since groups_outlined doesn't exist
    page: GroupManagement(showBottomNavigation: false),
    pageKey: 'groups_page',
    keepAlive: true,
  );
  
  /// Configuration for the Profile page (index 2)
  /// 
  /// Uses person/account icons and displays the ProfileSettings widget.
  /// This page allows users to manage their profile and app settings.
  static const PageConfiguration profile = PageConfiguration(
    title: 'Profile',
    activeIcon: Icons.person,
    inactiveIcon: Icons.person_outline,
    page: ProfileSettings(showBottomNavigation: false),
    pageKey: 'profile_page',
    keepAlive: true,
  );
  
  /// List of all page configurations in order (Dashboard, Groups, Profile)
  /// 
  /// This list maintains the correct order for the PageView and bottom navigation.
  /// The index in this list corresponds to the page index used throughout the navigation system.
  static const List<PageConfiguration> allPages = [
    dashboard,  // index 0
    groups,     // index 1
    profile,    // index 2
  ];
  
  /// Gets a page configuration by index
  /// 
  /// [index] - The page index (0=Dashboard, 1=Groups, 2=Profile)
  /// 
  /// Returns the PageConfiguration for the specified index, or null if invalid
  static PageConfiguration? getPageByIndex(int index) {
    if (index < 0 || index >= allPages.length) {
      return null;
    }
    return allPages[index];
  }
  
  /// Gets the page index for a specific configuration
  /// 
  /// [configuration] - The PageConfiguration to find
  /// 
  /// Returns the index of the configuration, or -1 if not found
  static int getIndexForPage(PageConfiguration configuration) {
    return allPages.indexOf(configuration);
  }
  
  /// Gets the total number of pages
  static int get totalPages => allPages.length;
  
  /// Validates a page index
  /// 
  /// [index] - The page index to validate
  /// 
  /// Returns true if the index is valid (0-2), false otherwise
  static bool isValidPageIndex(int index) {
    return index >= 0 && index < allPages.length;
  }
  
  /// Gets the page title by index
  /// 
  /// [index] - The page index
  /// 
  /// Returns the page title or null if invalid index
  static String? getPageTitle(int index) {
    final page = getPageByIndex(index);
    return page?.title;
  }
  
  /// Gets the appropriate icon for a page based on its active state
  /// 
  /// [index] - The page index
  /// [isActive] - Whether the page is currently active/selected
  /// 
  /// Returns the appropriate IconData or null if invalid index
  static IconData? getPageIcon(int index, bool isActive) {
    final page = getPageByIndex(index);
    return page?.getIcon(isActive);
  }
}