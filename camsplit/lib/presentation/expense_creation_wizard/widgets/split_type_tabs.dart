import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../models/expense_wizard_data.dart';
import 'split_widget_constants.dart';
import 'split_text_styles.dart';

class SplitTypeTabs extends StatelessWidget {
  final SplitType selectedType;
  final Function(SplitType) onTypeChanged;

  const SplitTypeTabs({
    Key? key,
    required this.selectedType,
    required this.onTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SplitWidgetConstants.spacingLarge.w),
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(SplitWidgetConstants.borderRadiusMedium),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton('Equal', SplitType.equal, Icons.equalizer),
            ),
            Expanded(
              child: _buildTabButton('Percentage', SplitType.percentage, Icons.percent),
            ),
            Expanded(
              child: _buildTabButton('Custom', SplitType.custom, Icons.attach_money),
            ),
            Expanded(
              child: _buildTabButton('Items', SplitType.items, Icons.receipt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, SplitType type, IconData icon) {
    final isActive = selectedType == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTypeChanged(type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.2.h),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(SplitWidgetConstants.borderRadiusSmall),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(SplitWidgetConstants.opacityShadow),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: SplitWidgetConstants.iconSizeLarge,
                color: isActive ? AppTheme.primaryLight : AppTheme.textSecondaryLight,
              ),
              SizedBox(width: SplitWidgetConstants.spacingSmall.w),
              Text(
                label,
                style: SplitTextStyles.bodyMedium(
                  isActive ? AppTheme.primaryLight : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

