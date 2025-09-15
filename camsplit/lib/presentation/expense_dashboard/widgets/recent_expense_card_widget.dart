import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';

import '../../../core/app_export.dart';
import '../../../services/currency_service.dart';
import '../../../widgets/currency_display_widget.dart';

class RecentExpenseCardWidget extends StatelessWidget {
  final Map<String, dynamic> expense;
  final bool isPrivacyMode;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final Currency currency;

  RecentExpenseCardWidget({
    super.key,
    required this.expense,
    required this.isPrivacyMode,
    required this.onEdit,
    required this.onDuplicate,
    required this.onShare,
    required this.onDelete,
    required this.onTap,
    Currency? currency,
  }) : currency = currency ?? CamSplitCurrencyService.getDefaultCurrency();

  @override
  Widget build(BuildContext context) {
    final amount = expense["amount"] as double;
    final description = expense["description"] as String;
    final group = expense["group"] as String;
    final receiptUrl = expense["receiptUrl"] as String;
    final paidBy = expense["paidBy"] as String;
    final date = expense["date"] as DateTime;
    final splitWith = expense["splitWith"] as List;
    final amountOwed = (expense["amountOwed"] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _showContextMenu(context);
        },
        child: Card(
            elevation: 1.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Container(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  // Receipt thumbnail
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: AppTheme.borderLight,
                        width: 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CustomImageWidget(
                        imageUrl: receiptUrl,
                        width: 15.w,
                        height: 15.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Expense details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'group',
                              color: AppTheme.textSecondaryLight,
                              size: 14,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              group,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Paid by $paidBy',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                            color: AppTheme.textSecondaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 2.w),
                  // Amount, amount owed, and timestamp info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      isPrivacyMode
                          ? Text(
                              '••••••',
                              style: AppTheme.getMonospaceStyle(
                                isLight: true,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : CurrencyDisplayWidget(
                              amount: amount,
                              currency: currency,
                              style: AppTheme.getMonospaceStyle(
                                isLight: true,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                      if (amountOwed > 0) ...[
                        SizedBox(height: 0.3.h),
                        isPrivacyMode
                            ? Text(
                                '••••••',
                                style: AppTheme.getMonospaceStyle(
                                  isLight: true,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ).copyWith(
                                  color: AppTheme.errorLight,
                                ),
                              )
                            : CurrencyDisplayWidget(
                                amount: amountOwed,
                                currency: currency,
                                style: AppTheme.getMonospaceStyle(
                                  isLight: true,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ).copyWith(
                                  color: AppTheme.errorLight,
                                ),
                              ),
                      ],
                      SizedBox(height: 0.5.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'schedule',
                            color: AppTheme.textSecondaryLight,
                            size: 12,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _formatDate(date),
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }


  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              expense["description"] as String,
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'visibility',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'edit',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Edit Expense'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                onDuplicate();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                onShare();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.errorLight,
                size: 24,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: AppTheme.errorLight),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
