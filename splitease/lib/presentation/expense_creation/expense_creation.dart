import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/add_item_bottom_sheet.dart';
import './widgets/expense_details_widget.dart';
import './widgets/ocr_item_card_widget.dart';
import './widgets/receipt_image_widget.dart';
import './widgets/split_options_widget.dart';

class ExpenseCreation extends StatefulWidget {
  const ExpenseCreation({super.key});

  @override
  State<ExpenseCreation> createState() => _ExpenseCreationState();
}

class _ExpenseCreationState extends State<ExpenseCreation>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _tipController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _isDraft = false;
  String _selectedGroup = 'Roommates';
  String _selectedCategory = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();
  String _splitType = 'equal';
  double _totalAmount = 0.0;
  double _taxAmount = 0.0;
  double _tipAmount = 0.0;

  // Mock data
  final List<Map<String, dynamic>> _ocrItems = [
    {
      "id": 1,
      "name": "Chicken Sandwich",
      "unit_price": 12.99,
      "total_price": 12.99,
      "quantity": 1,
      "assignedTo": "You",
      "category": "Food",
    },
    {
      "id": 2,
      "name": "French Fries",
      "unit_price": 4.50,
      "total_price": 9.00,
      "quantity": 2,
      "assignedTo": "Sarah",
      "category": "Food",
    },
    {
      "id": 3,
      "name": "Coca Cola",
      "unit_price": 2.99,
      "total_price": 2.99,
      "quantity": 1,
      "assignedTo": "Mike",
      "category": "Beverages",
    },
  ];

  final List<Map<String, dynamic>> _groupMembers = [
    {
      "id": 1,
      "name": "You",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
    },
    {
      "id": 2,
      "name": "Sarah",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
    },
    {
      "id": 3,
      "name": "Mike",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
    },
    {
      "id": 4,
      "name": "Emma",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png"
    },
  ];

  final List<String> _groups = [
    'Roommates',
    'Work Team',
    'Travel Group',
    'Friends'
  ];
  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Healthcare',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _calculateTotal();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    _taxController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    double itemsTotal = _ocrItems.fold(
        0.0,
        (sum, item) =>
            sum + (item['total_price'] as double));
    _totalAmount = itemsTotal + _taxAmount + _tipAmount;
    setState(() {});
  }

  void _updateItemQuantity(int itemId, int newQuantity) {
    setState(() {
      final itemIndex = _ocrItems.indexWhere((item) => item['id'] == itemId);
      if (itemIndex != -1) {
        _ocrItems[itemIndex]['quantity'] = newQuantity;
        _ocrItems[itemIndex]['total_price'] = (_ocrItems[itemIndex]['unit_price'] as double) * newQuantity;
        _calculateTotal();
      }
    });
  }

  void _updateItemAssignment(int itemId, String assignedTo) {
    setState(() {
      final itemIndex = _ocrItems.indexWhere((item) => item['id'] == itemId);
      if (itemIndex != -1) {
        _ocrItems[itemIndex]['assignedTo'] = assignedTo;
      }
    });
  }

  void _removeItem(int itemId) {
    setState(() {
      _ocrItems.removeWhere((item) => item['id'] == itemId);
      _calculateTotal();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Implement undo functionality
          },
        ),
      ),
    );
  }

  void _addManualItem(Map<String, dynamic> newItem) {
    setState(() {
      newItem['total_price'] = (newItem['unit_price'] as double) * (newItem['quantity'] as int);
      _ocrItems.add(newItem);
      _calculateTotal();
    });
  }

  void _showAddItemBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemBottomSheet(
        groupMembers: _groupMembers,
        onAddItem: _addManualItem,
      ),
    );
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _updateTax(String value) {
    final double? taxPercent = double.tryParse(value);
    if (taxPercent != null) {
      final double itemsTotal = _ocrItems.fold(
          0.0,
          (sum, item) =>
              sum + (item['total_price'] as double));
      _taxAmount = itemsTotal * (taxPercent / 100);
      _calculateTotal();
      HapticFeedback.lightImpact();
    }
  }

  void _updateTip(String value) {
    final double? tipPercent = double.tryParse(value);
    if (tipPercent != null) {
      final double itemsTotal = _ocrItems.fold(
          0.0,
          (sum, item) =>
              sum + (item['total_price'] as double));
      _tipAmount = itemsTotal * (tipPercent / 100);
      _calculateTotal();
      HapticFeedback.lightImpact();
    }
  }

  void _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense created successfully!')),
      );
      Navigator.pushReplacementNamed(context, '/expense-dashboard');
    }
  }

  void _saveDraft() {
    setState(() {
      _isDraft = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved')),
    );
  }

  Map<String, double> _calculateMemberBreakdown() {
    Map<String, double> breakdown = {};

    for (var member in _groupMembers) {
      breakdown[member['name']] = 0.0;
    }

    if (_splitType == 'equal') {
      final double perPerson = _totalAmount / _groupMembers.length;
      for (var member in _groupMembers) {
        breakdown[member['name']] = perPerson;
      }
    } else {
      // Custom assignment based on items
      for (var item in _ocrItems) {
        final String assignedTo = item['assignedTo'];
        final double itemTotal =
            (item['total_price'] as double);
        breakdown[assignedTo] = (breakdown[assignedTo] ?? 0.0) + itemTotal;
      }

      // Distribute tax and tip equally
      final double taxTipPerPerson =
          (_taxAmount + _tipAmount) / _groupMembers.length;
      for (var member in _groupMembers) {
        breakdown[member['name']] =
            (breakdown[member['name']] ?? 0.0) + taxTipPerPerson;
      }
    }

    return breakdown;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Sticky Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.cardColor,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.lightTheme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    Text(
                      'Create Expense',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: _saveDraft,
                      child: Text(
                        'Draft',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Receipt Image
                      ReceiptImageWidget(
                        imageUrl:
                            "https://images.pexels.com/photos/4386321/pexels-photo-4386321.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
                      ),

                      SizedBox(height: 3.h),

                      // OCR Items Section
                      Text(
                        'Extracted Items',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ocrItems.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 1.h),
                        itemBuilder: (context, index) {
                          final item = _ocrItems[index];
                          return OcrItemCardWidget(
                            item: item,
                            groupMembers: _groupMembers,
                            onQuantityChanged: _updateItemQuantity,
                            onAssignmentChanged: _updateItemAssignment,
                            onRemove: _removeItem,
                          );
                        },
                      ),

                      SizedBox(height: 2.h),

                      // Add Item Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showAddItemBottomSheet,
                          icon: CustomIconWidget(
                            iconName: 'add',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 20,
                          ),
                          label: Text('Add Item'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          ),
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Expense Details
                      ExpenseDetailsWidget(
                        selectedGroup: _selectedGroup,
                        selectedCategory: _selectedCategory,
                        selectedDate: _selectedDate,
                        notesController: _notesController,
                        groups: _groups,
                        categories: _categories,
                        onGroupChanged: (value) =>
                            setState(() => _selectedGroup = value),
                        onCategoryChanged: (value) =>
                            setState(() => _selectedCategory = value),
                        onDateTap: _selectDate,
                      ),

                      SizedBox(height: 3.h),

                      // Split Options
                      SplitOptionsWidget(
                        splitType: _splitType,
                        onSplitTypeChanged: (value) =>
                            setState(() => _splitType = value),
                      ),

                      SizedBox(height: 3.h),

                      // Tax and Tip
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _taxController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Tax (%)',
                                hintText: '0.00',
                                prefixIcon: CustomIconWidget(
                                  iconName: 'receipt',
                                  color:
                                      AppTheme.lightTheme.colorScheme.secondary,
                                  size: 20,
                                ),
                              ),
                              onChanged: _updateTax,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: TextFormField(
                              controller: _tipController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Tip (%)',
                                hintText: '0.00',
                                prefixIcon: CustomIconWidget(
                                  iconName: 'star',
                                  color:
                                      AppTheme.lightTheme.colorScheme.secondary,
                                  size: 20,
                                ),
                              ),
                              onChanged: _updateTip,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      // Total Amount Display
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.lightTheme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '\$${_totalAmount.toStringAsFixed(2)}',
                                  style: AppTheme.getMonospaceStyle(
                                    isLight: true,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Member Breakdown:',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            ..._calculateMemberBreakdown().entries.map(
                                  (entry) => Padding(
                                    padding: EdgeInsets.only(bottom: 0.5.h),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: AppTheme
                                              .lightTheme.textTheme.bodyMedium,
                                        ),
                                        Text(
                                          '\$${entry.value.toStringAsFixed(2)}',
                                          style: AppTheme.getMonospaceStyle(
                                            isLight: true,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),

                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.cardColor,
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.lightTheme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveExpense,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Create Expense',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
