import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';

import '../../../core/app_export.dart';
import '../../../services/currency_service.dart';
import '../../../widgets/currency_display_widget.dart';

class QuickStatsWidget extends StatelessWidget {
  final double monthlySpending;
  final int pendingSettlements;
  final int activeGroups;
  final bool isPrivacyMode;
  final Currency currency;

  QuickStatsWidget({
    super.key,
    required this.monthlySpending,
    required this.pendingSettlements,
    required this.activeGroups,
    required this.isPrivacyMode,
    Currency? currency,
  }) : currency = currency ?? CamSplitCurrencyService.getDefaultCurrency();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: 'trending_up',
              title: 'Monthly',
              value: isPrivacyMode
                  ? '••••••'
                  : null,
              currencyValue: isPrivacyMode
                  ? null
                  : monthlySpending,
              color: AppTheme.lightTheme.primaryColor,
              backgroundColor:
                  AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              icon: 'pending_actions',
              title: 'Pending',
              value: pendingSettlements.toString(),
              currencyValue: null,
              color: AppTheme.warningLight,
              backgroundColor: AppTheme.warningLight.withValues(alpha: 0.1),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildStatCard(
              icon: 'groups',
              title: 'Groups',
              value: activeGroups.toString(),
              currencyValue: null,
              color: AppTheme.successLight,
              backgroundColor: AppTheme.successLight.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String title,
    String? value,
    double? currencyValue,
    required Color color,
    required Color backgroundColor,
  }) {
    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: CustomIconWidget(
                iconName: icon,
                color: color,
                size: 20,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 0.5.h),
            value != null
                ? Text(
                    value,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : CurrencyDisplayWidget(
                    amount: currencyValue!,
                    currency: currency,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    decimalPlaces: 0,
                  ),
          ],
        ),
      ),
    );
  }
}
