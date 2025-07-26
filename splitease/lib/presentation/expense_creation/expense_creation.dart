import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/receipt_mode_data.dart';
import '../../models/receipt_mode_config.dart';
import '../../models/mock_group_data.dart';
import './widgets/expense_details_widget.dart';
import './widgets/receipt_image_widget.dart';
import './widgets/split_options_widget.dart';
import 'package:currency_picker/currency_picker.dart';

class ExpenseCreation extends StatefulWidget {
  final String mode; // 'manual' or 'receipt'
  final ReceiptModeData? receiptData; // New parameter for receipt mode
  const ExpenseCreation({super.key, this.mode = 'manual', this.receiptData});

  @override
  State<ExpenseCreation> createState() => _ExpenseCreationState();
}

class _ExpenseCreationState extends State<ExpenseCreation>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String mode;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  Currency _currency = Currency(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    flag: 'EUR',
    number: 978,
    decimalDigits: 2,
    namePlural: 'Euros',
    symbolOnLeft: false,
    decimalSeparator: ',',
    thousandsSeparator: '.',
    spaceBetweenAmountAndSymbol: true,
  );

  // State variables
  bool _isLoading = false;
  bool _isDraft = false;
  String _selectedGroup = 'Weekend Getaway 🏖️';
  String _selectedCategory = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();
  String _splitType = 'equal';
  double _totalAmount = 0.0;
  
  // Receipt mode state
  bool _isReceiptMode = false;
  ReceiptModeData? _receiptData;
  ReceiptModeConfig _receiptModeConfig = ReceiptModeConfig.manualMode;
  Map<String, double> _prefilledCustomAmounts = {};

  // Group members - populated from receipt data or user selection
  List<Map<String, dynamic>> _groupMembers = [];

  // Get groups from mock data to match item assignment page
  List<String> get _groups {
    final mockGroups = MockGroupData.getGroupsSortedByMostRecent();
    return mockGroups.map((group) => group.name).toList();
  }
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
    mode = widget.mode;
    _totalController.addListener(_onTotalChanged);
    
    // Initialize receipt mode detection and state
    _initializeReceiptMode();
    
    // Defer reading arguments until after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromArguments();
    });
  }

  void _initializeReceiptMode() {
    // Check if we're in receipt mode
    _isReceiptMode = mode == 'receipt' || widget.receiptData != null;
    
    if (_isReceiptMode) {
      // Set receipt mode configuration
      _receiptModeConfig = ReceiptModeConfig.receiptMode;
      
      // Initialize receipt data
      if (widget.receiptData != null) {
        _receiptData = widget.receiptData;
        
        // Validate receipt data
        final validationError = _receiptData!.validate();
        if (validationError != null) {
          // Log error and fallback to manual mode
          debugPrint('Receipt mode validation error: $validationError');
          _fallbackToManualMode('Invalid receipt data: $validationError');
          return;
        }
        
        // Pre-fill data from receipt
        _initializeFromReceiptData();
      }
    } else {
      _receiptModeConfig = ReceiptModeConfig.manualMode;
    }
  }

  void _initializeFromReceiptData() {
    if (_receiptData == null) return;
    
    setState(() {
      // Set total amount
      _totalAmount = _receiptData!.total;
      _totalController.text = _totalAmount.toStringAsFixed(2);
      
      // Set split type to custom for receipt mode
      _splitType = _receiptModeConfig.defaultSplitType;
      
      // Pre-fill custom amounts
      _prefilledCustomAmounts = {};
      for (var participantAmount in _receiptData!.participantAmounts) {
        _prefilledCustomAmounts[participantAmount.name] = participantAmount.amount;
      }
      
      // Set selected group from receipt data
      if (_receiptData!.selectedGroupName != null) {
        final selectedGroupName = _receiptData!.selectedGroupName!;
        // Check if the selected group exists in available groups
        if (_groups.contains(selectedGroupName)) {
          _selectedGroup = selectedGroupName;
        } else {
          // If not found, use the first available group as fallback
          _selectedGroup = _groups.isNotEmpty ? _groups.first : 'Weekend Getaway 🏖️';
          debugPrint('Selected group "$selectedGroupName" not found in available groups, using fallback: $_selectedGroup');
        }
      }
      
      // Update group members from receipt data
      if (_receiptData!.groupMembers.isNotEmpty) {
        // Clear existing group members and use the ones from receipt data
        _groupMembers.clear();
        _groupMembers.addAll(_receiptData!.groupMembers);
      }
    });
  }

  void _fallbackToManualMode(String errorMessage) {
    setState(() {
      _isReceiptMode = false;
      _receiptModeConfig = ReceiptModeConfig.manualMode;
      _receiptData = null;
      _prefilledCustomAmounts = {};
      mode = 'manual';
    });
    
    // Show error to user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to manual mode: $errorMessage'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _initializeFromArguments() {
    // Read arguments for receipt mode initialization
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null && !_isReceiptMode) {
      // Handle backward compatibility for receipt mode via arguments
      if (args['receiptData'] != null) {
        try {
          final receiptDataJson = args['receiptData'] as Map<String, dynamic>;
          final receiptData = ReceiptModeData.fromJson(receiptDataJson);
          
          // Validate the data
          final validationError = receiptData.validate();
          if (validationError != null) {
            _fallbackToManualMode('Invalid receipt data from arguments: $validationError');
            return;
          }
          
          // Switch to receipt mode
          setState(() {
            _isReceiptMode = true;
            _receiptModeConfig = ReceiptModeConfig.receiptMode;
            _receiptData = receiptData;
            mode = 'receipt';
          });
          
          _initializeFromReceiptData();
        } catch (e) {
          _fallbackToManualMode('Failed to parse receipt data: $e');
        }
      }
      // Maintain backward compatibility with direct total argument
      else if (args['total'] != null && mode == 'receipt') {
        setState(() {
          _totalAmount = (args['total'] as num).toDouble();
          _totalController.text = _totalAmount.toStringAsFixed(2);
        });
      }
    } else if (!_isReceiptMode) {
      _calculateTotal();
      _totalController.text = '';
    }
  }

  void _onTotalChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    _totalController.removeListener(_onTotalChanged);
    _totalController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    double itemsTotal = 0.0; // No items to sum up
    _totalAmount = itemsTotal;
    if (mode == 'receipt') {
      _totalController.text = _totalAmount.toStringAsFixed(2);
    }
    setState(() {});
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

  void _saveExpense() async {
    // Validate form with receipt mode constraints
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Additional validation for receipt mode
      if (_isReceiptMode && _receiptData != null) {
        final validationError = _receiptData!.validate();
        if (validationError != null) {
          throw Exception('Receipt data validation failed: $validationError');
        }
      }

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isReceiptMode 
              ? 'Receipt expense created successfully!' 
              : 'Expense created successfully!'),
          ),
        );
        Navigator.pushReplacementNamed(context, '/expense-dashboard');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _validateForm() {
    // Standard form validation
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Receipt mode specific validation
    if (_isReceiptMode) {
      // Ensure receipt data is valid
      if (_receiptData == null) {
        _showValidationError('Receipt data is missing');
        return false;
      }

      // Validate receipt data integrity
      final validationError = _receiptData!.validate();
      if (validationError != null) {
        _showValidationError('Receipt validation failed: $validationError');
        return false;
      }

      // Ensure total amount matches receipt data
      double parsedTotal = double.tryParse(_totalController.text.replaceAll(',', '.')) ?? 0.0;
      if ((parsedTotal - _receiptData!.total).abs() > 0.01) {
        _showValidationError('Total amount does not match receipt data');
        return false;
      }

      // Ensure split type is custom for receipt mode
      if (_splitType != 'custom') {
        _showValidationError('Receipt mode requires custom split type');
        return false;
      }
    } else {
      // Manual mode validation
      double parsedTotal = double.tryParse(_totalController.text.replaceAll(',', '.')) ?? 0.0;
      if (parsedTotal <= 0) {
        _showValidationError('Total amount must be greater than zero');
        return false;
      }
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _saveDraft() {
    setState(() {
      _isDraft = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved')),
    );
  }

  void _onCurrencyChanged(Currency? value) {
    if (value != null) {
      setState(() {
        _currency = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double parsedTotal = double.tryParse(_totalController.text.replaceAll(',', '.')) ?? 0.0;
    final symbol = _currency.symbol;
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Create Expense',
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

                      // Expense Details
                      ExpenseDetailsWidget(
                        selectedGroup: _selectedGroup,
                        selectedCategory: _selectedCategory,
                        selectedDate: _selectedDate,
                        notesController: _notesController,
                        groups: _groups,
                        categories: _categories,
                        onGroupChanged: _receiptModeConfig.isGroupEditable 
                            ? (value) => setState(() => _selectedGroup = value)
                            : null,
                        onCategoryChanged: (value) =>
                            setState(() => _selectedCategory = value),
                        onDateTap: _selectDate,
                        totalController: _totalController,
                        currency: _currency,
                        onCurrencyChanged: _onCurrencyChanged,
                        mode: mode,
                        isReceiptMode: _isReceiptMode,
                        receiptModeConfig: _receiptModeConfig,
                      ),

                      SizedBox(height: 3.h),

                      // Split Options
                      SplitOptionsWidget(
                        splitType: _splitType,
                        onSplitTypeChanged: _receiptModeConfig.isSplitTypeEditable
                            ? (value) => setState(() => _splitType = value)
                            : null,
                        groupMembers: _isReceiptMode && _receiptData != null 
                            ? _receiptData!.groupMembers 
                            : _groupMembers,
                        totalAmount: parsedTotal,
                        currencySymbol: _currency.symbol,
                        isReceiptMode: _isReceiptMode,
                        prefilledCustomAmounts: _isReceiptMode ? _prefilledCustomAmounts : null,
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
