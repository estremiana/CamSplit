import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/group_member.dart';
import '../models/receipt_item.dart';
import 'split_widget_constants.dart';
import 'split_text_styles.dart';
import 'member_avatar_widget.dart';

class QuickSplitPanel extends StatelessWidget {
  final ReceiptItem item;
  final List<GroupMember> groupMembers;
  final bool isLocked;
  final Function(String memberId) onQuickToggle;
  final VoidCallback onClearAssignments;
  final VoidCallback onShowAdvanced;
  final VoidCallback? onSelectAll; // Callback to select/deselect all members

  const QuickSplitPanel({
    Key? key,
    required this.item,
    required this.groupMembers,
    required this.isLocked,
    required this.onQuickToggle,
    required this.onClearAssignments,
    required this.onShowAdvanced,
    this.onSelectAll,
  }) : super(key: key);

  String _formatQuantity(double qty) {
    return qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final assignedCount = item.getAssignedCount();
    final hasAnyAssignments = item.assignments.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(SplitWidgetConstants.paddingHorizontal.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(SplitWidgetConstants.opacityBackground),
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryLight.withOpacity(SplitWidgetConstants.opacityBorder),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUICK SPLIT (EQUAL)',
                style: SplitTextStyles.labelMedium(AppTheme.textSecondaryLight),
              ),
              // Only show Select All/Clear button when not locked (custom split not active)
              if (!isLocked && onSelectAll != null)
                TextButton(
                  onPressed: onSelectAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    hasAnyAssignments ? 'Clear' : 'Select All',
                    style: SplitTextStyles.bodyMedium(AppTheme.primaryLight),
                  ),
                ),
            ],
          ),
          SizedBox(height: SplitWidgetConstants.spacingMedium.h),
          // Member avatars grid
          Stack(
            children: [
              Opacity(
                opacity: isLocked ? SplitWidgetConstants.opacityDisabled : 1.0,
                child: IgnorePointer(
                  ignoring: isLocked,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: SplitWidgetConstants.gridCrossAxisCount,
                      crossAxisSpacing: SplitWidgetConstants.spacingSmall.w,
                      mainAxisSpacing: SplitWidgetConstants.spacingSmall.h,
                    ),
                    itemCount: groupMembers.length,
                    itemBuilder: (context, index) {
                      final member = groupMembers[index];
                      final memberId = member.id.toString();
                      final qty = item.assignments[memberId] ?? 0;
                      final isAssigned = qty > 0;

                      return InkWell(
                        onTap: () => onQuickToggle(memberId),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            MemberAvatarWidget(
                              member: member,
                              isSelected: isAssigned,
                              showCheckBadge: false,
                              showBadge: isAssigned,
                              badgeText: _formatQuantity(qty),
                              size: SplitWidgetConstants.avatarSize,
                            ),
                            SizedBox(height: SplitWidgetConstants.spacingXSmall.h),
                            Text(
                              member.nickname.split(' ')[0],
                              style: isAssigned
                                  ? SplitTextStyles.bodyMedium(AppTheme.primaryLight)
                                  : SplitTextStyles.bodyMedium(Colors.grey[400]!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Locked overlay
              if (isLocked)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: SplitWidgetConstants.paddingHorizontal.w,
                        vertical: 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(SplitWidgetConstants.opacityOverlay),
                        borderRadius: BorderRadius.circular(SplitWidgetConstants.borderRadiusMedium),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            size: SplitWidgetConstants.iconSizeLarge,
                            color: Colors.amber[600],
                          ),
                          SizedBox(width: SplitWidgetConstants.spacingSmall.w),
                          Text(
                            'Custom Split Active',
                            style: SplitTextStyles.bodyMedium(Colors.grey[600]!),
                          ),
                          SizedBox(width: SplitWidgetConstants.spacingMedium.w),
                          TextButton(
                            onPressed: onClearAssignments,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: SplitWidgetConstants.spacingMedium.w,
                                vertical: SplitWidgetConstants.spacingXSmall.h,
                              ),
                              backgroundColor: AppTheme.primaryLight.withOpacity(
                                SplitWidgetConstants.opacityBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  size: SplitWidgetConstants.iconSizeSmall,
                                  color: AppTheme.primaryLight,
                                ),
                                SizedBox(width: SplitWidgetConstants.spacingXSmall.w),
                                Text(
                                  'Reset',
                                  style: SplitTextStyles.bodySmall(AppTheme.primaryLight),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: SplitWidgetConstants.spacingMedium.h),
          Divider(),
          SizedBox(height: SplitWidgetConstants.spacingSmall.h),
          // Advanced button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onShowAdvanced,
              icon: Icon(
                Icons.settings,
                size: SplitWidgetConstants.textSizeLarge,
                color: AppTheme.primaryLight,
              ),
              label: Text(
                'Advanced / Partial Split',
                style: SplitTextStyles.bodyMedium(AppTheme.primaryLight),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryLight.withOpacity(
                  SplitWidgetConstants.opacityBorder,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: SplitWidgetConstants.paddingHorizontal.w,
                  vertical: 1.5.h,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

