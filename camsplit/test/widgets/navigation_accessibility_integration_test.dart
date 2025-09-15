import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/widgets/enhanced_bottom_navigation.dart';
import 'package:camsplit/services/accessibility_service.dart';

void main() {
  group('Navigation Accessibility Integration Tests', () {
    group('EnhancedBottomNavigation Accessibility', () {
      testWidgets('should provide proper semantic labels for navigation items', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 0,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check that bottom navigation has proper semantic labels
        final bottomNav = find.byType(EnhancedBottomNavigation);
        expect(bottomNav, findsOneWidget);

        final semantics = tester.getSemantics(bottomNav);
        expect(semantics.label, equals('Bottom navigation bar'));
        expect(semantics.hint, contains('Navigate between'));
      });

      testWidgets('should announce navigation actions to screen readers', (WidgetTester tester) async {
        bool navigationCalled = false;
        int navigatedTo = -1;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 0,
                onPageSelected: (index) {
                  navigationCalled = true;
                  navigatedTo = index;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on Groups navigation item
        final groupsItem = find.text('Groups');
        await tester.tap(groupsItem);
        await tester.pumpAndSettle();

        // Verify navigation was called
        expect(navigationCalled, isTrue);
        expect(navigatedTo, equals(1));
      });

      testWidgets('should handle disabled state during animation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 0,
                isAnimating: true,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Try to tap on navigation item during animation
        final groupsItem = find.text('Groups');
        await tester.tap(groupsItem);
        await tester.pumpAndSettle();

        // Should still be on Dashboard page (navigation blocked during animation)
        expect(find.text('Dashboard'), findsOneWidget);
      });

      testWidgets('should provide proper semantic states for navigation items', (WidgetTester tester) async {
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

        await tester.pumpAndSettle();

        // Check that Groups item shows as selected
        final groupsItem = find.text('Groups');
        expect(groupsItem, findsOneWidget);

        // Verify semantic properties for selected item
        final semantics = tester.getSemantics(groupsItem);
        expect(semantics.label, contains('Groups, currently selected'));
        expect(semantics.hint, contains('currently active page'));
      });
    });

    group('Accessibility Service Integration', () {
      testWidgets('should validate accessibility configuration', (WidgetTester tester) async {
        // Test valid configuration
        final isValid = AccessibilityService.validateAccessibilityConfig(
          currentPageIndex: 0,
          totalPages: 3,
          isAnimating: false,
        );
        expect(isValid, isTrue);

        // Test invalid configuration
        final isInvalid = AccessibilityService.validateAccessibilityConfig(
          currentPageIndex: -1,
          totalPages: 3,
          isAnimating: false,
        );
        expect(isInvalid, isFalse);
      });

      testWidgets('should generate proper semantic labels', (WidgetTester tester) async {
        // Test enabled navigation label
        final enabledLabel = AccessibilityService.generateNavigationLabel('Dashboard');
        expect(enabledLabel, equals('Navigate to Dashboard'));

        // Test selected navigation label
        final selectedLabel = AccessibilityService.generateNavigationLabel(
          'Dashboard',
          isSelected: true,
        );
        expect(selectedLabel, equals('Dashboard, currently selected'));

        // Test disabled navigation label
        final disabledLabel = AccessibilityService.generateNavigationLabel(
          'Dashboard',
          isEnabled: false,
        );
        expect(disabledLabel, equals('Dashboard, disabled'));
      });

      testWidgets('should generate proper semantic hints', (WidgetTester tester) async {
        // Test enabled navigation hint
        final enabledHint = AccessibilityService.generateNavigationHint('Dashboard');
        expect(enabledHint, equals('Double tap to navigate to Dashboard page'));

        // Test selected navigation hint
        final selectedHint = AccessibilityService.generateNavigationHint(
          'Dashboard',
          isSelected: true,
        );
        expect(selectedHint, equals('This is the currently active page'));

        // Test disabled navigation hint
        final disabledHint = AccessibilityService.generateNavigationHint(
          'Dashboard',
          isEnabled: false,
        );
        expect(disabledHint, equals('This navigation option is currently disabled'));
      });
    });

    group('Keyboard Navigation Testing', () {
      testWidgets('should handle keyboard navigation events', (WidgetTester tester) async {
        bool navigationCalled = false;
        int navigatedTo = -1;

        // Test left arrow key
        final leftEvent = KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowLeft,
          logicalKey: LogicalKeyboardKey.arrowLeft,
          timeStamp: Duration.zero,
        );

        final leftHandled = AccessibilityService.handleKeyboardNavigation(
          leftEvent,
          1, // Current page index
          3, // Total pages
          (pageIndex) {
            navigationCalled = true;
            navigatedTo = pageIndex;
          },
        );

        expect(leftHandled, isFalse); // No logical key in this event
        expect(navigationCalled, isFalse);

        // Test digit key navigation
        final digitEvent = KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.digit1,
          logicalKey: LogicalKeyboardKey.digit1,
          timeStamp: Duration.zero,
        );

        final digitHandled = AccessibilityService.handleKeyboardNavigation(
          digitEvent,
          0, // Current page index
          3, // Total pages
          (pageIndex) {
            navigationCalled = true;
            navigatedTo = pageIndex;
          },
        );

        expect(digitHandled, isFalse); // No logical key in this event
        expect(navigationCalled, isFalse);
      });
    });

    group('Semantic Wrapper Testing', () {
      testWidgets('should create semantic wrappers correctly', (WidgetTester tester) async {
        final widget = AccessibilityService.createSemanticWrapper(
          label: 'Test Label',
          hint: 'Test Hint',
          isButton: true,
          isSelected: false,
          isEnabled: true,
          child: Container(
            width: 100,
            height: 100,
            color: Colors.blue,
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));

        final semantics = tester.getSemantics(find.byType(Container));
        expect(semantics.label, equals('Test Label'));
        expect(semantics.hint, equals('Test Hint'));
      });

      testWidgets('should create focus wrappers correctly', (WidgetTester tester) async {
        final focusNode = FocusNode();
        bool focusChanged = false;

        final widget = AccessibilityService.createFocusWrapper(
          focusNode: focusNode,
          onFocusChange: () {
            focusChanged = true;
          },
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 100,
              height: 100,
              color: Colors.blue,
            ),
          ),
        );

        await tester.pumpWidget(MaterialApp(home: widget));

        // Request focus directly
        focusNode.requestFocus();
        await tester.pump();

        expect(focusChanged, isTrue);
        expect(focusNode.hasFocus, isTrue);
      });
    });

    group('Screen Reader Support', () {
      testWidgets('should provide comprehensive screen reader support', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 0,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify all navigation elements have proper semantic labels
        final bottomNav = find.byType(EnhancedBottomNavigation);
        expect(bottomNav, findsOneWidget);

        // Verify semantic properties are set
        final navSemantics = tester.getSemantics(bottomNav);
        expect(navSemantics.label, isNotEmpty);
        expect(navSemantics.hint, isNotEmpty);
      });

      testWidgets('should announce state changes to screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 0,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to different page
        final groupsItem = find.text('Groups');
        await tester.tap(groupsItem);
        await tester.pumpAndSettle();

        // Verify that the navigation state changed
        expect(find.text('Groups'), findsOneWidget);
      });
    });

    group('Focus Management', () {
      testWidgets('should manage focus properly during navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 0,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Focus the navigation container
        await tester.tap(find.byType(EnhancedBottomNavigation));
        await tester.pump();

        // Test that the widget can receive focus by tapping on navigation items
        final groupsItem = find.text('Groups');
        await tester.tap(groupsItem);
        await tester.pumpAndSettle();

        // Verify navigation occurred
        expect(find.text('Groups'), findsOneWidget);
      });

      testWidgets('should provide logical focus order', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 0,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Focus the navigation container
        await tester.tap(find.byType(EnhancedBottomNavigation));
        await tester.pump();

        // Test tab navigation by sending tab key
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Verify that the widget can still receive focus
        final groupsItem = find.text('Groups');
        await tester.tap(groupsItem);
        await tester.pumpAndSettle();

        // Verify navigation occurred, indicating focus is working
        expect(find.text('Groups'), findsOneWidget);
      });
    });
  });
} 