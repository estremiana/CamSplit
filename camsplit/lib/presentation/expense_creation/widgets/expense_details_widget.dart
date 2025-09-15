import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/receipt_mode_config.dart';

import 'package:currency_picker/currency_picker.dart';
import '../../../widgets/currency_selection_widget.dart';

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
  final bool isLoadingGroups; // Add loading state parameter
  // Payer selection parameters
  final String selectedPayerId;
  final Function(String)? onPayerChanged;
  final List<Map<String, dynamic>> groupMembers;
  final bool isLoadingPayers;
  // Title field and group visibility parameters
  final bool showGroupField;
  final TextEditingController titleController;
  final Function(String)? onTitleChanged;

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
    this.isLoadingGroups = false, // Add loading state parameter
    // Payer selection parameters with defaults
    this.selectedPayerId = '',
    this.onPayerChanged,
    this.groupMembers = const [],
    this.isLoadingPayers = false,
    // Title field and group visibility parameters
    this.showGroupField = true,
    required this.titleController,
    this.onTitleChanged,
  });

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  // Helper methods for payer dropdown edge case handling
  bool _shouldDisablePayerDropdown() {
    return isReadOnly || selectedGroup.isEmpty || (groupMembers.isEmpty && !isLoadingPayers);
  }

  bool _canChangePayerSelection() {
    return !isReadOnly && 
           onPayerChanged != null && 
           groupMembers.isNotEmpty && 
           !isLoadingPayers && 
           selectedGroup.isNotEmpty;
  }

  String _getPayerDropdownHint() {
    if (selectedGroup.isEmpty) {
      return 'Select a group first';
    }
    if (isLoadingPayers) {
      return 'Loading members...';
    }
    if (groupMembers.isEmpty) {
      return 'No members available';
    }
    return 'Select who paid';
  }

  Color _getPayerDropdownIconColor() {
    if (isReadOnly || selectedGroup.isEmpty) {
      return AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.6);
    }
    return AppTheme.lightTheme.colorScheme.secondary;
  }

  Widget? _getPayerDropdownSuffixIcon() {
    if (isReadOnly) {
      return Icon(
        Icons.lock_outline,
        color: AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.6),
        size: 16,
      );
    }
    if (selectedGroup.isEmpty) {
      return Icon(
        Icons.group_off,
        color: AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.6),
        size: 16,
      );
    }
    if (groupMembers.isEmpty && !isLoadingPayers) {
      return Icon(
        Icons.person_off,
        color: AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.6),
        size: 16,
      );
    }
    return null;
  }

  // Receipt mode specific styling helpers for payer dropdown
  bool _isPayerDropdownDisabledInReceiptMode() {
    // In receipt mode, payer selection should remain editable
    // This follows the requirement that payer selection works in receipt mode
    return false;
  }

  Color _getPayerDropdownFillColor() {
    if (_shouldDisablePayerDropdown()) {
      return AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5);
    }
    // In receipt mode, maintain normal styling since payer selection is allowed
    return Colors.transparent;
  }

  TextStyle? _getPayerDropdownTextStyle() {
    if (_shouldDisablePayerDropdown()) {
      return TextStyle(color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6));
    }
    // In receipt mode, maintain normal text styling
    return null;
  }

  List<DropdownMenuItem<String>>? _getPayerDropdownItems() {
    if (groupMembers.isEmpty) {
      return [];
    }
    
    return groupMembers.where((member) => 
      member['id'] != null && 
      member['id'].toString().isNotEmpty &&
      member['name'] != null && 
      member['name'].toString().isNotEmpty
    ).map<DropdownMenuItem<String>>((member) {
              final memberId = member['id']?.toString() ?? '';
        final memberName = member['name']?.toString() ?? 'Unknown';
        final initials = member['initials']?.toString() ?? 
                        (memberName.isNotEmpty ? memberName.substring(0, 1).toUpperCase() : '?');
        
        return DropdownMenuItem<String>(
          value: memberId,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  memberName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
    }).toList();
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

        // Title Field
        TextFormField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: isReadOnly ? null : 'Enter expense title...',
            prefixIcon: CustomIconWidget(
              iconName: 'title',
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
            fillColor: isReadOnly 
                ? AppTheme.lightTheme.colorScheme.surface.withOpacity(0.5)
                : null,
            filled: isReadOnly,
          ),
          style: isReadOnly 
              ? TextStyle(color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6))
              : null,
          enabled: !isReadOnly,
          readOnly: isReadOnly,
          onChanged: onTitleChanged,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title for this expense';
            }
            if (value.trim().length > 100) {
              return 'Title must be 100 characters or less';
            }
            return null;
          },
          autovalidateMode: AutovalidateMode.disabled,
        ),

        SizedBox(height: 2.h),

        // Group Selector
        if (showGroupField)
        DropdownButtonFormField<String>(
          value: selectedGroup.isNotEmpty ? selectedGroup : null,
          decoration: InputDecoration(
            labelText: 'Group',
            prefixIcon: isLoadingGroups 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  )
                : CustomIconWidget(
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
          items: groups.isNotEmpty ? groups.map<DropdownMenuItem<String>>((String group) {
            return DropdownMenuItem<String>(
              value: group,
              child: Text(group),
            );
          }).toList() : null,
          onChanged: (!isReadOnly && (receiptModeConfig?.isGroupEditable ?? true) && onGroupChanged != null && groups.isNotEmpty && !isLoadingGroups)
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

        if (showGroupField)
        SizedBox(height: 2.h),

        // Payer Selector
        DropdownButtonFormField<String>(
          value: (selectedPayerId.isNotEmpty && groupMembers.isNotEmpty && _getPayerDropdownItems()?.isNotEmpty == true) ? selectedPayerId : null,
          decoration: InputDecoration(
            labelText: 'Who Paid',
            hintText: _getPayerDropdownHint(),
            prefixIcon: isLoadingPayers 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  )
                : CustomIconWidget(
                    iconName: 'person',
                    color: _getPayerDropdownIconColor(),
                    size: 20,
                  ),
            suffixIcon: _getPayerDropdownSuffixIcon(),
            // Apply consistent styling with receipt mode patterns
            fillColor: _getPayerDropdownFillColor(),
            filled: _shouldDisablePayerDropdown(),
          ),
          style: _getPayerDropdownTextStyle(),
          items: _getPayerDropdownItems() ?? [],
          onChanged: _canChangePayerSelection() ? (value) {
            if (value != null) {
              onPayerChanged!(value);
            }
          } : null,
          validator: (value) {
            // Comprehensive payer selection validation following existing patterns
            if (selectedGroup.isEmpty) {
              return 'Please select a group first';
            }
            
            // Check for loading state - don't show error during loading
            if (isLoadingPayers) {
              return null; // Allow validation to pass during loading
            }
            
            if (groupMembers.isEmpty) {
              return 'No members available in selected group';
            }
            
            if (value == null || value.isEmpty) {
              return 'Please select who paid for this expense';
            }
            
            // Validate that selected payer exists in group members
            final payerExists = groupMembers.any((member) => member['id'].toString() == value);
            if (!payerExists) {
              return 'Selected payer is not a valid group member';
            }
            
            return null;
          },
          // Disable auto-validation to prevent premature validation errors
          autovalidateMode: AutovalidateMode.disabled,
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
                autovalidateMode: AutovalidateMode.disabled,
              ),
            ),
            SizedBox(width: 2.w),
            CurrencySelectionWidget(
              selectedCurrency: currency,
              onCurrencySelected: onCurrencyChanged ?? (Currency currency) {},
              isCompact: true,
              width: 80,
              isEnabled: !isReadOnly && (receiptModeConfig?.isTotalEditable ?? true),
              isReadOnly: isReadOnly || (receiptModeConfig != null && !receiptModeConfig!.isTotalEditable && isReceiptMode),
              showFlag: false,
              showCurrencyName: false,
              showCurrencyCode: true, // Must be true to satisfy currency_picker assertion
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
