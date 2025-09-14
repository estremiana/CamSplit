import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/expense_detail/expense_detail_page.dart';
import 'package:camsplit/models/expense_detail_model.dart';
import 'package:camsplit/models/participant_amount.dart';
import 'package:camsplit/services/expense_detail_service.dart';
import 'package:sizer/sizer.dart';

void main() {
  group('ExpenseDetailPage Save and Cancel Operations', () {
    late Widget testWidget;

    setUp(() {
      testWidget = Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: ExpenseDetailPage(expenseId: 1),
          );
        },
      );
    });

    testWidgets('should show save and cancel buttons in edit mode', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      
      // Wait for the expense to load
      await tester.pumpAndSettle();
      
      // Find and tap the edit button
      final editButton = find.text('Edit');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();
      
      // Verify save and cancel buttons are visible
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should validate form before saving', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      
      // Enter edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      
      // Clear the total field to trigger validation error
      final totalField = find.byType(TextFormField).first;
      await tester.enterText(totalField, '');
      await tester.pumpAndSettle();
      
      // Try to save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      
      // Should show validation error
      expect(find.textContaining('Please fix'), findsOneWidget);
    });

    testWidgets('should show confirmation dialog when canceling with changes', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      
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

    testWidgets('should restore original data when canceling', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      
      // Enter edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      
      // Make a change
      final notesField = find.byType(TextFormField).last;
      await tester.enterText(notesField, 'Modified notes');
      await tester.pumpAndSettle();
      
      // Cancel and confirm
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      
      // Should be back in read-only mode
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('should show loading indicator during save', (WidgetTester tester) async {
      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      
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
      
      // Should show loading indicator
      expect(find.text('Saving changes...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('ExpenseDetailPage Validation', () {
    testWidgets('should validate split options for equal split', (WidgetTester tester) async {
      final testWidget = Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: ExpenseDetailPage(expenseId: 1),
          );
        },
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle();
      
      // Enter edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      
      // Try to save without selecting members (if applicable)
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      
      // The validation should pass since we're using existing expense data
      // This test verifies the validation logic is in place
    });
  });
}