import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:camsplit/presentation/group_detail/widgets/expense_list_widget.dart';
import 'package:camsplit/models/group_detail_model.dart';
import 'package:camsplit/theme/app_theme.dart';

void main() {
  group('ExpenseListWidget Tests', () {
    late List<GroupExpense> mockExpenses;

    setUp(() {
      mockExpenses = [
        GroupExpense(
          id: 1,
          title: 'Dinner at Restaurant',
          amount: 45.50,
          currency: 'EUR',
          date: DateTime.now().subtract(const Duration(days: 1)),
          payerName: 'John Doe',
          payerId: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        GroupExpense(
          id: 2,
          title: 'Grocery Shopping',
          amount: 23.75,
          currency: 'EUR',
          date: DateTime.now().subtract(const Duration(days: 3)),
          payerName: 'Jane Smith',
          payerId: 2,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        GroupExpense(
          id: 3,
          title: 'Movie Tickets',
          amount: 18.00,
          currency: 'EUR',
          date: DateTime.now().subtract(const Duration(days: 7)),
          payerName: 'Bob Johnson',
          payerId: 3,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];
    });

    Widget createTestWidget(Widget child) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: child,
            ),
          );
        },
      );
    }

    testWidgets('displays loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ExpenseListWidget(
            expenses: [],
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No expenses yet'), findsNothing);
    });

    testWidgets('displays empty state when expenses list is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ExpenseListWidget(
            expenses: [],
            isLoading: false,
          ),
        ),
      );

      expect(find.text('No expenses yet'), findsOneWidget);
      expect(find.text('Start adding expenses to track group spending'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('displays list of expenses when expenses are provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ExpenseListWidget(
            expenses: mockExpenses,
            isLoading: false,
          ),
        ),
      );

      // Check that all expenses are displayed
      expect(find.text('Dinner at Restaurant'), findsOneWidget);
      expect(find.text('Grocery Shopping'), findsOneWidget);
      expect(find.text('Movie Tickets'), findsOneWidget);

      // Check that amounts are displayed correctly
      expect(find.text('45.50EUR'), findsOneWidget);
      expect(find.text('23.75EUR'), findsOneWidget);
      expect(find.text('18.00EUR'), findsOneWidget);

      // Check that payer information is displayed
      expect(find.text('Paid by John Doe'), findsOneWidget);
      expect(find.text('Paid by Jane Smith'), findsOneWidget);
      expect(find.text('Paid by Bob Johnson'), findsOneWidget);
    });

    testWidgets('displays expenses in ListView.builder', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ExpenseListWidget(
            expenses: mockExpenses,
            isLoading: false,
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(ExpenseItemWidget), findsNWidgets(3));
    });

    testWidgets('has pull-to-refresh functionality', (WidgetTester tester) async {
      bool refreshCalled = false;
      
      await tester.pumpWidget(
        createTestWidget(
          ExpenseListWidget(
            expenses: mockExpenses,
            isLoading: false,
            onRefresh: () {
              refreshCalled = true;
            },
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
      
      // Simulate pull-to-refresh
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      expect(refreshCalled, isTrue);
    });

    testWidgets('empty state has pull-to-refresh functionality', (WidgetTester tester) async {
      bool refreshCalled = false;
      
      await tester.pumpWidget(
        createTestWidget(
          ExpenseListWidget(
            expenses: const [],
            isLoading: false,
            onRefresh: () {
              refreshCalled = true;
            },
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
      
      // Simulate pull-to-refresh on empty state
      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      expect(refreshCalled, isTrue);
    });

    testWidgets('calls onExpenseItemTap when expense item is tapped', (WidgetTester tester) async {
      bool tapCalled = false;
      GroupExpense? tappedExpense;

      await tester.pumpWidget(
        createTestWidget(
          ExpenseListWidget(
            expenses: mockExpenses,
            isLoading: false,
            onExpenseItemTap: (expense) {
              tapCalled = true;
              tappedExpense = expense;
            },
          ),
        ),
      );

      // Tap on the first expense item
      await tester.tap(find.byType(ExpenseItemWidget).first);
      await tester.pump();

      expect(tapCalled, isTrue);
      expect(tappedExpense, equals(mockExpenses[0]));
    });

    testWidgets('does not call onExpenseItemTap when callback is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ExpenseListWidget(
            expenses: mockExpenses,
            isLoading: false,
            onExpenseItemTap: null,
          ),
        ),
      );

      // Tap on the first expense item - should not crash
      await tester.tap(find.byType(ExpenseItemWidget).first);
      await tester.pump();

      // Should still display the expenses
      expect(find.text('Dinner at Restaurant'), findsOneWidget);
    });
  });

  group('ExpenseItemWidget Tests', () {
    late GroupExpense mockExpense;

    setUp(() {
      mockExpense = GroupExpense(
        id: 1,
        title: 'Test Expense',
        amount: 25.50,
        currency: 'EUR',
        date: DateTime.now().subtract(const Duration(days: 2)),
        payerName: 'Test User',
        payerId: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );
    });

    Widget createTestWidget(Widget child) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: child,
            ),
          );
        },
      );
    }

    testWidgets('displays expense information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ExpenseItemWidget(expense: mockExpense),
        ),
      );

      expect(find.text('Test Expense'), findsOneWidget);
      expect(find.text('25.50EUR'), findsOneWidget);
      expect(find.text('Paid by Test User'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('displays correct date formatting for recent dates', (WidgetTester tester) async {
      final todayExpense = GroupExpense(
        id: 1,
        title: 'Today Expense',
        amount: 10.00,
        currency: 'EUR',
        date: DateTime.now(),
        payerName: 'Test User',
        payerId: 1,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          ExpenseItemWidget(expense: todayExpense),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('displays correct date formatting for yesterday', (WidgetTester tester) async {
      final yesterdayExpense = GroupExpense(
        id: 1,
        title: 'Yesterday Expense',
        amount: 10.00,
        currency: 'EUR',
        date: DateTime.now().subtract(const Duration(days: 1)),
        payerName: 'Test User',
        payerId: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        createTestWidget(
          ExpenseItemWidget(expense: yesterdayExpense),
        ),
      );

      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('displays correct date formatting for days ago', (WidgetTester tester) async {
      final daysAgoExpense = GroupExpense(
        id: 1,
        title: 'Days Ago Expense',
        amount: 10.00,
        currency: 'EUR',
        date: DateTime.now().subtract(const Duration(days: 3)),
        payerName: 'Test User',
        payerId: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      );

      await tester.pumpWidget(
        createTestWidget(
          ExpenseItemWidget(expense: daysAgoExpense),
        ),
      );

      expect(find.text('3 days ago'), findsOneWidget);
    });

    testWidgets('displays correct date formatting for weeks ago', (WidgetTester tester) async {
      final weeksAgoExpense = GroupExpense(
        id: 1,
        title: 'Weeks Ago Expense',
        amount: 10.00,
        currency: 'EUR',
        date: DateTime.now().subtract(const Duration(days: 14)),
        payerName: 'Test User',
        payerId: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      );

      await tester.pumpWidget(
        createTestWidget(
          ExpenseItemWidget(expense: weeksAgoExpense),
        ),
      );

      expect(find.text('2 weeks ago'), findsOneWidget);
    });

    testWidgets('displays correct date formatting for months ago', (WidgetTester tester) async {
      final monthsAgoExpense = GroupExpense(
        id: 1,
        title: 'Months Ago Expense',
        amount: 10.00,
        currency: 'EUR',
        date: DateTime(2023, 6, 15),
        payerName: 'Test User',
        payerId: 1,
        createdAt: DateTime(2023, 6, 15),
      );

      await tester.pumpWidget(
        createTestWidget(
          ExpenseItemWidget(expense: monthsAgoExpense),
        ),
      );

      expect(find.text('15 Jun 2023'), findsOneWidget);
    });

    testWidgets('handles long expense titles with ellipsis', (WidgetTester tester) async {
      final longTitleExpense = GroupExpense(
        id: 1,
        title: 'This is a very long expense title that should be truncated with ellipsis when it exceeds the maximum number of lines',
        amount: 10.00,
        currency: 'EUR',
        date: DateTime.now(),
        payerName: 'Test User',
        payerId: 1,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          ExpenseItemWidget(expense: longTitleExpense),
        ),
      );

      final titleWidget = tester.widget<Text>(find.text(longTitleExpense.title));
      expect(titleWidget.maxLines, equals(1));
      expect(titleWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('applies correct styling and layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ExpenseItemWidget(expense: mockExpense),
        ),
      );

      expect(find.byType(Container), findsWidgets); // Container for styling
      expect(find.byType(Column), findsNWidgets(2)); // Left column and right column
      expect(find.byType(Row), findsNWidgets(2)); // Main row and payer info row
    });

    testWidgets('handles tap events correctly', (WidgetTester tester) async {
      bool tapCalled = false;
      GroupExpense? tappedExpense;

      await tester.pumpWidget(
        createTestWidget(
          ExpenseItemWidget(
            expense: mockExpense,
            onTap: () {
              tapCalled = true;
              tappedExpense = mockExpense;
            },
          ),
        ),
      );

      // Tap on the expense item
      await tester.tap(find.byType(ExpenseItemWidget));
      await tester.pump();

      expect(tapCalled, isTrue);
      expect(tappedExpense, equals(mockExpense));
    });

    testWidgets('does not crash when onTap is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ExpenseItemWidget(
            expense: mockExpense,
            onTap: null,
          ),
        ),
      );

      // Tap on the expense item - should not crash
      await tester.tap(find.byType(ExpenseItemWidget));
      await tester.pump();

      // Should still display the expense
      expect(find.text('Test Expense'), findsOneWidget);
    });
  });
}