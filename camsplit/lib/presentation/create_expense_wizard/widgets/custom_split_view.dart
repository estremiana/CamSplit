import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wizard_expense_data.dart';
import '../../../models/group_member.dart';

/// View for Custom split mode
/// Displays amount input fields for each member to enter their exact amount
/// Calculates remaining amount and validates sum = total
class CustomSplitView extends StatefulWidget {
  final WizardExpenseData wizardData;
  final List<GroupMember> groupMembers;
  final Function(WizardExpenseData) onDataChanged;

  const CustomSplitView({
    super.key,
    required this.wizardData,
    required this.groupMembers,
    required this.onDataChanged,
  });

  @override
  State<CustomSplitView> createState() => _CustomSplitViewState();
}

class _CustomSplitViewState extends State<CustomSplitView> {
  late Map<String, TextEditingController> _controllers;
  late Map<String, double> _amounts;

  @override
  void initState() {
    super.initState();
    _amounts = Map<String, double>.from(widget.wizardData.splitDetails);
    _controllers = {};
    
    // Initialize controllers for each member
    for (final member in widget.groupMembers) {
      final memberId = member.id.toString();
      final amount = _amounts[memberId] ?? 0.0;
      _controllers[memberId] = TextEditingController(
        text: amount > 0 ? amount.toStringAsFixed(2) : '',
      );
      
      // Add listener to update amounts when text changes
      _controllers[memberId]!.addListener(() {
        _handleAmountChange(memberId);
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

  /// Handle amount input change
  void _handleAmountChange(String memberId) {
    final text = _controllers[memberId]!.text;
    final value = double.tryParse(text) ?? 0.0;
    
    setState(() {
      _amounts[memberId] = value;
    });
    
    _updateWizardData();
  }

  /// Update wizard data with current amounts
  void _updateWizardData() {
    // Only include members with non-zero amounts
    final nonZeroAmounts = Map<String, double>.from(_amounts)
      ..removeWhere((key, value) => value <= 0);
    
    widget.onDataChanged(
      widget.wizardData.copyWith(
        splitDetails: nonZeroAmounts,
      ),
    );
  }

  /// Calculate total amount
  double _calculateTotalAmount() {
    return _amounts.values.fold(0.0, (sum, amt) => sum + amt);
  }

  /// Calculate remaining amount
  double _calculateRemainingAmount() {
    return widget.wizardData.amount - _calculateTotalAmount();
  }

  /// Check if split is valid (sum = total within tolerance)
  bool _isSplitValid() {
    final total = _calculateTotalAmount();
    return (total - widget.wizardData.amount).abs() <= 0.05 && 
           _amounts.values.any((v) => v > 0);
  }

  /// Get validation error message
  String? _getValidationError() {
    final total = _calculateTotalAmount();
    final remaining = _calculateRemainingAmount();
    
    if (_amounts.values.every((v) => v <= 0)) {
      return 'Enter amounts for at least one member';
    }
    
    if ((total - widget.wizardData.amount).abs() > 0.05) {
      if (remaining > 0) {
        return 'Remaining: \$${remaining.toStringAsFixed(2)} (must equal \$0.00)';
      } else {
        return 'Over by: \$${(-remaining).toStringAsFixed(2)} (must equal total)';
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalAmount = _calculateTotalAmount();
    final remainingAmount = _calculateRemainingAmount();
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
                'Assign Custom Amounts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total expense: \$${widget.wizardData.amount.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              
              // Total amount indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assigned:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '\$${totalAmount.toStringAsFixed(2)}',
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
              
              // Remaining amount indicator
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
                    '\$${remainingAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: remainingAmount.abs() <= 0.05
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

        // Member list with amount inputs
        Expanded(
          child: widget.groupMembers.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: widget.groupMembers.length,
                  itemBuilder: (context, index) {
                    final member = widget.groupMembers[index];
                    final memberId = member.id.toString();
                    final amount = _amounts[memberId] ?? 0.0;

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
                            
                            // Member name
                            Expanded(
                              child: Text(
                                member.displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Amount input
                            SizedBox(
                              width: 120,
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
                                  prefixText: '\$',
                                  hintText: '0.00',
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
