import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/group.dart';
import 'group_selection_widget.dart';

class AssignmentSummaryWidget extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> members;
  final bool isEqualSplit;
  final VoidCallback onToggleEqualSplit;
  final VoidCallback? onAddParticipant;
  final List<Map<String, dynamic>>? quantityAssignments;
  
  // New properties for state management
  final Map<String, double>? previousIndividualTotals;
  final Function(Map<String, double>)? onIndividualTotalsChanged;

  // Group selection properties
  final List<Group>? availableGroups;
  final String? selectedGroupId;
  final Function(String groupId)? onGroupChanged;
  final bool hasExistingAssignments;

  const AssignmentSummaryWidget({
    super.key,
    required this.items,
    required this.members,
    required this.isEqualSplit,
    required this.onToggleEqualSplit,
    this.onAddParticipant,
    this.quantityAssignments,
    this.previousIndividualTotals,
    this.onIndividualTotalsChanged,
    this.availableGroups,
    this.selectedGroupId,
    this.onGroupChanged,
    this.hasExistingAssignments = false,
  });

  @override
  State<AssignmentSummaryWidget> createState() => _AssignmentSummaryWidgetState();
}

class _AssignmentSummaryWidgetState extends State<AssignmentSummaryWidget> {

  @override
  void didUpdateWidget(AssignmentSummaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle dynamic participant list updates
    if (oldWidget.members != widget.members) {
      // When members change, we need to recalculate totals
      // The calculation methods will handle the new member list automatically
      // Force a rebuild to reflect the new participant list
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // Trigger rebuild with new member list
          });
        }
      });
    }
  }

  Map<String, double> _calculateIndividualTotals() {
    Map<String, double> totals = {};

    // Initialize all members with 0
    for (var member in widget.members) {
      totals[member['id'].toString()] = 0.0;
    }

    // Use quantity assignments if available, otherwise fall back to old assignment structure
    if (widget.quantityAssignments != null && widget.quantityAssignments!.isNotEmpty) {
      // Calculate totals based on quantity assignments
      for (var assignment in widget.quantityAssignments!) {
        final memberIds = assignment['memberIds'] as List<dynamic>? ?? [];
        final totalPrice = assignment['totalPrice'] as double? ?? 0.0;
        final sharedAmount =
            memberIds.isNotEmpty ? totalPrice / memberIds.length : 0.0;

        for (var memberId in memberIds) {
          final memberIdString = memberId.toString();
          totals[memberIdString] =
              (totals[memberIdString] ?? 0.0) + sharedAmount;
        }
      }
    } else {
      // Fallback to old assignment structure
      for (var item in widget.items) {
        final assignedMembers =
            item['assignedMembers'] as List<String>? ?? [];
        if (assignedMembers.isNotEmpty) {
          final itemTotal =
              (item['total_price'] as double);
          final perMember = itemTotal / assignedMembers.length;

          for (var memberId in assignedMembers) {
            totals[memberId] = (totals[memberId] ?? 0.0) + perMember;
          }
        }
      }
    }

    return totals;
  }

  Map<String, double> _calculateEqualSplitTotals() {
    Map<String, double> totals = {};

    // Initialize all members with 0
    for (var member in widget.members) {
      totals[member['id'].toString()] = 0.0;
    }

    // Equal split among all members
    final totalAmount = widget.items.fold(
        0.0,
        (sum, item) =>
            sum + (item['total_price'] as double));
    final perMember = widget.members.isNotEmpty ? totalAmount / widget.members.length : 0.0;

    for (var member in widget.members) {
      totals[member['id'].toString()] = perMember;
    }

    return totals;
  }

  Map<String, double> _calculateMemberTotals() {
    if (widget.isEqualSplit) {
      return _calculateEqualSplitTotals();
    } else {
      // When equal split is off, use individual assignments
      // If we have previous individual totals and no current assignments, use previous
      final currentIndividualTotals = _calculateIndividualTotals();
      final hasCurrentAssignments = currentIndividualTotals.values.any((total) => total > 0);
      
      if (!hasCurrentAssignments && widget.previousIndividualTotals != null) {
        // No current assignments but we have previous individual totals, use them
        return Map<String, double>.from(widget.previousIndividualTotals!);
      } else {
        // Use current individual assignments and notify parent of changes
        if (widget.onIndividualTotalsChanged != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onIndividualTotalsChanged!(currentIndividualTotals);
          });
        }
        return currentIndividualTotals;
      }
    }
  }

  double _getTotalAmount() {
    if (widget.isEqualSplit) {
      // Equal split mode: Always show the actual total of all items
      return widget.items.fold(
          0.0,
          (sum, item) =>
              sum + (item['total_price'] as double? ?? 0.0));
    } else {
      // Non-equal split mode: Show the sum of current assignments (starts at 0)
      if (widget.quantityAssignments != null && widget.quantityAssignments!.isNotEmpty) {
        // Calculate total from quantity assignments
        return widget.quantityAssignments!.fold(
            0.0,
            (sum, assignment) =>
                sum + (assignment['totalPrice'] as double? ?? 0.0));
      } else {
        // Calculate total from individual item assignments
        double assignedTotal = 0.0;
        for (var item in widget.items) {
          final assignedMembers = item['assignedMembers'] as List<String>? ?? [];
          if (assignedMembers.isNotEmpty) {
            assignedTotal += (item['total_price'] as double? ?? 0.0);
          }
        }
        return assignedTotal;
      }
    }
  }

  int _getUnassignedItemsCount() {
    if (widget.quantityAssignments != null && widget.quantityAssignments!.isNotEmpty) {
      // Count items that still have remaining quantity
      return widget.items.where((item) {
        final remainingQuantity = item['remainingQuantity'] as int? ?? 0;
        return remainingQuantity > 0;
      }).length;
    } else {
      // Fallback to old assignment structure
      return widget.items.where((item) {
        final assignedMembers = item['assignedMembers'] as List<String>? ?? [];
        return assignedMembers.isEmpty;
      }).length;
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberTotals = _calculateMemberTotals();
    final totalAmount = _getTotalAmount();
    final unassignedCount = _getUnassignedItemsCount();

    return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
            color: AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppTheme.lightTheme.dividerColor, width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header with equal split toggle
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Assignment Summary',
                style: AppTheme.lightTheme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Row(children: [
              Text('Equal Split',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.secondary)),
              SizedBox(width: 2.w),
              Switch(
                  value: widget.isEqualSplit, onChanged: (_) => widget.onToggleEqualSplit()),
            ]),
          ]),

          SizedBox(height: 2.h),

          // Group Selection Widget (positioned above Add More Participants button)
          if (widget.availableGroups != null && widget.onGroupChanged != null)
            GroupSelectionWidget(
              availableGroups: widget.availableGroups!,
              selectedGroupId: widget.selectedGroupId,
              onGroupChanged: widget.onGroupChanged!,
              hasExistingAssignments: widget.hasExistingAssignments,
            ),

          // Add Participant Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onAddParticipant,
              icon: Icon(
                Icons.person_add,
                size: 4.w,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              label: const Text('Add More Participants'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                side: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Warning for unassigned items
          if (!widget.isEqualSplit && unassignedCount > 0)
            Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.warning,
                      color: AppTheme.lightTheme.colorScheme.onErrorContainer,
                      size: 20),
                  SizedBox(width: 2.w),
                  Expanded(
                      child: Text(
                          widget.quantityAssignments != null &&
                                  widget.quantityAssignments!.isNotEmpty
                              ? '$unassignedCount items have remaining quantities to assign'
                              : '$unassignedCount items need to be assigned',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w500))),
                ])),

          if (!widget.isEqualSplit && unassignedCount > 0) SizedBox(height: 2.h),

          // Member breakdown
          Column(
              children: widget.members.map((member) {
            final memberId = member['id'].toString();
            final memberTotal = memberTotals[memberId] ?? 0.0;
            final percentage =
                totalAmount > 0 ? (memberTotal / totalAmount) * 100 : 0.0;

            return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  // Member avatar
                  CircleAvatar(
                      radius: 4.w,
                      backgroundColor:
                          AppTheme.lightTheme.colorScheme.primaryContainer,
                      child: ClipOval(
                          child: CustomImageWidget(
                              imageUrl: member['avatar'] ?? '',
                              fit: BoxFit.cover,
                              width: 8.w,
                              height: 8.w))),
                  SizedBox(width: 3.w),
                  // Member name
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(member['name'],
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text('${percentage.toStringAsFixed(1)}% of total',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.secondary)),
                      ])),
                  // Amount
                  Text('\$${memberTotal.toStringAsFixed(2)}',
                      style: AppTheme.getMonospaceStyle(
                          isLight: true,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ]));
          }).toList()),

          SizedBox(height: 2.h),

          // Total
          Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount',
                        style: AppTheme.lightTheme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text('\$${totalAmount.toStringAsFixed(2)}',
                        style: AppTheme.getMonospaceStyle(
                            isLight: true,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ])),
        ]));
  }
}
