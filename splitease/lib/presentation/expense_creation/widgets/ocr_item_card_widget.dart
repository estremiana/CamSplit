import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OcrItemCardWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final List<Map<String, dynamic>> groupMembers;
  final Function(int, int) onQuantityChanged;
  final Function(int, String) onAssignmentChanged;
  final Function(int) onRemove;

  const OcrItemCardWidget({
    super.key,
    required this.item,
    required this.groupMembers,
    required this.onQuantityChanged,
    required this.onAssignmentChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item['id'].toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onRemove(item['id']),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'delete',
              color: AppTheme.lightTheme.colorScheme.onError,
              size: 24,
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Delete',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '\$${(item['unit_price'] as double).toStringAsFixed(2)} x ${item['quantity']} = \$${(item['total_price'] as double).toStringAsFixed(2)}',
                          style: AppTheme.getMonospaceStyle(
                            isLight: true,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quantity Controls
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
                          onPressed: item['quantity'] > 1
                              ? () => onQuantityChanged(
                                    item['id'],
                                    item['quantity'] - 1,
                                  )
                              : null,
                          icon: CustomIconWidget(
                            iconName: 'remove',
                            color: item['quantity'] > 1
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.secondary,
                            size: 20,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 8.w,
                            minHeight: 6.h,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                          child: Text(
                            item['quantity'].toString(),
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => onQuantityChanged(
                            item['id'],
                            item['quantity'] + 1,
                          ),
                          icon: CustomIconWidget(
                            iconName: 'add',
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 20,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 8.w,
                            minHeight: 6.h,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Assignment Dropdown
              Row(
                children: [
                  Text(
                    'Assigned to:',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: item['assignedTo'],
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: (groupMembers as List)
                          .map<DropdownMenuItem<String>>((member) {
                        return DropdownMenuItem<String>(
                          value: member['name'],
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundImage: NetworkImage(member['avatar']),
                              ),
                              SizedBox(width: 2.w),
                              Text(member['name']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          onAssignmentChanged(item['id'], value);
                        }
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.h),

              // Total for this item
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Item Total:',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.secondary,
                    ),
                  ),
                  Text(
                    '\$${((item['unit_price'] as double) * (item['quantity'] as int)).toStringAsFixed(2)}',
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
      ),
    );
  }
}
