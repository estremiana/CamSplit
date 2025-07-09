import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ConfidenceIndicatorWidget extends StatelessWidget {
  final double confidence;
  final double size;

  const ConfidenceIndicatorWidget({
    super.key,
    required this.confidence,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    Color getConfidenceColor() {
      if (confidence >= 0.8) {
        return AppTheme.lightTheme.colorScheme.tertiary; // Success green
      } else if (confidence >= 0.6) {
        return AppTheme.warningLight; // Warning amber
      } else {
        return AppTheme.lightTheme.colorScheme.error; // Error red
      }
    }

    IconData getConfidenceIcon() {
      if (confidence >= 0.8) {
        return Icons.check_circle;
      } else if (confidence >= 0.6) {
        return Icons.warning;
      } else {
        return Icons.error;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: getConfidenceColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getConfidenceColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getConfidenceIcon(),
            size: size,
            color: getConfidenceColor(),
          ),
          SizedBox(width: 1.w),
          Text(
            '${(confidence * 100).toInt()}%',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: getConfidenceColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
