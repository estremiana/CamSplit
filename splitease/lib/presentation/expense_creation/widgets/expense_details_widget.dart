import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/receipt_mode_config.dart';
import 'group_dropdown_widget.dart';
import 'package:currency_picker/currency_picker.dart';

class ExpenseDetailsWidget extends StatelessWidget {
  final String selectedGroup;
  final String selectedCategory;
  final DateTime selectedDate;
  final TextEditingController notesController;
  final List<String> groups;
  final List<String> categories;
  final Function(String)? onGroupChanged;
  final Function(String)? onCategoryChanged;
  final VoidCallback? onDateTap;
  // Add these new parameters
  final TextEditingController totalController;
  final Currency? currency;
  final Function(Currency?)? onCurrencyChanged;
  final String mode;
  // Receipt mode parameters
  final bool isReceiptMode;
  final ReceiptModeConfig? receiptModeConfig;
  final bool isReadOnly;

  const ExpenseDetailsWidget({
    super.key,
    required this.selectedGroup,
    required this.selectedCategory,
    required this.selectedDate,
    required this.notesController,
    required this.groups,
    required this.categories,
    this.onGroupChanged,
    this.onCategoryChanged,
    this.onDateTap,
    required this.totalController,
    this.currency,
    this.onCurrencyChanged,
    required this.mode,
    this.isReceiptMode = false,
    this.receiptModeConfig,
    this.isReadOnly = false,
  });

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Details',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),

        // Group Selector
        DropdownButtonFormField<String>(
          value: selectedGroup,
          decoration: InputDecoration(
            labelText: 'Group',
            prefixIcon: CustomIconWidget(
              iconName: 'group',
              color: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isGroupEditable && isReceiptMode))
                  ? AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6)
                  : AppTheme.lightTheme.colorScheme.secondary,
              size: 20,
            ),
            // Add visual indicator for disabled state
            suffixIcon: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isGroupEditable && isReceiptMode))
                ? Icon(
                    Icons.lock_outline,
                    color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6),
                    size: 16,
                  )
                : null,
            // Apply disabled styling when read-only
            fillColor: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isGroupEditable && isReceiptMode))
                ? AppTheme.lightTheme.colorScheme.surface.withOpacity(0.5)
                : null,
            filled: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isGroupEditable && isReceiptMode)),
          ),
          style: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isGroupEditable && isReceiptMode))
              ? TextStyle(color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6))
              : null,
          items: groups.map<DropdownMenuItem<String>>((String group) {
            return DropdownMenuItem<String>(
              value: group,
              child: Text(group),
            );
          }).toList(),
          onChanged: (!isReadOnly && (receiptModeConfig?.isGroupEditable ?? true) && onGroupChanged != null)
              ? (value) {
                  if (value != null) {
                    onGroupChanged!(value);
                  }
                }
              : null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a group';
            }
            return null;
          },
        ),

        SizedBox(height: 2.h),

        // Category Selector
        DropdownButtonFormField<String>(
          value: selectedCategory,
          decoration: InputDecoration(
            labelText: 'Category',
            prefixIcon: CustomIconWidget(
              iconName: 'category',
              color: isReadOnly 
                  ? AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6)
                  : AppTheme.lightTheme.colorScheme.secondary,
              size: 20,
            ),
            suffixIcon: isReadOnly
                ? Icon(
                    Icons.lock_outline,
                    color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6),
                    size: 16,
                  )
                : null,
            // Apply disabled styling when read-only
            fillColor: isReadOnly 
                ? AppTheme.lightTheme.colorScheme.surface.withOpacity(0.5)
                : null,
            filled: isReadOnly,
          ),
          style: isReadOnly 
              ? TextStyle(color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6))
              : null,
          items: categories.map<DropdownMenuItem<String>>((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (!isReadOnly && onCategoryChanged != null) ? (value) {
            if (value != null) {
              onCategoryChanged!(value);
            }
          } : null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),

        SizedBox(height: 2.h),

        // Date Field
        GestureDetector(
          onTap: !isReadOnly && onDateTap != null ? onDateTap : null,
          child: AbsorbPointer(
            child: TextFormField(
              enabled: !isReadOnly,
              decoration: InputDecoration(
                labelText: 'Date',
                hintText: _formatDate(selectedDate),
                prefixIcon: CustomIconWidget(
                  iconName: 'calendar_today',
                  color: isReadOnly 
                      ? AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6)
                      : AppTheme.lightTheme.colorScheme.secondary,
                  size: 20,
                ),
                suffixIcon: isReadOnly
                    ? Icon(
                        Icons.lock_outline,
                        color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6),
                        size: 16,
                      )
                    : CustomIconWidget(
                        iconName: 'arrow_drop_down',
                        color: AppTheme.lightTheme.colorScheme.secondary,
                        size: 20,
                      ),
                // Apply disabled styling when read-only
                fillColor: isReadOnly 
                    ? AppTheme.lightTheme.colorScheme.surface.withOpacity(0.5)
                    : null,
                filled: isReadOnly,
              ),
              style: isReadOnly 
                  ? TextStyle(color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6))
                  : null,
              controller:
                  TextEditingController(text: _formatDate(selectedDate)),
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Total + Currency Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: totalController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Total',
                  hintText: isReadOnly ? null : '0.00',
                  prefixIcon: CustomIconWidget(
                    iconName: 'payments',
                    color: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isTotalEditable && isReceiptMode))
                        ? AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6)
                        : AppTheme.lightTheme.colorScheme.secondary,
                    size: 20,
                  ),
                  // Add visual indicator for disabled state
                  suffixIcon: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isTotalEditable && isReceiptMode))
                      ? Icon(
                          Icons.lock_outline,
                          color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6),
                          size: 16,
                        )
                      : null,
                  // Apply disabled styling when read-only
                  fillColor: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isTotalEditable && isReceiptMode))
                      ? AppTheme.lightTheme.colorScheme.surface.withOpacity(0.5)
                      : null,
                  filled: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isTotalEditable && isReceiptMode)),
                ),
                style: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isTotalEditable && isReceiptMode))
                    ? TextStyle(color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6))
                    : null,
                enabled: !isReadOnly && (receiptModeConfig?.isTotalEditable ?? true),
                readOnly: isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isTotalEditable),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a total amount';
                  }
                  final double? total = double.tryParse(value);
                  if (total == null || total < 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
            ),
            SizedBox(width: 2.w),
            SizedBox(
              width: 80,
              child: GestureDetector(
                onTap: (!isReadOnly && (receiptModeConfig?.isTotalEditable ?? true) && onCurrencyChanged != null)
                    ? () {
                        showCurrencyPicker(
                          context: context,
                          showFlag: true,
                          showCurrencyName: true,
                          showCurrencyCode: true,
                          onSelect: (Currency currencyObj) {
                            onCurrencyChanged!(currencyObj);
                          },
                        );
                      }
                    : null,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      suffixIcon: (!isReadOnly && (receiptModeConfig?.isTotalEditable ?? true))
                          ? CustomIconWidget(
                              iconName: 'arrow_drop_down',
                              color: AppTheme.lightTheme.colorScheme.secondary,
                              size: 20,
                            )
                          : Icon(
                              Icons.lock_outline,
                              color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6),
                              size: 16,
                            ),
                      // Apply disabled styling when read-only
                      fillColor: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isTotalEditable && isReceiptMode))
                          ? AppTheme.lightTheme.colorScheme.surface.withOpacity(0.5)
                          : null,
                      filled: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isTotalEditable && isReceiptMode)),
                    ),
                    style: (isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isTotalEditable && isReceiptMode))
                        ? TextStyle(color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6))
                        : null,
                    controller: TextEditingController(text: currency?.symbol ?? 'EUR'),
                    enabled: !isReadOnly && (receiptModeConfig?.isTotalEditable ?? true),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Notes Field
        TextFormField(
          controller: notesController,
          maxLines: 3,
          readOnly: isReadOnly,
          enabled: !isReadOnly,
          decoration: InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: isReadOnly ? null : 'Add any additional details...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: CustomIconWidget(
                iconName: 'note',
                color: isReadOnly 
                    ? AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6)
                    : AppTheme.lightTheme.colorScheme.secondary,
                size: 20,
              ),
            ),
            suffixIcon: isReadOnly
                ? Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Icon(
                      Icons.lock_outline,
                      color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6),
                      size: 16,
                    ),
                  )
                : null,
            alignLabelWithHint: true,
            // Apply disabled styling when read-only
            fillColor: isReadOnly 
                ? AppTheme.lightTheme.colorScheme.surface.withOpacity(0.5)
                : null,
            filled: isReadOnly,
          ),
          style: isReadOnly 
              ? TextStyle(color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6))
              : null,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }
}
