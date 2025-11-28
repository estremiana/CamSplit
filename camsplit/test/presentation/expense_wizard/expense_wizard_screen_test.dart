import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/expense_wizard_screen.dart';

void main() {
  group('ExpenseWizardScreen Navigation Tests', () {
    testWidgets('Wizard initializes on first page', (WidgetTester tester) async {
      // Build the wizard
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify we're on page 1
      expect(find.text('Page 1 of 3'), findsOneWidget);
      expect(find.text('Amount & Scan'), findsOneWidget);
    });

    testWidgets('Next button navigates to second page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter a valid amount to enable Next button
      await tester.enterText(find.byType(TextField).first, '50.00');
      await tester.pumpAndSettle();

      // Tap Next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify we're on page 2
      expect(find.text('Page 2 of 3'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('Back button navigates to previous page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter a valid amount to enable Next button
      await tester.enterText(find.byType(TextField).first, '50.00');
      await tester.pumpAndSettle();

      // Navigate to page 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap Back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Verify we're back on page 1
      expect(find.text('Page 1 of 3'), findsOneWidget);
      expect(find.text('Amount & Scan'), findsOneWidget);
    });

    testWidgets('Can navigate through all three pages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Page 1
      expect(find.text('Page 1 of 3'), findsOneWidget);

      // Enter a valid amount to enable Next button
      await tester.enterText(find.byType(TextField).first, '50.00');
      await tester.pumpAndSettle();

      // Navigate to page 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Page 2 of 3'), findsOneWidget);

      // Navigate to page 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Page 3 of 3'), findsOneWidget);
      expect(find.text('Split Options'), findsOneWidget);
    });

    testWidgets('Back button not shown on first page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Back button is not present on first page
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('Next button not shown on last page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter a valid amount to enable Next button
      await tester.enterText(find.byType(TextField).first, '50.00');
      await tester.pumpAndSettle();

      // Navigate to last page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Verify Next button is not present on last page
      expect(find.text('Next'), findsNothing);
      // But Create Expense button should be present (find by button type)
      expect(find.widgetWithText(ElevatedButton, 'Create Expense'), findsOneWidget);
    });

    testWidgets('Discard button shown on first page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Discard button is present on first page
      expect(find.text('Discard'), findsOneWidget);
    });
  });

  group('ExpenseWizardScreen Discard Dialog Tests', () {
    testWidgets('Discard button shows confirmation dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Discard button
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Discard Expense?'), findsOneWidget);
      expect(find.text('Are you sure you want to discard this expense? All entered data will be lost.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Discard'), findsNWidgets(2)); // One in dialog, one in page
    });

    testWidgets('Cancel button in dialog dismisses dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Discard button
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Tap Cancel in dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog is dismissed and we're still on wizard
      expect(find.text('Discard Expense?'), findsNothing);
      expect(find.text('Page 1 of 3'), findsOneWidget);
    });

    testWidgets('Discard button in dialog closes wizard', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExpenseWizardScreen(),
                    ),
                  );
                },
                child: const Text('Open Wizard'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open wizard
      await tester.tap(find.text('Open Wizard'));
      await tester.pumpAndSettle();

      // Verify wizard is open
      expect(find.text('Page 1 of 3'), findsOneWidget);

      // Tap Discard button
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Tap Discard in dialog (find the one in the dialog, not the page)
      final discardButtons = find.text('Discard');
      await tester.tap(discardButtons.last);
      await tester.pumpAndSettle();

      // Verify wizard is closed
      expect(find.text('Page 1 of 3'), findsNothing);
      expect(find.text('Open Wizard'), findsOneWidget);
    });

    testWidgets('Close button in AppBar shows discard dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap close button in AppBar
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Discard Expense?'), findsOneWidget);
    });

    testWidgets('WillPopScope is present for back button handling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify WillPopScope is present
      expect(find.byType(WillPopScope), findsOneWidget);
    });
  });
}
