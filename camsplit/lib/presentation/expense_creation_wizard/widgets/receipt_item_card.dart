import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/group_member.dart';
import '../models/receipt_item.dart';
import 'quick_split_panel.dart';

class ReceiptItemCard extends StatefulWidget {
  final ReceiptItem item;
  final bool isExpanded;
  final bool isEditing;
  final List<GroupMember> groupMembers;
  final Function(String) onToggleExpand;
  final Function(String memberId) onQuickToggle;
  final VoidCallback onClearAssignments;
  final VoidCallback onShowAdvanced;
  final Function(String) onNameChanged;
  final Function(double) onQuantityChanged;
  final Function(double) onUnitPriceChanged;
  final VoidCallback onDelete;
  final VoidCallback? onSelectAll; // Callback to select/deselect all members

  const ReceiptItemCard({
    Key? key,
    required this.item,
    required this.isExpanded,
    required this.isEditing,
    required this.groupMembers,
    required this.onToggleExpand,
    required this.onQuickToggle,
    required this.onClearAssignments,
    required this.onShowAdvanced,
    required this.onNameChanged,
    required this.onQuantityChanged,
    required this.onUnitPriceChanged,
    required this.onDelete,
    this.onSelectAll,
  }) : super(key: key);

  @override
  State<ReceiptItemCard> createState() => _ReceiptItemCardState();
}

class _ReceiptItemCardState extends State<ReceiptItemCard> {
  late TextEditingController _nameController;
  late TextEditingController _qtyController;
  late TextEditingController _unitPriceController;
  late FocusNode _nameFocusNode;
  late FocusNode _qtyFocusNode;
  late FocusNode _unitPriceFocusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _qtyController = TextEditingController(text: widget.item.quantity.toInt().toString());
    _unitPriceController = TextEditingController(text: widget.item.unitPrice.toStringAsFixed(2));
    _nameFocusNode = FocusNode();
    _qtyFocusNode = FocusNode();
    _unitPriceFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(ReceiptItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controllers if item changed and we're not editing (to preserve user input)
    if (oldWidget.item.id != widget.item.id || (!widget.isEditing && oldWidget.isEditing)) {
      _nameController.text = widget.item.name;
      _qtyController.text = widget.item.quantity.toInt().toString();
      _unitPriceController.text = widget.item.unitPrice.toStringAsFixed(2);
    } else if (widget.isEditing) {
      // When editing, only update controllers if field doesn't have focus
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_nameFocusNode.hasFocus && _nameController.text != widget.item.name) {
          _nameController.text = widget.item.name;
        }
        final qtyText = widget.item.quantity.toInt().toString();
        if (!_qtyFocusNode.hasFocus && _qtyController.text != qtyText) {
          _qtyController.text = qtyText;
        }
        final unitPriceText = widget.item.unitPrice.toStringAsFixed(2);
        if (!_unitPriceFocusNode.hasFocus && _unitPriceController.text != unitPriceText) {
          _unitPriceController.text = unitPriceText;
        }
      });
    } else {
      // Update from item data when not editing
      if (_nameController.text != widget.item.name) {
        _nameController.text = widget.item.name;
      }
      if (_qtyController.text != widget.item.quantity.toInt().toString()) {
        _qtyController.text = widget.item.quantity.toInt().toString();
      }
      if (_unitPriceController.text != widget.item.unitPrice.toStringAsFixed(2)) {
        _unitPriceController.text = widget.item.unitPrice.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitPriceController.dispose();
    _nameFocusNode.dispose();
    _qtyFocusNode.dispose();
    _unitPriceFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignedCount = widget.item.getAssignedCount();
    final isFullyAssigned = widget.item.isFullyAssigned;
    final isLocked = widget.item.isCustomSplit;

    if (widget.isEditing) {
      return _buildItemEditCard();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFullyAssigned && !widget.isExpanded
              ? Colors.green[100]!
              : AppTheme.borderLight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Item header
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onToggleExpand(widget.item.id),
                borderRadius: widget.isExpanded
                    ? BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: widget.isExpanded
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
                                widget.item.name,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isFullyAssigned ? Colors.green[800] : AppTheme.textPrimaryLight,
                                ),
                              ),
                              if (widget.item.quantity > 1) ...[
                                SizedBox(width: 1.w),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.5.h),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'x${widget.item.quantity.toInt()}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
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
                                '€${widget.item.unitPrice.toStringAsFixed(2)} each',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppTheme.textSecondaryLight,
                                ),
                              ),
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
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber[600],
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  '${assignedCount % 1 == 0 ? assignedCount.toInt() : assignedCount.toStringAsFixed(1)}/${widget.item.quantity % 1 == 0 ? widget.item.quantity.toInt() : widget.item.quantity.toStringAsFixed(1)} assigned',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isFullyAssigned ? Colors.green[600] : AppTheme.primaryLight,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${widget.item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        Icon(
                          widget.isExpanded ? Icons.expand_less : Icons.expand_more,
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
          if (widget.isExpanded)
            QuickSplitPanel(
              item: widget.item,
              groupMembers: widget.groupMembers,
              isLocked: isLocked,
              onQuickToggle: widget.onQuickToggle,
              onClearAssignments: widget.onClearAssignments,
              onShowAdvanced: widget.onShowAdvanced,
              onSelectAll: widget.onSelectAll,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemEditCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Item name and delete button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
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
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (value) => widget.onNameChanged(value),
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 18),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          // Bottom row: QTY, UNIT €, and Total (labels inline)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // QTY section with inline label
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QTY',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondaryLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Container(
                    width: 14.w,
                    height: 6.h,
                    child: TextField(
                      controller: _qtyController,
                      focusNode: _qtyFocusNode,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final qty = int.tryParse(value) ?? 1;
                        widget.onQuantityChanged(qty.toDouble());
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(width: 4.w),
              // UNIT € section with inline label
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'UNIT €',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondaryLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Container(
                    width: 18.w,
                    height: 6.h,
                    child: TextField(
                      controller: _unitPriceController,
                      focusNode: _unitPriceFocusNode,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final unitPrice = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
                        widget.onUnitPriceChanged(unitPrice);
                      },
                    ),
                  ),
                ],
              ),
              Spacer(),
              // Total price aligned to the right
              Text(
                '€${widget.item.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

