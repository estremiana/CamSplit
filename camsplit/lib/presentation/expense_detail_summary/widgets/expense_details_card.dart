import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';
import '../../../core/app_export.dart';
import '../../../models/expense_detail_model.dart';
import '../../../models/group_member.dart';

class ExpenseDetailsCard extends StatelessWidget {
  final ExpenseDetailModel expense;
  final bool isEditMode;
  final TextEditingController titleController;
  final TextEditingController amountController;
  final TextEditingController categoryController;
  final DateTime? selectedDate;
  final int? selectedPayerId;
  final List<GroupMember> groupMembers;
  final Function(DateTime) onDateChanged;
  final Function(int?) onPayerChanged;
  final Function(String) onCategoryChanged;

  const ExpenseDetailsCard({
    Key? key,
    required this.expense,
    required this.isEditMode,
    required this.titleController,
    required this.amountController,
    required this.categoryController,
    required this.selectedDate,
    required this.selectedPayerId,
    required this.groupMembers,
    required this.onDateChanged,
    required this.onPayerChanged,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Paid By
          _buildDetailRow(
            icon: Icons.person,
            label: 'PAID BY',
            child: isEditMode
                ? _buildPayerDropdown()
                : Text(
                    _getPayerName(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
          ),
          
          Divider(height: 1, color: AppTheme.lightTheme.dividerColor),
          
          // Date and Category (side by side)
          Row(
            children: [
              Expanded(
                child: _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: 'DATE',
                  child: isEditMode
                      ? _buildDatePicker(context)
                      : Text(
                          _formatDate(expense.date),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: AppTheme.lightTheme.dividerColor,
              ),
              Expanded(
                child: _buildDetailRow(
                  icon: Icons.tag,
                  label: 'CATEGORY',
                  child: isEditMode
                      ? _buildCategoryField()
                      : Text(
                          expense.category,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                ),
              ),
            ],
          ),
          
          Divider(height: 1, color: AppTheme.lightTheme.dividerColor),
          
          // Group (read-only)
          _buildDetailRow(
            icon: Icons.people,
            label: 'GROUP',
            child: Text(
              expense.groupName,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required Widget child,
    Color? backgroundColor,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: backgroundColor,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryLight,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 0.5.h),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayerDropdown() {
    return DropdownButton<int>(
      value: selectedPayerId ?? expense.payerId,
      isExpanded: true,
      underline: SizedBox(),
      items: groupMembers.map((member) {
        return DropdownMenuItem<int>(
          value: member.id,
          child: Text(
            member.nickname,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) => onPayerChanged(value),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? expense.date,
          firstDate: DateTime.now().subtract(Duration(days: 365)),
          lastDate: DateTime.now().add(Duration(days: 30)),
        );
        if (picked != null) {
          onDateChanged(picked);
        }
      },
      child: Text(
        _formatDate(selectedDate ?? expense.date),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return TextField(
      controller: categoryController,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimaryLight,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  String _getPayerName() {
    if (selectedPayerId != null) {
      final member = groupMembers.firstWhere(
        (m) => m.id == selectedPayerId,
        orElse: () => groupMembers.first,
      );
      return member.nickname;
    }
    return expense.payerName;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

