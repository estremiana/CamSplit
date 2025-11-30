import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/group_member.dart';
import '../models/receipt_item.dart';
import 'member_avatar_widget.dart';
import 'split_widget_constants.dart';
import 'split_text_styles.dart';

class AdvancedAssignmentModal extends StatefulWidget {
  final ReceiptItem item;
  final List<GroupMember> members;
  final VoidCallback onClose;
  final Function(List<String> memberIds, double quantity) onAssign;
  final Function(String memberId) onRemoveAssignment;
  final ReceiptItem Function()? getCurrentItem; // Optional callback to get current item

  const AdvancedAssignmentModal({
    Key? key,
    required this.item,
    required this.members,
    required this.onClose,
    required this.onAssign,
    required this.onRemoveAssignment,
    this.getCurrentItem,
  }) : super(key: key);

  @override
  State<AdvancedAssignmentModal> createState() => _AdvancedAssignmentModalState();
}

class _AdvancedAssignmentModalState extends State<AdvancedAssignmentModal> {
  double _assignQty = 1.0;
  final List<String> _selectedMemberIds = [];
  late DraggableScrollableController _draggableController;
  late TextEditingController _qtyController;
  bool _isDecrementPressed = false;
  bool _isIncrementPressed = false;

  @override
  void initState() {
    super.initState();
    final currentItem = _currentItem;
    final remaining = currentItem.getRemainingQuantity();
    _assignQty = remaining > 0 ? (remaining < 1 ? remaining : 1.0).roundToDouble() : 0.0;
    _qtyController = TextEditingController(text: _assignQty.toInt().toString());
    _draggableController = DraggableScrollableController();
    _draggableController.addListener(_onDragUpdate);
  }

  ReceiptItem get _currentItem {
    return widget.getCurrentItem?.call() ?? widget.item;
  }

  @override
  void didUpdateWidget(AdvancedAssignmentModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update state when item changes (e.g., assignments added/removed)
    final currentItem = _currentItem;
    if (oldWidget.item.assignments != currentItem.assignments) {
      final remaining = currentItem.getRemainingQuantity();
      _assignQty = remaining > 0 ? (remaining < 1 ? remaining : 1.0).roundToDouble() : 0.0;
      _qtyController.text = _assignQty.toInt().toString();
      // Clear selected members if they were removed from assignments
      _selectedMemberIds.removeWhere((memberId) => !currentItem.assignments.containsKey(memberId) && 
          !widget.members.any((m) => m.id.toString() == memberId));
    }
  }

  @override
  void dispose() {
    _draggableController.removeListener(_onDragUpdate);
    _draggableController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  void _onDragUpdate() {
    // showModalBottomSheet handles dismissal automatically when dragged down
    // This listener can be used for other purposes if needed
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
    // Use a post-frame callback to update after the parent has updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedMemberIds.clear();
          final currentItem = _currentItem;
          final remaining = currentItem.getRemainingQuantity();
          _assignQty = remaining > 0 ? (remaining < 1 ? remaining : 1.0).roundToDouble() : 0.0;
          _qtyController.text = _assignQty.toInt().toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _currentItem;
    final remaining = currentItem.getRemainingQuantity();
    
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: DraggableScrollableSheet(
        controller: _draggableController,
        initialChildSize: 0.9,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        snap: true,
        snapSizes: const [0.3, 0.5, 0.9],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Draggable header area
                GestureDetector(
                  onTap: () {}, // Prevent taps from closing
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
                                    currentItem.name,
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryLight,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    '${remaining.toInt()} / ${currentItem.quantity.toInt()} Remaining',
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
                              style: SplitTextStyles.labelLarge(AppTheme.textSecondaryLight),
                            ),
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Listener(
                                    onPointerDown: (_) {
                                      setState(() {
                                        _isDecrementPressed = true;
                                      });
                                    },
                                    onPointerUp: (_) {
                                      setState(() {
                                        _isDecrementPressed = false;
                                        _assignQty = (_assignQty - 1).clamp(1.0, remaining).roundToDouble();
                                        _qtyController.text = _assignQty.toInt().toString();
                                      });
                                    },
                                    onPointerCancel: (_) {
                                      setState(() {
                                        _isDecrementPressed = false;
                                      });
                                    },
                                    child: AnimatedScale(
                                      scale: _isDecrementPressed ? 0.9 : 1.0,
                                      duration: Duration(milliseconds: 100),
                                      curve: Curves.easeInOut,
                                      alignment: Alignment.center,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        width: 48,
                                        height: 48,
                                        alignment: Alignment.center,
                                        child: Icon(Icons.remove, size: 20),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: _qtyController,
                                      readOnly: true,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryLight,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        filled: true,
                                        fillColor: Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                  Listener(
                                    onPointerDown: (_) {
                                      setState(() {
                                        _isIncrementPressed = true;
                                      });
                                    },
                                    onPointerUp: (_) {
                                      setState(() {
                                        _isIncrementPressed = false;
                                        _assignQty = (_assignQty + 1).clamp(1.0, remaining).roundToDouble();
                                        _qtyController.text = _assignQty.toInt().toString();
                                      });
                                    },
                                    onPointerCancel: (_) {
                                      setState(() {
                                        _isIncrementPressed = false;
                                      });
                                    },
                                    child: AnimatedScale(
                                      scale: _isIncrementPressed ? 0.9 : 1.0,
                                      duration: Duration(milliseconds: 150),
                                      curve: Curves.easeInOut,
                                      alignment: Alignment.center,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        width: 48,
                                        height: 48,
                                        alignment: Alignment.center,
                                        child: Icon(Icons.add, size: 20),
                                      ),
                                    ),
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
                              style: SplitTextStyles.labelLarge(AppTheme.textSecondaryLight),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  if (_selectedMemberIds.isEmpty) {
                                    // Select all members
                                    _selectedMemberIds.addAll(
                                      widget.members.map((m) => m.id.toString()).toList(),
                                    );
                                  } else {
                                    // Clear all selections
                                    _selectedMemberIds.clear();
                                  }
                                });
                              },
                              child: Text(
                                _selectedMemberIds.isEmpty ? 'Select All' : 'Clear',
                                style: SplitTextStyles.bodyLarge(AppTheme.primaryLight),
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
                                  MemberAvatarWidget(
                                    member: member,
                                    isSelected: isSelected,
                                    showCheckBadge: isSelected,
                                    showBadge: false,
                                    size: SplitWidgetConstants.avatarSize,
                                    onTap: () => _toggleMemberSelection(memberId),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    member.nickname.split(' ')[0],
                                    style: isSelected
                                        ? SplitTextStyles.bodyMedium(AppTheme.primaryLight)
                                        : SplitTextStyles.bodyMedium(Colors.grey[400]!),
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
                                      ? 'Assign ${_assignQty.toInt()} to ${widget.members.firstWhere((m) => m.id.toString() == _selectedMemberIds.first).nickname.split(' ')[0]}'
                                      : 'Split ${_assignQty.toInt()} between ${_selectedMemberIds.length} people',
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
                        SizedBox(height: 2.h),
                        Text(
                          'CURRENT ASSIGNMENTS',
                          style: SplitTextStyles.labelLarge(AppTheme.textSecondaryLight),
                        ),
                        SizedBox(height: 2.h),
                        if (currentItem.assignments.isEmpty)
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
                          ...currentItem.assignments.entries.map((entry) {
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
                                  MemberAvatarWidget(
                                    member: member,
                                    isSelected: false,
                                    showCheckBadge: false,
                                    showBadge: false,
                                    size: 8.0,
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
                                        '€${(qty * currentItem.unitPrice).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: AppTheme.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 2.w),
                                  IconButton(
                                    onPressed: () {
                                      widget.onRemoveAssignment(entry.key);
                                      // Update UI after removal
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) {
                                          setState(() {
                                            final currentItem = _currentItem;
                                            final remaining = currentItem.getRemainingQuantity();
                                            _assignQty = remaining > 0 ? (remaining < 1 ? remaining : 1.0).roundToDouble() : 0.0;
                                            _qtyController.text = _assignQty.toInt().toString();
                                          });
                                        }
                                      });
                                    },
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
    );
  }
}

