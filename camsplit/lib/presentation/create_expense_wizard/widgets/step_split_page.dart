import 'package:flutter/material.dart';
import '../models/wizard_expense_data.dart';
import '../models/split_type.dart';
import '../../../models/group_member.dart';
import '../../../services/group_service.dart';
import 'equal_split_view.dart';
import 'percentage_split_view.dart';
import 'custom_split_view.dart';
import 'items_split_view.dart';

/// Third page of the expense wizard for configuring split options
/// Supports Equal, Percentage, Custom, and Items split modes
class StepSplitPage extends StatefulWidget {
  final WizardExpenseData wizardData;
  final VoidCallback onBack;
  final Function(WizardExpenseData) onDataChanged;
  final VoidCallback onSubmit;

  const StepSplitPage({
    super.key,
    required this.wizardData,
    required this.onBack,
    required this.onDataChanged,
    required this.onSubmit,
  });

  @override
  State<StepSplitPage> createState() => _StepSplitPageState();
}

class _StepSplitPageState extends State<StepSplitPage> {
  late SplitType _selectedSplitType;
  List<GroupMember> _groupMembers = [];
  bool _isLoadingMembers = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _selectedSplitType = widget.wizardData.splitType;
    _loadGroupMembers();
  }

  /// Load group members for the selected group
  Future<void> _loadGroupMembers() async {
    if (widget.wizardData.groupId.isEmpty) {
      setState(() {
        _groupMembers = [];
        _loadError = 'No group selected';
      });
      return;
    }

    setState(() {
      _isLoadingMembers = true;
      _loadError = null;
    });

    try {
      final group = await GroupService.getGroupWithMembers(widget.wizardData.groupId);
      if (group != null && mounted) {
        setState(() {
          _groupMembers = group.members;
          _isLoadingMembers = false;
        });
      } else if (mounted) {
        setState(() {
          _groupMembers = [];
          _isLoadingMembers = false;
          _loadError = 'Group not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _groupMembers = [];
          _isLoadingMembers = false;
          _loadError = 'Failed to load group members: $e';
        });
      }
    }
  }

  /// Handle split type tab change
  void _handleSplitTypeChange(SplitType newType) {
    setState(() {
      _selectedSplitType = newType;
    });
    
    // Update wizard data with new split type
    widget.onDataChanged(widget.wizardData.copyWith(splitType: newType));
  }

  /// Check if the current split configuration is valid
  bool _isSplitValid() {
    return widget.wizardData.isSplitValid();
  }

  /// Get validation error message for current split type
  String? _getValidationError() {
    switch (_selectedSplitType) {
      case SplitType.equal:
        if (widget.wizardData.involvedMembers.isEmpty) {
          return 'Select at least one member to split with';
        }
        return null;
        
      case SplitType.percentage:
        if (widget.wizardData.splitDetails.isEmpty) {
          return 'Enter percentages for at least one member';
        }
        final totalPercentage = widget.wizardData.splitDetails.values.fold(0.0, (sum, pct) => sum + pct);
        if ((totalPercentage - 100.0).abs() > 0.1) {
          final remaining = 100.0 - totalPercentage;
          if (remaining > 0) {
            return 'Remaining: ${remaining.toStringAsFixed(1)}% (must equal 0%)';
          } else {
            return 'Over by: ${(-remaining).toStringAsFixed(1)}% (must equal 100%)';
          }
        }
        return null;
        
      case SplitType.custom:
        if (widget.wizardData.splitDetails.isEmpty) {
          return 'Enter amounts for at least one member';
        }
        final totalAmount = widget.wizardData.splitDetails.values.fold(0.0, (sum, amt) => sum + amt);
        if ((totalAmount - widget.wizardData.amount).abs() > 0.05) {
          final remaining = widget.wizardData.amount - totalAmount;
          if (remaining > 0) {
            return 'Remaining: \${remaining.toStringAsFixed(2)} (must equal \$0.00)';
          } else {
            return 'Over by: \${(-remaining).toStringAsFixed(2)} (must equal total)';
          }
        }
        return null;
        
      case SplitType.items:
        if (widget.wizardData.items.isEmpty) {
          return 'No items available. Scan a receipt on the first page.';
        }
        // Check if all items are fully assigned
        final unassignedItems = widget.wizardData.items.where((item) => !item.isFullyAssigned()).toList();
        if (unassignedItems.isNotEmpty) {
          return 'Assign all items before continuing (${unassignedItems.length} item${unassignedItems.length == 1 ? '' : 's'} remaining)';
        }
        return null;
    }
  }

  /// Handle create expense button press
  void _handleCreateExpense() {
    if (_isSplitValid()) {
      widget.onSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSplitValid = _isSplitValid();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator with animation
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      'Split Options',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Page 3 of 3',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Split type tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildSplitTypeTab(
                    context,
                    SplitType.equal,
                    SplitType.equal.displayName,
                  ),
                  _buildSplitTypeTab(
                    context,
                    SplitType.percentage,
                    SplitType.percentage.displayName,
                  ),
                  _buildSplitTypeTab(
                    context,
                    SplitType.custom,
                    SplitType.custom.displayName,
                  ),
                  _buildSplitTypeTab(
                    context,
                    SplitType.items,
                    SplitType.items.displayName,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Main content area with animated transitions
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: _buildSplitContent(context),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Validation error banner with animation
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: (!isSplitValid && _getValidationError() != null)
                        ? Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getValidationError()!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  
                  // Navigation buttons row
                  Row(
                    children: [
                      // Back button
                      TextButton.icon(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      ),
                      const Spacer(),
                      // Create Expense button
                      ElevatedButton(
                        onPressed: isSplitValid ? _handleCreateExpense : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Create Expense'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single split type tab with animation
  Widget _buildSplitTypeTab(
    BuildContext context,
    SplitType type,
    String label,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedSplitType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleSplitTypeChange(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            style: theme.textTheme.titleMedium!.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// Build the content area based on selected split type
  Widget _buildSplitContent(BuildContext context) {
    final theme = Theme.of(context);

    // Show loading state while fetching members
    if (_isLoadingMembers) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading group members...',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Show error state if loading failed
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Members',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadGroupMembers,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Build content based on selected split type with unique keys for animation
    switch (_selectedSplitType) {
      case SplitType.equal:
        return EqualSplitView(
          key: const ValueKey('equal-split'),
          wizardData: widget.wizardData,
          groupMembers: _groupMembers,
          onDataChanged: widget.onDataChanged,
        );
      case SplitType.percentage:
        return PercentageSplitView(
          key: const ValueKey('percentage-split'),
          wizardData: widget.wizardData,
          groupMembers: _groupMembers,
          onDataChanged: widget.onDataChanged,
        );
      case SplitType.custom:
        return CustomSplitView(
          key: const ValueKey('custom-split'),
          wizardData: widget.wizardData,
          groupMembers: _groupMembers,
          onDataChanged: widget.onDataChanged,
        );
      case SplitType.items:
        return ItemsSplitView(
          key: const ValueKey('items-split'),
          wizardData: widget.wizardData,
          groupMembers: _groupMembers,
          onDataChanged: widget.onDataChanged,
        );
    }
  }

  /// Build placeholder content for split modes (to be replaced in future tasks)
  Widget _buildPlaceholderContent(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Implementation coming soon',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }


}
