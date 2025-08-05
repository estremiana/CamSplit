import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import './member_avatar_widget.dart';

class QuantityAssignmentWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> members;
  final Function(Map<String, dynamic>) onQuantityAssigned;
  final Function(Map<String, dynamic>) onAssignmentRemoved;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;

  const QuantityAssignmentWidget({
    super.key,
    required this.item,
    required this.members,
    required this.onQuantityAssigned,
    required this.onAssignmentRemoved,
    required this.isExpanded,
    required this.onToggleExpanded,
  });

  @override
  State<QuantityAssignmentWidget> createState() =>
      _QuantityAssignmentWidgetState();
}

class _QuantityAssignmentWidgetState extends State<QuantityAssignmentWidget> {
  int _assignableQuantity = 1;
  Set<String> _selectedMemberIds = {};
  final TextEditingController _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _assignableQuantity = 1;
    _quantityController.text = '1';
  }

  @override
  void didUpdateWidget(QuantityAssignmentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle dynamic participant list updates
    if (oldWidget.members != widget.members) {
      // Clear selected members if they no longer exist in the new member list
      final newMemberIds = widget.members.map((m) => m['id'].toString()).toSet();
      _selectedMemberIds.removeWhere((memberId) => !newMemberIds.contains(memberId));
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  int get _maxQuantity => widget.item['originalQuantity'] ?? 1;
  int get _remainingQuantity =>
      widget.item['remainingQuantity'] ?? _maxQuantity;

  void _updateQuantity(int newQuantity) {
    final clampedQuantity = newQuantity.clamp(1, _remainingQuantity);
    setState(() {
      _assignableQuantity = clampedQuantity;
      _quantityController.text = clampedQuantity.toString();
    });
    HapticFeedback.lightImpact();
  }

  void _toggleMemberSelection(String memberId) {
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _assignQuantity() {
    if (_selectedMemberIds.isNotEmpty && _assignableQuantity > 0) {
      // Create assignment for each selected member with shared quantity
      final selectedMembers = widget.members
          .where(
              (member) => _selectedMemberIds.contains(member['id'].toString()))
          .toList();

      final assignment = {
        'itemId': widget.item['id'],
        'itemName': widget.item['name'],
        'quantity': _assignableQuantity,
        'unitPrice': widget.item['unit_price'],
        'totalPrice': (widget.item['unit_price'] as double) * _assignableQuantity,
        'memberIds': _selectedMemberIds.toList(),
        'memberNames': selectedMembers.map((m) => m['name']).toList(),
        'assignmentId': DateTime.now().millisecondsSinceEpoch.toString(),
        'isShared': _selectedMemberIds.length > 1,
      };

      widget.onQuantityAssigned(assignment);

      // Reset selection
      setState(() {
        _selectedMemberIds.clear();
        _assignableQuantity = 1;
        _quantityController.text = '1';
      });

      HapticFeedback.mediumImpact();
    }
  }

  void _removeAssignment(Map<String, dynamic> assignment) {
    widget.onAssignmentRemoved(assignment);
    HapticFeedback.lightImpact();
  }

  List<Map<String, dynamic>> get _currentAssignments {
    return (widget.item['quantityAssignments']
            as List<Map<String, dynamic>>?) ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    final assignments = _currentAssignments;
    final hasAssignments = assignments.isNotEmpty;
    final canAssign = _remainingQuantity > 0;

    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Header - Always visible
          GestureDetector(
            onTap: widget.onToggleExpanded,
            child: Container(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  // Item info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['name'],
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '\$${widget.item['unit_price'].toStringAsFixed(2)} each',
                          style: AppTheme.getMonospaceStyle(
                            isLight: true,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.5.h),
                              decoration: BoxDecoration(
                                color: canAssign
                                    ? AppTheme
                                        .lightTheme.colorScheme.primaryContainer
                                    : AppTheme
                                        .lightTheme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Remaining: $_remainingQuantity',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: canAssign
                                      ? AppTheme.lightTheme.colorScheme
                                          .onPrimaryContainer
                                      : AppTheme.lightTheme.colorScheme
                                          .onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (hasAssignments) ...[
                              SizedBox(width: 2.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 2.w, vertical: 0.5.h),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightTheme.colorScheme
                                      .secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${assignments.length} assignments',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSecondaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse icon
                  Icon(
                    widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: widget.isExpanded ? null : 0,
            child: widget.isExpanded
                ? Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme
                          .lightTheme.colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current assignments
                        if (hasAssignments) ...[
                          Text(
                            'Current Assignments:',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 1.h),
                          ...assignments.map((assignment) {
                            final isShared = assignment['isShared'] ?? false;
                            final memberNames =
                                assignment['memberNames'] as List<dynamic>? ??
                                    [];

                            return Container(
                              margin: EdgeInsets.only(bottom: 1.h),
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: isShared
                                    ? AppTheme.lightTheme.colorScheme
                                        .tertiaryContainer
                                    : AppTheme.lightTheme.colorScheme
                                        .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  if (isShared)
                                    Icon(
                                      Icons.group,
                                      size: 5.w,
                                      color: AppTheme.lightTheme.colorScheme
                                          .onTertiaryContainer,
                                    )
                                  else
                                    CircleAvatar(
                                      radius: 3.w,
                                      backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
                                      child: ClipOval(
                                        child: CustomImageWidget(
                                          imageUrl: widget.members.firstWhere((m) =>
                                              assignment['memberIds'].contains(
                                                  m['id']
                                                      .toString()))['avatar'],
                                          width: 6.w,
                                          height: 6.w,
                                          fit: BoxFit.cover,
                                          userName: widget.members.firstWhere((m) =>
                                              assignment['memberIds'].contains(
                                                  m['id']
                                                      .toString()))['name'],
                                        ),
                                      ),
                                    ),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isShared
                                              ? 'Shared by ${memberNames.join(', ')}'
                                              : memberNames.first.toString(),
                                          style: AppTheme
                                              .lightTheme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Quantity: ${assignment['quantity']}',
                                          style: AppTheme
                                              .lightTheme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${assignment['totalPrice'].toStringAsFixed(2)}',
                                    style: AppTheme.getMonospaceStyle(
                                      isLight: true,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  IconButton(
                                    onPressed: () =>
                                        _removeAssignment(assignment),
                                    icon: Icon(
                                      Icons.close,
                                      size: 4.w,
                                      color:
                                          AppTheme.lightTheme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          SizedBox(height: 2.h),
                        ],

                        // New assignment section
                        if (canAssign) ...[
                          Text(
                            'Create New Assignment:',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 1.h),

                          // Quantity selector
                          Row(
                            children: [
                              Text(
                                'Quantity:',
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              SizedBox(width: 4.w),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.lightTheme.dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: _assignableQuantity > 1
                                          ? () => _updateQuantity(
                                              _assignableQuantity - 1)
                                          : null,
                                      icon: const Icon(Icons.remove),
                                      iconSize: 18,
                                      constraints: const BoxConstraints(
                                          minWidth: 36, minHeight: 36),
                                    ),
                                    SizedBox(
                                      width: 12.w,
                                      child: TextField(
                                        controller: _quantityController,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: AppTheme
                                            .lightTheme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                        onChanged: (value) {
                                          final newQuantity =
                                              int.tryParse(value) ?? 1;
                                          _updateQuantity(newQuantity);
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _assignableQuantity <
                                              _remainingQuantity
                                          ? () => _updateQuantity(
                                              _assignableQuantity + 1)
                                          : null,
                                      icon: const Icon(Icons.add),
                                      iconSize: 18,
                                      constraints: const BoxConstraints(
                                          minWidth: 36, minHeight: 36),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Max: $_remainingQuantity',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 2.h),

                          // Member selection - Multiple selection enabled
                          Text(
                            'Select Members (multiple allowed for shared items):',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          SizedBox(height: 1.h),
                          Wrap(
                            spacing: 2.w,
                            runSpacing: 1.h,
                            children: widget.members.map((member) {
                              final isSelected = _selectedMemberIds
                                  .contains(member['id'].toString());
                              return GestureDetector(
                                onTap: () => _toggleMemberSelection(
                                    member['id'].toString()),
                                child: Column(
                                  children: [
                                    MemberAvatarWidget(
                                      member: member,
                                      isSelected: isSelected,
                                      onTap: () => _toggleMemberSelection(
                                          member['id'].toString()),
                                      size: 10.0,
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      member['name'],
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: isSelected
                                            ? AppTheme
                                                .lightTheme.colorScheme.primary
                                            : AppTheme.lightTheme.colorScheme
                                                .onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                          SizedBox(height: 2.h),

                          // Assignment preview and button
                          if (_selectedMemberIds.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: _selectedMemberIds.length > 1
                                    ? AppTheme.lightTheme.colorScheme
                                        .tertiaryContainer
                                    : AppTheme.lightTheme.colorScheme
                                        .primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedMemberIds.length > 1
                                            ? 'Shared Assignment Preview:'
                                            : 'Assignment Preview:',
                                        style: AppTheme
                                            .lightTheme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '\$${((widget.item['unit_price'] as double) * _assignableQuantity).toStringAsFixed(2)}',
                                        style: AppTheme.getMonospaceStyle(
                                          isLight: true,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_selectedMemberIds.length > 1) ...[
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      'Shared between ${_selectedMemberIds.length} members',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: AppTheme.lightTheme.colorScheme
                                            .onTertiaryContainer,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: 1.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _assignQuantity,
                                icon: Icon(_selectedMemberIds.length > 1
                                    ? Icons.group_add
                                    : Icons.person_add),
                                label: Text(_selectedMemberIds.length > 1
                                    ? 'Create Shared Assignment'
                                    : 'Assign'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 1.5.h),
                                ),
                              ),
                            ),
                          ],
                        ] else ...[
                          // All quantities assigned
                          Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  size: 5.w,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'All quantities have been assigned',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
