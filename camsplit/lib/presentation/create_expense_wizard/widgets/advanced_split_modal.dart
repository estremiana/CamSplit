import 'package:flutter/material.dart';
import '../models/receipt_item.dart';
import '../../../models/group_member.dart';
import '../../../widgets/initials_avatar_widget.dart';

/// Bottom sheet modal for creating advanced partial assignments
/// Allows selecting quantity and members for complex split scenarios
class AdvancedSplitModal extends StatefulWidget {
  final ReceiptItem item;
  final List<GroupMember> groupMembers;
  final Function(Map<String, double> newAssignments) onAssignmentCreated;

  const AdvancedSplitModal({
    super.key,
    required this.item,
    required this.groupMembers,
    required this.onAssignmentCreated,
  });

  @override
  State<AdvancedSplitModal> createState() => _AdvancedSplitModalState();
}

class _AdvancedSplitModalState extends State<AdvancedSplitModal> {
  late double _assignQty;
  late Set<String> _selectedMemberIds;
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    final remainingQty = widget.item.getRemainingCount();
    _assignQty = remainingQty > 0 ? remainingQty : 1.0;
    _selectedMemberIds = {};
    _qtyController = TextEditingController(
      text: _assignQty.toStringAsFixed(_assignQty.truncateToDouble() == _assignQty ? 0 : 1),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  /// Increment quantity
  void _incrementQuantity() {
    final remainingQty = widget.item.getRemainingCount();
    if (_assignQty < remainingQty) {
      setState(() {
        _assignQty += 1;
        _qtyController.text = _assignQty.toStringAsFixed(
          _assignQty.truncateToDouble() == _assignQty ? 0 : 1,
        );
      });
    }
  }

  /// Decrement quantity
  void _decrementQuantity() {
    if (_assignQty > 0.5) {
      setState(() {
        _assignQty -= 1;
        if (_assignQty < 0.5) _assignQty = 0.5;
        _qtyController.text = _assignQty.toStringAsFixed(
          _assignQty.truncateToDouble() == _assignQty ? 0 : 1,
        );
      });
    }
  }

  /// Update quantity from text input
  void _updateQuantityFromInput(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      final remainingQty = widget.item.getRemainingCount();
      setState(() {
        _assignQty = parsed.clamp(0.1, remainingQty);
      });
    }
  }

  /// Toggle member selection
  void _toggleMemberSelection(String memberId) {
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
  }

  /// Get action button text based on current selection
  String _getActionButtonText() {
    if (_selectedMemberIds.isEmpty) {
      return 'Select members to assign';
    }
    
    final qtyText = _assignQty.toStringAsFixed(
      _assignQty.truncateToDouble() == _assignQty ? 0 : 1,
    );
    final memberCount = _selectedMemberIds.length;
    
    return 'Split $qtyText between $memberCount ${memberCount == 1 ? 'person' : 'people'}';
  }

  /// Create the assignment
  void _commitAssignment() {
    if (_selectedMemberIds.isEmpty) return;

    // Calculate share per person
    final sharePerPerson = _assignQty / _selectedMemberIds.length;

    // Create new assignments map by adding to existing assignments
    final newAssignments = Map<String, double>.from(widget.item.assignments);
    
    for (final memberId in _selectedMemberIds) {
      newAssignments[memberId] = (newAssignments[memberId] ?? 0.0) + sharePerPerson;
    }

    // Call the callback with updated assignments
    widget.onAssignmentCreated(newAssignments);

    // Close the modal
    Navigator.of(context).pop();
  }

  /// Delete an existing assignment
  void _deleteAssignment(String memberId) {
    final newAssignments = Map<String, double>.from(widget.item.assignments);
    newAssignments.remove(memberId);
    widget.onAssignmentCreated(newAssignments);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingQty = widget.item.getRemainingCount();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(context, remainingQty),

            const Divider(height: 1),

            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quantity selector
                  _buildQuantitySelector(context, remainingQty),

                  const SizedBox(height: 24),

                  // Member selection
                  _buildMemberSelection(context),

                  const SizedBox(height: 24),

                  // Current assignments (always show, with empty state)
                  _buildCurrentAssignments(context),
                  const SizedBox(height: 24),

                  // Action button
                  _buildActionButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the modal header
  Widget _buildHeader(BuildContext context, double remainingQty) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Remaining: ${remainingQty.toStringAsFixed(remainingQty.truncateToDouble() == remainingQty ? 0 : 1)} of ${widget.item.quantity.toStringAsFixed(widget.item.quantity.truncateToDouble() == widget.item.quantity ? 0 : 1)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  /// Build quantity selector with +/- buttons
  Widget _buildQuantitySelector(BuildContext context, double remainingQty) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity to Assign',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Decrement button
            IconButton.filled(
              onPressed: _assignQty > 0.5 ? _decrementQuantity : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
            ),

            const SizedBox(width: 16),

            // Quantity input
            Expanded(
              child: TextField(
                controller: _qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: _updateQuantityFromInput,
              ),
            ),

            const SizedBox(width: 16),

            // Increment button
            IconButton.filled(
              onPressed: _assignQty < remainingQty ? _incrementQuantity : null,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build member selection grid
  Widget _buildMemberSelection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Members',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.groupMembers.map((member) {
            final memberIdStr = member.userId?.toString() ?? member.id.toString();
            final isSelected = _selectedMemberIds.contains(memberIdStr);

            return GestureDetector(
              onTap: () => _toggleMemberSelection(memberIdStr),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: isSelected ? 3 : 2,
                      ),
                    ),
                    child: InitialsAvatarWidget(
                      name: member.nickname,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 64,
                    child: Text(
                      member.nickname.split(' ').first,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
        ),
      ],
    );
  }

  /// Build current assignments list
  Widget _buildCurrentAssignments(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Assignments',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Show empty state if no assignments
        if (widget.item.assignments.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'No one assigned yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          )
        else
          // Show list of assignments
          ...widget.item.assignments.entries.map((entry) {
            final memberId = entry.key;
            final quantity = entry.value;
            final member = widget.groupMembers.firstWhere(
              (m) => (m.userId?.toString() ?? m.id.toString()) == memberId,
              orElse: () => GroupMember(
                id: 0,
                groupId: 0,
                nickname: 'Unknown',
                role: 'member',
                isRegisteredUser: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            final amount = quantity * widget.item.unitPrice;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  InitialsAvatarWidget(
                    name: member.nickname,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.nickname,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1)} × \${widget.item.unitPrice.toStringAsFixed(2)} = \${amount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteAssignment(memberId),
                    icon: const Icon(Icons.delete_outline),
                    color: theme.colorScheme.error,
                    iconSize: 20,
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  /// Build action button
  Widget _buildActionButton(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = _selectedMemberIds.isNotEmpty && _assignQty > 0;

    return FilledButton(
      onPressed: isEnabled ? _commitAssignment : null,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        _getActionButtonText(),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
