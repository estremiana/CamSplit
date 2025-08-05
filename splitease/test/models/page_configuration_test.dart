import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splitease/models/page_configuration.dart';
import 'package:splitease/models/navigation_page_configurations.dart';

void main() {
  group('PageConfiguration', () {
    test('should create PageConfiguration with all required properties', () {
      const config = PageConfiguration(
        title: 'Test Page',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        page: Placeholder(),
        pageKey: 'test_page',
        keepAlive: true,
      );

      expect(config.title, equals('Test Page'));
      expect(config.activeIcon, equals(Icons.home));
      expect(config.inactiveIcon, equals(Icons.home_outlined));
      expect(config.pageKey, equals('test_page'));
      expect(config.keepAlive, isTrue);
      expect(config.page, isA<Placeholder>());
    });

    test('should create PageConfiguration with default keepAlive value', () {
      const config = PageConfiguration(
        title: 'Test Page',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        page: Placeholder(),
        pageKey: 'test_page',
      );

      expect(config.keepAlive, isTrue);
    });

    test('should return correct icon based on active state', () {
      const config = PageConfiguration(
        title: 'Test Page',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        page: Placeholder(),
        pageKey: 'test_page',
      );

      expect(config.getIcon(true), equals(Icons.home));
      expect(config.getIcon(false), equals(Icons.home_outlined));
    });

    test('should create copy with modified properties', () {
      const original = PageConfiguration(
        title: 'Original',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        page: Placeholder(),
        pageKey: 'original_page',
        keepAlive: true,
      );

      final copy = original.copyWith(
        title: 'Modified',
        keepAlive: false,
      );

      expect(copy.title, equals('Modified'));
      expect(copy.activeIcon, equals(Icons.home));
      expect(copy.inactiveIcon, equals(Icons.home_outlined));
      expect(copy.pageKey, equals('original_page'));
      expect(copy.keepAlive, isFalse);
    });

    test('should implement equality correctly', () {
      const config1 = PageConfiguration(
        title: 'Test Page',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        page: Placeholder(),
        pageKey: 'test_page',
        keepAlive: true,
      );

      const config2 = PageConfiguration(
        title: 'Test Page',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        page: Placeholder(),
        pageKey: 'test_page',
        keepAlive: true,
      );

      const config3 = PageConfiguration(
        title: 'Different Page',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        page: Placeholder(),
        pageKey: 'test_page',
        keepAlive: true,
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('should have consistent hashCode for equal objects', () {
      const config1 = PageConfiguration(
        title: 'Test Page',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        page: Placeholder(),
        pageKey: 'test_page',
        keepAlive: true,
      );

      const config2 = PageConfiguration(
        title: 'Test Page',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        page: Placeholder(),
        pageKey: 'test_page',
        keepAlive: true,
      );

      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should provide meaningful toString representation', () {
      const config = PageConfiguration(
        title: 'Test Page',
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        page: Placeholder(),
        pageKey: 'test_page',
        keepAlive: true,
      );

      final stringRepresentation = config.toString();
      expect(stringRepresentation, contains('Test Page'));
      expect(stringRepresentation, contains('test_page'));
      expect(stringRepresentation, contains('true'));
    });
  });

  group('NavigationState', () {
    test('should create NavigationState with all required properties', () {
      const state = NavigationState(
        currentPageIndex: 1,
        isAnimating: true,
        pageInitialized: [true, false, true],
        totalPages: 3,
      );

      expect(state.currentPageIndex, equals(1));
      expect(state.isAnimating, isTrue);
      expect(state.pageInitialized, equals([true, false, true]));
      expect(state.totalPages, equals(3));
    });

    test('should create initial NavigationState with default values', () {
      final state = NavigationState.initial();

      expect(state.currentPageIndex, equals(0));
      expect(state.isAnimating, isFalse);
      expect(state.totalPages, equals(3));
      expect(state.pageInitialized, equals([true, false, false]));
    });

    test('should create initial NavigationState with custom initial page', () {
      final state = NavigationState.initial(initialPageIndex: 2);

      expect(state.currentPageIndex, equals(2));
      expect(state.isAnimating, isFalse);
      expect(state.totalPages, equals(3));
      expect(state.pageInitialized, equals([false, false, true]));
    });

    test('should clamp invalid initial page index', () {
      final state = NavigationState.initial(initialPageIndex: 5, totalPages: 3);

      expect(state.currentPageIndex, equals(2)); // Clamped to max valid index
      expect(state.pageInitialized, equals([false, false, true]));
    });

    test('should create copy with modified properties', () {
      const original = NavigationState(
        currentPageIndex: 0,
        isAnimating: false,
        pageInitialized: [true, false, false],
        totalPages: 3,
      );

      final copy = original.copyWith(
        currentPageIndex: 1,
        isAnimating: true,
      );

      expect(copy.currentPageIndex, equals(1));
      expect(copy.isAnimating, isTrue);
      expect(copy.pageInitialized, equals([true, false, false]));
      expect(copy.totalPages, equals(3));
    });

    test('should navigate to page and mark it as initialized', () {
      const original = NavigationState(
        currentPageIndex: 0,
        isAnimating: false,
        pageInitialized: [true, false, false],
        totalPages: 3,
      );

      final navigated = original.navigateToPage(2);

      expect(navigated.currentPageIndex, equals(2));
      expect(navigated.pageInitialized, equals([true, false, true]));
      expect(navigated.isAnimating, isFalse); // Animation state unchanged
    });

    test('should clamp invalid page index when navigating', () {
      const original = NavigationState(
        currentPageIndex: 0,
        isAnimating: false,
        pageInitialized: [true, false, false],
        totalPages: 3,
      );

      final navigated = original.navigateToPage(5);

      expect(navigated.currentPageIndex, equals(2)); // Clamped to max valid index
      expect(navigated.pageInitialized, equals([true, false, true]));
    });

    test('should set animation state', () {
      const original = NavigationState(
        currentPageIndex: 0,
        isAnimating: false,
        pageInitialized: [true, false, false],
        totalPages: 3,
      );

      final animating = original.setAnimating(true);

      expect(animating.isAnimating, isTrue);
      expect(animating.currentPageIndex, equals(0)); // Other properties unchanged
      expect(animating.pageInitialized, equals([true, false, false]));
    });

    test('should check if page is initialized', () {
      const state = NavigationState(
        currentPageIndex: 1,
        isAnimating: false,
        pageInitialized: [true, false, true],
        totalPages: 3,
      );

      expect(state.isPageInitialized(0), isTrue);
      expect(state.isPageInitialized(1), isFalse);
      expect(state.isPageInitialized(2), isTrue);
      expect(state.isPageInitialized(-1), isFalse); // Invalid index
      expect(state.isPageInitialized(3), isFalse); // Invalid index
    });

    test('should correctly identify first and last pages', () {
      const firstPage = NavigationState(
        currentPageIndex: 0,
        isAnimating: false,
        pageInitialized: [true, false, false],
        totalPages: 3,
      );

      const middlePage = NavigationState(
        currentPageIndex: 1,
        isAnimating: false,
        pageInitialized: [true, true, false],
        totalPages: 3,
      );

      const lastPage = NavigationState(
        currentPageIndex: 2,
        isAnimating: false,
        pageInitialized: [true, false, true],
        totalPages: 3,
      );

      expect(firstPage.isFirstPage, isTrue);
      expect(firstPage.isLastPage, isFalse);
      expect(firstPage.canNavigateLeft, isFalse);
      expect(firstPage.canNavigateRight, isTrue);

      expect(middlePage.isFirstPage, isFalse);
      expect(middlePage.isLastPage, isFalse);
      expect(middlePage.canNavigateLeft, isTrue);
      expect(middlePage.canNavigateRight, isTrue);

      expect(lastPage.isFirstPage, isFalse);
      expect(lastPage.isLastPage, isTrue);
      expect(lastPage.canNavigateLeft, isTrue);
      expect(lastPage.canNavigateRight, isFalse);
    });

    test('should implement equality correctly', () {
      const state1 = NavigationState(
        currentPageIndex: 1,
        isAnimating: true,
        pageInitialized: [true, false, true],
        totalPages: 3,
      );

      const state2 = NavigationState(
        currentPageIndex: 1,
        isAnimating: true,
        pageInitialized: [true, false, true],
        totalPages: 3,
      );

      const state3 = NavigationState(
        currentPageIndex: 2,
        isAnimating: true,
        pageInitialized: [true, false, true],
        totalPages: 3,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('should have consistent hashCode for equal objects', () {
      const state1 = NavigationState(
        currentPageIndex: 1,
        isAnimating: true,
        pageInitialized: [true, false, true],
        totalPages: 3,
      );

      const state2 = NavigationState(
        currentPageIndex: 1,
        isAnimating: true,
        pageInitialized: [true, false, true],
        totalPages: 3,
      );

      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('should provide meaningful toString representation', () {
      const state = NavigationState(
        currentPageIndex: 1,
        isAnimating: true,
        pageInitialized: [true, false, true],
        totalPages: 3,
      );

      final stringRepresentation = state.toString();
      expect(stringRepresentation, contains('currentPageIndex: 1'));
      expect(stringRepresentation, contains('isAnimating: true'));
      expect(stringRepresentation, contains('totalPages: 3'));
    });
  });

  group('NavigationPageConfigurations', () {
    test('should have correct dashboard configuration', () {
      const config = NavigationPageConfigurations.dashboard;

      expect(config.title, equals('Dashboard'));
      expect(config.activeIcon, equals(Icons.dashboard));
      expect(config.inactiveIcon, equals(Icons.dashboard_outlined));
      expect(config.pageKey, equals('dashboard_page'));
      expect(config.keepAlive, isTrue);
    });

    test('should have correct groups configuration', () {
      const config = NavigationPageConfigurations.groups;

      expect(config.title, equals('Groups'));
      expect(config.activeIcon, equals(Icons.groups));
      expect(config.inactiveIcon, equals(Icons.groups_outlined));
      expect(config.pageKey, equals('groups_page'));
      expect(config.keepAlive, isTrue);
    });

    test('should have correct profile configuration', () {
      const config = NavigationPageConfigurations.profile;

      expect(config.title, equals('Profile'));
      expect(config.activeIcon, equals(Icons.person));
      expect(config.inactiveIcon, equals(Icons.person_outline));
      expect(config.pageKey, equals('profile_page'));
      expect(config.keepAlive, isTrue);
    });

    test('should have all pages in correct order', () {
      const pages = NavigationPageConfigurations.allPages;

      expect(pages.length, equals(3));
      expect(pages[0], equals(NavigationPageConfigurations.dashboard));
      expect(pages[1], equals(NavigationPageConfigurations.groups));
      expect(pages[2], equals(NavigationPageConfigurations.profile));
    });

    test('should get page by valid index', () {
      final dashboardPage = NavigationPageConfigurations.getPageByIndex(0);
      final groupsPage = NavigationPageConfigurations.getPageByIndex(1);
      final profilePage = NavigationPageConfigurations.getPageByIndex(2);

      expect(dashboardPage, equals(NavigationPageConfigurations.dashboard));
      expect(groupsPage, equals(NavigationPageConfigurations.groups));
      expect(profilePage, equals(NavigationPageConfigurations.profile));
    });

    test('should return null for invalid page index', () {
      final invalidPage1 = NavigationPageConfigurations.getPageByIndex(-1);
      final invalidPage2 = NavigationPageConfigurations.getPageByIndex(3);

      expect(invalidPage1, isNull);
      expect(invalidPage2, isNull);
    });

    test('should get index for page configuration', () {
      final dashboardIndex = NavigationPageConfigurations.getIndexForPage(
        NavigationPageConfigurations.dashboard,
      );
      final groupsIndex = NavigationPageConfigurations.getIndexForPage(
        NavigationPageConfigurations.groups,
      );
      final profileIndex = NavigationPageConfigurations.getIndexForPage(
        NavigationPageConfigurations.profile,
      );

      expect(dashboardIndex, equals(0));
      expect(groupsIndex, equals(1));
      expect(profileIndex, equals(2));
    });

    test('should return -1 for unknown page configuration', () {
      const unknownConfig = PageConfiguration(
        title: 'Unknown',
        activeIcon: Icons.help,
        inactiveIcon: Icons.help_outline,
        page: Placeholder(),
        pageKey: 'unknown_page',
      );

      final index = NavigationPageConfigurations.getIndexForPage(unknownConfig);
      expect(index, equals(-1));
    });

    test('should return correct total pages count', () {
      expect(NavigationPageConfigurations.totalPages, equals(3));
    });

    test('should validate page indices correctly', () {
      expect(NavigationPageConfigurations.isValidPageIndex(0), isTrue);
      expect(NavigationPageConfigurations.isValidPageIndex(1), isTrue);
      expect(NavigationPageConfigurations.isValidPageIndex(2), isTrue);
      expect(NavigationPageConfigurations.isValidPageIndex(-1), isFalse);
      expect(NavigationPageConfigurations.isValidPageIndex(3), isFalse);
    });

    test('should get page titles by index', () {
      expect(NavigationPageConfigurations.getPageTitle(0), equals('Dashboard'));
      expect(NavigationPageConfigurations.getPageTitle(1), equals('Groups'));
      expect(NavigationPageConfigurations.getPageTitle(2), equals('Profile'));
      expect(NavigationPageConfigurations.getPageTitle(-1), isNull);
      expect(NavigationPageConfigurations.getPageTitle(3), isNull);
    });

    test('should get page icons by index and active state', () {
      // Dashboard icons
      expect(
        NavigationPageConfigurations.getPageIcon(0, true),
        equals(Icons.dashboard),
      );
      expect(
        NavigationPageConfigurations.getPageIcon(0, false),
        equals(Icons.dashboard_outlined),
      );

      // Groups icons
      expect(
        NavigationPageConfigurations.getPageIcon(1, true),
        equals(Icons.groups),
      );
      expect(
        NavigationPageConfigurations.getPageIcon(1, false),
        equals(Icons.groups_outlined),
      );

      // Profile icons
      expect(
        NavigationPageConfigurations.getPageIcon(2, true),
        equals(Icons.person),
      );
      expect(
        NavigationPageConfigurations.getPageIcon(2, false),
        equals(Icons.person_outline),
      );

      // Invalid indices
      expect(NavigationPageConfigurations.getPageIcon(-1, true), isNull);
      expect(NavigationPageConfigurations.getPageIcon(3, false), isNull);
    });
  });
}