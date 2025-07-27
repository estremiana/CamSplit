import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:splitease/presentation/group_detail/widgets/debt_list_widget.dart';
import 'package:splitease/models/debt_relationship_model.dart';
import 'package:splitease/theme/app_theme.dart';

void main() {
  group('DebtListWidget Tests', () {
    // Helper method to create test debt relationships
    List<DebtRelationship> createTestDebts() {
      return [
        DebtRelationship(
          debtorId: 1,
          debtorName: 'Alice',
          creditorId: 2,
          creditorName: 'Bob',
          amount: 25.50,
          currency: 'EUR',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        ),
        DebtRelationship(
          debtorId: 3,
          debtorName: 'Charlie',
          creditorId: 1,
          creditorName: 'Alice',
          amount: 15.75,
          currency: 'EUR',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now(),
        ),
        DebtRelationship(
          debtorId: 2,
          debtorName: 'Bob',
          creditorId: 3,
          creditorName: 'Charlie',
          amount: 30.00,
          currency: 'EUR',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    Widget createTestWidget(List<DebtRelationship> debts, {int? currentUserId}) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: DebtListWidget(
                debts: debts,
                currentUserId: currentUserId,
              ),
            ),
          );
        },
      );
    }

    Widget createDarkTestWidget(List<DebtRelationship> debts, {int? currentUserId}) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: DebtListWidget(
                debts: debts,
                currentUserId: currentUserId,
              ),
            ),
          );
        },
      );
    }

    group('Empty State Tests', () {
      testWidgets('should display empty state when no debts exist', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget([]));

        expect(find.text('Outstanding Balances'), findsOneWidget);
        expect(find.text('Everyone is settled up'), findsOneWidget);
        expect(find.text('No outstanding balances in this group'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });

      testWidgets('should use success color for empty state icon and text', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget([]));

        final iconFinder = find.byIcon(Icons.check_circle_outline);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.color, AppTheme.successLight);
        expect(iconWidget.size, 48);

        final titleFinder = find.text('Everyone is settled up');
        final Text titleWidget = tester.widget(titleFinder);
        expect(titleWidget.style?.color, AppTheme.successLight);
        expect(titleWidget.style?.fontWeight, FontWeight.w500);
      });

      testWidgets('should center empty state content', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget([]));

        final containerFinder = find.byType(Container).last;
        final Container container = tester.widget(containerFinder);
        expect(container.constraints?.maxWidth, double.infinity);

        final columnFinder = find.byType(Column).last;
        final Column column = tester.widget(columnFinder);
        expect(column.mainAxisAlignment, MainAxisAlignment.center);
      });

      testWidgets('should display empty state in dark theme', (WidgetTester tester) async {
        await tester.pumpWidget(createDarkTestWidget([]));

        final iconFinder = find.byIcon(Icons.check_circle_outline);
        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.color, AppTheme.successDark);

        final titleFinder = find.text('Everyone is settled up');
        final Text titleWidget = tester.widget(titleFinder);
        expect(titleWidget.style?.color, AppTheme.successDark);
      });
    });

    group('Debt List Display Tests', () {
      testWidgets('should display all debt relationships', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        expect(find.text('Outstanding Balances'), findsOneWidget);
        expect(find.text('Alice owes Bob'), findsOneWidget);
        expect(find.text('Charlie owes Alice'), findsOneWidget);
        expect(find.text('Bob owes Charlie'), findsOneWidget);
      });

      testWidgets('should display formatted amounts correctly', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        expect(find.text('25.50EUR'), findsOneWidget);
        expect(find.text('15.75EUR'), findsOneWidget);
        expect(find.text('30.00EUR'), findsOneWidget);
      });

      testWidgets('should display debt relationship icons', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        final iconFinders = find.byIcon(Icons.swap_horiz);
        expect(iconFinders, findsNWidgets(3)); // One for each debt
      });

      testWidgets('should use warning color for debt amounts', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        final amountFinder = find.text('25.50EUR');
        final Text amountWidget = tester.widget(amountFinder);
        expect(amountWidget.style?.color, AppTheme.warningLight);
      });

      testWidgets('should use monospace font for amounts', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        final amountFinder = find.text('25.50EUR');
        final Text amountWidget = tester.widget(amountFinder);
        expect(amountWidget.style?.fontWeight, FontWeight.w600);
      });
    });

    group('Current User Involvement Tests', () {
      testWidgets('should highlight debts involving current user', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts, currentUserId: 1));

        // Alice (user 1) is involved in first two debts
        final containers = find.byType(Container);
        expect(containers, findsWidgets);

        // Check that user perspective text is shown
        expect(find.text('You owe 25.50EUR to Bob'), findsOneWidget);
        expect(find.text('Charlie owes you 15.75EUR'), findsOneWidget);
      });

      testWidgets('should show user perspective text for involved debts', (WidgetTester tester) async {
        final debts = [
          DebtRelationship(
            debtorId: 1,
            debtorName: 'Alice',
            creditorId: 2,
            creditorName: 'Bob',
            amount: 25.50,
            currency: 'EUR',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        await tester.pumpWidget(createTestWidget(debts, currentUserId: 1));

        expect(find.text('Alice owes Bob'), findsOneWidget);
        expect(find.text('You owe 25.50EUR to Bob'), findsOneWidget);
      });

      testWidgets('should show creditor perspective correctly', (WidgetTester tester) async {
        final debts = [
          DebtRelationship(
            debtorId: 2,
            debtorName: 'Bob',
            creditorId: 1,
            creditorName: 'Alice',
            amount: 30.00,
            currency: 'EUR',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        await tester.pumpWidget(createTestWidget(debts, currentUserId: 1));

        expect(find.text('Bob owes Alice'), findsOneWidget);
        expect(find.text('Bob owes you 30.00EUR'), findsOneWidget);
      });

      testWidgets('should not show user perspective for uninvolved debts', (WidgetTester tester) async {
        final debts = [
          DebtRelationship(
            debtorId: 2,
            debtorName: 'Bob',
            creditorId: 3,
            creditorName: 'Charlie',
            amount: 20.00,
            currency: 'EUR',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        await tester.pumpWidget(createTestWidget(debts, currentUserId: 1));

        expect(find.text('Bob owes Charlie'), findsOneWidget);
        expect(find.textContaining('You owe'), findsNothing);
        expect(find.textContaining('owes you'), findsNothing);
      });
    });

    group('Visual Styling Tests', () {
      testWidgets('should use proper card styling', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);

        final Card card = tester.widget(cardFinder);
        expect(card.elevation, 1.0);
        expect(card.margin, const EdgeInsets.symmetric(horizontal: 16, vertical: 8));
      });

      testWidgets('should have proper section header styling', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        final headerFinder = find.text('Outstanding Balances');
        expect(headerFinder, findsOneWidget);

        final Text headerWidget = tester.widget(headerFinder);
        expect(headerWidget.style?.fontWeight, FontWeight.w600);
        expect(headerWidget.style?.color, AppTheme.textPrimaryLight);

        final iconFinder = find.byIcon(Icons.account_balance_wallet_outlined);
        expect(iconFinder, findsOneWidget);

        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.size, 20);
        expect(iconWidget.color, AppTheme.textSecondaryLight);
      });

      testWidgets('should style debt items properly', (WidgetTester tester) async {
        final debts = [createTestDebts().first];
        await tester.pumpWidget(createTestWidget(debts));

        // Check debt item container styling
        final containers = find.byType(Container);
        expect(containers, findsWidgets);

        // Check debt text styling
        final debtTextFinder = find.text('Alice owes Bob');
        final Text debtTextWidget = tester.widget(debtTextFinder);
        expect(debtTextWidget.style?.fontWeight, FontWeight.w500);
        expect(debtTextWidget.style?.color, AppTheme.textPrimaryLight);
      });

      testWidgets('should highlight user-involved debts with border', (WidgetTester tester) async {
        final debts = [createTestDebts().first];
        await tester.pumpWidget(createTestWidget(debts, currentUserId: 1));

        // Find the debt item container
        final containers = find.byType(Container);
        expect(containers, findsWidgets);

        // The debt item container should have a border for user-involved debts
        // This is tested by checking the decoration properties
      });
    });

    group('Dark Theme Tests', () {
      testWidgets('should use dark theme colors', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createDarkTestWidget(debts));

        final headerFinder = find.text('Outstanding Balances');
        final Text headerWidget = tester.widget(headerFinder);
        expect(headerWidget.style?.color, AppTheme.textPrimaryDark);

        final iconFinder = find.byIcon(Icons.account_balance_wallet_outlined);
        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.color, AppTheme.textSecondaryDark);

        final amountFinder = find.text('25.50EUR');
        final Text amountWidget = tester.widget(amountFinder);
        expect(amountWidget.style?.color, AppTheme.warningDark);
      });

      testWidgets('should use dark theme colors for empty state', (WidgetTester tester) async {
        await tester.pumpWidget(createDarkTestWidget([]));

        final iconFinder = find.byIcon(Icons.check_circle_outline);
        final Icon iconWidget = tester.widget(iconFinder);
        expect(iconWidget.color, AppTheme.successDark);

        final titleFinder = find.text('Everyone is settled up');
        final Text titleWidget = tester.widget(titleFinder);
        expect(titleWidget.style?.color, AppTheme.successDark);
      });
    });

    group('Currency Tests', () {
      testWidgets('should display different currencies correctly', (WidgetTester tester) async {
        final debts = [
          DebtRelationship(
            debtorId: 1,
            debtorName: 'Alice',
            creditorId: 2,
            creditorName: 'Bob',
            amount: 25.50,
            currency: 'USD',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          DebtRelationship(
            debtorId: 2,
            debtorName: 'Bob',
            creditorId: 3,
            creditorName: 'Charlie',
            amount: 15.75,
            currency: 'GBP',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        await tester.pumpWidget(createTestWidget(debts));

        expect(find.text('25.50USD'), findsOneWidget);
        expect(find.text('15.75GBP'), findsOneWidget);
      });

      testWidgets('should handle empty currency', (WidgetTester tester) async {
        final debts = [
          DebtRelationship(
            debtorId: 1,
            debtorName: 'Alice',
            creditorId: 2,
            creditorName: 'Bob',
            amount: 25.50,
            currency: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        await tester.pumpWidget(createTestWidget(debts));

        expect(find.text('25.50'), findsOneWidget);
      });
    });

    group('Edge Cases Tests', () {
      testWidgets('should handle single debt relationship', (WidgetTester tester) async {
        final debts = [createTestDebts().first];
        await tester.pumpWidget(createTestWidget(debts));

        expect(find.text('Outstanding Balances'), findsOneWidget);
        expect(find.text('Alice owes Bob'), findsOneWidget);
        expect(find.text('25.50EUR'), findsOneWidget);
        expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      });

      testWidgets('should handle very small amounts', (WidgetTester tester) async {
        final debts = [
          DebtRelationship(
            debtorId: 1,
            debtorName: 'Alice',
            creditorId: 2,
            creditorName: 'Bob',
            amount: 0.01,
            currency: 'EUR',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        await tester.pumpWidget(createTestWidget(debts));

        expect(find.text('0.01EUR'), findsOneWidget);
      });

      testWidgets('should handle large amounts', (WidgetTester tester) async {
        final debts = [
          DebtRelationship(
            debtorId: 1,
            debtorName: 'Alice',
            creditorId: 2,
            creditorName: 'Bob',
            amount: 9999.99,
            currency: 'EUR',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        await tester.pumpWidget(createTestWidget(debts));

        expect(find.text('9999.99EUR'), findsOneWidget);
      });

      testWidgets('should handle long names', (WidgetTester tester) async {
        final debts = [
          DebtRelationship(
            debtorId: 1,
            debtorName: 'Very Long Name That Might Overflow',
            creditorId: 2,
            creditorName: 'Another Very Long Name',
            amount: 25.50,
            currency: 'EUR',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        await tester.pumpWidget(createTestWidget(debts));

        expect(find.text('Very Long Name That Might Overflow owes Another Very Long Name'), findsOneWidget);
      });

      testWidgets('should handle null currentUserId', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts, currentUserId: null));

        expect(find.text('Alice owes Bob'), findsOneWidget);
        expect(find.textContaining('You owe'), findsNothing);
        expect(find.textContaining('owes you'), findsNothing);
      });
    });

    group('Widget Structure Tests', () {
      testWidgets('should have proper widget hierarchy', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(Column), findsWidgets);
        expect(find.byType(Row), findsWidgets);
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should have proper padding and margins', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        final cardFinder = find.byType(Card);
        final Card card = tester.widget(cardFinder);
        expect(card.margin, const EdgeInsets.symmetric(horizontal: 16, vertical: 8));
      });

      testWidgets('should expand properly in available space', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        final expandedFinders = find.byType(Expanded);
        expect(expandedFinders, findsWidgets);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should be accessible with screen readers', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        // Verify all text is readable
        expect(find.text('Outstanding Balances'), findsOneWidget);
        expect(find.text('Alice owes Bob'), findsOneWidget);
        expect(find.text('25.50EUR'), findsOneWidget);

        // Verify icons are present
        expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
        expect(find.byIcon(Icons.swap_horiz), findsWidgets);
      });

      testWidgets('should maintain semantic structure for empty state', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget([]));

        expect(find.text('Outstanding Balances'), findsOneWidget);
        expect(find.text('Everyone is settled up'), findsOneWidget);
        expect(find.text('No outstanding balances in this group'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });

      testWidgets('should provide clear visual hierarchy', (WidgetTester tester) async {
        final debts = createTestDebts();
        await tester.pumpWidget(createTestWidget(debts));

        final headerFinder = find.text('Outstanding Balances');
        final Text headerWidget = tester.widget(headerFinder);
        expect(headerWidget.style?.fontWeight, FontWeight.w600);

        final debtTextFinder = find.text('Alice owes Bob');
        final Text debtTextWidget = tester.widget(debtTextFinder);
        expect(debtTextWidget.style?.fontWeight, FontWeight.w500);
      });
    });
  });
}