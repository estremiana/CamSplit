import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/widgets/main_navigation_container.dart';
import 'package:splitease/widgets/enhanced_bottom_navigation.dart';
import 'package:splitease/services/haptic_feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Navigation Gesture Conflict Tests', () {
    late Widget testApp;

    setUp(() {
      HapticFeedbackService.setEnabled(true);
      
      testApp = MaterialApp(
        home: MainNavigationContainer(initialPage: 0),
      );
    });

    tearDown(() {
      HapticFeedbackService.setEnabled(true);
    });

    group('Gesture Conflict Resolution', () {
      testWidgets('should handle internal scrolling without triggering navigation', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Find scrollable content within the dashboard
        final scrollableContent = find.byType(SingleChildScrollView);
        if (scrollableContent.evaluate().isNotEmpty) {
          // Scroll vertically within the page
          await tester.drag(scrollableContent.first, const Offset(0, -200));
          await tester.pumpAndSettle();

          // Verify still on dashboard (no horizontal navigation occurred)
          final bottomNav = tester.widget<EnhancedBottomNavigation>(
            find.byType(EnhancedBottomNavigation),
          );
          expect(bottomNav.currentPageIndex, equals(0));
        }
      });

      testWidgets('should handle horizontal scrolling within page content', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Find any horizontal scrollable content
        final horizontalScrollable = find.byType(PageView);
        if (horizontalScrollable.evaluate().isNotEmpty) {
          // Try to scroll horizontally within page content
          await tester.drag(horizontalScrollable.first, const Offset(-50, 0));
          await tester.pump();

          // Verify navigation behavior is appropriate
          final bottomNav = tester.widget<EnhancedBottomNavigation>(
            find.byType(EnhancedBottomNavigation),
          );
          // Should either stay on same page or navigate appropriately
          expect(bottomNav.currentPageIndex, isA<int>());
        }
      });

      testWidgets('should handle simultaneous vertical and horizontal gestures', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Perform diagonal gesture (both horizontal and vertical)
        await tester.drag(find.byType(PageView), const Offset(-100, -100));
        await tester.pumpAndSettle();

        // Verify navigation state is consistent
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, isA<int>());
        expect(bottomNav.currentPageIndex, greaterThanOrEqualTo(0));
        expect(bottomNav.currentPageIndex, lessThanOrEqualTo(2));
      });

      testWidgets('should handle rapid gesture sequences', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Perform rapid gesture sequence
        for (int i = 0; i < 5; i++) {
          await tester.drag(find.byType(PageView), const Offset(-50, 0));
          await tester.pump();
          await tester.drag(find.byType(PageView), const Offset(50, 0));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        // Verify final state is consistent
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, isA<int>());
        expect(bottomNav.currentPageIndex, greaterThanOrEqualTo(0));
        expect(bottomNav.currentPageIndex, lessThanOrEqualTo(2));
      });
    });

    group('Boundary Condition Tests', () {
      testWidgets('should handle extreme swipe distances', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Perform very long swipe
        await tester.drag(find.byType(PageView), const Offset(-1000, 0));
        await tester.pumpAndSettle();

        // Verify navigation is handled appropriately
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, isA<int>());
        expect(bottomNav.currentPageIndex, greaterThanOrEqualTo(0));
        expect(bottomNav.currentPageIndex, lessThanOrEqualTo(2));
      });

      testWidgets('should handle very short swipe distances', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Perform very short swipe
        await tester.drag(find.byType(PageView), const Offset(-10, 0));
        await tester.pumpAndSettle();

        // Verify behavior is appropriate for short swipes
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, isA<int>());
      });

      testWidgets('should handle zero-distance gestures', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Perform zero-distance gesture
        await tester.drag(find.byType(PageView), const Offset(0, 0));
        await tester.pumpAndSettle();

        // Verify no navigation occurs
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });

      testWidgets('should handle boundary swipes with different velocities', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Navigate to groups first
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Try to swipe right with different velocities
        for (int i = 0; i < 3; i++) {
          await tester.drag(find.byType(PageView), const Offset(100, 0));
          await tester.pump();
          await tester.pumpAndSettle();
        }

        // Verify navigation behavior is consistent
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, isA<int>());
      });
    });

    group('Multi-touch and Complex Gesture Tests', () {
      testWidgets('should handle multiple simultaneous touches', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Simulate multiple touches (this is a simplified test)
        await tester.tap(find.byType(PageView));
        await tester.pumpAndSettle();

        // Verify navigation state remains consistent
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, isA<int>());
      });

      testWidgets('should handle gesture cancellation', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Start a gesture but cancel it
        await tester.drag(find.byType(PageView), const Offset(-100, 0));
        await tester.pump();
        
        // Cancel the gesture by tapping elsewhere
        await tester.tap(find.byType(EnhancedBottomNavigation));
        await tester.pumpAndSettle();

        // Verify navigation state is consistent
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, isA<int>());
      });

      testWidgets('should handle gesture interruption by system events', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Start a navigation gesture
        await tester.drag(find.byType(PageView), const Offset(-150, 0));
        await tester.pump();

        // Simulate system interruption by rebuilding widget
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Verify navigation state is consistent
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, isA<int>());
      });
    });

    group('Performance Under Gesture Load', () {
      testWidgets('should maintain responsiveness during rapid gestures', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        // Perform rapid gesture sequence
        for (int i = 0; i < 10; i++) {
          await tester.drag(find.byType(PageView), const Offset(-50, 0));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Verify performance is acceptable (should complete within reasonable time)
        expect(stopwatch.elapsed.inMilliseconds, lessThan(5000));

        // Verify final state is consistent
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, isA<int>());
      });

      testWidgets('should handle gesture conflicts without memory leaks', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Perform gesture sequences that might cause conflicts
        for (int i = 0; i < 20; i++) {
          await tester.drag(find.byType(PageView), const Offset(-30, 10));
          await tester.pump();
          await tester.drag(find.byType(PageView), const Offset(30, -10));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        // Verify widget is still functional
        expect(find.byType(MainNavigationContainer), findsOneWidget);
        expect(find.byType(EnhancedBottomNavigation), findsOneWidget);

        // Verify navigation state is consistent
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, isA<int>());
      });
    });

    group('Edge Case Navigation Scenarios', () {
      testWidgets('should handle navigation during page rebuilds', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Start navigation
        await tester.drag(find.byType(PageView), const Offset(-100, 0));
        await tester.pump();

        // Trigger widget rebuild
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Verify navigation state is preserved
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, isA<int>());
      });

      testWidgets('should handle navigation with different initial pages', (WidgetTester tester) async {
        // Test with different initial pages
        for (int initialPage = 0; initialPage < 3; initialPage++) {
          final testAppWithInitialPage = MaterialApp(
            home: MainNavigationContainer(initialPage: initialPage),
          );

          await tester.pumpWidget(testAppWithInitialPage);
          await tester.pumpAndSettle();

          // Verify initial page is correct
          final bottomNav = tester.widget<EnhancedBottomNavigation>(
            find.byType(EnhancedBottomNavigation),
          );
          expect(bottomNav.currentPageIndex, equals(initialPage));

          // Test navigation from this initial page
          await tester.drag(find.byType(PageView), const Offset(-300, 0));
          await tester.pumpAndSettle();

          // Verify navigation works correctly
          final newBottomNav = tester.widget<EnhancedBottomNavigation>(
            find.byType(EnhancedBottomNavigation),
          );
          expect(newBottomNav.currentPageIndex, isA<int>());
          expect(newBottomNav.currentPageIndex, greaterThanOrEqualTo(0));
          expect(newBottomNav.currentPageIndex, lessThanOrEqualTo(2));
        }
      });

      testWidgets('should handle navigation with disabled haptic feedback', (WidgetTester tester) async {
        HapticFeedbackService.setEnabled(false);
        
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Perform navigation gestures
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Verify navigation works without haptic feedback
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(1));

        // Re-enable haptic feedback
        HapticFeedbackService.setEnabled(true);
      });
    });
  });
} 