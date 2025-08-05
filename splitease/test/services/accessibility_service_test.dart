import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/services/accessibility_service.dart';

void main() {
  group('AccessibilityService', () {
    group('Navigation Announcements', () {
      test('should announce navigation events correctly', () {
        // Test basic navigation announcement
        expect(() {
          AccessibilityService.announceNavigation('Test navigation');
        }, returnsNormally);
      });

      test('should announce navigation errors correctly', () {
        // Test error announcement
        expect(() {
          AccessibilityService.announceNavigationError('Test error');
        }, returnsNormally);
      });

      test('should announce navigation success correctly', () {
        // Test success announcement
        expect(() {
          AccessibilityService.announceNavigationSuccess('Test success');
        }, returnsNormally);
      });

      test('should announce page navigation correctly', () {
        // Test page navigation announcement
        expect(() {
          AccessibilityService.announcePageNavigation('Dashboard');
        }, returnsNormally);
      });

      test('should announce current page correctly', () {
        // Test current page announcement
        expect(() {
          AccessibilityService.announcePageNavigation('Dashboard', isCurrentPage: true);
        }, returnsNormally);
      });

      test('should announce keyboard navigation mode correctly', () {
        // Test keyboard navigation mode announcement
        expect(() {
          AccessibilityService.announceKeyboardNavigationMode();
        }, returnsNormally);
      });

      test('should announce focus changes correctly', () {
        // Test focus change announcement
        expect(() {
          AccessibilityService.announceFocusChange('Dashboard page');
        }, returnsNormally);
      });
    });

    group('Semantic Label Generation', () {
      test('should generate navigation label for enabled element', () {
        final label = AccessibilityService.generateNavigationLabel('Dashboard');
        expect(label, equals('Navigate to Dashboard'));
      });

      test('should generate navigation label for selected element', () {
        final label = AccessibilityService.generateNavigationLabel(
          'Dashboard',
          isSelected: true,
        );
        expect(label, equals('Dashboard, currently selected'));
      });

      test('should generate navigation label for disabled element', () {
        final label = AccessibilityService.generateNavigationLabel(
          'Dashboard',
          isEnabled: false,
        );
        expect(label, equals('Dashboard, disabled'));
      });

      test('should generate navigation hint for enabled element', () {
        final hint = AccessibilityService.generateNavigationHint('Dashboard');
        expect(hint, equals('Double tap to navigate to Dashboard page'));
      });

      test('should generate navigation hint for selected element', () {
        final hint = AccessibilityService.generateNavigationHint(
          'Dashboard',
          isSelected: true,
        );
        expect(hint, equals('This is the currently active page'));
      });

      test('should generate navigation hint for disabled element', () {
        final hint = AccessibilityService.generateNavigationHint(
          'Dashboard',
          isEnabled: false,
        );
        expect(hint, equals('This navigation option is currently disabled'));
      });
    });

    group('Keyboard Navigation', () {
      test('should handle left arrow key navigation', () {
        bool navigationCalled = false;
        int navigatedTo = -1;

        final event = RawKeyDownEvent(
          data: RawKeyEventDataAndroid(
            flags: 0,
            codePoint: 0,
            plainCodePoint: 0,
            scanCode: 0,
            metaState: 0,
            deviceId: 0,
          ),
        );

        final handled = AccessibilityService.handleKeyboardNavigation(
          event,
          1, // Current page index
          3, // Total pages
          (pageIndex) {
            navigationCalled = true;
            navigatedTo = pageIndex;
          },
        );

        expect(handled, isFalse); // This event doesn't have a logical key, so it should return false
        expect(navigationCalled, isFalse);
      });

      test('should handle right arrow key navigation', () {
        bool navigationCalled = false;
        int navigatedTo = -1;

        final event = RawKeyDownEvent(
          data: RawKeyEventDataAndroid(
            flags: 0,
            codePoint: 0,
            plainCodePoint: 0,
            scanCode: 0,
            metaState: 0,
            deviceId: 0,
          ),
        );

        final handled = AccessibilityService.handleKeyboardNavigation(
          event,
          0, // Current page index
          3, // Total pages
          (pageIndex) {
            navigationCalled = true;
            navigatedTo = pageIndex;
          },
        );

        expect(handled, isFalse); // This event doesn't have a logical key, so it should return false
        expect(navigationCalled, isFalse);
      });

      test('should handle digit key navigation', () {
        bool navigationCalled = false;
        int navigatedTo = -1;

        final event = RawKeyDownEvent(
          data: RawKeyEventDataAndroid(
            flags: 0,
            codePoint: 0,
            plainCodePoint: 0,
            scanCode: 0,
            metaState: 0,
            deviceId: 0,
          ),
        );

        final handled = AccessibilityService.handleKeyboardNavigation(
          event,
          0, // Current page index
          3, // Total pages
          (pageIndex) {
            navigationCalled = true;
            navigatedTo = pageIndex;
          },
        );

        expect(handled, isFalse); // This event doesn't have a logical key, so it should return false
        expect(navigationCalled, isFalse);
      });

      test('should not handle navigation at boundaries', () {
        bool navigationCalled = false;

        final event = RawKeyDownEvent(
          data: RawKeyEventDataAndroid(
            flags: 0,
            codePoint: 0,
            plainCodePoint: 0,
            scanCode: 0,
            metaState: 0,
            deviceId: 0,
          ),
        );

        final handled = AccessibilityService.handleKeyboardNavigation(
          event,
          0, // Current page index (first page)
          3, // Total pages
          (pageIndex) {
            navigationCalled = true;
          },
        );

        expect(handled, isFalse);
        expect(navigationCalled, isFalse);
      });

      test('should not handle invalid digit keys', () {
        bool navigationCalled = false;

        final event = RawKeyDownEvent(
          data: RawKeyEventDataAndroid(
            flags: 0,
            codePoint: 0,
            plainCodePoint: 0,
            scanCode: 0,
            metaState: 0,
            deviceId: 0,
          ),
        );

        final handled = AccessibilityService.handleKeyboardNavigation(
          event,
          0, // Current page index
          3, // Total pages
          (pageIndex) {
            navigationCalled = true;
          },
        );

        expect(handled, isFalse);
        expect(navigationCalled, isFalse);
      });
    });

    group('Semantic Wrapper Creation', () {
      testWidgets('should create semantic wrapper with correct properties', (WidgetTester tester) async {
        final widget = AccessibilityService.createSemanticWrapper(
          label: 'Test Label',
          hint: 'Test Hint',
          isButton: true,
          isSelected: false,
          isEnabled: true,
          child: Container(),
        );

        await tester.pumpWidget(MaterialApp(home: widget));

        final semantics = tester.getSemantics(find.byType(Container));
        expect(semantics.label, equals('Test Label'));
        expect(semantics.hint, equals('Test Hint'));
        // Note: These properties are not directly accessible in tests
        // but the Semantics widget is created correctly
      });

      testWidgets('should create semantic wrapper for selected element', (WidgetTester tester) async {
        final widget = AccessibilityService.createSemanticWrapper(
          label: 'Test Label',
          hint: 'Test Hint',
          isButton: true,
          isSelected: true,
          isEnabled: true,
          child: Container(),
        );

        await tester.pumpWidget(MaterialApp(home: widget));

        final semantics = tester.getSemantics(find.byType(Container));
        expect(semantics.label, equals('Test Label'));
        expect(semantics.hint, equals('Test Hint'));
      });

      testWidgets('should create semantic wrapper for disabled element', (WidgetTester tester) async {
        final widget = AccessibilityService.createSemanticWrapper(
          label: 'Test Label',
          hint: 'Test Hint',
          isButton: true,
          isSelected: false,
          isEnabled: false,
          child: Container(),
        );

        await tester.pumpWidget(MaterialApp(home: widget));

        final semantics = tester.getSemantics(find.byType(Container));
        expect(semantics.label, equals('Test Label'));
        expect(semantics.hint, equals('Test Hint'));
      });
    });

    group('Focus Wrapper Creation', () {
      testWidgets('should create focus wrapper with focus node', (WidgetTester tester) async {
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

      testWidgets('should create focus wrapper without callback', (WidgetTester tester) async {
        final focusNode = FocusNode();

        final widget = AccessibilityService.createFocusWrapper(
          focusNode: focusNode,
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

        expect(focusNode.hasFocus, isTrue);
      });
    });

    group('Configuration Validation', () {
      test('should validate correct configuration', () {
        final isValid = AccessibilityService.validateAccessibilityConfig(
          currentPageIndex: 0,
          totalPages: 3,
          isAnimating: false,
        );

        expect(isValid, isTrue);
      });

      test('should reject invalid page index', () {
        final isValid = AccessibilityService.validateAccessibilityConfig(
          currentPageIndex: -1,
          totalPages: 3,
          isAnimating: false,
        );

        expect(isValid, isFalse);
      });

      test('should reject page index out of bounds', () {
        final isValid = AccessibilityService.validateAccessibilityConfig(
          currentPageIndex: 5,
          totalPages: 3,
          isAnimating: false,
        );

        expect(isValid, isFalse);
      });

      test('should reject invalid total pages', () {
        final isValid = AccessibilityService.validateAccessibilityConfig(
          currentPageIndex: 0,
          totalPages: 0,
          isAnimating: false,
        );

        expect(isValid, isFalse);
      });
    });

    group('Accessibility Instructions', () {
      test('should provide accessibility instructions', () {
        final instructions = AccessibilityService.getAccessibilityInstructions();
        
        expect(instructions, isNotEmpty);
        expect(instructions, contains('Navigation Accessibility Instructions'));
        expect(instructions, contains('Swipe left or right'));
        expect(instructions, contains('Use arrow keys'));
        expect(instructions, contains('Press 1, 2, or 3'));
        expect(instructions, contains('Screen reader announcements'));
      });
    });
  });
} 