import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';

import '../utils/currency_utils.dart';

/// A standardized currency display widget that provides consistent
/// currency amount formatting across the entire application.
/// 
/// This widget replaces hardcoded currency symbols with dynamic
/// formatting based on Currency objects, ensuring consistent display
/// of monetary amounts throughout the app.
class CurrencyDisplayWidget extends StatelessWidget {
  /// The monetary amount to display
  final double amount;
  
  /// The currency object containing formatting rules
  final Currency currency;
  
  /// Optional text style for the displayed amount
  final TextStyle? style;
  
  /// Whether to show the amount in privacy mode (e.g., "***" for sensitive data)
  final bool isPrivacyMode;
  
  /// Optional override for decimal places (uses currency default if null)
  final int? decimalPlaces;
  
  /// Whether to show the currency code alongside the symbol
  final bool showCurrencyCode;
  
  /// Whether to use minimal decimal formatting (removes trailing zeros)
  final bool useMinimalFormatting;
  
  /// Whether to show negative amounts with parentheses instead of minus sign
  final bool useParenthesesForNegative;
  
  /// Custom text alignment
  final TextAlign? textAlign;
  
  /// Whether to show the amount as compact (e.g., "1.2K" instead of "1,200")
  final bool isCompact;
  
  /// Maximum number of digits before using compact format
  final int compactThreshold;

  const CurrencyDisplayWidget({
    super.key,
    required this.amount,
    required this.currency,
    this.style,
    this.isPrivacyMode = false,
    this.decimalPlaces,
    this.showCurrencyCode = false,
    this.useMinimalFormatting = false,
    this.useParenthesesForNegative = false,
    this.textAlign,
    this.isCompact = false,
    this.compactThreshold = 4,
  });

  /// Get the formatted amount string
  String _getFormattedAmount() {
    if (isPrivacyMode) {
      return '***';
    }

    double displayAmount = amount;
    String formattedAmount;

    // Handle compact formatting
    if (isCompact && _shouldUseCompactFormat()) {
      formattedAmount = _formatCompactAmount(displayAmount);
    } else {
      // Use the appropriate formatting method
      if (useMinimalFormatting) {
        formattedAmount = CamSplitCurrencyUtils.formatAmountMinimal(displayAmount, currency);
      } else {
        formattedAmount = CamSplitCurrencyUtils.formatAmount(displayAmount, currency, decimalPlaces: decimalPlaces);
      }
    }

    // Handle negative amounts with parentheses if requested
    if (useParenthesesForNegative && amount < 0) {
      formattedAmount = formattedAmount.replaceFirst('-', '(') + ')';
    }

    // Add currency code if requested
    if (showCurrencyCode) {
      formattedAmount += ' ${currency.code}';
    }

    return formattedAmount;
  }

  /// Check if compact formatting should be used
  bool _shouldUseCompactFormat() {
    final absAmount = amount.abs();
    final digits = absAmount.toStringAsFixed(0).length;
    return digits >= compactThreshold;
  }

  /// Format amount in compact form (e.g., "1.2K", "1.5M")
  String _formatCompactAmount(double amount) {
    final absAmount = amount.abs();
    final isNegative = amount < 0;
    
    String compactAmount;
    if (absAmount >= 1000000) {
      compactAmount = '${(absAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absAmount >= 1000) {
      compactAmount = '${(absAmount / 1000).toStringAsFixed(1)}K';
    } else {
      // For amounts less than 1000, use normal formatting
      compactAmount = CamSplitCurrencyUtils.formatAmount(absAmount, currency, decimalPlaces: decimalPlaces);
      // Remove the currency symbol since we'll add it back
      compactAmount = compactAmount.replaceFirst(currency.symbol, '');
    }

    // Add currency symbol according to currency rules
    if (currency.symbolOnLeft) {
      compactAmount = currency.spaceBetweenAmountAndSymbol 
          ? '${currency.symbol} $compactAmount'
          : '${currency.symbol}$compactAmount';
    } else {
      compactAmount = currency.spaceBetweenAmountAndSymbol 
          ? '$compactAmount ${currency.symbol}'
          : '$compactAmount${currency.symbol}';
    }

    // Add negative sign if needed
    if (isNegative) {
      compactAmount = '-$compactAmount';
    }

    return compactAmount;
  }

  /// Get the appropriate text color based on amount and context
  Color _getTextColor(BuildContext context) {
    if (isPrivacyMode) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }

    // Use provided style color or default
    if (style?.color != null) {
      return style!.color!;
    }

    // Default color based on amount
    if (amount < 0) {
      return Theme.of(context).colorScheme.error;
    } else if (amount == 0) {
      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }

    return Theme.of(context).colorScheme.onSurface;
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = _getFormattedAmount();
    final textColor = _getTextColor(context);

    return Text(
      formattedAmount,
      style: style?.copyWith(color: textColor) ?? TextStyle(color: textColor),
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Extension to provide convenient currency display methods
extension CurrencyDisplayExtension on Widget {
  /// Wrap a widget with currency display formatting
  Widget withCurrencyDisplay({
    required double amount,
    required Currency currency,
    TextStyle? style,
    bool isPrivacyMode = false,
    int? decimalPlaces,
    bool showCurrencyCode = false,
    bool useMinimalFormatting = false,
    bool useParenthesesForNegative = false,
    TextAlign? textAlign,
    bool isCompact = false,
    int compactThreshold = 4,
  }) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: style,
      isPrivacyMode: isPrivacyMode,
      decimalPlaces: decimalPlaces,
      showCurrencyCode: showCurrencyCode,
      useMinimalFormatting: useMinimalFormatting,
      useParenthesesForNegative: useParenthesesForNegative,
      textAlign: textAlign,
      isCompact: isCompact,
      compactThreshold: compactThreshold,
    );
  }
}

/// Convenience class for common currency display patterns
class CurrencyDisplay {
  /// Display amount with default formatting
  static Widget amount({
    required double amount,
    required Currency currency,
    TextStyle? style,
    TextAlign? textAlign,
  }) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: style,
      textAlign: textAlign,
    );
  }

  /// Display amount in compact format (e.g., "€1.2K")
  static Widget compact({
    required double amount,
    required Currency currency,
    TextStyle? style,
    int threshold = 4,
  }) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: style,
      isCompact: true,
      compactThreshold: threshold,
    );
  }

  /// Display amount with minimal decimal places
  static Widget minimal({
    required double amount,
    required Currency currency,
    TextStyle? style,
  }) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: style,
      useMinimalFormatting: true,
    );
  }

  /// Display amount in privacy mode (shows "***")
  static Widget privacy({
    required double amount,
    required Currency currency,
    TextStyle? style,
  }) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: style,
      isPrivacyMode: true,
    );
  }

  /// Display amount with currency code
  static Widget withCode({
    required double amount,
    required Currency currency,
    TextStyle? style,
  }) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: style,
      showCurrencyCode: true,
    );
  }

  /// Display negative amounts with parentheses
  static Widget withParentheses({
    required double amount,
    required Currency currency,
    TextStyle? style,
  }) {
    return CurrencyDisplayWidget(
      amount: amount,
      currency: currency,
      style: style,
      useParenthesesForNegative: true,
    );
  }
}
