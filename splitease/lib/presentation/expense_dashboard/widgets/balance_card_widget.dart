import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/dashboard_model.dart';

class BalanceCardWidget extends StatelessWidget {
  final double totalOwed;
  final double totalOwing;
  final bool isPrivacyMode;
  final VoidCallback onPrivacyToggle;

  const BalanceCardWidget({
    super.key,
    required this.totalOwed,
    required this.totalOwing,
    required this.isPrivacyMode,
    required this.onPrivacyToggle,
  });

  // Alternative constructor for new payment summary structure
  factory BalanceCardWidget.fromPaymentSummary({
    required PaymentSummaryModel paymentSummary,
    required bool isPrivacyMode,
    required VoidCallback onPrivacyToggle,
  }) {
    return BalanceCardWidget(
      totalOwed: paymentSummary.totalOwed,
      totalOwing: paymentSummary.totalOwing,
      isPrivacyMode: isPrivacyMode,
      onPrivacyToggle: onPrivacyToggle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final netBalance = totalOwed - totalOwing;
    final isPositive = netBalance >= 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightTheme.primaryColor,
                AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Balance',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.onPrimaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onPrivacyToggle();
                    },
                    child: Container(
                      padding: EdgeInsets.all(1.w),
                      decoration: BoxDecoration(
                        color: AppTheme.onPrimaryLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: CustomIconWidget(
                        iconName:
                            isPrivacyMode ? 'visibility_off' : 'visibility',
                        color: AppTheme.onPrimaryLight,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You are owed',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color:
                                AppTheme.onPrimaryLight.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          isPrivacyMode
                              ? '••••••'
                              : '\$${totalOwed.toStringAsFixed(2)}',
                          style: AppTheme.getMonospaceStyle(
                            isLight: false,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ).copyWith(
                            color: AppTheme.onPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 6.h,
                    color: AppTheme.onPrimaryLight.withValues(alpha: 0.3),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You owe',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color:
                                AppTheme.onPrimaryLight.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          isPrivacyMode
                              ? '••••••'
                              : '\$${totalOwing.toStringAsFixed(2)}',
                          style: AppTheme.getMonospaceStyle(
                            isLight: false,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ).copyWith(
                            color: AppTheme.onPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.onPrimaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? AppTheme.successLight.withValues(alpha: 0.2)
                            : AppTheme.warningLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: CustomIconWidget(
                        iconName: isPositive ? 'trending_up' : 'trending_down',
                        color: isPositive
                            ? AppTheme.successLight
                            : AppTheme.warningLight,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net Balance',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.onPrimaryLight
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            isPrivacyMode
                                ? '••••••'
                                : '${isPositive ? '+' : ''}\$${netBalance.abs().toStringAsFixed(2)}',
                            style: AppTheme.getMonospaceStyle(
                              isLight: false,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ).copyWith(
                              color: AppTheme.onPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
