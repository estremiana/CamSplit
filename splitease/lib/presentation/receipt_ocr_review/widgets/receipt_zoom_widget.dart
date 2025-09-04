import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';

import '../../../core/app_export.dart';
import '../../../widgets/currency_display_widget.dart';

class ReceiptZoomWidget extends StatefulWidget {
  final String imageUrl;
  final List<Map<String, dynamic>> items;
  final Function(int) onItemTapped;
  final Currency currency;

  const ReceiptZoomWidget({
    super.key,
    required this.imageUrl,
    required this.items,
    required this.onItemTapped,
    required this.currency,
  });

  @override
  State<ReceiptZoomWidget> createState() => _ReceiptZoomWidgetState();
}

class _ReceiptZoomWidgetState extends State<ReceiptZoomWidget> {
  final TransformationController _transformationController =
      TransformationController();
  int? _highlightedItemId;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _highlightItem(int itemId) {
    setState(() {
      _highlightedItemId = itemId;
    });
    widget.onItemTapped(itemId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.8,
          maxScale: 4.0,
          child: Container(
            width: double.infinity,
            color: AppTheme.lightTheme.cardColor,
            child: Stack(
              children: [
                // Receipt Image
                CustomImageWidget(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
                // Tap zones for items (simulated positions)
                ...widget.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isHighlighted = _highlightedItemId == item['id'];

                  // Simulate item positions on receipt
                  final double topPosition = 20.0 + (index * 8.0);
                  final double leftPosition = 10.0;

                  return Positioned(
                    top: topPosition.h,
                    left: leftPosition.w,
                    child: GestureDetector(
                      onTap: () => _highlightItem(item['id']),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isHighlighted
                              ? Border.all(
                                  color: AppTheme.lightTheme.colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item['name']} - ',
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: isHighlighted
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            CurrencyDisplayWidget(
                              amount: item['unit_price'] as double,
                              currency: widget.currency,
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: isHighlighted
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            Text(
                              ' x ${item['quantity']} = ',
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: isHighlighted
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            CurrencyDisplayWidget(
                              amount: item['total_price'] as double,
                              currency: widget.currency,
                              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                                color: isHighlighted
                                    ? AppTheme.lightTheme.colorScheme.primary
                                    : AppTheme.lightTheme.colorScheme.onSurface,
                                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                // Zoom controls
                Positioned(
                  bottom: 2.h,
                  right: 2.w,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: "zoom_in",
                        onPressed: () {
                          final Matrix4 matrix =
                              _transformationController.value.clone();
                          matrix.scale(1.2);
                          _transformationController.value = matrix;
                        },
                        child: const Icon(Icons.zoom_in),
                      ),
                      SizedBox(height: 1.h),
                      FloatingActionButton.small(
                        heroTag: "zoom_out",
                        onPressed: () {
                          final Matrix4 matrix =
                              _transformationController.value.clone();
                          matrix.scale(0.8);
                          _transformationController.value = matrix;
                        },
                        child: const Icon(Icons.zoom_out),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
