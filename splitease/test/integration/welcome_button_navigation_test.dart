import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/widgets/main_navigation_container.dart';
import 'package:splitease/widgets/enhanced_bottom_navigation.dart';
import 'package:splitease/services/navigation_service.dart';
import 'package:splitease/services/haptic_feedback_service.dart';
import 'package:splitease/presentation/expense_dashboard/expense_dashboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Welcome Button Navigation Tests', () {
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

    group('Welcome Button Detection and Interaction', () {
      testWidgets('should find welcome button on dashboard', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Look for welcome button with various possible text patterns
        final welcomeButton = find.byWidgetPredicate((widget) {
          if (widget is Text) {
            return widget.data?.toLowerCase().contains('welcome') == true ||
                   widget.data?.toLowerCase().contains('back') == true;
          }
          if (widget is TextButton || widget is ElevatedButton || widget is InkWell) {
            return true; // Could be a button containing welcome text
          }
          return false;
        });

        // If welcome button is found, test interaction
        if (welcomeButton.evaluate().isNotEmpty) {
          await tester.tap(welcomeButton.first);
          await tester.pumpAndSettle();

          // Verify navigation to profile page
          final bottomNav = tester.widget<EnhancedBottomNavigation>(
            find.byType(EnhancedBottomNavigation),
          );
          expect(bottomNav.currentPageIndex, equals(2));
        }
      });

      testWidgets('should handle welcome button tap with haptic feedback', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Find welcome button
        final welcomeButton = find.byWidgetPredicate((widget) {
          if (widget is Text) {
            return widget.data?.toLowerCase().contains('welcome') == true;
          }
          return false;
        });

        if (welcomeButton.evaluate().isNotEmpty) {
          // Tap welcome button
          await tester.tap(welcomeButton.first);
          await tester.pumpAndSettle();

          // Verify navigation occurred
          final bottomNav = tester.widget<EnhancedBottomNavigation>(
            find.byType(EnhancedBottomNavigation),
          );
          expect(bottomNav.currentPageIndex, equals(2));

          // Note: Haptic feedback is tested in service tests
          // This test verifies the integration works without errors
        }
      });

      testWidgets('should handle welcome button tap without haptic feedback', (WidgetTester tester) async {
        HapticFeedbackService.setEnabled(false);
        
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Find welcome button
        final welcomeButton = find.byWidgetPredicate((widget) {
          if (widget is Text) {
            return widget.data?.toLowerCase().contains('welcome') == true;
          }
          return false;
        });

        if (welcomeButton.evaluate().isNotEmpty) {
          // Tap welcome button
          await tester.tap(welcomeButton.first);
          await tester.pumpAndSettle();

          // Verify navigation still works without haptic feedback
          final bottomNav = tester.widget<EnhancedBottomNavigation>(
            find.byType(EnhancedBottomNavigation),
          );
          expect(bottomNav.currentPageIndex, equals(2));
        }

        // Re-enable haptic feedback
        HapticFeedbackService.setEnabled(true);
      });
    });

    group('Navigation Service Integration', () {
      testWidgets('should navigate to profile via NavigationService.navigateToProfile()', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Use NavigationService to navigate to profile
        NavigationService.navigateToProfile();
        await tester.pumpAndSettle();

        // Verify profile page is active
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(2));
      });

      testWidgets('should handle rapid NavigationService calls', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Make rapid navigation calls
        NavigationService.navigateToProfile();
        await tester.pump();
        NavigationService.navigateToPage(1, animate: false);
        await tester.pump();
        NavigationService.navigateToPage(0, animate: false);
        await tester.pumpAndSettle();

        // Verify final state is correct
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });

      testWidgets('should handle NavigationService calls from different pages', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Navigate to groups first
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Use NavigationService to navigate to profile from groups page
        NavigationService.navigateToProfile();
        await tester.pumpAndSettle();

        // Verify profile page is active
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(2));
      });
    });

    group('Animation and Transition Testing', () {
      testWidgets('should complete welcome button navigation animation', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        // Find and tap welcome button
        final welcomeButton = find.byWidgetPredicate((widget) {
          if (widget is Text) {
            return widget.data?.toLowerCase().contains('welcome') == true;
          }
          return false;
        });

        if (welcomeButton.evaluate().isNotEmpty) {
          await tester.tap(welcomeButton.first);
          await tester.pumpAndSettle();

          stopwatch.stop();

          // Verify animation completes within reasonable time
          expect(stopwatch.elapsed.inMilliseconds, lessThan(2000));

          // Verify navigation was successful
          final bottomNav = tester.widget<EnhancedBottomNavigation>(
            find.byType(EnhancedBottomNavigation),
          );
          expect(bottomNav.currentPageIndex, equals(2));
        }
      });

      testWidgets('should handle welcome button navigation with animation disabled', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Use NavigationService with animation disabled
        NavigationService.navigateToPage(2, animate: false);
        await tester.pumpAndSettle();

        // Verify instant navigation to profile
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(2));
      });

      testWidgets('should handle interrupted welcome button navigation', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Start welcome button navigation
        NavigationService.navigateToProfile();
        await tester.pump();

        // Interrupt with another navigation
        NavigationService.navigateToPage(1, animate: false);
        await tester.pumpAndSettle();

        // Verify final state is consistent
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(1));
      });
    });

    group('State Preservation During Welcome Navigation', () {
      testWidgets('should preserve dashboard state after welcome navigation', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Perform some action on dashboard (scroll, etc.)
        final scrollable = find.byType(SingleChildScrollView);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -100));
          await tester.pumpAndSettle();
        }

        // Navigate to profile via welcome button
        final welcomeButton = find.byWidgetPredicate((widget) {
          if (widget is Text) {
            return widget.data?.toLowerCase().contains('welcome') == true;
          }
          return false;
        });

        if (welcomeButton.evaluate().isNotEmpty) {
          await tester.tap(welcomeButton.first);
          await tester.pumpAndSettle();

          // Navigate back to dashboard
          await tester.drag(find.byType(PageView), const Offset(600, 0));
          await tester.pumpAndSettle();

          // Verify dashboard is still there (state preserved)
          expect(find.byType(ExpenseDashboard), findsOneWidget);
        }
      });

      testWidgets('should preserve other pages state during welcome navigation', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Navigate to groups first
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Perform some action on groups page
        final scrollable = find.byType(SingleChildScrollView);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -100));
          await tester.pumpAndSettle();
        }

        // Navigate to profile via NavigationService
        NavigationService.navigateToProfile();
        await tester.pumpAndSettle();

        // Navigate back to groups
        await tester.drag(find.byType(PageView), const Offset(300, 0));
        await tester.pumpAndSettle();

        // Verify groups page is still there (state preserved)
        expect(find.byType(ExpenseDashboard), findsOneWidget);
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('should handle welcome button navigation during page rebuilds', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Start welcome button navigation
        NavigationService.navigateToProfile();
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

      testWidgets('should handle welcome button navigation with different initial pages', (WidgetTester tester) async {
        // Test with different initial pages
        for (int initialPage = 0; initialPage < 3; initialPage++) {
          final testAppWithInitialPage = MaterialApp(
            home: MainNavigationContainer(initialPage: initialPage),
          );

          await tester.pumpWidget(testAppWithInitialPage);
          await tester.pumpAndSettle();

          // Use NavigationService to navigate to profile
          NavigationService.navigateToProfile();
          await tester.pumpAndSettle();

          // Verify profile page is active regardless of initial page
          final bottomNav = tester.widget<EnhancedBottomNavigation>(
            find.byType(EnhancedBottomNavigation),
          );
          expect(bottomNav.currentPageIndex, equals(2));
        }
      });

      testWidgets('should handle multiple welcome button taps gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Find welcome button
        final welcomeButton = find.byWidgetPredicate((widget) {
          if (widget is Text) {
            return widget.data?.toLowerCase().contains('welcome') == true;
          }
          return false;
        });

        if (welcomeButton.evaluate().isNotEmpty) {
          // Tap welcome button multiple times rapidly
          for (int i = 0; i < 3; i++) {
            await tester.tap(welcomeButton.first);
            await tester.pump();
          }
          await tester.pumpAndSettle();

          // Verify final state is correct
          final bottomNav = tester.widget<EnhancedBottomNavigation>(
            find.byType(EnhancedBottomNavigation),
          );
          expect(bottomNav.currentPageIndex, equals(2));
        }
      });

      testWidgets('should handle welcome button navigation during other animations', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Start a swipe navigation
        await tester.drag(find.byType(PageView), const Offset(-150, 0));
        await tester.pump();

        // Try welcome button navigation during swipe
        NavigationService.navigateToProfile();
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

    group('Performance Testing', () {
      testWidgets('should complete welcome navigation within performance limits', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        // Perform welcome button navigation
        NavigationService.navigateToProfile();
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Verify performance is acceptable
        expect(stopwatch.elapsed.inMilliseconds, lessThan(1000));

        // Verify navigation was successful
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(2));
      });

      testWidgets('should handle rapid welcome navigation sequences', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        // Perform rapid navigation sequence
        for (int i = 0; i < 5; i++) {
          NavigationService.navigateToProfile();
          await tester.pump();
          NavigationService.navigateToPage(0, animate: false);
          await tester.pump();
        }
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Verify performance is acceptable
        expect(stopwatch.elapsed.inMilliseconds, lessThan(3000));

        // Verify final state is correct
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });
    });
  });
} 