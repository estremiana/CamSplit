import 'package:flutter_test/flutter_test.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:splitease/services/currency_service.dart';
import 'package:splitease/services/currency_migration_service.dart';

void main() {
  group('Currency Performance Tests', () {
    setUp(() {
      // Clear cache before each test
      SplitEaseCurrencyService.clearCache();
    });

    group('Currency Service Performance', () {
      test('should cache currency lookups for improved performance', () {
        final stopwatch = Stopwatch();
        
        // First lookup (should populate cache)
        stopwatch.start();
        final currency1 = SplitEaseCurrencyService.getCurrencyByCode('USD');
        stopwatch.stop();
        final firstLookupTime = stopwatch.elapsedMicroseconds;
        
        // Second lookup (should use cache)
        stopwatch.reset();
        stopwatch.start();
        final currency2 = SplitEaseCurrencyService.getCurrencyByCode('USD');
        stopwatch.stop();
        final secondLookupTime = stopwatch.elapsedMicroseconds;
        
        // Verify same currency returned
        expect(currency1.code, equals('USD'));
        expect(currency2.code, equals('USD'));
        expect(currency1, equals(currency2));
        
        // Verify cache is working (second lookup should be faster)
        expect(secondLookupTime, lessThan(firstLookupTime));
        
        // Verify cache statistics
        final stats = SplitEaseCurrencyService.getCacheStats();
        expect(stats['cacheSize'], equals(1));
        expect(stats['cachedCurrencies'], contains('USD'));
      });

      test('should handle cache eviction when max size is reached', () {
        // Fill cache with supported currencies
        final supportedCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR', 'BRL'];
        
        // Add each currency multiple times to test cache behavior
        for (int i = 0; i < 10; i++) {
          for (final code in supportedCurrencies) {
            SplitEaseCurrencyService.getCurrencyByCode(code);
          }
        }
        
        // Verify cache size is limited
        final stats = SplitEaseCurrencyService.getCacheStats();
        expect(stats['cacheSize'], lessThanOrEqualTo(50));
      });

      test('should perform bulk currency lookups efficiently', () {
        final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR', 'BRL'];
        final stopwatch = Stopwatch();
        
        stopwatch.start();
        for (final code in currencies) {
          SplitEaseCurrencyService.getCurrencyByCode(code);
        }
        stopwatch.stop();
        
        final totalTime = stopwatch.elapsedMicroseconds;
        final averageTime = totalTime / currencies.length;
        
        // Verify all currencies were cached
        final stats = SplitEaseCurrencyService.getCacheStats();
        expect(stats['cacheSize'], equals(currencies.length));
        
        // Verify performance is reasonable (less than 1000 microseconds per lookup)
        expect(averageTime, lessThan(1000));
      });
    });

    group('Currency Migration Service Performance', () {
      test('should efficiently convert string codes to Currency objects', () {
        final testData = [
          'USD',
          'EUR',
          'GBP',
          'JPY',
          'CAD',
          'AUD',
          'CHF',
          'CNY',
          'INR',
          'BRL',
        ];
        
        final stopwatch = Stopwatch();
        stopwatch.start();
        
        for (final code in testData) {
          CurrencyMigrationService.stringToCurrency(code);
        }
        
        stopwatch.stop();
        final totalTime = stopwatch.elapsedMicroseconds;
        final averageTime = totalTime / testData.length;
        
        // Verify performance is reasonable
        expect(averageTime, lessThan(1000));
      });

      test('should efficiently validate currency data', () {
        final testData = [
          'USD',
          'EUR',
          'INVALID',
          'GBP',
          'TEST',
          'JPY',
        ];
        
        final stopwatch = Stopwatch();
        stopwatch.start();
        
        for (final code in testData) {
          CurrencyMigrationService.validateCurrencyData(code);
        }
        
        stopwatch.stop();
        final totalTime = stopwatch.elapsedMicroseconds;
        final averageTime = totalTime / testData.length;
        
        // Verify performance is reasonable
        expect(averageTime, lessThan(1000));
      });

      test('should efficiently migrate mixed currency data', () {
        final testData = [
          'USD',
          {'code': 'EUR', 'name': 'Euro'},
          'GBP',
          'INVALID',
          {'code': 'JPY', 'name': 'Japanese Yen'},
        ];
        
        final stopwatch = Stopwatch();
        stopwatch.start();
        
        for (final data in testData) {
          try {
            CurrencyMigrationService.migrateCurrencyData(data);
          } catch (e) {
            // Expected for invalid data
          }
        }
        
        stopwatch.stop();
        final totalTime = stopwatch.elapsedMicroseconds;
        final averageTime = totalTime / testData.length;
        
        // Verify performance is reasonable
        expect(averageTime, lessThan(1000));
      });
    });

    group('Currency Formatting Performance', () {
      test('should format amounts efficiently', () {
        final currency = SplitEaseCurrencyService.getCurrencyByCode('USD');
        final amounts = [0.0, 1.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0];
        
        final stopwatch = Stopwatch();
        stopwatch.start();
        
        for (final amount in amounts) {
          SplitEaseCurrencyService.formatAmount(amount, currency);
        }
        
        stopwatch.stop();
        final totalTime = stopwatch.elapsedMicroseconds;
        final averageTime = totalTime / amounts.length;
        
        // Verify performance is reasonable
        expect(averageTime, lessThan(1000));
      });

      test('should handle large numbers efficiently', () {
        final currency = SplitEaseCurrencyService.getCurrencyByCode('USD');
        final largeAmount = 999999999.99;
        
        final stopwatch = Stopwatch();
        stopwatch.start();
        
        for (int i = 0; i < 100; i++) {
          SplitEaseCurrencyService.formatAmount(largeAmount, currency);
        }
        
        stopwatch.stop();
        final totalTime = stopwatch.elapsedMicroseconds;
        final averageTime = totalTime / 100;
        
        // Verify performance is reasonable
        expect(averageTime, lessThan(1000));
      });
    });

    group('Memory Usage Tests', () {
      test('should not cause memory leaks with repeated lookups', () {
        final initialStats = SplitEaseCurrencyService.getCacheStats();
        
        // Perform many lookups
        for (int i = 0; i < 1000; i++) {
          SplitEaseCurrencyService.getCurrencyByCode('USD');
        }
        
        final finalStats = SplitEaseCurrencyService.getCacheStats();
        
        // Cache size should remain reasonable
        expect(finalStats['cacheSize'], lessThanOrEqualTo(50));
        
        // Should not have grown significantly beyond initial size
        expect(finalStats['cacheSize'], lessThanOrEqualTo(initialStats['cacheSize'] + 10));
      });

      test('should handle cache clearing efficiently', () {
        // Populate cache
        for (int i = 0; i < 20; i++) {
          SplitEaseCurrencyService.getCurrencyByCode('USD');
        }
        
        final statsBefore = SplitEaseCurrencyService.getCacheStats();
        expect(statsBefore['cacheSize'], greaterThan(0));
        
        // Clear cache
        SplitEaseCurrencyService.clearCache();
        
        final statsAfter = SplitEaseCurrencyService.getCacheStats();
        expect(statsAfter['cacheSize'], equals(0));
      });
    });
  });
}
