import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/group.dart';
import '../../../services/group_service.dart';
import 'group_selection_widget.dart';

/// Demo widget to test GroupSelectionWidget dropdown functionality
/// This demonstrates all the required features:
/// - Dropdown displays available groups ordered by most recent
/// - Shows group name and member count in dropdown items
/// - Handles empty state with "No groups available" placeholder
/// - Implements group selection change handling
class GroupSelectionDemo extends StatefulWidget {
  const GroupSelectionDemo({super.key});

  @override
  State<GroupSelectionDemo> createState() => _GroupSelectionDemoState();
}

class _GroupSelectionDemoState extends State<GroupSelectionDemo> {
  List<Group> _availableGroups = [];
  String? _selectedGroupId;
  bool _hasExistingAssignments = false;
  String _statusMessage = 'No group selected';

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() async {
    try {
      setState(() {
        _statusMessage = 'Loading groups...';
      });
      
      // TODO: This will be replaced with actual API call via GroupService
      final groups = await GroupService.getAllGroups();
      
      setState(() {
        _availableGroups = groups;
        // Pre-select the most recent group if available
        if (_availableGroups.isNotEmpty) {
          _selectedGroupId = _availableGroups.first.id;
          _statusMessage = 'Selected: ${_availableGroups.first.name}';
        } else {
          _statusMessage = 'No groups available';
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading groups: $e';
        _availableGroups = [];
        _selectedGroupId = null;
      });
    }
  }

  void _handleGroupChanged(String groupId) {
    final selectedGroup = _availableGroups.firstWhere((group) => group.id == groupId);
    setState(() {
      _selectedGroupId = groupId;
      _statusMessage = 'Selected: ${selectedGroup.name} (${selectedGroup.memberCount} members)';
    });
  }

  void _toggleAssignments() {
    setState(() {
      _hasExistingAssignments = !_hasExistingAssignments;
    });
  }

  void _clearGroups() {
    setState(() {
      _availableGroups = [];
      _selectedGroupId = null;
      _statusMessage = 'No groups available';
    });
  }

  void _resetGroups() {
    _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Selection Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Demo title
            Text(
              'Group Dropdown Functionality Demo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),

            // Status message
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Status: $_statusMessage',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Group selection widget
            GroupSelectionWidget(
              availableGroups: _availableGroups,
              selectedGroupId: _selectedGroupId,
              onGroupChanged: _handleGroupChanged,
              hasExistingAssignments: _hasExistingAssignments,
            ),

            SizedBox(height: 3.h),

            // Demo controls
            Text(
              'Demo Controls:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),

            // Toggle assignments button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleAssignments,
                icon: Icon(_hasExistingAssignments ? Icons.assignment_turned_in : Icons.assignment),
                label: Text(_hasExistingAssignments 
                  ? 'Disable Assignment Warning' 
                  : 'Enable Assignment Warning'),
              ),
            ),
            SizedBox(height: 1.h),

            // Clear groups button (to test empty state)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearGroups,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Groups (Test Empty State)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
            SizedBox(height: 1.h),

            // Reset groups button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetGroups,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Groups'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ),

            SizedBox(height: 3.h),

            // Feature checklist
            Text(
              'Implemented Features:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),

            _buildFeatureItem('✅ Dropdown displays available groups ordered by most recent'),
            _buildFeatureItem('✅ Shows group name and member count in dropdown items'),
            _buildFeatureItem('✅ Handles empty state with "No groups available" placeholder'),
            _buildFeatureItem('✅ Implements group selection change handling'),
            _buildFeatureItem('✅ Shows warning dialog when changing groups with existing assignments'),
            _buildFeatureItem('✅ Create group button with placeholder functionality'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}