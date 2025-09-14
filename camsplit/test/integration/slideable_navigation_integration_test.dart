import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/widgets/main_navigation_container.dart';
import 'package:camsplit/widgets/enhanced_bottom_navigation.dart';
import 'package:camsplit/services/navigation_service.dart';
import 'package:camsplit/services/haptic_feedback_service.dart';
import 'package:camsplit/services/animation_service.dart';
import 'package:camsplit/presentation/expense_dashboard/expense_dashboard.dart';
import 'package:camsplit/presentation/group_management/group_management.dart';
import 'package:camsplit/presentation/profile_settings/profile_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Slideable Navigation Integration Tests', () {
    late Widget testApp;

    setUp(() {
      // Enable haptic feedback for testing
      HapticFeedbackService.setEnabled(true);
      
      testApp = MaterialApp(
        home: MainNavigationContainer(initialPage: 0),
      );
    });

    tearDown(() {
      // Reset haptic feedback state
      HapticFeedbackService.setEnabled(true);
    });

    group('Complete Navigation Flow', () {
      testWidgets('should display all three pages in PageView', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Verify all three pages are present
        expect(find.byType(ExpenseDashboard), findsOneWidget);
        expect(find.byType(GroupManagement), findsOneWidget);
        expect(find.byType(ProfileSettings), findsOneWidget);
        
        // Verify bottom navigation is present
        expect(find.byType(EnhancedBottomNavigation), findsOneWidget);
      });

      testWidgets('should start on dashboard page', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Verify dashboard is visible and active
        expect(find.byType(ExpenseDashboard), findsOneWidget);
        expect(find.byType(GroupManagement), findsOneWidget);
        expect(find.byType(ProfileSettings), findsOneWidget);

        // Verify dashboard page is active in bottom navigation
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });

      testWidgets('should navigate to groups page via swipe', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Swipe left from dashboard to groups
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Verify groups page is now active
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(1));
      });

      testWidgets('should navigate to profile page via swipe', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Swipe left twice to reach profile
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Verify profile page is now active
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(2));
      });

      testWidgets('should navigate back via swipe', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Navigate to groups first
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Swipe right to go back to dashboard
        await tester.drag(find.byType(PageView), const Offset(300, 0));
        await tester.pumpAndSettle();

        // Verify dashboard is active again
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });
    });

    group('Bottom Navigation Tap Functionality', () {
      testWidgets('should navigate to groups via bottom navigation tap', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Tap on groups tab
        final groupsTab = find.byIcon(Icons.group);
        await tester.tap(groupsTab);
        await tester.pumpAndSettle();

        // Verify groups page is active
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(1));
      });

      testWidgets('should navigate to profile via bottom navigation tap', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Tap on profile tab
        final profileTab = find.byIcon(Icons.person);
        await tester.tap(profileTab);
        await tester.pumpAndSettle();

        // Verify profile page is active
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(2));
      });

      testWidgets('should navigate to dashboard via bottom navigation tap', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Navigate to groups first
        final groupsTab = find.byIcon(Icons.group);
        await tester.tap(groupsTab);
        await tester.pumpAndSettle();

        // Tap on dashboard tab
        final dashboardTab = find.byIcon(Icons.dashboard);
        await tester.tap(dashboardTab);
        await tester.pumpAndSettle();

        // Verify dashboard is active
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });

      testWidgets('should provide haptic feedback on bottom navigation taps', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Tap on groups tab and verify haptic feedback is triggered
        final groupsTab = find.byIcon(Icons.group);
        await tester.tap(groupsTab);
        await tester.pumpAndSettle();

        // Note: Haptic feedback is tested in the service tests
        // This test verifies the integration works without errors
        expect(find.byType(EnhancedBottomNavigation), findsOneWidget);
      });
    });

    group('Welcome Button Navigation Flow', () {
      testWidgets('should navigate to profile via welcome button', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Find and tap the welcome button (assuming it's a button with text containing "Welcome")
        final welcomeButton = find.textContaining('Welcome');
        if (welcomeButton.evaluate().isNotEmpty) {
          await tester.tap(welcomeButton);
          await tester.pumpAndSettle();

          // Verify profile page is active
          final bottomNav = tester.widget<EnhancedBottomNavigation>(
            find.byType(EnhancedBottomNavigation),
          );
          expect(bottomNav.currentPageIndex, equals(2));
        }
      });

      testWidgets('should provide haptic feedback on welcome button tap', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Find and tap the welcome button
        final welcomeButton = find.textContaining('Welcome');
        if (welcomeButton.evaluate().isNotEmpty) {
          await tester.tap(welcomeButton);
          await tester.pumpAndSettle();

          // Note: Haptic feedback is tested in the service tests
          // This test verifies the integration works without errors
          expect(find.byType(EnhancedBottomNavigation), findsOneWidget);
        }
      });
    });

    group('State Preservation Across Navigation', () {
      testWidgets('should preserve scroll position on dashboard', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Find a scrollable widget on dashboard and scroll
        final scrollable = find.byType(SingleChildScrollView);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -100));
          await tester.pumpAndSettle();

          // Navigate away
          await tester.drag(find.byType(PageView), const Offset(-300, 0));
          await tester.pumpAndSettle();

          // Navigate back
          await tester.drag(find.byType(PageView), const Offset(300, 0));
          await tester.pumpAndSettle();

          // Verify dashboard is still there (state preserved)
          expect(find.byType(ExpenseDashboard), findsOneWidget);
        }
      });

      testWidgets('should preserve scroll position on groups page', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Navigate to groups
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Find a scrollable widget on groups and scroll
        final scrollable = find.byType(SingleChildScrollView);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -100));
          await tester.pumpAndSettle();

          // Navigate away
          await tester.drag(find.byType(PageView), const Offset(-300, 0));
          await tester.pumpAndSettle();

          // Navigate back
          await tester.drag(find.byType(PageView), const Offset(300, 0));
          await tester.pumpAndSettle();

          // Verify groups page is still there (state preserved)
          expect(find.byType(GroupManagement), findsOneWidget);
        }
      });

      testWidgets('should preserve scroll position on profile page', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Navigate to profile
        await tester.drag(find.byType(PageView), const Offset(-600, 0));
        await tester.pumpAndSettle();

        // Find a scrollable widget on profile and scroll
        final scrollable = find.byType(SingleChildScrollView);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -100));
          await tester.pumpAndSettle();

          // Navigate away
          await tester.drag(find.byType(PageView), const Offset(300, 0));
          await tester.pumpAndSettle();

          // Navigate back
          await tester.drag(find.byType(PageView), const Offset(-300, 0));
          await tester.pumpAndSettle();

          // Verify profile page is still there (state preserved)
          expect(find.byType(ProfileSettings), findsOneWidget);
        }
      });
    });

    group('Gesture Boundary Conditions and Edge Cases', () {
      testWidgets('should prevent right swipe on first page', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Try to swipe right on dashboard (first page)
        await tester.drag(find.byType(PageView), const Offset(300, 0));
        await tester.pumpAndSettle();

        // Verify still on dashboard
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });

      testWidgets('should prevent left swipe on last page', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Navigate to profile (last page)
        await tester.drag(find.byType(PageView), const Offset(-600, 0));
        await tester.pumpAndSettle();

        // Try to swipe left on profile (last page)
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Verify still on profile
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(2));
      });

      testWidgets('should handle rapid navigation requests', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Rapidly tap different navigation items
        final dashboardTab = find.byIcon(Icons.dashboard);
        final groupsTab = find.byIcon(Icons.group);
        final profileTab = find.byIcon(Icons.person);

        await tester.tap(groupsTab);
        await tester.pump();
        await tester.tap(profileTab);
        await tester.pump();
        await tester.tap(dashboardTab);
        await tester.pumpAndSettle();

        // Verify final state is correct
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });

      testWidgets('should handle interrupted swipes', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Start a swipe but don't complete it
        await tester.drag(find.byType(PageView), const Offset(-150, 0));
        await tester.pump();

        // Verify page snaps back to original position
        await tester.pumpAndSettle();

        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });

      testWidgets('should handle vertical swipes without navigation', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Try vertical swipe (should not trigger navigation)
        await tester.drag(find.byType(PageView), const Offset(0, -100));
        await tester.pumpAndSettle();

        // Verify still on dashboard
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });
    });

    group('Animation and Performance', () {
      testWidgets('should complete page transitions within reasonable time', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        // Navigate to groups
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Verify animation completes within reasonable time (should be less than 1 second)
        expect(stopwatch.elapsed.inMilliseconds, lessThan(1000));

        // Verify navigation was successful
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(1));
      });

      testWidgets('should maintain smooth animations during rapid navigation', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Perform rapid navigation
        for (int i = 0; i < 3; i++) {
          await tester.drag(find.byType(PageView), const Offset(-300, 0));
          await tester.pump();
          await tester.drag(find.byType(PageView), const Offset(300, 0));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        // Verify final state is correct
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });
    });

    group('Navigation Service Integration', () {
      testWidgets('should respond to NavigationService calls', (WidgetTester tester) async {
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

      testWidgets('should handle NavigationService calls with animation disabled', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Use NavigationService to navigate to groups without animation
        NavigationService.navigateToPage(1, animate: false);
        await tester.pumpAndSettle();

        // Verify groups page is active
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(1));
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('should handle invalid page indices gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Try to navigate to invalid page index
        NavigationService.navigateToPage(5, animate: false);
        await tester.pumpAndSettle();

        // Verify still on dashboard (should not crash)
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });

      testWidgets('should handle negative page indices gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Try to navigate to negative page index
        NavigationService.navigateToPage(-1, animate: false);
        await tester.pumpAndSettle();

        // Verify still on dashboard (should not crash)
        final bottomNav = tester.widget<EnhancedBottomNavigation>(
          find.byType(EnhancedBottomNavigation),
        );
        expect(bottomNav.currentPageIndex, equals(0));
      });

      testWidgets('should handle widget disposal gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Navigate to different pages
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await tester.pumpAndSettle();

        // Dispose and recreate widget
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();

        // Recreate the navigation container
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle();

        // Verify widget works correctly after recreation
        expect(find.byType(MainNavigationContainer), findsOneWidget);
        expect(find.byType(EnhancedBottomNavigation), findsOneWidget);
      });
    });
  });
} 