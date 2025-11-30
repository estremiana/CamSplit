import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../models/expense_detail_model.dart';
import '../../models/group_member.dart';
import '../../services/expense_detail_service.dart';
import '../../services/group_service.dart';
import '../../services/api_service.dart';
import '../../services/currency_service.dart';
import 'widgets/expense_summary_header.dart';
import 'widgets/expense_details_card.dart';
import 'widgets/split_breakdown_section.dart';
import '../expense_split_edit/expense_split_edit_page.dart';
import '../../presentation/expense_creation_wizard/models/expense_wizard_data.dart';
import '../../presentation/expense_creation_wizard/models/receipt_item.dart';

class ExpenseDetailSummaryPage extends StatefulWidget {
  final int expenseId;

  const ExpenseDetailSummaryPage({
    Key? key,
    required this.expenseId,
  }) : super(key: key);

  @override
  State<ExpenseDetailSummaryPage> createState() => _ExpenseDetailSummaryPageState();
}

class _ExpenseDetailSummaryPageState extends State<ExpenseDetailSummaryPage> {
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSaving = false;
  ExpenseDetailModel? _expense;
  ExpenseDetailModel? _originalExpense;
  String? _errorMessage;
  List<GroupMember> _groupMembers = [];
  bool _isLoadingMembers = false;

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  DateTime? _selectedDate;
  int? _selectedPayerId;

  @override
  void initState() {
    super.initState();
    _loadExpenseData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenseData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final basicExpense = await ExpenseDetailService.getExpenseById(widget.expenseId);
      final groupId = int.tryParse(basicExpense.groupId);
      
      if (groupId == null || groupId <= 0) {
        throw ExpenseDetailServiceException('Invalid group ID for expense');
      }
      
      final expense = await ExpenseDetailService.getExpenseWithMemberDetails(widget.expenseId, groupId);
      
      // Load group members
      await _loadGroupMembers(groupId);
      
      setState(() {
        _expense = expense;
        _originalExpense = expense;
        _isLoading = false;
      });
      
      _populateFormFields();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadGroupMembers(int groupId) async {
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final group = await GroupService.getGroupWithMembers(groupId.toString());
      if (group != null && mounted) {
        setState(() {
          _groupMembers = group.members;
          _isLoadingMembers = false;
        });
      } else {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading group members: $e');
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    }
  }

  void _populateFormFields() {
    if (_expense == null) return;

    _titleController.text = _expense!.title;
    _amountController.text = _expense!.amount.toStringAsFixed(2);
    _categoryController.text = _expense!.category;
    _selectedDate = _expense!.date;
    _selectedPayerId = _expense!.payerId;
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        // Cancel - restore original values
        if (_originalExpense != null) {
          _expense = _originalExpense;
          _populateFormFields();
        }
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_expense == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final newAmount = double.tryParse(_amountController.text) ?? _expense!.amount;
      final newTitle = _titleController.text.trim();
      final newCategory = _categoryController.text.trim();
      final newDate = _selectedDate ?? _expense!.date;
      final newPayerId = _selectedPayerId ?? _expense!.payerId;

      // Create updated expense
      final updatedExpense = _expense!.copyWith(
        title: newTitle,
        amount: newAmount,
        category: newCategory,
        date: newDate,
        payerId: newPayerId,
        updatedAt: DateTime.now(),
      );

      // Create payer data
      final payerData = [
        {
          'group_member_id': newPayerId,
          'amount_paid': newAmount,
          'payment_method': 'unknown',
          'payment_date': DateTime.now().toIso8601String(),
        }
      ];

      // Create update request
      final updateRequest = ExpenseUpdateRequest(
        expenseId: updatedExpense.id,
        groupId: int.tryParse(updatedExpense.groupId) ?? 0,
        title: updatedExpense.title,
        amount: updatedExpense.amount,
        currency: updatedExpense.currency,
        date: updatedExpense.date,
        category: updatedExpense.category,
        notes: updatedExpense.notes,
        splitType: updatedExpense.splitType,
        participantAmounts: updatedExpense.participantAmounts,
        payers: payerData,
      );

      // Save expense
      final savedExpense = await ExpenseDetailService.updateExpense(updateRequest);

      setState(() {
        _expense = savedExpense;
        _originalExpense = savedExpense;
        _isSaving = false;
        _isEditMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Expense updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _navigateToEditSplit() async {
    if (_expense == null) return;

    // Convert expense to ExpenseWizardData
    final wizardData = await _convertExpenseToWizardData();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseSplitEditPage(
          expenseId: widget.expenseId,
          initialData: wizardData,
        ),
      ),
    );

    // If split was updated, reload expense data
    if (result == true && mounted) {
      await _loadExpenseData();
    }
  }

  Future<ExpenseWizardData> _convertExpenseToWizardData() async {
    if (_expense == null) {
      throw Exception('Expense is null');
    }

    // Convert split type
    SplitType splitType;
    switch (_expense!.splitType) {
      case 'equal':
        splitType = SplitType.equal;
        break;
      case 'percentage':
        splitType = SplitType.percentage;
        break;
      case 'custom':
        splitType = SplitType.custom;
        break;
      case 'itemized':
        splitType = SplitType.items;
        break;
      default:
        splitType = SplitType.equal;
    }

    // Convert split details
    Map<String, double> splitDetails = {};
    List<String> involvedMembers = [];

    if (splitType == SplitType.items) {
      // Load items for itemized expenses
      final items = await _loadExpenseItems();
      return ExpenseWizardData(
        amount: _expense!.amount,
        title: _expense!.title,
        date: _expense!.date.toIso8601String().split('T')[0],
        category: _expense!.category,
        payerId: _expense!.payerId.toString(),
        groupId: _expense!.groupId,
        splitType: splitType,
        items: items,
      );
    } else {
      // Convert participant amounts to split details
      for (var participant in _expense!.participantAmounts) {
        if (participant.groupMemberId != null) {
          final memberId = participant.groupMemberId.toString();
          involvedMembers.add(memberId);
          
          if (splitType == SplitType.percentage && participant.percentage != null) {
            splitDetails[memberId] = participant.percentage!;
          } else if (splitType == SplitType.custom) {
            splitDetails[memberId] = participant.amount;
          }
        }
      }
    }

    return ExpenseWizardData(
      amount: _expense!.amount,
      title: _expense!.title,
      date: _expense!.date.toIso8601String().split('T')[0],
      category: _expense!.category,
      payerId: _expense!.payerId.toString(),
      groupId: _expense!.groupId,
      splitType: splitType,
      splitDetails: splitDetails,
      involvedMembers: involvedMembers,
    );
  }

  Future<List<ReceiptItem>> _loadExpenseItems() async {
    try {
      final response = await ApiService.instance.getExpenseItems(widget.expenseId.toString());
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final itemsData = data['items'] as List<dynamic>? ?? [];
        
        return itemsData.map((itemJson) {
          // Convert backend item format to ReceiptItem
          final itemId = itemJson['id'].toString();
          final name = itemJson['name'] ?? '';
          final unitPrice = (itemJson['unit_price'] ?? 0.0).toDouble();
          final quantity = (itemJson['max_quantity'] ?? itemJson['quantity'] ?? 1.0).toDouble();
          final price = unitPrice * quantity;
          
          // Convert assignments
          Map<String, double> assignments = {};
          final assignmentsData = itemJson['assignments'] as List<dynamic>? ?? [];
          
          for (var assignment in assignmentsData) {
            final assignedUsers = assignment['assigned_users'] as List<dynamic>? ?? [];
            for (var user in assignedUsers) {
              final memberId = user['group_member_id'].toString();
              final qty = (assignment['quantity'] ?? 0.0).toDouble();
              assignments[memberId] = (assignments[memberId] ?? 0.0) + qty;
            }
          }
          
          return ReceiptItem(
            id: itemId,
            name: name,
            price: price,
            quantity: quantity,
            unitPrice: unitPrice,
            assignments: assignments,
            isCustomSplit: assignments.isNotEmpty && assignments.values.any((qty) => qty != quantity / assignments.length),
          );
        }).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error loading expense items: $e');
      return [];
    }
  }

  Map<String, double> _getMemberTotals() {
    if (_expense == null) return {};
    
    final totals = <String, double>{};
    
    if (_expense!.splitType == 'itemized') {
      // For itemized, we'd need to load items - for now return participant amounts
      for (var participant in _expense!.participantAmounts) {
        if (participant.groupMemberId != null) {
          totals[participant.groupMemberId.toString()] = participant.amount;
        }
      }
    } else {
      // For other split types, use participant amounts
      for (var participant in _expense!.participantAmounts) {
        if (participant.groupMemberId != null) {
          totals[participant.groupMemberId.toString()] = participant.amount;
        }
      }
    }
    
    return totals;
  }

  String _getSplitTypeDisplayName() {
    if (_expense == null) return 'Equal';
    
    switch (_expense!.splitType) {
      case 'equal':
        return 'Equal';
      case 'percentage':
        return 'Percentage';
      case 'custom':
        return 'Custom';
      case 'itemized':
        return 'Itemized';
      default:
        return 'Equal';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_expense == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Expense Details'),
        ),
        body: Center(
          child: Text(_errorMessage ?? 'Expense not found'),
        ),
      );
    }

    final memberTotals = _getMemberTotals();
    final isItemized = _expense!.splitType == 'itemized';

    return PopScope(
      canPop: !_isEditMode,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isEditMode) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Discard Changes?'),
              content: Text('You have unsaved changes. Are you sure you want to leave?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Stay'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Discard'),
                ),
              ],
            ),
          );
          if (shouldPop == true && mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              ExpenseSummaryHeader(
                isEditMode: _isEditMode,
                isSaving: _isSaving,
                onEditPressed: _toggleEditMode,
                onSavePressed: _saveChanges,
                onBackPressed: () {
                  if (_isEditMode) {
                    _toggleEditMode();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount and Title
                      _buildAmountAndTitle(),
                      
                      SizedBox(height: 3.h),
                      
                      // Details Card
                      ExpenseDetailsCard(
                        expense: _expense!,
                        isEditMode: _isEditMode,
                        titleController: _titleController,
                        amountController: _amountController,
                        categoryController: _categoryController,
                        selectedDate: _selectedDate,
                        selectedPayerId: _selectedPayerId,
                        groupMembers: _groupMembers,
                        onDateChanged: (date) => setState(() => _selectedDate = date),
                        onPayerChanged: (payerId) => setState(() => _selectedPayerId = payerId),
                        onCategoryChanged: (category) => setState(() {}),
                      ),
                      
                      SizedBox(height: 3.h),
                      
                      // Split Breakdown
                      SplitBreakdownSection(
                        splitType: _getSplitTypeDisplayName(),
                        memberTotals: memberTotals,
                        groupMembers: _groupMembers,
                        expense: _expense!,
                        onEditSplit: _navigateToEditSplit,
                      ),
                      
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountAndTitle() {
    return Column(
      children: [
        // Amount
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '€',
              style: TextStyle(
                fontSize: 24.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(width: 1.w),
            if (_isEditMode && _expense!.splitType != 'itemized')
              SizedBox(
                width: 40.w,
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryLight),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryLight),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryLight, width: 2),
                    ),
                  ),
                ),
              )
            else
              Text(
                _expense!.amount.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
          ],
        ),
        
        SizedBox(height: 1.h),
        
        // Title
        if (_isEditMode)
          SizedBox(
            width: double.infinity,
            child: TextField(
              controller: _titleController,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'Expense Title',
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryLight),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryLight),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primaryLight, width: 2),
                ),
              ),
            ),
          )
        else
          Text(
            _expense!.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryLight,
            ),
          ),
      ],
    );
  }
}

