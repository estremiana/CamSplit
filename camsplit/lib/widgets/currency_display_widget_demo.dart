import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:sizer/sizer.dart';

import '../theme/app_theme.dart';
import 'currency_display_widget.dart';

/// Demo page showing different usage examples of CurrencyDisplayWidget
/// This demonstrates the consistent currency amount display interface across the app
class CurrencyDisplayWidgetDemo extends StatefulWidget {
  const CurrencyDisplayWidgetDemo({super.key});

  @override
  State<CurrencyDisplayWidgetDemo> createState() => _CurrencyDisplayWidgetDemoState();
}

class _CurrencyDisplayWidgetDemoState extends State<CurrencyDisplayWidgetDemo> {
  Currency _selectedCurrency = Currency(
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

  final double _testAmount = 1234.56;
  final double _largeAmount = 1234567.89;
  final double _negativeAmount = -567.89;
  final double _zeroAmount = 0.0;
  final double _smallAmount = 0.99;

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'Currency Display Widget Demo',
          theme: AppTheme.lightTheme,
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Currency Display Demo'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.currency_exchange),
                  onPressed: () => _showCurrencyPicker(context),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Currency Display Widget Examples',
                    style: AppTheme.lightTheme.textTheme.headlineSmall,
                  ),
                  SizedBox(height: 2.h),
                  
                  // Current currency display
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(3.w),
                      child: Row(
                        children: [
                          Text('${_selectedCurrency.flag} ${_selectedCurrency.code}'),
                          const Spacer(),
                          Text(_selectedCurrency.name),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Basic formatting examples
                  _buildSection(
                    '1. Basic Formatting',
                    [
                      _buildExample('Standard', _testAmount),
                      _buildExample('Large Amount', _largeAmount),
                      _buildExample('Negative Amount', _negativeAmount),
                      _buildExample('Zero Amount', _zeroAmount),
                      _buildExample('Small Amount', _smallAmount),
                    ],
                  ),

                  // Compact formatting
                  _buildSection(
                    '2. Compact Formatting',
                    [
                      _buildExample('Compact Large', _largeAmount, isCompact: true),
                      _buildExample('Compact Medium', _testAmount, isCompact: true),
                      _buildExample('Compact Small', _smallAmount, isCompact: true),
                    ],
                  ),

                  // Minimal formatting
                  _buildSection(
                    '3. Minimal Decimal Places',
                    [
                      _buildExample('Minimal', _testAmount, useMinimalFormatting: true),
                      _buildExample('Minimal Zero', _zeroAmount, useMinimalFormatting: true),
                      _buildExample('Minimal Small', _smallAmount, useMinimalFormatting: true),
                    ],
                  ),

                  // With currency code
                  _buildSection(
                    '4. With Currency Code',
                    [
                      _buildExample('With Code', _testAmount, showCurrencyCode: true),
                      _buildExample('With Code Large', _largeAmount, showCurrencyCode: true),
                    ],
                  ),

                  // Negative with parentheses
                  _buildSection(
                    '5. Negative with Parentheses',
                    [
                      _buildExample('Parentheses', _negativeAmount, useParenthesesForNegative: true),
                      _buildExample('Parentheses Large', -_largeAmount, useParenthesesForNegative: true),
                    ],
                  ),

                  // Privacy mode
                  _buildSection(
                    '6. Privacy Mode',
                    [
                      _buildExample('Privacy', _testAmount, isPrivacyMode: true),
                      _buildExample('Privacy Large', _largeAmount, isPrivacyMode: true),
                    ],
                  ),

                  // Different styles
                  _buildSection(
                    '7. Different Styles',
                    [
                      _buildExample('Primary Color', _testAmount, 
                          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                          )),
                      _buildExample('Error Color', _negativeAmount,
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.error,
                          )),
                      _buildExample('Bold', _testAmount,
                          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),

                  // Convenience methods
                  _buildSection(
                    '8. Convenience Methods',
                    [
                      _buildConvenienceExample('CurrencyDisplay.amount()', _testAmount),
                      _buildConvenienceExample('CurrencyDisplay.compact()', _largeAmount),
                      _buildConvenienceExample('CurrencyDisplay.minimal()', _testAmount),
                      _buildConvenienceExample('CurrencyDisplay.withCode()', _testAmount),
                      _buildConvenienceExample('CurrencyDisplay.withParentheses()', _negativeAmount),
                    ],
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<Widget> examples) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        ...examples,
        SizedBox(height: 3.h),
      ],
    );
  }

  Widget _buildExample(String label, double amount, {
    bool isCompact = false,
    bool useMinimalFormatting = false,
    bool showCurrencyCode = false,
    bool useParenthesesForNegative = false,
    bool isPrivacyMode = false,
    TextStyle? style,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: CurrencyDisplayWidget(
              amount: amount,
              currency: _selectedCurrency,
              style: style,
              isCompact: isCompact,
              useMinimalFormatting: useMinimalFormatting,
              showCurrencyCode: showCurrencyCode,
              useParenthesesForNegative: useParenthesesForNegative,
              isPrivacyMode: isPrivacyMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvenienceExample(String method, double amount) {
    Widget displayWidget;
    
    switch (method) {
      case 'CurrencyDisplay.amount()':
        displayWidget = CurrencyDisplay.amount(
          amount: amount,
          currency: _selectedCurrency,
        );
        break;
      case 'CurrencyDisplay.compact()':
        displayWidget = CurrencyDisplay.compact(
          amount: amount,
          currency: _selectedCurrency,
        );
        break;
      case 'CurrencyDisplay.minimal()':
        displayWidget = CurrencyDisplay.minimal(
          amount: amount,
          currency: _selectedCurrency,
        );
        break;
      case 'CurrencyDisplay.withCode()':
        displayWidget = CurrencyDisplay.withCode(
          amount: amount,
          currency: _selectedCurrency,
        );
        break;
      case 'CurrencyDisplay.withParentheses()':
        displayWidget = CurrencyDisplay.withParentheses(
          amount: amount,
          currency: _selectedCurrency,
        );
        break;
      default:
        displayWidget = CurrencyDisplay.amount(
          amount: amount,
          currency: _selectedCurrency,
        );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              method,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(child: displayWidget),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currency) {
        setState(() {
          _selectedCurrency = currency;
        });
      },
      favorite: ['EUR', 'USD', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR', 'BRL'],
      theme: CurrencyPickerThemeData(
        flagSize: 25,
        titleTextStyle: AppTheme.lightTheme.textTheme.titleLarge,
        subtitleTextStyle: AppTheme.lightTheme.textTheme.bodyMedium,
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.7,
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
      ),
    );
  }
}
