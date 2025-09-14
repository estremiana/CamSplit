import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import '../../lib/presentation/group_detail/group_detail_page.dart';
import '../../lib/presentation/group_detail/widgets/expense_list_widget.dart';
import '../../lib/widgets/loading_states.dart';
import '../../lib/utils/error_recovery.dart';
import '../../lib/utils/real_time_updates.dart';

void main() {
  group('UI Refresh Functionality Tests', () {
    testWidgets('GroupDetailPage shows loading state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GroupDetailPage(groupId: 1),
        ),
      );

      // Should show loading state initially
      expect(find.text('Loading group details...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ExpenseListWidget shows loading state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseListWidget(
              expenses: [],
              isLoading: true,
            ),
          ),
        ),
      );

      // Should show loading state
      expect(find.text('Loading expenses...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('LoadingStates.fullScreen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStates.fullScreen(message: 'Test Loading'),
          ),
        ),
      );

      expect(find.text('Test Loading'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('LoadingStates.withRetry displays retry information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStates.withRetry(
              message: 'Loading...',
              retryCount: 2,
              maxRetries: 3,
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.text('Retry attempt 2/3'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('LoadingStates.compact displays inline loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStates.compact(
              message: 'Loading...',
              size: 20,
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('PulsingLoadingIndicator animates correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PulsingLoadingIndicator(
              size: 40,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(PulsingLoadingIndicator), findsOneWidget);
      
      // Test animation
      await tester.pump(Duration(milliseconds: 750));
      await tester.pump(Duration(milliseconds: 750));
    });

    testWidgets('ShimmerLoading applies shimmer effect', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShimmerLoading(
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerLoading), findsOneWidget);
      
      // Test animation
      await tester.pump(Duration(milliseconds: 750));
      await tester.pump(Duration(milliseconds: 750));
    });
  });

  group('Error Recovery Tests', () {
    test('ErrorRecovery.isRecoverableError identifies recoverable errors', () {
      expect(ErrorRecovery.isRecoverableError('Network error'), true);
      expect(ErrorRecovery.isRecoverableError('Connection timeout'), true);
      expect(ErrorRecovery.isRecoverableError('Server error 500'), true);
      expect(ErrorRecovery.isRecoverableError('Unauthorized 401'), false);
      expect(ErrorRecovery.isRecoverableError('Not found 404'), false);
      expect(ErrorRecovery.isRecoverableError('Validation error'), false);
    });

    test('ErrorRecovery.getRecommendedRetryDelay returns appropriate delays', () {
      final networkDelay = ErrorRecovery.getRecommendedRetryDelay('Network error', 1);
      final serverDelay = ErrorRecovery.getRecommendedRetryDelay('Server error 500', 1);
      final rateLimitDelay = ErrorRecovery.getRecommendedRetryDelay('Rate limit 429', 1);

      expect(networkDelay.inSeconds, 2);
      expect(serverDelay.inSeconds, 4);
      expect(rateLimitDelay.inSeconds, 10);
    });
  });

  group('Real Time Updates Tests', () {
    test('RealTimeUpdates can create optimistic expense', () {
      final expenseData = {
        'id': 1,
        'title': 'Test Expense',
        'amount': 25.0,
        'currency': 'EUR',
        'date': DateTime.now().toIso8601String(),
        'payerName': 'John Doe',
        'category': 'Food',
        'splitType': 'equal',
        'notes': 'Test notes',
      };

      final expense = RealTimeUpdates.createOptimisticExpense(expenseData, 1);
      
      expect(expense.id, 1);
      expect(expense.title, 'Test Expense');
      expect(expense.amount, 25.0);
      expect(expense.currency, 'EUR');
      expect(expense.payerName, 'John Doe');
    });

    test('RealTimeUpdates.isDataStale correctly identifies stale data', () {
      final now = DateTime.now();
      final freshData = now.subtract(Duration(minutes: 2));
      final staleData = now.subtract(Duration(minutes: 10));
      final maxAge = Duration(minutes: 5);

      expect(RealTimeUpdates.isDataStale(freshData, maxAge), false);
      expect(RealTimeUpdates.isDataStale(staleData, maxAge), true);
    });
  });

  group('Loading States Integration Tests', () {
    testWidgets('LoadingStates.overlay displays overlay correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStates.overlay(
              message: 'Processing...',
              backgroundColor: Colors.black54,
            ),
          ),
        ),
      );

      expect(find.text('Processing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('LoadingStates.skeletonListItem displays skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStates.skeletonListItem(),
          ),
        ),
      );

      // Should show skeleton placeholders
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('LoadingStates.skeletonCard displays card skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStates.skeletonCard(),
          ),
        ),
      );

      // Should show skeleton placeholders
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('LoadingStates.withProgress displays progress correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStates.withProgress(
              progress: 0.5,
              message: 'Uploading...',
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Uploading...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
} 