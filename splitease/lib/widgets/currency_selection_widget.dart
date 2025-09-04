import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import 'custom_icon_widget.dart';

/// A standardized currency selection widget that provides consistent
/// currency picker functionality across the entire application.
/// 
/// This widget uses the currency_picker package and maintains visual
/// consistency with the existing expense creation currency picker.
/// Includes real-time visual feedback and animations for currency changes.
class CurrencySelectionWidget extends StatefulWidget {
  /// The currently selected currency
  final Currency? selectedCurrency;
  
  /// Callback function called when a currency is selected
  final Function(Currency) onCurrencySelected;
  
  /// Whether to show the currency flag
  final bool showFlag;
  
  /// Whether to show the currency name
  /// Note: At least one of showCurrencyName or showCurrencyCode must be true
  /// to satisfy the currency_picker package requirements
  final bool showCurrencyName;
  
  /// Whether to show the currency code
  /// Note: At least one of showCurrencyName or showCurrencyCode must be true
  /// to satisfy the currency_picker package requirements
  final bool showCurrencyCode;
  
  /// Optional label text for the field
  final String? labelText;
  
  /// Whether the widget is enabled for interaction
  final bool isEnabled;
  
  /// Whether the widget is in read-only mode
  final bool isReadOnly;
  
  /// Optional hint text when no currency is selected
  final String? hintText;
  
  /// Custom width for the widget (useful for inline usage)
  final double? width;
  
  /// Whether to show as a compact version (symbol only)
  final bool isCompact;
  
  /// Custom text style for the displayed currency
  final TextStyle? textStyle;

  const CurrencySelectionWidget({
    super.key,
    this.selectedCurrency,
    required this.onCurrencySelected,
    this.showFlag = true,
    this.showCurrencyName = true,
    this.showCurrencyCode = true,
    this.labelText,
    this.isEnabled = true,
    this.isReadOnly = false,
    this.hintText,
    this.width,
    this.isCompact = false,
    this.textStyle,
  });

  @override
  State<CurrencySelectionWidget> createState() => _CurrencySelectionWidgetState();
}

class _CurrencySelectionWidgetState extends State<CurrencySelectionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  
  Currency? _previousCurrency;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: AppTheme.lightTheme.colorScheme.primary,
      end: AppTheme.lightTheme.colorScheme.secondary,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _previousCurrency = widget.selectedCurrency;
  }
  
  @override
  void didUpdateWidget(CurrencySelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if currency changed and trigger animation
    if (widget.selectedCurrency != _previousCurrency && 
        widget.selectedCurrency != null && 
        _previousCurrency != null) {
      _triggerCurrencyChangeAnimation();
    }
    
    _previousCurrency = widget.selectedCurrency;
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _triggerCurrencyChangeAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // Trigger haptic feedback
    HapticFeedback.lightImpact();
  }

  /// Get the display text for the selected currency
  String _getCurrencyDisplayText() {
    if (widget.selectedCurrency == null) {
      return widget.hintText ?? 'Select Currency';
    }
    
    if (widget.isCompact) {
      return widget.selectedCurrency!.symbol;
    }
    
    final parts = <String>[];
    
    if (widget.showFlag) {
      parts.add(widget.selectedCurrency!.flag ?? '');
    }
    
    if (widget.showCurrencyCode) {
      parts.add(widget.selectedCurrency!.code);
    }
    
    if (widget.showCurrencyName && !widget.isCompact) {
      parts.add(widget.selectedCurrency!.name);
    }
    
    return parts.join(' ');
  }

  /// Get the appropriate icon color based on state
  Color _getIconColor(BuildContext context) {
    if (widget.isReadOnly || !widget.isEnabled) {
      return AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6);
    }
    return AppTheme.lightTheme.colorScheme.secondary;
  }

  /// Get the appropriate text color based on state
  Color? _getTextColor(BuildContext context) {
    if (widget.isReadOnly || !widget.isEnabled) {
      return AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.6);
    }
    return null;
  }

  /// Get the appropriate fill color based on state
  Color? _getFillColor(BuildContext context) {
    if (widget.isReadOnly || !widget.isEnabled) {
      return AppTheme.lightTheme.colorScheme.surface.withOpacity(0.5);
    }
    return null;
  }

  /// Handle currency selection tap with error handling
  void _handleTap(BuildContext context) {
    if (!widget.isEnabled || widget.isReadOnly) return;
    
    // Validate that at least one of showCurrencyName or showCurrencyCode is true
    // This prevents the currency_picker assertion error
    if (!widget.showCurrencyName && !widget.showCurrencyCode) {
      _showCurrencyError(context, 'Currency picker requires either showCurrencyName or showCurrencyCode to be true');
      return;
    }
    
    try {
      showCurrencyPicker(
        context: context,
        showFlag: widget.showFlag,
        showCurrencyName: widget.showCurrencyName,
        showCurrencyCode: widget.showCurrencyCode,
        onSelect: (currency) => _handleCurrencySelection(context, currency),
        favorite: ['EUR', 'USD', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR', 'BRL'],
        currencyFilter: null, // Show all currencies
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
    } catch (e) {
      _showCurrencyError(context, 'Failed to open currency picker: $e');
    }
  }
  
  /// Handle currency selection with validation
  void _handleCurrencySelection(BuildContext context, Currency currency) {
    try {
      // Validate selected currency
      if (currency.code.isEmpty) {
        throw ArgumentError('Selected currency has empty code');
      }
      
      // Call the original callback
      widget.onCurrencySelected(currency);
    } catch (e) {
      _showCurrencyError(context, 'Invalid currency selected: $e');
    }
  }
  
  /// Show currency selection error
  void _showCurrencyError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      // Compact version for inline usage (like in expense creation)
      return SizedBox(
        width: widget.width ?? 80,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTap: () => _handleTap(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      suffixIcon: (widget.isEnabled && !widget.isReadOnly)
                          ? CustomIconWidget(
                              iconName: 'arrow_drop_down',
                              color: _getIconColor(context),
                              size: 20,
                            )
                          : Icon(
                              Icons.lock_outline,
                              color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6),
                              size: 16,
                            ),
                      fillColor: _getFillColor(context),
                      filled: widget.isReadOnly || !widget.isEnabled,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: AppTheme.lightTheme.colorScheme.outline,
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: AppTheme.lightTheme.colorScheme.outline,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          width: 2.0,
                        ),
                      ),
                    ),
                    style: widget.textStyle ?? TextStyle(color: _getTextColor(context)),
                    controller: TextEditingController(text: _getCurrencyDisplayText()),
                    enabled: widget.isEnabled && !widget.isReadOnly,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Full version for forms and settings
    return SizedBox(
      width: widget.width,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
              onTap: () => _handleTap(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: widget.labelText,
                    hintText: widget.hintText ?? 'Select a currency',
                    prefixIcon: CustomIconWidget(
                      iconName: 'currency_exchange',
                      color: _getIconColor(context),
                      size: 20,
                    ),
                    suffixIcon: (widget.isEnabled && !widget.isReadOnly)
                        ? CustomIconWidget(
                            iconName: 'arrow_drop_down',
                            color: _getIconColor(context),
                            size: 20,
                          )
                        : Icon(
                            Icons.lock_outline,
                            color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6),
                            size: 16,
                          ),
                    fillColor: _getFillColor(context),
                    filled: widget.isReadOnly || !widget.isEnabled,
                  ),
                  style: widget.textStyle ?? TextStyle(color: _getTextColor(context)),
                  controller: TextEditingController(text: _getCurrencyDisplayText()),
                  enabled: widget.isEnabled && !widget.isReadOnly,
                  validator: (value) {
                    if (widget.selectedCurrency == null) {
                      return 'Please select a currency';
                    }
                    return null;
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}