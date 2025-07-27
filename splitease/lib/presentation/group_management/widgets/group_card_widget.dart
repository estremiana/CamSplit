import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GroupCardWidget extends StatefulWidget {
  final Map<String, dynamic> group;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onInvite;
  final VoidCallback? onSettings;
  final VoidCallback? onViewDetails;
  final VoidCallback? onArchive;
  final VoidCallback? onLeave;

  const GroupCardWidget({
    Key? key,
    required this.group,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onInvite,
    this.onSettings,
    this.onViewDetails,
    this.onArchive,
    this.onLeave,
  }) : super(key: key);

  @override
  State<GroupCardWidget> createState() => _GroupCardWidgetState();
}

class _GroupCardWidgetState extends State<GroupCardWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.value = 0.0; // Explicitly set to collapsed
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String _formatCurrency(double amount, String currency) {
    return '\$${amount.abs().toStringAsFixed(2)}';
  }

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
    final totalBalance = widget.group['totalBalance'] as double;
    final isPositive = widget.group['isPositive'] as bool;
    final members = widget.group['members'] as List;
    final recentExpenses = widget.group['recentExpenses'] as List;

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
          onTap: widget.isMultiSelectMode 
              ? widget.onTap 
              : _toggleExpanded,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(12.0),
          child: Column(
            children: [
              Padding(
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.group['name'] as String,
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!widget.isMultiSelectMode)
                                CustomIconWidget(
                                  iconName: _isExpanded
                                      ? 'expand_less'
                                      : 'expand_more',
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            widget.group['description'] as String,
                            style: AppTheme.lightTheme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 1.h),
                          Row(
                            children: [
                              _buildMemberAvatars(members),
                              SizedBox(width: 3.w),
                              Text(
                                '${widget.group['memberCount']} members',
                                style: AppTheme.lightTheme.textTheme.bodySmall,
                              ),
                              Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatCurrency(
                                        totalBalance, widget.group['currency']),
                                    style: AppTheme.getMonospaceStyle(
                                      isLight: true,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ).copyWith(
                                      color: totalBalance == 0
                                          ? AppTheme
                                              .lightTheme.colorScheme.onSurface
                                          : isPositive
                                              ? AppTheme.successLight
                                              : AppTheme.errorLight,
                                    ),
                                  ),
                                  Text(
                                    _getTimeAgo(widget.group['lastActivity']),
                                    style:
                                        AppTheme.lightTheme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isExpanded)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: _animationController.value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildExpandedContent(members, recentExpenses),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberAvatars(List members) {
    final displayMembers = members.take(3).toList();
    final remainingCount = members.length - 3;

    return Row(
      children: [
        ...displayMembers.map((member) {
          return Container(
            margin: EdgeInsets.only(right: 1.w),
            child: CircleAvatar(
              radius: 3.w,
              backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
              child: member['avatar'] != null
                  ? ClipOval(
                      child: CustomImageWidget(
                        imageUrl: member['avatar'],
                        width: 6.w,
                        height: 6.w,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      (member['name'] as String).substring(0, 1).toUpperCase(),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
        }).toList(),
        if (remainingCount > 0)
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.lightTheme.colorScheme.secondaryContainer,
            ),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandedContent(List members, List recentExpenses) {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: AppTheme.lightTheme.dividerColor,
            height: 2.h,
          ),
          if (members.isNotEmpty) ...[
            Text(
              'Members',
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            ...members
                .take(4)
                .map((member) => _buildMemberItem(member))
                .toList(),
            if (members.length > 4)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: TextButton(
                  onPressed: () {
                    // Show all members
                  },
                  child: Text('View all ${members.length} members'),
                ),
              ),
            SizedBox(height: 2.h),
          ],
          if (recentExpenses.isNotEmpty) ...[
            Text(
              'Recent Activity',
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            ...recentExpenses
                .take(2)
                .map((expense) => _buildExpenseItem(expense))
                .toList(),
            SizedBox(height: 2.h),
          ],
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMemberItem(Map<String, dynamic> member) {
    final balance = member['balance'] as double;
    final isPositive = member['isPositive'] as bool;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 4.w,
            backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
            child: member['avatar'] != null
                ? ClipOval(
                    child: CustomImageWidget(
                      imageUrl: member['avatar'],
                      width: 8.w,
                      height: 8.w,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    (member['name'] as String).substring(0, 1).toUpperCase(),
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  member['email'] as String,
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            balance == 0
                ? 'Settled'
                : '${isPositive ? '+' : '-'}\$${balance.abs().toStringAsFixed(2)}',
            style: AppTheme.getMonospaceStyle(
              isLight: true,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ).copyWith(
              color: balance == 0
                  ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  : isPositive
                      ? AppTheme.successLight
                      : AppTheme.errorLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Map<String, dynamic> expense) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.lightTheme.colorScheme.tertiaryContainer,
            ),
            child: CustomIconWidget(
              iconName: 'receipt',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 16,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense['title'] as String,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getTimeAgo(expense['date']),
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '\$${(expense['amount'] as double).toStringAsFixed(2)}',
            style: AppTheme.getMonospaceStyle(
              isLight: true,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onViewDetails,
            icon: CustomIconWidget(
              iconName: 'visibility',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 16,
            ),
            label: Text('View Details'),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onInvite,
            icon: CustomIconWidget(
              iconName: 'person_add',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 16,
            ),
            label: Text('Invite'),
          ),
        ),
      ],
    );
  }
}
