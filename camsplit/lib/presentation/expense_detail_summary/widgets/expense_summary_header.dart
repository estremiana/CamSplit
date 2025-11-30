import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class ExpenseSummaryHeader extends StatelessWidget {
  final bool isEditMode;
  final bool isSaving;
  final VoidCallback onEditPressed;
  final VoidCallback onSavePressed;
  final VoidCallback onBackPressed;

  const ExpenseSummaryHeader({
    Key? key,
    required this.isEditMode,
    required this.isSaving,
    required this.onEditPressed,
    required this.onSavePressed,
    required this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Back button
          TextButton(
            onPressed: onBackPressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: AppTheme.textSecondaryLight,
                ),
                SizedBox(width: 0.5.w),
                Text(
                  isEditMode ? 'Cancel' : 'Back',
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          
          // Title
          Text(
            isEditMode ? 'Edit Expense' : 'Expense Details',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          
          // Edit/Save button
          if (isEditMode)
            TextButton(
              onPressed: isSaving ? null : onSavePressed,
              child: Text(
                'Save',
                style: TextStyle(
                  color: isSaving 
                      ? AppTheme.textSecondaryLight 
                      : AppTheme.primaryLight,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            IconButton(
              onPressed: onEditPressed,
              icon: Icon(
                Icons.edit,
                size: 20,
                color: AppTheme.primaryLight,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

