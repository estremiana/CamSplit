import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const ProgressIndicatorWidget({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          Row(
            children: [
              for (int i = 0; i < totalSteps; i++) ...[
                // Step circle
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < currentStep
                        ? AppTheme.lightTheme.colorScheme.tertiary
                        : i == currentStep
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.outline,
                  ),
                  child: Center(
                    child: i < currentStep
                        ? Icon(
                            Icons.check,
                            color: AppTheme.lightTheme.colorScheme.onTertiary,
                            size: 4.w,
                          )
                        : Text(
                            '${i + 1}',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: i == currentStep
                                  ? AppTheme.lightTheme.colorScheme.onPrimary
                                  : AppTheme.lightTheme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                // Connecting line
                if (i < totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < currentStep
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.colorScheme.outline,
                    ),
                  ),
              ],
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            stepLabels[currentStep],
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
