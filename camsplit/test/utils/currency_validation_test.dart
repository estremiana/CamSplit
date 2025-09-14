import 'package:flutter_test/flutter_test.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:camsplit/utils/currency_validation.dart';
import 'package:camsplit/services/currency_service.dart';

void main() {
  group('CurrencyValidation Tests', () {
    late Currency validCurrency;
    late Currency invalidCurrency;

    setUp(() {
      validCurrency = Currency(
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

      invalidCurrency = Currency(
        code: 'INVALID',
        name: '',
        symbol: '',
        flag: '🏳️',
        number: 0,
        decimalDigits: -1,
        namePlural: '',
        symbolOnLeft: true,
        decimalSeparator: '',
        thousandsSeparator: '',
        spaceBetweenAmountAndSymbol: false,
      );
    });

    group('validateExpenseCurrency', () {
      test('should return valid result for valid currency', () {
        final result = CurrencyValidation.validateExpenseCurrency(validCurrency);
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return invalid result for null currency', () {
        final result = CurrencyValidation.validateExpenseCurrency(null);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency selection is required'));
      });

      test('should return invalid result for invalid currency', () {
        final result = CurrencyValidation.validateExpenseCurrency(invalidCurrency);
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
      });
    });

    group('validateGroupCurrency', () {
      test('should return valid result for valid currency', () {
        final result = CurrencyValidation.validateGroupCurrency(validCurrency);
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return invalid result for null currency', () {
        final result = CurrencyValidation.validateGroupCurrency(null);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Group currency is required'));
      });
    });

    group('validateSettlementCurrency', () {
      test('should return valid result for valid currency', () {
        final result = CurrencyValidation.validateSettlementCurrency(validCurrency);
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return invalid result for null currency', () {
        final result = CurrencyValidation.validateSettlementCurrency(null);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Settlement currency is required'));
      });
    });

    group('validateCurrency', () {
      test('should return valid result for valid currency', () {
        final result = CurrencyValidation.validateCurrency(validCurrency);
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return invalid result for empty currency code', () {
        final currencyWithEmptyCode = Currency(
          code: '',
          name: 'Test',
          symbol: '\$',
          flag: '🏳️',
          number: 840,
          decimalDigits: 2,
          namePlural: 'Test',
          symbolOnLeft: true,
          decimalSeparator: '.',
          thousandsSeparator: ',',
          spaceBetweenAmountAndSymbol: false,
        );

        final result = CurrencyValidation.validateCurrency(currencyWithEmptyCode);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency code cannot be empty'));
      });

      test('should return invalid result for invalid currency code length', () {
        final currencyWithInvalidCode = Currency(
          code: 'US',
          name: 'Test',
          symbol: '\$',
          flag: '🏳️',
          number: 840,
          decimalDigits: 2,
          namePlural: 'Test',
          symbolOnLeft: true,
          decimalSeparator: '.',
          thousandsSeparator: ',',
          spaceBetweenAmountAndSymbol: false,
        );

        final result = CurrencyValidation.validateCurrency(currencyWithInvalidCode);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency code must be exactly 3 characters long'));
      });

      test('should return invalid result for non-letter currency code', () {
        final currencyWithInvalidCode = Currency(
          code: 'US1',
          name: 'Test',
          symbol: '\$',
          flag: '🏳️',
          number: 840,
          decimalDigits: 2,
          namePlural: 'Test',
          symbolOnLeft: true,
          decimalSeparator: '.',
          thousandsSeparator: ',',
          spaceBetweenAmountAndSymbol: false,
        );

        final result = CurrencyValidation.validateCurrency(currencyWithInvalidCode);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency code must contain only uppercase letters'));
      });

      test('should return invalid result for unsupported currency code', () {
        final currencyWithUnsupportedCode = Currency(
          code: 'XYZ',
          name: 'Test',
          symbol: '\$',
          flag: '🏳️',
          number: 840,
          decimalDigits: 2,
          namePlural: 'Test',
          symbolOnLeft: true,
          decimalSeparator: '.',
          thousandsSeparator: ',',
          spaceBetweenAmountAndSymbol: false,
        );

        final result = CurrencyValidation.validateCurrency(currencyWithUnsupportedCode);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency code "XYZ" is not supported'));
      });

      test('should return invalid result for empty currency name', () {
        final currencyWithEmptyName = Currency(
          code: 'USD',
          name: '',
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

        final result = CurrencyValidation.validateCurrency(currencyWithEmptyName);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency name cannot be empty'));
      });

      test('should return invalid result for empty currency symbol', () {
        final currencyWithEmptySymbol = Currency(
          code: 'USD',
          name: 'US Dollar',
          symbol: '',
          flag: '🇺🇸',
          number: 840,
          decimalDigits: 2,
          namePlural: 'US Dollars',
          symbolOnLeft: true,
          decimalSeparator: '.',
          thousandsSeparator: ',',
          spaceBetweenAmountAndSymbol: false,
        );

        final result = CurrencyValidation.validateCurrency(currencyWithEmptySymbol);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency symbol cannot be empty'));
      });

      test('should return invalid result for invalid decimal digits', () {
        final currencyWithInvalidDecimals = Currency(
          code: 'USD',
          name: 'US Dollar',
          symbol: '\$',
          flag: '🇺🇸',
          number: 840,
          decimalDigits: 5, // Invalid: should be 0-4
          namePlural: 'US Dollars',
          symbolOnLeft: true,
          decimalSeparator: '.',
          thousandsSeparator: ',',
          spaceBetweenAmountAndSymbol: false,
        );

        final result = CurrencyValidation.validateCurrency(currencyWithInvalidDecimals);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency decimal digits must be between 0 and 4'));
      });

      test('should return invalid result for empty decimal separator', () {
        final currencyWithEmptyDecimalSeparator = Currency(
          code: 'USD',
          name: 'US Dollar',
          symbol: '\$',
          flag: '🇺🇸',
          number: 840,
          decimalDigits: 2,
          namePlural: 'US Dollars',
          symbolOnLeft: true,
          decimalSeparator: '',
          thousandsSeparator: ',',
          spaceBetweenAmountAndSymbol: false,
        );

        final result = CurrencyValidation.validateCurrency(currencyWithEmptyDecimalSeparator);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Decimal separator cannot be empty'));
      });

      test('should return invalid result for empty thousands separator', () {
        final currencyWithEmptyThousandsSeparator = Currency(
          code: 'USD',
          name: 'US Dollar',
          symbol: '\$',
          flag: '🇺🇸',
          number: 840,
          decimalDigits: 2,
          namePlural: 'US Dollars',
          symbolOnLeft: true,
          decimalSeparator: '.',
          thousandsSeparator: '',
          spaceBetweenAmountAndSymbol: false,
        );

        final result = CurrencyValidation.validateCurrency(currencyWithEmptyThousandsSeparator);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Thousands separator cannot be empty'));
      });

      test('should return invalid result for same decimal and thousands separators', () {
        final currencyWithSameSeparators = Currency(
          code: 'USD',
          name: 'US Dollar',
          symbol: '\$',
          flag: '🇺🇸',
          number: 840,
          decimalDigits: 2,
          namePlural: 'US Dollars',
          symbolOnLeft: true,
          decimalSeparator: '.',
          thousandsSeparator: '.', // Same as decimal separator
          spaceBetweenAmountAndSymbol: false,
        );

        final result = CurrencyValidation.validateCurrency(currencyWithSameSeparators);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Decimal and thousands separators must be different'));
      });
    });

    group('validateCurrencyCode', () {
      test('should return valid result for valid currency code', () {
        final result = CurrencyValidation.validateCurrencyCode('USD');
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return invalid result for null currency code', () {
        final result = CurrencyValidation.validateCurrencyCode(null);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency code is required'));
      });

      test('should return invalid result for empty currency code', () {
        final result = CurrencyValidation.validateCurrencyCode('');
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency code is required'));
      });

      test('should return invalid result for invalid length', () {
        final result = CurrencyValidation.validateCurrencyCode('US');
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency code must be exactly 3 characters long'));
      });

      test('should return invalid result for non-letter characters', () {
        final result = CurrencyValidation.validateCurrencyCode('US1');
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency code must contain only letters'));
      });

      test('should return invalid result for unsupported currency code', () {
        final result = CurrencyValidation.validateCurrencyCode('XYZ');
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Currency code "XYZ" is not supported'));
      });

      test('should normalize currency code to uppercase', () {
        final result = CurrencyValidation.validateCurrencyCode('usd');
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });
    });

    group('validateCurrencyAmount', () {
      test('should return valid result for valid amount', () {
        final result = CurrencyValidation.validateCurrencyAmount(100.50, validCurrency);
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return invalid result for null amount', () {
        final result = CurrencyValidation.validateCurrencyAmount(null, validCurrency);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Amount is required'));
      });

      test('should return invalid result for zero amount', () {
        final result = CurrencyValidation.validateCurrencyAmount(0.0, validCurrency);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Amount must be greater than zero'));
      });

      test('should return invalid result for negative amount', () {
        final result = CurrencyValidation.validateCurrencyAmount(-50.0, validCurrency);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Amount must be greater than zero'));
      });

      test('should return invalid result for NaN amount', () {
        final result = CurrencyValidation.validateCurrencyAmount(double.nan, validCurrency);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Amount must be a valid number'));
      });

      test('should return invalid result for infinite amount', () {
        final result = CurrencyValidation.validateCurrencyAmount(double.infinity, validCurrency);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Amount must be a valid number'));
      });

      test('should return invalid result for too many decimal places', () {
        final result = CurrencyValidation.validateCurrencyAmount(100.123, validCurrency);
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Amount has too many decimal places for USD (max: 2)'));
      });

      test('should handle JPY currency with no decimal places', () {
        final jpyCurrency = Currency(
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

        // Valid amount for JPY
        final validResult = CurrencyValidation.validateCurrencyAmount(1000, jpyCurrency);
        expect(validResult.isValid, isTrue);

        // Invalid amount for JPY (has decimal places)
        final invalidResult = CurrencyValidation.validateCurrencyAmount(1000.50, jpyCurrency);
        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errors, contains('Amount has too many decimal places for JPY (max: 0)'));
      });
    });

    group('validateCurrencyConsistency', () {
      test('should return valid result when all currencies match', () {
        final result = CurrencyValidation.validateCurrencyConsistency(
          groupCurrency: validCurrency,
          expenseCurrency: validCurrency,
          settlementCurrency: validCurrency,
        );
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return valid result when currencies are null', () {
        final result = CurrencyValidation.validateCurrencyConsistency();
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should return invalid result when group and expense currencies differ', () {
        final differentCurrency = Currency(
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

        final result = CurrencyValidation.validateCurrencyConsistency(
          groupCurrency: validCurrency,
          expenseCurrency: differentCurrency,
        );
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Expense currency (EUR) must match group currency (USD)'));
      });

      test('should return invalid result when group and settlement currencies differ', () {
        final differentCurrency = Currency(
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

        final result = CurrencyValidation.validateCurrencyConsistency(
          groupCurrency: validCurrency,
          settlementCurrency: differentCurrency,
        );
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Settlement currency (EUR) must match group currency (USD)'));
      });

      test('should return invalid result when expense and settlement currencies differ', () {
        final differentCurrency = Currency(
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

        final result = CurrencyValidation.validateCurrencyConsistency(
          expenseCurrency: validCurrency,
          settlementCurrency: differentCurrency,
        );
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Settlement currency (EUR) must match expense currency (USD)'));
      });
    });

    group('getFallbackCurrency', () {
      test('should return default currency for null input', () {
        final fallback = CurrencyValidation.getFallbackCurrency(null);
        expect(fallback.code, equals('EUR'));
      });

      test('should return default currency for empty input', () {
        final fallback = CurrencyValidation.getFallbackCurrency('');
        expect(fallback.code, equals('EUR'));
      });

      test('should suggest USD for USA input', () {
        final fallback = CurrencyValidation.getFallbackCurrency('USA');
        expect(fallback.code, equals('USD'));
      });

      test('should suggest EUR for EURO input', () {
        final fallback = CurrencyValidation.getFallbackCurrency('EURO');
        expect(fallback.code, equals('EUR'));
      });

      test('should suggest GBP for POUND input', () {
        final fallback = CurrencyValidation.getFallbackCurrency('POUND');
        expect(fallback.code, equals('GBP'));
      });

      test('should return default currency for unknown input', () {
        final fallback = CurrencyValidation.getFallbackCurrency('UNKNOWN');
        expect(fallback.code, equals('EUR'));
      });
    });
  });

  group('ValidationResult Tests', () {
    test('should create valid result correctly', () {
      final result = ValidationResult(isValid: true, errors: []);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.hasErrors, isFalse);
      expect(result.firstError, isNull);
      expect(result.allErrors, equals(''));
    });

    test('should create invalid result correctly', () {
      final errors = ['Error 1', 'Error 2'];
      final result = ValidationResult(isValid: false, errors: errors);
      expect(result.isValid, isFalse);
      expect(result.errors, equals(errors));
      expect(result.hasErrors, isTrue);
      expect(result.firstError, equals('Error 1'));
      expect(result.allErrors, equals('Error 1, Error 2'));
    });

    test('should handle single error correctly', () {
      final result = ValidationResult(isValid: false, errors: ['Single error']);
      expect(result.firstError, equals('Single error'));
      expect(result.allErrors, equals('Single error'));
    });
  });
}
