import 'package:flutter/material.dart';
import '../models/wizard_expense_data.dart';
import '../../../models/group_member.dart';

/// View for Equal split mode
/// Displays all group members with checkboxes to include/exclude them
/// Calculates and displays equal share per member
class EqualSplitView extends StatefulWidget {
  final WizardExpenseData wizardData;
  final List<GroupMember> groupMembers;
  final Function(WizardExpenseData) onDataChanged;

  const EqualSplitView({
    super.key,
    required this.wizardData,
    required this.groupMembers,
    required this.onDataChanged,
  });

  @override
  State<EqualSplitView> createState() => _EqualSplitViewState();
}

class _EqualSplitViewState extends State<EqualSplitView> {
  late Set<String> _selectedMemberIds;

  @override
  void initState() {
    super.initState();
    // Initialize with currently involved members or all members if none selected
    if (widget.wizardData.involvedMembers.isEmpty) {
      _selectedMemberIds = widget.groupMembers
          .map((member) => member.id.toString())
          .toSet();
      // Update wizard data with all members selected by default
      _updateWizardData();
    } else {
      _selectedMemberIds = widget.wizardData.involvedMembers.toSet();
    }
  }

  /// Toggle member inclusion/exclusion
  void _toggleMember(String memberId) {
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
    _updateWizardData();
  }

  /// Update wizard data with current selection
  void _updateWizardData() {
    widget.onDataChanged(
      widget.wizardData.copyWith(
        involvedMembers: _selectedMemberIds.toList(),
      ),
    );
  }

  /// Calculate equal share per member
  double _calculateEqualShare() {
    if (_selectedMemberIds.isEmpty) return 0.0;
    return widget.wizardData.amount / _selectedMemberIds.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final equalShare = _calculateEqualShare();

    return Column(
      children: [
        // Header with summary
        Container(
          padding: const EdgeInsets.all(16.0),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Members',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedMemberIds.isNotEmpty)
                Text(
                  '${_selectedMemberIds.length} member${_selectedMemberIds.length == 1 ? '' : 's'} selected',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (_selectedMemberIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Each pays: \$${equalShare.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Member list
        Expanded(
          child: widget.groupMembers.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: widget.groupMembers.length,
                  itemBuilder: (context, index) {
                    final member = widget.groupMembers[index];
                    final memberId = member.id.toString();
                    final isSelected = _selectedMemberIds.contains(memberId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          _toggleMember(memberId);
                        },
                        title: Text(
                          member.displayName,
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: isSelected
                            ? Text(
                                '\$${equalShare.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : null,
                        secondary: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            member.initials,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Group Members',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select a group with members on the previous page',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
