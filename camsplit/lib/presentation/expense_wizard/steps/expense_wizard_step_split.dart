import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/receipt_item.dart';
import '../expense_wizard.dart'; // For SplitType enum
import '../widgets/item_card_widget.dart';
import '../widgets/advanced_split_modal.dart';

class ExpenseWizardStepSplit extends StatefulWidget {
  final double amount;
  final SplitType splitType;
  final Map<String, double> splitDetails;
  final List<String> involvedMembers;
  final List<ReceiptItem> items;
  final List<Map<String, dynamic>> groupMembers;
  final Function(Map<String, dynamic>) onSplitChanged;
  final VoidCallback? onSubmit;
  final VoidCallback? onBack;

  const ExpenseWizardStepSplit({
    super.key,
    required this.amount,
    required this.splitType,
    required this.splitDetails,
    required this.involvedMembers,
    required this.items,
    required this.groupMembers,
    required this.onSplitChanged,
    this.onSubmit,
    this.onBack,
  });

  @override
  State<ExpenseWizardStepSplit> createState() => _ExpenseWizardStepSplitState();
}

class _ExpenseWizardStepSplitState extends State<ExpenseWizardStepSplit> {
  SplitType _currentSplitType = SplitType.equal;
  bool _isEditingItems = false;
  String? _expandedItemId;
  ReceiptItem? _activeModalItem;
  final Map<String, TextEditingController> _amountControllers = {};

  @override
  void initState() {
    super.initState();
    _currentSplitType = widget.splitType;
    
    // Initialize controllers for existing members
    for (final member in widget.groupMembers) {
      final memberId = member['id'].toString();
      final value = widget.splitDetails[memberId] ?? 0.0;
      _amountControllers[memberId] = TextEditingController(
        text: value > 0
            ? value.toStringAsFixed(
                _currentSplitType == SplitType.percentage ? 1 : 2,
              )
            : '',
      );
    }
    
    // If items exist, default to itemized mode
    if (widget.items.isNotEmpty && _currentSplitType != SplitType.itemized) {
      _currentSplitType = SplitType.itemized;
      widget.onSplitChanged({'splitType': SplitType.itemized});
    }
  }

  @override
  void didUpdateWidget(ExpenseWizardStepSplit oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync local state with widget props
    if (widget.splitType != _currentSplitType) {
      setState(() {
        _currentSplitType = widget.splitType;
      });
    }
    
    // Initialize controllers for new members
    for (final member in widget.groupMembers) {
      final memberId = member['id'].toString();
      if (!_amountControllers.containsKey(memberId)) {
        final value = widget.splitDetails[memberId] ?? 0.0;
        _amountControllers[memberId] = TextEditingController(
          text: value > 0
              ? value.toStringAsFixed(
                  _currentSplitType == SplitType.percentage ? 1 : 2,
                )
              : '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSplitTypeChange(SplitType type) {
    if (type == _currentSplitType) return;
    
    setState(() {
      _currentSplitType = type;
    });

    final updates = <String, dynamic>{'splitType': type};

    // Initialize defaults for manual modes
    if (type == SplitType.percentage || type == SplitType.custom) {
      final involved = widget.involvedMembers.isNotEmpty 
          ? widget.involvedMembers 
          : widget.groupMembers.map((m) => m['id'].toString()).toList();
      final count = involved.length;
      final newDetails = <String, double>{};

      if (type == SplitType.percentage) {
        final base = (100 / count).floor();
        final remainder = 100 - (base * count);
        for (int i = 0; i < involved.length; i++) {
          newDetails[involved[i]] = (base + (i < remainder ? 1 : 0)).toDouble();
        }
      } else {
        // Custom: Distribute amount evenly
        final base = widget.amount / count;
        for (final id in involved) {
          newDetails[id] = double.parse(base.toStringAsFixed(2));
        }
      }
      updates['splitDetails'] = newDetails;
      updates['involvedMembers'] = involved;
    }

    widget.onSplitChanged(updates);
  }

  void _handleItemAssignment(String itemId, Map<String, double> assignments, {bool isAdvanced = false}) {
    final updatedItems = widget.items.map((item) {
      if (item.id == itemId) {
        return item.updateAssignments(assignments, isAdvanced: isAdvanced);
      }
      return item;
    }).toList();

    widget.onSplitChanged({'items': updatedItems});
  }

  void _handleItemUpdate(String itemId, ReceiptItem updatedItem) {
    final updatedItems = widget.items.map((item) {
      if (item.id == itemId) {
        return updatedItem;
      }
      return item;
    }).toList();

    widget.onSplitChanged({'items': updatedItems});
  }

  void _handleItemDelete(String itemId) {
    final updatedItems = widget.items.where((item) => item.id != itemId).toList();
    widget.onSplitChanged({'items': updatedItems});
  }

  void _handleItemAdd() {
    final newItem = ReceiptItem(
      id: 'manual-${DateTime.now().millisecondsSinceEpoch}',
      name: 'New Item',
      unitPrice: 0,
      quantity: 1,
      totalPrice: 0,
    );
    widget.onSplitChanged({'items': [...widget.items, newItem]});
  }

  bool _isSplitValid() {
    if (_currentSplitType == SplitType.itemized) {
      final unassigned = widget.items.fold(0.0, (sum, item) => 
        sum + item.getRemainingQuantity() * item.unitPrice);
      return unassigned < 0.05;
    }
    if (_currentSplitType == SplitType.percentage) {
      final total = widget.splitDetails.values.fold(0.0, (sum, val) => sum + val);
      return (100 - total).abs() < 0.1;
    }
    if (_currentSplitType == SplitType.custom) {
      final total = widget.splitDetails.values.fold(0.0, (sum, val) => sum + val);
      return (widget.amount - total).abs() < 0.05;
    }
    return true; // Equal is always valid
  }

  double _getUnassignedAmount() {
    if (_currentSplitType != SplitType.itemized) return 0.0;
    return widget.items.fold(0.0, (sum, item) => 
      sum + item.getRemainingQuantity() * item.unitPrice);
  }

  double _getItemizedTotalForMember(String memberId) {
    return widget.items.fold(0.0, (sum, item) => 
      sum + item.getAssignedPriceForMember(memberId));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: widget.onBack,
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                  ),
                ),
              ),
              Text(
                '3 of 3',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  color: Colors.grey[900],
                ),
              ),
              if (_currentSplitType == SplitType.itemized && !_isEditingItems)
                TextButton(
                  onPressed: () => setState(() => _isEditingItems = true),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 16, color: AppTheme.lightTheme.primaryColor),
                      SizedBox(width: 1.w),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: AppTheme.lightTheme.primaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_currentSplitType == SplitType.itemized && _isEditingItems)
                TextButton(
                  onPressed: () {
                    setState(() => _isEditingItems = false);
                    // Recalculate total from items
                    final newTotal = widget.items.fold(0.0, (sum, item) => sum + item.totalPrice);
                    widget.onSplitChanged({'amount': newTotal});
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 16, color: Colors.green),
                      SizedBox(width: 1.w),
                      Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(width: 20.w),
            ],
          ),

          SizedBox(height: 2.h),

          // Title and subtitle
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Split Options',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _currentSplitType == SplitType.itemized
                      ? (_isEditingItems 
                          ? 'Modify items, prices and quantities' 
                          : 'Tap items to assign')
                      : 'How should this €${widget.amount.toStringAsFixed(2)} be shared?',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Tabs (only show if not editing items)
          if (!_isEditingItems)
            Container(
              padding: EdgeInsets.all(0.5.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab('Equal', SplitType.equal, Icons.equalizer),
                  _buildTab('%', SplitType.percentage, Icons.percent),
                  _buildTab('Custom', SplitType.custom, Icons.attach_money),
                  _buildTab('Items', SplitType.itemized, Icons.receipt),
                ],
              ),
            ),

          SizedBox(height: 2.h),

          // Content
          Expanded(
            child: _currentSplitType == SplitType.itemized
                ? _buildItemizedView()
                : _buildStandardSplitView(),
          ),

          // Footer with Create button
          if (!_isEditingItems && _activeModalItem == null)
            Container(
              padding: EdgeInsets.only(top: 2.h),
              child: Column(
                children: [
                  if (!_isSplitValid())
                    Container(
                      margin: EdgeInsets.only(bottom: 1.h),
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red[700], size: 16),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              _currentSplitType == SplitType.itemized
                                  ? 'Assign all items before continuing'
                                  : 'Total mismatch. Adjust ${_currentSplitType == SplitType.percentage ? '%' : 'amount'} to match total.',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSplitValid() ? widget.onSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSplitValid()
                            ? AppTheme.lightTheme.primaryColor
                            : Colors.grey[400],
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 2.w),
                          Text(
                            'Create Expense',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 2.h),
        ],
      ),
    ),
        // Advanced Split Modal
        if (_activeModalItem != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _activeModalItem = null),
              child: Container(
                color: Colors.black.withOpacity(0.25),
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping modal
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AdvancedSplitModal(
                      item: _activeModalItem!,
                      groupMembers: widget.groupMembers,
                      onAssignmentChanged: (assignments, {bool isAdvanced = true}) {
                        _handleItemAssignment(
                          _activeModalItem!.id,
                          assignments,
                          isAdvanced: isAdvanced,
                        );
                        // Update the active item
                        final updatedItem = widget.items.firstWhere(
                          (item) => item.id == _activeModalItem!.id,
                        );
                        setState(() {
                          _activeModalItem = updatedItem;
                        });
                      },
                      onClose: () => setState(() => _activeModalItem = null),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTab(String label, SplitType type, IconData icon) {
    final isSelected = _currentSplitType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleSplitTypeChange(type),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? AppTheme.lightTheme.primaryColor
                    : Colors.grey[500],
              ),
              SizedBox(width: 1.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemizedView() {
    if (widget.items.isEmpty) {
      return Center(
        child: Text(
          'No items to split. Go back to scan a receipt or add items manually.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.items.length + (_isEditingItems ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isEditingItems && index == widget.items.length) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: ElevatedButton.icon(
                    onPressed: _handleItemAdd,
                    icon: Icon(Icons.add),
                    label: Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                );
              }

              final item = widget.items[index];
              return ItemCardWidget(
                item: item,
                groupMembers: widget.groupMembers,
                isExpanded: _expandedItemId == item.id,
                isEditing: _isEditingItems,
                onExpandedChanged: (expanded) {
                  setState(() {
                    _expandedItemId = expanded ? item.id : null;
                  });
                },
                onAssignmentChanged: (assignments, {bool isAdvanced = false}) {
                  _handleItemAssignment(item.id, assignments, isAdvanced: isAdvanced);
                },
                onItemUpdated: (updatedItem) {
                  _handleItemUpdate(item.id, updatedItem);
                },
                onItemDeleted: () {
                  _handleItemDelete(item.id);
                },
                onAdvancedSplit: () {
                  setState(() {
                    _activeModalItem = item;
                    _expandedItemId = null; // Close quick split when opening advanced
                  });
                },
              );
            },
          ),
        ),

        // Summary
        if (!_isEditingItems)
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUMMARY',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 1.h),
                ...widget.groupMembers.map((member) {
                  final total = _getItemizedTotalForMember(member['id'].toString());
                  if (total < 0.01) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(bottom: 0.5.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          member['name'] ?? 'Unknown',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        Text(
                          '€${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (_getUnassignedAmount() > 0.01)
                  Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Unassigned',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red[600],
                          ),
                        ),
                        Text(
                          '€${_getUnassignedAmount().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStandardSplitView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Remaining amount indicator (for Percentage and Custom)
          if (_currentSplitType == SplitType.percentage || _currentSplitType == SplitType.custom)
            Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: _getRemainingAmount() < 0.1
                    ? Colors.green[50]
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRemainingAmount() < 0.1
                      ? Colors.green[200]!
                      : Colors.red[200]!,
                ),
              ),
              child: Text(
                _currentSplitType == SplitType.percentage
                    ? '${_getRemainingAmount().toStringAsFixed(1)}% remaining'
                    : '€${_getRemainingAmount().toStringAsFixed(2)} remaining',
                style: TextStyle(
                  color: _getRemainingAmount() < 0.1
                      ? Colors.green[700]
                      : Colors.red[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 13.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Member list
          ...widget.groupMembers.map((member) {
            final memberId = member['id'].toString();
            final isSelected = _currentSplitType == SplitType.equal
                ? widget.involvedMembers.contains(memberId)
                : widget.splitDetails.containsKey(memberId) &&
                    widget.splitDetails[memberId]! > 0;

            return Container(
              margin: EdgeInsets.only(bottom: 1.5.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor.withOpacity(0.3)
                      : Colors.transparent,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppTheme.lightTheme.primaryColor.withOpacity(0.1)
                          : Colors.grey[200],
                    ),
                    child: Center(
                      child: Text(
                        member['avatar'] ?? '?',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.lightTheme.primaryColor
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                            color: isSelected
                                ? Colors.grey[900]
                                : Colors.grey[500],
                          ),
                        ),
                        if (isSelected && _currentSplitType == SplitType.equal)
                          Text(
                            'Pays €${_getEqualAmount(memberId).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppTheme.lightTheme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Toggle/Input
                  if (_currentSplitType == SplitType.equal)
                    InkWell(
                      onTap: () {
                        final currentInvolved = [...widget.involvedMembers];
                        if (currentInvolved.contains(memberId)) {
                          if (currentInvolved.length > 1) {
                            widget.onSplitChanged({
                              'involvedMembers': currentInvolved
                                  .where((id) => id != memberId)
                                  .toList(),
                            });
                          }
                        } else {
                          widget.onSplitChanged({
                            'involvedMembers': [...currentInvolved, memberId],
                          });
                        }
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.lightTheme.primaryColor
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          color: isSelected
                              ? AppTheme.lightTheme.primaryColor
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    )
                  else
                    SizedBox(
                      width: 20.w,
                      child: TextField(
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isSelected
                                  ? AppTheme.lightTheme.primaryColor
                                  : Colors.grey[300]!,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isSelected
                                  ? AppTheme.lightTheme.primaryColor
                                  : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppTheme.lightTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 1.h,
                          ),
                          suffixText: _currentSplitType == SplitType.percentage
                              ? '%'
                              : '€',
                          suffixStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12.sp,
                          ),
                        ),
                        enabled: isSelected,
                        controller: _amountControllers.putIfAbsent(
                          memberId,
                          () {
                            final value = widget.splitDetails[memberId] ?? 0.0;
                            return TextEditingController(
                              text: value > 0
                                  ? value.toStringAsFixed(
                                      _currentSplitType == SplitType.percentage ? 1 : 2,
                                    )
                                  : '',
                            );
                          },
                        ),
                        onChanged: (value) {
                          final numValue = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                          final newDetails = Map<String, double>.from(
                            widget.splitDetails,
                          );
                          if (numValue > 0) {
                            newDetails[memberId] = numValue;
                          } else {
                            newDetails.remove(memberId);
                          }
                          widget.onSplitChanged({'splitDetails': newDetails});
                        },
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  double _getRemainingAmount() {
    if (_currentSplitType == SplitType.percentage) {
      final total = widget.splitDetails.values.fold(0.0, (sum, val) => sum + val);
      return 100 - total;
    } else if (_currentSplitType == SplitType.custom) {
      final total = widget.splitDetails.values.fold(0.0, (sum, val) => sum + val);
      return widget.amount - total;
    }
    return 0.0;
  }

  double _getEqualAmount(String memberId) {
    if (!widget.involvedMembers.contains(memberId)) return 0.0;
    if (widget.involvedMembers.isEmpty) return 0.0;
    return widget.amount / widget.involvedMembers.length;
  }
}

