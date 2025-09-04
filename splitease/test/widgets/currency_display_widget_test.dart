import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:sizer/sizer.dart';

import '../../lib/widgets/currency_display_widget.dart';
import '../../lib/theme/app_theme.dart';

void main() {
  group('CurrencyDisplayWidget Tests', () {
    late Currency eurCurrency;
    late Currency usdCurrency;
    late Currency jpyCurrency;
    late Currency brlCurrency;
    
    setUp(() {
      eurCurrency = Currency(
        code: 'EUR',
        name: 'Euro',
        symbol: '€',
        flag: '🇪🇺',
        number: 978,
        decimalDigits: 2,
        namePlural: 'Euros',
        symbolOnLeft: true,
        decimalSeparator: '.',
        thousandsSeparator: ',',
        spaceBetweenAmountAndSymbol: false,
      );
      
      usdCurrency = Currency(
        code: 'USD',
        name: 'US Dollar',
        symbol: '\$',
        flag: '🇺🇸',
        number: 840,
        decimalDigits: 2,
        namePlural: 'US Dollars',
        symbolOnLeft: true,
        decimalSeparator: '.',
        thousandsSeparator: ',',
        spaceBetweenAmountAndSymbol: false,
      );
      
      jpyCurrency = Currency(
        code: 'JPY',
        name: 'Japanese Yen',
        symbol: '¥',
        flag: '🇯🇵',
        number: 392,
        decimalDigits: 0,
        namePlural: 'Japanese Yen',
        symbolOnLeft: true,
        decimalSeparator: '.',
        thousandsSeparator: ',',
        spaceBetweenAmountAndSymbol: false,
      );
      
      brlCurrency = Currency(
        code: 'BRL',
        name: 'Brazilian Real',
        symbol: 'R\$',
        flag: '🇧🇷',
        number: 986,
        decimalDigits: 2,
        namePlural: 'Brazilian Reais',
        symbolOnLeft: true,
        decimalSeparator: ',',
        thousandsSeparator: '.',
        spaceBetweenAmountAndSymbol: true,
      );
    });

    Widget createTestWidget({
      required double amount,
      required Currency currency,
      TextStyle? style,
      bool isPrivacyMode = false,
      int? decimalPlaces,
      bool showCurrencyCode = false,
      bool useMinimalFormatting = false,
      bool useParenthesesForNegative = false,
      TextAlign? textAlign,
      bool isCompact = false,
      int compactThreshold = 4,
    }) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CurrencyDisplayWidget(
                amount: amount,
                currency: currency,
                style: style,
                isPrivacyMode: isPrivacyMode,
                decimalPlaces: decimalPlaces,
                showCurrencyCode: showCurrencyCode,
                useMinimalFormatting: useMinimalFormatting,
                useParenthesesForNegative: useParenthesesForNegative,
                textAlign: textAlign,
                isCompact: isCompact,
                compactThreshold: compactThreshold,
              ),
            ),
          );
        },
      );
    }

    group('Basic Formatting', () {
      testWidgets('should display EUR amount correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: eurCurrency,
        ));
        
        expect(find.text('€1,234.56'), findsOneWidget);
      });

      testWidgets('should display USD amount correctly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: usdCurrency,
        ));
        
        expect(find.text('\$1,234.56'), findsOneWidget);
      });

      testWidgets('should display JPY amount correctly (no decimals)', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: jpyCurrency,
        ));
        
        expect(find.text('¥1,235'), findsOneWidget);
      });

      testWidgets('should display BRL amount correctly (custom separators)', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: brlCurrency,
        ));
        
        expect(find.text('R\$ 1.234,56'), findsOneWidget);
      });

      testWidgets('should handle zero amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 0.0,
          currency: eurCurrency,
        ));
        
        expect(find.text('€0.00'), findsOneWidget);
      });

      testWidgets('should handle negative amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: -1234.56,
          currency: eurCurrency,
        ));
        
        expect(find.text('€-1,234.56'), findsOneWidget);
      });

      testWidgets('should handle small amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 0.99,
          currency: eurCurrency,
        ));
        
        expect(find.text('€0.99'), findsOneWidget);
      });
    });

    group('Privacy Mode', () {
      testWidgets('should display asterisks in privacy mode', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: eurCurrency,
          isPrivacyMode: true,
        ));
        
        expect(find.text('***'), findsOneWidget);
      });

      testWidgets('should not show actual amount in privacy mode', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: eurCurrency,
          isPrivacyMode: true,
        ));
        
        expect(find.text('€1,234.56'), findsNothing);
      });
    });

    group('Currency Code Display', () {
      testWidgets('should show currency code when requested', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: eurCurrency,
          showCurrencyCode: true,
        ));
        
        expect(find.text('€1,234.56 EUR'), findsOneWidget);
      });

      testWidgets('should not show currency code by default', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: eurCurrency,
        ));
        
        expect(find.text('€1,234.56 EUR'), findsNothing);
      });
    });

    group('Minimal Formatting', () {
      testWidgets('should remove trailing zeros with minimal formatting', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.00,
          currency: eurCurrency,
          useMinimalFormatting: true,
        ));
        
        expect(find.text('€1,234'), findsOneWidget);
      });

      testWidgets('should keep necessary decimal places with minimal formatting', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.10,
          currency: eurCurrency,
          useMinimalFormatting: true,
        ));
        
        expect(find.text('€1,234.1'), findsOneWidget);
      });

      testWidgets('should keep all decimal places when needed with minimal formatting', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: eurCurrency,
          useMinimalFormatting: true,
        ));
        
        expect(find.text('€1,234.56'), findsOneWidget);
      });
    });

    group('Parentheses for Negative', () {
      testWidgets('should show negative amounts with parentheses when requested', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: -1234.56,
          currency: eurCurrency,
          useParenthesesForNegative: true,
        ));
        
        expect(find.text('€(1,234.56)'), findsOneWidget);
      });

      testWidgets('should not show parentheses for positive amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: eurCurrency,
          useParenthesesForNegative: true,
        ));
        
        expect(find.text('€1,234.56'), findsOneWidget);
      });
    });

    group('Compact Formatting', () {
      testWidgets('should display large amounts in compact format', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234567.89,
          currency: eurCurrency,
          isCompact: true,
        ));
        
        expect(find.text('€1.2M'), findsOneWidget);
      });

      testWidgets('should display medium amounts in compact format', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 12345.67,
          currency: eurCurrency,
          isCompact: true,
        ));
        
        expect(find.text('€12.3K'), findsOneWidget);
      });

      testWidgets('should not use compact format for small amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 123.45,
          currency: eurCurrency,
          isCompact: true,
        ));
        
        expect(find.text('€123.45'), findsOneWidget);
      });

      testWidgets('should respect compact threshold', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: eurCurrency,
          isCompact: true,
          compactThreshold: 5, // Higher threshold
        ));
        
        expect(find.text('€1,234.56'), findsOneWidget); // Should not be compact
      });
    });

    group('Custom Decimal Places', () {
      testWidgets('should override currency decimal places when specified', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.567,
          currency: eurCurrency,
          decimalPlaces: 3,
        ));
        
        expect(find.text('€1,234.567'), findsOneWidget);
      });

      testWidgets('should use currency default when decimal places not specified', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.567,
          currency: eurCurrency,
        ));
        
        expect(find.text('€1,234.57'), findsOneWidget); // Rounded to 2 decimal places
      });
    });

    group('Text Styling', () {
      testWidgets('should apply custom text style', (WidgetTester tester) async {
        const customStyle = TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        );
        
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: eurCurrency,
          style: customStyle,
        ));
        
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.style?.fontSize, equals(24));
        expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
        expect(textWidget.style?.color, equals(Colors.red));
      });

      testWidgets('should use error color for negative amounts by default', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: -1234.56,
          currency: eurCurrency,
        ));
        
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.style?.color, equals(Theme.of(tester.element(find.byType(Text))).colorScheme.error));
      });

      testWidgets('should use muted color for zero amounts by default', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 0.0,
          currency: eurCurrency,
        ));
        
        final textWidget = tester.widget<Text>(find.byType(Text));
        final expectedColor = Theme.of(tester.element(find.byType(Text))).colorScheme.onSurface.withValues(alpha: 0.6);
        expect(textWidget.style?.color, equals(expectedColor));
      });
    });

    group('Text Alignment', () {
      testWidgets('should apply custom text alignment', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 1234.56,
          currency: eurCurrency,
          textAlign: TextAlign.center,
        ));
        
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.textAlign, equals(TextAlign.center));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle very large amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 999999999.99,
          currency: eurCurrency,
        ));
        
        expect(find.text('€999,999,999.99'), findsOneWidget);
      });

      testWidgets('should handle very small amounts', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: 0.01,
          currency: eurCurrency,
        ));
        
        expect(find.text('€0.01'), findsOneWidget);
      });

      testWidgets('should handle infinity gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: double.infinity,
          currency: eurCurrency,
        ));
        
        // Should not crash and should display something
        expect(find.byType(Text), findsOneWidget);
      });

      testWidgets('should handle NaN gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(
          amount: double.nan,
          currency: eurCurrency,
        ));
        
        // Should not crash and should display something
        expect(find.byType(Text), findsOneWidget);
      });
    });
  });

  group('CurrencyDisplay Convenience Methods', () {
    late Currency testCurrency;
    
    setUp(() {
      testCurrency = Currency(
        code: 'EUR',
        name: 'Euro',
        symbol: '€',
        flag: '🇪🇺',
        number: 978,
        decimalDigits: 2,
        namePlural: 'Euros',
        symbolOnLeft: true,
        decimalSeparator: '.',
        thousandsSeparator: ',',
        spaceBetweenAmountAndSymbol: false,
      );
    });

    testWidgets('CurrencyDisplay.amount should work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.amount(
              amount: 1234.56,
              currency: testCurrency,
            ),
          ),
        ),
      );
      
      expect(find.text('€1,234.56'), findsOneWidget);
    });

    testWidgets('CurrencyDisplay.compact should work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.compact(
              amount: 1234567.89,
              currency: testCurrency,
            ),
          ),
        ),
      );
      
      expect(find.text('€1.2M'), findsOneWidget);
    });

    testWidgets('CurrencyDisplay.minimal should work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.minimal(
              amount: 1234.00,
              currency: testCurrency,
            ),
          ),
        ),
      );
      
      expect(find.text('€1,234'), findsOneWidget);
    });

    testWidgets('CurrencyDisplay.withCode should work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.withCode(
              amount: 1234.56,
              currency: testCurrency,
            ),
          ),
        ),
      );
      
      expect(find.text('€1,234.56 EUR'), findsOneWidget);
    });

    testWidgets('CurrencyDisplay.withParentheses should work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.withParentheses(
              amount: -1234.56,
              currency: testCurrency,
            ),
          ),
        ),
      );
      
      expect(find.text('€(1,234.56)'), findsOneWidget);
    });

    testWidgets('CurrencyDisplay.privacy should work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrencyDisplay.privacy(
              amount: 1234.56,
              currency: testCurrency,
            ),
          ),
        ),
      );
      
      expect(find.text('***'), findsOneWidget);
    });
  });
}
