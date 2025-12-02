import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/expense_detail_model.dart';
import '../../../models/group_member.dart';
import '../../../widgets/currency_display_widget.dart';

class SplitBreakdownSection extends StatelessWidget {
  final String splitType;
  final Map<String, double> memberTotals;
  final List<GroupMember> groupMembers;
  final ExpenseDetailModel expense;
  final VoidCallback onEditSplit;

  const SplitBreakdownSection({
    Key? key,
    required this.splitType,
    required this.memberTotals,
    required this.groupMembers,
    required this.expense,
    required this.onEditSplit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Edit Split button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Split Breakdown',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(width: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    splitType,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: onEditSplit,
              icon: Icon(
                Icons.edit,
                size: 16,
                color: AppTheme.primaryLight,
              ),
              label: Text(
                'Edit Split',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 2.h),
        
        // Member list
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.lightTheme.dividerColor,
              width: 1,
            ),
          ),
          child: memberTotals.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Center(
                    child: Text(
                      'No splits assigned yet.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: memberTotals.entries.map((entry) {
                    final memberId = int.tryParse(entry.key);
                    if (memberId == null) return SizedBox.shrink();
                    
                    final member = groupMembers.firstWhere(
                      (m) => m.id == memberId,
                      orElse: () => groupMembers.first, // Fallback to first member if not found
                    );
                    final amount = entry.value;
                    
                    // Only show members with amount > 0
                    if (amount <= 0) return SizedBox.shrink();
                    
                    return _buildMemberRow(member, amount);
                  }).where((widget) => widget is! SizedBox).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildMemberRow(GroupMember member, double amount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.lightTheme.dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18.sp,
            backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
            child: Text(
              _getInitials(member.nickname),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryLight,
              ),
            ),
          ),
          
          SizedBox(width: 3.w),
          
          // Name
          Expanded(
            child: Text(
              member.nickname,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          
          // Amount
          CurrencyDisplayWidget(
            amount: amount,
            currency: expense.currency,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    return '${nameParts[0].substring(0, 1)}${nameParts[1].substring(0, 1)}'.toUpperCase();
  }
}

