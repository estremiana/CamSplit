import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettlementHistoryWidget extends StatelessWidget {
  final Map<String, dynamic> settlement;
  final bool isPrivacyMode;

  const SettlementHistoryWidget({
    super.key,
    required this.settlement,
    required this.isPrivacyMode,
  });

  @override
  Widget build(BuildContext context) {
    final String personName = settlement['person'];
    final String personAvatar = settlement['personAvatar'];
    final double amount = settlement['amount'];
    final String description = settlement['description'];
    final DateTime date = settlement['date'];
    final String method = settlement['method'];
    final String type = settlement['type']; // 'received' or 'paid'

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Card(
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status indicator
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: CustomIconWidget(
                      iconName: 'check_circle',
                      color: AppTheme.successLight,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Person avatar
                  Container(
                    width: 10.w,
                    height: 10.w,
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
                        width: 10.w,
                        height: 10.w,
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
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          type == 'received' ? 'paid you' : 'received payment',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount and date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isPrivacyMode
                            ? '••••••'
                            : '\$${amount.toStringAsFixed(2)}',
                        style: AppTheme.getMonospaceStyle(
                          isLight: true,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ).copyWith(
                          color: AppTheme.successLight,
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
              // Description
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 1.h),
              // Payment method and timestamp
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
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
                          size: 14,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          method,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _getTimeAgo(date),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
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

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
