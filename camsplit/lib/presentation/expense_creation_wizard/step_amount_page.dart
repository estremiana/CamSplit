import 'dart:io';
import 'dart:math' as math;
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
    // Explicitly preserve items when updating amount (prevents losing items when controller text is set)
    widget.onDataChanged(widget.data.copyWith(
      amount: amount,
      items: widget.data.items, // Preserve items
    ));
    setState(() {}); // Trigger rebuild to update width
  }

  void _onTitleChanged() {
    // Explicitly preserve items when updating title
    widget.onDataChanged(widget.data.copyWith(
      title: _titleController.text,
      items: widget.data.items, // Preserve items
    ));
  }

  Future<void> _pickAndScanReceipt() async {
    if (_isScanning) return;
    _showImageSourceDialog();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 1.h),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    'Select Image Source',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppTheme.primaryLight,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Camera',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    'Take a photo of your receipt',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: AppTheme.primaryLight,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Gallery',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  subtitle: Text(
                    'Choose from your photos',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.gallery);
                  },
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
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
        
        // Parse items (matching the working implementation in receipt_ocr_review)
        final List<ReceiptItem> receiptItems = [];
        if (data['items'] != null && data['items'] is List) {
          final items = data['items'] as List;
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            // Use total_price from backend (same as working implementation)
            var totalPrice = (item['total_price'] ?? 0.0).toDouble();
            final qty = (item['quantity'] ?? 1).toDouble();
            var unitPrice = (item['unit_price'] ?? 0.0).toDouble();
            
            // If total_price is missing or 0, calculate from unit_price * quantity (backend fallback logic)
            if (totalPrice <= 0 && unitPrice > 0) {
              totalPrice = unitPrice * qty;
            }
            // If unit_price is missing or 0, calculate from total_price / quantity (backend fallback logic)
            if (unitPrice <= 0 && totalPrice > 0 && qty > 0) {
              unitPrice = totalPrice / qty;
            }

            receiptItems.add(ReceiptItem(
              id: 'item-${DateTime.now().millisecondsSinceEpoch}-$i',
              name: item['description'] ?? item['name'] ?? 'Unknown Item',
              quantity: qty,
              unitPrice: unitPrice,
              price: totalPrice, // Use total_price from backend
              assignments: {},
              isCustomSplit: false,
            ));
          }
        }

        // Extract OCR values
        final ocrAmount = (data['total_amount'] ?? 0.0).toDouble();
        final ocrTitle = data['title'] ?? data['merchant'];
        final ocrDate = data['date'];
        final ocrCategory = data['category'];

        // Update wizard data with OCR results (always overwrite with OCR data)
        // Auto-set split type to items if items were detected
        final updatedData = widget.data.copyWith(
          amount: ocrAmount,
          title: ocrTitle != null && ocrTitle.toString().isNotEmpty 
              ? ocrTitle.toString() 
              : widget.data.title,
          date: ocrDate ?? widget.data.date,
          category: ocrCategory ?? widget.data.category,
          receiptImage: _receiptImageFile!.path,
          items: receiptItems,
          splitType: receiptItems.isNotEmpty ? SplitType.items : widget.data.splitType,
        );

        widget.onDataChanged(updatedData);

        // Update controllers with OCR results (always overwrite)
        // Temporarily remove listeners to prevent _onAmountChanged/_onTitleChanged from overwriting items
        _amountController.removeListener(_onAmountChanged);
        _titleController.removeListener(_onTitleChanged);
        
        _amountController.text = ocrAmount.toStringAsFixed(2);
        if (ocrTitle != null && ocrTitle.toString().isNotEmpty) {
          _titleController.text = ocrTitle.toString();
        }
        
        // Re-add listeners after updating controllers
        _amountController.addListener(_onAmountChanged);
        _titleController.addListener(_onTitleChanged);

        // Trigger rebuild to update button state
        if (mounted) {
          setState(() {});
        }
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
                      'Cancel',
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
              child: Column(
                children: [
                  // Spacer to push content above middle
                  Spacer(flex: 2),
                  // Amount Input - positioned above middle
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final text = _amountController.text.isEmpty ? '0' : _amountController.text;
                        
                        // Measure the euro symbol width
                        final euroPainter = TextPainter(
                          text: TextSpan(
                            text: '€',
                            style: TextStyle(
                              fontSize: 28.sp,
                              color: AppTheme.textSecondaryLight,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          textDirection: TextDirection.ltr,
                        );
                        euroPainter.layout();
                        final euroWidth = euroPainter.size.width;
                        
                        // Measure the amount text width
                        final textPainter = TextPainter(
                          text: TextSpan(
                            text: text,
                            style: TextStyle(
                              fontSize: 36.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryLight,
                            ),
                          ),
                          textDirection: TextDirection.ltr,
                        );
                        textPainter.layout();
                        final textWidth = textPainter.size.width;
                        
                        // Calculate max width: screen width minus euro symbol width, padding, and margins
                        final maxWidth = constraints.maxWidth - euroWidth - (1.w) - (4.w * 2) - 20;
                        // Ensure field is at least as wide as the text plus adequate padding for cursor
                        final minFieldWidth = textWidth + 30; // Adequate padding for cursor and rendering
                        final fieldWidth = math.min(minFieldWidth, maxWidth);
                        
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 1.w),
                              child: Text(
                                '€',
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  color: AppTheme.textSecondaryLight,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                scrollPadding: EdgeInsets.zero,
                                controller: _amountController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryLight,
                                ),
                                decoration: InputDecoration(
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    fontSize: 36.sp,
                                    color: AppTheme.textSecondaryLight.withOpacity(0.3),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                  isCollapsed: true,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Title Input
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 80.w),
                      margin: EdgeInsets.symmetric(horizontal: 10.w),
                      child: TextField(
                        controller: _titleController,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'What is this for?',
                          hintStyle: TextStyle(
                            fontSize: 18.sp,
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
                  ),
                  // Spacer to separate amount/title from scan button
                  Spacer(flex: 1),
                  // AI Scanner Button or Receipt Preview
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 80.w),
                      margin: EdgeInsets.symmetric(horizontal: 10.w),
                      child: _isScanning || _receiptImageFile == null
                          ? _buildScanButton()
                          : _buildReceiptPreview(),
                    ),
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
                  // Spacer to push footer to bottom
                  Spacer(flex: 2),
                  // Footer hint at bottom
                  Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: Text(
                      'Start by adding an amount or scanning a receipt',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondaryLight.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
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
