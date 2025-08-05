import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/group.dart';
import '../../../models/group_member.dart';

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

  @override
  Widget build(BuildContext context) {
    // Use Group model properties
    final memberCount = widget.group.memberCount;
    final lastActivity = widget.group.lastUsed;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Card(
        elevation: widget.isSelected ? 4.0 : 1.0,
        color: widget.isSelected
            ? AppTheme.lightTheme.colorScheme.primaryContainer
            : AppTheme.lightTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
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
          borderRadius: BorderRadius.circular(12.0),
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
                      Text(
                        widget.group.name,
                        style: AppTheme
                            .lightTheme.textTheme.titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        widget.group.description ?? 'No description',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'group',
                            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            size: 16,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '$memberCount members',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Spacer(),
                          Text(
                            _getTimeAgo(lastActivity),
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!widget.isMultiSelectMode)
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
