import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                provider: 'Google',
                onPressed: () => onSocialRegistration('Google'),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _SocialButton(
                provider: 'Apple',
                onPressed: () => onSocialRegistration('Apple'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String provider;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.provider,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: provider == 'Apple' ? Colors.black : Colors.white,
          side: BorderSide(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            SizedBox(width: 2.w),
            Text(
              provider,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: provider == 'Apple' ? Colors.white : AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (provider) {
      case 'Google':
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://developers.google.com/identity/images/g-logo.png',
              ),
              fit: BoxFit.contain,
            ),
          ),
        );
      case 'Apple':
        return SvgPicture.asset(
          'assets/images/apple_logo.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        );
      default:
        return Icon(
          Icons.account_circle,
          size: 20,
          color: AppTheme.lightTheme.colorScheme.onSurface,
        );
    }
  }
} 