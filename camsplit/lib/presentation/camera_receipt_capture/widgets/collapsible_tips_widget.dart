import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../services/receipt_detection_service.dart';

class CollapsibleTipsWidget extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<String> tips;
  final DetectionResult? detectionResult;

  const CollapsibleTipsWidget({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.tips,
    this.detectionResult,
  });

  @override
  State<CollapsibleTipsWidget> createState() => _CollapsibleTipsWidgetState();
}

class _CollapsibleTipsWidgetState extends State<CollapsibleTipsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CollapsibleTipsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 15.h,
      left: 4.w,
      right: 4.w,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
                      return SlideTransition(
              position: _slideAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: widget.isExpanded ? null : 12.w,
                constraints: BoxConstraints(
                  maxHeight: widget.isExpanded ? 30.h : 12.w,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with toggle button
                      _buildHeader(),
                      
                      // Expandable content
                      Expanded(
                        child: SizeTransition(
                          sizeFactor: _heightAnimation,
                          child: FadeTransition(
                            opacity: _opacityAnimation,
                            child: _buildTipsContent(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: widget.onToggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'info',
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                _getHeaderText(),
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            AnimatedRotation(
              turns: widget.isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: CustomIconWidget(
                iconName: 'expand_more',
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsContent() {
    return Container(
      padding: EdgeInsets.only(
        left: 4.w,
        right: 4.w,
        bottom: 4.w,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contextual tip based on detection state
            if (_hasValidDetection())
              _buildContextualTip()
            else
              ...widget.tips.map((tip) => _buildTip(tip)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContextualTip() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.successLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.successLight.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'check_circle',
            color: AppTheme.successLight,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Great! Your receipt is well-positioned. You can now capture the photo.',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1.w,
            height: 1.w,
            margin: EdgeInsets.only(top: 1.5.w, right: 3.w),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderText() {
    if (widget.detectionResult?.isDetected == true) {
      final confidence = widget.detectionResult!.confidence;
      if (confidence >= 0.8) {
        return 'Receipt detected! Tap for tips';
      } else if (confidence >= 0.6) {
        return 'Possible receipt found! Tap for tips';
      } else {
        return 'Low confidence detection. Tap for tips';
      }
    }
    
    if (widget.detectionResult?.errorMessage != null) {
      return 'Detection error. Tap for tips';
    }
    
    return 'Tips for best results';
  }

  bool _hasValidDetection() {
    return widget.detectionResult?.isDetected == true && 
           widget.detectionResult!.confidence >= 0.6;
  }
}
