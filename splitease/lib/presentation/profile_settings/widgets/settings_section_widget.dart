import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsSectionWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> settings;

  const SettingsSectionWidget({
    super.key,
    required this.title,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
          child: Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: AppTheme.borderLight.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Column(
            children: settings.asMap().entries.map((entry) {
              final index = entry.key;
              final setting = entry.value;
              final isLast = index == settings.length - 1;

              return _buildSettingItem(setting, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(Map<String, dynamic> setting, bool isLast) {
    final String title = setting['title'] as String;
    final String? subtitle = setting['subtitle'] as String?;
    final String type = setting['type'] as String;
    final dynamic value = setting['value'];
    final VoidCallback? onTap = setting['onTap'] as VoidCallback?;
    final Function(bool)? onChanged = setting['onChanged'] as Function(bool)?;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppTheme.borderLight.withValues(alpha: 0.3),
                  width: 1.0,
                ),
              ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        title: Text(
          title,
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryLight,
                ),
              )
            : null,
        trailing: _buildTrailing(type, value, onChanged),
        onTap: type == 'navigation' ? onTap : null,
      ),
    );
  }

  Widget _buildTrailing(String type, dynamic value, Function(bool)? onChanged) {
    switch (type) {
      case 'toggle':
        return Switch(
          value: value as bool,
          onChanged: onChanged,
          activeColor: AppTheme.lightTheme.primaryColor,
          inactiveThumbColor: AppTheme.textSecondaryLight,
          inactiveTrackColor: AppTheme.borderLight,
        );

      case 'navigation':
        return CustomIconWidget(
          iconName: 'chevron_right',
          color: AppTheme.textSecondaryLight,
          size: 20,
        );

      case 'info':
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }
}
