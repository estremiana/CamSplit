import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/group_service.dart';
import '../../models/group_member.dart';
import 'models/expense_wizard_data.dart';
import 'models/receipt_item.dart';

class StepSplitPage extends StatefulWidget {
  final ExpenseWizardData data;
  final Function(ExpenseWizardData) onDataChanged;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const StepSplitPage({
    Key? key,
    required this.data,
    required this.onDataChanged,
    required this.onBack,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<StepSplitPage> createState() => _StepSplitPageState();
}

class _StepSplitPageState extends State<StepSplitPage> {
  List<GroupMember> _groupMembers = [];
  bool _isLoadingMembers = false;
  String? _expandedItemId;
  bool _isEditingItems = false;
  ReceiptItem? _activeModalItem;

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
    _initializeSplitType();
  }

  Future<void> _loadGroupMembers() async {
    if (widget.data.groupId == null || widget.data.groupId!.isEmpty) return;

    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final group = await GroupService.getGroupWithMembers(widget.data.groupId!);
      if (mounted && group != null) {
        setState(() {
          _groupMembers = group.members;
          _isLoadingMembers = false;
          
          // Initialize involved members if empty
          if (widget.data.involvedMembers.isEmpty) {
            widget.onDataChanged(
              widget.data.copyWith(
                involvedMembers: _groupMembers.map((m) => m.id.toString()).toList(),
              ),
            );
          }
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

  void _initializeSplitType() {
    // Initialize split details based on split type
    if (widget.data.splitType == SplitType.percentage || widget.data.splitType == SplitType.custom) {
      if (widget.data.splitDetails.isEmpty && widget.data.involvedMembers.isNotEmpty) {
        final involved = widget.data.involvedMembers;
        final count = involved.length;
        final newDetails = <String, double>{};

        if (widget.data.splitType == SplitType.percentage) {
          final base = (100 / count).floor();
          final remainder = 100 - (base * count);
          for (int i = 0; i < involved.length; i++) {
            newDetails[involved[i]] = (base + (i < remainder ? 1 : 0)).toDouble();
          }
        } else {
          // Custom: Distribute amount evenly
          final base = widget.data.amount / count;
          for (var id in involved) {
            newDetails[id] = double.parse(base.toStringAsFixed(2));
          }
        }

        widget.onDataChanged(
          widget.data.copyWith(splitDetails: newDetails),
        );
      }
    }
  }

  void _handleSplitTypeChange(SplitType type) {
    if (type == widget.data.splitType) return;

    final updates = <String, dynamic>{'splitType': type};

    // Initialize defaults for Manual Modes
    if (type == SplitType.percentage || type == SplitType.custom) {
      final involved = widget.data.involvedMembers.isNotEmpty
          ? widget.data.involvedMembers
          : _groupMembers.map((m) => m.id.toString()).toList();
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
        final base = widget.data.amount / count;
        for (var id in involved) {
          newDetails[id] = double.parse(base.toStringAsFixed(2));
        }
      }
      updates['splitDetails'] = newDetails;
      updates['involvedMembers'] = involved;
    }

    widget.onDataChanged(widget.data.copyWith(
      splitType: type,
      splitDetails: updates['splitDetails'] ?? widget.data.splitDetails,
      involvedMembers: updates['involvedMembers'] ?? widget.data.involvedMembers,
    ));
  }

  void _handleManualValueChange(String memberId, String valueStr) {
    final value = double.tryParse(valueStr.replaceAll(',', '.')) ?? 0.0;
    final newDetails = Map<String, double>.from(widget.data.splitDetails);
    newDetails[memberId] = value;
    widget.onDataChanged(widget.data.copyWith(splitDetails: newDetails));
  }

  void _toggleMemberEqual(String memberId) {
    final currentInvolved = List<String>.from(widget.data.involvedMembers);
    if (currentInvolved.contains(memberId)) {
      if (currentInvolved.length > 1) {
        currentInvolved.remove(memberId);
        widget.onDataChanged(widget.data.copyWith(involvedMembers: currentInvolved));
      }
    } else {
      currentInvolved.add(memberId);
      widget.onDataChanged(widget.data.copyWith(involvedMembers: currentInvolved));
    }
  }

  void _toggleMemberManual(String memberId) {
    final isIncluded = widget.data.involvedMembers.contains(memberId);
    var newInvolved = List<String>.from(widget.data.involvedMembers);
    var newDetails = Map<String, double>.from(widget.data.splitDetails);

    if (isIncluded) {
      newInvolved.remove(memberId);
      newDetails.remove(memberId);
    } else {
      newInvolved.add(memberId);
      newDetails[memberId] = 0.0;
    }

    widget.onDataChanged(
      widget.data.copyWith(
        involvedMembers: newInvolved,
        splitDetails: newDetails,
      ),
    );
  }

  double _getEqualAmount(String memberId) {
    if (widget.data.involvedMembers.contains(memberId)) {
      return widget.data.amount / widget.data.involvedMembers.length;
    }
    return 0.0;
  }

  double _getRemainingManual() {
    final total = widget.data.splitDetails.values.fold(0.0, (sum, val) => sum + val);
    if (widget.data.splitType == SplitType.percentage) {
      return 100 - total;
    } else if (widget.data.splitType == SplitType.custom) {
      return widget.data.amount - total;
    }
    return 0.0;
  }

  bool _isSplitValid() {
    if (widget.data.splitType == SplitType.items) {
      // Items validation will be handled separately
      return widget.data.items.every((item) => item.isFullyAssigned) && widget.data.items.isNotEmpty;
    } else if (widget.data.splitType == SplitType.percentage) {
      return _getRemainingManual().abs() < 0.1;
    } else if (widget.data.splitType == SplitType.custom) {
      return _getRemainingManual().abs() < 0.05;
    }
    return widget.data.involvedMembers.isNotEmpty; // Equal is always valid if at least one member
  }

  // Items mode methods
  void _handleQuickToggle(String memberId, ReceiptItem item) {
    if (item.isCustomSplit) return;

    final currentMemberIds = item.assignments.keys.toList();
    List<String> newMemberIds;

    if (currentMemberIds.contains(memberId)) {
      newMemberIds = currentMemberIds.where((id) => id != memberId).toList();
    } else {
      newMemberIds = [...currentMemberIds, memberId];
    }

    final newAssignments = <String, double>{};
    if (newMemberIds.isNotEmpty) {
      final share = item.quantity / newMemberIds.length;
      for (var id in newMemberIds) {
        newAssignments[id] = share;
      }
    }

    final newItems = widget.data.items.map((i) {
      if (i.id == item.id) {
        return i.copyWith(assignments: newAssignments, isCustomSplit: false);
      }
      return i;
    }).toList();

    widget.onDataChanged(widget.data.copyWith(items: newItems));
  }

  void _clearItemAssignments(String itemId) {
    final newItems = widget.data.items.map((i) {
      if (i.id == itemId) {
        return i.copyWith(assignments: {}, isCustomSplit: false);
      }
      return i;
    }).toList();
    widget.onDataChanged(widget.data.copyWith(items: newItems));
  }

  double _getItemizedTotalForMember(String memberId) {
    double total = 0;
    for (var item in widget.data.items) {
      final qty = item.assignments[memberId] ?? 0;
      total += qty * item.unitPrice;
    }
    return total;
  }

  double _getUnassignedAmount() {
    double unassigned = 0;
    for (var item in widget.data.items) {
      final assignedCount = item.getAssignedCount();
      unassigned += (item.quantity - assignedCount) * item.unitPrice;
    }
    return unassigned;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: widget.onBack,
                        child: Text(
                          'Back',
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ),
                      Text(
                        '3 of 3',
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      SizedBox(width: 60), // Spacer for alignment
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: Column(
                    children: [
                      // Title
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Split Options',
                                    style: TextStyle(
                                      fontSize: 28.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryLight,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    widget.data.splitType == SplitType.items
                                        ? (_isEditingItems ? 'Modify items, prices and quantities' : 'Tap items to assign')
                                        : 'How should this €${widget.data.amount.toStringAsFixed(2)} be shared?',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppTheme.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.data.splitType == SplitType.items && !_isEditingItems)
                              TextButton.icon(
                                onPressed: () => setState(() => _isEditingItems = true),
                                icon: Icon(Icons.edit, size: 16, color: AppTheme.primaryLight),
                                label: Text(
                                  'Edit',
                                  style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.w600),
                                ),
                              ),
                            if (widget.data.splitType == SplitType.items && _isEditingItems)
                              TextButton.icon(
                                onPressed: () {
                                  // Recalculate total from items
                                  final newTotal = widget.data.items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
                                  widget.onDataChanged(widget.data.copyWith(amount: newTotal));
                                  setState(() => _isEditingItems = false);
                                },
                                icon: Icon(Icons.check, size: 16, color: Colors.green[600]),
                                label: Text(
                                  'Done',
                                  style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      // Tabs
                      _buildSplitTabs(),
                      SizedBox(height: 2.h),
                      // Content Area
                      Expanded(
                        child: _isLoadingMembers
                            ? Center(child: CircularProgressIndicator())
                            : _buildSplitContent(),
                      ),
                    ],
                  ),
                ),
                // Bottom Button
                _buildBottomButton(),
              ],
            ),
          ),
        ),
        // Advanced Assignment Modal
        if (_activeModalItem != null) _buildAdvancedModal(),
      ],
    );
  }

  Widget _buildSplitTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton('Equal', SplitType.equal, Icons.equalizer),
            ),
            Expanded(
              child: _buildTabButton('%', SplitType.percentage, Icons.percent),
            ),
            Expanded(
              child: _buildTabButton('Custom', SplitType.custom, Icons.attach_money),
            ),
            Expanded(
              child: _buildTabButton('Items', SplitType.items, Icons.receipt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, SplitType type, IconData icon) {
    final isActive = widget.data.splitType == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleSplitTypeChange(type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
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
                color: isActive ? AppTheme.primaryLight : AppTheme.textSecondaryLight,
              ),
              SizedBox(width: 1.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppTheme.primaryLight : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitContent() {
    if (widget.data.splitType == SplitType.items) {
      return _buildItemsView();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          // Remaining indicator for manual modes
          if (widget.data.splitType == SplitType.percentage || widget.data.splitType == SplitType.custom)
            Container(
              margin: EdgeInsets.only(bottom: 2.h),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: _getRemainingManual().abs() < 0.1
                    ? Colors.green[50]
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.data.splitType == SplitType.percentage
                    ? '${_getRemainingManual().toStringAsFixed(1)}% remaining'
                    : '€${_getRemainingManual().toStringAsFixed(2)} remaining',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: _getRemainingManual().abs() < 0.1
                      ? Colors.green[700]
                      : Colors.red[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // Member list
          ..._groupMembers.map((member) => _buildMemberCard(member)),
          SizedBox(height: 10.h), // Space for bottom button
        ],
      ),
    );
  }

  Widget _buildMemberCard(GroupMember member) {
    final memberId = member.id.toString();
    final isSelected = widget.data.involvedMembers.contains(memberId);
    final equalAmount = _getEqualAmount(memberId);

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryLight.withOpacity(0.3) : Colors.transparent,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.data.splitType == SplitType.equal) {
              _toggleMemberEqual(memberId);
            } else {
              _toggleMemberManual(memberId);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryLight.withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          member.initials,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.primaryLight : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 5.w,
                          height: 5.w,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 3.w),
                // Name and amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.nickname,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.textPrimaryLight : Colors.grey[600],
                        ),
                      ),
                      if (isSelected && widget.data.splitType == SplitType.equal)
                        Text(
                          'Pays €${equalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                // Input for manual modes
                if (widget.data.splitType != SplitType.equal)
                  Container(
                    width: 20.w,
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryLight.withOpacity(0.3) : Colors.transparent,
                      ),
                    ),
                    child: TextField(
                      enabled: isSelected,
                      controller: TextEditingController(
                        text: isSelected
                            ? (widget.data.splitDetails[memberId]?.toStringAsFixed(2) ?? '0.00')
                            : '',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        suffix: Text(
                          widget.data.splitType == SplitType.percentage ? '%' : '€',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      onChanged: (value) => _handleManualValueChange(memberId, value),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isSplitValid())
            Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red[700]),
                  SizedBox(width: 1.w),
                  Text(
                    widget.data.splitType == SplitType.items
                        ? 'Assign all items before continuing'
                        : 'Total mismatch. Adjust ${widget.data.splitType == SplitType.percentage ? '%' : 'amount'} to match total.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
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
                backgroundColor: AppTheme.primaryLight,
                disabledBackgroundColor: Colors.grey[300],
                padding: EdgeInsets.symmetric(vertical: 3.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _isSplitValid() ? 4 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: Colors.white, size: 20),
                  SizedBox(width: 2.w),
                  Text(
                    'Create Expense',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsView() {
    if (widget.data.items.isEmpty) {
      return Center(
        child: Text(
          'No items found. Please scan a receipt or add items manually.',
          style: TextStyle(color: AppTheme.textSecondaryLight),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          ...widget.data.items.map((item) => _buildItemCard(item)),
          if (!_isEditingItems) _buildSummaryWidget(),
          SizedBox(height: 10.h), // Space for bottom button
        ],
      ),
    );
  }

  Widget _buildItemCard(ReceiptItem item) {
    final assignedCount = item.getAssignedCount();
    final isFullyAssigned = item.isFullyAssigned;
    final isExpanded = _expandedItemId == item.id;
    final isLocked = item.isCustomSplit;

    if (_isEditingItems) {
      return _buildItemEditCard(item);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFullyAssigned && !isExpanded
              ? Colors.green[100]!
              : AppTheme.borderLight,
        ),
      ),
      child: Column(
        children: [
          // Item header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedItemId = isExpanded ? null : item.id;
                });
              },
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isExpanded
                      ? AppTheme.primaryLight.withOpacity(0.05)
                      : (isFullyAssigned ? Colors.green[50] : Colors.white),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isFullyAssigned ? Colors.green[800] : AppTheme.textPrimaryLight,
                                ),
                              ),
                              if (item.quantity > 1) ...[
                                SizedBox(width: 1.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.h),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'x${item.quantity.toInt()}',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              Text(
                                '€${item.unitPrice.toStringAsFixed(2)} each',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppTheme.textSecondaryLight,
                                ),
                              ),
                              if (!isExpanded) ...[
                                SizedBox(width: 1.w),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 1.w),
                                if (isLocked)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock, size: 12, color: Colors.amber[600]),
                                      SizedBox(width: 0.5.w),
                                      Text(
                                        'Custom Split',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber[600],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    '${assignedCount % 1 == 0 ? assignedCount.toInt() : assignedCount.toStringAsFixed(1)}/${item.quantity} assigned',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isFullyAssigned ? Colors.green[600] : AppTheme.primaryLight,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded quick split panel
          if (isExpanded) _buildQuickSplitPanel(item),
        ],
      ),
    );
  }

  Widget _buildQuickSplitPanel(ReceiptItem item) {
    final assignedCount = item.getAssignedCount();
    final isLocked = item.isCustomSplit;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.03),
        border: Border(
          top: BorderSide(color: AppTheme.primaryLight.withOpacity(0.1)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUICK SPLIT (EQUAL)',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              Text(
                '${assignedCount % 1 == 0 ? assignedCount.toInt() : assignedCount.toStringAsFixed(1)} / ${item.quantity} ASSIGNED',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: item.isFullyAssigned ? Colors.green[600] : AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Member avatars grid
          Stack(
            children: [
              Opacity(
                opacity: isLocked ? 0.2 : 1.0,
                child: IgnorePointer(
                  ignoring: isLocked,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 1.w,
                      mainAxisSpacing: 1.h,
                    ),
                    itemCount: _groupMembers.length,
                    itemBuilder: (context, index) {
                      final member = _groupMembers[index];
                      final memberId = member.id.toString();
                      final qty = item.assignments[memberId] ?? 0;
                      final isAssigned = qty > 0;

                      return InkWell(
                        onTap: () => _handleQuickToggle(memberId, item),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 10.w,
                                  height: 10.w,
                                  decoration: BoxDecoration(
                                    color: isAssigned
                                        ? AppTheme.primaryLight.withOpacity(0.1)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isAssigned
                                          ? AppTheme.primaryLight
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      member.initials,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isAssigned
                                            ? AppTheme.primaryLight
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                                if (isAssigned)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      width: 5.w,
                                      height: 5.w,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1),
                                      ),
                                      child: Center(
                                        child: Text(
                                          qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 7.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              member.nickname.split(' ')[0],
                              style: TextStyle(
                                fontSize: 8.sp,
                                fontWeight: isAssigned ? FontWeight.w600 : FontWeight.normal,
                                color: isAssigned ? AppTheme.primaryLight : Colors.grey[400],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Locked overlay
              if (isLocked)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 16, color: Colors.amber[600]),
                          SizedBox(width: 1.w),
                          Text(
                            'Custom Split Active',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 2.w),
                          TextButton(
                            onPressed: () => _clearItemAssignments(item.id),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                              backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh, size: 12, color: AppTheme.primaryLight),
                                SizedBox(width: 0.5.w),
                                Text(
                                  'Reset',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Divider(),
          SizedBox(height: 1.h),
          // Advanced button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _activeModalItem = item;
                });
              },
              icon: Icon(Icons.settings, size: 14, color: AppTheme.primaryLight),
              label: Text(
                'Advanced / Partial Split',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemEditCard(ReceiptItem item) {
    final nameController = TextEditingController(text: item.name);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final unitPriceController = TextEditingController(text: item.unitPrice.toStringAsFixed(2));

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryLight),
                    ),
                  ),
                  onChanged: (value) {
                    final newItems = widget.data.items.map((i) {
                      if (i.id == item.id) {
                        return i.copyWith(name: value);
                      }
                      return i;
                    }).toList();
                    widget.onDataChanged(widget.data.copyWith(items: newItems));
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  final newItems = widget.data.items.where((i) => i.id != item.id).toList();
                  widget.onDataChanged(widget.data.copyWith(items: newItems));
                },
                icon: Icon(Icons.delete_outline, color: Colors.red[400]),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QTY',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                      ),
                      onChanged: (value) {
                        final qty = double.tryParse(value) ?? 1.0;
                        final newItems = widget.data.items.map((i) {
                          if (i.id == item.id) {
                            final newPrice = qty * i.unitPrice;
                            return i.copyWith(quantity: qty, price: newPrice);
                          }
                          return i;
                        }).toList();
                        widget.onDataChanged(widget.data.copyWith(items: newItems));
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNIT €',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    TextField(
                      controller: unitPriceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                      ),
                      onChanged: (value) {
                        final unitPrice = double.tryParse(value) ?? 0.0;
                        final newItems = widget.data.items.map((i) {
                          if (i.id == item.id) {
                            final newPrice = i.quantity * unitPrice;
                            return i.copyWith(unitPrice: unitPrice, price: newPrice);
                          }
                          return i;
                        }).toList();
                        widget.onDataChanged(widget.data.copyWith(items: newItems));
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              Padding(
                padding: EdgeInsets.only(top: 3.h),
                child: Text(
                  '€${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryWidget() {
    final membersWithAmounts = _groupMembers
        .where((m) => _getItemizedTotalForMember(m.id.toString()) > 0.01)
        .toList();
    final unassigned = _getUnassignedAmount();

    return Container(
      margin: EdgeInsets.only(top: 2.h),
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
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          ...membersWithAmounts.map((member) {
            final total = _getItemizedTotalForMember(member.id.toString());
            return Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    member.nickname,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  Text(
                    '€${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (unassigned > 0.01) ...[
            Divider(),
            SizedBox(height: 0.5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unassigned',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
                Text(
                  '€${unassigned.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedModal() {
    final item = _activeModalItem!;
    final remaining = item.getRemainingQuantity();
    
    return _AdvancedAssignmentModal(
      item: item,
      members: _groupMembers,
      onClose: () => setState(() => _activeModalItem = null),
      onAssign: (memberIds, quantity) {
        final newItems = widget.data.items.map((i) {
          if (i.id == item.id) {
            final newAssignments = Map<String, double>.from(i.assignments);
            final qtyPerPerson = quantity / memberIds.length;
            for (var memberId in memberIds) {
              newAssignments[memberId] = (newAssignments[memberId] ?? 0) + qtyPerPerson;
            }
            return i.copyWith(assignments: newAssignments, isCustomSplit: true);
          }
          return i;
        }).toList();
        widget.onDataChanged(widget.data.copyWith(items: newItems));
        setState(() {
          _activeModalItem = newItems.firstWhere((i) => i.id == item.id);
        });
      },
      onRemoveAssignment: (memberId) {
        final newItems = widget.data.items.map((i) {
          if (i.id == item.id) {
            final newAssignments = Map<String, double>.from(i.assignments);
            newAssignments.remove(memberId);
            return i.copyWith(assignments: newAssignments, isCustomSplit: true);
          }
          return i;
        }).toList();
        widget.onDataChanged(widget.data.copyWith(items: newItems));
        setState(() {
          _activeModalItem = newItems.firstWhere((i) => i.id == item.id);
        });
      },
    );
  }
}

// Advanced Assignment Modal Widget
class _AdvancedAssignmentModal extends StatefulWidget {
  final ReceiptItem item;
  final List<GroupMember> members;
  final VoidCallback onClose;
  final Function(List<String> memberIds, double quantity) onAssign;
  final Function(String memberId) onRemoveAssignment;

  const _AdvancedAssignmentModal({
    required this.item,
    required this.members,
    required this.onClose,
    required this.onAssign,
    required this.onRemoveAssignment,
  });

  @override
  State<_AdvancedAssignmentModal> createState() => _AdvancedAssignmentModalState();
}

class _AdvancedAssignmentModalState extends State<_AdvancedAssignmentModal> {
  double _assignQty = 1.0;
  final List<String> _selectedMemberIds = [];

  @override
  void initState() {
    super.initState();
    final remaining = widget.item.getRemainingQuantity();
    _assignQty = remaining > 0 ? (remaining < 1 ? remaining : 1.0) : 0.0;
  }

  void _toggleMemberSelection(String memberId) {
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
  }

  void _commitAssignment() {
    if (_selectedMemberIds.isEmpty || _assignQty <= 0) return;
    widget.onAssign(_selectedMemberIds, _assignQty);
    setState(() {
      _selectedMemberIds.clear();
      final remaining = widget.item.getRemainingQuantity();
      _assignQty = remaining > 0 ? (remaining < 1 ? remaining : 1.0) : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.item.getRemainingQuantity();
    
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.25),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: EdgeInsets.only(top: 1.h),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.item.name,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryLight,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                '$remaining / ${widget.item.quantity} Remaining',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onClose,
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quantity selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'QUANTITY TO ASSIGN',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: AppTheme.textSecondaryLight,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _assignQty = (_assignQty - 0.5).clamp(0.5, remaining);
                                        });
                                      },
                                      icon: Icon(Icons.remove, size: 20),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: TextField(
                                        controller: TextEditingController(text: _assignQty.toStringAsFixed(1)),
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        onChanged: (value) {
                                          final qty = double.tryParse(value) ?? 0.0;
                                          setState(() {
                                            _assignQty = qty.clamp(0.0, remaining);
                                          });
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _assignQty = (_assignQty + 0.5).clamp(0.5, remaining);
                                        });
                                      },
                                      icon: Icon(Icons.add, size: 20),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          // Member selection
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SELECT MEMBERS',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: AppTheme.textSecondaryLight,
                                ),
                              ),
                              if (_selectedMemberIds.isNotEmpty)
                                TextButton(
                                  onPressed: () => setState(() => _selectedMemberIds.clear()),
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(fontSize: 11.sp),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 2.w,
                              mainAxisSpacing: 2.h,
                            ),
                            itemCount: widget.members.length,
                            itemBuilder: (context, index) {
                              final member = widget.members[index];
                              final memberId = member.id.toString();
                              final isSelected = _selectedMemberIds.contains(memberId);

                              return InkWell(
                                onTap: () => _toggleMemberSelection(memberId),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 12.w,
                                          height: 12.w,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppTheme.primaryLight.withOpacity(0.1)
                                                : Colors.grey[100],
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppTheme.primaryLight
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              member.initials,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? AppTheme.primaryLight
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: -2,
                                            right: -2,
                                            child: Container(
                                              width: 6.w,
                                              height: 6.w,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryLight,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      member.nickname.split(' ')[0],
                                      style: TextStyle(
                                        fontSize: 9.sp,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        color: isSelected ? AppTheme.primaryLight : Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 4.h),
                          // Assign button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectedMemberIds.isEmpty || _assignQty <= 0
                                  ? null
                                  : _commitAssignment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryLight,
                                disabledBackgroundColor: Colors.grey[300],
                                padding: EdgeInsets.symmetric(vertical: 3.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _selectedMemberIds.isEmpty
                                    ? 'Select members above'
                                    : _selectedMemberIds.length == 1
                                        ? 'Assign ${_assignQty.toStringAsFixed(1)} to ${widget.members.firstWhere((m) => m.id.toString() == _selectedMemberIds.first).nickname.split(' ')[0]}'
                                        : 'Split ${_assignQty.toStringAsFixed(1)} between ${_selectedMemberIds.length} people',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          // Current assignments
                          Divider(),
                          SizedBox(height: 2.h),
                          Text(
                            'CURRENT ASSIGNMENTS',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          if (widget.item.assignments.isEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(4.h),
                                child: Text(
                                  'No one assigned yet.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...widget.item.assignments.entries.map((entry) {
                              final member = widget.members.firstWhere(
                                (m) => m.id.toString() == entry.key,
                                orElse: () => widget.members.first,
                              );
                              final qty = entry.value;

                              return Container(
                                margin: EdgeInsets.only(bottom: 1.h),
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.borderLight),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8.w,
                                      height: 8.w,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppTheme.borderLight),
                                      ),
                                      child: Center(
                                        child: Text(
                                          member.initials,
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 3.w),
                                    Expanded(
                                      child: Text(
                                        member.nickname,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimaryLight,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${qty % 1 == 0 ? qty.toInt() : qty.toStringAsFixed(1)} items',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimaryLight,
                                          ),
                                        ),
                                        Text(
                                          '€${(qty * widget.item.unitPrice).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppTheme.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: 2.w),
                                    IconButton(
                                      onPressed: () => widget.onRemoveAssignment(entry.key),
                                      icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
