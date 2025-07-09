import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AssignmentSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> members;
  final bool isEqualSplit;
  final VoidCallback onToggleEqualSplit;
  final VoidCallback? onAddParticipant;
  final List<Map<String, dynamic>>? quantityAssignments;

  const AssignmentSummaryWidget({
    super.key,
    required this.items,
    required this.members,
    required this.isEqualSplit,
    required this.onToggleEqualSplit,
    this.onAddParticipant,
    this.quantityAssignments,
  });

  Map<String, double> _calculateMemberTotals() {
    Map<String, double> totals = {};

    // Initialize all members with 0
    for (var member in members) {
      totals[member['id'].toString()] = 0.0;
    }

    if (isEqualSplit) {
      // Equal split among all members
      final totalAmount = items.fold(
          0.0,
          (sum, item) =>
              sum + (item['total_price'] as double));
      final perMember = totalAmount / members.length;

      for (var member in members) {
        totals[member['id'].toString()] = perMember;
      }
    } else {
      // Use quantity assignments if available, otherwise fall back to old assignment structure
      if (quantityAssignments != null && quantityAssignments!.isNotEmpty) {
        // Calculate totals based on quantity assignments
        for (var assignment in quantityAssignments!) {
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
        for (var item in items) {
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
    }

    return totals;
  }

  double _getTotalAmount() {
    if (quantityAssignments != null && quantityAssignments!.isNotEmpty) {
      // Calculate total from quantity assignments
      return quantityAssignments!.fold(
          0.0,
          (sum, assignment) =>
              sum + (assignment['totalPrice'] as double? ?? 0.0));
    } else {
      // Fallback to calculating from items
      return items.fold(
          0.0,
          (sum, item) =>
              sum + (item['total_price'] as double));
    }
  }

  int _getUnassignedItemsCount() {
    if (quantityAssignments != null && quantityAssignments!.isNotEmpty) {
      // Count items that still have remaining quantity
      return items.where((item) {
        final remainingQuantity = item['remainingQuantity'] as int? ?? 0;
        return remainingQuantity > 0;
      }).length;
    } else {
      // Fallback to old assignment structure
      return items.where((item) {
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
                  value: isEqualSplit, onChanged: (_) => onToggleEqualSplit()),
            ]),
          ]),

          SizedBox(height: 2.h),

          // Add Participant Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddParticipant,
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
          if (!isEqualSplit && unassignedCount > 0)
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
                          quantityAssignments != null &&
                                  quantityAssignments!.isNotEmpty
                              ? '$unassignedCount items have remaining quantities to assign'
                              : '$unassignedCount items need to be assigned',
                          style: AppTheme.lightTheme.textTheme.bodySmall
                              ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w500))),
                ])),

          if (!isEqualSplit && unassignedCount > 0) SizedBox(height: 2.h),

          // Member breakdown
          Column(
              children: members.map((member) {
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
