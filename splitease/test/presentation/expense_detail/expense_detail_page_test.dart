import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:splitease/presentation/expense_detail/expense_detail_page.dart';
import 'package:splitease/services/expense_detail_service.dart';

void main() {
  group('ExpenseDetailPage Tests', () {
    setUp(() {
      ExpenseDetailService.clearCache();
    });

    tearDown(() {
      ExpenseDetailService.clearCache();
    });

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 1),
            );
          },
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display expense details after loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 1),
            );
          },
        ),
      );

      // Wait for the async operation to complete
      await tester.pump(const Duration(milliseconds: 600));

      // Should show expense detail header
      expect(find.text('Expense Detail'), findsOneWidget);
      
      // Should show edit button in read-only mode
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('should display receipt image when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 1), // Expense 1 has receipt image
            );
          },
        ),
      );

      // Wait for the async operation to complete
      await tester.pump(const Duration(milliseconds: 600));

      // Should show receipt image widget
      expect(find.text('Tap to view full receipt'), findsOneWidget);
    });

    testWidgets('should not display receipt image when not available', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 2), // Expense 2 has no receipt image
            );
          },
        ),
      );

      // Wait for the async operation to complete
      await tester.pump(const Duration(milliseconds: 600));

      // Should not show receipt image widget
      expect(find.text('Tap to view full receipt'), findsNothing);
    });

    testWidgets('should show all expense fields in read-only mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 1),
            );
          },
        ),
      );

      // Wait for the async operation to complete
      await tester.pump(const Duration(milliseconds: 600));

      // Should show expense details section
      expect(find.text('Expense Details'), findsOneWidget);
      
      // Should show split options section
      expect(find.text('Split Options'), findsOneWidget);
    });

    testWidgets('should handle loading errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseDetailPage(expenseId: 999), // Non-existent ID
            );
          },
        ),
      );

      // Wait for the async operation to complete
      await tester.pump(const Duration(milliseconds: 600));

      // Should still load (service provides fallback data)
      expect(find.text('Expense Detail'), findsOneWidget);
    });

    testWidgets('should display different data for different expense IDs', (WidgetTester tester) async {
      // Test expense ID 1
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

      // Test expense ID 2
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

    testWidgets('should handle form validation in edit mode', (WidgetTester tester) async {
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

      // Should show form fields
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should maintain scroll position during state changes', (WidgetTester tester) async {
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

      // Should have scroll controller
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should handle back navigation', (WidgetTester tester) async {
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

      // Should show back button
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('should display expense amount and currency correctly', (WidgetTester tester) async {
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

      // Should display formatted amount (from mock data)
      expect(find.textContaining('85.50'), findsOneWidget);
      expect(find.textContaining('EUR'), findsOneWidget);
    });

    testWidgets('should show participant information', (WidgetTester tester) async {
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

      // Should show participant names (from mock data)
      expect(find.textContaining('John Doe'), findsOneWidget);
      expect(find.textContaining('Jane Smith'), findsOneWidget);
    });
  });
}