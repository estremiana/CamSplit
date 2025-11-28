import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/widgets/step_split_page.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';

/// Integration test for split validation and error banner display
void main() {
  group('Split Validation Integration Tests', () {
    testWidgets('Items split with unassigned items shows error banner', (WidgetTester tester) async {
      // Create wizard data with partially assigned items
      final wizardData = WizardExpenseData(
        amount: 100.0,
        title: 'Test Expense',
        groupId: 'group_1',
        payerId: 'user_1',
        date: DateTime.now().toIso8601String(),
        splitType: SplitType.items,
        items: [
          ReceiptItem(
            id: 'item_1',
            name: 'Pizza',
            quantity: 4.0,
            unitPrice: 10.0,
            price: 40.0,
            assignments: {
              'member_1': 2.0, // Only 2/4 assigned
            },
          ),
        ],
      );

      bool backCalled = false;
      bool submitCalled = false;
      WizardExpenseData? updatedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepSplitPage(
              wizardData: wizardData,
              onBack: () => backCalled = true,
              onDataChanged: (data) => updatedData = data,
              onSubmit: () => submitCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error banner is displayed
      expect(find.text('Assign all items before continuing (1 item remaining)'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Verify Create Expense button is disabled
      final createButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Expense'),
      );
      expect(createButton.onPressed, isNull);

      // Verify submit is not called when button is tapped
      await tester.tap(find.text('Create Expense'));
      await tester.pumpAndSettle();
      expect(submitCalled, false);
    });

    testWidgets('Items split with all items assigned hides error banner', (WidgetTester tester) async {
      // Create wizard data with fully assigned items
      final wizardData = WizardExpenseData(
        amount: 100.0,
        title: 'Test Expense',
        groupId: 'group_1',
        payerId: 'user_1',
        date: DateTime.now().toIso8601String(),
        splitType: SplitType.items,
        items: [
          ReceiptItem(
            id: 'item_1',
            name: 'Pizza',
            quantity: 4.0,
            unitPrice: 10.0,
            price: 40.0,
            assignments: {
              'member_1': 2.0,
              'member_2': 2.0, // Fully assigned
            },
          ),
        ],
      );

      bool submitCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepSplitPage(
              wizardData: wizardData,
              onBack: () {},
              onDataChanged: (data) {},
              onSubmit: () => submitCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error banner is NOT displayed
      expect(find.text('Assign all items before continuing'), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);

      // Verify Create Expense button is enabled
      final createButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Expense'),
      );
      expect(createButton.onPressed, isNotNull);
    });

    testWidgets('Percentage split with invalid total shows error banner', (WidgetTester tester) async {
      // Create wizard data with invalid percentage split
      final wizardData = WizardExpenseData(
        amount: 100.0,
        title: 'Test Expense',
        groupId: 'group_1',
        payerId: 'user_1',
        date: DateTime.now().toIso8601String(),
        splitType: SplitType.percentage,
        splitDetails: {
          'member_1': 50.0,
          'member_2': 30.0, // Total = 80%, not 100%
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepSplitPage(
              wizardData: wizardData,
              onBack: () {},
              onDataChanged: (data) {},
              onSubmit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error banner is displayed
      expect(find.textContaining('Remaining:'), findsOneWidget);
      expect(find.textContaining('20.0%'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Verify Create Expense button is disabled
      final createButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Expense'),
      );
      expect(createButton.onPressed, isNull);
    });

    testWidgets('Custom split with invalid total shows error banner', (WidgetTester tester) async {
      // Create wizard data with invalid custom split
      final wizardData = WizardExpenseData(
        amount: 100.0,
        title: 'Test Expense',
        groupId: 'group_1',
        payerId: 'user_1',
        date: DateTime.now().toIso8601String(),
        splitType: SplitType.custom,
        splitDetails: {
          'member_1': 50.0,
          'member_2': 30.0, // Total = 80, not 100
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepSplitPage(
              wizardData: wizardData,
              onBack: () {},
              onDataChanged: (data) {},
              onSubmit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error banner is displayed
      expect(find.textContaining('Remaining:'), findsOneWidget);
      expect(find.textContaining('20.00'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Verify Create Expense button is disabled
      final createButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Expense'),
      );
      expect(createButton.onPressed, isNull);
    });

    testWidgets('Equal split with no members shows error banner', (WidgetTester tester) async {
      // Create wizard data with no involved members
      final wizardData = WizardExpenseData(
        amount: 100.0,
        title: 'Test Expense',
        groupId: 'group_1',
        payerId: 'user_1',
        date: DateTime.now().toIso8601String(),
        splitType: SplitType.equal,
        involvedMembers: [], // No members selected
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StepSplitPage(
              wizardData: wizardData,
              onBack: () {},
              onDataChanged: (data) {},
              onSubmit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error banner is displayed
      expect(find.text('Select at least one member to split with'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Verify Create Expense button is disabled
      final createButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create Expense'),
      );
      expect(createButton.onPressed, isNull);
    });
  });
}
