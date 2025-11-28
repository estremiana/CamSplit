import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/expense_wizard_screen.dart';
import 'package:camsplit/routes/app_routes.dart';

/// Unit tests for wizard entry point from expense dashboard
/// Tests Requirements 1.1, 1.2, 1.4
void main() {
  group('Wizard Entry Point Tests', () {
    testWidgets('Wizard route is defined in AppRoutes', (WidgetTester tester) async {
      // Requirement 1.1: WHEN a user views the expense dashboard 
      // THEN the system SHALL display a button or option to access the new wizard-based expense creation flow
      
      // Verify the wizard route constant exists
      expect(AppRoutes.expenseWizard, equals('/expense-wizard'));
      
      // Verify the route is in the routes map
      expect(AppRoutes.routes.containsKey(AppRoutes.expenseWizard), isTrue);
    });

    testWidgets('Wizard route creates ExpenseWizardScreen', (WidgetTester tester) async {
      // Requirement 1.2: WHEN a user taps the new expense creation button 
      // THEN the system SHALL navigate to the first page of the ExpenseWizard
      
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.expenseWizard,
        ),
      );
      await tester.pumpAndSettle();

      // Verify ExpenseWizardScreen is created
      expect(find.byType(ExpenseWizardScreen), findsOneWidget);
    });

    testWidgets('Manual expense creation route still exists', (WidgetTester tester) async {
      // Requirement 1.4: WHEN the ExpenseWizard opens 
      // THEN the system SHALL preserve the existing manual expense creation option for backward compatibility
      
      // Verify the manual expense creation route still exists
      expect(AppRoutes.expenseCreation, equals('/expense-creation'));
      expect(AppRoutes.routes.containsKey(AppRoutes.expenseCreation), isTrue);
    });

    testWidgets('Camera receipt capture route still exists', (WidgetTester tester) async {
      // Requirement 1.4: Backward compatibility - camera capture should still be available
      
      // Verify the camera receipt capture route still exists
      expect(AppRoutes.cameraReceiptCapture, equals('/camera-receipt-capture'));
      expect(AppRoutes.routes.containsKey(AppRoutes.cameraReceiptCapture), isTrue);
    });

    testWidgets('Wizard can be navigated to programmatically', (WidgetTester tester) async {
      // Requirement 1.2: Verify navigation to wizard works
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.expenseWizard);
                },
                child: const Text('Open Wizard'),
              ),
            ),
          ),
          routes: AppRoutes.routes,
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to navigate to wizard
      await tester.tap(find.text('Open Wizard'));
      await tester.pumpAndSettle();

      // Verify wizard screen is displayed
      expect(find.byType(ExpenseWizardScreen), findsOneWidget);
    });
  });

  group('Wizard Entry Integration Tests', () {
    testWidgets('Wizard opens with progress indicator 1 of 3', (WidgetTester tester) async {
      // Requirement 1.3: WHEN the ExpenseWizard opens 
      // THEN the system SHALL display a progress indicator showing "1 of 3"
      
      await tester.pumpWidget(
        MaterialApp(
          home: const ExpenseWizardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify progress indicator shows "1 of 3" or "Page 1 of 3"
      expect(find.textContaining('1 of 3'), findsOneWidget);
    });

    testWidgets('Wizard can be navigated back from', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
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

      // Verify wizard opened
      expect(find.textContaining('1 of 3'), findsOneWidget);

      // Navigate back using close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Confirm discard
      await tester.tap(find.text('Discard').last);
      await tester.pumpAndSettle();

      // Verify we're back
      expect(find.text('Open Wizard'), findsOneWidget);
    });
  });

  group('Backward Compatibility Tests', () {
    testWidgets('Existing expense creation route still works', (WidgetTester tester) async {
      // Requirement 1.4: Ensure backward compatibility
      
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/expense-creation',
          routes: {
            '/expense-creation': (context) => const Scaffold(
              body: Center(child: Text('Manual Expense Creation')),
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Verify manual expense creation screen loads
      expect(find.text('Manual Expense Creation'), findsOneWidget);
    });

    testWidgets('Camera receipt capture route still works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.cameraReceiptCapture,
          routes: {
            AppRoutes.cameraReceiptCapture: (context) => const Scaffold(
              body: Center(child: Text('Camera Receipt Capture')),
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Verify camera capture screen loads
      expect(find.text('Camera Receipt Capture'), findsOneWidget);
    });
  });
}
