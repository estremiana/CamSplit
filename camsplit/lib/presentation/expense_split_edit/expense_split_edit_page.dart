import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/expense_detail_service.dart';
import '../../services/api_service.dart';
import '../../utils/split_logic.dart';
import '../../presentation/expense_creation_wizard/models/expense_wizard_data.dart';
import '../../presentation/expense_creation_wizard/step_split_page.dart';

class ExpenseSplitEditPage extends StatefulWidget {
  final int expenseId;
  final ExpenseWizardData initialData;

  const ExpenseSplitEditPage({
    Key? key,
    required this.expenseId,
    required this.initialData,
  }) : super(key: key);

  @override
  State<ExpenseSplitEditPage> createState() => _ExpenseSplitEditPageState();
}

class _ExpenseSplitEditPageState extends State<ExpenseSplitEditPage> {
  late ExpenseWizardData _wizardData;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _wizardData = widget.initialData;
  }

  void _updateData(ExpenseWizardData newData) {
    setState(() {
      _wizardData = newData;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Convert wizard data to expense update format
      final updateData = await _convertWizardDataToUpdateFormat();

      // Update expense via API
      await _updateExpenseSplits(updateData);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save splits: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _convertWizardDataToUpdateFormat() async {
    // Build splits based on split type
    List<Map<String, dynamic>> splits = [];
    
    if (_wizardData.splitType == SplitType.items) {
      // For items, calculate splits from item assignments
      Map<String, double> memberAmounts = {};
      
      for (var item in _wizardData.items) {
        final costs = SplitLogic.calculateItemCosts(item);
        costs.forEach((memberId, cost) {
          memberAmounts[memberId] = (memberAmounts[memberId] ?? 0.0) + cost;
        });
      }
      
      splits = memberAmounts.entries.map((entry) {
        return {
          'group_member_id': int.parse(entry.key),
          'amount_owed': entry.value,
        };
      }).toList();
    } else if (_wizardData.splitType == SplitType.equal) {
      // For equal split
      final amountPerPerson = _wizardData.amount / _wizardData.involvedMembers.length;
      splits = _wizardData.involvedMembers.map((memberId) {
        return {
          'group_member_id': int.parse(memberId),
          'amount_owed': amountPerPerson,
        };
      }).toList();
    } else if (_wizardData.splitType == SplitType.percentage) {
      // For percentage split
      splits = _wizardData.splitDetails.entries.map((entry) {
        final percentage = entry.value;
        final amountOwed = _wizardData.amount * (percentage / 100.0);
        return {
          'group_member_id': int.parse(entry.key),
          'amount_owed': amountOwed,
          'percentage': percentage,
        };
      }).toList();
    } else if (_wizardData.splitType == SplitType.custom) {
      // For custom split
      splits = _wizardData.splitDetails.entries.map((entry) {
        return {
          'group_member_id': int.parse(entry.key),
          'amount_owed': entry.value,
        };
      }).toList();
    }

    // Get split type string
    String splitTypeString;
    switch (_wizardData.splitType) {
      case SplitType.equal:
        splitTypeString = 'equal';
        break;
      case SplitType.percentage:
        splitTypeString = 'percentage';
        break;
      case SplitType.custom:
        splitTypeString = 'custom';
        break;
      case SplitType.items:
        splitTypeString = 'itemized';
        break;
    }

    return {
      'split_type': splitTypeString,
      'splits': splits,
      'items': _wizardData.splitType == SplitType.items 
          ? _buildItemsData() 
          : null,
    };
  }

  List<Map<String, dynamic>> _buildItemsData() {
    return _wizardData.items.map((item) {
      List<Map<String, dynamic>> assignments = [];
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

  Future<void> _updateExpenseSplits(Map<String, dynamic> updateData) async {
    // First, get the current expense to get group ID
    final expense = await ExpenseDetailService.getExpenseById(widget.expenseId);
    final groupId = int.tryParse(expense.groupId);
    
    if (groupId == null) {
      throw Exception('Invalid group ID');
    }

    // If itemized, update items and assignments
    if (_wizardData.splitType == SplitType.items && updateData['items'] != null) {
      // Delete existing items and assignments
      // Then create new ones
      // For now, we'll use a simplified approach - update via expense update endpoint
      final expenseUpdateData = {
        'split_type': updateData['split_type'],
        'total_amount': _wizardData.amount,
        // Include items data if backend supports it
      };
      
      await ApiService.instance.updateExpense(
        widget.expenseId.toString(),
        expenseUpdateData,
      );
    } else {
      // For non-itemized splits, update splits directly
      final expenseUpdateData = {
        'split_type': updateData['split_type'],
        'total_amount': _wizardData.amount,
        'participant_amounts': updateData['splits'].map((split) {
          return {
            'group_member_id': split['group_member_id'],
            'amount': split['amount_owed'],
            'percentage': split['percentage'],
          };
        }).toList(),
      };
      
      await ApiService.instance.updateExpense(
        widget.expenseId.toString(),
        expenseUpdateData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Split',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Split options content (reusing StepSplitPage)
          StepSplitPage(
            data: _wizardData,
            onDataChanged: _updateData,
            onBack: () => Navigator.pop(context),
            onSubmit: () => _saveChanges(), // Wrap in lambda to handle async
            hideWizardHeader: true, // Hide "3 of 3" and back button since we have AppBar
          ),
          
          // Save button overlay
          if (_isSaving)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

