import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import './member_avatar_widget.dart';

class BulkAssignmentWidget extends StatefulWidget {
  final List<Map<String, dynamic>> selectedItems;
  final List<Map<String, dynamic>> members;
  final Function(List<Map<String, dynamic>>) onBulkAssignmentChanged;
  final VoidCallback onClose;

  const BulkAssignmentWidget({
    super.key,
    required this.selectedItems,
    required this.members,
    required this.onBulkAssignmentChanged,
    required this.onClose,
  });

  @override
  State<BulkAssignmentWidget> createState() => _BulkAssignmentWidgetState();
}

class _BulkAssignmentWidgetState extends State<BulkAssignmentWidget> {
  final List<String> _selectedMembers = [];
  String _assignmentType = 'equal'; // 'equal' or 'percentage'
  final Map<String, double> _memberPercentages = {};

  @override
  void initState() {
    super.initState();
    // Initialize percentages
    for (var member in widget.members) {
      _memberPercentages[member['id'].toString()] = 0.0;
    }
  }

  void _toggleMemberSelection(String memberId) {
    setState(() {
      if (_selectedMembers.contains(memberId)) {
        _selectedMembers.remove(memberId);
        _memberPercentages[memberId] = 0.0;
      } else {
        _selectedMembers.add(memberId);
        if (_assignmentType == 'equal') {
          _updateEqualPercentages();
        }
      }
    });
  }

  void _updateEqualPercentages() {
    if (_selectedMembers.isEmpty) return;

    final equalPercentage = 100.0 / _selectedMembers.length;
    setState(() {
      for (var member in widget.members) {
        final memberId = member['id'].toString();
        if (_selectedMembers.contains(memberId)) {
          _memberPercentages[memberId] = equalPercentage;
        } else {
          _memberPercentages[memberId] = 0.0;
        }
      }
    });
  }

  void _updatePercentage(String memberId, double percentage) {
    setState(() {
      _memberPercentages[memberId] = percentage;
    });
  }

  double _getTotalPercentage() {
    return _memberPercentages.values
        .fold(0.0, (sum, percentage) => sum + percentage);
  }

  void _applyBulkAssignment() {
    if (_selectedMembers.isEmpty) return;

    List<Map<String, dynamic>> updatedItems = [];

    for (var item in widget.selectedItems) {
      final updatedItem = Map<String, dynamic>.from(item);

      if (_assignmentType == 'equal') {
        updatedItem['assignedMembers'] = List<String>.from(_selectedMembers);
      } else {
        // For percentage assignment, only include members with non-zero percentages
        updatedItem['assignedMembers'] = _memberPercentages.entries
            .where((entry) => entry.value > 0)
            .map((entry) => entry.key)
            .toList();
        updatedItem['memberPercentages'] =
            Map<String, double>.from(_memberPercentages);
      }

      updatedItems.add(updatedItem);
    }

    widget.onBulkAssignmentChanged(updatedItems);
    widget.onClose();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final totalPercentage = _getTotalPercentage();
    final isValid = _selectedMembers.isNotEmpty &&
        (_assignmentType == 'equal' ||
            (totalPercentage >= 99.0 && totalPercentage <= 100.0));

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bulk Assignment',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            Text(
              '${widget.selectedItems.length} items selected',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.secondary,
              ),
            ),

            SizedBox(height: 3.h),

            // Assignment type selector
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Equal Split'),
                    value: 'equal',
                    groupValue: _assignmentType,
                    onChanged: (value) {
                      setState(() {
                        _assignmentType = value!;
                        if (value == 'equal') {
                          _updateEqualPercentages();
                        }
                      });
                    },
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Custom %'),
                    value: 'percentage',
                    groupValue: _assignmentType,
                    onChanged: (value) {
                      setState(() {
                        _assignmentType = value!;
                      });
                    },
                    dense: true,
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Member selection
            Text(
              'Select members:',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),

            // Members list
            SizedBox(
              height: 35.h,
              child: ListView.builder(
                itemCount: widget.members.length,
                itemBuilder: (context, index) {
                  final member = widget.members[index];
                  final memberId = member['id'].toString();
                  final isSelected = _selectedMembers.contains(memberId);
                  final memberPercentage = _memberPercentages[memberId] ?? 0.0;

                  return Container(
                    margin: EdgeInsets.only(bottom: 1.h),
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primaryContainer
                          : AppTheme
                              .lightTheme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            MemberAvatarWidget(
                              member: member,
                              isSelected: isSelected,
                              onTap: () => _toggleMemberSelection(memberId),
                              size: 6.0,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                member['name'],
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_assignmentType == 'percentage' && isSelected)
                              Container(
                                width: 20.w,
                                child: TextFormField(
                                  initialValue:
                                      memberPercentage.toStringAsFixed(1),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    suffixText: '%',
                                    isDense: true,
                                  ),
                                  onChanged: (value) {
                                    final percentage =
                                        double.tryParse(value) ?? 0.0;
                                    _updatePercentage(memberId, percentage);
                                  },
                                ),
                              ),
                          ],
                        ),
                        if (_assignmentType == 'percentage' && isSelected)
                          Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Slider(
                              value: memberPercentage,
                              min: 0.0,
                              max: 100.0,
                              divisions: 100,
                              onChanged: (value) {
                                _updatePercentage(memberId, value);
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Percentage validation
            if (_assignmentType == 'percentage')
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: totalPercentage == 100.0
                      ? AppTheme.lightTheme.colorScheme.tertiaryContainer
                      : AppTheme.lightTheme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Percentage:',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${totalPercentage.toStringAsFixed(1)}%',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: totalPercentage == 100.0
                            ? AppTheme
                                .lightTheme.colorScheme.onTertiaryContainer
                            : AppTheme.lightTheme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 3.h),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isValid ? _applyBulkAssignment : null,
                    child: const Text('Apply Assignment'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
