import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class EnhancedEmptyStateWidget extends StatefulWidget {
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final bool showAnimation;

  const EnhancedEmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    this.actionText,
    this.onActionPressed,
    this.showAnimation = true,
  });

  @override
  State<EnhancedEmptyStateWidget> createState() =>
      _EnhancedEmptyStateWidgetState();
}

class _EnhancedEmptyStateWidgetState extends State<EnhancedEmptyStateWidget>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    if (widget.showAnimation) {
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _bounceController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceController, _fadeController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated icon
                    Transform.scale(
                      scale: _bounceAnimation.value,
                      child: Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.lightTheme.colorScheme.primary,
                              AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.receipt_long,
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          size: 12.w,
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Title
                    Text(
                      widget.title,
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 2.h),

                    // Description
                    Text(
                      widget.description,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.secondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 4.h),

                    // Helpful steps
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.lightTheme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Steps:',
                            style: AppTheme.lightTheme.textTheme.titleSmall
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          _buildStep(
                            number: '1',
                            text: 'Take a photo of your receipt',
                            icon: Icons.camera_alt,
                          ),
                          SizedBox(height: 1.h),
                          _buildStep(
                            number: '2',
                            text: 'Review and edit detected items',
                            icon: Icons.edit,
                          ),
                          SizedBox(height: 1.h),
                          _buildStep(
                            number: '3',
                            text: 'Assign items to group members',
                            icon: Icons.group,
                          ),
                        ],
                      ),
                    ),

                    if (widget.actionText != null &&
                        widget.onActionPressed != null) ...[
                      SizedBox(height: 4.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onActionPressed,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(widget.actionText!),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep({
    required String number,
    required String text,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Icon(
          icon,
          color: AppTheme.lightTheme.colorScheme.secondary,
          size: 5.w,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            text,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
