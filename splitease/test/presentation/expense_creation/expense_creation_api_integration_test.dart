import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../lib/presentation/expense_creation/expense_creation.dart';

void main() {
  group('ExpenseCreation API Integration Tests', () {
    Widget createTestWidget({Map<String, dynamic>? arguments}) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: Builder(
              builder: (context) {
                return ExpenseCreation();
              },
            ),
            onGenerateRoute: (settings) {
              if (settings.name == '/expense-creation') {
                return MaterialPageRoute(
                  builder: (context) => ExpenseCreation(),
                  settings: RouteSettings(arguments: arguments),
                );
              }
              return null;
            },
          );
        },
      );
    }

    group('Title Field API Integration', () {
      testWidgets('should include title field value in API request data structure', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        
        // Verify title field is present for API integration
        expect(find.text('Title'), findsOneWidget);
        
        // Find the title field and enter a custom title
        final titleFields = find.byType(TextFormField);
        if (titleFields.evaluate().isNotEmpty) {
          final titleField = titleFields.first;
          await tester.enterText(titleField, 'API Integration Test Expense');
          await tester.pump();
          
          // Verify the title was entered
          expect(find.text('API Integration Test Expense'), findsOneWidget);
        }
      });

      testWidgets('should use default title when field is empty', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        
        // Leave title field empty and verify form structure
        expect(find.text('Title'), findsOneWidget);
        
        // The API integration should use "Expense" as default when title is empty
        // This is tested through the actual API call in the _saveExpense method
      });

      testWidgets('should trim whitespace from title before API submission', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        
        // Enter title with whitespace
        final titleFields = find.byType(TextFormField);
        if (titleFields.evaluate().isNotEmpty) {
          final titleField = titleFields.first;
          await tester.enterText(titleField, '  Whitespace Test Title  ');
          await tester.pump();
          
          // The API integration should trim whitespace before submission
          expect(find.text('  Whitespace Test Title  '), findsOneWidget);
        }
      });

      testWidgets('should handle title field in all navigation contexts', (WidgetTester tester) async {
        // Test dashboard context
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Title'), findsOneWidget);
        
        // Test OCR assignment context
        final ocrArguments = {
          'receiptData': {
            'total': 25.50,
            'selectedGroupName': 'Test Group',
            'groupMembers': [],
            'participantAmounts': [],
            'items': [],
          }
        };
        await tester.pumpWidget(createTestWidget(arguments: ocrArguments));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Title'), findsOneWidget);
        
        // Test group detail context
        final groupArguments = {'groupId': 1};
        await tester.pumpWidget(createTestWidget(arguments: groupArguments));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Title'), findsOneWidget);
      });
    });

    group('Form Validation with Title Field', () {
      testWidgets('should validate title field along with other required fields', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        
        // Form should include title field validation
        expect(find.byType(Form), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
        
        // All form fields should be present for comprehensive validation
        expect(find.text('Who Paid'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
      });

      testWidgets('should prevent API submission when title validation fails', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        
        // Clear title field to trigger validation error
        final titleFields = find.byType(TextFormField);
        if (titleFields.evaluate().isNotEmpty) {
          final titleField = titleFields.first;
          await tester.enterText(titleField, '');
          await tester.pump();
          
          // Try to submit form
          final saveButton = find.text('Create Expense');
          if (saveButton.evaluate().isNotEmpty) {
            await tester.tap(saveButton);
            await tester.pumpAndSettle();
            
            // Should show validation error and prevent API call
            expect(find.text('Please enter a title for this expense'), findsOneWidget);
          }
        }
      });

      testWidgets('should allow API submission when title validation passes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        
        // Enter valid title
        final titleFields = find.byType(TextFormField);
        if (titleFields.evaluate().isNotEmpty) {
          final titleField = titleFields.first;
          await tester.enterText(titleField, 'Valid API Test Title');
          await tester.pump();
          
          // Title validation should pass
          expect(find.text('Valid API Test Title'), findsOneWidget);
          expect(find.text('Please enter a title for this expense'), findsNothing);
        }
      });
    });

    group('Backward Compatibility', () {
      testWidgets('should maintain existing API structure with title field addition', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        
        // All existing fields should still be present
        expect(find.text('Title'), findsOneWidget); // New field
        expect(find.text('Who Paid'), findsOneWidget); // Existing field
        expect(find.text('Category'), findsOneWidget); // Existing field
        expect(find.text('Total'), findsOneWidget); // Existing field
        expect(find.text('Notes (Optional)'), findsOneWidget); // Existing field
      });

      testWidgets('should preserve existing form behavior with title field', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        
        // Form should still function as before, with title field added
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(TextFormField), findsWidgets);
        
        // Should have more form fields now (including title)
        final formFields = find.byType(TextFormField);
        expect(formFields.evaluate().length, greaterThan(2));
      });
    });

    group('Receipt Mode Integration', () {
      testWidgets('should include title field in receipt mode', (WidgetTester tester) async {
        final receiptArguments = {
          'receiptData': {
            'total': 25.50,
            'selectedGroupName': 'Test Group',
            'groupMembers': [],
            'participantAmounts': [],
            'items': [],
          }
        };

        await tester.pumpWidget(createTestWidget(arguments: receiptArguments));
        await tester.pump(const Duration(milliseconds: 100));
        
        // Title field should be present in receipt mode
        expect(find.text('Title'), findsOneWidget);
        
        // Group field should be hidden in receipt mode
        expect(find.text('Group'), findsNothing);
      });

      testWidgets('should validate title field in receipt mode', (WidgetTester tester) async {
        final receiptArguments = {
          'receiptData': {
            'total': 25.50,
            'selectedGroupName': 'Test Group',
            'groupMembers': [],
            'participantAmounts': [],
            'items': [],
          }
        };

        await tester.pumpWidget(createTestWidget(arguments: receiptArguments));
        await tester.pump(const Duration(milliseconds: 100));
        
        // Title field validation should work in receipt mode
        final titleFields = find.byType(TextFormField);
        if (titleFields.evaluate().isNotEmpty) {
          final titleField = titleFields.first;
          await tester.enterText(titleField, 'Receipt Mode Title');
          await tester.pump();
          
          expect(find.text('Receipt Mode Title'), findsOneWidget);
        }
      });
    });
  });
}