import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';

class GroupCreationProgress extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final bool isAnimating;

  const GroupCreationProgress({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    this.isAnimating = true,
  }) : super(key: key);

  @override
  State<GroupCreationProgress> createState() => _GroupCreationProgressState();
}

class _GroupCreationProgressState extends State<GroupCreationProgress>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _stepAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.currentStep / widget.totalSteps,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _stepAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    if (widget.isAnimating) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(GroupCreationProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.currentStep / widget.totalSteps,
        end: widget.currentStep / widget.totalSteps,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: 0.8.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(0.4.h),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.primaryColor,
                    borderRadius: BorderRadius.circular(0.4.h),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 3.h),
        // Step indicators
        ...List.generate(widget.stepLabels.length, (index) {
          final isCompleted = index < widget.currentStep;
          final isCurrent = index == widget.currentStep - 1;
          final isPending = index >= widget.currentStep;
          
          return AnimatedBuilder(
            animation: _stepAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isCurrent ? 1.0 + (_stepAnimation.value * 0.1) : 1.0,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.h),
                  child: Row(
                    children: [
                      // Step indicator
                      Container(
                        width: 4.w,
                        height: 4.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStepColor(isCompleted, isCurrent, isPending),
                          border: isCurrent 
                              ? Border.all(
                                  color: AppTheme.lightTheme.primaryColor,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: isCompleted
                            ? Icon(
                                Icons.check,
                                size: 2.5.w,
                                color: Colors.white,
                              )
                            : isCurrent
                                ? AnimatedBuilder(
                                    animation: _animationController,
                                    builder: (context, child) {
                                      return CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      );
                                    },
                                  )
                                : null,
                      ),
                      SizedBox(width: 3.w),
                      // Step label
                      Expanded(
                        child: Text(
                          widget.stepLabels[index],
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: _getStepTextColor(isCompleted, isCurrent, isPending),
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Color _getStepColor(bool isCompleted, bool isCurrent, bool isPending) {
    if (isCompleted) {
      return AppTheme.lightTheme.primaryColor;
    } else if (isCurrent) {
      return AppTheme.lightTheme.primaryColor;
    } else {
      return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  Color _getStepTextColor(bool isCompleted, bool isCurrent, bool isPending) {
    if (isCompleted) {
      return AppTheme.lightTheme.colorScheme.onSurface;
    } else if (isCurrent) {
      return AppTheme.lightTheme.primaryColor;
    } else {
      return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }
} 