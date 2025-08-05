import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/services/icon_preloader.dart';

void main() {
  group('IconPreloader Tests', () {
    setUp(() {
      // Clear cache before each test
      IconPreloader.clearCache();
    });

    tearDown(() {
      // Clear cache after each test
      IconPreloader.clearCache();
    });

    group('Preloading', () {
      test('should preload navigation icons successfully', () {
        // Initially not preloaded
        expect(IconPreloader.isNavigationIconsPreloaded, isFalse);
        expect(IconPreloader.preloadedIconCount, equals(0));

        // Preload icons
        IconPreloader.preloadNavigationIcons();

        // Verify preloading is complete
        expect(IconPreloader.isNavigationIconsPreloaded, isTrue);
        expect(IconPreloader.preloadedIconCount, equals(5)); // 5 navigation icons
      });

      test('should not preload twice', () {
        // First preload
        IconPreloader.preloadNavigationIcons();
        final firstCount = IconPreloader.preloadedIconCount;

        // Second preload (should not add more)
        IconPreloader.preloadNavigationIcons();
        final secondCount = IconPreloader.preloadedIconCount;

        expect(firstCount, equals(secondCount));
      });

      test('should preload all required navigation icons', () {
        IconPreloader.preloadNavigationIcons();

        // Verify all navigation icons are preloaded
        expect(IconPreloader.isIconPreloaded('dashboard'), isTrue);
        expect(IconPreloader.isIconPreloaded('group'), isTrue);
        expect(IconPreloader.isIconPreloaded('groups'), isTrue);
        expect(IconPreloader.isIconPreloaded('person'), isTrue);
        expect(IconPreloader.isIconPreloaded('person_outline'), isTrue);
      });
    });

    group('Icon Retrieval', () {
      test('should return correct icon data for preloaded icons', () {
        IconPreloader.preloadNavigationIcons();

        // Verify correct icon data is returned
        expect(IconPreloader.getPreloadedIcon('dashboard'), equals(Icons.dashboard));
        expect(IconPreloader.getPreloadedIcon('group'), equals(Icons.group));
        expect(IconPreloader.getPreloadedIcon('groups'), equals(Icons.groups));
        expect(IconPreloader.getPreloadedIcon('person'), equals(Icons.person));
        expect(IconPreloader.getPreloadedIcon('person_outline'), equals(Icons.person_outline));
      });

      test('should return null for non-preloaded icons', () {
        IconPreloader.preloadNavigationIcons();

        // Verify non-navigation icons return null
        expect(IconPreloader.getPreloadedIcon('invalid_icon'), isNull);
        expect(IconPreloader.getPreloadedIcon('home'), isNull);
      });

      test('should return null when not preloaded', () {
        // Don't preload icons
        expect(IconPreloader.getPreloadedIcon('dashboard'), isNull);
        expect(IconPreloader.getPreloadedIcon('group'), isNull);
      });
    });

    group('Verification', () {
      test('should verify all navigation icons are available', () {
        // Initially not verified
        expect(IconPreloader.verifyNavigationIcons(), isFalse);

        // Preload icons
        IconPreloader.preloadNavigationIcons();

        // Now should be verified
        expect(IconPreloader.verifyNavigationIcons(), isTrue);
      });

      test('should detect missing icons', () {
        // Preload icons
        IconPreloader.preloadNavigationIcons();

        // Clear cache to simulate missing icons
        IconPreloader.clearCache();

        // Should detect missing icons
        expect(IconPreloader.verifyNavigationIcons(), isFalse);
      });
    });

    group('Cache Management', () {
      test('should clear cache correctly', () {
        // Preload icons
        IconPreloader.preloadNavigationIcons();
        expect(IconPreloader.preloadedIconCount, equals(5));

        // Clear cache
        IconPreloader.clearCache();
        expect(IconPreloader.preloadedIconCount, equals(0));
        expect(IconPreloader.isNavigationIconsPreloaded, isFalse);
      });

      test('should return correct preloaded icon names', () {
        IconPreloader.preloadNavigationIcons();

        final iconNames = IconPreloader.preloadedIconNames;
        expect(iconNames.length, equals(5));
        expect(iconNames, contains('dashboard'));
        expect(iconNames, contains('group'));
        expect(iconNames, contains('groups'));
        expect(iconNames, contains('person'));
        expect(iconNames, contains('person_outline'));
      });
    });

    group('Status Report', () {
      test('should generate status report correctly', () {
        // Before preloading
        String report = IconPreloader.getStatusReport();
        expect(report, contains('Preloading Complete: false'));
        expect(report, contains('Preloaded Icons: 0'));

        // After preloading
        IconPreloader.preloadNavigationIcons();
        report = IconPreloader.getStatusReport();
        expect(report, contains('Preloading Complete: true'));
        expect(report, contains('Preloaded Icons: 5'));
        expect(report, contains('Navigation Icons Verified: true'));
        expect(report, contains('- dashboard'));
        expect(report, contains('- group'));
        expect(report, contains('- groups'));
        expect(report, contains('- person'));
        expect(report, contains('- person_outline'));
      });
    });

    group('Edge Cases', () {
      test('should handle multiple preload calls gracefully', () {
        // Multiple preload calls should not cause issues
        IconPreloader.preloadNavigationIcons();
        IconPreloader.preloadNavigationIcons();
        IconPreloader.preloadNavigationIcons();

        expect(IconPreloader.isNavigationIconsPreloaded, isTrue);
        expect(IconPreloader.preloadedIconCount, equals(5));
      });

      test('should handle clear cache after preloading', () {
        IconPreloader.preloadNavigationIcons();
        expect(IconPreloader.isNavigationIconsPreloaded, isTrue);

        IconPreloader.clearCache();
        expect(IconPreloader.isNavigationIconsPreloaded, isFalse);

        // Should be able to preload again
        IconPreloader.preloadNavigationIcons();
        expect(IconPreloader.isNavigationIconsPreloaded, isTrue);
      });
    });
  });
} 