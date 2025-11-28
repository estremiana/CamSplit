import 'package:flutter/material.dart';
import '../models/wizard_expense_data.dart';
import '../models/receipt_item.dart';
import '../../../models/group_member.dart';

/// Summary section displaying member totals and unassigned amounts
/// Shows at the bottom of Items split view
class SplitSummary extends StatelessWidget {
  final WizardExpenseData wizardData;
  final List<GroupMember> groupMembers;

  const SplitSummary({
    super.key,
    required this.wizardData,
    required this.groupMembers,
  });

  /// Calculate the total amount owed by a specific member
  /// Sum of (assigned quantity × unit price) across all items
  double calculateMemberTotal(String memberId) {
    double total = 0.0;
    
    for (final item in wizardData.items) {
      final assignedQty = item.assignments[memberId] ?? 0.0;
      total += assignedQty * item.unitPrice;
    }
    
    return total;
  }

  /// Get list of members who have been assigned items
  /// Filters out members with zero assignments
  List<GroupMember> getAssignedMembers() {
    return groupMembers.where((member) {
      final memberId = member.userId?.toString() ?? member.id.toString();
      final total = calculateMemberTotal(memberId);
      return total > 0.01; // Use small tolerance for floating point
    }).toList();
  }

  /// Calculate the total unassigned amount across all items
  double calculateUnassignedAmount() {
    double unassigned = 0.0;
    
    for (final item in wizardData.items) {
      final remainingQty = item.getRemainingCount();
      unassigned += remainingQty * item.unitPrice;
    }
    
    return unassigned;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assignedMembers = getAssignedMembers();
    final unassignedAmount = calculateUnassignedAmount();
    final hasUnassigned = unassignedAmount > 0.01;

    // Don't show summary if no members have assignments
    if (assignedMembers.isEmpty && !hasUnassigned) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          Text(
            'Split Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),

          // Member totals
          if (assignedMembers.isNotEmpty) ...[
            ...assignedMembers.map((member) {
              final memberId = member.userId?.toString() ?? member.id.toString();
              final total = calculateMemberTotal(memberId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    // Member name
                    Expanded(
                      child: Text(
                        member.nickname,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    
                    // Amount owed
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Unassigned amount (only show if > 0)
          if (hasUnassigned) ...[
            if (assignedMembers.isNotEmpty) const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unassigned',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '\$${unassignedAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
