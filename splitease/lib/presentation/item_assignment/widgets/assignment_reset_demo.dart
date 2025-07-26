import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/group.dart';
import '../../../services/group_service.dart';
import 'group_selection_widget.dart';

/// Demo widget to test assignment reset functionality
class AssignmentResetDemo extends StatefulWidget {
  const AssignmentResetDemo({super.key});

  @override
  State<AssignmentResetDemo> createState() => _AssignmentResetDemoState();
}

class _AssignmentResetDemoState extends State<AssignmentResetDemo> {
  List<Group> _availableGroups = [];
  String? _selectedGroupId;
  List<Map<String, dynamic>> _assignments = [];
  String _statusMessage = 'No assignments yet';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    try {
      // TODO: Load groups via service layer (will be replaced with actual API call)
      final groups = await GroupService.getAllGroups();
      
      setState(() {
        _availableGroups = groups;
        if (_availableGroups.isNotEmpty) {
          _selectedGroupId = _availableGroups.first.id;
        }
      });
    } catch (e) {
      // Handle error loading groups
      setState(() {
        _availableGroups = [];
        _selectedGroupId = null;
      });
    }
  }

  bool _hasExistingAssignments() {
    return _assignments.isNotEmpty;
  }

  void _addAssignment() {
    setState(() {
      _assignments.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'itemName': 'Test Item ${_assignments.length + 1}',
        'amount': 10.0,
        'assignedTo': 'User ${_assignments.length + 1}',
      });
      _statusMessage = 'Added assignment ${_assignments.length}';
    });
  }

  void _clearAssignments() {
    setState(() {
      _assignments.clear();
      _statusMessage = 'All assignments cleared';
    });
  }

  void _onGroupChanged(String groupId) {
    final selectedGroup = _availableGroups.firstWhere(
      (group) => group.id == groupId,
      orElse: () => _availableGroups.first,
    );

    setState(() {
      _selectedGroupId = groupId;
      // Clear assignments when group changes (implements requirement 3.3)
      _assignments.clear();
      _statusMessage = 'Group changed to "${selectedGroup.name}" - assignments cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Reset Demo'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Instructions:',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text('1. Add some assignments using the button below'),
                  Text('2. Try changing the group - you should see a warning dialog'),
                  Text('3. Cancel the dialog - assignments should remain'),
                  Text('4. Confirm the dialog - assignments should be cleared'),
                  Text('5. When no assignments exist, group changes should be immediate'),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Group Selection Widget
            Text(
              'Group Selection:',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            GroupSelectionWidget(
              availableGroups: _availableGroups,
              selectedGroupId: _selectedGroupId,
              onGroupChanged: _onGroupChanged,
              hasExistingAssignments: _hasExistingAssignments(),
            ),

            SizedBox(height: 3.h),

            // Assignment Controls
            Text(
              'Assignment Controls:',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addAssignment,
                    child: const Text('Add Assignment'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _assignments.isNotEmpty ? _clearAssignments : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightTheme.colorScheme.error,
                      foregroundColor: AppTheme.lightTheme.colorScheme.onError,
                    ),
                    child: const Text('Clear All'),
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Status
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status:',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text('Selected Group: ${_availableGroups.firstWhere((g) => g.id == _selectedGroupId, orElse: () => _availableGroups.first).name}'),
                  Text('Assignments Count: ${_assignments.length}'),
                  Text('Has Existing Assignments: ${_hasExistingAssignments()}'),
                  Text('Last Action: $_statusMessage'),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // Current Assignments
            Text(
              'Current Assignments:',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            
            if (_assignments.isEmpty)
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('No assignments yet'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _assignments.length,
                separatorBuilder: (context, index) => SizedBox(height: 1.h),
                itemBuilder: (context, index) {
                  final assignment = _assignments[index];
                  return Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignment['itemName'],
                                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Assigned to: ${assignment['assignedTo']}',
                                style: AppTheme.lightTheme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${assignment['amount'].toStringAsFixed(2)}',
                          style: AppTheme.getMonospaceStyle(
                            isLight: true,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}