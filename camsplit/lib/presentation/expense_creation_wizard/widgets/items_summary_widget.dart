import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/group_member.dart';
import 'split_widget_constants.dart';
import 'split_text_styles.dart';

class ItemsSummaryWidget extends StatelessWidget {
  final List<GroupMember> groupMembers;
  final Map<String, double> memberTotals; // memberId -> total amount
  final double unassignedAmount;

  const ItemsSummaryWidget({
    Key? key,
    required this.groupMembers,
    required this.memberTotals,
    required this.unassignedAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final membersWithAmounts = groupMembers
        .where((m) => (memberTotals[m.id.toString()] ?? 0) > 0.01)
        .toList();

    return Container(
      margin: EdgeInsets.only(top: SplitWidgetConstants.spacingMedium.h),
      padding: EdgeInsets.all(SplitWidgetConstants.spacingLarge.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(SplitWidgetConstants.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SUMMARY',
            style: SplitTextStyles.labelLarge(AppTheme.textSecondaryLight),
          ),
          SizedBox(height: SplitWidgetConstants.spacingSmall.h),
          ...membersWithAmounts.map((member) {
            final total = memberTotals[member.id.toString()] ?? 0.0;
            return Padding(
              padding: EdgeInsets.only(bottom: SplitWidgetConstants.spacingXSmall.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    member.nickname,
                    style: SplitTextStyles.bodyLarge(AppTheme.textPrimaryLight),
                  ),
                  Text(
                    '€${total.toStringAsFixed(2)}',
                    style: SplitTextStyles.bodyLarge(AppTheme.textPrimaryLight),
                  ),
                ],
              ),
            );
          }),
          if (unassignedAmount > 0.01) ...[
            Divider(),
            SizedBox(height: SplitWidgetConstants.spacingXSmall.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unassigned',
                  style: SplitTextStyles.bodyLarge(Colors.red[600]!),
                ),
                Text(
                  '€${unassignedAmount.toStringAsFixed(2)}',
                  style: SplitTextStyles.titleMedium(Colors.red[600]!),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

