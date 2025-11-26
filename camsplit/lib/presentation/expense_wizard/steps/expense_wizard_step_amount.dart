import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/receipt_item.dart';
import '../../../services/api_service.dart';
import '../../../presentation/camera_capture/expense_photo_capture.dart';

class ExpenseWizardStepAmount extends StatefulWidget {
  final double amount;
  final String title;
  final String? receiptImage;
  final List<ReceiptItem> items;
  final Function(double) onAmountChanged;
  final Function(String) onTitleChanged;
  final Function(Map<String, dynamic>) onReceiptDataChanged;
  final VoidCallback? onNext;
  final VoidCallback? onCancel;

  const ExpenseWizardStepAmount({
    super.key,
    required this.amount,
    required this.title,
    this.receiptImage,
    required this.items,
    required this.onAmountChanged,
    required this.onTitleChanged,
    required this.onReceiptDataChanged,
    this.onNext,
    this.onCancel,
  });

  @override
  State<ExpenseWizardStepAmount> createState() => _ExpenseWizardStepAmountState();
}

class _ExpenseWizardStepAmountState extends State<ExpenseWizardStepAmount> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.amount > 0 ? widget.amount.toStringAsFixed(2) : '';
    _titleController.text = widget.title;
    _amountController.addListener(_onAmountChanged);
    _titleController.addListener(_onTitleChanged);
  }

  void _onAmountChanged() {
    final value = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    widget.onAmountChanged(value);
  }

  void _onTitleChanged() {
    widget.onTitleChanged(_titleController.text);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _titleController.removeListener(_onTitleChanged);
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    try {
      final result = await ExpensePhotoCapture.showExpensePhotoCaptureWithResult(context);
      
      if (result != null && result['success'] == true && result['imagePath'] != null) {
        setState(() {
          _isScanning = true;
        });

        try {
          // Process receipt with OCR
          final ocrResponse = await ApiService.instance.processReceipt(File(result['imagePath']));
          
          if (ocrResponse['success'] == true && ocrResponse['data'] != null) {
            final data = ocrResponse['data'];
            
            // Map OCR response to ReceiptItem list
            final items = <ReceiptItem>[];
            if (data['items'] != null && data['items'] is List) {
              int index = 0;
              for (var itemData in data['items']) {
                final qty = (itemData['quantity'] ?? 1).toDouble();
                final unitPrice = (itemData['price'] ?? itemData['unit_price'] ?? 0.0).toDouble();
                final totalPrice = unitPrice * qty;

                items.add(ReceiptItem(
                  id: 'item-${DateTime.now().millisecondsSinceEpoch}-$index',
                  name: itemData['name'] ?? 'Item',
                  unitPrice: unitPrice,
                  quantity: qty,
                  totalPrice: totalPrice,
                ));
                index++;
              }
            }

            // Calculate total from items if not provided
            double total = data['total']?.toDouble() ?? 0.0;
            if (total == 0 && items.isNotEmpty) {
              total = items.fold(0.0, (sum, item) => sum + item.totalPrice);
            }

            widget.onReceiptDataChanged({
              'receiptImage': result['imagePath'],
              'items': items,
              'amount': total,
              'title': data['merchant'] ?? widget.title,
              'date': data['date'],
              'category': data['category'] ?? 'Food & Dining',
            });

            // Update amount controller
            if (total > 0) {
              _amountController.text = total.toStringAsFixed(2);
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to read receipt: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isScanning = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'Discard',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14.sp,
                  ),
                ),
              ),
              Text(
                '1 of 3',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                  color: Colors.grey[900],
                ),
              ),
              TextButton(
                onPressed: widget.onNext,
                child: Text(
                  'Next',
                  style: TextStyle(
                    color: widget.onNext != null 
                        ? AppTheme.lightTheme.primaryColor 
                        : Colors.grey[300],
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Amount Input
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Amount field
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 1.h, right: 1.w),
                      child: Text(
                        '€',
                        style: TextStyle(
                          fontSize: 24.sp,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60.w,
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: Colors.grey[200],
                            fontSize: 48.sp,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Title input
                SizedBox(
                  width: 80.w,
                  child: TextField(
                    controller: _titleController,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.grey[900],
                    ),
                    decoration: InputDecoration(
                      hintText: 'What is this for?',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 18.sp,
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[100]!, width: 2),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[100]!, width: 2),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppTheme.lightTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 6.h),

                // Scan Receipt Button
                SizedBox(
                  width: 80.w,
                  child: widget.receiptImage == null
                      ? ElevatedButton(
                          onPressed: _isScanning ? null : _scanReceipt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 4.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: AppTheme.lightTheme.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.all(
                              AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                            ),
                          ),
                          child: _isScanning
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppTheme.lightTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Reading Receipt...',
                                      style: TextStyle(
                                        color: AppTheme.lightTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome,
                                        color: AppTheme.lightTheme.primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'Scan Receipt with AI',
                                      style: TextStyle(
                                        color: AppTheme.lightTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                        )
                      : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(widget.receiptImage!),
                                width: double.infinity,
                                height: 20.h,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () {
                                  widget.onReceiptDataChanged({
                                    'receiptImage': null,
                                    'items': <ReceiptItem>[],
                                  });
                                },
                                icon: const Icon(Icons.close, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                // Items count badge
                if (widget.items.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green[100]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.green[700], size: 16),
                          SizedBox(width: 1.w),
                          Text(
                            '${widget.items.length} items found',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Footer hint
          Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Text(
              'Start by adding an amount or scanning a receipt',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

