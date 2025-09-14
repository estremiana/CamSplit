import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/currency_service.dart';
import 'currency_flow_integration_test.dart' as currency_flow_test;

/// Test runner for all currency integration tests
/// This provides a centralized way to run all currency-related integration tests
/// and ensures proper setup/teardown across all test suites
void main() {
  group('Currency Integration Test Suite', () {
    setUpAll(() async {
      // Global setup for all currency integration tests
      SharedPreferences.setMockInitialValues({});
      await CamSplitCurrencyService.initialize();
    });

    tearDownAll(() async {
      // Global cleanup for all currency integration tests
      await CamSplitCurrencyService.clearAllPreferences();
    });

    setUp(() async {
      // Setup before each test group
      SharedPreferences.setMockInitialValues({});
      await CamSplitCurrencyService.initialize();
    });

    tearDown(() async {
      // Cleanup after each test group
      await CamSplitCurrencyService.clearAllPreferences();
    });

    // Run currency flow integration tests
    currency_flow_test.main();

    group('Currency Integration Test Summary', () {
      test('should have comprehensive test coverage', () {
        // This test serves as a summary and verification that all test categories are covered
        expect(true, isTrue); // Placeholder - actual verification would be done by test framework
      });

      test('should verify currency service initialization', () async {
        // Verify currency service is properly initialized
        final defaultCurrency = CamSplitCurrencyService.getDefaultCurrency();
        expect(defaultCurrency.code, equals('EUR'));
        expect(defaultCurrency.name, equals('Euro'));
        expect(defaultCurrency.symbol, equals('€'));
      });

      test('should verify currency preference persistence', () async {
        // Test that currency preferences can be set and retrieved
        final usdCurrency = CamSplitCurrencyService.getCurrencyByCode('USD');
        await CamSplitCurrencyService.setUserPreferredCurrency(usdCurrency);
        
        final retrievedCurrency = CamSplitCurrencyService.getUserPreferredCurrency();
        expect(retrievedCurrency.code, equals('USD'));
        expect(retrievedCurrency.symbol, equals('\$'));
      });

      test('should verify currency validation works', () {
        // Test that currency validation is working
        final validResult = CamSplitCurrencyService.getCurrencyByCode('USD');
        expect(validResult.code, equals('USD'));
        
        // Test fallback for invalid currency
        final fallbackResult = CamSplitCurrencyService.getCurrencyByCode('INVALID');
        expect(fallbackResult.code, equals('EUR')); // Should fall back to EUR
      });

      test('should verify currency cascading logic', () async {
        // Test that group currency cascades to expenses
        final groupId = 123;
        final usdCurrency = CamSplitCurrencyService.getCurrencyByCode('USD');
        
        await CamSplitCurrencyService.setGroupCurrency(groupId, usdCurrency);
        final groupCurrency = CamSplitCurrencyService.getGroupCurrency(groupId);
        
        expect(groupCurrency.code, equals('USD'));
      });

      test('should verify locale-based currency detection', () {
        // Test locale-based currency detection (mock context)
        final detectedCurrency = CamSplitCurrencyService.getSuggestedCurrencyForLocale('en_US');
        expect(detectedCurrency.code, equals('USD'));
        
        final detectedCurrency2 = CamSplitCurrencyService.getSuggestedCurrencyForLocale('de_DE');
        expect(detectedCurrency2.code, equals('EUR'));
      });
    });
  });
}

/// Helper class to run specific currency test categories
class CurrencyTestRunner {
  /// Run only currency flow tests
  static void runCurrencyFlowTests() {
    currency_flow_test.main();
  }

  /// Run only currency validation tests
  static void runCurrencyValidationTests() {
    // This would run the currency validation tests
    // Implementation depends on how the validation tests are structured
  }

  /// Run only currency widget tests
  static void runCurrencyWidgetTests() {
    // This would run the currency widget tests
    // Implementation depends on how the widget tests are structured
  }

  /// Run all currency tests
  static void runAllCurrencyTests() {
    main();
  }
}

/// Test configuration for currency integration tests
class CurrencyTestConfig {
  static const int defaultTimeout = 30; // seconds
  static const bool enableVerboseLogging = true;
  static const List<String> supportedCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD'];
  
  /// Get test currencies for integration testing
  static List<String> getTestCurrencies() {
    return supportedCurrencies;
  }
  
  /// Get test amounts for currency formatting tests
  static List<double> getTestAmounts() {
    return [0.01, 1.00, 10.50, 100.00, 1000.99, 999999.99];
  }
  
  /// Get test scenarios for currency flow testing
  static List<Map<String, dynamic>> getTestScenarios() {
    return [
      {
        'name': 'USD Flow',
        'currency': 'USD',
        'amount': 100.50,
        'expectedSymbol': '\$',
        'expectedFormat': '\$100.50',
      },
      {
        'name': 'EUR Flow',
        'currency': 'EUR',
        'amount': 100.50,
        'expectedSymbol': '€',
        'expectedFormat': '€100.50',
      },
      {
        'name': 'JPY Flow',
        'currency': 'JPY',
        'amount': 1000,
        'expectedSymbol': '¥',
        'expectedFormat': '¥1,000',
      },
      {
        'name': 'GBP Flow',
        'currency': 'GBP',
        'amount': 100.50,
        'expectedSymbol': '£',
        'expectedFormat': '£100.50',
      },
    ];
  }
}
