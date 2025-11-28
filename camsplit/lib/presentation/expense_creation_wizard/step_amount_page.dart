import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/api_service.dart';
import 'models/expense_wizard_data.dart';
import 'models/receipt_item.dart';

class StepAmountPage extends StatefulWidget {
  final ExpenseWizardData data;
  final Function(ExpenseWizardData) onDataChanged;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  const StepAmountPage({
    Key? key,
    required this.data,
    required this.onDataChanged,
    required this.onNext,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<StepAmountPage> createState() => _StepAmountPageState();
}

class _StepAmountPageState extends State<StepAmountPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isScanning = false;
  File? _receiptImageFile;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.data.amount > 0 ? widget.data.amount.toStringAsFixed(2) : '';
    _titleController.text = widget.data.title;
    _amountController.addListener(_onAmountChanged);
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    widget.onDataChanged(widget.data.copyWith(amount: amount));
  }

  void _onTitleChanged() {
    widget.onDataChanged(widget.data.copyWith(title: _titleController.text));
  }

  Future<void> _pickAndScanReceipt() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isScanning = true;
        _receiptImageFile = File(image.path);
      });

      // Call OCR API
      final result = await ApiService.instance.processReceipt(_receiptImageFile!);
      
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        
        // Parse items
        final List<ReceiptItem> receiptItems = [];
        if (data['items'] != null && data['items'] is List) {
          final items = data['items'] as List;
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            final qty = (item['quantity'] ?? 1).toDouble();
            final unitPrice = (item['unit_price'] ?? item['price'] ?? 0.0).toDouble();
            final totalPrice = unitPrice * qty;

            receiptItems.add(ReceiptItem(
              id: 'item-${DateTime.now().millisecondsSinceEpoch}-$i',
              name: item['description'] ?? item['name'] ?? 'Unknown Item',
              quantity: qty,
              unitPrice: unitPrice,
              price: totalPrice,
              assignments: {},
              isCustomSplit: false,
            ));
          }
        }

        // Update wizard data
        widget.onDataChanged(
          widget.data.copyWith(
            amount: (data['total_amount'] ?? 0.0).toDouble(),
            title: data['title'] ?? data['merchant'] ?? widget.data.title,
            date: data['date'] ?? widget.data.date,
            category: data['category'] ?? widget.data.category,
            receiptImage: _receiptImageFile!.path,
            items: receiptItems,
          ),
        );

        // Update controllers
        _amountController.text = widget.data.amount.toStringAsFixed(2);
        _titleController.text = widget.data.title;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to read receipt. Please enter details manually.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Receipt scanning error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read receipt. Please enter details manually.'),
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

  void _removeReceipt() {
    setState(() {
      _receiptImageFile = null;
    });
    widget.onDataChanged(
      widget.data.copyWith(
        receiptImage: null,
        items: [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    onPressed: widget.onCancel,
                    child: Text(
                      'Discard',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ),
                  Text(
                    '1 of 3',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.data.validateStep1() ? widget.onNext : null,
                    child: Text(
                      'Next',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.data.validateStep1()
                            ? AppTheme.primaryLight
                            : AppTheme.textSecondaryLight.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 4.h),
                    // Amount Input
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 1.h, right: 1.w),
                            child: Text(
                              '€',
                              style: TextStyle(
                                fontSize: 36.sp,
                                color: AppTheme.textSecondaryLight,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 60.w,
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 56.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryLight,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                  fontSize: 56.sp,
                                  color: AppTheme.textSecondaryLight.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    // Title Input
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 80.w),
                      margin: EdgeInsets.symmetric(horizontal: 10.w),
                      child: TextField(
                        controller: _titleController,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'What is this for?',
                          hintStyle: TextStyle(
                            fontSize: 20.sp,
                            color: AppTheme.textSecondaryLight.withOpacity(0.5),
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.borderLight,
                              width: 2,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.borderLight,
                              width: 2,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppTheme.primaryLight,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    // AI Scanner Button or Receipt Preview
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 80.w),
                      margin: EdgeInsets.symmetric(horizontal: 10.w),
                      child: _receiptImageFile == null
                          ? _buildScanButton()
                          : _buildReceiptPreview(),
                    ),
                    // Items count badge
                    if (widget.data.items.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                            SizedBox(width: 1.w),
                            Text(
                              '${widget.data.items.length} items found',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 4.h),
                    // Footer hint
                    Text(
                      'Start by adding an amount or scanning a receipt',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE0E7FF), // indigo-50
            Color(0xFFF3E8FF), // purple-50
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFC7D2FE), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isScanning ? null : _pickAndScanReceipt,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isScanning) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Reading Receipt...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Scan Receipt with AI',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptPreview() {
    return Stack(
      children: [
        Container(
          height: 20.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
            image: _receiptImageFile != null
                ? DecorationImage(
                    image: FileImage(_receiptImageFile!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _receiptImageFile == null
              ? Center(
                  child: Icon(
                    Icons.receipt,
                    size: 48,
                    color: AppTheme.textSecondaryLight,
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        SizedBox(width: 1.w),
                        Text(
                          'Receipt Attached',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _removeReceipt,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
