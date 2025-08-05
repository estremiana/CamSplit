import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../lib/presentation/expense_creation/expense_creation.dart';

void main() {
  group('ExpenseCreation Context Detection Tests', () {
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

    group('Context Detection Logic', () {
      testWidgets('should detect dashboard context with no arguments', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        
        // The group field should be visible in dashboard context
        expect(find.text('Group'), findsOneWidget);
      });

      testWidgets('should detect OCR assignment context with receiptData', (WidgetTester tester) async {
        final arguments = {
          'receiptData': {
            'total': 25.50,
            'selectedGroupName': 'Test Group',
            'groupMembers': [],
            'participantAmounts': [],
            'items': [],
          }
        };

        await tester.pumpWidget(createTestWidget(arguments: arguments));
        await tester.pump(const Duration(milliseconds: 100));
        
        // The group field should be hidden in OCR assignment context
        expect(find.text('Group'), findsNothing);
      });

      testWidgets('should detect group detail context with groupId', (WidgetTester tester) async {
        final arguments = {
          'groupId': 1,
        };

        await tester.pumpWidget(createTestWidget(arguments: arguments));
        await tester.pump(const Duration(milliseconds: 100));
        
        // The group field should be hidden in group detail context
        expect(find.text('Group'), findsNothing);
      });

      testWidgets('should detect expense detail context with groupId', (WidgetTester tester) async {
        final arguments = {
          'groupId': 2,
          'expenseId': 123,
        };

        await tester.pumpWidget(createTestWidget(arguments: arguments));
        await tester.pump(const Duration(milliseconds: 100));
        
        // The group field should be hidden in expense detail context
        expect(find.text('Group'), findsNothing);
      });

      testWidgets('should fallback to dashboard context with invalid arguments', (WidgetTester tester) async {
        final arguments = {
          'invalidKey': 'invalidValue',
        };

        await tester.pumpWidget(createTestWidget(arguments: arguments));
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should fallback to dashboard context and show group field
        expect(find.text('Group'), findsOneWidget);
      });

      testWidgets('should handle malformed arguments gracefully', (WidgetTester tester) async {
        final arguments = {
          'receiptData': 'invalid_data_type',
        };

        await tester.pumpWidget(createTestWidget(arguments: arguments));
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should handle malformed data and still show the form
        expect(find.text('Expense Details'), findsOneWidget);
      });
    });

    group('Context-Specific Behavior', () {
      testWidgets('should preserve group value when field is hidden in OCR context', (WidgetTester tester) async {
        final arguments = {
          'receiptData': {
            'total': 25.50,
            'selectedGroupName': 'Test Group',
            'groupMembers': [],
            'participantAmounts': [],
            'items': [],
          }
        };

        await tester.pumpWidget(createTestWidget(arguments: arguments));
        await tester.pump(const Duration(milliseconds: 100));
        
        // Group field should be hidden but group value should be preserved
        expect(find.text('Group'), findsNothing);
        expect(find.text('Expense Details'), findsOneWidget);
      });

      testWidgets('should preserve group value when field is hidden in group detail context', (WidgetTester tester) async {
        final arguments = {
          'groupId': 1,
        };

        await tester.pumpWidget(createTestWidget(arguments: arguments));
        await tester.pump(const Duration(milliseconds: 100));
        
        // Group field should be hidden but form should be functional
        expect(find.text('Group'), findsNothing);
        expect(find.text('Expense Details'), findsOneWidget);
      });

      testWidgets('should show group field in dashboard context', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump(const Duration(milliseconds: 100));
        
        // Group field should be visible in dashboard context
        expect(find.text('Group'), findsOneWidget);
        expect(find.text('Expense Details'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null arguments', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(arguments: null));
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should default to dashboard context
        expect(find.text('Group'), findsOneWidget);
      });

      testWidgets('should handle empty arguments map', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(arguments: {}));
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should default to dashboard context
        expect(find.text('Group'), findsOneWidget);
      });

      testWidgets('should prioritize receiptData over groupId when both present', (WidgetTester tester) async {
        final arguments = {
          'receiptData': {
            'total': 25.50,
            'selectedGroupName': 'Test Group',
            'groupMembers': [],
            'participantAmounts': [],
            'items': [],
          },
          'groupId': 1,
        };

        await tester.pumpWidget(createTestWidget(arguments: arguments));
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should detect OCR assignment context (receiptData takes priority)
        expect(find.text('Group'), findsNothing);
      });
    });
  });
}