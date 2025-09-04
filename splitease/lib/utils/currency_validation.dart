import 'package:currency_picker/currency_picker.dart';
import '../services/currency_service.dart';

/// Comprehensive currency validation utilities
class CurrencyValidation {
  /// Validate currency selection in expense creation
  static ValidationResult validateExpenseCurrency(Currency? currency) {
    if (currency == null) {
      return ValidationResult(
        isValid: false,
        errors: ['Currency selection is required'],
      );
    }
    
    return validateCurrency(currency);
  }
  
  /// Validate currency selection in group creation
  static ValidationResult validateGroupCurrency(Currency? currency) {
    if (currency == null) {
      return ValidationResult(
        isValid: false,
        errors: ['Group currency is required'],
      );
    }
    
    return validateCurrency(currency);
  }
  
  /// Validate currency for settlements
  static ValidationResult validateSettlementCurrency(Currency? currency) {
    if (currency == null) {
      return ValidationResult(
        isValid: false,
        errors: ['Settlement currency is required'],
      );
    }
    
    return validateCurrency(currency);
  }
  
  /// Validate currency object comprehensively
  static ValidationResult validateCurrency(Currency currency) {
    final errors = <String>[];
    
    // Validate currency code
    if (currency.code.isEmpty) {
      errors.add('Currency code cannot be empty');
    } else if (currency.code.length != 3) {
      errors.add('Currency code must be exactly 3 characters long');
    } else if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency.code)) {
      errors.add('Currency code must contain only uppercase letters');
    } else if (!SplitEaseCurrencyService.isValidCurrencyCode(currency.code)) {
      errors.add('Currency code "${currency.code}" is not supported');
    }
    
    // Validate currency name
    if (currency.name.isEmpty) {
      errors.add('Currency name cannot be empty');
    }
    
    // Validate currency symbol
    if (currency.symbol.isEmpty) {
      errors.add('Currency symbol cannot be empty');
    }
    
    // Validate decimal digits
    if (currency.decimalDigits < 0 || currency.decimalDigits > 4) {
      errors.add('Currency decimal digits must be between 0 and 4');
    }
    
    // Validate separators
    if (currency.decimalSeparator.isEmpty) {
      errors.add('Decimal separator cannot be empty');
    }
    
    if (currency.thousandsSeparator.isEmpty) {
      errors.add('Thousands separator cannot be empty');
    }
    
    if (currency.decimalSeparator == currency.thousandsSeparator) {
      errors.add('Decimal and thousands separators must be different');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Validate currency code string
  static ValidationResult validateCurrencyCode(String? code) {
    final errors = <String>[];
    
    if (code == null || code.isEmpty) {
      errors.add('Currency code is required');
      return ValidationResult(isValid: false, errors: errors);
    }
    
    final normalizedCode = code.trim().toUpperCase();
    
    if (normalizedCode.length != 3) {
      errors.add('Currency code must be exactly 3 characters long');
    }
    
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCode)) {
      errors.add('Currency code must contain only letters');
    }
    
    if (!SplitEaseCurrencyService.isValidCurrencyCode(normalizedCode)) {
      errors.add('Currency code "$normalizedCode" is not supported');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Validate amount for currency
  static ValidationResult validateCurrencyAmount(double? amount, Currency currency) {
    final errors = <String>[];
    
    if (amount == null) {
      errors.add('Amount is required');
      return ValidationResult(isValid: false, errors: errors);
    }
    
    if (amount <= 0) {
      errors.add('Amount must be greater than zero');
    }
    
    if (amount.isNaN || amount.isInfinite) {
      errors.add('Amount must be a valid number');
    }
    
    // Validate amount precision based on currency decimal digits
    final maxAmount = double.parse('9' * (10 - currency.decimalDigits) + '.' + '9' * currency.decimalDigits);
    if (amount > maxAmount) {
      errors.add('Amount exceeds maximum allowed for ${currency.code}');
    }
    
    // Check decimal places
    final amountString = amount.toStringAsFixed(currency.decimalDigits + 2);
    final decimalPart = amountString.split('.').length > 1 ? amountString.split('.')[1] : '';
    final significantDecimals = decimalPart.replaceAll(RegExp(r'0+$'), '').length;
    
    if (significantDecimals > currency.decimalDigits) {
      errors.add('Amount has too many decimal places for ${currency.code} (max: ${currency.decimalDigits})');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Validate currency consistency across related entities
  static ValidationResult validateCurrencyConsistency({
    Currency? groupCurrency,
    Currency? expenseCurrency,
    Currency? settlementCurrency,
  }) {
    final errors = <String>[];
    
    if (groupCurrency != null && expenseCurrency != null) {
      if (groupCurrency.code != expenseCurrency.code) {
        errors.add('Expense currency (${expenseCurrency.code}) must match group currency (${groupCurrency.code})');
      }
    }
    
    if (groupCurrency != null && settlementCurrency != null) {
      if (groupCurrency.code != settlementCurrency.code) {
        errors.add('Settlement currency (${settlementCurrency.code}) must match group currency (${groupCurrency.code})');
      }
    }
    
    if (expenseCurrency != null && settlementCurrency != null) {
      if (expenseCurrency.code != settlementCurrency.code) {
        errors.add('Settlement currency (${settlementCurrency.code}) must match expense currency (${expenseCurrency.code})');
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
  
  /// Get suggested fallback currency for invalid input
  static Currency getFallbackCurrency(String? invalidCode) {
    if (invalidCode != null && invalidCode.isNotEmpty) {
      // Try to suggest similar currency codes
      final suggestions = _getSimilarCurrencyCodes(invalidCode);
      for (final suggestion in suggestions) {
        if (SplitEaseCurrencyService.isValidCurrencyCode(suggestion)) {
          return SplitEaseCurrencyService.getCurrencyByCode(suggestion);
        }
      }
    }
    
    return SplitEaseCurrencyService.getDefaultCurrency();
  }
  
  /// Get similar currency codes for typo correction
  static List<String> _getSimilarCurrencyCodes(String input) {
    final normalized = input.trim().toUpperCase();
    final suggestions = <String>[];
    
    // Common typos and variations
    final corrections = {
      'USA': 'USD',
      'DOLLAR': 'USD',
      'EURO': 'EUR',
      'POUND': 'GBP',
      'YEN': 'JPY',
      'FRANC': 'CHF',
      'YUAN': 'CNY',
      'RUPEE': 'INR',
      'REAL': 'BRL',
    };
    
    // Check exact matches first
    if (corrections.containsKey(normalized)) {
      suggestions.add(corrections[normalized]!);
    }
    
    // Add common currencies as fallbacks
    suggestions.addAll(['USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD']);
    
    return suggestions;
  }
}

/// Result of currency validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
  
  /// Get the first error message, if any
  String? get firstError => errors.isNotEmpty ? errors.first : null;
  
  /// Get all error messages as a single string
  String get allErrors => errors.join(', ');
  
  /// Check if there are any errors
  bool get hasErrors => errors.isNotEmpty;
}
