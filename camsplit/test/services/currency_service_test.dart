import 'package:flutter_test/flutter_test.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camsplit/services/currency_service.dart';

void main() {
  group('CamSplitCurrencyService', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      await CamSplitCurrencyService.initialize();
    });

    tearDown(() async {
      // Clear all preferences after each test
      await CamSplitCurrencyService.clearAllPreferences();
    });

    group('Default Currency', () {
      test('should return EUR as default currency', () {
        final currency = CamSplitCurrencyService.getDefaultCurrency();
        expect(currency.code, equals('EUR'));
        expect(currency.name, equals('Euro'));
        expect(currency.symbol, equals('€'));
      });
    });

    group('User Preferred Currency', () {
      test('should return default currency when no preference is set', () {
        final currency = CamSplitCurrencyService.getUserPreferredCurrency();
        expect(currency.code, equals('EUR'));
      });

      test('should store and retrieve user preferred currency', () async {
        final usdCurrency = CamSplitCurrencyService.getCurrencyByCode('USD');
        await CamSplitCurrencyService.setUserPreferredCurrency(usdCurrency);
        
        final retrievedCurrency = CamSplitCurrencyService.getUserPreferredCurrency();
        expect(retrievedCurrency.code, equals('USD'));
        expect(retrievedCurrency.symbol, equals('\$'));
      });

      test('should handle invalid stored currency data gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_preferred_currency', 'invalid_json');
        
        final currency = CamSplitCurrencyService.getUserPreferredCurrency();
        expect(currency.code, equals('EUR')); // Should fall back to default
      });
    });

    group('Group Currency', () {
      test('should return user preferred currency when no group currency is set', () {
        final currency = CamSplitCurrencyService.getGroupCurrency(123);
        expect(currency.code, equals('EUR')); // Default user preference
      });

      test('should store and retrieve group currency', () async {
        final gbpCurrency = CamSplitCurrencyService.getCurrencyByCode('GBP');
        await CamSplitCurrencyService.setGroupCurrency(123, gbpCurrency);
        
        final retrievedCurrency = CamSplitCurrencyService.getGroupCurrency(123);
        expect(retrievedCurrency.code, equals('GBP'));
        expect(retrievedCurrency.symbol, equals('£'));
      });

      test('should handle different group IDs independently', () async {
        final usdCurrency = CamSplitCurrencyService.getCurrencyByCode('USD');
        final jpyCurrency = CamSplitCurrencyService.getCurrencyByCode('JPY');
        
        await CamSplitCurrencyService.setGroupCurrency(1, usdCurrency);
        await CamSplitCurrencyService.setGroupCurrency(2, jpyCurrency);
        
        expect(CamSplitCurrencyService.getGroupCurrency(1).code, equals('USD'));
        expect(CamSplitCurrencyService.getGroupCurrency(2).code, equals('JPY'));
      });
    });

    group('Expense Currency', () {
      test('should return user preferred currency when no expense currency is set', () {
        final currency = CamSplitCurrencyService.getExpenseCurrency(456);
        expect(currency.code, equals('EUR')); // Default user preference
      });

      test('should store and retrieve expense currency', () async {
        final cadCurrency = CamSplitCurrencyService.getCurrencyByCode('CAD');
        await CamSplitCurrencyService.setExpenseCurrency(456, cadCurrency);
        
        final retrievedCurrency = CamSplitCurrencyService.getExpenseCurrency(456);
        expect(retrievedCurrency.code, equals('CAD'));
        expect(retrievedCurrency.symbol, equals('CA\$'));
      });
    });

    group('Popular Currencies', () {
      test('should return list of popular currencies', () {
        final popularCurrencies = CamSplitCurrencyService.getPopularCurrencies();
        
        expect(popularCurrencies.length, equals(10));
        expect(popularCurrencies.map((c) => c.code), contains('EUR'));
        expect(popularCurrencies.map((c) => c.code), contains('USD'));
        expect(popularCurrencies.map((c) => c.code), contains('GBP'));
        expect(popularCurrencies.map((c) => c.code), contains('JPY'));
      });

      test('should return valid Currency objects', () {
        final popularCurrencies = CamSplitCurrencyService.getPopularCurrencies();
        
        for (final currency in popularCurrencies) {
          expect(currency.code.length, equals(3));
          expect(currency.name.isNotEmpty, isTrue);
          expect(currency.symbol.isNotEmpty, isTrue);
        }
      });
    });

    group('Currency by Code', () {
      test('should return correct currency for valid codes', () {
        final eurCurrency = CamSplitCurrencyService.getCurrencyByCode('EUR');
        expect(eurCurrency.code, equals('EUR'));
        expect(eurCurrency.symbol, equals('€'));

        final usdCurrency = CamSplitCurrencyService.getCurrencyByCode('USD');
        expect(usdCurrency.code, equals('USD'));
        expect(usdCurrency.symbol, equals('\$'));
      });

      test('should return default currency for invalid codes', () {
        final invalidCurrency = CamSplitCurrencyService.getCurrencyByCode('INVALID');
        expect(invalidCurrency.code, equals('EUR')); // Should fall back to default
      });

      test('should handle empty or null codes', () {
        final emptyCurrency = CamSplitCurrencyService.getCurrencyByCode('');
        expect(emptyCurrency.code, equals('EUR'));
      });
    });

    group('Amount Formatting', () {
      test('should format amount with EUR currency correctly', () {
        final eurCurrency = CamSplitCurrencyService.getCurrencyByCode('EUR');
        final formatted = CamSplitCurrencyService.formatAmount(1234.56, eurCurrency);
        expect(formatted, equals('€1,234.56'));
      });

      test('should format amount with USD currency correctly', () {
        final usdCurrency = CamSplitCurrencyService.getCurrencyByCode('USD');
        final formatted = CamSplitCurrencyService.formatAmount(1234.56, usdCurrency);
        expect(formatted, equals('\$1,234.56'));
      });

      test('should handle zero amounts', () {
        final eurCurrency = CamSplitCurrencyService.getCurrencyByCode('EUR');
        final formatted = CamSplitCurrencyService.formatAmount(0.0, eurCurrency);
        expect(formatted, equals('€0.00'));
      });

      test('should handle large amounts with thousands separators', () {
        final eurCurrency = CamSplitCurrencyService.getCurrencyByCode('EUR');
        final formatted = CamSplitCurrencyService.formatAmount(1234567.89, eurCurrency);
        expect(formatted, equals('€1,234,567.89'));
      });

      test('should respect currency decimal digits', () {
        final jpyCurrency = CamSplitCurrencyService.getCurrencyByCode('JPY');
        final formatted = CamSplitCurrencyService.formatAmount(1234.56, jpyCurrency);
        expect(formatted, equals('¥1,235')); // JPY has 0 decimal places
      });
    });

    group('Clear Preferences', () {
      test('should clear all currency preferences', () async {
        // Set various preferences
        final usdCurrency = CamSplitCurrencyService.getCurrencyByCode('USD');
        await CamSplitCurrencyService.setUserPreferredCurrency(usdCurrency);
        await CamSplitCurrencyService.setGroupCurrency(1, usdCurrency);
        await CamSplitCurrencyService.setExpenseCurrency(1, usdCurrency);
        
        // Verify they are set
        expect(CamSplitCurrencyService.getUserPreferredCurrency().code, equals('USD'));
        expect(CamSplitCurrencyService.getGroupCurrency(1).code, equals('USD'));
        expect(CamSplitCurrencyService.getExpenseCurrency(1).code, equals('USD'));
        
        // Clear all preferences
        await CamSplitCurrencyService.clearAllPreferences();
        
        // Verify they are cleared (should return defaults)
        expect(CamSplitCurrencyService.getUserPreferredCurrency().code, equals('EUR'));
        expect(CamSplitCurrencyService.getGroupCurrency(1).code, equals('EUR'));
        expect(CamSplitCurrencyService.getExpenseCurrency(1).code, equals('EUR'));
      });
    });

    group('Error Handling', () {
      test('should handle SharedPreferences initialization failure gracefully', () {
        // Test when _prefs is null
        final currency = CamSplitCurrencyService.getUserPreferredCurrency();
        expect(currency.code, equals('EUR')); // Should return default
      });

      test('should handle JSON parsing errors gracefully', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_preferred_currency', '{invalid json}');
        
        final currency = CamSplitCurrencyService.getUserPreferredCurrency();
        expect(currency.code, equals('EUR')); // Should fall back to default
      });
    });

    group('Currency Persistence', () {
      test('should persist user currency across service reinitialization', () async {
        final usdCurrency = CamSplitCurrencyService.getCurrencyByCode('USD');
        await CamSplitCurrencyService.setUserPreferredCurrency(usdCurrency);
        
        // Reinitialize service (simulates app restart)
        await CamSplitCurrencyService.initialize();
        
        final retrievedCurrency = CamSplitCurrencyService.getUserPreferredCurrency();
        expect(retrievedCurrency.code, equals('USD'));
      });

      test('should persist group currencies across service reinitialization', () async {
        final gbpCurrency = CamSplitCurrencyService.getCurrencyByCode('GBP');
        await CamSplitCurrencyService.setGroupCurrency(123, gbpCurrency);
        
        // Reinitialize service
        await CamSplitCurrencyService.initialize();
        
        final retrievedCurrency = CamSplitCurrencyService.getGroupCurrency(123);
        expect(retrievedCurrency.code, equals('GBP'));
      });
    });
  });
}