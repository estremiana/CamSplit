import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/wizard_expense_data.dart';
import '../models/receipt_item.dart';
import '../../../services/currency_service.dart';
import '../../../services/receipt_scanner_service.dart';
import 'package:currency_picker/currency_picker.dart';

/// First page of the expense wizard for entering amount and title
/// Supports optional receipt scanning with AI
class StepAmountPage extends StatefulWidget {
  final WizardExpenseData wizardData;
  final VoidCallback onNext;
  final VoidCallback onDiscard;
  final Function(WizardExpenseData) onDataChanged;

  const StepAmountPage({
    super.key,
    required this.wizardData,
    required this.onNext,
    required this.onDiscard,
    required this.onDataChanged,
  });

  @override
  State<StepAmountPage> createState() => _StepAmountPageState();
}

class _StepAmountPageState extends State<StepAmountPage> {
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late Currency _currency;
  bool _isScanning = false;
  File? _receiptImageFile;

  @override
  void initState() {
    super.initState();
    _currency = CamSplitCurrencyService.getUserPreferredCurrency();
    _amountController = TextEditingController(
      text: widget.wizardData.amount > 0 ? widget.wizardData.amount.toStringAsFixed(2) : '',
    );
    _titleController = TextEditingController(text: widget.wizardData.title);

    // Listen to changes and update wizard data
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
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    widget.onDataChanged(widget.wizardData.copyWith(amount: amount));
  }

  void _onTitleChanged() {
    widget.onDataChanged(widget.wizardData.copyWith(title: _titleController.text));
  }

  bool _isAmountValid() {
    return widget.wizardData.isAmountValid();
  }

  void _handleNext() {
    if (_isAmountValid()) {
      widget.onNext();
    }
  }

  /// Show dialog to select image source (camera or gallery)
  Future<void> _showImageSourceDialog() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      await _scanReceipt(source);
    }
  }

  /// Scan receipt from selected source
  Future<void> _scanReceipt(ImageSource source) async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Pick image from selected source
      File? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await ReceiptScannerService.instance.pickFromCamera();
      } else {
        imageFile = await ReceiptScannerService.instance.pickFromGallery();
      }

      if (imageFile == null) {
        // User cancelled
        setState(() {
          _isScanning = false;
        });
        return;
      }

      // Process the image with AI/OCR
      final scannedData = await ReceiptScannerService.instance.processReceiptImage(imageFile);

      // Convert scanned items to ReceiptItem objects
      final receiptItems = scannedData.items.map((scannedItem) {
        final quantity = scannedItem.quantity?.toDouble() ?? 1.0;
        final unitPrice = scannedItem.price / quantity;
        
        return ReceiptItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + scannedItem.name.hashCode.toString(),
          name: scannedItem.name,
          quantity: quantity,
          unitPrice: unitPrice,
          price: scannedItem.price,
        );
      }).toList();

      // Update wizard data with scanned information
      final updatedData = widget.wizardData.copyWith(
        amount: scannedData.total ?? widget.wizardData.amount,
        title: scannedData.merchant ?? widget.wizardData.title,
        receiptImage: imageFile.path,
        items: receiptItems,
      );

      widget.onDataChanged(updatedData);

      // Update local controllers to reflect the changes
      if (scannedData.total != null && scannedData.total! > 0) {
        _amountController.text = scannedData.total!.toStringAsFixed(2);
      }
      if (scannedData.merchant != null && scannedData.merchant!.isNotEmpty) {
        _titleController.text = scannedData.merchant!;
      }

      setState(() {
        _receiptImageFile = imageFile;
        _isScanning = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt scanned! Found ${scannedData.items.length} items'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan receipt: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAmountValid = _isAmountValid();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator with animation
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      'Amount & Scan',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Page 1 of 3',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // Amount input section
                    Text(
                      'How much?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Large centered amount input with currency symbol and animated border
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAmountValid 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.outline,
                          width: 2,
                        ),
                        boxShadow: isAmountValid
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Currency symbol
                          Text(
                            _currency.symbol,
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Amount input
                          Flexible(
                            child: IntrinsicWidth(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                style: theme.textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  hintText: '0.00',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                autofocus: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title input field
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'e.g., Dinner at restaurant',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 32),

                    // Scan Receipt button with loading animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: OutlinedButton.icon(
                        onPressed: _isScanning ? null : _showImageSourceDialog,
                        icon: _isScanning 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : const Icon(Icons.camera_alt_outlined),
                        label: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _isScanning ? 'Reading Receipt...' : 'Scan Receipt with AI',
                            key: ValueKey<bool>(_isScanning),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Receipt preview (shown after scanning) with fade-in animation
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          ),
                        );
                      },
                      child: (widget.wizardData.receiptImage != null && 
                              widget.wizardData.receiptImage!.isNotEmpty)
                          ? Container(
                              key: const ValueKey('receipt-preview'),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _receiptImageFile != null
                                        ? Image.file(
                                            _receiptImageFile!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surface,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.receipt_long),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Items found badge
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Receipt attached',
                                          style: theme.textTheme.titleSmall,
                                        ),
                                        if (widget.wizardData.items.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primaryContainer,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${widget.wizardData.items.length} items found',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Remove button
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _receiptImageFile = null;
                                      });
                                      widget.onDataChanged(
                                        widget.wizardData.copyWith(
                                          receiptImage: '',
                                          items: [],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Remove receipt',
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('no-receipt')),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Discard button
                  TextButton(
                    onPressed: widget.onDiscard,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: const Text('Discard'),
                  ),
                  const Spacer(),
                  // Next button
                  ElevatedButton(
                    onPressed: isAmountValid ? _handleNext : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
