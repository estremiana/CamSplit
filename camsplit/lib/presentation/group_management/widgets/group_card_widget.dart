import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/group.dart';

import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/currency_display_widget.dart';

class GroupCardWidget extends StatefulWidget {
  final Group group;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GroupCardWidget({
    Key? key,
    required this.group,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<GroupCardWidget> createState() => _GroupCardWidgetState();
}

class _GroupCardWidgetState extends State<GroupCardWidget> {
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildMemberAvatars() {
    final members = widget.group.members;
    final maxVisible = 3; // Show up to 3 avatars
    final visibleMembers = members.take(maxVisible).toList();
    final remainingCount = members.length - maxVisible;

    // Debug logging
    print('GroupCardWidget: Building avatars for group "${widget.group.name}"');
    print('GroupCardWidget: Members count: ${members.length}');
    print('GroupCardWidget: Visible members: ${visibleMembers.length}');
    for (var member in visibleMembers) {
      print('GroupCardWidget: Member: ${member.nickname}, Avatar: ${member.avatarUrl}, UserId: ${member.userId}');
    }

    // If no members, show a placeholder
    if (members.isEmpty) {
      return Container(
        width: 7.w,
        height: 7.w,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.group,
            size: 12,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Row(
      children: [
        ...visibleMembers.map((member) => Container(
          margin: EdgeInsets.only(right: 0.5.w),
          child: Container(
            width: 7.w,
            height: 7.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl: member.avatarUrl,
                width: 7.w,
                height: 7.w,
                userName: member.nickname,
                fit: BoxFit.cover,
              ),
            ),
          ),
        )),
        if (remainingCount > 0)
          Container(
            width: 7.w,
            height: 7.w,
            margin: EdgeInsets.only(left: 0.5.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBalanceDisplay() {
    final balance = widget.group.userBalance;
    if (balance == null) return SizedBox.shrink();

    Color balanceColor;
    if (balance > 0) {
      balanceColor = const Color(0xFF10B981); // Brighter green for positive balance
    } else if (balance < 0) {
      balanceColor = const Color(0xFFEF4444); // Brighter red for negative balance
    } else {
      balanceColor = AppTheme.lightTheme.colorScheme.onSurfaceVariant; // Balanced
    }

    return CurrencyDisplayWidget(
      amount: balance,
      currency: widget.group.currency,
      style: AppTheme.getMonospaceStyle(
        isLight: true,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ).copyWith(
        color: balanceColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Group model properties
    final memberCount = widget.group.memberCount;
    final lastActivity = widget.group.lastUsed;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      child: Card(
        elevation: widget.isSelected ? 4.0 : 0.0,
        color: widget.isSelected
            ? AppTheme.lightTheme.colorScheme.primaryContainer
            : AppTheme.lightTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: widget.isSelected
              ? BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  width: 2.0,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          key: Key('group_card_main_inkwell'),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                if (widget.isMultiSelectMode) ...[
                  Container(
                    width: 6.w,
                    height: 6.w,
                    margin: EdgeInsets.only(right: 3.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.outline,
                        width: 2.0,
                      ),
                      color: widget.isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : Colors.transparent,
                    ),
                    child: widget.isSelected
                        ? CustomIconWidget(
                            iconName: 'check',
                            color:
                                AppTheme.lightTheme.colorScheme.onPrimary,
                            size: 16,
                          )
                        : null,
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with title and balance
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.group.name,
                              style: AppTheme
                                  .lightTheme.textTheme.titleLarge
                                  ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!widget.isMultiSelectMode) ...[
                            SizedBox(width: 2.w),
                            _buildBalanceDisplay(),
                          ],
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      // Description
                      Text(
                        widget.group.description ?? 'No description',
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      // Bottom row with avatars, member count, and time
                      Row(
                        children: [
                          _buildMemberAvatars(),
                          SizedBox(width: 2.w),
                          Text(
                            '$memberCount members',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          Spacer(),
                          Text(
                            _getTimeAgo(lastActivity),
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          if (!widget.isMultiSelectMode) ...[
                            SizedBox(width: 1.w),
                            CustomIconWidget(
                              iconName: 'chevron_right',
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ],
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
