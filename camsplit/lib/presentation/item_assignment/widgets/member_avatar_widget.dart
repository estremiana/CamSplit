import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MemberAvatarWidget extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const MemberAvatarWidget({
    super.key,
    required this.member,
    required this.isSelected,
    required this.onTap,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    // Debug logging for avatar data
    print('DEBUG: MemberAvatarWidget - Member ${member['name']} has avatar: ${member['avatar']}');
    
    return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: 2.w),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.dividerColor,
                    width: isSelected ? 3 : 2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4)),
                      ]
                    : null),
            child: Stack(children: [
              CircleAvatar(
                  radius: size.w,
                  backgroundColor:
                      AppTheme.lightTheme.colorScheme.primaryContainer,
                  child: ClipOval(
                      child: CustomImageWidget(
                          imageUrl: member['avatar'],
                          fit: BoxFit.cover,
                          width: (size * 2).w,
                          height: (size * 2).w,
                          userName: member['name'],
                      ))),
              if (isSelected)
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.lightTheme.cardColor,
                                width: 2)),
                        child: Icon(Icons.check,
                            color: AppTheme.lightTheme.colorScheme.onPrimary,
                            size: 3.w))),
            ])));
  }
}
