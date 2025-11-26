import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../services/currency_service.dart';

class ExpenseWizardStepDetails extends StatefulWidget {
  final List<Group> groups;
  final List<Map<String, dynamic>> groupMembers;
  final String? selectedGroupId;
  final String? selectedPayerId;
  final DateTime selectedDate;
  final String selectedCategory;
  final bool isLoadingGroups;
  final Function(Map<String, dynamic>) onDetailsChanged;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const ExpenseWizardStepDetails({
    super.key,
    required this.groups,
    required this.groupMembers,
    this.selectedGroupId,
    this.selectedPayerId,
    required this.selectedDate,
    required this.selectedCategory,
    required this.isLoadingGroups,
    required this.onDetailsChanged,
    this.onNext,
    this.onBack,
  });

  @override
  State<ExpenseWizardStepDetails> createState() => _ExpenseWizardStepDetailsState();
}

class _ExpenseWizardStepDetailsState extends State<ExpenseWizardStepDetails> {
  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Healthcare',
    'Other'
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != widget.selectedDate) {
      widget.onDetailsChanged({'date': picked});
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selectedGroup = widget.groups.firstWhere(
      (g) => g.id.toString() == widget.selectedGroupId,
      orElse: () => widget.groups.isNotEmpty ? widget.groups.first : Group(
        id: 0,
        name: '',
        currency: CamSplitCurrencyService.getDefaultCurrency(),
        description: '',
        createdBy: 0,
        members: [],
        lastUsed: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final selectedPayer = widget.groupMembers.firstWhere(
      (m) => m['id'].toString() == widget.selectedPayerId,
      orElse: () => widget.groupMembers.isNotEmpty 
          ? Map<String, Object>.from(widget.groupMembers.first)
          : <String, Object>{'id': '', 'name': 'Unknown', 'avatar': '?'},
    );

    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: widget.onBack,
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                  ),
                ),
              ),
              Text(
                '2 of 3',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  color: Colors.grey[900],
                ),
              ),
              TextButton(
                onPressed: widget.onNext,
                child: Text(
                  'Next',
                  style: TextStyle(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'The Details',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
          ),

          SizedBox(height: 4.h),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Selector
                  _buildSection(
                    label: 'GROUP',
                    child: GestureDetector(
                      onTap: () async {
                        if (widget.isLoadingGroups) return;
                        
                        final selected = await showDialog<Group>(
                          context: context,
                          builder: (context) => _GroupSelectorDialog(groups: widget.groups),
                        );
                        
                        if (selected != null) {
                          widget.onDetailsChanged({'groupId': selected.id.toString()});
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.people,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedGroup.name.isNotEmpty ? selectedGroup.name : 'Select Group',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                  if (selectedGroup.name.isNotEmpty)
                                    Text(
                                      '${widget.groupMembers.length} Members',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Payer Selector
                  _buildSection(
                    label: 'WHO PAID?',
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButton<String>(
                        value: widget.selectedPayerId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                        items: widget.groupMembers.map((member) {
                          return DropdownMenuItem<String>(
                            value: member['id'].toString(),
                            child: Row(
                              children: [
                                Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: AppTheme.lightTheme.primaryColor,
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  member['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            widget.onDetailsChanged({'payerId': value});
                          }
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Date and Category Row
                  Row(
                    children: [
                      // Date
                      Expanded(
                        child: _buildSection(
                          label: 'DATE',
                          child: GestureDetector(
                            onTap: _selectDate,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.grey[400],
                                    size: 18,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    _formatDate(widget.selectedDate),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 3.w),

                      // Category
                      Expanded(
                        child: _buildSection(
                          label: 'CATEGORY',
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButton<String>(
                              value: widget.selectedCategory,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                              items: _categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.label,
                                        color: Colors.grey[400],
                                        size: 18,
                                      ),
                                      SizedBox(width: 3.w),
                                      Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  widget.onDetailsChanged({'category': value});
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 1.w, bottom: 1.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _GroupSelectorDialog extends StatelessWidget {
  final List<Group> groups;

  const _GroupSelectorDialog({required this.groups});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 60.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Select Group',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ListTile(
                    leading: Icon(Icons.people, color: AppTheme.lightTheme.primaryColor),
                    title: Text(group.name),
                    onTap: () => Navigator.pop(context, group),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

