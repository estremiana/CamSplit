import 'package:currency_picker/currency_picker.dart';
import 'dart:io';

/// Utility class for currency formatting, validation, and locale-based operations
/// 
/// This class provides static utility methods for:
/// - Currency amount formatting with proper symbols and separators
/// - Currency code validation
/// - Locale-based default currency detection
/// - Currency symbol extraction
class CamSplitCurrencyUtils {
  
  /// Format amount with currency using proper formatting rules
  /// 
  /// [amount] - The monetary amount to format
  /// [currency] - The currency object containing formatting rules
  /// [decimalPlaces] - Optional override for decimal places (uses currency default if null)
  /// 
  /// Returns formatted string like "€123.45" or "$1,234.56"
  static String formatAmount(double amount, Currency currency, {int? decimalPlaces}) {
    final digits = decimalPlaces ?? currency.decimalDigits;
    final formattedAmount = amount.toStringAsFixed(digits);
    final parts = formattedAmount.split('.');
    
    // Add thousands separator to integer part
    String integerPart = parts[0];
    if (integerPart.length > 3) {
      integerPart = _addThousandsSeparator(integerPart, currency.thousandsSeparator);
    }
    
    // Combine integer and decimal parts
    String finalAmount = integerPart;
    if (parts.length > 1 && (digits > 0)) {
      finalAmount += currency.decimalSeparator + parts[1];
    }
    
    // Add currency symbol according to currency rules
    return _formatWithSymbol(finalAmount, currency);
  }
  
  /// Get currency symbol for a given currency code
  /// 
  /// [currencyCode] - ISO currency code (e.g., 'USD', 'EUR')
  /// 
  /// Returns the currency symbol or the code itself if not found
  static String getCurrencySymbol(String currencyCode) {
    try {
      final currency = _getCurrencyByCode(currencyCode);
      return currency.symbol;
    } catch (e) {
      // Return the code itself if currency not found
      return currencyCode;
    }
  }
  
  /// Parse currency code and return Currency object
  /// 
  /// [code] - ISO currency code to parse
  /// 
  /// Returns Currency object or throws exception if invalid
  static Currency parseCurrencyCode(String code) {
    if (!isValidCurrencyCode(code)) {
      throw ArgumentError('Invalid currency code: $code');
    }
    return _getCurrencyByCode(code);
  }
  
  /// Validate if a currency code is valid
  /// 
  /// [code] - Currency code to validate
  /// 
  /// Returns true if the code is a valid ISO currency code
  static bool isValidCurrencyCode(String code) {
    if (code.length != 3) return false;
    
    try {
      _getCurrencyByCode(code);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get system default currency based on device locale
  /// 
  /// Attempts to detect the appropriate currency based on the device's
  /// locale settings. Falls back to EUR if detection fails.
  /// 
  /// Returns Currency object for the detected or default currency
  static Currency getSystemDefaultCurrency() {
    try {
      final locale = Platform.localeName;
      final countryCode = _extractCountryCode(locale);
      final currencyCode = _getCurrencyForCountry(countryCode);
      
      if (currencyCode != null && isValidCurrencyCode(currencyCode)) {
        return parseCurrencyCode(currencyCode);
      }
    } catch (e) {
      // Ignore errors and fall back to default
    }
    
    // Fall back to EUR as specified in requirements
    return _getCurrencyByCode('EUR');
  }
  
  /// Format amount for display with minimal decimal places
  /// 
  /// Removes unnecessary trailing zeros and decimal points
  /// 
  /// [amount] - Amount to format
  /// [currency] - Currency for formatting rules
  /// 
  /// Returns formatted string with minimal decimal representation
  static String formatAmountMinimal(double amount, Currency currency) {
    String formatted = formatAmount(amount, currency);
    
    // Remove trailing zeros after decimal separator
    if (formatted.contains(currency.decimalSeparator)) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      if (formatted.endsWith(currency.decimalSeparator)) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
    }
    
    return formatted;
  }
  
  /// Compare two currency amounts with proper decimal precision
  /// 
  /// [amount1] - First amount to compare
  /// [amount2] - Second amount to compare
  /// [currency] - Currency for decimal precision
  /// 
  /// Returns -1 if amount1 < amount2, 0 if equal, 1 if amount1 > amount2
  static int compareAmounts(double amount1, double amount2, Currency currency) {
    final precision = currency.decimalDigits;
    final multiplier = _getPrecisionMultiplier(precision);
    
    final int1 = (amount1 * multiplier).round();
    final int2 = (amount2 * multiplier).round();
    
    return int1.compareTo(int2);
  }
  
  /// Check if two amounts are equal within currency precision
  /// 
  /// [amount1] - First amount to compare
  /// [amount2] - Second amount to compare
  /// [currency] - Currency for decimal precision
  /// 
  /// Returns true if amounts are equal within the currency's decimal precision
  static bool areAmountsEqual(double amount1, double amount2, Currency currency) {
    return compareAmounts(amount1, amount2, currency) == 0;
  }
  
  // Private helper methods
  
  /// Add thousands separator to integer part of amount
  static String _addThousandsSeparator(String integerPart, String separator) {
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(integerPart[i]);
    }
    return buffer.toString();
  }
  
  /// Format amount with currency symbol according to currency rules
  static String _formatWithSymbol(String amount, Currency currency) {
    if (currency.symbolOnLeft) {
      return currency.spaceBetweenAmountAndSymbol 
          ? '${currency.symbol} $amount'
          : '${currency.symbol}$amount';
    } else {
      return currency.spaceBetweenAmountAndSymbol 
          ? '$amount ${currency.symbol}'
          : '$amount${currency.symbol}';
    }
  }
  
  /// Extract country code from locale string
  static String _extractCountryCode(String locale) {
    // Locale format is typically "en_US" or "en-US"
    final parts = locale.split(RegExp(r'[_-]'));
    return parts.length > 1 ? parts[1].toUpperCase() : '';
  }
  
  /// Get currency code for a country code
  static String? _getCurrencyForCountry(String countryCode) {
    // Map of common country codes to currency codes
    const countryToCurrency = {
      'US': 'USD',
      'GB': 'GBP',
      'DE': 'EUR',
      'FR': 'EUR',
      'IT': 'EUR',
      'ES': 'EUR',
      'NL': 'EUR',
      'BE': 'EUR',
      'AT': 'EUR',
      'PT': 'EUR',
      'IE': 'EUR',
      'FI': 'EUR',
      'GR': 'EUR',
      'LU': 'EUR',
      'MT': 'EUR',
      'CY': 'EUR',
      'SK': 'EUR',
      'SI': 'EUR',
      'EE': 'EUR',
      'LV': 'EUR',
      'LT': 'EUR',
      'JP': 'JPY',
      'CA': 'CAD',
      'AU': 'AUD',
      'CH': 'CHF',
      'CN': 'CNY',
      'IN': 'INR',
      'BR': 'BRL',
      'MX': 'MXN',
      'KR': 'KRW',
      'RU': 'RUB',
      'ZA': 'ZAR',
      'SE': 'SEK',
      'NO': 'NOK',
      'DK': 'DKK',
      'PL': 'PLN',
      'CZ': 'CZK',
      'HU': 'HUF',
      'RO': 'RON',
      'BG': 'BGN',
      'HR': 'HRK',
      'TR': 'TRY',
      'IL': 'ILS',
      'AE': 'AED',
      'SA': 'SAR',
      'EG': 'EGP',
      'NG': 'NGN',
      'KE': 'KES',
      'GH': 'GHS',
      'TH': 'THB',
      'VN': 'VND',
      'ID': 'IDR',
      'MY': 'MYR',
      'SG': 'SGD',
      'PH': 'PHP',
      'HK': 'HKD',
      'TW': 'TWD',
      'NZ': 'NZD',
      'AR': 'ARS',
      'CL': 'CLP',
      'CO': 'COP',
      'PE': 'PEN',
      'UY': 'UYU',
    };
    
    return countryToCurrency[countryCode];
  }
  
  /// Get precision multiplier for decimal places
  static double _getPrecisionMultiplier(int decimalPlaces) {
    double multiplier = 1.0;
    for (int i = 0; i < decimalPlaces; i++) {
      multiplier *= 10.0;
    }
    return multiplier;
  }
  
  /// Get currency by code using a predefined map
  static Currency _getCurrencyByCode(String code) {
    final currencies = {
      'EUR': Currency(
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
      ),
      'USD': Currency(
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
      ),
      'GBP': Currency(
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
      ),
      'JPY': Currency(
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
      ),
      'CAD': Currency(
        code: 'CAD',
        name: 'Canadian Dollar',
        symbol: 'CA\$',
        flag: '🇨🇦',
        number: 124,
        decimalDigits: 2,
        namePlural: 'Canadian Dollars',
        symbolOnLeft: true,
        decimalSeparator: '.',
        thousandsSeparator: ',',
        spaceBetweenAmountAndSymbol: false,
      ),
      'AUD': Currency(
        code: 'AUD',
        name: 'Australian Dollar',
        symbol: 'A\$',
        flag: '🇦🇺',
        number: 36,
        decimalDigits: 2,
        namePlural: 'Australian Dollars',
        symbolOnLeft: true,
        decimalSeparator: '.',
        thousandsSeparator: ',',
        spaceBetweenAmountAndSymbol: false,
      ),
      'CHF': Currency(
        code: 'CHF',
        name: 'Swiss Franc',
        symbol: 'CHF',
        flag: '🇨🇭',
        number: 756,
        decimalDigits: 2,
        namePlural: 'Swiss Francs',
        symbolOnLeft: true,
        decimalSeparator: '.',
        thousandsSeparator: ',',
        spaceBetweenAmountAndSymbol: true,
      ),
      'CNY': Currency(
        code: 'CNY',
        name: 'Chinese Yuan',
        symbol: '¥',
        flag: '🇨🇳',
        number: 156,
        decimalDigits: 2,
        namePlural: 'Chinese Yuan',
        symbolOnLeft: true,
        decimalSeparator: '.',
        thousandsSeparator: ',',
        spaceBetweenAmountAndSymbol: false,
      ),
      'INR': Currency(
        code: 'INR',
        name: 'Indian Rupee',
        symbol: '₹',
        flag: '🇮🇳',
        number: 356,
        decimalDigits: 2,
        namePlural: 'Indian Rupees',
        symbolOnLeft: true,
        decimalSeparator: '.',
        thousandsSeparator: ',',
        spaceBetweenAmountAndSymbol: false,
      ),
      'BRL': Currency(
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
      ),
    };
    
    final currency = currencies[code];
    if (currency == null) {
      throw ArgumentError('Currency not found: $code');
    }
    return currency;
  }
}