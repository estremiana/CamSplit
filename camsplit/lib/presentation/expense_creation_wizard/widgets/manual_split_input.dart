import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import 'split_widget_constants.dart';
import 'split_text_styles.dart';
import 'split_callbacks.dart';

class ManualSplitInput extends StatelessWidget {
  final String memberId;
  final bool isSelected;
  final bool isPercentage;
  final double value;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ManualValueChangedCallback onValueChanged;

  const ManualSplitInput({
    Key? key,
    required this.memberId,
    required this.isSelected,
    required this.isPercentage,
    required this.value,
    this.controller,
    this.focusNode,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayValue = isPercentage ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
    final hasFocus = focusNode?.hasFocus ?? false;
    
    // Only update controller text if value changed externally and field doesn't have focus
    if (controller != null && !hasFocus) {
      final currentText = controller!.text;
      // Only update if the parsed value differs from what's displayed
      final currentValue = double.tryParse(currentText.replaceAll(',', '.')) ?? 0.0;
      final formattedCurrent = isPercentage ? currentValue.toStringAsFixed(0) : currentValue.toStringAsFixed(2);
      if (formattedCurrent != displayValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode?.hasFocus == false) {
            controller!.text = displayValue;
          }
        });
      }
    }
    
    return Container(
      width: 25.w,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: isSelected,
        keyboardType: TextInputType.numberWithOptions(decimal: !isPercentage),
        textAlign: TextAlign.right,
        style: SplitTextStyles.bodyLarge(
          isSelected ? AppTheme.textPrimaryLight : Colors.grey[400]!,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(
            horizontal: SplitWidgetConstants.spacingMedium.w,
            vertical: 0.8.h,
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SplitWidgetConstants.borderRadiusSmall),
            borderSide: BorderSide(
              color: isSelected ? Colors.grey[300]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SplitWidgetConstants.borderRadiusSmall),
            borderSide: BorderSide(
              color: isSelected ? Colors.grey[300]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SplitWidgetConstants.borderRadiusSmall),
            borderSide: BorderSide(
              color: AppTheme.primaryLight,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(SplitWidgetConstants.borderRadiusSmall),
            borderSide: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          suffixText: isPercentage ? '%' : '€',
          suffixStyle: SplitTextStyles.bodySmall(
            isSelected ? Colors.grey[400]! : Colors.grey[300]!,
          ),
        ),
        onChanged: (value) {
          if (isSelected) {
            onValueChanged(memberId, value);
          }
        },
      ),
    );
  }
}

