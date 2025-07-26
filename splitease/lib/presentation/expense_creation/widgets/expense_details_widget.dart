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
  final Function(String) onCategoryChanged;
  final VoidCallback onDateTap;
  // Add these new parameters
  final TextEditingController totalController;
  final Currency currency;
  final Function(Currency?) onCurrencyChanged;
  final String mode;
  // Receipt mode parameters
  final bool isReceiptMode;
  final ReceiptModeConfig receiptModeConfig;

  const ExpenseDetailsWidget({
    super.key,
    required this.selectedGroup,
    required this.selectedCategory,
    required this.selectedDate,
    required this.notesController,
    required this.groups,
    required this.categories,
    this.onGroupChanged,
    required this.onCategoryChanged,
    required this.onDateTap,
    required this.totalController,
    required this.currency,
    required this.onCurrencyChanged,
    required this.mode,
    this.isReceiptMode = false,
    this.receiptModeConfig = ReceiptModeConfig.manualMode,
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
              color: AppTheme.lightTheme.colorScheme.secondary,
              size: 20,
            ),
            // Add visual indicator for disabled state
            suffixIcon: !receiptModeConfig.isGroupEditable && isReceiptMode
                ? Icon(
                    Icons.lock_outline,
                    color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6),
                    size: 16,
                  )
                : null,
          ),
          items: groups.map<DropdownMenuItem<String>>((String group) {
            return DropdownMenuItem<String>(
              value: group,
              child: Text(group),
            );
          }).toList(),
          onChanged: receiptModeConfig.isGroupEditable && onGroupChanged != null
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
              color: AppTheme.lightTheme.colorScheme.secondary,
              size: 20,
            ),
          ),
          items: categories.map<DropdownMenuItem<String>>((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onCategoryChanged(value);
            }
          },
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
          onTap: onDateTap,
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Date',
                hintText: _formatDate(selectedDate),
                prefixIcon: CustomIconWidget(
                  iconName: 'calendar_today',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 20,
                ),
                suffixIcon: CustomIconWidget(
                  iconName: 'arrow_drop_down',
                  color: AppTheme.lightTheme.colorScheme.secondary,
                  size: 20,
                ),
              ),
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
                  hintText: '0.00',
                  prefixIcon: CustomIconWidget(
                    iconName: 'payments',
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    size: 20,
                  ),
                  // Add visual indicator for disabled state
                  suffixIcon: !receiptModeConfig.isTotalEditable && isReceiptMode
                      ? Icon(
                          Icons.lock_outline,
                          color: AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.6),
                          size: 16,
                        )
                      : null,
                ),
                enabled: receiptModeConfig.isTotalEditable,
                readOnly: !receiptModeConfig.isTotalEditable,
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
                onTap: receiptModeConfig.isTotalEditable
                    ? () {
                        showCurrencyPicker(
                          context: context,
                          showFlag: true,
                          showCurrencyName: true,
                          showCurrencyCode: true,
                          onSelect: (Currency currencyObj) {
                            onCurrencyChanged(currencyObj);
                          },
                        );
                      }
                    : null,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      suffixIcon: receiptModeConfig.isTotalEditable
                          ? CustomIconWidget(
                              iconName: 'arrow_drop_down',
                              color: AppTheme.lightTheme.colorScheme.secondary,
                              size: 20,
                            )
                          : Icon(
                              Icons.lock_outline,
                              color: AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.6),
                              size: 16,
                            ),
                    ),
                    controller: TextEditingController(text: currency.symbol),
                    enabled: receiptModeConfig.isTotalEditable,
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
          decoration: InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Add any additional details...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: CustomIconWidget(
                iconName: 'note',
                color: AppTheme.lightTheme.colorScheme.secondary,
                size: 20,
              ),
            ),
            alignLabelWithHint: true,
          ),
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }
}
