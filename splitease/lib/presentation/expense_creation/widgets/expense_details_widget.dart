import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExpenseDetailsWidget extends StatelessWidget {
  final String selectedGroup;
  final String selectedCategory;
  final DateTime selectedDate;
  final TextEditingController notesController;
  final List<String> groups;
  final List<String> categories;
  final Function(String) onGroupChanged;
  final Function(String) onCategoryChanged;
  final VoidCallback onDateTap;

  const ExpenseDetailsWidget({
    super.key,
    required this.selectedGroup,
    required this.selectedCategory,
    required this.selectedDate,
    required this.notesController,
    required this.groups,
    required this.categories,
    required this.onGroupChanged,
    required this.onCategoryChanged,
    required this.onDateTap,
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
          ),
          items: groups.map<DropdownMenuItem<String>>((String group) {
            return DropdownMenuItem<String>(
              value: group,
              child: Text(group),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onGroupChanged(value);
            }
          },
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
