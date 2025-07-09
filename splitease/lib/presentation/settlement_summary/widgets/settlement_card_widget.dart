import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettlementCardWidget extends StatelessWidget {
  final Map<String, dynamic> settlement;
  final bool isPrivacyMode;
  final VoidCallback onSettle;
  final VoidCallback onRemind;

  const SettlementCardWidget({
    super.key,
    required this.settlement,
    required this.isPrivacyMode,
    required this.onSettle,
    required this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOwed = settlement.containsKey('debtor');
    final String personName = settlement['creditor'] ?? settlement['debtor'];
    final String personAvatar =
        settlement['creditorAvatar'] ?? settlement['debtorAvatar'];
    final double amount = settlement['amount'];
    final String description = settlement['description'];
    final DateTime date = settlement['date'];
    final String group = settlement['group'];

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isOwed ? AppTheme.successLight : AppTheme.warningLight,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Direction indicator
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: (isOwed
                              ? AppTheme.successLight
                              : AppTheme.warningLight)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: CustomIconWidget(
                      iconName: isOwed ? 'arrow_downward' : 'arrow_upward',
                      color: isOwed
                          ? AppTheme.successLight
                          : AppTheme.warningLight,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Person avatar
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.borderLight,
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: CustomImageWidget(
                        imageUrl: personAvatar,
                        width: 12.w,
                        height: 12.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Person info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personName,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          isOwed ? 'owes you' : 'you owe',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isPrivacyMode
                            ? '••••••'
                            : '\$${amount.toStringAsFixed(2)}',
                        style: AppTheme.getMonospaceStyle(
                          isLight: true,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ).copyWith(
                          color: isOwed
                              ? AppTheme.successLight
                              : AppTheme.warningLight,
                        ),
                      ),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              // Description and group
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.5.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  group,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              // Suggested payment methods
              if (settlement['suggestedMethods'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested methods:',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      children: (settlement['suggestedMethods'] as List)
                          .map((method) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 1.w,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightTheme.cardColor,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomIconWidget(
                                      iconName: _getPaymentMethodIcon(method),
                                      color: AppTheme.lightTheme.primaryColor,
                                      size: 16,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      method,
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.textPrimaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRemind,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.textSecondaryLight,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'notifications',
                            color: AppTheme.textSecondaryLight,
                            size: 16,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'Remind',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSettle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOwed
                            ? AppTheme.successLight
                            : AppTheme.warningLight,
                        foregroundColor: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomIconWidget(
                            iconName: 'payment',
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            isOwed ? 'Request' : 'Settle',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'venmo':
        return 'account_balance_wallet';
      case 'paypal':
        return 'payment';
      case 'bank transfer':
        return 'account_balance';
      case 'cash':
        return 'local_atm';
      default:
        return 'payment';
    }
  }
}
