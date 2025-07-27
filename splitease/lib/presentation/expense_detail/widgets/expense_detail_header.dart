import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class ExpenseDetailHeader extends StatelessWidget {
  final bool isEditMode;
  final bool isSaving;
  final VoidCallback onEditPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onCancelPressed;
  final VoidCallback onBackPressed;

  const ExpenseDetailHeader({
    Key? key,
    required this.isEditMode,
    required this.isSaving,
    required this.onEditPressed,
    required this.onSavePressed,
    required this.onCancelPressed,
    required this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.lightTheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Back/Cancel button
          TextButton(
            onPressed: isEditMode ? onCancelPressed : onBackPressed,
            child: Text(
              isEditMode ? 'Cancel' : 'Back',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.secondary,
              ),
            ),
          ),

          // Center - Title
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Expense Detail',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Right side - Edit/Save button
          if (isEditMode)
            TextButton(
              onPressed: isSaving ? null : onSavePressed,
              child: isSaving
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    )
                  : Text(
                      'Save',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            )
          else
            TextButton(
              onPressed: onEditPressed,
              child: Text(
                'Edit',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}