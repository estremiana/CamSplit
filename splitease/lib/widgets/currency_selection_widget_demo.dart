import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:sizer/sizer.dart';

import '../theme/app_theme.dart';
import 'currency_selection_widget.dart';

/// Demo page showing different usage examples of CurrencySelectionWidget
/// This demonstrates the consistent currency selection interface across the app
class CurrencySelectionWidgetDemo extends StatefulWidget {
  const CurrencySelectionWidgetDemo({super.key});

  @override
  State<CurrencySelectionWidgetDemo> createState() => _CurrencySelectionWidgetDemoState();
}

class _CurrencySelectionWidgetDemoState extends State<CurrencySelectionWidgetDemo> {
  Currency? _profileCurrency;
  Currency? _groupCurrency;
  Currency? _expenseCurrency;
  Currency? _compactCurrency;

  @override
  void initState() {
    super.initState();
    // Initialize with some default currencies
    _profileCurrency = Currency(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      flag: '🇪🇺',
      number: 978,
      decimalDigits: 2,
      namePlural: 'Euros',
      symbolOnLeft: true,
      decimalSeparator: '.',
      thousandsSeparator: ',',
      spaceBetweenAmountAndSymbol: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'Currency Selection Widget Demo',
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Currency Selection Demo'),
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Currency Selection Widget Examples',
                    style: AppTheme.lightTheme.textTheme.headlineSmall,
                  ),
                  SizedBox(height: 3.h),

                  // Profile Settings Example
                  Text(
                    '1. Profile Settings Currency',
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 1.h),
                  CurrencySelectionWidget(
                    selectedCurrency: _profileCurrency,
                    onCurrencySelected: (Currency currency) {
                      setState(() {
                        _profileCurrency = currency;
                      });
                    },
                    labelText: 'Preferred Currency',
                    showFlag: true,
                    showCurrencyName: true,
                    showCurrencyCode: true,
                  ),
                  SizedBox(height: 3.h),

                  // Group Creation Example
                  Text(
                    '2. Group Creation Currency',
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 1.h),
                  CurrencySelectionWidget(
                    selectedCurrency: _groupCurrency,
                    onCurrencySelected: (Currency currency) {
                      setState(() {
                        _groupCurrency = currency;
                      });
                    },
                    labelText: 'Group Currency',
                    hintText: 'Select group currency',
                    showFlag: true,
                    showCurrencyName: true,
                    showCurrencyCode: true,
                  ),
                  SizedBox(height: 3.h),

                  // Expense Creation Example
                  Text(
                    '3. Expense Creation Currency',
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 1.h),
                  CurrencySelectionWidget(
                    selectedCurrency: _expenseCurrency,
                    onCurrencySelected: (Currency currency) {
                      setState(() {
                        _expenseCurrency = currency;
                      });
                    },
                    labelText: 'Expense Currency',
                    showFlag: true,
                    showCurrencyName: false, // Don't show name to save space
                    showCurrencyCode: true,
                  ),
                  SizedBox(height: 3.h),

                  // Compact Example (like in expense creation total field)
                  Text(
                    '4. Compact Currency Selection (Inline)',
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            hintText: '0.00',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      CurrencySelectionWidget(
                        selectedCurrency: _compactCurrency,
                        onCurrencySelected: (Currency currency) {
                          setState(() {
                            _compactCurrency = currency;
                          });
                        },
                        isCompact: true,
                        width: 80,
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),

                  // Read-only Example
                  Text(
                    '5. Read-only Currency Display',
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 1.h),
                  CurrencySelectionWidget(
                    selectedCurrency: _profileCurrency,
                    onCurrencySelected: (Currency currency) {
                      // This won't be called since it's read-only
                    },
                    labelText: 'Current Currency (Read-only)',
                    isReadOnly: true,
                    showFlag: true,
                    showCurrencyName: true,
                    showCurrencyCode: true,
                  ),
                  SizedBox(height: 3.h),

                  // Disabled Example
                  Text(
                    '6. Disabled Currency Selection',
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 1.h),
                  CurrencySelectionWidget(
                    selectedCurrency: null,
                    onCurrencySelected: (Currency currency) {
                      // This won't be called since it's disabled
                    },
                    labelText: 'Disabled Currency',
                    isEnabled: false,
                    hintText: 'Cannot select currency',
                  ),
                  SizedBox(height: 3.h),

                  // Current Selections Summary
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Selections:',
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Profile: ${_profileCurrency?.name ?? 'Not selected'} (${_profileCurrency?.symbol ?? 'N/A'})',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Group: ${_groupCurrency?.name ?? 'Not selected'} (${_groupCurrency?.symbol ?? 'N/A'})',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Expense: ${_expenseCurrency?.name ?? 'Not selected'} (${_expenseCurrency?.symbol ?? 'N/A'})',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Compact: ${_compactCurrency?.name ?? 'Not selected'} (${_compactCurrency?.symbol ?? 'N/A'})',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}