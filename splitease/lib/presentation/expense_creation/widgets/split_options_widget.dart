import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SplitOptionsWidget extends StatelessWidget {
  final String splitType;
  final Function(String) onSplitTypeChanged;

  const SplitOptionsWidget({
    super.key,
    required this.splitType,
    required this.onSplitTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split Options',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.lightTheme.dividerColor,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Equal Split
              RadioListTile<String>(
                title: Text(
                  'Equal Split',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Divide equally among all members',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  ),
                ),
                value: 'equal',
                groupValue: splitType,
                onChanged: (value) {
                  if (value != null) {
                    onSplitTypeChanged(value);
                  }
                },
                secondary: CustomIconWidget(
                  iconName: 'balance',
                  color: splitType == 'equal'
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.secondary,
                  size: 24,
                ),
              ),

              Divider(
                height: 1,
                color: AppTheme.lightTheme.dividerColor,
              ),

              // Percentage Split
              RadioListTile<String>(
                title: Text(
                  'Percentage Split',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Assign percentages to each member',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  ),
                ),
                value: 'percentage',
                groupValue: splitType,
                onChanged: (value) {
                  if (value != null) {
                    onSplitTypeChanged(value);
                  }
                },
                secondary: CustomIconWidget(
                  iconName: 'percent',
                  color: splitType == 'percentage'
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.secondary,
                  size: 24,
                ),
              ),

              Divider(
                height: 1,
                color: AppTheme.lightTheme.dividerColor,
              ),

              // Custom Split
              RadioListTile<String>(
                title: Text(
                  'Custom Split',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Assign items to specific members',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  ),
                ),
                value: 'custom',
                groupValue: splitType,
                onChanged: (value) {
                  if (value != null) {
                    onSplitTypeChanged(value);
                  }
                },
                secondary: CustomIconWidget(
                  iconName: 'tune',
                  color: splitType == 'custom'
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.secondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        if (splitType == 'custom') ...[
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Items are assigned individually. Tax and tip will be split equally.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
