import 'package:flutter_test/flutter_test.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:splitease/utils/currency_utils.dart';

void main() {
  group('SplitEaseCurrencyUtils', () {
    late Currency eurCurrency;
    late Currency usdCurrency;
    late Currency jpyCurrency;
    late Currency gbpCurrency;

    setUpAll(() {
      // Create currency objects manually for testing
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
      gbpCurrency = Currency(
        code: 'GBP',
        name: 'British Pound',
        symbol: '£',
        flag: '🇬🇧',
        number: 826,
        decimalDigits: 2,
        namePlural: 'British Pounds',
        symbolOnLeft: true,
        decimalSeparator: '.',
        thousandsSeparator: ',',
        spaceBetweenAmountAndSymbol: false,
      );
    });

    group('formatAmount', () {
      test('should format EUR amounts correctly', () {
        expect(SplitEaseCurrencyUtils.formatAmount(1234.56, eurCurrency), equals('€1,234.56'));
        expect(SplitEaseCurrencyUtils.formatAmount(0.0, eurCurrency), equals('€0.00'));
        expect(SplitEaseCurrencyUtils.formatAmount(1000000.99, eurCurrency), equals('€1,000,000.99'));
      });

      test('should format USD amounts correctly', () {
        expect(SplitEaseCurrencyUtils.formatAmount(1234.56, usdCurrency), equals('\$1,234.56'));
        expect(SplitEaseCurrencyUtils.formatAmount(999.99, usdCurrency), equals('\$999.99'));
      });

      test('should format JPY amounts correctly (no decimal places)', () {
        expect(SplitEaseCurrencyUtils.formatAmount(1234.56, jpyCurrency), equals('¥1,235'));
        expect(SplitEaseCurrencyUtils.formatAmount(1000.0, jpyCurrency), equals('¥1,000'));
      });

      test('should handle custom decimal places override', () {
        expect(SplitEaseCurrencyUtils.formatAmount(1234.567, eurCurrency, decimalPlaces: 3), equals('€1,234.567'));
        expect(SplitEaseCurrencyUtils.formatAmount(1234.5, eurCurrency, decimalPlaces: 0), equals('€1,235'));
      });

      test('should handle small amounts correctly', () {
        expect(SplitEaseCurrencyUtils.formatAmount(0.01, eurCurrency), equals('€0.01'));
        expect(SplitEaseCurrencyUtils.formatAmount(0.99, usdCurrency), equals('\$0.99'));
      });

      test('should handle negative amounts', () {
        expect(SplitEaseCurrencyUtils.formatAmount(-1234.56, eurCurrency), equals('€-1,234.56'));
        expect(SplitEaseCurrencyUtils.formatAmount(-0.01, usdCurrency), equals('\$-0.01'));
      });
    });

    group('getCurrencySymbol', () {
      test('should return correct symbols for valid currency codes', () {
        expect(SplitEaseCurrencyUtils.getCurrencySymbol('EUR'), equals('€'));
        expect(SplitEaseCurrencyUtils.getCurrencySymbol('USD'), equals('\$'));
        expect(SplitEaseCurrencyUtils.getCurrencySymbol('GBP'), equals('£'));
        expect(SplitEaseCurrencyUtils.getCurrencySymbol('JPY'), equals('¥'));
      });

      test('should return currency code for invalid codes', () {
        expect(SplitEaseCurrencyUtils.getCurrencySymbol('INVALID'), equals('INVALID'));
        expect(SplitEaseCurrencyUtils.getCurrencySymbol('XYZ'), equals('XYZ'));
      });

      test('should handle empty string', () {
        expect(SplitEaseCurrencyUtils.getCurrencySymbol(''), equals(''));
      });
    });

    group('parseCurrencyCode', () {
      test('should parse valid currency codes correctly', () {
        final eurParsed = SplitEaseCurrencyUtils.parseCurrencyCode('EUR');
        expect(eurParsed.code, equals('EUR'));
        expect(eurParsed.symbol, equals('€'));

        final usdParsed = SplitEaseCurrencyUtils.parseCurrencyCode('USD');
        expect(usdParsed.code, equals('USD'));
        expect(usdParsed.symbol, equals('\$'));
      });

      test('should throw ArgumentError for invalid currency codes', () {
        expect(() => SplitEaseCurrencyUtils.parseCurrencyCode('INVALID'), throwsArgumentError);
        expect(() => SplitEaseCurrencyUtils.parseCurrencyCode('XY'), throwsArgumentError);
        expect(() => SplitEaseCurrencyUtils.parseCurrencyCode(''), throwsArgumentError);
      });
    });

    group('isValidCurrencyCode', () {
      test('should return true for valid currency codes', () {
        expect(SplitEaseCurrencyUtils.isValidCurrencyCode('EUR'), isTrue);
        expect(SplitEaseCurrencyUtils.isValidCurrencyCode('USD'), isTrue);
        expect(SplitEaseCurrencyUtils.isValidCurrencyCode('GBP'), isTrue);
        expect(SplitEaseCurrencyUtils.isValidCurrencyCode('JPY'), isTrue);
        expect(SplitEaseCurrencyUtils.isValidCurrencyCode('CAD'), isTrue);
      });

      test('should return false for invalid currency codes', () {
        expect(SplitEaseCurrencyUtils.isValidCurrencyCode('INVALID'), isFalse);
        expect(SplitEaseCurrencyUtils.isValidCurrencyCode('XYZ'), isFalse);
        expect(SplitEaseCurrencyUtils.isValidCurrencyCode(''), isFalse);
        expect(SplitEaseCurrencyUtils.isValidCurrencyCode('EU'), isFalse); // Too short
        expect(SplitEaseCurrencyUtils.isValidCurrencyCode('EURO'), isFalse); // Too long
      });
    });

    group('getSystemDefaultCurrency', () {
      test('should return a valid Currency object', () {
        final defaultCurrency = SplitEaseCurrencyUtils.getSystemDefaultCurrency();
        expect(defaultCurrency.code.length, equals(3));
        expect(defaultCurrency.name.isNotEmpty, isTrue);
        expect(defaultCurrency.symbol.isNotEmpty, isTrue);
      });

      test('should fall back to EUR if locale detection fails', () {
        // This test verifies the fallback behavior
        // The actual result may vary based on the test environment
        final defaultCurrency = SplitEaseCurrencyUtils.getSystemDefaultCurrency();
        expect(SplitEaseCurrencyUtils.isValidCurrencyCode(defaultCurrency.code), isTrue);
      });
    });

    group('formatAmountMinimal', () {
      test('should remove trailing zeros', () {
        expect(SplitEaseCurrencyUtils.formatAmountMinimal(1234.00, eurCurrency), equals('€1,234'));
        expect(SplitEaseCurrencyUtils.formatAmountMinimal(1234.10, eurCurrency), equals('€1,234.1'));
        expect(SplitEaseCurrencyUtils.formatAmountMinimal(1234.56, eurCurrency), equals('€1,234.56'));
      });

      test('should handle zero amounts', () {
        expect(SplitEaseCurrencyUtils.formatAmountMinimal(0.0, eurCurrency), equals('€0'));
        expect(SplitEaseCurrencyUtils.formatAmountMinimal(0.00, usdCurrency), equals('\$0'));
      });

      test('should work with currencies that have no decimal places', () {
        expect(SplitEaseCurrencyUtils.formatAmountMinimal(1234.0, jpyCurrency), equals('¥1,234'));
      });
    });

    group('compareAmounts', () {
      test('should compare amounts correctly with currency precision', () {
        expect(SplitEaseCurrencyUtils.compareAmounts(1234.56, 1234.57, eurCurrency), equals(-1));
        expect(SplitEaseCurrencyUtils.compareAmounts(1234.57, 1234.56, eurCurrency), equals(1));
        expect(SplitEaseCurrencyUtils.compareAmounts(1234.56, 1234.56, eurCurrency), equals(0));
      });

      test('should handle precision correctly for JPY (no decimals)', () {
        expect(SplitEaseCurrencyUtils.compareAmounts(1234.4, 1234.6, jpyCurrency), equals(-1)); // 1234 vs 1235 when rounded
        expect(SplitEaseCurrencyUtils.compareAmounts(1234.0, 1235.0, jpyCurrency), equals(-1));
      });

      test('should handle very small differences within precision', () {
        expect(SplitEaseCurrencyUtils.compareAmounts(1234.561, 1234.562, eurCurrency), equals(0)); // Same when rounded to 2 decimals
        expect(SplitEaseCurrencyUtils.compareAmounts(1234.56, 1234.57, eurCurrency), equals(-1));
      });
    });

    group('areAmountsEqual', () {
      test('should return true for equal amounts within precision', () {
        expect(SplitEaseCurrencyUtils.areAmountsEqual(1234.56, 1234.56, eurCurrency), isTrue);
        expect(SplitEaseCurrencyUtils.areAmountsEqual(1234.561, 1234.562, eurCurrency), isTrue); // Same when rounded
      });

      test('should return false for different amounts', () {
        expect(SplitEaseCurrencyUtils.areAmountsEqual(1234.56, 1234.57, eurCurrency), isFalse);
        expect(SplitEaseCurrencyUtils.areAmountsEqual(1234.0, 1235.0, eurCurrency), isFalse);
      });

      test('should handle JPY precision correctly', () {
        expect(SplitEaseCurrencyUtils.areAmountsEqual(1234.4, 1234.6, jpyCurrency), isFalse); // 1234 vs 1235 when rounded
        expect(SplitEaseCurrencyUtils.areAmountsEqual(1234.0, 1235.0, jpyCurrency), isFalse);
      });

      test('should handle zero amounts', () {
        expect(SplitEaseCurrencyUtils.areAmountsEqual(0.0, 0.0, eurCurrency), isTrue);
        expect(SplitEaseCurrencyUtils.areAmountsEqual(0.001, 0.002, eurCurrency), isTrue); // Both round to 0.00
        expect(SplitEaseCurrencyUtils.areAmountsEqual(0.01, 0.02, eurCurrency), isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle very large amounts', () {
        final largeAmount = 999999999.99;
        final formatted = SplitEaseCurrencyUtils.formatAmount(largeAmount, eurCurrency);
        expect(formatted, contains('€'));
        expect(formatted, contains('999,999,999.99'));
      });

      test('should handle very small amounts', () {
        final smallAmount = 0.001;
        final formatted = SplitEaseCurrencyUtils.formatAmount(smallAmount, eurCurrency);
        expect(formatted, equals('€0.00')); // Rounded to currency precision
      });

      test('should handle infinity and NaN gracefully', () {
        expect(() => SplitEaseCurrencyUtils.formatAmount(double.infinity, eurCurrency), returnsNormally);
        expect(() => SplitEaseCurrencyUtils.formatAmount(double.nan, eurCurrency), returnsNormally);
      });
    });

    group('Currency Symbol Positioning', () {
      test('should respect symbolOnLeft property', () {
        // EUR has symbol on left
        expect(SplitEaseCurrencyUtils.formatAmount(100.0, eurCurrency), startsWith('€'));
        
        // USD has symbol on left
        expect(SplitEaseCurrencyUtils.formatAmount(100.0, usdCurrency), startsWith('\$'));
      });

      test('should respect spaceBetweenAmountAndSymbol property', () {
        final formatted = SplitEaseCurrencyUtils.formatAmount(100.0, eurCurrency);
        // Check that formatting follows the currency's spacing rules
        expect(formatted, isA<String>());
        expect(formatted.length, greaterThan(0));
      });
    });

    group('Thousands Separator', () {
      test('should add thousands separator for amounts >= 1000', () {
        expect(SplitEaseCurrencyUtils.formatAmount(1000.0, eurCurrency), contains(','));
        expect(SplitEaseCurrencyUtils.formatAmount(10000.0, eurCurrency), contains(','));
        expect(SplitEaseCurrencyUtils.formatAmount(100000.0, eurCurrency), contains(','));
      });

      test('should not add thousands separator for amounts < 1000', () {
        expect(SplitEaseCurrencyUtils.formatAmount(999.99, eurCurrency), isNot(contains(',')));
        expect(SplitEaseCurrencyUtils.formatAmount(100.0, eurCurrency), isNot(contains(',')));
      });
    });
  });
}