import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wizard_expense_data.dart';
import '../../../models/group_member.dart';

/// View for Percentage split mode
/// Displays input fields for each member to enter their percentage
/// Calculates remaining percentage and validates sum = 100%
class PercentageSplitView extends StatefulWidget {
  final WizardExpenseData wizardData;
  final List<GroupMember> groupMembers;
  final Function(WizardExpenseData) onDataChanged;

  const PercentageSplitView({
    super.key,
    required this.wizardData,
    required this.groupMembers,
    required this.onDataChanged,
  });

  @override
  State<PercentageSplitView> createState() => _PercentageSplitViewState();
}

class _PercentageSplitViewState extends State<PercentageSplitView> {
  late Map<String, TextEditingController> _controllers;
  late Map<String, double> _percentages;

  @override
  void initState() {
    super.initState();
    _percentages = Map<String, double>.from(widget.wizardData.splitDetails);
    _controllers = {};
    
    // Initialize controllers for each member
    for (final member in widget.groupMembers) {
      final memberId = member.id.toString();
      final percentage = _percentages[memberId] ?? 0.0;
      _controllers[memberId] = TextEditingController(
        text: percentage > 0 ? percentage.toStringAsFixed(2) : '',
      );
      
      // Add listener to update percentages when text changes
      _controllers[memberId]!.addListener(() {
        _handlePercentageChange(memberId);
      });
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Handle percentage input change
  void _handlePercentageChange(String memberId) {
    final text = _controllers[memberId]!.text;
    final value = double.tryParse(text) ?? 0.0;
    
    setState(() {
      _percentages[memberId] = value;
    });
    
    _updateWizardData();
  }

  /// Update wizard data with current percentages
  void _updateWizardData() {
    // Only include members with non-zero percentages
    final nonZeroPercentages = Map<String, double>.from(_percentages)
      ..removeWhere((key, value) => value <= 0);
    
    widget.onDataChanged(
      widget.wizardData.copyWith(
        splitDetails: nonZeroPercentages,
      ),
    );
  }

  /// Calculate total percentage
  double _calculateTotalPercentage() {
    return _percentages.values.fold(0.0, (sum, pct) => sum + pct);
  }

  /// Calculate remaining percentage
  double _calculateRemainingPercentage() {
    return 100.0 - _calculateTotalPercentage();
  }

  /// Check if split is valid (sum = 100% within tolerance)
  bool _isSplitValid() {
    final total = _calculateTotalPercentage();
    return (total - 100.0).abs() <= 0.1 && _percentages.values.any((v) => v > 0);
  }

  /// Get validation error message
  String? _getValidationError() {
    final total = _calculateTotalPercentage();
    final remaining = _calculateRemainingPercentage();
    
    if (_percentages.values.every((v) => v <= 0)) {
      return 'Enter percentages for at least one member';
    }
    
    if ((total - 100.0).abs() > 0.1) {
      if (remaining > 0) {
        return 'Remaining: ${remaining.toStringAsFixed(1)}% (must equal 0%)';
      } else {
        return 'Over by: ${(-remaining).toStringAsFixed(1)}% (must equal 100%)';
      }
    }
    
    return null;
  }

  /// Calculate amount for a given percentage
  double _calculateAmount(double percentage) {
    return (widget.wizardData.amount * percentage) / 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPercentage = _calculateTotalPercentage();
    final remainingPercentage = _calculateRemainingPercentage();
    final isValid = _isSplitValid();
    final errorMessage = _getValidationError();

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
                'Assign Percentages',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              // Total percentage indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${totalPercentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isValid
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Remaining percentage indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${remainingPercentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: remainingPercentage.abs() <= 0.1
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              
              // Validation error message
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
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
                          errorMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Member list with percentage inputs
        Expanded(
          child: widget.groupMembers.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: widget.groupMembers.length,
                  itemBuilder: (context, index) {
                    final member = widget.groupMembers[index];
                    final memberId = member.id.toString();
                    final percentage = _percentages[memberId] ?? 0.0;
                    final amount = _calculateAmount(percentage);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Member avatar
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                member.initials,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Member name and amount
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.displayName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (percentage > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${amount.toStringAsFixed(2)}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Percentage input
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _controllers[memberId],
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  suffixText: '%',
                                  hintText: '0',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                ),
                                textAlign: TextAlign.right,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
