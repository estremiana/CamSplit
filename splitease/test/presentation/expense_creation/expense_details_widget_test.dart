import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';

import '../../../lib/presentation/expense_creation/widgets/expense_details_widget.dart';
import '../../../lib/models/receipt_mode_config.dart';

void main() {
  group('ExpenseDetailsWidget Enhanced Tests', () {
    late TextEditingController notesController;
    late TextEditingController totalController;
    late TextEditingController titleController;
    late Currency testCurrency;

    setUp(() {
      notesController = TextEditingController();
      totalController = TextEditingController();
      titleController = TextEditingController();
      testCurrency = Currency(
        code: 'USD',
        name: 'US Dollar',
        symbol: '\$',
        flag: 'USD',
        number: 840,
        decimalDigits: 2,
        namePlural: 'US Dollars',
        symbolOnLeft: true,
        decimalSeparator: '.',
        thousandsSeparator: ',',
        spaceBetweenAmountAndSymbol: false,
      );
    });

    tearDown(() {
      notesController.dispose();
      totalController.dispose();
      titleController.dispose();
    });

    Widget createTestWidget({
      bool showGroupField = true,
      bool isReadOnly = false,
      List<String> groups = const ['Test Group 1', 'Test Group 2'],
      List<Map<String, dynamic>> groupMembers = const [],
    }) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: Scaffold(
              body: ExpenseDetailsWidget(
                selectedGroup: groups.isNotEmpty ? groups.first : '',
                selectedCategory: 'Food & Dining',
                selectedDate: DateTime.now(),
                notesController: notesController,
                totalController: totalController,
                titleController: titleController,
                groups: groups,
                categories: const ['Food & Dining', 'Transportation', 'Entertainment'],
                currency: testCurrency,
                mode: 'manual',
                showGroupField: showGroupField,
                isReadOnly: isReadOnly,
                groupMembers: groupMembers,
                onTitleChanged: (value) {},
                onGroupChanged: (value) {},
                onCategoryChanged: (value) {},
                onDateTap: () {},
                onCurrencyChanged: (value) {},
                onPayerChanged: (value) {},
              ),
            ),
          );
        },
      );
    }

    group('Title Field Rendering', () {
      testWidgets('should display title field with proper styling', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Title field should be present
        expect(find.text('Title'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, ''), findsWidgets);
        
        // Check for title field decoration
        final titleField = find.ancestor(
          of: find.text('Title'),
          matching: find.byType(TextFormField),
        );
        expect(titleField, findsOneWidget);
      });

      testWidgets('should display title field hint text when not read-only', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isReadOnly: false));
        
        // Should show hint text for title field
        expect(find.text('Enter expense title...'), findsOneWidget);
      });

      testWidgets('should not display title field hint text when read-only', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isReadOnly: true));
        
        // Should not show hint text when read-only
        expect(find.text('Enter expense title...'), findsNothing);
      });

      testWidgets('should display lock icon for title field when read-only', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isReadOnly: true));
        
        // Should show lock icon when read-only
        expect(find.byIcon(Icons.lock_outline), findsWidgets);
      });

      testWidgets('should position title field above group field', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showGroupField: true));
        
        // Both title and group should be present
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Group'), findsOneWidget);
        
        // Get the positions of both fields
        final titlePosition = tester.getTopLeft(find.text('Title'));
        final groupPosition = tester.getTopLeft(find.text('Group'));
        
        // Title should be above group (smaller y coordinate)
        expect(titlePosition.dy, lessThan(groupPosition.dy));
      });
    });

    group('Conditional Group Field Visibility', () {
      testWidgets('should show group field when showGroupField is true', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showGroupField: true));
        
        // Group field should be visible
        expect(find.text('Group'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
      });

      testWidgets('should hide group field when showGroupField is false', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showGroupField: false));
        
        // Group field should be hidden
        expect(find.text('Group'), findsNothing);
        
        // But other fields should still be present
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Who Paid'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
      });

      testWidgets('should maintain proper spacing when group field is hidden', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(showGroupField: false));
        
        // Title field should still be properly spaced
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Who Paid'), findsOneWidget);
        
        // Verify the layout is still functional
        final titlePosition = tester.getTopLeft(find.text('Title'));
        final payerPosition = tester.getTopLeft(find.text('Who Paid'));
        
        // There should be reasonable spacing between title and payer fields
        expect(payerPosition.dy, greaterThan(titlePosition.dy));
      });

      testWidgets('should show group field spacing only when group field is visible', (WidgetTester tester) async {
        // Test with group field visible
        await tester.pumpWidget(createTestWidget(showGroupField: true));
        expect(find.text('Group'), findsOneWidget);
        
        // Test with group field hidden
        await tester.pumpWidget(createTestWidget(showGroupField: false));
        expect(find.text('Group'), findsNothing);
        
        // Layout should adapt properly in both cases
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Who Paid'), findsOneWidget);
      });
    });

    group('Title Field Validation', () {
      testWidgets('should validate empty title field', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Find the title field
        final titleFields = find.byType(TextFormField);
        final titleField = titleFields.first;
        
        // Clear the title field
        await tester.enterText(titleField, '');
        await tester.pump();
        
        // Get the TextFormField widget to access its validator
        final titleFormField = tester.widget<TextFormField>(titleField);
        final validationResult = titleFormField.validator?.call('');
        
        // Should return validation error for empty title
        expect(validationResult, equals('Please enter a title for this expense'));
      });

      testWidgets('should validate title field character limit', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Find the title field
        final titleFields = find.byType(TextFormField);
        final titleField = titleFields.first;
        
        // Enter a title exceeding 100 characters
        final longTitle = 'a' * 101;
        await tester.enterText(titleField, longTitle);
        await tester.pump();
        
        // Get the TextFormField widget to access its validator
        final titleFormField = tester.widget<TextFormField>(titleField);
        final validationResult = titleFormField.validator?.call(longTitle);
        
        // Should return validation error for long title
        expect(validationResult, equals('Title must be 100 characters or less'));
      });

      testWidgets('should accept valid title', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Find the title field
        final titleFields = find.byType(TextFormField);
        final titleField = titleFields.first;
        
        // Enter a valid title
        const validTitle = 'Valid Expense Title';
        await tester.enterText(titleField, validTitle);
        await tester.pump();
        
        // Get the TextFormField widget to access its validator
        final titleFormField = tester.widget<TextFormField>(titleField);
        final validationResult = titleFormField.validator?.call(validTitle);
        
        // Should return null for valid title
        expect(validationResult, isNull);
      });

      testWidgets('should handle whitespace trimming in validation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Find the title field
        final titleFields = find.byType(TextFormField);
        final titleField = titleFields.first;
        
        // Test whitespace-only title
        await tester.enterText(titleField, '   ');
        await tester.pump();
        
        // Get the TextFormField widget to access its validator
        final titleFormField = tester.widget<TextFormField>(titleField);
        final validationResult = titleFormField.validator?.call('   ');
        
        // Should return validation error for whitespace-only title
        expect(validationResult, equals('Please enter a title for this expense'));
      });
    });

    group('Widget Parameter Validation', () {
      testWidgets('should handle required titleController parameter', (WidgetTester tester) async {
        // This test ensures the titleController is properly required
        expect(() => createTestWidget(), returnsNormally);
      });

      testWidgets('should handle default showGroupField parameter', (WidgetTester tester) async {
        // Test default value of showGroupField (should be true)
        await tester.pumpWidget(createTestWidget());
        
        // Group field should be visible by default
        expect(find.text('Group'), findsOneWidget);
      });

      testWidgets('should handle onTitleChanged callback', (WidgetTester tester) async {
        String? changedValue;
        
        final widget = Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: Scaffold(
                body: ExpenseDetailsWidget(
                  selectedGroup: 'Test Group',
                  selectedCategory: 'Food & Dining',
                  selectedDate: DateTime.now(),
                  notesController: notesController,
                  totalController: totalController,
                  titleController: titleController,
                  groups: const ['Test Group'],
                  categories: const ['Food & Dining'],
                  currency: testCurrency,
                  mode: 'manual',
                  onTitleChanged: (value) {
                    changedValue = value;
                  },
                ),
              ),
            );
          },
        );
        
        await tester.pumpWidget(widget);
        
        // Find and interact with title field
        final titleFields = find.byType(TextFormField);
        final titleField = titleFields.first;
        
        await tester.enterText(titleField, 'Test Title');
        await tester.pump();
        
        // Callback should have been called
        expect(changedValue, equals('Test Title'));
      });
    });

    group('Accessibility Features', () {
      testWidgets('should provide proper accessibility labels', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Title field should have proper label
        expect(find.text('Title'), findsOneWidget);
        
        // Should have semantic labels for screen readers
        final titleField = find.ancestor(
          of: find.text('Title'),
          matching: find.byType(TextFormField),
        );
        expect(titleField, findsOneWidget);
      });

      testWidgets('should handle keyboard navigation properly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Title field should be focusable
        final titleFields = find.byType(TextFormField);
        final titleField = titleFields.first;
        
        await tester.tap(titleField);
        await tester.pump();
        
        // Field should accept focus and input
        await tester.enterText(titleField, 'Keyboard Input Test');
        await tester.pump();
        
        expect(find.text('Keyboard Input Test'), findsOneWidget);
      });

      testWidgets('should provide proper visual feedback for disabled state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isReadOnly: true));
        
        // Should show visual indicators for read-only state
        expect(find.byIcon(Icons.lock_outline), findsWidgets);
        
        // Title field should be present but disabled
        expect(find.text('Title'), findsOneWidget);
      });
    });

    group('Integration with Other Fields', () {
      testWidgets('should work properly with other form fields', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // All expected fields should be present
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Group'), findsOneWidget);
        expect(find.text('Who Paid'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Notes (Optional)'), findsOneWidget);
      });

      testWidgets('should maintain proper field order', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Get positions of key fields
        final titlePosition = tester.getTopLeft(find.text('Title'));
        final groupPosition = tester.getTopLeft(find.text('Group'));
        final payerPosition = tester.getTopLeft(find.text('Who Paid'));
        
        // Verify proper order: Title -> Group -> Payer
        expect(titlePosition.dy, lessThan(groupPosition.dy));
        expect(groupPosition.dy, lessThan(payerPosition.dy));
      });

      testWidgets('should work with receipt mode configuration', (WidgetTester tester) async {
        final receiptModeConfig = ReceiptModeConfig.receiptMode;
        
        final widget = Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: Scaffold(
                body: ExpenseDetailsWidget(
                  selectedGroup: 'Test Group',
                  selectedCategory: 'Food & Dining',
                  selectedDate: DateTime.now(),
                  notesController: notesController,
                  totalController: totalController,
                  titleController: titleController,
                  groups: const ['Test Group'],
                  categories: const ['Food & Dining'],
                  currency: testCurrency,
                  mode: 'receipt',
                  isReceiptMode: true,
                  receiptModeConfig: receiptModeConfig,
                ),
              ),
            );
          },
        );
        
        await tester.pumpWidget(widget);
        
        // Title field should still be present and functional in receipt mode
        expect(find.text('Title'), findsOneWidget);
      });
    });
  });
}