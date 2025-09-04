import 'package:currency_picker/currency_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

/// Custom exception for currency validation errors
class CurrencyValidationException implements Exception {
  final String message;
  const CurrencyValidationException(this.message);
  
  @override
  String toString() => 'CurrencyValidationException: $message';
}

/// Custom exception for currency service errors
class CurrencyServiceException implements Exception {
  final String message;
  final dynamic originalError;
  const CurrencyServiceException(this.message, [this.originalError]);
  
  @override
  String toString() => 'CurrencyServiceException: $message${originalError != null ? ' (Original: $originalError)' : ''}';
}

/// Service for managing currency preferences and operations across the app
/// 
/// This service provides centralized currency management functionality including:
/// - User preferred currency storage and retrieval
/// - Group currency management
/// - Default currency detection
/// - Currency validation and formatting
class SplitEaseCurrencyService {
  static const String _userCurrencyKey = 'user_preferred_currency';
  static const String _groupCurrencyPrefix = 'group_currency_';
  static const String _expenseCurrencyPrefix = 'expense_currency_';
  
  static SharedPreferences? _prefs;
  
  // Cache for frequently accessed currencies to improve performance
  static final Map<String, Currency> _currencyCache = {};
  static const int _maxCacheSize = 50;
  
  /// Initialize the service with SharedPreferences
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// Get the default currency (EUR as specified in requirements)
  static Currency getDefaultCurrency() {
    return SplitEaseCurrencyService.getCurrencyByCode('EUR');
  }
  
  /// Detect and suggest appropriate default currency based on user's locale
  static Currency detectLocaleBasedCurrency(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final countryCode = locale.countryCode;
    
    if (countryCode == null) {
      return getDefaultCurrency();
    }
    
    // Map of country codes to currency codes
    final countryToCurrency = {
      'US': 'USD', // United States
      'CA': 'CAD', // Canada
      'GB': 'GBP', // United Kingdom
      'JP': 'JPY', // Japan
      'AU': 'AUD', // Australia
      'CH': 'CHF', // Switzerland
      'CN': 'CNY', // China
      'IN': 'INR', // India
      'BR': 'BRL', // Brazil
      'MX': 'MXN', // Mexico
      'KR': 'KRW', // South Korea
      'SG': 'SGD', // Singapore
      'HK': 'HKD', // Hong Kong
      'NZ': 'NZD', // New Zealand
      'SE': 'SEK', // Sweden
      'NO': 'NOK', // Norway
      'DK': 'DKK', // Denmark
      'PL': 'PLN', // Poland
      'CZ': 'CZK', // Czech Republic
      'HU': 'HUF', // Hungary
      'RO': 'RON', // Romania
      'BG': 'BGN', // Bulgaria
      'HR': 'HRK', // Croatia
      'RS': 'RSD', // Serbia
      'BA': 'BAM', // Bosnia and Herzegovina
      'ME': 'EUR', // Montenegro (uses EUR)
      'MK': 'MKD', // North Macedonia
      'AL': 'ALL', // Albania
      'TR': 'TRY', // Turkey
      'IL': 'ILS', // Israel
      'AE': 'AED', // United Arab Emirates
      'SA': 'SAR', // Saudi Arabia
      'QA': 'QAR', // Qatar
      'KW': 'KWD', // Kuwait
      'BH': 'BHD', // Bahrain
      'OM': 'OMR', // Oman
      'JO': 'JOD', // Jordan
      'LB': 'LBP', // Lebanon
      'EG': 'EGP', // Egypt
      'ZA': 'ZAR', // South Africa
      'NG': 'NGN', // Nigeria
      'KE': 'KES', // Kenya
      'GH': 'GHS', // Ghana
      'UG': 'UGX', // Uganda
      'TZ': 'TZS', // Tanzania
      'ET': 'ETB', // Ethiopia
      'MA': 'MAD', // Morocco
      'TN': 'TND', // Tunisia
      'DZ': 'DZD', // Algeria
      'LY': 'LYD', // Libya
      'SD': 'SDG', // Sudan
      'SS': 'SSP', // South Sudan
      'CM': 'XAF', // Cameroon
      'CI': 'XOF', // Ivory Coast
      'SN': 'XOF', // Senegal
      'ML': 'XOF', // Mali
      'BF': 'XOF', // Burkina Faso
      'NE': 'XOF', // Niger
      'TD': 'XAF', // Chad
      'CF': 'XAF', // Central African Republic
      'CG': 'XAF', // Republic of the Congo
      'CD': 'CDF', // Democratic Republic of the Congo
      'GA': 'XAF', // Gabon
      'GQ': 'XAF', // Equatorial Guinea
      'ST': 'STN', // São Tomé and Príncipe
      'GW': 'XOF', // Guinea-Bissau
      'GN': 'GNF', // Guinea
      'SL': 'SLL', // Sierra Leone
      'LR': 'LRD', // Liberia
      'TG': 'XOF', // Togo
      'BJ': 'XOF', // Benin
      'CV': 'CVE', // Cape Verde
      'GM': 'GMD', // Gambia
      'MR': 'MRU', // Mauritania
      'DJ': 'DJF', // Djibouti
      'SO': 'SOS', // Somalia
      'ER': 'ERN', // Eritrea
      'RW': 'RWF', // Rwanda
      'BI': 'BIF', // Burundi
      'MW': 'MWK', // Malawi
      'ZM': 'ZMW', // Zambia
      'ZW': 'ZWL', // Zimbabwe
      'BW': 'BWP', // Botswana
      'NA': 'NAD', // Namibia
      'LS': 'LSL', // Lesotho
      'SZ': 'SZL', // Eswatini
      'MG': 'MGA', // Madagascar
      'MU': 'MUR', // Mauritius
      'SC': 'SCR', // Seychelles
      'KM': 'KMF', // Comoros
      'MV': 'MVR', // Maldives
      'LK': 'LKR', // Sri Lanka
      'BD': 'BDT', // Bangladesh
      'NP': 'NPR', // Nepal
      'BT': 'BTN', // Bhutan
      'MM': 'MMK', // Myanmar
      'TH': 'THB', // Thailand
      'LA': 'LAK', // Laos
      'KH': 'KHR', // Cambodia
      'VN': 'VND', // Vietnam
      'PH': 'PHP', // Philippines
      'MY': 'MYR', // Malaysia
      'ID': 'IDR', // Indonesia
      'TL': 'USD', // Timor-Leste (uses USD)
      'PG': 'PGK', // Papua New Guinea
      'FJ': 'FJD', // Fiji
      'VU': 'VUV', // Vanuatu
      'NC': 'XPF', // New Caledonia
      'PF': 'XPF', // French Polynesia
      'TO': 'TOP', // Tonga
      'WS': 'WST', // Samoa
      'KI': 'AUD', // Kiribati (uses AUD)
      'TV': 'AUD', // Tuvalu (uses AUD)
      'NR': 'AUD', // Nauru (uses AUD)
      'PW': 'USD', // Palau (uses USD)
      'MH': 'USD', // Marshall Islands (uses USD)
      'FM': 'USD', // Micronesia (uses USD)
      'CK': 'NZD', // Cook Islands (uses NZD)
      'NU': 'NZD', // Niue (uses NZD)
      'TK': 'NZD', // Tokelau (uses NZD)
      'AS': 'USD', // American Samoa (uses USD)
      'GU': 'USD', // Guam (uses USD)
      'MP': 'USD', // Northern Mariana Islands (uses USD)
      'VI': 'USD', // U.S. Virgin Islands (uses USD)
      'PR': 'USD', // Puerto Rico (uses USD)
      'DO': 'DOP', // Dominican Republic
      'HT': 'HTG', // Haiti
      'JM': 'JMD', // Jamaica
      'BB': 'BBD', // Barbados
      'TT': 'TTD', // Trinidad and Tobago
      'GD': 'XCD', // Grenada
      'LC': 'XCD', // Saint Lucia
      'VC': 'XCD', // Saint Vincent and the Grenadines
      'AG': 'XCD', // Antigua and Barbuda
      'DM': 'XCD', // Dominica
      'KN': 'XCD', // Saint Kitts and Nevis
      'BS': 'BSD', // Bahamas
      'BZ': 'BZD', // Belize
      'GT': 'GTQ', // Guatemala
      'SV': 'SVC', // El Salvador
      'HN': 'HNL', // Honduras
      'NI': 'NIO', // Nicaragua
      'CR': 'CRC', // Costa Rica
      'PA': 'PAB', // Panama
      'CO': 'COP', // Colombia
      'VE': 'VES', // Venezuela
      'GY': 'GYD', // Guyana
      'SR': 'SRD', // Suriname
      'GF': 'EUR', // French Guiana (uses EUR)
      'EC': 'USD', // Ecuador (uses USD)
      'PE': 'PEN', // Peru
      'BO': 'BOB', // Bolivia
      'CL': 'CLP', // Chile
      'AR': 'ARS', // Argentina
      'PY': 'PYG', // Paraguay
      'UY': 'UYU', // Uruguay
      'FK': 'FKP', // Falkland Islands
      'GS': 'GBP', // South Georgia and the South Sandwich Islands (uses GBP)
      'AQ': 'USD', // Antarctica (uses USD as fallback)
      'IO': 'USD', // British Indian Ocean Territory (uses USD)
      'TF': 'EUR', // French Southern Territories (uses EUR)
      'PN': 'NZD', // Pitcairn Islands (uses NZD)
      'CC': 'AUD', // Cocos Islands (uses AUD)
      'CX': 'AUD', // Christmas Island (uses AUD)
      'NF': 'AUD', // Norfolk Island (uses AUD)
      'HM': 'AUD', // Heard Island and McDonald Islands (uses AUD)
      'BV': 'NOK', // Bouvet Island (uses NOK)
      'SJ': 'NOK', // Svalbard and Jan Mayen (uses NOK)
      'YT': 'EUR', // Mayotte (uses EUR)
      'RE': 'EUR', // Réunion (uses EUR)
      'BL': 'EUR', // Saint Barthélemy (uses EUR)
      'MF': 'EUR', // Saint Martin (uses EUR)
      'GP': 'EUR', // Guadeloupe (uses EUR)
      'MQ': 'EUR', // Martinique (uses EUR)
      'PM': 'EUR', // Saint Pierre and Miquelon (uses EUR)
      'WF': 'XPF', // Wallis and Futuna (uses XPF)
      'NC': 'XPF', // New Caledonia (uses XPF)
      'PF': 'XPF', // French Polynesia (uses XPF)
      'AW': 'AWG', // Aruba
      'CW': 'ANG', // Curaçao
      'SX': 'ANG', // Sint Maarten
      'BQ': 'USD', // Caribbean Netherlands (uses USD)
      'AI': 'XCD', // Anguilla (uses XCD)
      'BM': 'BMD', // Bermuda
      'TC': 'USD', // Turks and Caicos Islands (uses USD)
      'KY': 'KYD', // Cayman Islands
      'VG': 'USD', // British Virgin Islands (uses USD)
      'MS': 'XCD', // Montserrat (uses XCD)
      'SH': 'SHP', // Saint Helena
      'AC': 'SHP', // Ascension Island (uses SHP)
      'TA': 'GBP', // Tristan da Cunha (uses GBP)
      'GI': 'GIP', // Gibraltar
      'AD': 'EUR', // Andorra (uses EUR)
      'MC': 'EUR', // Monaco (uses EUR)
      'SM': 'EUR', // San Marino (uses EUR)
      'VA': 'EUR', // Vatican City (uses EUR)
      'LI': 'CHF', // Liechtenstein (uses CHF)
      'MT': 'EUR', // Malta (uses EUR)
      'CY': 'EUR', // Cyprus (uses EUR)
      'GR': 'EUR', // Greece (uses EUR)
      'PT': 'EUR', // Portugal (uses EUR)
      'ES': 'EUR', // Spain (uses EUR)
      'IT': 'EUR', // Italy (uses EUR)
      'SI': 'EUR', // Slovenia (uses EUR)
      'SK': 'EUR', // Slovakia (uses EUR)
      'EE': 'EUR', // Estonia (uses EUR)
      'LV': 'EUR', // Latvia (uses EUR)
      'LT': 'EUR', // Lithuania (uses EUR)
      'FI': 'EUR', // Finland (uses EUR)
      'IE': 'EUR', // Ireland (uses EUR)
      'LU': 'EUR', // Luxembourg (uses EUR)
      'BE': 'EUR', // Belgium (uses EUR)
      'NL': 'EUR', // Netherlands (uses EUR)
      'DE': 'EUR', // Germany (uses EUR)
      'AT': 'EUR', // Austria (uses EUR)
      'FR': 'EUR', // France (uses EUR)
    };
    
    final currencyCode = countryToCurrency[countryCode];
    if (currencyCode != null) {
      try {
        return getCurrencyByCode(currencyCode);
      } catch (e) {
        // If currency code is not supported, fall back to default
        return getDefaultCurrency();
      }
    }
    
    // For unsupported locales, fall back to default currency
    return getDefaultCurrency();
  }
  
  /// Get suggested currency for a locale without requiring BuildContext
  static Currency getSuggestedCurrencyForLocale(String localeString) {
    // Parse locale string (e.g., "en_US", "fr_FR", "de_DE")
    final parts = localeString.split('_');
    if (parts.length < 2) {
      return getDefaultCurrency();
    }
    
    final countryCode = parts[1];
    
    // Use the same mapping as detectLocaleBasedCurrency
    final countryToCurrency = {
      'US': 'USD', 'CA': 'CAD', 'GB': 'GBP', 'JP': 'JPY', 'AU': 'AUD',
      'CH': 'CHF', 'CN': 'CNY', 'IN': 'INR', 'BR': 'BRL', 'MX': 'MXN',
      'KR': 'KRW', 'SG': 'SGD', 'HK': 'HKD', 'NZ': 'NZD', 'SE': 'SEK',
      'NO': 'NOK', 'DK': 'DKK', 'PL': 'PLN', 'CZ': 'CZK', 'HU': 'HUF',
      'RO': 'RON', 'BG': 'BGN', 'HR': 'HRK', 'RS': 'RSD', 'BA': 'BAM',
      'ME': 'EUR', 'MK': 'MKD', 'AL': 'ALL', 'TR': 'TRY', 'IL': 'ILS',
      'AE': 'AED', 'SA': 'SAR', 'QA': 'QAR', 'KW': 'KWD', 'BH': 'BHD',
      'OM': 'OMR', 'JO': 'JOD', 'LB': 'LBP', 'EG': 'EGP', 'ZA': 'ZAR',
      'NG': 'NGN', 'KE': 'KES', 'GH': 'GHS', 'UG': 'UGX', 'TZ': 'TZS',
      'ET': 'ETB', 'MA': 'MAD', 'TN': 'TND', 'DZ': 'DZD', 'LY': 'LYD',
      'SD': 'SDG', 'SS': 'SSP', 'CM': 'XAF', 'CI': 'XOF', 'SN': 'XOF',
      'ML': 'XOF', 'BF': 'XOF', 'NE': 'XOF', 'TD': 'XAF', 'CF': 'XAF',
      'CG': 'XAF', 'CD': 'CDF', 'GA': 'XAF', 'GQ': 'XAF', 'ST': 'STN',
      'GW': 'XOF', 'GN': 'GNF', 'SL': 'SLL', 'LR': 'LRD', 'TG': 'XOF',
      'BJ': 'XOF', 'CV': 'CVE', 'GM': 'GMD', 'MR': 'MRU', 'DJ': 'DJF',
      'SO': 'SOS', 'ER': 'ERN', 'RW': 'RWF', 'BI': 'BIF', 'MW': 'MWK',
      'ZM': 'ZMW', 'ZW': 'ZWL', 'BW': 'BWP', 'NA': 'NAD', 'LS': 'LSL',
      'SZ': 'SZL', 'MG': 'MGA', 'MU': 'MUR', 'SC': 'SCR', 'KM': 'KMF',
      'MV': 'MVR', 'LK': 'LKR', 'BD': 'BDT', 'NP': 'NPR', 'BT': 'BTN',
      'MM': 'MMK', 'TH': 'THB', 'LA': 'LAK', 'KH': 'KHR', 'VN': 'VND',
      'PH': 'PHP', 'MY': 'MYR', 'ID': 'IDR', 'TL': 'USD', 'PG': 'PGK',
      'FJ': 'FJD', 'VU': 'VUV', 'NC': 'XPF', 'PF': 'XPF', 'TO': 'TOP',
      'WS': 'WST', 'KI': 'AUD', 'TV': 'AUD', 'NR': 'AUD', 'PW': 'USD',
      'MH': 'USD', 'FM': 'USD', 'CK': 'NZD', 'NU': 'NZD', 'TK': 'NZD',
      'AS': 'USD', 'GU': 'USD', 'MP': 'USD', 'VI': 'USD', 'PR': 'USD',
      'DO': 'DOP', 'HT': 'HTG', 'JM': 'JMD', 'BB': 'BBD', 'TT': 'TTD',
      'GD': 'XCD', 'LC': 'XCD', 'VC': 'XCD', 'AG': 'XCD', 'DM': 'XCD',
      'KN': 'XCD', 'BS': 'BSD', 'BZ': 'BZD', 'GT': 'GTQ', 'SV': 'SVC',
      'HN': 'HNL', 'NI': 'NIO', 'CR': 'CRC', 'PA': 'PAB', 'CO': 'COP',
      'VE': 'VES', 'GY': 'GYD', 'SR': 'SRD', 'GF': 'EUR', 'EC': 'USD',
      'PE': 'PEN', 'BO': 'BOB', 'CL': 'CLP', 'AR': 'ARS', 'PY': 'PYG',
      'UY': 'UYU', 'FK': 'FKP', 'GS': 'GBP', 'AQ': 'USD', 'IO': 'USD',
      'TF': 'EUR', 'PN': 'NZD', 'CC': 'AUD', 'CX': 'AUD', 'NF': 'AUD',
      'HM': 'AUD', 'BV': 'NOK', 'SJ': 'NOK', 'YT': 'EUR', 'RE': 'EUR',
      'BL': 'EUR', 'MF': 'EUR', 'GP': 'EUR', 'MQ': 'EUR', 'PM': 'EUR',
      'WF': 'XPF', 'AW': 'AWG', 'CW': 'ANG', 'SX': 'ANG', 'BQ': 'USD',
      'AI': 'XCD', 'BM': 'BMD', 'TC': 'USD', 'KY': 'KYD', 'VG': 'USD',
      'MS': 'XCD', 'SH': 'SHP', 'AC': 'SHP', 'TA': 'GBP', 'GI': 'GIP',
      'AD': 'EUR', 'MC': 'EUR', 'SM': 'EUR', 'VA': 'EUR', 'LI': 'CHF',
      'MT': 'EUR', 'CY': 'EUR', 'GR': 'EUR', 'PT': 'EUR', 'ES': 'EUR',
      'IT': 'EUR', 'SI': 'EUR', 'SK': 'EUR', 'EE': 'EUR', 'LV': 'EUR',
      'LT': 'EUR', 'FI': 'EUR', 'IE': 'EUR', 'LU': 'EUR', 'BE': 'EUR',
      'NL': 'EUR', 'DE': 'EUR', 'AT': 'EUR', 'FR': 'EUR',
    };
    
    final currencyCode = countryToCurrency[countryCode];
    if (currencyCode != null) {
      try {
        return getCurrencyByCode(currencyCode);
      } catch (e) {
        return getDefaultCurrency();
      }
    }
    
    return getDefaultCurrency();
  }
  
  /// Set user's preferred currency with error handling
  static Future<void> setUserPreferredCurrency(Currency currency) async {
    try {
      await initialize();
      
      // Validate currency object
      if (currency.code.isEmpty) {
        throw CurrencyValidationException('Currency code cannot be empty');
      }
      
      if (!isValidCurrencyCode(currency.code)) {
        throw CurrencyValidationException('Invalid currency code: ${currency.code}');
      }
      
      final currencyJson = {
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
      
      await _prefs!.setString(_userCurrencyKey, jsonEncode(currencyJson));
    } catch (e) {
      if (e is CurrencyValidationException) {
        rethrow;
      }
      throw CurrencyServiceException('Failed to set user preferred currency', e);
    }
  }
  
  /// Get user's preferred currency with enhanced error handling
  static Currency getUserPreferredCurrency() {
    try {
      if (_prefs == null) {
        print('SharedPreferences not initialized, returning default currency');
        return getDefaultCurrency();
      }
      
      final currencyString = _prefs!.getString(_userCurrencyKey);
      if (currencyString == null) {
        return getDefaultCurrency();
      }
      
      final currencyJson = jsonDecode(currencyString) as Map<String, dynamic>;
      
      // Validate stored currency data
      final code = currencyJson['code'] as String?;
      if (code == null || code.isEmpty) {
        print('Invalid stored currency: missing or empty code');
        return getDefaultCurrency();
      }
      
      if (!isValidCurrencyCode(code)) {
        print('Invalid stored currency code: $code');
        return getDefaultCurrency();
      }
      
      return Currency(
        code: code,
        name: currencyJson['name'] ?? 'Unknown Currency',
        symbol: currencyJson['symbol'] ?? code,
        flag: currencyJson['flag'] ?? '',
        number: currencyJson['number'] ?? 0,
        decimalDigits: currencyJson['decimalDigits'] ?? 2,
        namePlural: currencyJson['namePlural'] ?? 'Unknown Currencies',
        symbolOnLeft: currencyJson['symbolOnLeft'] ?? true,
        decimalSeparator: currencyJson['decimalSeparator'] ?? '.',
        thousandsSeparator: currencyJson['thousandsSeparator'] ?? ',',
        spaceBetweenAmountAndSymbol: currencyJson['spaceBetweenAmountAndSymbol'] ?? false,
      );
    } catch (e) {
      print('Error retrieving user preferred currency: $e');
      return getDefaultCurrency();
    }
  }
  
  /// Set currency for a specific group with validation
  static Future<void> setGroupCurrency(int groupId, Currency currency) async {
    try {
      await initialize();
      
      // Validate group ID
      if (groupId <= 0) {
        throw CurrencyValidationException('Group ID must be positive, got: $groupId');
      }
      
      // Validate currency
      if (currency.code.isEmpty) {
        throw CurrencyValidationException('Currency code cannot be empty');
      }
      
      if (!isValidCurrencyCode(currency.code)) {
        throw CurrencyValidationException('Invalid currency code: ${currency.code}');
      }
      
      final currencyJson = {
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
      
      await _prefs!.setString('$_groupCurrencyPrefix$groupId', jsonEncode(currencyJson));
    } catch (e) {
      if (e is CurrencyValidationException) {
        rethrow;
      }
      throw CurrencyServiceException('Failed to set group currency for group $groupId', e);
    }
  }
  
  /// Get currency for a specific group
  static Currency getGroupCurrency(int groupId) {
    if (_prefs == null) {
      return getUserPreferredCurrency();
    }
    
    final currencyString = _prefs!.getString('$_groupCurrencyPrefix$groupId');
    if (currencyString == null) {
      return getUserPreferredCurrency();
    }
    
    try {
      final currencyJson = jsonDecode(currencyString) as Map<String, dynamic>;
      return Currency(
        code: currencyJson['code'] ?? 'EUR',
        name: currencyJson['name'] ?? 'Euro',
        symbol: currencyJson['symbol'] ?? '€',
        flag: currencyJson['flag'] ?? '🇪🇺',
        number: currencyJson['number'] ?? 978,
        decimalDigits: currencyJson['decimalDigits'] ?? 2,
        namePlural: currencyJson['namePlural'] ?? 'Euros',
        symbolOnLeft: currencyJson['symbolOnLeft'] ?? true,
        decimalSeparator: currencyJson['decimalSeparator'] ?? '.',
        thousandsSeparator: currencyJson['thousandsSeparator'] ?? ',',
        spaceBetweenAmountAndSymbol: currencyJson['spaceBetweenAmountAndSymbol'] ?? false,
      );
    } catch (e) {
      return getUserPreferredCurrency();
    }
  }
  
  /// Set currency for a specific expense
  static Future<void> setExpenseCurrency(int expenseId, Currency currency) async {
    await initialize();
    final currencyJson = {
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
    await _prefs!.setString('$_expenseCurrencyPrefix$expenseId', jsonEncode(currencyJson));
  }
  
  /// Get currency for a specific expense
  static Currency getExpenseCurrency(int expenseId) {
    if (_prefs == null) {
      return getUserPreferredCurrency();
    }
    
    final currencyString = _prefs!.getString('$_expenseCurrencyPrefix$expenseId');
    if (currencyString == null) {
      return getUserPreferredCurrency();
    }
    
    try {
      final currencyJson = jsonDecode(currencyString) as Map<String, dynamic>;
      return Currency(
        code: currencyJson['code'] ?? 'EUR',
        name: currencyJson['name'] ?? 'Euro',
        symbol: currencyJson['symbol'] ?? '€',
        flag: currencyJson['flag'] ?? '🇪🇺',
        number: currencyJson['number'] ?? 978,
        decimalDigits: currencyJson['decimalDigits'] ?? 2,
        namePlural: currencyJson['namePlural'] ?? 'Euros',
        symbolOnLeft: currencyJson['symbolOnLeft'] ?? true,
        decimalSeparator: currencyJson['decimalSeparator'] ?? '.',
        thousandsSeparator: currencyJson['thousandsSeparator'] ?? ',',
        spaceBetweenAmountAndSymbol: currencyJson['spaceBetweenAmountAndSymbol'] ?? false,
      );
    } catch (e) {
      return getUserPreferredCurrency();
    }
  }
  
  /// Get a list of popular currencies for quick selection
  static List<Currency> getPopularCurrencies() {
    return [
      getCurrencyByCode('EUR'), // Euro
      getCurrencyByCode('USD'), // US Dollar
      getCurrencyByCode('GBP'), // British Pound
      getCurrencyByCode('JPY'), // Japanese Yen
      getCurrencyByCode('CAD'), // Canadian Dollar
      getCurrencyByCode('AUD'), // Australian Dollar
      getCurrencyByCode('CHF'), // Swiss Franc
      getCurrencyByCode('CNY'), // Chinese Yuan
      getCurrencyByCode('INR'), // Indian Rupee
      getCurrencyByCode('BRL'), // Brazilian Real
    ];
  }
  
  /// Get currency by currency code with comprehensive error handling
  static Currency getCurrencyByCode(String code) {
    try {
      // Validate input
      if (code.isEmpty) {
        throw CurrencyValidationException('Currency code cannot be empty');
      }
      
      // Normalize code to uppercase
      final normalizedCode = code.trim().toUpperCase();
      
      // Validate format
      if (normalizedCode.length != 3) {
        throw CurrencyValidationException('Currency code must be exactly 3 characters long, got: $normalizedCode');
      }
      
      // Check if code contains only letters
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCode)) {
        throw CurrencyValidationException('Currency code must contain only letters, got: $normalizedCode');
      }
      
      return _getCurrencyByCode(normalizedCode);
    } on CurrencyValidationException catch (e) {
      // Log validation error and return default currency
      print('Currency validation failed for code: $code, error: ${e.message}');
      return _getCurrencyByCode('EUR');
    } catch (e) {
      // Log error and return default currency if code is not found
      print('Currency lookup failed for code: $code, error: $e');
      return _getCurrencyByCode('EUR');
    }
  }
  
  /// Validate currency code without throwing exceptions
  static bool isValidCurrencyCode(String code) {
    try {
      if (code.isEmpty) return false;
      
      final normalizedCode = code.trim().toUpperCase();
      if (normalizedCode.length != 3) return false;
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCode)) return false;
      
      _getCurrencyByCode(normalizedCode);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Safe currency code conversion with fallback
  static Currency safeCurrencyFromCode(String? code) {
    if (code == null || code.isEmpty) {
      return getDefaultCurrency();
    }
    
    try {
      return getCurrencyByCode(code);
    } on CurrencyValidationException catch (e) {
      print('Currency validation failed: ${e.message}');
      return getDefaultCurrency();
    } catch (e) {
      print('Unexpected error in currency conversion: $e');
      return getDefaultCurrency();
    }
  }
  
  /// Format amount with currency
  static String formatAmount(double amount, Currency currency) {
    final formattedAmount = amount.toStringAsFixed(currency.decimalDigits);
    final parts = formattedAmount.split('.');
    
    // Add thousands separator
    String integerPart = parts[0];
    if (integerPart.length > 3) {
      final buffer = StringBuffer();
      for (int i = 0; i < integerPart.length; i++) {
        if (i > 0 && (integerPart.length - i) % 3 == 0) {
          buffer.write(currency.thousandsSeparator);
        }
        buffer.write(integerPart[i]);
      }
      integerPart = buffer.toString();
    }
    
    // Combine integer and decimal parts
    String finalAmount = integerPart;
    if (parts.length > 1 && currency.decimalDigits > 0) {
      finalAmount += currency.decimalSeparator + parts[1];
    }
    
    // Add currency symbol
    if (currency.symbolOnLeft) {
      return currency.spaceBetweenAmountAndSymbol 
          ? '${currency.symbol} $finalAmount'
          : '${currency.symbol}$finalAmount';
    } else {
      return currency.spaceBetweenAmountAndSymbol 
          ? '$finalAmount ${currency.symbol}'
          : '$finalAmount${currency.symbol}';
    }
  }
  
  /// Clear all stored currency preferences (for testing/reset)
  static Future<void> clearAllPreferences() async {
    await initialize();
    final keys = _prefs!.getKeys().where((key) => 
        key == _userCurrencyKey || 
        key.startsWith(_groupCurrencyPrefix) || 
        key.startsWith(_expenseCurrencyPrefix)
    ).toList();
    
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }
  
  /// Get currency by code using a predefined map
  /// Get currency by code with caching for performance optimization
  static Currency _getCurrencyByCode(String code) {
    // Check cache first
    if (_currencyCache.containsKey(code)) {
      return _currencyCache[code]!;
    }
    
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
    
    // Cache the currency for future lookups
    _cacheCurrency(code, currency);
    
    return currency;
  }
  
  /// Cache a currency for performance optimization
  static void _cacheCurrency(String code, Currency currency) {
    // Implement LRU cache eviction if cache is full
    if (_currencyCache.length >= _maxCacheSize) {
      // Remove the oldest entry (first key)
      final oldestKey = _currencyCache.keys.first;
      _currencyCache.remove(oldestKey);
    }
    
    _currencyCache[code] = currency;
  }
  
  /// Clear the currency cache (useful for testing or memory management)
  static void clearCache() {
    _currencyCache.clear();
  }
  
  /// Get cache statistics for monitoring
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _currencyCache.length,
      'maxCacheSize': _maxCacheSize,
      'cachedCurrencies': _currencyCache.keys.toList(),
    };
  }
}