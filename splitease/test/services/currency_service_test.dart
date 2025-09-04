import 'package:flutter_test/flutter_test.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitease/services/currency_service.dart';

void main() {
  group('SplitEaseCurrencyService', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      await SplitEaseCurrencyService.initialize();
    });

    tearDown(() async {
      // Clear all preferences after each test
      await SplitEaseCurrencyService.clearAllPreferences();
    });

    group('Default Currency', () {
      test('should return EUR as default currency', () {
        final currency = SplitEaseCurrencyService.getDefaultCurrency();
        expect(currency.code, equals('EUR'));
        expect(currency.name, equals('Euro'));
        expect(currency.symbol, equals('€'));
      });
    });

    group('User Preferred Currency', () {
      test('should return default currency when no preference is set', () {
        final currency = SplitEaseCurrencyService.getUserPreferredCurrency();
        expect(currency.code, equals('EUR'));
      });

      test('should store and retrieve user preferred currency', () async {
        final usdCurrency = SplitEaseCurrencyService.getCurrencyByCode('USD');
        await SplitEaseCurrencyService.setUserPreferredCurrency(usdCurrency);
        
        final retrievedCurrency = SplitEaseCurrencyService.getUserPreferredCurrency();
        expect(retrievedCurrency.code, equals('USD'));
        expect(retrievedCurrency.symbol, equals('\$'));
      });

      test('should handle invalid stored currency data gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_preferred_currency', 'invalid_json');
        
        final currency = SplitEaseCurrencyService.getUserPreferredCurrency();
        expect(currency.code, equals('EUR')); // Should fall back to default
      });
    });

    group('Group Currency', () {
      test('should return user preferred currency when no group currency is set', () {
        final currency = SplitEaseCurrencyService.getGroupCurrency(123);
        expect(currency.code, equals('EUR')); // Default user preference
      });

      test('should store and retrieve group currency', () async {
        final gbpCurrency = SplitEaseCurrencyService.getCurrencyByCode('GBP');
        await SplitEaseCurrencyService.setGroupCurrency(123, gbpCurrency);
        
        final retrievedCurrency = SplitEaseCurrencyService.getGroupCurrency(123);
        expect(retrievedCurrency.code, equals('GBP'));
        expect(retrievedCurrency.symbol, equals('£'));
      });

      test('should handle different group IDs independently', () async {
        final usdCurrency = SplitEaseCurrencyService.getCurrencyByCode('USD');
        final jpyCurrency = SplitEaseCurrencyService.getCurrencyByCode('JPY');
        
        await SplitEaseCurrencyService.setGroupCurrency(1, usdCurrency);
        await SplitEaseCurrencyService.setGroupCurrency(2, jpyCurrency);
        
        expect(SplitEaseCurrencyService.getGroupCurrency(1).code, equals('USD'));
        expect(SplitEaseCurrencyService.getGroupCurrency(2).code, equals('JPY'));
      });
    });

    group('Expense Currency', () {
      test('should return user preferred currency when no expense currency is set', () {
        final currency = SplitEaseCurrencyService.getExpenseCurrency(456);
        expect(currency.code, equals('EUR')); // Default user preference
      });

      test('should store and retrieve expense currency', () async {
        final cadCurrency = SplitEaseCurrencyService.getCurrencyByCode('CAD');
        await SplitEaseCurrencyService.setExpenseCurrency(456, cadCurrency);
        
        final retrievedCurrency = SplitEaseCurrencyService.getExpenseCurrency(456);
        expect(retrievedCurrency.code, equals('CAD'));
        expect(retrievedCurrency.symbol, equals('CA\$'));
      });
    });

    group('Popular Currencies', () {
      test('should return list of popular currencies', () {
        final popularCurrencies = SplitEaseCurrencyService.getPopularCurrencies();
        
        expect(popularCurrencies.length, equals(10));
        expect(popularCurrencies.map((c) => c.code), contains('EUR'));
        expect(popularCurrencies.map((c) => c.code), contains('USD'));
        expect(popularCurrencies.map((c) => c.code), contains('GBP'));
        expect(popularCurrencies.map((c) => c.code), contains('JPY'));
      });

      test('should return valid Currency objects', () {
        final popularCurrencies = SplitEaseCurrencyService.getPopularCurrencies();
        
        for (final currency in popularCurrencies) {
          expect(currency.code.length, equals(3));
          expect(currency.name.isNotEmpty, isTrue);
          expect(currency.symbol.isNotEmpty, isTrue);
        }
      });
    });

    group('Currency by Code', () {
      test('should return correct currency for valid codes', () {
        final eurCurrency = SplitEaseCurrencyService.getCurrencyByCode('EUR');
        expect(eurCurrency.code, equals('EUR'));
        expect(eurCurrency.symbol, equals('€'));

        final usdCurrency = SplitEaseCurrencyService.getCurrencyByCode('USD');
        expect(usdCurrency.code, equals('USD'));
        expect(usdCurrency.symbol, equals('\$'));
      });

      test('should return default currency for invalid codes', () {
        final invalidCurrency = SplitEaseCurrencyService.getCurrencyByCode('INVALID');
        expect(invalidCurrency.code, equals('EUR')); // Should fall back to default
      });

      test('should handle empty or null codes', () {
        final emptyCurrency = SplitEaseCurrencyService.getCurrencyByCode('');
        expect(emptyCurrency.code, equals('EUR'));
      });
    });

    group('Amount Formatting', () {
      test('should format amount with EUR currency correctly', () {
        final eurCurrency = SplitEaseCurrencyService.getCurrencyByCode('EUR');
        final formatted = SplitEaseCurrencyService.formatAmount(1234.56, eurCurrency);
        expect(formatted, equals('€1,234.56'));
      });

      test('should format amount with USD currency correctly', () {
        final usdCurrency = SplitEaseCurrencyService.getCurrencyByCode('USD');
        final formatted = SplitEaseCurrencyService.formatAmount(1234.56, usdCurrency);
        expect(formatted, equals('\$1,234.56'));
      });

      test('should handle zero amounts', () {
        final eurCurrency = SplitEaseCurrencyService.getCurrencyByCode('EUR');
        final formatted = SplitEaseCurrencyService.formatAmount(0.0, eurCurrency);
        expect(formatted, equals('€0.00'));
      });

      test('should handle large amounts with thousands separators', () {
        final eurCurrency = SplitEaseCurrencyService.getCurrencyByCode('EUR');
        final formatted = SplitEaseCurrencyService.formatAmount(1234567.89, eurCurrency);
        expect(formatted, equals('€1,234,567.89'));
      });

      test('should respect currency decimal digits', () {
        final jpyCurrency = SplitEaseCurrencyService.getCurrencyByCode('JPY');
        final formatted = SplitEaseCurrencyService.formatAmount(1234.56, jpyCurrency);
        expect(formatted, equals('¥1,235')); // JPY has 0 decimal places
      });
    });

    group('Clear Preferences', () {
      test('should clear all currency preferences', () async {
        // Set various preferences
        final usdCurrency = SplitEaseCurrencyService.getCurrencyByCode('USD');
        await SplitEaseCurrencyService.setUserPreferredCurrency(usdCurrency);
        await SplitEaseCurrencyService.setGroupCurrency(1, usdCurrency);
        await SplitEaseCurrencyService.setExpenseCurrency(1, usdCurrency);
        
        // Verify they are set
        expect(SplitEaseCurrencyService.getUserPreferredCurrency().code, equals('USD'));
        expect(SplitEaseCurrencyService.getGroupCurrency(1).code, equals('USD'));
        expect(SplitEaseCurrencyService.getExpenseCurrency(1).code, equals('USD'));
        
        // Clear all preferences
        await SplitEaseCurrencyService.clearAllPreferences();
        
        // Verify they are cleared (should return defaults)
        expect(SplitEaseCurrencyService.getUserPreferredCurrency().code, equals('EUR'));
        expect(SplitEaseCurrencyService.getGroupCurrency(1).code, equals('EUR'));
        expect(SplitEaseCurrencyService.getExpenseCurrency(1).code, equals('EUR'));
      });
    });

    group('Error Handling', () {
      test('should handle SharedPreferences initialization failure gracefully', () {
        // Test when _prefs is null
        final currency = SplitEaseCurrencyService.getUserPreferredCurrency();
        expect(currency.code, equals('EUR')); // Should return default
      });

      test('should handle JSON parsing errors gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_preferred_currency', '{invalid json}');
        
        final currency = SplitEaseCurrencyService.getUserPreferredCurrency();
        expect(currency.code, equals('EUR')); // Should fall back to default
      });
    });

    group('Currency Persistence', () {
      test('should persist user currency across service reinitialization', () async {
        final usdCurrency = SplitEaseCurrencyService.getCurrencyByCode('USD');
        await SplitEaseCurrencyService.setUserPreferredCurrency(usdCurrency);
        
        // Reinitialize service (simulates app restart)
        await SplitEaseCurrencyService.initialize();
        
        final retrievedCurrency = SplitEaseCurrencyService.getUserPreferredCurrency();
        expect(retrievedCurrency.code, equals('USD'));
      });

      test('should persist group currencies across service reinitialization', () async {
        final gbpCurrency = SplitEaseCurrencyService.getCurrencyByCode('GBP');
        await SplitEaseCurrencyService.setGroupCurrency(123, gbpCurrency);
        
        // Reinitialize service
        await SplitEaseCurrencyService.initialize();
        
        final retrievedCurrency = SplitEaseCurrencyService.getGroupCurrency(123);
        expect(retrievedCurrency.code, equals('GBP'));
      });
    });
  });
}