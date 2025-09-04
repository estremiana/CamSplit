import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/currency_display_widget.dart';
import './member_avatar_widget.dart';

class AssignmentItemCardWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> members;
  final Function(Map<String, dynamic>) onAssignmentChanged;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final Currency currency;

  const AssignmentItemCardWidget({
    super.key,
    required this.item,
    required this.members,
    required this.onAssignmentChanged,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.currency,
  });

  @override
  State<AssignmentItemCardWidget> createState() =>
      _AssignmentItemCardWidgetState();
}

class _AssignmentItemCardWidgetState extends State<AssignmentItemCardWidget> {
  int _quantity = 1;
  List<String> _assignedMembers = [];

  @override
  void initState() {
    super.initState();
    _quantity = widget.item['quantity'] ?? 1;
    _assignedMembers = List<String>.from(widget.item['assignedMembers'] ?? []);
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _quantity = newQuantity;
      });
      _updateAssignment();
      HapticFeedback.lightImpact();
    }
  }

  void _toggleMemberAssignment(String memberId) {
    setState(() {
      if (_assignedMembers.contains(memberId)) {
        _assignedMembers.remove(memberId);
      } else {
        _assignedMembers.add(memberId);
      }
    });
    _updateAssignment();
  }

  void _updateAssignment() {
    final updatedItem = Map<String, dynamic>.from(widget.item);
    updatedItem['quantity'] = _quantity;
    updatedItem['assignedMembers'] = _assignedMembers;
    widget.onAssignmentChanged(updatedItem);
  }

  double _calculateMemberShare() {
    if (_assignedMembers.isEmpty) return 0.0;
    final totalPrice = (widget.item['unit_price'] as double) * _quantity;
    return totalPrice / _assignedMembers.length;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Header - Always visible
          GestureDetector(
            onTap: widget.onToggleExpanded,
            child: Container(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  // Item info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['name'],
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CurrencyDisplayWidget(
                              amount: widget.item['unit_price'] as double,
                              currency: widget.currency,
                              style: AppTheme.getMonospaceStyle(
                                isLight: true,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              ' x $_quantity = ',
                              style: AppTheme.getMonospaceStyle(
                                isLight: true,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            CurrencyDisplayWidget(
                              amount: (widget.item['unit_price'] as double) * _quantity,
                              currency: widget.currency,
                              style: AppTheme.getMonospaceStyle(
                                isLight: true,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (widget.item['category'] != null) ...[
                          SizedBox(height: 0.5.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: AppTheme
                                  .lightTheme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.item['category'],
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Assignment status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_assignedMembers.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: AppTheme
                                .lightTheme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_assignedMembers.length} assigned',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      SizedBox(height: 1.h),
                      Icon(
                        widget.isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppTheme.lightTheme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: widget.isExpanded ? null : 0,
            child: widget.isExpanded
                ? Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppTheme
                          .lightTheme.colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quantity selector
                        Row(
                          children: [
                            Text(
                              'Quantity:',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.lightTheme.dividerColor,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _updateQuantity(_quantity - 1),
                                    icon: const Icon(Icons.remove),
                                    iconSize: 20,
                                    constraints: const BoxConstraints(
                                        minWidth: 40, minHeight: 40),
                                  ),
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 3.w),
                                    child: Text(
                                      '$_quantity',
                                      style: AppTheme
                                          .lightTheme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _updateQuantity(_quantity + 1),
                                    icon: const Icon(Icons.add),
                                    iconSize: 20,
                                    constraints: const BoxConstraints(
                                        minWidth: 40, minHeight: 40),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 2.h),

                        // Member assignment
                        Text(
                          'Assign to members:',
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 2.w,
                          runSpacing: 1.h,
                          children: widget.members.map((member) {
                            final isSelected = _assignedMembers
                                .contains(member['id'].toString());
                            return Column(
                              children: [
                                MemberAvatarWidget(
                                  member: member,
                                  isSelected: isSelected,
                                  onTap: () => _toggleMemberAssignment(
                                      member['id'].toString()),
                                  size: 10.0,
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  member['name'],
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: isSelected
                                        ? AppTheme
                                            .lightTheme.colorScheme.primary
                                        : AppTheme
                                            .lightTheme.colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),

                        if (_assignedMembers.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: AppTheme
                                  .lightTheme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Split Details:',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Per person:',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodyMedium,
                                    ),
                                    CurrencyDisplayWidget(
                                      amount: _calculateMemberShare(),
                                      currency: widget.currency,
                                      style: AppTheme.getMonospaceStyle(
                                        isLight: true,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total:',
                                      style: AppTheme
                                          .lightTheme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    CurrencyDisplayWidget(
                                      amount: (widget.item['unit_price'] as double) * _quantity,
                                      currency: widget.currency,
                                      style: AppTheme.getMonospaceStyle(
                                        isLight: true,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
