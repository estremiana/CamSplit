import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/group.dart';
import '../../../services/group_service.dart';
import 'quantity_assignment_widget.dart';
import 'assignment_summary_widget.dart';

/// Demo widget to test dynamic participant list updates
class DynamicParticipantDemo extends StatefulWidget {
  const DynamicParticipantDemo({super.key});

  @override
  State<DynamicParticipantDemo> createState() => _DynamicParticipantDemoState();
}

class _DynamicParticipantDemoState extends State<DynamicParticipantDemo> {
  List<Group> _availableGroups = [];
  String? _selectedGroupId;
  List<Map<String, dynamic>> _groupMembers = [];
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _quantityAssignments = [];
  bool _isEqualSplit = false;

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
        
        // Pre-select the first group
        if (_availableGroups.isNotEmpty) {
          _selectedGroupId = _availableGroups.first.id;
          _updateGroupMembers(_selectedGroupId!);
        }
      });
    } catch (e) {
      // Handle error loading groups
      setState(() {
        _availableGroups = [];
        _selectedGroupId = null;
        _groupMembers = [];
      });
    }

    // Create test items
    _items = [
      {
        'id': 1,
        'name': 'Pizza',
        'unit_price': 15.99,
        'originalQuantity': 2,
        'remainingQuantity': 2,
        'quantityAssignments': <Map<String, dynamic>>[],
        'assignedMembers': <String>[],
        'total_price': 31.98,
      },
      {
        'id': 2,
        'name': 'Drinks',
        'unit_price': 3.50,
        'originalQuantity': 4,
        'remainingQuantity': 4,
        'quantityAssignments': <Map<String, dynamic>>[],
        'assignedMembers': <String>[],
        'total_price': 14.00,
      },
    ];
  }

  void _updateGroupMembers(String groupId) {
    final selectedGroup = _availableGroups.firstWhere(
      (group) => group.id == groupId,
      orElse: () => _availableGroups.first,
    );

    setState(() {
      _groupMembers = selectedGroup.members.map((member) => {
        'id': int.parse(member.id),
        'name': member.name,
        'avatar': member.avatar,
      }).toList();
      
      // Clear assignments when group changes (this handles requirement 3.3)
      _clearAllAssignments();
    });
  }

  /// Clears all existing assignments when group changes
  /// This implements requirement 3.3: Clear all assignments when user confirms group change
  void _clearAllAssignments() {
    for (var item in _items) {
      item['assignedMembers'] = <String>[];
      item['remainingQuantity'] = item['originalQuantity'];
      item['quantityAssignments'] = <Map<String, dynamic>>[];
    }
    _quantityAssignments.clear();
  }

  /// Detects if there are existing assignments that would be lost on group change
  bool _hasExistingAssignments() {
    // Check if any quantity assignments exist
    if (_quantityAssignments.isNotEmpty) {
      return true;
    }
    
    // Check if any items have assigned members (fallback for old assignment structure)
    for (var item in _items) {
      final assignedMembers = item['assignedMembers'] as List<String>? ?? [];
      if (assignedMembers.isNotEmpty) {
        return true;
      }
      
      // Check if any items have quantity assignments
      final quantityAssignments = item['quantityAssignments'] as List<Map<String, dynamic>>? ?? [];
      if (quantityAssignments.isNotEmpty) {
        return true;
      }
    }
    
    return false;
  }

  void _onGroupChanged(String groupId) {
    _selectedGroupId = groupId;
    _updateGroupMembers(groupId);
  }

  void _onQuantityAssigned(Map<String, dynamic> assignment) {
    setState(() {
      _quantityAssignments.add(assignment);

      // Update the item's remaining quantity
      final itemIndex = _items.indexWhere((item) => item['id'] == assignment['itemId']);
      if (itemIndex != -1) {
        final item = _items[itemIndex];
        final currentAssignments = List<Map<String, dynamic>>.from(item['quantityAssignments'] ?? []);
        currentAssignments.add(assignment);

        final totalAssignedQuantity = currentAssignments.fold<int>(
            0, (sum, assign) => sum + (assign['quantity'] as int));

        _items[itemIndex]['quantityAssignments'] = currentAssignments;
        _items[itemIndex]['remainingQuantity'] =
            (_items[itemIndex]['originalQuantity'] as int) - totalAssignedQuantity;
      }
    });
  }

  void _onQuantityAssignmentRemoved(Map<String, dynamic> assignment) {
    setState(() {
      _quantityAssignments.removeWhere(
          (assign) => assign['assignmentId'] == assignment['assignmentId']);

      // Update the item's remaining quantity
      final itemIndex = _items.indexWhere((item) => item['id'] == assignment['itemId']);
      if (itemIndex != -1) {
        final item = _items[itemIndex];
        final currentAssignments = List<Map<String, dynamic>>.from(item['quantityAssignments'] ?? []);
        currentAssignments.removeWhere(
            (assign) => assign['assignmentId'] == assignment['assignmentId']);

        final totalAssignedQuantity = currentAssignments.fold<int>(
            0, (sum, assign) => sum + (assign['quantity'] as int));

        _items[itemIndex]['quantityAssignments'] = currentAssignments;
        _items[itemIndex]['remainingQuantity'] =
            (_items[itemIndex]['originalQuantity'] as int) - totalAssignedQuantity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Participant Demo'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group selection buttons
            Text(
              'Select Group:',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              children: _availableGroups.map((group) {
                final isSelected = _selectedGroupId == group.id;
                return ElevatedButton(
                  onPressed: () => _onGroupChanged(group.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                    foregroundColor: isSelected
                        ? AppTheme.lightTheme.colorScheme.onPrimary
                        : AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                  child: Text('${group.name} (${group.members.length})'),
                );
              }).toList(),
            ),

            SizedBox(height: 3.h),

            // Current participants
            Text(
              'Current Participants:',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: _groupMembers.map((member) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundImage: NetworkImage(member['avatar']),
                    ),
                    label: Text(member['name']),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 3.h),

            // Assignment Summary
            AssignmentSummaryWidget(
              items: _items,
              members: _groupMembers,
              isEqualSplit: _isEqualSplit,
              onToggleEqualSplit: () {
                setState(() {
                  _isEqualSplit = !_isEqualSplit;
                });
              },
              quantityAssignments: _quantityAssignments,
              availableGroups: _availableGroups,
              selectedGroupId: _selectedGroupId,
              onGroupChanged: _onGroupChanged,
              hasExistingAssignments: _hasExistingAssignments(),
            ),

            SizedBox(height: 3.h),

            // Quantity Assignment Widgets
            Text(
              'Item Assignment:',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final item = _items[index];
                return QuantityAssignmentWidget(
                  item: item,
                  members: _groupMembers,
                  onQuantityAssigned: _onQuantityAssigned,
                  onAssignmentRemoved: _onQuantityAssignmentRemoved,
                  isExpanded: true, // Always expanded for demo
                  onToggleExpanded: () {},
                );
              },
            ),

            SizedBox(height: 3.h),

            // Test results
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test Results:',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text('Selected Group: ${_availableGroups.firstWhere((g) => g.id == _selectedGroupId).name}'),
                  Text('Participants: ${_groupMembers.length}'),
                  Text('Total Assignments: ${_quantityAssignments.length}'),
                  Text('Items with Remaining Quantity: ${_items.where((item) => (item['remainingQuantity'] as int) > 0).length}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}