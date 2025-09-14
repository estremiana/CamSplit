import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AddItemBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> groupMembers;
  final Function(Map<String, dynamic>) onAddItem;

  const AddItemBottomSheet({
    super.key,
    required this.groupMembers,
    required this.onAddItem,
  });

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();

  int _quantity = 1;
  String _assignedTo = 'You';

  @override
  void initState() {
    super.initState();
    _assignedTo = widget.groupMembers.first['name'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) return;

    final double? unitPrice = double.tryParse(_unitPriceController.text);
    if (unitPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid unit price')),
      );
      return;
    }
    final int quantity = _quantity;
    final double totalPrice = unitPrice * quantity;
    final newItem = {
      "id": DateTime.now().millisecondsSinceEpoch,
      "name": _nameController.text.trim(),
      "unit_price": unitPrice,
      "total_price": totalPrice,
      "quantity": quantity,
      "assignedTo": _assignedTo,
      "category": "Manual",
    };
    widget.onAddItem(newItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 4.w,
          right: 4.w,
          top: 2.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 2.h,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // Title
              Text(
                'Add Manual Item',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 3.h),

              // Item Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'Enter item name',
                  prefixIcon: CustomIconWidget(
                    iconName: 'shopping_cart',
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    size: 20,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),

              SizedBox(height: 2.h),

              // Unit Price
              TextFormField(
                controller: _unitPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Unit Price',
                  hintText: '0.00',
                  prefixIcon: CustomIconWidget(
                    iconName: 'attach_money',
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    size: 20,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a unit price';
                  }
                  final double? unitPrice = double.tryParse(value);
                  if (unitPrice == null || unitPrice <= 0) {
                    return 'Please enter a valid unit price';
                  }
                  return null;
                },
              ),

              SizedBox(height: 2.h),

              // Quantity
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quantity',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.lightTheme.dividerColor,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          icon: CustomIconWidget(
                            iconName: 'remove',
                            color: _quantity > 1
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.secondary,
                            size: 20,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 3.w),
                          child: Text(
                            _quantity.toString(),
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _quantity++),
                          icon: CustomIconWidget(
                            iconName: 'add',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Assign to
              DropdownButtonFormField<String>(
                value: _assignedTo,
                decoration: InputDecoration(
                  labelText: 'Assign to',
                  prefixIcon: CustomIconWidget(
                    iconName: 'person',
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    size: 20,
                  ),
                ),
                items: (widget.groupMembers as List)
                    .map<DropdownMenuItem<String>>((member) {
                  return DropdownMenuItem<String>(
                    value: member['name'],
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
                          child: ClipOval(
                            child: CustomImageWidget(
                              imageUrl: member['avatar'],
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              userName: member['name'],
                            ),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(member['name']),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _assignedTo = value);
                  }
                },
              ),

              SizedBox(height: 4.h),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addItem,
                      child: Text('Add Item'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
