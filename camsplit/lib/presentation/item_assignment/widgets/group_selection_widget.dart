import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/group.dart';
import 'group_change_warning_dialog.dart';

/// Widget for selecting groups and creating new groups in the item assignment page.
/// Positioned above the "Add More Participants" button in the AssignmentSummaryWidget.
class GroupSelectionWidget extends StatefulWidget {
  /// List of available groups for the user, sorted by most recent usage
  final List<Group> availableGroups;
  
  /// Currently selected group ID
  final String? selectedGroupId;
  
  /// Callback when a group is selected from the dropdown
  final Function(String groupId) onGroupChanged;
  
  /// Whether there are existing assignments that would be reset on group change
  final bool hasExistingAssignments;
  
  /// Whether groups are currently being loaded
  final bool isLoading;

  const GroupSelectionWidget({
    super.key,
    required this.availableGroups,
    this.selectedGroupId,
    required this.onGroupChanged,
    required this.hasExistingAssignments,
    this.isLoading = false,
  });

  @override
  State<GroupSelectionWidget> createState() => _GroupSelectionWidgetState();
}

class _GroupSelectionWidgetState extends State<GroupSelectionWidget> {
  
  /// Gets the available groups sorted by most recent usage
  List<Group> get _sortedGroups {
    final groups = List<Group>.from(widget.availableGroups);
    groups.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return groups;
  }
  
  /// Shows a placeholder message for the create group functionality
  void _showCreateGroupPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This feature will be implemented in a future update'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Shows warning dialog when changing groups with existing assignments
  Future<void> _showGroupChangeWarning(String newGroupId) async {
    final result = await GroupChangeWarningDialog.show(
      context: context,
      onConfirm: () {
        // User confirmed - proceed with group change (assignments will be cleared)
        widget.onGroupChanged(newGroupId);
      },
      onCancel: () {
        // User cancelled - no action needed, group selection remains unchanged
        // The dropdown will automatically revert to the previous selection
      },
    );
    
    // If dialog was dismissed without selection, ensure dropdown reverts
    if (result != true) {
      // Force rebuild to ensure dropdown shows correct selection
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Handles group selection with warning if needed
  void _handleGroupSelection(String? newGroupId) {
    if (newGroupId == null || newGroupId == widget.selectedGroupId) {
      return;
    }

    if (widget.hasExistingAssignments) {
      _showGroupChangeWarning(newGroupId);
    } else {
      widget.onGroupChanged(newGroupId);
    }
  }

  /// Builds the dropdown menu item for a group
  DropdownMenuItem<String> _buildGroupDropdownItem(Group group) {
    return DropdownMenuItem<String>(
      value: group.id.toString(),
      child: Row(
        children: [
          // Group icon/avatar placeholder
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Icon(
              Icons.group,
              size: 4.w,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  group.name,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${group.memberCount} member${group.memberCount != 1 ? 's' : ''}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Group selection section',
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        child: Row(
          children: [
            // Group dropdown
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: widget.isLoading
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.primary,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Loading groups...',
                            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: widget.selectedGroupId,
                        hint: Semantics(
                          label: 'Select a group',
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                            child: Text(
                              _sortedGroups.isEmpty 
                                ? 'No groups available'
                                : 'Select a group',
                              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        items: _sortedGroups.isEmpty 
                          ? null
                          : _sortedGroups.map(_buildGroupDropdownItem).toList(),
                        onChanged: _sortedGroups.isEmpty ? null : _handleGroupSelection,
                        isExpanded: true,
                        icon: Padding(
                          padding: EdgeInsets.only(right: 3.w),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        selectedItemBuilder: (BuildContext context) {
                      return _sortedGroups.map<Widget>((Group group) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                          child: Row(
                            children: [
                              Container(
                                width: 6.w,
                                height: 6.w,
                                decoration: BoxDecoration(
                                  color: AppTheme.lightTheme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Icon(
                                  Icons.group,
                                  size: 4.w,
                                  color: AppTheme.lightTheme.colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    dropdownColor: AppTheme.lightTheme.cardColor,
                    borderRadius: BorderRadius.circular(8.0),
                    elevation: 4,
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 3.w),
            
            // Create group button
            Semantics(
              label: 'Create new group',
              button: true,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: IconButton(
                  onPressed: _showCreateGroupPlaceholder,
                  icon: Icon(
                    Icons.add,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 5.w,
                  ),
                  tooltip: 'Create new group',
                  padding: EdgeInsets.all(2.w),
                  constraints: BoxConstraints(
                    minWidth: 12.w,
                    minHeight: 12.w,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}