import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/widgets/enhanced_bottom_navigation.dart';
import 'package:splitease/models/navigation_page_configurations.dart';

void main() {
  group('EnhancedBottomNavigation', () {
    testWidgets('should display all navigation items', (WidgetTester tester) async {
      int selectedPageIndex = 0;
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EnhancedBottomNavigation(
              currentPageIndex: selectedPageIndex,
              onPageSelected: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Verify all navigation items are present
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Groups'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify the BottomNavigationBar is present
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should call onPageSelected when item is tapped', (WidgetTester tester) async {
      int selectedPageIndex = 0;
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EnhancedBottomNavigation(
              currentPageIndex: selectedPageIndex,
              onPageSelected: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Tap on the Groups tab (index 1)
      await tester.tap(find.text('Groups'));
      await tester.pump();

      // Verify the callback was called with the correct index
      expect(tappedIndex, equals(1));
    });

    testWidgets('should not call onPageSelected when tapping current page', (WidgetTester tester) async {
      int selectedPageIndex = 0;
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EnhancedBottomNavigation(
              currentPageIndex: selectedPageIndex,
              onPageSelected: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Tap on the Dashboard tab (current page, index 0)
      await tester.tap(find.text('Dashboard'));
      await tester.pump();

      // Verify the callback was not called
      expect(tappedIndex, isNull);
    });

    testWidgets('should not call onPageSelected when animating', (WidgetTester tester) async {
      int selectedPageIndex = 0;
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EnhancedBottomNavigation(
              currentPageIndex: selectedPageIndex,
              isAnimating: true, // Animation in progress
              onPageSelected: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Tap on the Groups tab (index 1)
      await tester.tap(find.text('Groups'));
      await tester.pump();

      // Verify the callback was not called due to animation in progress
      expect(tappedIndex, isNull);
    });

    testWidgets('should highlight the correct current page', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EnhancedBottomNavigation(
              currentPageIndex: 1, // Groups page selected
              onPageSelected: (index) {},
            ),
          ),
        ),
      );

      // Find the BottomNavigationBar widget
      final bottomNavBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      // Verify the current index is set correctly
      expect(bottomNavBar.currentIndex, equals(1));
    });
  });
}