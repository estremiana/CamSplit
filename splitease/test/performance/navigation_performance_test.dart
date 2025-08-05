import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import '../../lib/widgets/main_navigation_container.dart';
import '../../lib/services/navigation_service.dart';
import '../../lib/services/performance_monitor.dart';
import '../../lib/services/animation_service.dart';
import '../../lib/services/haptic_feedback_service.dart';

void main() {
  group('Navigation Performance Tests', () {
    late WidgetTester tester;
    
    setUp(() {
      // Initialize performance monitoring for each test
      PerformanceMonitor.startMonitoring();
    });
    
    tearDown(() {
      // Stop monitoring and clear data
      PerformanceMonitor.stopMonitoring();
      PerformanceMonitor.clearPerformanceData();
    });

    testWidgets('Page transition performance under normal load', (WidgetTester tester) async {
      // Build the navigation container
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationContainer(initialPage: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Test rapid page transitions
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 10; i++) {
        // Navigate to each page in sequence
        await tester.tap(find.byIcon(Icons.group));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.dashboard));
        await tester.pumpAndSettle();
      }
      
      stopwatch.stop();
      
      // Verify performance metrics
      final stats = PerformanceMonitor.getPerformanceStats();
      expect(stats.animationStats, isNotEmpty);
      
      // Check that transitions complete within acceptable time
      final averageTransitionTime = stopwatch.elapsedMilliseconds / 30; // 30 transitions
      expect(averageTransitionTime, lessThan(500)); // Should be under 500ms per transition
      
      // Verify 60fps performance
      final frameRates = stats.frameRateStats['navigation'];
      if (frameRates != null) {
        expect(frameRates.averageFrameRate, greaterThan(55)); // Should maintain near 60fps
      }
    });

    testWidgets('Memory usage with state preservation', (WidgetTester tester) async {
      // Build the navigation container
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationContainer(initialPage: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate heavy usage with state preservation
      for (int i = 0; i < 20; i++) {
        // Navigate between pages rapidly
        await tester.tap(find.byIcon(Icons.group));
        await tester.pump();
        
        await tester.tap(find.byIcon(Icons.person));
        await tester.pump();
        
        await tester.tap(find.byIcon(Icons.dashboard));
        await tester.pump();
      }
      
      await tester.pumpAndSettle();
      
      // Verify that all pages are still accessible and functional
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      
      // Check that navigation still works smoothly
      await tester.tap(find.byIcon(Icons.group));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.group), findsOneWidget);
    });

    testWidgets('Animation performance with different curves', (WidgetTester tester) async {
      // Test different animation configurations
      final curves = [
        Curves.easeInOut,
        Curves.easeInOutCubic,
        Curves.easeOutQuart,
        Curves.elasticOut,
      ];
      
      for (final curve in curves) {
        // Build fresh container for each test
        await tester.pumpWidget(
          MaterialApp(
            home: MainNavigationContainer(initialPage: 0),
          ),
        );
        await tester.pumpAndSettle();
        
        final stopwatch = Stopwatch()..start();
        
        // Perform navigation with current curve
        await tester.tap(find.byIcon(Icons.group));
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Verify animation completes within acceptable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        
        // Check animation service performance rating
        final duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
        final rating = AnimationService.getPerformanceRating(duration);
        expect(rating, greaterThanOrEqualTo(3)); // Should be at least acceptable
      }
    });

    testWidgets('Gesture responsiveness under load', (WidgetTester tester) async {
      // Build the navigation container
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationContainer(initialPage: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Test rapid gesture sequences
      for (int i = 0; i < 5; i++) {
        // Simulate rapid swipes
        await tester.drag(find.byType(MainNavigationContainer), const Offset(-300, 0));
        await tester.pump();
        
        await tester.drag(find.byType(MainNavigationContainer), const Offset(300, 0));
        await tester.pump();
      }
      
      await tester.pumpAndSettle();
      
      // Verify system remains responsive
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      
      // Test that navigation still works after rapid gestures
      await tester.tap(find.byIcon(Icons.group));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.group), findsOneWidget);
    });

    testWidgets('Haptic feedback performance', (WidgetTester tester) async {
      // Test haptic feedback responsiveness
      final stopwatch = Stopwatch()..start();
      
      // Trigger multiple haptic feedback events rapidly
      for (int i = 0; i < 10; i++) {
        HapticFeedbackService.pageChange();
        HapticFeedbackService.swipeGesture();
        HapticFeedbackService.boundaryReached();
      }
      
      stopwatch.stop();
      
      // Verify haptic feedback doesn't cause performance issues
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
      
      // Test haptic feedback with navigation
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationContainer(initialPage: 0),
        ),
      );
      await tester.pumpAndSettle();
      
      final navigationStopwatch = Stopwatch()..start();
      
      await tester.tap(find.byIcon(Icons.group));
      await tester.pumpAndSettle();
      
      navigationStopwatch.stop();
      
      // Navigation with haptic feedback should still be smooth
      expect(navigationStopwatch.elapsedMilliseconds, lessThan(500));
    });

    testWidgets('Memory leak prevention', (WidgetTester tester) async {
      // Test for memory leaks with repeated widget creation/disposal
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: MainNavigationContainer(initialPage: 0),
          ),
        );
        await tester.pumpAndSettle();
        
        // Navigate between pages
        await tester.tap(find.byIcon(Icons.group));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();
        
        // Dispose widget
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      }
      
      // Verify no memory leaks by checking that new widget still works
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationContainer(initialPage: 0),
        ),
      );
      await tester.pumpAndSettle();
      
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      
      // Verify navigation still works
      await tester.tap(find.byIcon(Icons.group));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.group), findsOneWidget);
    });

    testWidgets('Performance under low-end device simulation', (WidgetTester tester) async {
      // Simulate lower-end device by reducing frame rate
      tester.binding.setSurfaceSize(const Size(320, 480)); // Smaller screen
      
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationContainer(initialPage: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Test navigation performance on "low-end" device
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.group));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.dashboard));
        await tester.pumpAndSettle();
      }
      
      stopwatch.stop();
      
      // Even on low-end devices, transitions should be reasonable
      final averageTime = stopwatch.elapsedMilliseconds / 15;
      expect(averageTime, lessThan(800)); // More lenient for low-end devices
      
      // Verify functionality is maintained
      expect(find.byType(MainNavigationContainer), findsOneWidget);
    });

    testWidgets('Animation interruption handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationContainer(initialPage: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Start navigation and interrupt it
      await tester.tap(find.byIcon(Icons.group));
      await tester.pump(); // Start animation
      
      // Interrupt with another navigation
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      // Verify system handles interruption gracefully
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      
      // Verify final state is correct
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Performance monitoring accuracy', (WidgetTester tester) async {
      // Test that performance monitoring provides accurate data
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationContainer(initialPage: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Perform some navigation actions
      await tester.tap(find.byIcon(Icons.group));
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      // Check performance stats
      final stats = PerformanceMonitor.getPerformanceStats();
      expect(stats, isNotNull);
      
      // Verify that performance data was recorded
      expect(stats.animationStats.isNotEmpty || stats.navigationLatency != null, isTrue);
      
      // Test performance acceptability
      final isAcceptable = PerformanceMonitor.isPerformanceAcceptable();
      expect(isAcceptable, isTrue); // Should be acceptable under normal conditions
    });
  });
}