import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/group_member.dart';
import 'split_widget_constants.dart';
import 'split_text_styles.dart';

/// Reusable avatar widget for displaying group members
/// 
/// Supports:
/// - Selection state with visual indicator
/// - Check badge overlay (for selection indication)
/// - Quantity badge overlay (e.g., for quantity)
/// - Customizable size
class MemberAvatarWidget extends StatelessWidget {
  final GroupMember member;
  final bool isSelected;
  final bool showCheckBadge;
  final bool showBadge;
  final String? badgeText;
  final double size;
  final VoidCallback? onTap;

  const MemberAvatarWidget({
    Key? key,
    required this.member,
    this.isSelected = false,
    this.showCheckBadge = false,
    this.showBadge = false,
    this.badgeText,
    this.size = SplitWidgetConstants.avatarSize,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size.w,
        height: size.w,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size.w,
              height: size.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryLight.withOpacity(0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(
                        color: AppTheme.primaryLight,
                        width: 2,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  member.initials,
                  style: TextStyle(
                    fontSize: (size * 1.4).sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppTheme.primaryLight : Colors.grey[600],
                  ),
                ),
              ),
            ),
            // Check badge on top-right (for selection indication)
            if (showCheckBadge && !showBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: SplitWidgetConstants.badgeSize.w,
                  height: SplitWidgetConstants.badgeSize.w,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
            // Quantity badge on top-right (for quantity display)
            if (showBadge && badgeText != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: SplitWidgetConstants.badgeSize.w,
                  height: SplitWidgetConstants.badgeSize.w,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.all(1),
                        child: Text(
                          badgeText!,
                          style: SplitTextStyles.labelSmall(Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

