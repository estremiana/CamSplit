import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickStatsWidget extends StatelessWidget {
  final double monthlySpending;
  final int pendingSettlements;
  final int activeGroups;
  final bool isPrivacyMode;

  const QuickStatsWidget({
    super.key,
    required this.monthlySpending,
    required this.pendingSettlements,
    required this.activeGroups,
    required this.isPrivacyMode,
  });

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
                  : '\$${monthlySpending.toStringAsFixed(0)}',
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
    required String value,
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
            Text(
              value,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
