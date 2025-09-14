import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/currency_display_widget.dart';

class DraggableItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final Widget child;
  final bool isDragging;
  final Currency currency;

  const DraggableItemWidget({
    super.key,
    required this.item,
    required this.child,
    this.isDragging = false,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<Map<String, dynamic>>(
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Transform.scale(
          scale: 1.05,
          child: Container(
            width: 85.w,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.drag_handle,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          CurrencyDisplayWidget(
                            amount: item['unit_price'] as double,
                            currency: currency,
                            style: AppTheme.getMonospaceStyle(
                              isLight: true,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ' x ${item['quantity']} = ',
                            style: AppTheme.getMonospaceStyle(
                              isLight: true,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          CurrencyDisplayWidget(
                            amount: item['total_price'] as double,
                            currency: currency,
                            style: AppTheme.getMonospaceStyle(
                              isLight: true,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: child,
      ),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
      },
      onDragEnd: (details) {
        HapticFeedback.lightImpact();
      },
      child: child,
    );
  }
}
