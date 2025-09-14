import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettlementProcessingWorkflow extends StatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const SettlementProcessingWorkflow({
    super.key,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<SettlementProcessingWorkflow> createState() => _SettlementProcessingWorkflowState();
}

class _SettlementProcessingWorkflowState extends State<SettlementProcessingWorkflow>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  
  int _currentStep = 0;
  final List<String> _steps = [
    'Validating settlement',
    'Creating expense record',
    'Updating balances',
    'Processing payment',
    'Completing settlement'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _startProcessing();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startProcessing() async {
    for (int i = 0; i < _steps.length; i++) {
      setState(() {
        _currentStep = i;
      });
      
      // Simulate processing time for each step
      await Future.delayed(Duration(milliseconds: 800 + (i * 200)));
      
      if (i == _steps.length - 1) {
        // Complete the process
        _animationController.forward();
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onComplete?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'payment',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Processing Settlement',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          
          // Progress indicator
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 2.h),
          
          // Steps list
          ...List.generate(_steps.length, (index) {
            final isCompleted = index < _currentStep;
            final isCurrent = index == _currentStep;
            final isPending = index > _currentStep;
            
            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              child: Row(
                children: [
                  // Step indicator
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppTheme.successLight
                          : isCurrent
                              ? AppTheme.lightTheme.primaryColor
                              : AppTheme.borderLight,
                    ),
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : isCurrent
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : null,
                  ),
                  SizedBox(width: 3.w),
                  
                  // Step text
                  Expanded(
                    child: Text(
                      _steps[index],
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: isCompleted
                            ? AppTheme.successLight
                            : isCurrent
                                ? AppTheme.lightTheme.primaryColor
                                : AppTheme.textSecondaryLight,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          
          SizedBox(height: 3.h),
          
          // Cancel button (only show during processing)
          if (_currentStep < _steps.length - 1)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppTheme.textSecondaryLight,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 