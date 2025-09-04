import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/currency_display_widget.dart';
import './member_avatar_widget.dart';

class MemberDropZoneWidget extends StatefulWidget {
  final Map<String, dynamic> member;
  final List<Map<String, dynamic>> assignedItems;
  final Function(Map<String, dynamic>, Map<String, dynamic>) onItemDropped;
  final VoidCallback? onTap;
  final Currency currency;

  const MemberDropZoneWidget({
    super.key,
    required this.member,
    required this.assignedItems,
    required this.onItemDropped,
    this.onTap,
    required this.currency,
  });

  @override
  State<MemberDropZoneWidget> createState() => _MemberDropZoneWidgetState();
}

class _MemberDropZoneWidgetState extends State<MemberDropZoneWidget>
    with TickerProviderStateMixin {
  bool _isDragOver = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
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
      begin: AppTheme.lightTheme.cardColor,
      end: AppTheme.lightTheme.colorScheme.primaryContainer,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDragEnter() {
    setState(() {
      _isDragOver = true;
    });
    _animationController.forward();
    HapticFeedback.selectionClick();
  }

  void _onDragLeave() {
    setState(() {
      _isDragOver = false;
    });
    _animationController.reverse();
  }

  void _onItemAccepted(Map<String, dynamic> item) {
    setState(() {
      _isDragOver = false;
    });
    _animationController.reverse();
    widget.onItemDropped(widget.member, item);
    HapticFeedback.mediumImpact();
  }

  double _calculateTotalAmount() {
    return widget.assignedItems.fold(
      0.0,
      (sum, item) => sum + (item['total_price'] as double),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _calculateTotalAmount();

    return GestureDetector(
      onTap: widget.onTap,
      child: DragTarget<Map<String, dynamic>>(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) => _onItemAccepted(details.data),
        onMove: (_) => _onDragEnter(),
        onLeave: (_) => _onDragLeave(),
        builder: (context, candidateData, rejectedData) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: _colorAnimation.value,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDragOver
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.dividerColor,
                      width: _isDragOver ? 2 : 1,
                    ),
                    boxShadow: _isDragOver
                        ? [
                            BoxShadow(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      // Member avatar and info
                      Row(
                        children: [
                          MemberAvatarWidget(
                            member: widget.member,
                            isSelected: widget.assignedItems.isNotEmpty,
                            onTap: widget.onTap ?? () {},
                            size: 8.0,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.member['name'],
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (widget.assignedItems.isNotEmpty)
                                  CurrencyDisplayWidget(
                                    amount: totalAmount,
                                    currency: widget.currency,
                                    style: AppTheme.getMonospaceStyle(
                                      isLight: true,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Assignment indicator
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: widget.assignedItems.isNotEmpty
                                  ? AppTheme
                                      .lightTheme.colorScheme.primaryContainer
                                  : AppTheme.lightTheme.colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.assignedItems.length} items',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: widget.assignedItems.isNotEmpty
                                    ? AppTheme.lightTheme.colorScheme
                                        .onPrimaryContainer
                                    : AppTheme.lightTheme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Drop zone indicator
                      if (_isDragOver)
                        Container(
                          margin: EdgeInsets.only(top: 2.h),
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              width: 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: AppTheme.lightTheme.colorScheme.primary,
                                size: 5.w,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                'Drop item here',
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Assigned items preview
                      if (widget.assignedItems.isNotEmpty && !_isDragOver)
                        Container(
                          margin: EdgeInsets.only(top: 2.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned Items:',
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      AppTheme.lightTheme.colorScheme.secondary,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              ...widget.assignedItems.take(3).map((item) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 0.5.h),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 1.w,
                                        height: 1.w,
                                        decoration: BoxDecoration(
                                          color: AppTheme
                                              .lightTheme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      SizedBox(width: 2.w),
                                      Expanded(
                                        child: Text(
                                          item['name'],
                                          style: AppTheme
                                              .lightTheme.textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      CurrencyDisplayWidget(
                                        amount: item['total_price'] as double,
                                        currency: widget.currency,
                                        style: AppTheme.getMonospaceStyle(
                                          isLight: true,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              if (widget.assignedItems.length > 3)
                                Text(
                                  '+${widget.assignedItems.length - 3} more',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.secondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
