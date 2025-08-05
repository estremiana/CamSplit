import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../models/settlement.dart';

/// A widget that displays all settlements within a group
/// with proper formatting and color coding.
class SettlementsWidget extends StatelessWidget {
  final List<Settlement> settlements;
  final int? currentUserId;

  const SettlementsWidget({
    super.key,
    required this.settlements,
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
                  Icons.payment_outlined,
                  size: 20,
                  color: _getIconColor(isLight),
                ),
                const SizedBox(width: 8),
                Text(
                  'Settlements',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getHeaderColor(isLight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettlementsContent(context, isLight),
          ],
        ),
      ),
    );
  }

  /// Builds the main content area - either settlements list or empty state
  Widget _buildSettlementsContent(BuildContext context, bool isLight) {
    if (settlements.isEmpty) {
      return _buildEmptyState(context, isLight);
    }

    return Column(
      children: settlements.map((settlement) => _buildSettlementItem(context, settlement, isLight)).toList(),
    );
  }

  /// Builds the empty state widget when no settlements exist
  Widget _buildEmptyState(BuildContext context, bool isLight) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: _getSecondaryTextColor(isLight),
          ),
          const SizedBox(height: 12),
          Text(
            'No settlements found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: _getSecondaryTextColor(isLight),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Settlements will appear here when they are calculated',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getSecondaryTextColor(isLight),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds an individual settlement item
  Widget _buildSettlementItem(BuildContext context, Settlement settlement, bool isLight) {
    final theme = Theme.of(context);
    final isUserInvolved = currentUserId != null && settlement.involvesUser(currentUserId!);
    final isActive = settlement.isActive;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getSettlementItemBackground(isLight, isUserInvolved, isActive),
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
          // Settlement status icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getStatusColor(isLight, isActive).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(
              isActive ? Icons.pending_outlined : Icons.check_circle_outline,
              size: 16,
              color: _getStatusColor(isLight, isActive),
            ),
          ),
          const SizedBox(width: 12),
          
          // Settlement description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settlement.displayText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: _getPrimaryTextColor(isLight),
                  ),
                ),
                if (isUserInvolved && currentUserId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    settlement.getUserPerspectiveText(currentUserId!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getSecondaryTextColor(isLight),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (settlement.calculationTimestamp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Calculated: ${_formatDate(settlement.calculationTimestamp!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getSecondaryTextColor(isLight),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Amount and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                settlement.formattedAmount,
                style: AppTheme.getMonospaceStyle(
                  isLight: isLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ).copyWith(
                  color: _getAmountColor(isLight),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(isLight, isActive).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  settlement.status.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(isLight, isActive),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Returns the background color for settlement items
  Color _getSettlementItemBackground(bool isLight, bool isUserInvolved, bool isActive) {
    if (isUserInvolved) {
      return isLight 
          ? AppTheme.primaryLight.withValues(alpha: 0.05)
          : AppTheme.primaryDark.withValues(alpha: 0.05);
    }
    if (!isActive) {
      return isLight 
          ? AppTheme.successLight.withValues(alpha: 0.05)
          : AppTheme.successDark.withValues(alpha: 0.05);
    }
    return isLight 
        ? AppTheme.surfaceLight
        : AppTheme.surfaceDark;
  }

  /// Returns the status color based on settlement status
  Color _getStatusColor(bool isLight, bool isActive) {
    if (isActive) {
      return isLight ? AppTheme.warningLight : AppTheme.warningDark;
    }
    return isLight ? AppTheme.successLight : AppTheme.successDark;
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

  /// Returns the amount color
  Color _getAmountColor(bool isLight) {
    return isLight ? AppTheme.textPrimaryLight : AppTheme.textPrimaryDark;
  }

  /// Returns the primary color
  Color _getPrimaryColor(bool isLight) {
    return isLight ? AppTheme.primaryLight : AppTheme.primaryDark;
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 