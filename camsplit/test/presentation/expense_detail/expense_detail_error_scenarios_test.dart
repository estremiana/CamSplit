import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:camsplit/presentation/expense_detail/expense_detail_page.dart';
import 'package:camsplit/services/expense_detail_service.dart';

void main() {
  group('ExpenseDetailPage Error Scenarios', () {
    setUp(() {
      ExpenseDetailService.clearCache();
    });

    tearDown(() {
      ExpenseDetailService.clearCache();
    });

    Widget createTestWidget({required int expenseId}) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: ExpenseDetailPage(expenseId: expenseId),
          );
        },
      );
    }

    group('Loading Error Scenarios', () {
      testWidgets('should handle loading state correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));

        // Should show loading indicator initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // Wait for loading to complete
        await tester.pump(const Duration(milliseconds: 600));
        
        // Should show loaded content
        expect(find.text('Expense Detail'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should handle non-existent expense ID gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 999));

        await tester.pump(const Duration(milliseconds: 600));

        // Service provides fallback data, so page should still load
        expect(find.text('Expense Detail'), findsOneWidget);
      });

      testWidgets('should handle loading timeout scenarios', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));

        // Test extended loading time
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Eventually should load
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Expense Detail'), findsOneWidget);
      });
    });

    group('Form Validation Error Scenarios', () {
      testWidgets('should handle empty total amount validation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Clear total field
        final totalField = find.byType(TextFormField).first;
        await tester.enterText(totalField, '');
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('Please fix'), findsOneWidget);
      });

      testWidgets('should handle negative amount validation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Enter negative amount
        final totalField = find.byType(TextFormField).first;
        await tester.enterText(totalField, '-50.00');
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('Please fix'), findsOneWidget);
      });

      testWidgets('should handle very large amount validation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Enter very large amount
        final totalField = find.byType(TextFormField).first;
        await tester.enterText(totalField, '1000000.00');
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('Please fix'), findsOneWidget);
      });

      testWidgets('should handle invalid text in amount field', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Enter invalid text
        final totalField = find.byType(TextFormField).first;
        await tester.enterText(totalField, 'invalid amount');
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('Please fix'), findsOneWidget);
      });

      testWidgets('should handle very long notes validation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Enter very long notes
        final notesField = find.byType(TextFormField).last;
        await tester.enterText(notesField, 'A' * 501); // Exceeds 500 character limit
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('Please fix'), findsOneWidget);
      });
    });

    group('Save Operation Error Scenarios', () {
      testWidgets('should handle save operation loading state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Make a valid change
        final totalField = find.byType(TextFormField).first;
        await tester.enterText(totalField, '100.00');
        await tester.pumpAndSettle();

        // Start save operation
        await tester.tap(find.text('Save'));
        await tester.pump(); // Don't settle to catch loading state

        // Should show saving state
        expect(find.text('Saving changes...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle successful save operation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Make a valid change
        final totalField = find.byType(TextFormField).first;
        await tester.enterText(totalField, '100.00');
        await tester.pumpAndSettle();

        // Save changes
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should return to read-only mode
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Save'), findsNothing);
        
        // Should show success message
        expect(find.textContaining('updated successfully'), findsOneWidget);
      });

      testWidgets('should disable save button during save operation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Make a valid change
        final totalField = find.byType(TextFormField).first;
        await tester.enterText(totalField, '100.00');
        await tester.pumpAndSettle();

        // Start save operation
        await tester.tap(find.text('Save'));
        await tester.pump(); // Don't settle to catch intermediate state

        // Save button should be disabled (showing loading indicator)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Save'), findsNothing);
      });
    });

    group('Cancel Operation Error Scenarios', () {
      testWidgets('should handle cancel without changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Cancel without making changes
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Should return to read-only mode immediately
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
      });

      testWidgets('should handle cancel with unsaved changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Make a change
        final notesField = find.byType(TextFormField).last;
        await tester.enterText(notesField, 'Modified notes');
        await tester.pumpAndSettle();

        // Try to cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        expect(find.text('Discard Changes?'), findsOneWidget);
        expect(find.text('Keep Editing'), findsOneWidget);
        expect(find.text('Discard'), findsOneWidget);
      });

      testWidgets('should handle cancel confirmation - keep editing', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode and make changes
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        final notesField = find.byType(TextFormField).last;
        await tester.enterText(notesField, 'Modified notes');
        await tester.pumpAndSettle();

        // Try to cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Choose to keep editing
        await tester.tap(find.text('Keep Editing'));
        await tester.pumpAndSettle();

        // Should remain in edit mode
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('should handle cancel confirmation - discard changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode and make changes
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        final notesField = find.byType(TextFormField).last;
        await tester.enterText(notesField, 'Modified notes');
        await tester.pumpAndSettle();

        // Try to cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Choose to discard changes
        await tester.tap(find.text('Discard'));
        await tester.pumpAndSettle();

        // Should return to read-only mode
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Save'), findsNothing);
        expect(find.text('Cancel'), findsNothing);
      });
    });

    group('State Management Error Scenarios', () {
      testWidgets('should handle rapid state transitions', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Rapidly toggle edit mode
        await tester.tap(find.text('Edit'));
        await tester.pump();
        
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Should end up in edit mode
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('should handle form state during widget rebuilds', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Make changes
        final totalField = find.byType(TextFormField).first;
        await tester.enterText(totalField, '150.00');
        await tester.pumpAndSettle();

        // Rebuild widget (simulating external state change)
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Should maintain basic structure
        expect(find.text('Expense Detail'), findsOneWidget);
      });

      testWidgets('should handle memory pressure scenarios', (WidgetTester tester) async {
        // Test multiple expense detail pages
        for (int i = 1; i <= 3; i++) {
          await tester.pumpWidget(createTestWidget(expenseId: i));
          await tester.pump(const Duration(milliseconds: 600));
          
          expect(find.text('Expense Detail'), findsOneWidget);
          
          // Clear to simulate memory pressure
          ExpenseDetailService.clearCache();
        }
      });
    });

    group('Edge Case Error Scenarios', () {
      testWidgets('should handle special characters in form fields', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Enter special characters in notes
        final notesField = find.byType(TextFormField).last;
        await tester.enterText(notesField, 'Notes with émojis 😊 and spëcial chars');
        await tester.pumpAndSettle();

        // Should handle special characters gracefully
        expect(find.textContaining('😊'), findsOneWidget);
      });

      testWidgets('should handle very small amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Enter very small amount
        final totalField = find.byType(TextFormField).first;
        await tester.enterText(totalField, '0.01');
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should accept small valid amounts
        expect(find.text('Edit'), findsOneWidget);
      });

      testWidgets('should handle zero amount validation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Enter zero amount
        final totalField = find.byType(TextFormField).first;
        await tester.enterText(totalField, '0.00');
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should show validation error for zero amount
        expect(find.textContaining('Please fix'), findsOneWidget);
      });

      testWidgets('should handle decimal precision edge cases', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(expenseId: 1));
        await tester.pump(const Duration(milliseconds: 600));

        // Enter edit mode
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Enter amount with many decimal places
        final totalField = find.byType(TextFormField).first;
        await tester.enterText(totalField, '10.999999');
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Should handle decimal precision appropriately
        expect(find.text('Edit'), findsOneWidget);
      });
    });
  });
}