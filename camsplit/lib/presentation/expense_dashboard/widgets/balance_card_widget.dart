import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';

import '../../../core/app_export.dart';

import '../../../services/currency_service.dart';
import '../../../widgets/currency_display_widget.dart';

class BalanceCardWidget extends StatelessWidget {
  final double totalOwed;
  final double totalOwing;
  final bool isPrivacyMode;
  final VoidCallback onPrivacyToggle;
  final Currency currency;

  BalanceCardWidget({
    super.key,
    required this.totalOwed,
    required this.totalOwing,
    required this.isPrivacyMode,
    required this.onPrivacyToggle,
    Currency? currency,
  }) : currency = currency ?? CamSplitCurrencyService.getDefaultCurrency();

  // Alternative constructor for new payment summary structure
  factory BalanceCardWidget.fromPaymentSummary({
    required PaymentSummaryModel paymentSummary,
    required bool isPrivacyMode,
    required VoidCallback onPrivacyToggle,
    Currency? currency,
  }) {
    return BalanceCardWidget(
      totalOwed: paymentSummary.totalOwed,
      totalOwing: paymentSummary.totalOwing,
      isPrivacyMode: isPrivacyMode,
      onPrivacyToggle: onPrivacyToggle,
      currency: currency,
    );
  }

  @override
  Widget build(BuildContext context) {
    final netBalance = totalOwed - totalOwing;
    final isPositive = netBalance >= 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.2.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.0),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2B32B2),
              Color(0xFF2563EB),
              Color(0xFF1488CC),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryLight.withValues(alpha: 0.35),
              blurRadius: 38,
              spreadRadius: -8,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.onPrimaryLight.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    isPrivacyMode
                        ? Text(
                            '••••••',
                            style: AppTheme.getMonospaceStyle(
                              isLight: false,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                            ).copyWith(
                              color: AppTheme.onPrimaryLight,
                            ),
                          )
                        : CurrencyDisplayWidget(
                            amount: netBalance,
                            currency: currency,
                            style: AppTheme.getMonospaceStyle(
                              isLight: false,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                            ).copyWith(
                              color: AppTheme.onPrimaryLight,
                            ),
                          ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPrivacyToggle();
                  },
                  child: Container(
                    padding: EdgeInsets.all(1.2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.onPrimaryLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: CustomIconWidget(
                      iconName: isPrivacyMode ? 'visibility_off' : 'visibility',
                      color: AppTheme.onPrimaryLight,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.5.h),
            Row(
              children: [
                Expanded(
                  child: _BalancePill(
                    label: 'You owe',
                    amount: totalOwing,
                    isPrivacyMode: isPrivacyMode,
                    currency: currency,
                    amountStyle: AppTheme.getMonospaceStyle(
                      isLight: false,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ).copyWith(
                      color: AppTheme.warningLight,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _BalancePill(
                    label: 'Owed to you',
                    amount: totalOwed,
                    isPrivacyMode: isPrivacyMode,
                    currency: currency,
                    amountStyle: AppTheme.getMonospaceStyle(
                      isLight: false,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ).copyWith(
                      color: AppTheme.successLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final String label;
  final double amount;
  final bool isPrivacyMode;
  final Currency currency;
  final TextStyle amountStyle;

  const _BalancePill({
    required this.label,
    required this.amount,
    required this.isPrivacyMode,
    required this.currency,
    required this.amountStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.onPrimaryLight.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: 0.5.h),
          isPrivacyMode
              ? Text(
                  '••••••',
                  style: amountStyle.copyWith(
                    color: AppTheme.onPrimaryLight,
                  ),
                )
              : CurrencyDisplayWidget(
                  amount: amount,
                  currency: currency,
                  style: amountStyle,
                ),
        ],
      ),
    );
  }
}
