import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import './confidence_indicator_widget.dart';

class EditableItemCardWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>) onItemChanged;
  final Function(int) onItemDeleted;
  final bool isHighlighted;

  const EditableItemCardWidget({
    super.key,
    required this.item,
    required this.onItemChanged,
    required this.onItemDeleted,
    this.isHighlighted = false,
  });

  @override
  State<EditableItemCardWidget> createState() => _EditableItemCardWidgetState();
}

class _EditableItemCardWidgetState extends State<EditableItemCardWidget> {
  late TextEditingController _nameController;
  late TextEditingController _unitPriceController;
  late TextEditingController _quantityController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item['name']);
    _unitPriceController =
        TextEditingController(text: widget.item['unit_price'].toString());
    _quantityController =
        TextEditingController(text: (widget.item['quantity'] ?? 1).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final double? newUnitPrice = double.tryParse(_unitPriceController.text);
    final int? newQuantity = int.tryParse(_quantityController.text);
    if (newUnitPrice != null &&
        _nameController.text.isNotEmpty &&
        newQuantity != null &&
        newQuantity > 0) {
      final updatedItem = Map<String, dynamic>.from(widget.item);
      updatedItem['name'] = _nameController.text;
      updatedItem['unit_price'] = newUnitPrice;
      updatedItem['quantity'] = newQuantity;
      updatedItem['total_price'] = newUnitPrice * newQuantity;
      widget.onItemChanged(updatedItem);
      setState(() {
        _isEditing = false;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _cancelEdit() {
    _nameController.text = widget.item['name'];
    _unitPriceController.text = widget.item['unit_price'].toString();
    _quantityController.text = (widget.item['quantity'] ?? 1).toString();
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: widget.isHighlighted
            ? AppTheme.lightTheme.colorScheme.primaryContainer
            : AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isHighlighted
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.dividerColor,
          width: widget.isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _isEditing
                      ? TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Item Name',
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.next,
                        )
                      : Text(
                          widget.item['name'],
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                if (!_isEditing) ...[
                  SizedBox(width: 2.w),
                  ConfidenceIndicatorWidget(
                    confidence: widget.item['confidence']?.toDouble() ?? 0.0,
                  ),
                ],
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: _isEditing
                      ? TextFormField(
                          controller: _unitPriceController,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Unit Price',
                            prefixText: '\$',
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.next,
                        )
                      : Text(
                          '\$${widget.item['unit_price'].toStringAsFixed(2)} x ${widget.item['quantity']} = \$${widget.item['total_price'].toStringAsFixed(2)}',
                          style: AppTheme.getMonospaceStyle(
                            isLight: true,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                SizedBox(width: 2.w),
                // Quantity field
                _isEditing
                    ? SizedBox(
                        width: 20.w,
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Qty',
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _saveChanges(),
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme
                              .lightTheme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Qty: ',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme
                                    .onSecondaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${widget.item['quantity'] ?? 1}',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme
                                    .onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: widget.item['category'] != null
                      ? Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: AppTheme
                                .lightTheme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.item['category'],
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
                SizedBox(width: 2.w),
                if (_isEditing) ...[
                  IconButton(
                    onPressed: _cancelEdit,
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.lightTheme.colorScheme.error,
                    ),
                  ),
                  IconButton(
                    onPressed: _saveChanges,
                    icon: Icon(
                      Icons.check,
                      color: AppTheme.lightTheme.colorScheme.tertiary,
                    ),
                  ),
                ] else ...[
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                      HapticFeedback.selectionClick();
                    },
                    icon: Icon(
                      Icons.edit,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      widget.onItemDeleted(widget.item['id']);
                    },
                    icon: Icon(
                      Icons.delete,
                      color: AppTheme.lightTheme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
