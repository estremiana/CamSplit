import 'package:flutter/material.dart';
import '../models/receipt_item.dart';
import '../../../models/group_member.dart';
import '../../../widgets/initials_avatar_widget.dart';

/// Panel for simple equal-split assignments shown when an item is expanded
/// Allows quick assignment by tapping member avatars
class QuickSplitPanel extends StatelessWidget {
  final ReceiptItem item;
  final List<GroupMember> groupMembers;
  final Function(String memberId) onMemberToggle;
  final VoidCallback? onAdvancedSplit;
  final VoidCallback? onReset;

  const QuickSplitPanel({
    super.key,
    required this.item,
    required this.groupMembers,
    required this.onMemberToggle,
    this.onAdvancedSplit,
    this.onReset,
  });

  /// Check if a member is assigned to this item
  bool _isMemberAssigned(String memberId) {
    return item.assignments.containsKey(memberId) && 
           item.assignments[memberId]! > 0;
  }

  /// Get the quantity assigned to a member
  double _getMemberQuantity(String memberId) {
    return item.assignments[memberId] ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assignedCount = item.getAssignedCount();
    final totalCount = item.quantity;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with label and progress
          Row(
            children: [
              Text(
                'Quick Split (Equal)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${assignedCount.toStringAsFixed(assignedCount.truncateToDouble() == assignedCount ? 0 : 1)}/${totalCount.toStringAsFixed(totalCount.truncateToDouble() == totalCount ? 0 : 1)} assigned',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Member avatar grid or locked overlay
          if (item.isCustomSplit)
            _buildLockedOverlay(context)
          else
            _buildMemberGrid(context),

          const SizedBox(height: 16),

          // Advanced split button
          if (!item.isCustomSplit && onAdvancedSplit != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdvancedSplit,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Advanced / Partial Split'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build the member avatar grid for quick assignment
  Widget _buildMemberGrid(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: groupMembers.map((member) {
        final memberIdStr = member.userId?.toString() ?? member.id.toString();
        final isAssigned = _isMemberAssigned(memberIdStr);
        final quantity = _getMemberQuantity(memberIdStr);

        return GestureDetector(
          onTap: () => onMemberToggle(memberIdStr),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAssigned 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.outline,
                        width: isAssigned ? 3 : 2,
                      ),
                    ),
                    child: InitialsAvatarWidget(
                      name: member.nickname,
                      size: 56,
                    ),
                  ),
                  
                  // Quantity badge
                  if (isAssigned && quantity > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        child: Center(
                          child: Text(
                            quantity.toStringAsFixed(
                              quantity.truncateToDouble() == quantity ? 0 : 1
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Member name
              SizedBox(
                width: 64,
                child: Text(
                  member.nickname.split(' ').first,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isAssigned 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isAssigned ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build the locked overlay when custom split is active
  Widget _buildLockedOverlay(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock,
            size: 48,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Custom Split Active',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This item has custom assignments. Reset to use Quick Split.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onReset != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
