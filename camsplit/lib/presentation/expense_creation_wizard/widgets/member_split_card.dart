import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/group_member.dart';
import '../models/expense_wizard_data.dart';
import 'manual_split_input.dart';
import 'split_widget_constants.dart';
import 'split_text_styles.dart';
import 'split_callbacks.dart';
import 'member_avatar_widget.dart';

class MemberSplitCard extends StatelessWidget {
  final GroupMember member;
  final bool isSelected;
  final SplitType splitType;
  final double equalAmount;
  final double percentageAmount;
  final double totalAmount;
  final double splitDetailValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final MemberToggleCallback onToggle;
  final ManualValueChangedCallback onValueChanged;

  const MemberSplitCard({
    Key? key,
    required this.member,
    required this.isSelected,
    required this.splitType,
    required this.equalAmount,
    required this.percentageAmount,
    required this.totalAmount,
    required this.splitDetailValue,
    this.controller,
    this.focusNode,
    required this.onToggle,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final memberId = member.id.toString();

    return Container(
      margin: EdgeInsets.only(bottom: SplitWidgetConstants.spacingSmall.h),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(SplitWidgetConstants.borderRadiusLarge),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryLight.withOpacity(0.3)
              : Colors.transparent,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(SplitWidgetConstants.opacityShadow),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: () => onToggle(memberId),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.all(SplitWidgetConstants.paddingHorizontal.w),
            child: Row(
              children: [
                // Avatar
                MemberAvatarWidget(
                  member: member,
                  isSelected: isSelected,
                  onTap: () => onToggle(memberId),
                  size: SplitWidgetConstants.avatarSize,
                ),
                SizedBox(width: SplitWidgetConstants.paddingHorizontal.w),
                // Name and amount
                Expanded(
                  child: GestureDetector(
                    onTap: () => onToggle(memberId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.nickname,
                          style: SplitTextStyles.bodyXLarge(
                            isSelected ? AppTheme.textPrimaryLight : Colors.grey[600]!,
                          ),
                        ),
                        // Show "Pays" for Equal and Percentage modes
                        if (isSelected &&
                            (splitType == SplitType.equal ||
                                splitType == SplitType.percentage))
                          Text(
                            splitType == SplitType.equal
                                ? 'Pays €${equalAmount.toStringAsFixed(2)}'
                                : 'Pays €${(totalAmount * percentageAmount / 100).toStringAsFixed(2)}',
                            style: SplitTextStyles.bodySmall(AppTheme.primaryLight),
                          ),
                      ],
                    ),
                  ),
                ),
                // Input for manual modes
                if (splitType != SplitType.equal)
                  GestureDetector(
                    onTap: () {}, // Prevent tap from propagating to parent GestureDetector
                    behavior: HitTestBehavior.opaque,
                    child: ManualSplitInput(
                      memberId: memberId,
                      isSelected: isSelected,
                      isPercentage: splitType == SplitType.percentage,
                      value: splitDetailValue,
                      controller: controller,
                      focusNode: focusNode,
                      onValueChanged: onValueChanged,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

