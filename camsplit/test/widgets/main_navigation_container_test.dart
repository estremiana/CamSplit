import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/navigation_page_configurations.dart';

void main() {
  group('MainNavigationContainer PageView Integration Tests', () {
    // Test the PageView integration without rendering actual page widgets
    // to avoid sizer package initialization issues in tests
    
    testWidgets('should have correct page configurations', (WidgetTester tester) async {
      // Test that we have the expected number of page configurations
      expect(NavigationPageConfigurations.allPages.length, equals(3));
      
      // Test Dashboard configuration
      final dashboardConfig = NavigationPageConfigurations.getPageByIndex(0);
      expect(dashboardConfig?.title, equals('Dashboard'));
      expect(dashboardConfig?.pageKey, equals('dashboard_page'));
      expect(dashboardConfig?.keepAlive, isTrue);
      
      // Test Groups configuration
      final groupsConfig = NavigationPageConfigurations.getPageByIndex(1);
      expect(groupsConfig?.title, equals('Groups'));
      expect(groupsConfig?.pageKey, equals('groups_page'));
      expect(groupsConfig?.keepAlive, isTrue);
      
      // Test Profile configuration
      final profileConfig = NavigationPageConfigurations.getPageByIndex(2);
      expect(profileConfig?.title, equals('Profile'));
      expect(profileConfig?.pageKey, equals('profile_page'));
      expect(profileConfig?.keepAlive, isTrue);
    });

    testWidgets('should validate page indices correctly', (WidgetTester tester) async {
      expect(NavigationPageConfigurations.isValidPageIndex(0), isTrue);
      expect(NavigationPageConfigurations.isValidPageIndex(1), isTrue);
      expect(NavigationPageConfigurations.isValidPageIndex(2), isTrue);
      expect(NavigationPageConfigurations.isValidPageIndex(-1), isFalse);
      expect(NavigationPageConfigurations.isValidPageIndex(3), isFalse);
    });

    testWidgets('should have proper icon configurations', (WidgetTester tester) async {
      // Test that each page has proper active and inactive icons
      for (int i = 0; i < NavigationPageConfigurations.allPages.length; i++) {
        final config = NavigationPageConfigurations.getPageByIndex(i);
        expect(config, isNotNull);
        
        // Test that icons are different for active/inactive states
        expect(config!.activeIcon, isNotNull);
        expect(config.inactiveIcon, isNotNull);
        expect(config.activeIcon != config.inactiveIcon, isTrue);
        
        // Test getIcon method
        expect(config.getIcon(true), equals(config.activeIcon));
        expect(config.getIcon(false), equals(config.inactiveIcon));
      }
    });

    testWidgets('should have unique page keys', (WidgetTester tester) async {
      final pageKeys = NavigationPageConfigurations.allPages
          .map((config) => config.pageKey)
          .toList();
      
      // Check that all page keys are unique
      final uniqueKeys = pageKeys.toSet();
      expect(uniqueKeys.length, equals(pageKeys.length));
      
      // Check specific expected keys
      expect(pageKeys, contains('dashboard_page'));
      expect(pageKeys, contains('groups_page'));
      expect(pageKeys, contains('profile_page'));
    });
  });

  group('Page Configuration Tests', () {
    test('should have correct page configurations', () {
      final pages = NavigationPageConfigurations.allPages;
      
      expect(pages.length, equals(3));
      
      // Test Dashboard configuration
      expect(pages[0].title, equals('Dashboard'));
      expect(pages[0].pageKey, equals('dashboard_page'));
      expect(pages[0].keepAlive, isTrue);
      
      // Test Groups configuration
      expect(pages[1].title, equals('Groups'));
      expect(pages[1].pageKey, equals('groups_page'));
      expect(pages[1].keepAlive, isTrue);
      
      // Test Profile configuration
      expect(pages[2].title, equals('Profile'));
      expect(pages[2].pageKey, equals('profile_page'));
      expect(pages[2].keepAlive, isTrue);
    });

    test('should validate page indices correctly', () {
      expect(NavigationPageConfigurations.isValidPageIndex(0), isTrue);
      expect(NavigationPageConfigurations.isValidPageIndex(1), isTrue);
      expect(NavigationPageConfigurations.isValidPageIndex(2), isTrue);
      expect(NavigationPageConfigurations.isValidPageIndex(-1), isFalse);
      expect(NavigationPageConfigurations.isValidPageIndex(3), isFalse);
    });
  });
}