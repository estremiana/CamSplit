import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:splitease/presentation/group_detail/widgets/balance_summary_widget.dart';
import 'package:splitease/theme/app_theme.dart';

void main() {
  group('BalanceSummaryWidget Tests', () {
    Widget createTestWidget(double balance, {String currency = 'EUR'}) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: BalanceSummaryWidget(
                balance: balance,
                currency: currency,
              ),
            ),
          );
        },
      );
    }

    Widget createDarkTestWidget(double balance, {String currency = 'EUR'}) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: BalanceSummaryWidget(
                balance: balance,
                currency: currency,
              ),
            ),
          );
        },
      );
    }

    group('Positive Balance Tests', () {
      testWidgets('should display positive balance correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(25.50));

        expect(find.text('Your Balance'), findsOneWidget);
        expect(find.text('25.50EUR'), findsOneWidget);
        expect(find.text('You are owed 25.50EUR'), findsOneWidget);
      });

      testWidgets('should use success color for positive balance', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(15.75));

        // Find the balance amount text widget
        final balanceTextFinder = find.text('15.75EUR');
        expect(balanceTextFinder, findsOneWidget);

        final Text balanceTextWidget = tester.widget(balanceTextFinder);
        expect(balanceTextWidget.style?.color, AppTheme.successLight);
      });

      testWidgets('should use success background for positive balance', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(10.00));

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, AppTheme.successLight.withValues(alpha: 0.1));
      });

      testWidgets('should handle large positive amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(1234.56));

        expect(find.text('1234.56EUR'), findsOneWidget);
        expect(find.text('You are owed 1234.56EUR'), findsOneWidget);
      });

      testWidgets('should handle small positive amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(0.01));

        expect(find.text('0.01EUR'), findsOneWidget);
        expect(find.text('You are owed 0.01EUR'), findsOneWidget);
      });
    });

    group('Negative Balance Tests', () {
      testWidgets('should display negative balance correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(-30.25));

        expect(find.text('Your Balance'), findsOneWidget);
        expect(find.text('30.25EUR'), findsOneWidget);
        expect(find.text('You owe 30.25EUR'), findsOneWidget);
      });

      testWidgets('should use error color for negative balance', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(-20.50));

        // Find the balance amount text widget
        final balanceTextFinder = find.text('20.50EUR');
        expect(balanceTextFinder, findsOneWidget);

        final Text balanceTextWidget = tester.widget(balanceTextFinder);
        expect(balanceTextWidget.style?.color, AppTheme.errorLight);
      });

      testWidgets('should use error background for negative balance', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(-15.00));

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, AppTheme.errorLight.withValues(alpha: 0.1));
      });

      testWidgets('should handle large negative amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(-999.99));

        expect(find.text('999.99EUR'), findsOneWidget);
        expect(find.text('You owe 999.99EUR'), findsOneWidget);
      });

      testWidgets('should handle small negative amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(-0.05));

        expect(find.text('0.05EUR'), findsOneWidget);
        expect(find.text('You owe 0.05EUR'), findsOneWidget);
      });
    });

    group('Zero Balance Tests', () {
      testWidgets('should display zero balance correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(0.00));

        expect(find.text('Your Balance'), findsOneWidget);
        expect(find.text('0.00EUR'), findsOneWidget);
        expect(find.text('You are settled up'), findsOneWidget);
      });

      testWidgets('should use neutral color for zero balance', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(0.00));

        // Find the balance amount text widget
        final balanceTextFinder = find.text('0.00EUR');
        expect(balanceTextFinder, findsOneWidget);

        final Text balanceTextWidget = tester.widget(balanceTextFinder);
        expect(balanceTextWidget.style?.color, AppTheme.textPrimaryLight);
      });

      testWidgets('should use card background for zero balance', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(0.00));

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, AppTheme.cardLight);
      });
    });

    group('Currency Tests', () {
      testWidgets('should display USD currency correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(50.00, currency: 'USD'));

        expect(find.text('50.00USD'), findsOneWidget);
        expect(find.text('You are owed 50.00USD'), findsOneWidget);
      });

      testWidgets('should display GBP currency correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(-25.75, currency: 'GBP'));

        expect(find.text('25.75GBP'), findsOneWidget);
        expect(find.text('You owe 25.75GBP'), findsOneWidget);
      });

      testWidgets('should handle empty currency string', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(10.00, currency: ''));

        expect(find.text('10.00'), findsOneWidget);
        expect(find.text('You are owed 10.00'), findsOneWidget);
      });

      testWidgets('should handle long currency codes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(15.50, currency: 'CRYPTO'));

        expect(find.text('15.50CRYPTO'), findsOneWidget);
        expect(find.text('You are owed 15.50CRYPTO'), findsOneWidget);
      });
    });

    group('Dark Theme Tests', () {
      testWidgets('should use dark theme colors for positive balance', (WidgetTester tester) async {
        await tester.pumpWidget(createDarkTestWidget(25.00));

        final balanceTextFinder = find.text('25.00EUR');
        expect(balanceTextFinder, findsOneWidget);

        final Text balanceTextWidget = tester.widget(balanceTextFinder);
        expect(balanceTextWidget.style?.color, AppTheme.successDark);

        final containerFinder = find.byType(Container);
        final Container container = tester.widget(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, AppTheme.successDark.withValues(alpha: 0.1));
      });

      testWidgets('should use dark theme colors for negative balance', (WidgetTester tester) async {
        await tester.pumpWidget(createDarkTestWidget(-30.00));

        final balanceTextFinder = find.text('30.00EUR');
        expect(balanceTextFinder, findsOneWidget);

        final Text balanceTextWidget = tester.widget(balanceTextFinder);
        expect(balanceTextWidget.style?.color, AppTheme.errorDark);

        final containerFinder = find.byType(Container);
        final Container container = tester.widget(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, AppTheme.errorDark.withValues(alpha: 0.1));
      });

      testWidgets('should use dark theme colors for zero balance', (WidgetTester tester) async {
        await tester.pumpWidget(createDarkTestWidget(0.00));

        final balanceTextFinder = find.text('0.00EUR');
        expect(balanceTextFinder, findsOneWidget);

        final Text balanceTextWidget = tester.widget(balanceTextFinder);
        expect(balanceTextWidget.style?.color, AppTheme.textPrimaryDark);

        final containerFinder = find.byType(Container);
        final Container container = tester.widget(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, AppTheme.cardDark);
      });
    });

    group('Widget Structure Tests', () {
      testWidgets('should have proper card structure', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(10.00));

        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);

        final Card card = tester.widget(cardFinder);
        expect(card.elevation, 2.0);
        expect(card.margin, const EdgeInsets.symmetric(horizontal: 16, vertical: 8));
      });

      testWidgets('should have proper container structure', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(10.00));

        final containerFinder = find.byType(Container);
        expect(containerFinder, findsOneWidget);

        final Container container = tester.widget(containerFinder);
        expect(container.padding, const EdgeInsets.all(20));
        expect(container.constraints?.maxWidth, double.infinity);

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(12.0));
      });

      testWidgets('should have proper column layout', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(10.00));

        final columnFinder = find.byType(Column);
        expect(columnFinder, findsOneWidget);

        final Column column = tester.widget(columnFinder);
        expect(column.mainAxisSize, MainAxisSize.min);
        expect(column.children.length, 5); // Title, SizedBox, Balance, SizedBox, Message
      });

      testWidgets('should have proper text alignment', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(10.00));

        final balanceTextFinder = find.text('10.00EUR');
        final Text balanceTextWidget = tester.widget(balanceTextFinder);
        expect(balanceTextWidget.textAlign, TextAlign.center);

        final messageTextFinder = find.text('You are owed 10.00EUR');
        final Text messageTextWidget = tester.widget(messageTextFinder);
        expect(messageTextWidget.textAlign, TextAlign.center);
      });
    });

    group('Text Style Tests', () {
      testWidgets('should use correct text styles', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(25.50));

        // Check title style
        final titleFinder = find.text('Your Balance');
        final Text titleWidget = tester.widget(titleFinder);
        expect(titleWidget.style?.fontWeight, FontWeight.w500);

        // Check balance amount style
        final balanceFinder = find.text('25.50EUR');
        final Text balanceWidget = tester.widget(balanceFinder);
        expect(balanceWidget.style?.fontWeight, FontWeight.w600);

        // Check message style
        final messageFinder = find.text('You are owed 25.50EUR');
        final Text messageWidget = tester.widget(messageFinder);
        expect(messageWidget.style?.fontWeight, FontWeight.w400);
      });

      testWidgets('should use correct text colors for labels', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(10.00));

        final titleFinder = find.text('Your Balance');
        final Text titleWidget = tester.widget(titleFinder);
        expect(titleWidget.style?.color, AppTheme.textSecondaryLight);

        final messageFinder = find.text('You are owed 10.00EUR');
        final Text messageWidget = tester.widget(messageFinder);
        expect(messageWidget.style?.color, AppTheme.textSecondaryLight);
      });
    });

    group('Edge Cases Tests', () {
      testWidgets('should handle very small positive amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(0.001));

        expect(find.text('0.00EUR'), findsOneWidget);
        expect(find.text('You are owed 0.00EUR'), findsOneWidget);
      });

      testWidgets('should handle very small negative amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(-0.001));

        expect(find.text('0.00EUR'), findsOneWidget);
        expect(find.text('You owe 0.00EUR'), findsOneWidget);
      });

      testWidgets('should handle extremely large amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(999999.99));

        expect(find.text('999999.99EUR'), findsOneWidget);
        expect(find.text('You are owed 999999.99EUR'), findsOneWidget);
      });

      testWidgets('should handle negative zero', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(-0.0));

        expect(find.text('0.00EUR'), findsOneWidget);
        expect(find.text('You are settled up'), findsOneWidget);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should be accessible with screen readers', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(50.00));

        // Verify that all text widgets are present and readable
        expect(find.text('Your Balance'), findsOneWidget);
        expect(find.text('50.00EUR'), findsOneWidget);
        expect(find.text('You are owed 50.00EUR'), findsOneWidget);

        // Verify widget structure supports accessibility
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
      });

      testWidgets('should maintain proper semantic structure', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(-25.00));

        // Verify the widget hierarchy is logical for screen readers
        final columnFinder = find.byType(Column);
        expect(columnFinder, findsOneWidget);

        final Column column = tester.widget(columnFinder);
        expect(column.children.length, 5);
      });
    });
  });
}