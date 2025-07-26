import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SplitOptionsWidget extends StatefulWidget {
  final String splitType;
  final Function(String)? onSplitTypeChanged;
  final List<Map<String, dynamic>> groupMembers;
  final Map<String, double>? memberPercentages;
  final List<String>? selectedMembers;
  final Function(Map<String, double>)? onPercentagesChanged;
  final Function(List<String>)? onMembersChanged;
  final double? totalAmount;
  final Function(Map<String, double>)? onCustomAmountsChanged;
  final String currencySymbol;
  // Receipt mode parameters
  final bool isReceiptMode;
  final Map<String, double>? prefilledCustomAmounts;

  const SplitOptionsWidget({
    super.key,
    required this.splitType,
    this.onSplitTypeChanged,
    required this.groupMembers,
    this.memberPercentages,
    this.selectedMembers,
    this.onPercentagesChanged,
    this.onMembersChanged,
    this.totalAmount,
    this.onCustomAmountsChanged,
    required this.currencySymbol,
    this.isReceiptMode = false,
    this.prefilledCustomAmounts,
  });

  @override
  State<SplitOptionsWidget> createState() => _SplitOptionsWidgetState();
}

class _SplitOptionsWidgetState extends State<SplitOptionsWidget> {
  late Map<String, double> _percentages;
  late List<String> _selectedMembers;
  late Map<String, TextEditingController> _controllers;
  late Map<String, double> _customAmounts;
  late Map<String, TextEditingController> _customAmountControllers;
  late Map<String, FocusNode> _percentageFocusNodes;
  late Map<String, FocusNode> _customAmountFocusNodes;
  
  // Performance optimization for large member lists
  static const int _maxVisibleMembers = 50;
  bool get _shouldOptimizeForLargeList => widget.groupMembers.length > _maxVisibleMembers;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant SplitOptionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize if groupMembers, prefilledCustomAmounts, or isReceiptMode changed
    if (widget.groupMembers != oldWidget.groupMembers ||
        widget.prefilledCustomAmounts != oldWidget.prefilledCustomAmounts ||
        widget.isReceiptMode != oldWidget.isReceiptMode) {
      _initializeControllers();
      setState(() {}); // Ensure UI updates with new controllers
    }
  }

  void _initializeControllers() {
    _percentages = Map.from(widget.memberPercentages ?? {});
    _selectedMembers = List.from(widget.selectedMembers ??
        widget.groupMembers.map((m) => m['name'].toString()).toList());

    _controllers = {};
    _customAmounts = {};
    _customAmountControllers = {};
    _percentageFocusNodes = {};
    _customAmountFocusNodes = {};

    for (var member in widget.groupMembers) {
      final memberName = member['name'].toString();
      final percentage = widget.memberPercentages != null && widget.memberPercentages!.containsKey(memberName)
          ? widget.memberPercentages![memberName]!
          : 0.0;
      _controllers[memberName] =
          TextEditingController(text: '');
      _percentages[memberName] = percentage;
      // Initialize custom amounts - use prefilled amounts for receipt mode
      final customAmount = widget.prefilledCustomAmounts?[memberName] ?? 0.0;
      _customAmounts[memberName] = customAmount;
      _customAmountControllers[memberName] = TextEditingController(
        text: widget.isReceiptMode
            ? customAmount.toStringAsFixed(2)
            : ''
      );
      // Initialize focus nodes for keyboard navigation
      _percentageFocusNodes[memberName] = FocusNode();
      _customAmountFocusNodes[memberName] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    for (var controller in _customAmountControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _percentageFocusNodes.values) {
      focusNode.dispose();
    }
    for (var focusNode in _customAmountFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // Helper method to compare group members lists
  bool _groupMembersEqual(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['id'] != list2[i]['id'] || list1[i]['name'] != list2[i]['name']) {
        return false;
      }
    }
    return true;
  }

  void _updatePercentage(String memberName, String value) {
    final percentage = double.tryParse(value) ?? 0.0;
    setState(() {
      _percentages[memberName] = percentage;
    });

    if (widget.onPercentagesChanged != null) {
      widget.onPercentagesChanged!(_percentages);
    }
  }

  void _updateCustomAmount(String memberName, String value) {
    final amount = double.tryParse(value) ?? 0.0;
    setState(() {
      _customAmounts[memberName] = amount;
    });

    if (widget.onCustomAmountsChanged != null) {
      widget.onCustomAmountsChanged!(_customAmounts);
    }
  }

  void _toggleMember(String memberName) {
    // Add haptic feedback for interactions
    HapticFeedback.lightImpact();
    
    setState(() {
      if (_selectedMembers.contains(memberName)) {
        if (_selectedMembers.length > 1) {
          _selectedMembers.remove(memberName);
        }
      } else {
        _selectedMembers.add(memberName);
      }
    });

    if (widget.onMembersChanged != null) {
      widget.onMembersChanged!(_selectedMembers);
    }
  }

  double get _totalPercentage {
    return _percentages.values.fold(0.0, (sum, percentage) => sum + percentage);
  }

  double get _totalCustomAmount {
    return _customAmounts.values.fold(0.0, (sum, amount) => sum + amount);
  }

  Widget _buildSplitTypeSelector() {
    return Semantics(
      label: 'Split type selector',
      hint: 'Choose how to split the expense',
      child: Container(
          decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightTheme.dividerColor)),
          child: Row(children: [
            Expanded(
                child: _buildSplitOption('equal', 'Equal', Icons.balance,
                    widget.splitType == 'equal')),
            Container(
                width: 1, height: 40, color: AppTheme.lightTheme.dividerColor),
            Expanded(
                child: _buildSplitOption('percentage', 'Percentage',
                    Icons.percent, widget.splitType == 'percentage')),
            Container(
                width: 1, height: 40, color: AppTheme.lightTheme.dividerColor),
            Expanded(
                child: _buildSplitOption('custom', 'Custom', Icons.tune,
                    widget.splitType == 'custom')),
          ])),
    );
  }

  Widget _buildSplitOption(
      String value, String label, IconData icon, bool isSelected) {
    final isEnabled = !widget.isReceiptMode && widget.onSplitTypeChanged != null;
    
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label split option',
      hint: isSelected 
          ? 'Currently selected' 
          : isEnabled 
              ? 'Tap to select $label split'
              : 'Disabled in receipt mode',
      child: InkWell(
          onTap: isEnabled ? () {
            // Add haptic feedback for split type selection
            HapticFeedback.selectionClick();
            widget.onSplitTypeChanged!(value);
          } : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height < 600 ? 1.5.h : 2.h, 
                  horizontal: MediaQuery.of(context).size.width < 400 ? 1.5.w : 2.w),
              decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    size: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.secondary),
                SizedBox(height: 0.5.h),
                Text(label,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.secondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400)),
              ]))),
    );
  }

  Widget _buildEqualSplitOptions() {
    return Semantics(
      label: 'Equal split member selection',
      hint: 'Select members to include in equal split',
      child: Container(
          margin: EdgeInsets.only(top: 2.h),
          decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightTheme.dividerColor)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12))),
                child: Row(children: [
                  CustomIconWidget(
                      iconName: 'people',
                      size: 18,
                      color: AppTheme.lightTheme.colorScheme.primary),
                  SizedBox(width: 2.w),
                  Text('Select Members',
                      style: AppTheme.lightTheme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Spacer(),
                  Semantics(
                    label: 'Selected members count',
                    value: '${_selectedMembers.length} out of ${widget.groupMembers.length} members selected',
                    child: Text('${_selectedMembers.length}/${widget.groupMembers.length}',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w500)),
                  ),
                ])),
            Padding(
                padding: EdgeInsets.all(3.w),
                child: _shouldOptimizeForLargeList 
                    ? _buildOptimizedMemberList()
                    : _buildStandardMemberList()),
          ])),
    );
  }

  Widget _buildStandardMemberList() {
    final totalAmount = widget.totalAmount ?? 0.0;
    final perPerson = _selectedMembers.isNotEmpty ? totalAmount / _selectedMembers.length : 0.0;
    return Column(
        children: widget.groupMembers.map((member) {
      final memberName = member['name'].toString();
      final isSelected = _selectedMembers.contains(memberName);

      return Padding(
          padding: EdgeInsets.only(bottom: 2.h),
          child: Semantics(
            button: true,
            selected: isSelected,
            label: 'Member $memberName',
            hint: isSelected ? 'Tap to deselect' : 'Tap to select',
            child: InkWell(
                onTap: () => _toggleMember(memberName),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme
                                .lightTheme.colorScheme.primaryContainer
                            : AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isSelected
                                ? AppTheme
                                    .lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.dividerColor)),
                    child: Row(children: [
                      CircleAvatar(
                          radius: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                          backgroundColor:
                              AppTheme.lightTheme.colorScheme.surface,
                          child: ClipOval(
                              child: CustomImageWidget(
                                  imageUrl: member['avatar'] ?? '',
                                  height: MediaQuery.of(context).size.width < 400 ? 28 : 32,
                                  width: MediaQuery.of(context).size.width < 400 ? 28 : 32,
                                  fit: BoxFit.cover))),
                      SizedBox(width: 3.w),
                      Expanded(
                          child: Text(memberName,
                              style: AppTheme
                                  .lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                      color: isSelected
                                          ? AppTheme.lightTheme
                                              .colorScheme.primary
                                          : AppTheme.lightTheme
                                              .colorScheme.onSurface,
                                      fontWeight: FontWeight.w500))),
                      if (isSelected)
                        Row(
                          children: [
                            Text(
                              // TODO: Replace '€' with currency symbol prop if available
                              '${widget.currencySymbol}${perPerson.toStringAsFixed(2)}',
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Icon(Icons.check_circle,
                                size: 20,
                                color: AppTheme
                                    .lightTheme.colorScheme.primary),
                          ],
                        ),
                    ]))),
          ));
    }).toList());
  }

  Widget _buildOptimizedMemberList() {
    // Performance optimization for large member lists using ListView.builder
    return SizedBox(
      height: 40.h, // Fixed height for scrollable list
      child: ListView.builder(
        itemCount: widget.groupMembers.length,
        itemBuilder: (context, index) {
          final member = widget.groupMembers[index];
          final memberName = member['name'].toString();
          final isSelected = _selectedMembers.contains(memberName);

          return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Semantics(
                button: true,
                selected: isSelected,
                label: 'Member $memberName',
                hint: isSelected ? 'Tap to deselect' : 'Tap to select',
                child: InkWell(
                    onTap: () => _toggleMember(memberName),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme
                                    .lightTheme.colorScheme.primaryContainer
                                : AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? AppTheme
                                        .lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.dividerColor)),
                        child: Row(children: [
                          CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppTheme.lightTheme.colorScheme.surface,
                              child: ClipOval(
                                  child: CustomImageWidget(
                                      imageUrl: member['avatar'] ?? '',
                                      height: 32,
                                      width: 32,
                                      fit: BoxFit.cover))),
                          SizedBox(width: 3.w),
                          Expanded(
                              child: Text(memberName,
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                          color: isSelected
                                              ? AppTheme.lightTheme
                                                  .colorScheme.primary
                                              : AppTheme.lightTheme
                                                  .colorScheme.onSurface,
                                          fontWeight: FontWeight.w500))),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                size: 20,
                                color: AppTheme
                                    .lightTheme.colorScheme.primary),
                        ]))),
              ));
        },
      ),
    );
  }

  Widget _buildPercentageSplitOptions() {
    final totalAmount = widget.totalAmount ?? 0.0;
    return Semantics(
      label: 'Percentage split configuration',
      hint: 'Assign percentage values to each member',
      child: Container(
          margin: EdgeInsets.only(top: 2.h),
          decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightTheme.dividerColor)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12))),
                child: Row(children: [
                  CustomIconWidget(
                      iconName: 'percent',
                      size: 18,
                      color: AppTheme.lightTheme.colorScheme.primary),
                  
                  Text('Assign Percentages',
                      style: AppTheme.lightTheme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Spacer(),
                  Semantics(
                    label: 'Total percentage',
                    value: '${_totalPercentage.toStringAsFixed(1)} percent',
                    hint: _totalPercentage == 100.0 ? 'Valid total' : 'Must equal 100 percent',
                    child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                            color: _totalPercentage == 100.0
                                ? AppTheme.lightTheme.colorScheme.primaryContainer
                                : AppTheme.lightTheme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('${_totalPercentage.toStringAsFixed(1)}%',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                                    color: _totalPercentage == 100.0
                                        ? AppTheme.lightTheme.colorScheme.primary
                                        : AppTheme.lightTheme.colorScheme.error,
                                    fontWeight: FontWeight.w600))),
                  ),
                ])),
            Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                    children: widget.groupMembers.map((member) {
                  final memberName = member['name'].toString();
                  final percentage = _percentages[memberName] ?? 0.0;
                  final amount = totalAmount * (percentage / 100.0);

                  return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Row(children: [
                        CircleAvatar(
                            radius: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                            backgroundColor:
                                AppTheme.lightTheme.colorScheme.surface,
                            child: ClipOval(
                                child: CustomImageWidget(
                                    imageUrl: member['avatar'] ?? '',
                                    height: MediaQuery.of(context).size.width < 400 ? 28 : 32,
                                    width: MediaQuery.of(context).size.width < 400 ? 28 : 32,
                                    fit: BoxFit.cover))),
                        SizedBox(width: 3.w),
                        Expanded(
                            child: Text(memberName,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500))),
                        SizedBox(width: 3.w),
                        Text(
                          // TODO: Replace '€' with currency symbol prop if available
                          '${widget.currencySymbol}${amount.toStringAsFixed(2)}',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        SizedBox(
                            width: MediaQuery.of(context).size.width < 400 ? 25.w : 20.w,
                            child: Semantics(
                              label: 'Percentage for $memberName',
                              hint: 'Enter percentage value',
                              textField: true,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _controllers[memberName],
                                      focusNode: _percentageFocusNodes[memberName],
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: AppTheme.lightTheme.dividerColor)),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: AppTheme.lightTheme.colorScheme.primary)),
                                        hintText: '0.0',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Enter a percentage';
                                        }
                                        final double? percent = double.tryParse(value);
                                        if (percent == null) {
                                          return 'Enter a valid number';
                                        }
                                        if (percent < 0 || percent > 100) {
                                          return 'Must be 0-100';
                                        }
                                        return null;
                                      },
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      onChanged: (value) {
                                        HapticFeedback.lightImpact();
                                        _updatePercentage(memberName, value);
                                      },
                                      onFieldSubmitted: (_) {
                                        final memberIndex = widget.groupMembers.indexWhere((m) => m['name'] == memberName);
                                        if (memberIndex < widget.groupMembers.length - 1) {
                                          final nextMember = widget.groupMembers[memberIndex + 1]['name'].toString();
                                          _percentageFocusNodes[nextMember]?.requestFocus();
                                        }
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '%',
                                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(color: AppTheme.lightTheme.colorScheme.secondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ),
                      ]));
                }).toList())),
            if (_totalPercentage != 100.0)
              Semantics(
                label: 'Validation error',
                hint: 'Total percentage must equal 100 percent',
                child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.errorContainer,
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(12))),
                    child: Row(children: [
                      Icon(Icons.warning_amber,
                          size: 16, color: AppTheme.lightTheme.colorScheme.error),
                      SizedBox(width: 2.w),
                      Text('Total percentage must equal 100%',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.error)),
                    ])),
              ),
          ])),
    );
  }

  Widget _buildCustomSplitOptions() {
    final totalAmount = widget.totalAmount ?? 0.0;
    final isValidTotal = (_totalCustomAmount - totalAmount).abs() < 0.01;

    return Semantics(
      label: 'Custom split configuration',
      hint: 'Assign custom amounts to each member',
      child: Container(
          margin: EdgeInsets.only(top: 2.h),
          decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.lightTheme.dividerColor)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                    color:
                        AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12))),
                child: Row(children: [
                  CustomIconWidget(
                      iconName: 'money',
                      size: 18,
                      color: AppTheme.lightTheme.colorScheme.primary),
                  SizedBox(width: 2.w),
                  Text('Assign Custom Amounts',
                      style: AppTheme.lightTheme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Spacer(),
                  Semantics(
                    label: 'Total custom amount',
                    value: '${_totalCustomAmount.toStringAsFixed(2)} dollars',
                    hint: isValidTotal ? 'Valid total' : 'Must equal ${totalAmount.toStringAsFixed(2)} dollars',
                    child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                            color: isValidTotal
                                ? AppTheme.lightTheme.colorScheme.primaryContainer
                                : AppTheme.lightTheme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('${widget.currencySymbol}${_totalCustomAmount.toStringAsFixed(2)}',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                                    color: isValidTotal
                                        ? AppTheme.lightTheme.colorScheme.primary
                                        : AppTheme.lightTheme.colorScheme.error,
                                    fontWeight: FontWeight.w600))),
                  ),
                ])),
            Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                    children: widget.groupMembers.map((member) {
                  final memberName = member['name'].toString();

                  return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Row(children: [
                        CircleAvatar(
                            radius: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                            backgroundColor:
                                AppTheme.lightTheme.colorScheme.surface,
                            child: ClipOval(
                                child: CustomImageWidget(
                                    imageUrl: member['avatar'] ?? '',
                                    height: MediaQuery.of(context).size.width < 400 ? 28 : 32,
                                    width: MediaQuery.of(context).size.width < 400 ? 28 : 32,
                                    fit: BoxFit.cover))),
                        SizedBox(width: 3.w),
                        Expanded(
                            child: Text(memberName,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500))),
                        SizedBox(width: 3.w),
                        SizedBox(
                            width: MediaQuery.of(context).size.width < 400 ? 30.w : 25.w,
                            child: Semantics(
                              label: 'Custom amount for $memberName',
                              hint: 'Enter custom amount',
                              textField: true,
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    alignment: Alignment.center,
                                    child: Text(
                                      widget.currencySymbol,
                                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(color: AppTheme.lightTheme.colorScheme.secondary),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _customAmountControllers[memberName],
                                      focusNode: _customAmountFocusNodes[memberName],
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      enabled: !widget.isReceiptMode,
                                      readOnly: widget.isReceiptMode,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: AppTheme.lightTheme.dividerColor)),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: AppTheme.lightTheme.colorScheme.primary)),
                                        hintText: '0.00',
                                        suffixIcon: widget.isReceiptMode
                                            ? Icon(
                                                Icons.lock_outline,
                                                color: AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.6),
                                                size: 16,
                                              )
                                            : null,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Enter an amount';
                                        }
                                        final double? amt = double.tryParse(value);
                                        if (amt == null) {
                                          return 'Enter a valid number';
                                        }
                                        if (amt < 0) {
                                          return 'Must be positive';
                                        }
                                        return null;
                                      },
                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                      onChanged: widget.isReceiptMode ? null : (value) {
                                        HapticFeedback.lightImpact();
                                        _updateCustomAmount(memberName, value);
                                      },
                                      onFieldSubmitted: widget.isReceiptMode ? null : (_) {
                                        final memberIndex = widget.groupMembers.indexWhere((m) => m['name'] == memberName);
                                        if (memberIndex < widget.groupMembers.length - 1) {
                                          final nextMember = widget.groupMembers[memberIndex + 1]['name'].toString();
                                          _customAmountFocusNodes[nextMember]?.requestFocus();
                                        }
                                      },
                                      inputFormatters: widget.isReceiptMode ? [] : [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ),
                      ]));
                }).toList())),
            if (!isValidTotal)
              Semantics(
                label: 'Validation error',
                hint: 'Total must equal ${totalAmount.toStringAsFixed(2)} dollars',
                child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.errorContainer,
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(12))),
                    child: Row(children: [
                      Icon(Icons.warning_amber,
                          size: 16, color: AppTheme.lightTheme.colorScheme.error),
                      SizedBox(width: 2.w),
                      Text('Total must equal \$${totalAmount.toStringAsFixed(2)}',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.error)),
                    ])),
              ),
          ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Split options configuration',
      hint: 'Configure how to split the expense among members',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Split Options',
              style: AppTheme.lightTheme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          if (widget.isReceiptMode)
            Container(
              margin: EdgeInsets.only(left: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 12,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Locked',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Spacer(),
          if (widget.splitType == 'equal')
            Semantics(
              label: 'Selected members summary',
              value: '${_selectedMembers.length} members selected',
              child: Text('${_selectedMembers.length} members',
                  style: AppTheme.lightTheme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.lightTheme.colorScheme.secondary)),
            ),
        ]),
        SizedBox(height: 2.h),
        _buildSplitTypeSelector(),

        // Show options based on selected split type
        if (widget.splitType == 'equal') _buildEqualSplitOptions(),
        if (widget.splitType == 'percentage') _buildPercentageSplitOptions(),
        if (widget.splitType == 'custom') _buildCustomSplitOptions(),
      ]),
    );
  }
}