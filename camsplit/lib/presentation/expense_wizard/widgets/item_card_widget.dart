import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/receipt_item.dart';
import 'quick_split_panel.dart';

class ItemCardWidget extends StatefulWidget {
  final ReceiptItem item;
  final List<Map<String, dynamic>> groupMembers;
  final bool isExpanded;
  final bool isEditing;
  final Function(bool) onExpandedChanged;
  final Function(Map<String, double>, {bool isAdvanced}) onAssignmentChanged;
  final Function(ReceiptItem) onItemUpdated;
  final VoidCallback onItemDeleted;
  final VoidCallback onAdvancedSplit;

  const ItemCardWidget({
    super.key,
    required this.item,
    required this.groupMembers,
    required this.isExpanded,
    required this.isEditing,
    required this.onExpandedChanged,
    required this.onAssignmentChanged,
    required this.onItemUpdated,
    required this.onItemDeleted,
    required this.onAdvancedSplit,
  });

  @override
  State<ItemCardWidget> createState() => _ItemCardWidgetState();
}

class _ItemCardWidgetState extends State<ItemCardWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.item.name;
    _quantityController.text = widget.item.quantity.toString();
    _unitPriceController.text = widget.item.unitPrice.toStringAsFixed(2);
  }

  @override
  void didUpdateWidget(ItemCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _nameController.text = widget.item.name;
      _quantityController.text = widget.item.quantity.toString();
      _unitPriceController.text = widget.item.unitPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _updateItem() {
    final quantity = double.tryParse(_quantityController.text) ?? widget.item.quantity;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? widget.item.unitPrice;
    final totalPrice = quantity * unitPrice;

    widget.onItemUpdated(
      widget.item.copyWith(
        name: _nameController.text,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignedCount = widget.item.getAssignedQuantity();
    final isFullyAssigned = widget.item.isFullyAssigned;

    if (widget.isEditing) {
      return _buildEditCard();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isExpanded
              ? AppTheme.lightTheme.primaryColor.withOpacity(0.3)
              : (isFullyAssigned ? Colors.green[200]! : Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Item header (clickable)
          InkWell(
            onTap: () => widget.onExpandedChanged(!widget.isExpanded),
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: widget.isExpanded
                    ? AppTheme.lightTheme.primaryColor.withOpacity(0.05)
                    : (isFullyAssigned ? Colors.green[50] : Colors.white),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                  bottom: Radius.circular(widget.isExpanded ? 0 : 12),
                ),
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
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                                color: isFullyAssigned
                                    ? Colors.green[800]
                                    : Colors.grey[900],
                              ),
                            ),
                            if (widget.item.quantity > 1) ...[
                              SizedBox(width: 2.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'x${widget.item.quantity.toInt()}',
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
                              '€${widget.item.unitPrice.toStringAsFixed(2)} each',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (!widget.isExpanded) ...[
                              SizedBox(width: 2.w),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              if (widget.item.isCustomSplit)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      size: 12,
                                      color: Colors.orange[600],
                                    ),
                                    SizedBox(width: 0.5.w),
                                    Text(
                                      'Custom Split',
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.orange[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  '${assignedCount.toStringAsFixed(assignedCount % 1 == 0 ? 0 : 1)}/${widget.item.quantity.toInt()} assigned',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: isFullyAssigned
                                        ? Colors.green[600]
                                        : AppTheme.lightTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
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
                        '€${widget.item.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: Colors.grey[900],
                        ),
                      ),
                      Icon(
                        widget.isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content (Quick Split Panel)
          if (widget.isExpanded)
            QuickSplitPanel(
              item: widget.item,
              groupMembers: widget.groupMembers,
              onAssignmentChanged: (assignments, {bool isAdvanced = false}) {
                widget.onAssignmentChanged(assignments, isAdvanced: isAdvanced);
              },
              onAdvancedSplit: widget.onAdvancedSplit,
            ),
        ],
      ),
    );
  }

  Widget _buildEditCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
                    border: UnderlineInputBorder(),
                  ),
                  onChanged: (_) => _updateItem(),
                ),
              ),
              IconButton(
                onPressed: widget.onItemDeleted,
                icon: Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QTY', style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(2.w),
                      ),
                      onChanged: (_) => _updateItem(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UNIT €', style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
                    TextField(
                      controller: _unitPriceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(2.w),
                      ),
                      onChanged: (_) => _updateItem(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TOTAL', style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
                  Text(
                    '€${widget.item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

