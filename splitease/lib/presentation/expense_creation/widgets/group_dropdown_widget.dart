import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Widget for selecting groups in the expense creation page.
/// Resembles the GroupSelectionWidget from item assignment but simplified for expense creation.
class GroupDropdownWidget extends StatefulWidget {
  /// List of available groups for the user
  final List<String> availableGroups;
  
  /// Currently selected group
  final String selectedGroup;
  
  /// Callback when a group is selected from the dropdown
  final Function(String group) onGroupChanged;
  
  /// Whether the dropdown is enabled/editable
  final bool isEnabled;

  const GroupDropdownWidget({
    super.key,
    required this.availableGroups,
    required this.selectedGroup,
    required this.onGroupChanged,
    this.isEnabled = true,
  });

  @override
  State<GroupDropdownWidget> createState() => _GroupDropdownWidgetState();
}

class _GroupDropdownWidgetState extends State<GroupDropdownWidget> {
  
  /// Builds the dropdown menu item for a group
  DropdownMenuItem<String> _buildGroupDropdownItem(String group) {
    return DropdownMenuItem<String>(
      value: group,
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
            child: Text(
              group,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Group selection dropdown',
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.selectedGroup,
            hint: Semantics(
              label: 'Select a group',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                child: Text(
                  widget.availableGroups.isEmpty 
                    ? 'No groups available'
                    : 'Select a group',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            items: widget.availableGroups.isEmpty 
              ? null
              : widget.availableGroups.map(_buildGroupDropdownItem).toList(),
            onChanged: widget.isEnabled && widget.availableGroups.isNotEmpty 
              ? (value) {
                  if (value != null) {
                    widget.onGroupChanged(value);
                  }
                }
              : null,
            isExpanded: true,
            icon: Padding(
              padding: EdgeInsets.only(right: 3.w),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: widget.isEnabled 
                  ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            selectedItemBuilder: (BuildContext context) {
              return widget.availableGroups.map<Widget>((String group) {
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
                          group,
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: widget.isEnabled 
                              ? AppTheme.lightTheme.colorScheme.onSurface
                              : AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Show lock icon if disabled
                      if (!widget.isEnabled) ...[
                        SizedBox(width: 2.w),
                        Icon(
                          Icons.lock_outline,
                          size: 4.w,
                          color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
} 