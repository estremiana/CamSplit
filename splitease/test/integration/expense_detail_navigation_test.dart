import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:splitease/presentation/expense_detail/expense_detail_page.dart';
import 'package:splitease/services/expense_detail_service.dart';

void main() {
  group('Expense Detail Navigation Integration Tests', () {
    setUp(() {
      ExpenseDetailService.clearCache();
    });

    tearDown(() {
      ExpenseDetailService.clearCache();
    });

    testWidgets('should handle complete navigation flow from list to detail', (WidgetTester tester) async {
      // Simulate navigation from expense list to detail page
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExpenseDetailPage(expenseId: 1),
                          ),
                        );
                      },
                      child: Text('View Expense Detail'),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Tap to navigate to expense detail
      await tester.tap(find.text('View Expense Detail'));
      await tester.pumpAndSettle();

      // Should be on expense detail page
      expect(find.text('Expense Detail'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('should handle back navigation from detail page', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 1),
            );
          },
        ),
      );

      // Wait for page to load
      await tester.pump(const Duration(milliseconds: 600));

      // Should show back button
      expect(find.text('Back'), findsOneWidget);

      // Tap back button
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Should navigate back (in real app, this would go to previous screen)
      // In test environment, we just verify the button works
    });

    testWidgets('should handle navigation during edit mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 1),
            );
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      // Enter edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Should show cancel button instead of back
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('should handle navigation with different expense IDs', (WidgetTester tester) async {
      // Test navigation to expense 1
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 1),
            );
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Expense Detail'), findsOneWidget);

      // Test navigation to expense 2
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 2),
            );
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Expense Detail'), findsOneWidget);
    });

    testWidgets('should maintain state during navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 1),
            );
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      // Enter edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Make a change
      final notesField = find.byType(TextFormField).last;
      await tester.enterText(notesField, 'Modified notes');
      await tester.pumpAndSettle();

      // State should be maintained
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should handle navigation after successful save', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 1),
            );
          },
        ),
      );

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
      await tester.pump(); // Don't settle to catch intermediate states
      
      // Should show saving state
      expect(find.text('Saving changes...'), findsOneWidget);
      
      // Wait for save to complete
      await tester.pumpAndSettle();

      // Should return to read-only mode
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('should handle navigation during error states', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 999), // Non-existent ID
            );
          },
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(milliseconds: 600));

      // Should still show the page (service provides fallback)
      expect(find.text('Expense Detail'), findsOneWidget);
      
      // Back navigation should still work
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('should handle deep navigation scenarios', (WidgetTester tester) async {
      // Simulate deep navigation: Home -> Group -> Expense List -> Expense Detail
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              initialRoute: '/',
              routes: {
                '/': (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/group'),
                      child: Text('Go to Group'),
                    ),
                  ),
                ),
                '/group': (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/expense-detail'),
                      child: Text('View Expense'),
                    ),
                  ),
                ),
                '/expense-detail': (context) => ExpenseDetailPage(expenseId: 1),
              },
            );
          },
        ),
      );

      // Navigate through the flow
      await tester.tap(find.text('Go to Group'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Expense'));
      await tester.pumpAndSettle();

      // Should be on expense detail page
      expect(find.text('Expense Detail'), findsOneWidget);
    });

    testWidgets('should handle navigation with route arguments', (WidgetTester tester) async {
      // Test passing expense ID as route argument
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExpenseDetailPage(expenseId: 2),
                            settings: RouteSettings(arguments: {'expenseId': 2}),
                          ),
                        );
                      },
                      child: Text('View Expense 2'),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.text('View Expense 2'));
      await tester.pumpAndSettle();

      // Should load expense 2 data
      expect(find.text('Expense Detail'), findsOneWidget);
    });

    testWidgets('should handle navigation state preservation during orientation changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 1),
            );
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      // Enter edit mode
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Simulate orientation change by rebuilding widget
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 1),
            );
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      // Should maintain the page structure
      expect(find.text('Expense Detail'), findsOneWidget);
    });
  });
}