import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class SocialRegistrationWidget extends StatelessWidget {
  final Function(String) onSocialRegistration;

  const SocialRegistrationWidget({
    super.key,
    required this.onSocialRegistration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Social Registration Buttons
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                icon: 'assets/icons/google_icon.png',
                label: 'Google',
                onPressed: () => onSocialRegistration('Google'),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _SocialButton(
                icon: 'assets/icons/apple_icon.png',
                label: 'Apple',
                onPressed: () => onSocialRegistration('Apple'),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _SocialButton(
                icon: 'assets/icons/facebook_icon.png',
                label: 'Facebook',
                onPressed: () => onSocialRegistration('Facebook'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 5.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          foregroundColor: AppTheme.lightTheme.colorScheme.onSurface,
          side: BorderSide(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon placeholder (you can replace with actual icons)
            Icon(
              _getIconForLabel(label),
              size: 20.sp,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'google':
        return Icons.g_mobiledata; // Placeholder for Google icon
      case 'apple':
        return Icons.apple; // Placeholder for Apple icon
      case 'facebook':
        return Icons.facebook; // Placeholder for Facebook icon
      default:
        return Icons.account_circle;
    }
  }
} 