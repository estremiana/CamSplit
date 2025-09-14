import 'package:flutter_test/flutter_test.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:camsplit/services/currency_migration_service.dart';
import 'package:camsplit/services/currency_service.dart';

void main() {
  group('CurrencyMigrationService', () {
    group('stringToCurrency', () {
      test('should convert valid currency code to Currency object', () {
        final currency = CurrencyMigrationService.stringToCurrency('USD');
        
        expect(currency.code, 'USD');
        expect(currency.name, 'US Dollar');
        expect(currency.symbol, '\$');
      });

      test('should handle lowercase currency codes', () {
        final currency = CurrencyMigrationService.stringToCurrency('eur');
        
        expect(currency.code, 'EUR');
        expect(currency.name, 'Euro');
        expect(currency.symbol, '€');
      });

      test('should handle currency codes with whitespace', () {
        final currency = CurrencyMigrationService.stringToCurrency(' GBP ');
        
        expect(currency.code, 'GBP');
        expect(currency.name, 'British Pound');
        expect(currency.symbol, '£');
      });

      test('should throw error for empty currency code', () {
        expect(
          () => CurrencyMigrationService.stringToCurrency(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error for invalid currency code format', () {
        expect(
          () => CurrencyMigrationService.stringToCurrency('US'),
          throwsA(isA<ArgumentError>()),
        );
        
        expect(
          () => CurrencyMigrationService.stringToCurrency('USDD'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error for unsupported currency code', () {
        expect(
          () => CurrencyMigrationService.stringToCurrency('XXX'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('currencyToString', () {
      test('should convert Currency object to string code', () {
        final currency = Currency(
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
        
        final result = CurrencyMigrationService.currencyToString(currency);
        expect(result, 'USD');
      });

      test('should throw error for Currency with empty code', () {
        final currency = Currency(
          code: '',
          name: 'Test',
          symbol: 'T',
          flag: '🏳️',
          number: 0,
          decimalDigits: 2,
          namePlural: 'Tests',
          symbolOnLeft: true,
          decimalSeparator: '.',
          thousandsSeparator: ',',
          spaceBetweenAmountAndSymbol: false,
        );
        
        expect(
          () => CurrencyMigrationService.currencyToString(currency),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('currencyToJson', () {
      test('should convert Currency object to JSON map', () {
        final currency = Currency(
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
        
        final json = CurrencyMigrationService.currencyToJson(currency);
        
        expect(json['code'], 'EUR');
        expect(json['name'], 'Euro');
        expect(json['symbol'], '€');
        expect(json['flag'], '🇪🇺');
        expect(json['number'], 978);
        expect(json['decimalDigits'], 2);
        expect(json['namePlural'], 'Euros');
        expect(json['symbolOnLeft'], true);
        expect(json['decimalSeparator'], '.');
        expect(json['thousandsSeparator'], ',');
        expect(json['spaceBetweenAmountAndSymbol'], false);
      });
    });

    group('jsonToCurrency', () {
      test('should convert JSON map to Currency object', () {
        final json = {
          'code': 'USD',
          'name': 'US Dollar',
          'symbol': '\$',
          'flag': '🇺🇸',
          'number': 840,
          'decimalDigits': 2,
          'namePlural': 'US Dollars',
          'symbolOnLeft': true,
          'decimalSeparator': '.',
          'thousandsSeparator': ',',
          'spaceBetweenAmountAndSymbol': false,
        };
        
        final currency = CurrencyMigrationService.jsonToCurrency(json);
        
        expect(currency.code, 'USD');
        expect(currency.name, 'US Dollar');
        expect(currency.symbol, '\$');
        expect(currency.flag, '🇺🇸');
        expect(currency.number, 840);
        expect(currency.decimalDigits, 2);
        expect(currency.namePlural, 'US Dollars');
        expect(currency.symbolOnLeft, true);
        expect(currency.decimalSeparator, '.');
        expect(currency.thousandsSeparator, ',');
        expect(currency.spaceBetweenAmountAndSymbol, false);
      });

      test('should use default values for missing fields', () {
        final json = {'code': 'EUR'};
        
        final currency = CurrencyMigrationService.jsonToCurrency(json);
        
        expect(currency.code, 'EUR');
        expect(currency.name, 'Euro');
        expect(currency.symbol, '€');
        expect(currency.flag, '🇪🇺');
        expect(currency.number, 978);
        expect(currency.decimalDigits, 2);
        expect(currency.namePlural, 'Euros');
        expect(currency.symbolOnLeft, true);
        expect(currency.decimalSeparator, '.');
        expect(currency.thousandsSeparator, ',');
        expect(currency.spaceBetweenAmountAndSymbol, false);
      });
    });

    group('validateCurrencyData', () {
      test('should validate valid string currency code', () {
        final result = CurrencyMigrationService.validateCurrencyData('USD');
        
        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      test('should validate valid Currency object', () {
        final currency = CamSplitCurrencyService.getCurrencyByCode('EUR');
        final result = CurrencyMigrationService.validateCurrencyData(currency);
        
        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      test('should validate valid JSON currency object', () {
        final json = {
          'code': 'GBP',
          'name': 'British Pound',
          'symbol': '£',
        };
        
        final result = CurrencyMigrationService.validateCurrencyData(json);
        
        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      test('should reject null data', () {
        final result = CurrencyMigrationService.validateCurrencyData(null);
        
        expect(result.isValid, false);
        expect(result.errors, contains('Currency data cannot be null'));
      });

      test('should reject empty string', () {
        final result = CurrencyMigrationService.validateCurrencyData('');
        
        expect(result.isValid, false);
        expect(result.errors, contains('Currency code cannot be empty'));
      });

      test('should reject invalid currency code format', () {
        final result = CurrencyMigrationService.validateCurrencyData('US');
        
        expect(result.isValid, false);
        expect(result.errors, contains('Invalid currency code format: US'));
      });

      test('should reject unsupported currency code', () {
        final result = CurrencyMigrationService.validateCurrencyData('XXX');
        
        expect(result.isValid, false);
        expect(result.errors, contains('Unsupported currency code: XXX'));
      });

      test('should reject JSON without code field', () {
        final json = {'name': 'Test Currency'};
        
        final result = CurrencyMigrationService.validateCurrencyData(json);
        
        expect(result.isValid, false);
        expect(result.errors, contains('Currency JSON must contain a code field'));
      });

      test('should reject unsupported data type', () {
        final result = CurrencyMigrationService.validateCurrencyData(123);
        
        expect(result.isValid, false);
        expect(result.errors, contains('Unsupported currency data type: int'));
      });
    });

    group('migrateCurrencyData', () {
      test('should migrate string currency code', () {
        final currency = CurrencyMigrationService.migrateCurrencyData('USD');
        
        expect(currency.code, 'USD');
        expect(currency.name, 'US Dollar');
      });

      test('should migrate JSON currency object', () {
        final json = {
          'code': 'EUR',
          'name': 'Euro',
          'symbol': '€',
        };
        
        final currency = CurrencyMigrationService.migrateCurrencyData(json);
        
        expect(currency.code, 'EUR');
        expect(currency.name, 'Euro');
        expect(currency.symbol, '€');
      });

      test('should return Currency object as-is', () {
        final originalCurrency = CamSplitCurrencyService.getCurrencyByCode('GBP');
        final migratedCurrency = CurrencyMigrationService.migrateCurrencyData(originalCurrency);
        
        expect(migratedCurrency, equals(originalCurrency));
      });

      test('should throw error for invalid data', () {
        expect(
          () => CurrencyMigrationService.migrateCurrencyData('XXX'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('prepareForBackend', () {
      test('should prepare currency as code string', () {
        final currency = CamSplitCurrencyService.getCurrencyByCode('USD');
        final result = CurrencyMigrationService.prepareForBackend(currency, format: 'code');
        
        expect(result, 'USD');
      });

      test('should prepare currency as JSON object', () {
        final currency = CamSplitCurrencyService.getCurrencyByCode('EUR');
        final result = CurrencyMigrationService.prepareForBackend(currency, format: 'json');
        
        expect(result, isA<Map<String, dynamic>>());
        expect(result['code'], 'EUR');
        expect(result['name'], 'Euro');
      });

      test('should throw error for unsupported format', () {
        final currency = CamSplitCurrencyService.getCurrencyByCode('GBP');
        
        expect(
          () => CurrencyMigrationService.prepareForBackend(currency, format: 'invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('parseFromBackend', () {
      test('should parse string currency code', () {
        final currency = CurrencyMigrationService.parseFromBackend('USD');
        
        expect(currency.code, 'USD');
        expect(currency.name, 'US Dollar');
      });

      test('should parse JSON currency object', () {
        final json = {
          'code': 'EUR',
          'name': 'Euro',
          'symbol': '€',
        };
        
        final currency = CurrencyMigrationService.parseFromBackend(json);
        
        expect(currency.code, 'EUR');
        expect(currency.name, 'Euro');
      });
    });

    group('needsMigration', () {
      test('should return false for Currency object', () {
        final currency = CamSplitCurrencyService.getCurrencyByCode('USD');
        final result = CurrencyMigrationService.needsMigration(currency);
        
        expect(result, false);
      });

      test('should return true for string currency code', () {
        final result = CurrencyMigrationService.needsMigration('USD');
        
        expect(result, true);
      });

      test('should return true for incomplete JSON object', () {
        final json = {'code': 'EUR'};
        final result = CurrencyMigrationService.needsMigration(json);
        
        expect(result, true);
      });

      test('should return false for complete JSON object', () {
        final json = {
          'code': 'EUR',
          'name': 'Euro',
          'symbol': '€',
        };
        final result = CurrencyMigrationService.needsMigration(json);
        
        expect(result, false);
      });

      test('should return false for null', () {
        final result = CurrencyMigrationService.needsMigration(null);
        
        expect(result, false);
      });
    });

    group('getMigrationStatistics', () {
      test('should calculate statistics for mixed dataset', () {
        final dataset = [
          'USD', // String - needs migration
          CamSplitCurrencyService.getCurrencyByCode('EUR'), // Currency object - no migration
          {'code': 'GBP'}, // Incomplete JSON - needs migration
          {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'}, // Complete JSON - no migration
          'XXX', // Invalid string - invalid
        ];
        
        final stats = CurrencyMigrationService.getMigrationStatistics(dataset);
        
        expect(stats.totalItems, 5);
        expect(stats.needsMigration, 2);
        expect(stats.validItems, 4);
        expect(stats.invalidItems, 1);
        expect(stats.migrationPercentage, 40.0);
        expect(stats.validityPercentage, 80.0);
        expect(stats.errors, contains('Unsupported currency code: XXX'));
      });

      test('should handle empty dataset', () {
        final stats = CurrencyMigrationService.getMigrationStatistics([]);
        
        expect(stats.totalItems, 0);
        expect(stats.needsMigration, 0);
        expect(stats.validItems, 0);
        expect(stats.invalidItems, 0);
        expect(stats.migrationPercentage, 0.0);
        expect(stats.validityPercentage, 0.0);
        expect(stats.errors, isEmpty);
      });
    });
  });
}
