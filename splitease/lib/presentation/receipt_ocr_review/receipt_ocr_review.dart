import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:math';

import '../../core/app_export.dart';
import '../../services/api_service.dart';
import './widgets/editable_item_card_widget.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/receipt_zoom_widget.dart';

class ReceiptOcrReview extends StatefulWidget {
  const ReceiptOcrReview({super.key});

  @override
  State<ReceiptOcrReview> createState() => _ReceiptOcrReviewState();
}

class _ReceiptOcrReviewState extends State<ReceiptOcrReview> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isAutoSaving = false;
  int _highlightedItemId = -1;
  final ApiService _apiService = ApiService.instance;

  // OCR extracted items
  List<Map<String, dynamic>> _extractedItems = [];

  final List<String> _categories = [
    'Main Course',
    'Appetizer',
    'Beverages',
    'Dessert',
    'Service',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOcrData();
      _startAutoSave();
    });
  }

  Future<void> _loadOcrData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the arguments from the previous screen
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['ocrResult'] != null) {
        // Use the OCR result directly if provided
        setState(() {
          final rand = Random();
          _extractedItems = List<Map<String, dynamic>>.from(args['ocrResult']['items'] ?? [])
            .map((item) {
              if (item.containsKey('description') && !item.containsKey('name')) {
                item['name'] = item['description'];
              }
              // Always assign a random id
              item['id'] = rand.nextInt(1 << 31);
              return item;
            }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load OCR data:  ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoSave() {
    // Simulate auto-save every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _isAutoSaving = true;
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _isAutoSaving = false;
            });
          }
        });
        _startAutoSave();
      }
    });
  }

  void _onItemChanged(Map<String, dynamic> updatedItem) {
    setState(() {
      final index =
          _extractedItems.indexWhere((item) => item['id'] == updatedItem['id']);
      if (index != -1) {
        _extractedItems[index] = updatedItem;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _onItemDeleted(int itemId) {
    final deletedItem =
        _extractedItems.firstWhere((item) => item['id'] == itemId);

    setState(() {
      _extractedItems.removeWhere((item) => item['id'] == itemId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedItem['name']} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _extractedItems.add(deletedItem);
              _extractedItems.sort((a, b) => a['id'].compareTo(b['id']));
            });
          },
        ),
      ),
    );
  }

  void _onItemTapped(int itemId) {
    setState(() {
      _highlightedItemId = itemId;
    });

    // Scroll to corresponding item in list
    final index = _extractedItems.indexWhere((item) => item['id'] == itemId);
    if (index != -1) {
      _scrollController.animateTo(
        index * 120.0, // Approximate item height
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _addNewItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddItemBottomSheet(),
    );
  }

  Widget _buildAddItemBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController unitPriceController = TextEditingController();
    String selectedCategory = _categories.first;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Add New Item',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'Enter item name',
              ),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: unitPriceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Unit Price',
                prefixText: '\$',
                isDense: true,
              ),
              textInputAction: TextInputAction.next,
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                selectedCategory = value!;
              },
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty && unitPriceController.text.isNotEmpty) {
                        final double? unitPrice = double.tryParse(unitPriceController.text);
                        final int quantity = 1;
                        if (unitPrice != null) {
                          setState(() {
                            final rand = Random();
                            _extractedItems.add({
                              'id': rand.nextInt(1 << 31),
                              'name': nameController.text,
                              'unit_price': unitPrice,
                              'quantity': quantity,
                              'total_price': unitPrice * quantity,
                              'category': selectedCategory,
                            });
                          });
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const Text('Add Item'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _continueToAssignment() {
    if (_extractedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to continue'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate processing delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.itemAssignment,
          arguments: _extractedItems,
        );
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  double _calculateTotal() {
    return _extractedItems.fold(0.0, (sum, item) => sum + item['total_price']);
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
              // Header with navigation and progress
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.cardColor,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.lightTheme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Back',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.secondary,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (_isAutoSaving)
                              Row(
                                children: [
                                  SizedBox(
                                    width: 4.w,
                                    height: 4.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme
                                            .lightTheme.colorScheme.tertiary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'Saving...',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.tertiary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : _continueToAssignment,
                          child: Text(
                            'Continue',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: _isLoading
                                  ? AppTheme.lightTheme.colorScheme.outline
                                  : AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ProgressIndicatorWidget(
                      currentStep: 1,
                      totalSteps: 3,
                      stepLabels: ['Capture', 'Review', 'Assign'],
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Receipt image with zoom
                      ReceiptZoomWidget(
                        imageUrl:
                            "https://images.pexels.com/photos/4386321/pexels-photo-4386321.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
                        items: _extractedItems,
                        onItemTapped: _onItemTapped,
                      ),

                      SizedBox(height: 3.h),

                      // Extracted items header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Extracted Items',
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_extractedItems.length} items',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 2.h),

                      // Items list
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _extractedItems.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 2.h),
                        itemBuilder: (context, index) {
                          final item = _extractedItems[index];
                          return EditableItemCardWidget(
                            item: item,
                            onItemChanged: _onItemChanged,
                            onItemDeleted: _onItemDeleted,
                            isHighlighted: _highlightedItemId == item['id'],
                          );
                        },
                      ),

                      SizedBox(height: 3.h),

                      // Add item button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _addNewItem,
                          icon: CustomIconWidget(
                            iconName: 'add',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 20,
                          ),
                          label: const Text('Add Missing Item'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                          ),
                        ),
                      ),

                      SizedBox(height: 4.h),

                      // Total summary
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
                            Text(
                              'Review Summary',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Items:',
                                  style:
                                      AppTheme.lightTheme.textTheme.bodyMedium,
                                ),
                                Text(
                                  '${_extractedItems.length}',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '\$${_calculateTotal().toStringAsFixed(2)}',
                                  style: AppTheme.getMonospaceStyle(
                                    isLight: true,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),

              // Bottom action button
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
                    onPressed: _isLoading ? null : _continueToAssignment,
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to Assignment',
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(
                                Icons.arrow_forward,
                                color:
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                              ),
                            ],
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
