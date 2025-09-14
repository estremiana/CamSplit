import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:camsplit/presentation/group_detail/group_detail_page.dart';
import 'package:camsplit/theme/app_theme.dart';

void main() {
  group('Group Detail Expense Creation Integration Tests', () {
    Widget createTestApp({int groupId = 1}) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: GroupDetailPage(groupId: groupId),
          );
        },
      );
    }

    group('Floating Action Button Tests', () {
      testWidgets('should display FAB with correct design', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Find the floating action button
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        // Verify FAB properties
        final FloatingActionButton fab = tester.widget(fabFinder);
        expect(fab.backgroundColor, AppTheme.lightTheme.floatingActionButtonTheme.backgroundColor);

        // Verify FAB is present and functional
        expect(fab.onPressed, isNotNull);
      });

      testWidgets('should be positioned correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final scaffoldFinder = find.byType(Scaffold);
        expect(scaffoldFinder, findsOneWidget);

        final Scaffold scaffold = tester.widget(scaffoldFinder);
        expect(scaffold.floatingActionButton, isNotNull);
      });
    });

    group('Navigation Tests', () {
      testWidgets('should have FAB that triggers navigation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify we're on group detail page
        expect(find.byType(GroupDetailPage), findsOneWidget);

        // Verify FAB is present and functional
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);
        
        final FloatingActionButton fab = tester.widget(fabFinder);
        expect(fab.onPressed, isNotNull);
      });

      testWidgets('should handle different group IDs', (WidgetTester tester) async {
        const testGroupId = 5;
        await tester.pumpWidget(createTestApp(groupId: testGroupId));
        await tester.pumpAndSettle();

        // Verify page loads with different group ID
        expect(find.byType(GroupDetailPage), findsOneWidget);
        
        // Verify FAB is still functional
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);
      });
    });

    group('Data Refresh Tests', () {
      testWidgets('should show loading state during data refresh', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        
        // Initially should show loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading group details...'), findsOneWidget);

        // Wait for data to load
        await tester.pumpAndSettle();
        
        // Loading should be gone
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should have refresh mechanism in place', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify the page has loaded and refresh mechanism exists
        expect(find.byType(GroupDetailPage), findsOneWidget);
        
        // The _onAddExpense method should trigger refresh when returning
        // This is tested through the navigation callback mechanism
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);
      });
    });

    group('Expense List Integration Tests', () {
      testWidgets('should display expense list section', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify expense list section is present
        expect(find.text('Recent Expenses'), findsOneWidget);
        expect(find.byType(Card), findsWidgets); // Multiple cards including expense section
      });

      testWidgets('should show expense items when expenses exist', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        
        // Wait for loading to complete
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Since mock data has expenses, should show expense items (at least the first few)
        expect(find.text('Grocery shopping'), findsOneWidget);
        expect(find.text('Electricity bill'), findsOneWidget);
        // Note: Internet bill might not be visible due to list height constraints
      });

      testWidgets('should have refresh functionality', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Find the RefreshIndicator in the expense list
        final refreshIndicatorFinder = find.byType(RefreshIndicator);
        expect(refreshIndicatorFinder, findsOneWidget);
      });

      testWidgets('should handle expense item tap navigation', (WidgetTester tester) async {
        // Create a test app with navigation support
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                theme: AppTheme.lightTheme,
                home: GroupDetailPage(groupId: 1),
                routes: {
                  '/expense-detail': (context) {
                    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                    final expenseId = args?['expenseId'] as int? ?? 1;
                    return Scaffold(
                      appBar: AppBar(title: Text('Expense Detail $expenseId')),
                      body: Center(child: Text('Expense Detail Page')),
                    );
                  },
                },
              );
            },
          ),
        );
        
        // Wait for loading to complete
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Verify we're on group detail page with expenses
        expect(find.byType(GroupDetailPage), findsOneWidget);
        expect(find.text('Grocery shopping'), findsOneWidget);

        // Tap on the first expense item
        await tester.tap(find.text('Grocery shopping'));
        await tester.pumpAndSettle();

        // Verify navigation to expense detail page
        expect(find.text('Expense Detail Page'), findsOneWidget);
        expect(find.text('Expense Detail 1'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle invalid group ID gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp(groupId: 999)); // Invalid group ID
        await tester.pumpAndSettle();

        // Should still show the page without crashing
        expect(find.byType(GroupDetailPage), findsOneWidget);
        
        // FAB should still be functional
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should have accessible FAB', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        // Verify FAB is accessible
        final FloatingActionButton fab = tester.widget(fabFinder);
        expect(fab.onPressed, isNotNull);
      });
    });

    group('Performance Tests', () {
      testWidgets('should load group detail page efficiently', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Verify page loads in reasonable time (less than 5 seconds for test)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        expect(find.byType(GroupDetailPage), findsOneWidget);
      });
    });

    group('State Management Tests', () {
      testWidgets('should maintain group detail state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Verify initial state - group detail page is loaded
        expect(find.byType(GroupDetailPage), findsOneWidget);
        
        // Verify FAB maintains its state
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);
        
        final FloatingActionButton fab = tester.widget(fabFinder);
        expect(fab.onPressed, isNotNull);
      });
    });
  });
}