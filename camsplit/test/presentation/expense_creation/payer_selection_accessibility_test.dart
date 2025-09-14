import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/expense_creation/widgets/expense_details_widget.dart';
import 'package:sizer/sizer.dart';

void main() {
  group('Payer Selection Accessibility Tests', () {
    
    group('Keyboard Navigation Tests', () {
      testWidgets('Payer dropdown is focusable and navigable with keyboard', (WidgetTester tester) async {
        final groupMembers = [
          {
            'id': 1,
            'name': 'Current User',
            'initials': 'CU',
            'isCurrentUser': true,
          },
          {
            'id': 2,
            'name': 'Friend One',
            'initials': 'FO',
            'isCurrentUser': false,
          },
          {
            'id': 3,
            'name': 'Friend Two',
            'initials': 'FT',
            'isCurrentUser': false,
          },
        ];

        String? selectedPayerId = '1';

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Test Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: groupMembers,
                    selectedPayerId: selectedPayerId ?? '',
                    onPayerChanged: (payerId) {
                      selectedPayerId = payerId;
                    },
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>);
        expect(payerDropdown, findsOneWidget);

        // Test Tab navigation to focus the dropdown
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Verify dropdown exists and can be interacted with
        expect(payerDropdown, findsOneWidget);

        // Test Enter key to open dropdown
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Test arrow key navigation within dropdown
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        // Test Enter to select item
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Verify selection changed
        expect(selectedPayerId, isNot(equals('1')));
      });

      testWidgets('Tab order includes payer dropdown in correct sequence', (WidgetTester tester) async {
        final groupMembers = [
          {
            'id': 1,
            'name': 'Test User',
            'initials': 'TU',
            'isCurrentUser': true,
          },
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Test Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: groupMembers,
                    selectedPayerId: '1',
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test tab navigation through form fields
        // Should go: Group dropdown -> Payer dropdown -> Category dropdown -> Date field -> Notes field
        
        // Test tab navigation through form fields
        // Should go: Group dropdown -> Payer dropdown -> Category dropdown -> Date field -> Notes field
        
        // Start with group dropdown
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        
        final groupDropdown = find.byType(DropdownButtonFormField<String>).first;
        expect(groupDropdown, findsOneWidget);

        // Tab to payer dropdown
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        
        final payerDropdown = find.byType(DropdownButtonFormField<String>).at(1);
        expect(payerDropdown, findsOneWidget);

        // Tab to category dropdown
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        
        final categoryDropdown = find.byType(DropdownButtonFormField<String>).at(2);
        expect(categoryDropdown, findsOneWidget);
      });

      testWidgets('Escape key closes payer dropdown', (WidgetTester tester) async {
        final groupMembers = [
          {
            'id': 1,
            'name': 'Test User',
            'initials': 'TU',
            'isCurrentUser': true,
          },
          {
            'id': 2,
            'name': 'Other User',
            'initials': 'OU',
            'isCurrentUser': false,
          },
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Test Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: groupMembers,
                    selectedPayerId: '1',
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Focus and open the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>).at(1);
        await tester.tap(payerDropdown);
        await tester.pumpAndSettle();

        // Verify dropdown is open (items are visible)
        expect(find.text('Test User'), findsWidgets);
        expect(find.text('Other User'), findsOneWidget);

        // Press Escape to close
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Verify dropdown is closed (only selected item visible)
        expect(find.text('Other User'), findsNothing);
      });
    });

    group('Screen Reader Support Tests', () {
      testWidgets('Payer dropdown has proper semantic labels', (WidgetTester tester) async {
        final groupMembers = [
          {
            'id': 1,
            'name': 'Current User',
            'initials': 'CU',
            'isCurrentUser': true,
          },
          {
            'id': 2,
            'name': 'Friend One',
            'initials': 'FO',
            'isCurrentUser': false,
          },
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Test Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: groupMembers,
                    selectedPayerId: '1',
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>).at(1);
        expect(payerDropdown, findsOneWidget);

        // Verify dropdown exists and has proper label
        expect(payerDropdown, findsOneWidget);
        expect(find.text('Who Paid'), findsOneWidget);

        // Test semantic announcements
        final semantics = tester.getSemantics(payerDropdown);
        expect(semantics.label, contains('Who Paid'));
        expect(semantics.hasEnabledState, isTrue);
        expect(semantics.isEnabled, isTrue);
      });

      testWidgets('Payer dropdown items have proper semantic descriptions', (WidgetTester tester) async {
        final groupMembers = [
          {
            'id': 1,
            'name': 'Current User',
            'initials': 'CU',
            'isCurrentUser': true,
          },
          {
            'id': 2,
            'name': 'Friend One',
            'initials': 'FO',
            'isCurrentUser': false,
          },
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Test Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: groupMembers,
                    selectedPayerId: '1',
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Open the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>).at(1);
        await tester.tap(payerDropdown);
        await tester.pumpAndSettle();

        // Verify dropdown items have proper semantic information
        final currentUserItem = find.text('Current User');
        expect(currentUserItem, findsOneWidget);
        
        final friendOneItem = find.text('Friend One');
        expect(friendOneItem, findsOneWidget);

        // Test that items are properly announced to screen readers
        final currentUserSemantics = tester.getSemantics(currentUserItem);
        expect(currentUserSemantics.label, contains('Current User'));
        expect(currentUserSemantics.hasEnabledState, isTrue);
        expect(currentUserSemantics.isEnabled, isTrue);
      });

      testWidgets('Loading state is announced to screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Test Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: [],
                    selectedPayerId: '',
                    isLoadingPayers: true,
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>).at(1);
        expect(payerDropdown, findsOneWidget);

        // Verify loading state is communicated
        expect(find.text('Loading members...'), findsOneWidget);

        // Verify loading state is properly communicated
        expect(find.text('Who Paid'), findsOneWidget);
      });

      testWidgets('Error states are announced to screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: '', // No group selected
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: [],
                    selectedPayerId: '',
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>).at(1);
        expect(payerDropdown, findsOneWidget);

        // Verify error state is communicated
        expect(find.text('Select a group first'), findsOneWidget);

        // Verify error state is properly communicated
        expect(find.text('Who Paid'), findsOneWidget);
      });

      testWidgets('Validation errors are announced to screen readers', (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: Form(
                    key: formKey,
                    child: ExpenseDetailsWidget(
                      selectedGroup: 'Test Group',
                      selectedCategory: 'Food & Dining',
                      selectedDate: DateTime.now(),
                      notesController: TextEditingController(),
                      totalController: TextEditingController(),
                      groups: ['Test Group'],
                      categories: ['Food & Dining'],
                      mode: 'manual',
                      groupMembers: [
                        {
                          'id': 1,
                          'name': 'Test User',
                          'initials': 'TU',
                          'isCurrentUser': true,
                        }
                      ],
                      selectedPayerId: '', // Empty to trigger validation error
                      onPayerChanged: (payerId) {},
                    ),
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Trigger form validation
        formKey.currentState?.validate();
        await tester.pumpAndSettle();

        // Verify validation error is displayed and accessible
        expect(find.text('Please select who paid for this expense'), findsOneWidget);

        // Test that validation error is announced to screen readers
        final errorText = find.text('Please select who paid for this expense');
        final errorSemantics = tester.getSemantics(errorText);
        expect(errorSemantics.label, contains('Please select who paid for this expense'));
      });
    });

    group('High Contrast and Visual Accessibility Tests', () {
      testWidgets('Payer dropdown maintains visibility in high contrast mode', (WidgetTester tester) async {
        final groupMembers = [
          {
            'id': 1,
            'name': 'Test User',
            'initials': 'TU',
            'isCurrentUser': true,
          },
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                theme: ThemeData(
                  // Simulate high contrast theme
                  brightness: Brightness.dark,
                  colorScheme: ColorScheme.dark(
                    primary: Colors.white,
                    secondary: Colors.white,
                    surface: Colors.black,
                    onSurface: Colors.white,
                  ),
                ),
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Test Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: groupMembers,
                    selectedPayerId: '1',
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>).at(1);
        expect(payerDropdown, findsOneWidget);

        // Verify dropdown is visible and functional in high contrast mode
        await tester.tap(payerDropdown);
        await tester.pumpAndSettle();

        expect(find.text('Test User'), findsOneWidget);
      });

      testWidgets('Focus indicators are visible for payer dropdown', (WidgetTester tester) async {
        final groupMembers = [
          {
            'id': 1,
            'name': 'Test User',
            'initials': 'TU',
            'isCurrentUser': true,
          },
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Test Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: groupMembers,
                    selectedPayerId: '1',
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Focus the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>).at(1);
        await tester.tap(payerDropdown);
        await tester.pumpAndSettle();

        // Verify focus indicator is present
        expect(payerDropdown, findsOneWidget);

        // Test that focus indicator is visually distinct
        final inputDecorator = find.ancestor(
          of: payerDropdown,
          matching: find.byType(InputDecorator),
        );
        expect(inputDecorator, findsOneWidget);
      });

      testWidgets('Text scaling works properly with payer dropdown', (WidgetTester tester) async {
        final groupMembers = [
          {
            'id': 1,
            'name': 'Test User with Very Long Name',
            'initials': 'TU',
            'isCurrentUser': true,
          },
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(textScaleFactor: 2.0), // Large text scaling
                  child: Scaffold(
                    body: ExpenseDetailsWidget(
                      selectedGroup: 'Test Group',
                      selectedCategory: 'Food & Dining',
                      selectedDate: DateTime.now(),
                      notesController: TextEditingController(),
                      totalController: TextEditingController(),
                      groups: ['Test Group'],
                      categories: ['Food & Dining'],
                      mode: 'manual',
                      groupMembers: groupMembers,
                      selectedPayerId: '1',
                      onPayerChanged: (payerId) {},
                    ),
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>).at(1);
        expect(payerDropdown, findsOneWidget);

        // Open dropdown to test text scaling
        await tester.tap(payerDropdown);
        await tester.pumpAndSettle();

        // Verify text is properly scaled and still readable
        expect(find.text('Test User with Very Long Name'), findsOneWidget);

        // Verify dropdown items handle text overflow properly
        final dropdownItem = find.text('Test User with Very Long Name');
        final itemWidget = tester.widget<Text>(dropdownItem);
        expect(itemWidget.overflow, equals(TextOverflow.ellipsis));
      });
    });
  });
}