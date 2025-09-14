import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/group_detail/widgets/settlements_widget.dart';
import 'package:camsplit/models/settlement.dart';

void main() {
  group('SettlementsWidget', () {
    testWidgets('displays empty state when no settlements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettlementsWidget(
              settlements: [],
              currentUserId: 1,
            ),
          ),
        ),
      );

      expect(find.text('Settlements'), findsOneWidget);
      expect(find.text('No settlements found'), findsOneWidget);
      expect(find.text('Settlements will appear here when they are calculated'), findsOneWidget);
    });

    testWidgets('displays settlements when available', (WidgetTester tester) async {
      final settlements = [
        Settlement(
          id: 1,
          groupId: 1,
          fromGroupMemberId: 1,
          toGroupMemberId: 2,
          amount: 25.00,
          currency: 'EUR',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          fromMember: {'nickname': 'John Doe'},
          toMember: {'nickname': 'Jane Smith'},
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettlementsWidget(
              settlements: settlements,
              currentUserId: 1,
            ),
          ),
        ),
      );

      expect(find.text('Settlements'), findsOneWidget);
      expect(find.text('John Doe owes Jane Smith'), findsOneWidget);
      expect(find.text('25.00 EUR'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('displays user perspective when user is involved', (WidgetTester tester) async {
      final settlements = [
        Settlement(
          id: 1,
          groupId: 1,
          fromGroupMemberId: 1,
          toGroupMemberId: 2,
          amount: 25.00,
          currency: 'EUR',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          fromMember: {'nickname': 'John Doe'},
          toMember: {'nickname': 'Jane Smith'},
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettlementsWidget(
              settlements: settlements,
              currentUserId: 1, // User is the debtor
            ),
          ),
        ),
      );

      expect(find.text('You owe Jane Smith'), findsOneWidget);
    });

    testWidgets('displays settled settlements with different styling', (WidgetTester tester) async {
      final settlements = [
        Settlement(
          id: 1,
          groupId: 1,
          fromGroupMemberId: 1,
          toGroupMemberId: 2,
          amount: 25.00,
          currency: 'EUR',
          status: 'settled',
          settledAt: DateTime.now(),
          settledBy: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          fromMember: {'nickname': 'John Doe'},
          toMember: {'nickname': 'Jane Smith'},
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SettlementsWidget(
              settlements: settlements,
              currentUserId: 1,
            ),
          ),
        ),
      );

      expect(find.text('SETTLED'), findsOneWidget);
    });
  });
} 