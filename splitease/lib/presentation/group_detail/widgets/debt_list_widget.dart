import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../models/debt_relationship_model.dart';

/// A widget that displays all debt relationships within a group
/// with proper formatting and color coding.
class DebtListWidget extends StatelessWidget {
  final List<DebtRelationship> debts;
  final int? currentUserId;

  const DebtListWidget({
    super.key,
    required this.debts,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: _getIconColor(isLight),
                ),
                const SizedBox(width: 8),
                Text(
                  'Outstanding Balances',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getHeaderColor(isLight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDebtContent(context, isLight),
          ],
        ),
      ),
    );
  }

  /// Builds the main content area - either debt list or empty state
  Widget _buildDebtContent(BuildContext context, bool isLight) {
    if (debts.isEmpty) {
      return _buildEmptyState(context, isLight);
    }

    return Column(
      children: debts.map((debt) => _buildDebtItem(context, debt, isLight)).toList(),
    );
  }

  /// Builds the empty state widget when no debts exist
  Widget _buildEmptyState(BuildContext context, bool isLight) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: _getSuccessColor(isLight),
          ),
          const SizedBox(height: 12),
          Text(
            'Everyone is settled up',
            style: theme.textTheme.titleMedium?.copyWith(
              color: _getSuccessColor(isLight),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'No outstanding balances in this group',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getSecondaryTextColor(isLight),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds an individual debt relationship item
  Widget _buildDebtItem(BuildContext context, DebtRelationship debt, bool isLight) {
    final theme = Theme.of(context);
    final isUserInvolved = currentUserId != null && debt.involvesUser(currentUserId!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getDebtItemBackground(isLight, isUserInvolved),
        borderRadius: BorderRadius.circular(8.0),
        border: isUserInvolved 
            ? Border.all(
                color: _getPrimaryColor(isLight).withValues(alpha: 0.3),
                width: 1.0,
              )
            : null,
      ),
      child: Row(
        children: [
          // Debt relationship icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getAmountColor(isLight).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(
              Icons.swap_horiz,
              size: 16,
              color: _getAmountColor(isLight),
            ),
          ),
          const SizedBox(width: 12),
          
          // Debt description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDebtDisplayText(debt),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _getPrimaryTextColor(isLight),
                  ),
                ),
                if (isUserInvolved && currentUserId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    debt.getUserPerspectiveText(currentUserId!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getSecondaryTextColor(isLight),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Amount
          Text(
            debt.formattedAmount,
            style: AppTheme.getMonospaceStyle(
              isLight: isLight,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ).copyWith(
              color: _getAmountColor(isLight),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the formatted debt display text
  String _getDebtDisplayText(DebtRelationship debt) {
    return '${debt.debtorName} owes ${debt.creditorName}';
  }

  /// Returns the background color for debt items
  Color _getDebtItemBackground(bool isLight, bool isUserInvolved) {
    if (isUserInvolved) {
      return isLight 
          ? AppTheme.primaryLight.withValues(alpha: 0.05)
          : AppTheme.primaryDark.withValues(alpha: 0.05);
    }
    return isLight 
        ? AppTheme.surfaceLight
        : AppTheme.surfaceDark;
  }

  /// Returns the icon color for the section header
  Color _getIconColor(bool isLight) {
    return isLight ? AppTheme.textSecondaryLight : AppTheme.textSecondaryDark;
  }

  /// Returns the header text color
  Color _getHeaderColor(bool isLight) {
    return isLight ? AppTheme.textPrimaryLight : AppTheme.textPrimaryDark;
  }

  /// Returns the primary text color
  Color _getPrimaryTextColor(bool isLight) {
    return isLight ? AppTheme.textPrimaryLight : AppTheme.textPrimaryDark;
  }

  /// Returns the secondary text color
  Color _getSecondaryTextColor(bool isLight) {
    return isLight ? AppTheme.textSecondaryLight : AppTheme.textSecondaryDark;
  }

  /// Returns the success color for empty state
  Color _getSuccessColor(bool isLight) {
    return isLight ? AppTheme.successLight : AppTheme.successDark;
  }

  /// Returns the amount color (using warning color for debt amounts)
  Color _getAmountColor(bool isLight) {
    return isLight ? AppTheme.warningLight : AppTheme.warningDark;
  }

  /// Returns the primary color
  Color _getPrimaryColor(bool isLight) {
    return isLight ? AppTheme.primaryLight : AppTheme.primaryDark;
  }
}