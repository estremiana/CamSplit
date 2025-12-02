import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/api_service.dart';
import '../../utils/split_logic.dart';
import 'models/expense_wizard_data.dart';
import 'step_amount_page.dart';
import 'step_details_page.dart';
import 'step_split_page.dart';

class ExpenseCreationWizard extends StatefulWidget {
  final int? groupId; // Optional pre-selected group

  const ExpenseCreationWizard({
    Key? key,
    this.groupId,
  }) : super(key: key);

  @override
  State<ExpenseCreationWizard> createState() => _ExpenseCreationWizardState();
}

class _ExpenseCreationWizardState extends State<ExpenseCreationWizard> {
  int _currentStep = 0;
  late ExpenseWizardData _wizardData;

  @override
  void initState() {
    super.initState();
    _wizardData = ExpenseWizardData(
      groupId: widget.groupId?.toString(),
      date: DateTime.now().toIso8601String().split('T')[0],
      category: 'Food & Dining',
    );
  }

  void _updateData(ExpenseWizardData newData) {
    debugPrint('🔍 [WIZARD] _updateData called - items count: ${newData.items.length}, splitType: ${newData.splitType}');
    debugPrint('🔍 [WIZARD] Previous items count: ${_wizardData.items.length}');
    if (_wizardData.items.isNotEmpty && newData.items.isEmpty) {
      debugPrint('⚠️ [WIZARD] WARNING: Items were lost! Previous had ${_wizardData.items.length} items, new has 0');
      debugPrint('⚠️ [WIZARD] Stack trace: ${StackTrace.current}');
    }
    setState(() {
      _wizardData = newData;
    });
    debugPrint('🔍 [WIZARD] After setState - _wizardData.items count: ${_wizardData.items.length}');
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    if (!_wizardData.validateStep3()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all required fields before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      // Show loading state
    });

    try {
      // Transform wizard data to API format
      final expenseData = await _transformToApiFormat(_wizardData);

      // Call API
      final response = await ApiService.instance.createExpense(expenseData);

      if (mounted) {
        Navigator.of(context).pop({
          'success': true,
          'expense': response['data'],
        });
      }
    } catch (e) {
      debugPrint('Error creating expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _transformToApiFormat(ExpenseWizardData data) async {
    final expenseData = <String, dynamic>{
      'title': data.title.isNotEmpty ? data.title : 'Expense',
      'total_amount': data.amount,
      'currency': 'EUR', // TODO: Get from group
      'date': data.date,
      'category': data.category.isNotEmpty ? data.category : 'Other',
      'group_id': int.parse(data.groupId!),
      'split_type': _getSplitTypeString(data.splitType),
      'payers': [
        {
          'group_member_id': int.parse(data.payerId!),
          'amount_paid': data.amount,
          'payment_method': 'unknown',
        }
      ],
      'splits': _buildSplits(data),
    };

    // Add items if in items mode
    if (data.splitType == SplitType.items && data.items.isNotEmpty) {
      expenseData['items'] = data.items.map((item) {
        // Transform assignments from map to array format
        // Each member gets their own assignment record
        final assignments = <Map<String, dynamic>>[];
        final costs = SplitLogic.calculateItemCosts(item);
        
        item.assignments.forEach((memberId, qty) {
          if (qty > 0) {
            final totalPrice = costs[memberId] ?? (qty * item.unitPrice);
            
            assignments.add({
              'user_ids': [int.parse(memberId)],
              'quantity': qty,
              'unit_price': item.unitPrice,
              'total_price': totalPrice,
              'people_count': 1,
              'price_per_person': totalPrice,
              'assignment_type': item.isCustomSplit ? 'advanced' : 'simple',
            });
          }
        });

        return {
          'name': item.name,
          'unit_price': item.unitPrice,
          'max_quantity': item.quantity,
          'assignments': assignments,
        };
      }).toList();
    }

    return expenseData;
  }

  String _getSplitTypeString(SplitType type) {
    switch (type) {
      case SplitType.equal:
        return 'equal';
      case SplitType.percentage:
        return 'percentage';
      case SplitType.custom:
        return 'custom';
      case SplitType.items:
        return 'itemized';
    }
  }

  List<Map<String, dynamic>> _buildSplits(ExpenseWizardData data) {
    if (data.splitType == SplitType.items) {
      // For items mode, calculate splits from item assignments
      // Sum up the total amount owed by each member based on their item assignments
      final Map<String, double> memberAmounts = {};
      
      for (var item in data.items) {
        final costs = SplitLogic.calculateItemCosts(item);
        costs.forEach((memberId, cost) {
          memberAmounts[memberId] = (memberAmounts[memberId] ?? 0.0) + cost;
        });
      }
      
      // Convert to splits array format
      return memberAmounts.entries.map((entry) {
        return {
          'group_member_id': int.parse(entry.key),
          'amount_owed': entry.value,
        };
      }).toList();
    }

    return data.involvedMembers.map((memberId) {
      double amount = 0.0;
      
      if (data.splitType == SplitType.equal) {
        amount = data.amount / data.involvedMembers.length;
      } else if (data.splitType == SplitType.percentage) {
        final percentage = data.splitDetails[memberId] ?? 0.0;
        amount = (data.amount * percentage) / 100.0;
      } else {
        amount = data.splitDetails[memberId] ?? 0.0;
      }

      return {
        'group_member_id': int.parse(memberId),
        'amount_owed': amount,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Container(
              height: 2,
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 3,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
              ),
            ),
            // Page content
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  StepAmountPage(
                    data: _wizardData,
                    onDataChanged: _updateData,
                    onNext: _nextStep,
                    onCancel: _cancel,
                  ),
                  StepDetailsPage(
                    data: _wizardData,
                    onDataChanged: _updateData,
                    onNext: _nextStep,
                    onBack: _previousStep,
                  ),
                  StepSplitPage(
                    data: _wizardData,
                    onDataChanged: _updateData,
                    onBack: _previousStep,
                    onSubmit: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

