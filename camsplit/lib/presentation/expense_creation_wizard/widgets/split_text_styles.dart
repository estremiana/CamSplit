import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import 'split_widget_constants.dart';

/// Reusable text styles for split-related widgets
class SplitTextStyles {
  // Label styles (uppercase, bold, letter spacing)
  static TextStyle labelXSmall(Color color) => TextStyle(
        fontSize: SplitWidgetConstants.textSizeXSmall.sp,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle labelSmall(Color color) => TextStyle(
        fontSize: SplitWidgetConstants.textSizeSmall.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: color,
      );

  static TextStyle labelMedium(Color color) => TextStyle(
        fontSize: SplitWidgetConstants.textSizeMedium.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: color,
      );
  
  static TextStyle labelLarge(Color color) => TextStyle(
        fontSize: SplitWidgetConstants.textSizeLarge.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: color,
      );

  // Body text styles
  static TextStyle bodySmall(Color color) => TextStyle(
        fontSize: SplitWidgetConstants.textSizeSmall.sp,
        color: color,
      );

  static TextStyle bodyMedium(Color color) => TextStyle(
        fontSize: SplitWidgetConstants.textSizeBody.sp,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLarge(Color color) => TextStyle(
        fontSize: SplitWidgetConstants.textSizeLarge.sp,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyXLarge(Color color) => TextStyle(
        fontSize: SplitWidgetConstants.textSizeXLarge.sp,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Title styles
  static TextStyle titleMedium(Color color) => TextStyle(
        fontSize: SplitWidgetConstants.textSizeXLarge.sp,
        fontWeight: FontWeight.bold,
        color: color,
      );

  // Status styles
  static TextStyle statusSuccess(Color color) => TextStyle(
        fontSize: SplitWidgetConstants.textSizeBody.sp,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Helper methods for common color combinations
  static TextStyle labelSecondary() => labelSmall(AppTheme.textSecondaryLight);
  static TextStyle bodyPrimary() => bodyLarge(AppTheme.textPrimaryLight);
  static TextStyle bodySecondary() => bodyMedium(AppTheme.textSecondaryLight);
  static TextStyle statusPrimary() => statusSuccess(AppTheme.primaryLight);
}

