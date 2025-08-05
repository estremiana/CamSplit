import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

/// A widget that displays the user's net balance for a group prominently
/// with color-coded styling and appropriate messaging.
class BalanceSummaryWidget extends StatelessWidget {
  final double balance;
  final String currency;

  const BalanceSummaryWidget({
    super.key,
    required this.balance,
    this.currency = 'EUR',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: _getBackgroundColor(isLight),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _getStatusText(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _getTextColor(isLight),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              _getBalanceText(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: _getBalanceColor(isLight),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the formatted balance text with currency symbol
  String _getBalanceText() {
    final absBalance = balance.abs();
    final sign = balance < 0 ? '-' : '';
    return '$sign${absBalance.toStringAsFixed(2)}$currency';
  }

  /// Returns the appropriate status text based on balance
  String _getStatusText() {
    if (balance > 0) {
      return 'You are owed';
    } else if (balance < 0) {
      return 'You owe';
    } else {
      return 'Settled up';
    }
  }

  /// Returns the background color based on balance status and theme
  Color _getBackgroundColor(bool isLight) {
    if (balance > 0) {
      // Positive balance - success background
      return isLight 
          ? AppTheme.successLight.withValues(alpha: 0.1)
          : AppTheme.successDark.withValues(alpha: 0.1);
    } else if (balance < 0) {
      // Negative balance - error background
      return isLight 
          ? AppTheme.errorLight.withValues(alpha: 0.1)
          : AppTheme.errorDark.withValues(alpha: 0.1);
    } else {
      // Neutral balance - card background
      return isLight ? AppTheme.cardLight : AppTheme.cardDark;
    }
  }

  /// Returns the balance amount color based on status and theme
  Color _getBalanceColor(bool isLight) {
    if (balance > 0) {
      // Positive balance - success color
      return isLight ? AppTheme.successLight : AppTheme.successDark;
    } else if (balance < 0) {
      // Negative balance - error color
      return isLight ? AppTheme.errorLight : AppTheme.errorDark;
    } else {
      // Neutral balance - primary text color
      return isLight ? AppTheme.textPrimaryLight : AppTheme.textPrimaryDark;
    }
  }

  /// Returns the text color for labels and messages
  Color _getTextColor(bool isLight) {
    return isLight ? AppTheme.textSecondaryLight : AppTheme.textSecondaryDark;
  }
}