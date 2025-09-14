import 'package:currency_picker/currency_picker.dart';
import 'currency_service.dart';

/// Service for handling currency data migration and compatibility
/// 
/// This service provides methods to:
/// - Convert between string currency codes and Currency objects
/// - Validate currency data during migration
/// - Ensure backward compatibility during the transition period
/// - Handle legacy data formats
class CurrencyMigrationService {
  
  /// Convert a string currency code to a Currency object
  /// 
  /// [currencyCode] - ISO currency code (e.g., 'USD', 'EUR')
  /// Returns a Currency object or throws an exception if invalid
  static Currency stringToCurrency(String currencyCode) {
    if (currencyCode.isEmpty) {
      throw ArgumentError('Currency code cannot be empty');
    }
    
    // Normalize the currency code
    final normalizedCode = currencyCode.toUpperCase().trim();
    
    // Validate format (3 uppercase letters)
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCode)) {
      throw ArgumentError('Invalid currency code format: $currencyCode');
    }
    
    // Get currency from service
    final currency = CamSplitCurrencyService.getCurrencyByCode(normalizedCode);
    
    // Check if we got the currency we requested (not a fallback)
    if (currency.code != normalizedCode) {
      throw ArgumentError('Unsupported currency code: $currencyCode');
    }
    
    return currency;
  }
  
  /// Convert a Currency object to a string currency code
  /// 
  /// [currency] - Currency object to convert
  /// Returns the currency code string
  static String currencyToString(Currency currency) {
    if (currency.code.isEmpty) {
      throw ArgumentError('Currency object has empty code');
    }
    
    return currency.code.toUpperCase();
  }
  
  /// Convert a Currency object to a JSON-serializable map
  /// 
  /// [currency] - Currency object to serialize
  /// Returns a Map that can be JSON serialized
  static Map<String, dynamic> currencyToJson(Currency currency) {
    return {
      'code': currency.code,
      'name': currency.name,
      'symbol': currency.symbol,
      'flag': currency.flag,
      'number': currency.number,
      'decimalDigits': currency.decimalDigits,
      'namePlural': currency.namePlural,
      'symbolOnLeft': currency.symbolOnLeft,
      'decimalSeparator': currency.decimalSeparator,
      'thousandsSeparator': currency.thousandsSeparator,
      'spaceBetweenAmountAndSymbol': currency.spaceBetweenAmountAndSymbol,
    };
  }
  
  /// Convert a JSON map to a Currency object
  /// 
  /// [json] - JSON map containing currency data
  /// Returns a Currency object
  static Currency jsonToCurrency(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] ?? 'EUR',
      name: json['name'] ?? 'Euro',
      symbol: json['symbol'] ?? '€',
      flag: json['flag'] ?? '🇪🇺',
      number: json['number'] ?? 978,
      decimalDigits: json['decimalDigits'] ?? 2,
      namePlural: json['namePlural'] ?? 'Euros',
      symbolOnLeft: json['symbolOnLeft'] ?? true,
      decimalSeparator: json['decimalSeparator'] ?? '.',
      thousandsSeparator: json['thousandsSeparator'] ?? ',',
      spaceBetweenAmountAndSymbol: json['spaceBetweenAmountAndSymbol'] ?? false,
    );
  }
  
  /// Validate currency data for migration
  /// 
  /// [data] - Data to validate (can be string, Map, or Currency object)
  /// Returns validation result with errors if any
  static CurrencyValidationResult validateCurrencyData(dynamic data) {
    final errors = <String>[];
    
    if (data == null) {
      errors.add('Currency data cannot be null');
      return CurrencyValidationResult(isValid: false, errors: errors);
    }
    
    if (data is String) {
      // Validate string currency code
      if (data.isEmpty) {
        errors.add('Currency code cannot be empty');
      } else if (!RegExp(r'^[A-Z]{3}$').hasMatch(data.toUpperCase())) {
        errors.add('Invalid currency code format: $data');
      } else {
        try {
          final currency = CamSplitCurrencyService.getCurrencyByCode(data);
          if (currency.code != data.toUpperCase().trim()) {
            errors.add('Unsupported currency code: $data');
          }
        } catch (e) {
          errors.add('Unsupported currency code: $data');
        }
      }
    } else if (data is Map<String, dynamic>) {
      // Validate JSON currency object
      if (!data.containsKey('code') || data['code'] == null) {
        errors.add('Currency JSON must contain a code field');
      } else {
        try {
          jsonToCurrency(data);
        } catch (e) {
          errors.add('Invalid currency JSON structure: $e');
        }
      }
    } else if (data is Currency) {
      // Validate Currency object
      if (data.code.isEmpty) {
        errors.add('Currency object has empty code');
      }
    } else {
      errors.add('Unsupported currency data type: ${data.runtimeType}');
    }
    
    return CurrencyValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Migrate currency data from legacy format to new format
  /// 
  /// [data] - Legacy currency data (string or Map)
  /// Returns migrated Currency object
  static Currency migrateCurrencyData(dynamic data) {
    final validation = validateCurrencyData(data);
    if (!validation.isValid) {
      throw ArgumentError('Invalid currency data: ${validation.errors.join(', ')}');
    }
    
    if (data is String) {
      return stringToCurrency(data);
    } else if (data is Map<String, dynamic>) {
      return jsonToCurrency(data);
    } else if (data is Currency) {
      return data;
    } else {
      throw ArgumentError('Unsupported data type for migration: ${data.runtimeType}');
    }
  }
  
  /// Prepare currency data for backend API calls
  /// 
  /// [currency] - Currency object to prepare
  /// [format] - Output format ('code' for string, 'json' for object)
  /// Returns data in the specified format
  static dynamic prepareForBackend(Currency currency, {String format = 'code'}) {
    switch (format) {
      case 'code':
        return currencyToString(currency);
      case 'json':
        return currencyToJson(currency);
      default:
        throw ArgumentError('Unsupported format: $format');
    }
  }
  
  /// Parse currency data from backend API responses
  /// 
  /// [data] - Data from backend (string or Map)
  /// Returns Currency object
  static Currency parseFromBackend(dynamic data) {
    return migrateCurrencyData(data);
  }
  
  /// Check if currency data needs migration
  /// 
  /// [data] - Currency data to check
  /// Returns true if migration is needed
  static bool needsMigration(dynamic data) {
    if (data == null) return false;
    
    // If it's already a Currency object, no migration needed
    if (data is Currency) return false;
    
    // If it's a string, migration is needed
    if (data is String) return true;
    
    // If it's a Map but doesn't have all required fields, migration needed
    if (data is Map<String, dynamic>) {
      final requiredFields = ['code', 'name', 'symbol'];
      return !requiredFields.every((field) => data.containsKey(field));
    }
    
    return true;
  }
  
  /// Get migration statistics for a dataset
  /// 
  /// [dataSet] - List of currency data to analyze
  /// Returns migration statistics
  static MigrationStatistics getMigrationStatistics(List<dynamic> dataSet) {
    int totalItems = dataSet.length;
    int needsMigrationCount = 0;
    int validItems = 0;
    int invalidItems = 0;
    final errors = <String>[];
    
    for (final item in dataSet) {
      final validation = validateCurrencyData(item);
      if (validation.isValid) {
        validItems++;
        if (needsMigration(item)) {
          needsMigrationCount++;
        }
      } else {
        invalidItems++;
        errors.addAll(validation.errors);
      }
    }
    
    return MigrationStatistics(
      totalItems: totalItems,
      needsMigration: needsMigrationCount,
      validItems: validItems,
      invalidItems: invalidItems,
      errors: errors,
    );
  }
}

/// Result of currency validation
class CurrencyValidationResult {
  final bool isValid;
  final List<String> errors;
  
  const CurrencyValidationResult({
    required this.isValid,
    required this.errors,
  });
}

/// Statistics about currency migration
class MigrationStatistics {
  final int totalItems;
  final int needsMigration;
  final int validItems;
  final int invalidItems;
  final List<String> errors;
  
  const MigrationStatistics({
    required this.totalItems,
    required this.needsMigration,
    required this.validItems,
    required this.invalidItems,
    required this.errors,
  });
  
  double get migrationPercentage => 
      totalItems > 0 ? (needsMigration / totalItems) * 100 : 0.0;
  
  double get validityPercentage => 
      totalItems > 0 ? (validItems / totalItems) * 100 : 0.0;
}
