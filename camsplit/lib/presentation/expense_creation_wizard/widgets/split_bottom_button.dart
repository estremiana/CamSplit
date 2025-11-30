import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../models/expense_wizard_data.dart';
import 'split_widget_constants.dart';
import 'split_text_styles.dart';

class SplitBottomButton extends StatelessWidget {
  final SplitType splitType;
  final double remainingAmount;
  final bool isValid;
  final VoidCallback onSubmit;

  const SplitBottomButton({
    Key? key,
    required this.splitType,
    required this.remainingAmount,
    required this.isValid,
    required this.onSubmit,
  }) : super(key: key);

  bool get _isRemainingValid {
    if (splitType == SplitType.percentage) {
      return remainingAmount.abs() < SplitWidgetConstants.percentageThreshold;
    } else if (splitType == SplitType.custom) {
      return remainingAmount.abs() < SplitWidgetConstants.customThreshold;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: SplitWidgetConstants.spacingMedium.h,
        bottom: SplitWidgetConstants.spacingLarge.w,
        left: SplitWidgetConstants.spacingLarge.w,
        right: SplitWidgetConstants.spacingLarge.w,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Remaining indicator for manual modes
          if (splitType == SplitType.percentage || splitType == SplitType.custom)
            Container(
              margin: EdgeInsets.only(bottom: SplitWidgetConstants.spacingSmall.h),
              padding: EdgeInsets.all(SplitWidgetConstants.spacingMedium.w),
              decoration: BoxDecoration(
                color: _isRemainingValid ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(SplitWidgetConstants.borderRadiusSmall),
              ),
              child: Text(
                splitType == SplitType.percentage
                    ? '${remainingAmount.toStringAsFixed(1)}% remaining'
                    : '€${remainingAmount.toStringAsFixed(2)} remaining',
                style: SplitTextStyles.bodyLarge(
                  _isRemainingValid ? Colors.green[700]! : Colors.red[600]!,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Center(
            child: SizedBox(
              width: SplitWidgetConstants.buttonWidth.w,
              child: ElevatedButton(
                onPressed: isValid ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: SplitWidgetConstants.spacingMedium.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(SplitWidgetConstants.borderRadiusLarge),
                  ),
                  elevation: isValid ? SplitWidgetConstants.buttonElevation : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 18),
                    SizedBox(width: SplitWidgetConstants.spacingMedium.w),
                    Text(
                      'Create Expense',
                      style: SplitTextStyles.bodyLarge(Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

