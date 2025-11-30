import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/group_service.dart';
import '../../models/group_member.dart';
import 'models/expense_wizard_data.dart';
import 'models/receipt_item.dart';
import 'widgets/split_type_tabs.dart';
import 'widgets/member_split_card.dart';
import 'widgets/split_bottom_button.dart';
import 'widgets/items_split_view.dart';
import 'widgets/advanced_assignment_modal.dart';
import 'widgets/split_widget_constants.dart';

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
  final Map<String, TextEditingController> _inputControllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 [STEP3] initState - items count: ${widget.data.items.length}, splitType: ${widget.data.splitType}');
    _loadGroupMembers();
    _initializeSplitType();
    _initializeControllers();
  }

  @override
  void dispose() {
    _inputControllers.values.forEach((controller) => controller.dispose());
    _focusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }

  void _initializeControllers() {
    for (var member in _groupMembers) {
      final memberId = member.id.toString();
      if (!_inputControllers.containsKey(memberId)) {
        _inputControllers[memberId] = TextEditingController();
        _focusNodes[memberId] = FocusNode();
      }
    }
  }

  @override
  void didUpdateWidget(StepSplitPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('🔍 [STEP3] didUpdateWidget - old items: ${oldWidget.data.items.length}, new items: ${widget.data.items.length}');
    debugPrint('🔍 [STEP3] didUpdateWidget - old splitType: ${oldWidget.data.splitType}, new splitType: ${widget.data.splitType}');
    
    // Reload members if groupId changed
    if (oldWidget.data.groupId != widget.data.groupId) {
      _loadGroupMembers();
    }
    // Ensure items are preserved if they existed before but are now missing
    // This can happen if copyWith was called without explicitly preserving items
    if (oldWidget.data.items.isNotEmpty && widget.data.items.isEmpty && widget.data.splitType == SplitType.items) {
      debugPrint('⚠️ [STEP3] WARNING: Items were lost in didUpdateWidget! Restoring ${oldWidget.data.items.length} items');
      widget.onDataChanged(widget.data.copyWith(items: oldWidget.data.items));
    }
    
    // Update input controllers when split details change externally
    if (oldWidget.data.splitDetails != widget.data.splitDetails || oldWidget.data.splitType != widget.data.splitType) {
      _updateInputControllers();
    }
  }

  void _updateInputControllers() {
    final isPercentage = widget.data.splitType == SplitType.percentage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var member in _groupMembers) {
        final memberId = member.id.toString();
        final controller = _inputControllers[memberId];
        final focusNode = _focusNodes[memberId];
        
        // Only update if the field doesn't have focus
        if (controller != null && focusNode != null && !focusNode.hasFocus) {
          final value = widget.data.splitDetails[memberId] ?? 0.0;
          final displayValue = isPercentage ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
          if (controller.text != displayValue) {
            controller.text = displayValue;
          }
        }
      }
    });
  }

  Future<void> _loadGroupMembers() async {
    if (widget.data.groupId == null || widget.data.groupId!.isEmpty) {
      setState(() {
        _isLoadingMembers = false;
        _groupMembers = [];
      });
      return;
    }

    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final group = await GroupService.getGroupWithMembers(widget.data.groupId!);
      if (mounted && group != null) {
        setState(() {
          _groupMembers = group.members;
          _isLoadingMembers = false;
          
          // Initialize controllers for new members
          for (var member in _groupMembers) {
            final memberId = member.id.toString();
            if (!_inputControllers.containsKey(memberId)) {
              _inputControllers[memberId] = TextEditingController();
              _focusNodes[memberId] = FocusNode();
            }
          }
          
          // Initialize involved members if empty
          if (widget.data.involvedMembers.isEmpty && _groupMembers.isNotEmpty) {
            widget.onDataChanged(
              widget.data.copyWith(
                involvedMembers: _groupMembers.map((m) => m.id.toString()).toList(),
              ),
            );
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingMembers = false;
            _groupMembers = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading group members: $e');
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
          _groupMembers = [];
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
        
        // Guard against division by zero
        if (count == 0) return;
        
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

    debugPrint('🔍 [STEP3] _handleSplitTypeChange - changing from ${widget.data.splitType} to $type');
    debugPrint('🔍 [STEP3] _handleSplitTypeChange - current items count: ${widget.data.items.length}');
    
    final updates = <String, dynamic>{'splitType': type};

    // Initialize defaults for Manual Modes
    if (type == SplitType.percentage || type == SplitType.custom) {
      final involved = widget.data.involvedMembers.isNotEmpty
          ? widget.data.involvedMembers
          : _groupMembers.map((m) => m.id.toString()).toList();
      final count = involved.length;
      
      // Guard against division by zero
      if (count > 0) {
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
      } else {
        // If no members, initialize with empty details
        updates['splitDetails'] = <String, double>{};
        updates['involvedMembers'] = [];
      }
    }

    final newData = widget.data.copyWith(
      splitType: type,
      splitDetails: updates['splitDetails'] ?? widget.data.splitDetails,
      involvedMembers: updates['involvedMembers'] ?? widget.data.involvedMembers,
      items: widget.data.items, // Explicitly preserve items when changing split type
    );
    debugPrint('🔍 [STEP3] _handleSplitTypeChange - new items count: ${newData.items.length}');
    widget.onDataChanged(newData);
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
      final count = widget.data.involvedMembers.length;
      if (count == 0) return 0.0;
      return widget.data.amount / count;
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
      return widget.data.items.every((item) => item.isFullyAssigned) &&
          widget.data.items.isNotEmpty;
    } else if (widget.data.splitType == SplitType.percentage) {
      return _getRemainingManual().abs() < SplitWidgetConstants.percentageThreshold;
    } else if (widget.data.splitType == SplitType.custom) {
      return _getRemainingManual().abs() < SplitWidgetConstants.customThreshold;
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

  void _handleSelectAll(String itemId) {
    final item = widget.data.items.firstWhere((i) => i.id == itemId);
    if (item.isCustomSplit) return;

    final hasAnyAssignments = item.assignments.isNotEmpty;
    final allMemberIds = _groupMembers.map((m) => m.id.toString()).toList();
    
    final newAssignments = <String, double>{};
    if (hasAnyAssignments) {
      // Clear all assignments
      // newAssignments stays empty
    } else {
      // Select all members
      if (allMemberIds.isNotEmpty) {
        final share = item.quantity / allMemberIds.length;
        for (var id in allMemberIds) {
          newAssignments[id] = share;
        }
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

  double _getBottomButtonHeight() {
    // Height needed so content stops scrolling at top of button
    // Container bottom padding: 4.w ≈ 0.8.h
    // Container top padding: 2.h
    return 0.8.h + 2.h; // ~2.8.h
  }

  double _getFullFloatingSectionHeight() {
    // Full height of the floating section for the gradient overlay
    // Container padding top: 2.h
    // Button: ~4.h (button + padding)
    // Container padding bottom: 0.8.h
    return 2.h + 4.h + 0.8.h; // ~6.8.h
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Unfocus any focused input when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Stack(
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
                // Content with floating button
                Expanded(
                  child: Stack(
                    children: [
                      // Scrollable content
                      Column(
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
                                          fontSize: 20.sp,
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
                          SplitTypeTabs(
                            selectedType: widget.data.splitType,
                            onTypeChanged: _handleSplitTypeChange,
                          ),
                          SizedBox(height: 2.h),
                          // Content Area
                          Expanded(
                            child: _isLoadingMembers
                                ? Center(child: CircularProgressIndicator())
                                : _buildSplitContent(),
                          ),
                        ],
                      ),
                      // Floating bottom button with gradient fade
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SplitBottomButton(
                          splitType: widget.data.splitType,
                          remainingAmount: _getRemainingManual(),
                          isValid: _isSplitValid(),
                          onSubmit: widget.onSubmit,
                        ),
                      ),
                    ],
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


  Widget _buildSplitContent() {
    debugPrint('🔍 [STEP3] _buildSplitContent - splitType: ${widget.data.splitType}, items count: ${widget.data.items.length}');
    if (widget.data.splitType == SplitType.items) {
      return ItemsSplitView(
        items: widget.data.items,
        groupMembers: _groupMembers,
        isEditingItems: _isEditingItems,
        expandedItemId: _expandedItemId,
        bottomButtonHeight: _getBottomButtonHeight(),
        gradientHeight: _getFullFloatingSectionHeight(),
        onToggleExpand: (itemId) {
          setState(() {
            _expandedItemId = _expandedItemId == itemId ? null : itemId;
          });
        },
        onQuickToggle: (itemId, memberId) {
          final item = widget.data.items.firstWhere((i) => i.id == itemId);
          _handleQuickToggle(memberId, item);
        },
        onClearAssignments: (itemId) => _clearItemAssignments(itemId),
        onSelectAll: (itemId) => _handleSelectAll(itemId),
        onShowAdvanced: (item) => _showAdvancedModal(item),
        onItemNameChanged: (itemId, name) {
          final newItems = widget.data.items.map((i) {
            if (i.id == itemId) {
              return i.copyWith(name: name);
            }
            return i;
          }).toList();
          widget.onDataChanged(widget.data.copyWith(items: newItems));
        },
        onItemQuantityChanged: (itemId, qty) {
          final newItems = widget.data.items.map((i) {
            if (i.id == itemId) {
              final newPrice = qty * i.unitPrice;
              return i.copyWith(quantity: qty, price: newPrice);
            }
            return i;
          }).toList();
          widget.onDataChanged(widget.data.copyWith(items: newItems));
        },
        onItemUnitPriceChanged: (itemId, unitPrice) {
          final newItems = widget.data.items.map((i) {
            if (i.id == itemId) {
              final newPrice = i.quantity * unitPrice;
              return i.copyWith(unitPrice: unitPrice, price: newPrice);
            }
            return i;
          }).toList();
          widget.onDataChanged(widget.data.copyWith(items: newItems));
        },
        onItemDelete: (itemId) {
          final newItems = widget.data.items.where((i) => i.id != itemId).toList();
          widget.onDataChanged(widget.data.copyWith(items: newItems));
        },
        memberTotals: _groupMembers.asMap().map((_, member) => MapEntry(
          member.id.toString(),
          _getItemizedTotalForMember(member.id.toString()),
        )),
        unassignedAmount: _getUnassignedAmount(),
      );
    }

    final scrollStopHeight = _getBottomButtonHeight();
    final gradientHeight = _getFullFloatingSectionHeight();
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 4.w,
            right: 4.w,
            bottom: scrollStopHeight, // Stop scrolling at top of remaining text/button
          ),
          child: Column(
            children: [
              // Member list
              ..._groupMembers.map((member) {
                final memberId = member.id.toString();
                final equalAmount = _getEqualAmount(memberId);
                final percentageAmount = widget.data.splitType == SplitType.percentage
                    ? (widget.data.splitDetails[memberId] ?? 0.0)
                    : 0.0;
                return MemberSplitCard(
                  member: member,
                  isSelected: widget.data.involvedMembers.contains(memberId),
                  splitType: widget.data.splitType,
                  equalAmount: equalAmount,
                  percentageAmount: percentageAmount,
                  totalAmount: widget.data.amount,
                  splitDetailValue: widget.data.splitDetails[memberId] ?? 0.0,
                  controller: _inputControllers[memberId],
                  focusNode: _focusNodes[memberId],
                  onToggle: (id) {
                    if (widget.data.splitType == SplitType.equal) {
                      _toggleMemberEqual(id);
                    } else {
                      _toggleMemberManual(id);
                    }
                  },
                  onValueChanged: _handleManualValueChange,
                );
              }),
            ],
          ),
        ),
        // Gradient fade overlay at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: gradientHeight,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.4),
                    Colors.white.withOpacity(0.9),
                    Colors.white,
                  ],
                  stops: [0.0, 0.4, 0.9, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  void _showAdvancedModal(ReceiptItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Get current item from parent's state
          final currentItem = widget.data.items.firstWhere(
            (i) => i.id == item.id,
            orElse: () => item,
          );
          
          return AdvancedAssignmentModal(
            item: currentItem,
            members: _groupMembers,
            getCurrentItem: () => widget.data.items.firstWhere(
              (i) => i.id == item.id,
              orElse: () => item,
            ),
            onClose: () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.pop(context);
            },
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
              // Force modal to rebuild with new data
              setModalState(() {});
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
              // Force modal to rebuild with new data
              setModalState(() {});
            },
          );
        },
      ),
    );
  }
}
