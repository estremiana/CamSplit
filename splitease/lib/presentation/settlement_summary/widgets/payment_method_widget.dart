import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PaymentMethodWidget extends StatefulWidget {
  final Map<String, dynamic> settlement;
  final bool isPrivacyMode;
  final Function(String) onPaymentComplete;

  const PaymentMethodWidget({
    super.key,
    required this.settlement,
    required this.isPrivacyMode,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentMethodWidget> createState() => _PaymentMethodWidgetState();
}

class _PaymentMethodWidgetState extends State<PaymentMethodWidget> {
  String? selectedMethod;
  bool isProcessing = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'name': 'Venmo',
      'icon': 'account_balance_wallet',
      'description': 'Instant transfer via Venmo',
      'fee': 0.0,
    },
    {
      'name': 'PayPal',
      'icon': 'payment',
      'description': 'Send via PayPal',
      'fee': 0.0,
    },
    {
      'name': 'Bank Transfer',
      'icon': 'account_balance',
      'description': '1-3 business days',
      'fee': 0.0,
    },
    {
      'name': 'Cash',
      'icon': 'local_atm',
      'description': 'Mark as paid in cash',
      'fee': 0.0,
    },
    {
      'name': 'Manual Confirmation',
      'icon': 'receipt',
      'description': 'Upload receipt manually',
      'fee': 0.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isOwed = widget.settlement.containsKey('debtor');
    final String personName =
        widget.settlement['creditor'] ?? widget.settlement['debtor'];
    final double amount = widget.settlement['amount'];

    return Container(
      padding: EdgeInsets.only(
        top: 2.h,
        left: 4.w,
        right: 4.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 2.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'payment',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOwed ? 'Request Payment' : 'Make Payment',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${isOwed ? 'From' : 'To'} $personName',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                widget.isPrivacyMode
                    ? '••••••'
                    : '\$${amount.toStringAsFixed(2)}',
                style: AppTheme.getMonospaceStyle(
                  isLight: true,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          // Payment methods
          Text(
            'Select Payment Method',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          ...paymentMethods.map((method) => _buildPaymentMethodOption(method)),
          SizedBox(height: 3.h),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedMethod != null && !isProcessing
                      ? _processPayment
                      : null,
                  child: isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.onPrimaryLight,
                            ),
                          ),
                        )
                      : Text(isOwed ? 'Send Request' : 'Pay Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(Map<String, dynamic> method) {
    final bool isSelected = selectedMethod == method['name'];

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            selectedMethod = method['name'];
          });
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
                : AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.borderLight,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
                      : AppTheme.borderLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CustomIconWidget(
                  iconName: method['icon'],
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.textSecondaryLight,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'],
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppTheme.lightTheme.primaryColor
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      method['description'],
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (method['fee'] > 0)
                Text(
                  '+\$${method['fee'].toStringAsFixed(2)}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              if (isSelected)
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (selectedMethod == null) return;

    setState(() {
      isProcessing = true;
    });

    HapticFeedback.mediumImpact();

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (selectedMethod == 'Manual Confirmation') {
      // Show receipt upload dialog
      await _showReceiptUploadDialog();
    } else {
      // Process payment through selected method
      await _processAutomaticPayment();
    }

    setState(() {
      isProcessing = false;
    });

    Navigator.pop(context);
    widget.onPaymentComplete(selectedMethod!);
  }

  Future<void> _showReceiptUploadDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please upload a receipt to confirm payment'),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Handle receipt upload
              },
              icon: CustomIconWidget(
                iconName: 'camera_alt',
                color: AppTheme.onPrimaryLight,
                size: 20,
              ),
              label: const Text('Take Photo'),
            ),
            SizedBox(height: 1.h),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Handle gallery selection
              },
              icon: CustomIconWidget(
                iconName: 'photo_library',
                color: AppTheme.lightTheme.primaryColor,
                size: 20,
              ),
              label: const Text('Choose from Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processAutomaticPayment() async {
    // Simulate API call for payment processing
    await Future.delayed(const Duration(seconds: 1));

    // Here you would integrate with actual payment APIs
    // For now, we'll just simulate success
  }
}
