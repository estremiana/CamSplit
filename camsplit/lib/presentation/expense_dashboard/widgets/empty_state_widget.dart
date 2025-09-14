import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onAddExpense;

  const EmptyStateWidget({
    super.key,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 60.w,
              height: 20.h, // Reduced from 30.h to 20.h
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'receipt_long',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 60, // Reduced from 80 to 60
                  ),
                  SizedBox(height: 1.h), // Reduced from 2.h to 1.h
                  CustomIconWidget(
                    iconName: 'add_circle_outline',
                    color:
                        AppTheme.lightTheme.primaryColor.withValues(alpha: 0.6),
                    size: 24, // Reduced from 32 to 24
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),

            // Title and description
            Text(
              'No Expenses Yet',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Start by adding your first expense.\nTake a photo of your receipt and let us handle the rest!',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondaryLight,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),

            // CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddExpense,
                icon: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: AppTheme.onPrimaryLight,
                  size: 20,
                ),
                label: Text(
                  'Add Your First Expense',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.onPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  foregroundColor: AppTheme.onPrimaryLight,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 2.0,
                ),
              ),
            ),
            SizedBox(height: 2.h),

            // Secondary actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to groups
                    },
                    icon: CustomIconWidget(
                      iconName: 'group_add',
                      color: AppTheme.lightTheme.primaryColor,
                      size: 18,
                    ),
                    label: Text(
                      'Create Group',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      side: BorderSide(
                        color: AppTheme.lightTheme.primaryColor,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Show tutorial
                      _showTutorial(context);
                    },
                    icon: CustomIconWidget(
                      iconName: 'help_outline',
                      color: AppTheme.lightTheme.primaryColor,
                      size: 18,
                    ),
                    label: Text(
                      'How it Works',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      side: BorderSide(
                        color: AppTheme.lightTheme.primaryColor,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),

            // Features list
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.cardColor,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: AppTheme.borderLight,
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'What you can do with CamSplit',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildFeatureItem(
                    icon: 'camera_alt',
                    title: 'Scan Receipts',
                    description: 'Take photos and extract items automatically',
                  ),
                  _buildFeatureItem(
                    icon: 'group',
                    title: 'Split with Friends',
                    description: 'Add friends and split expenses fairly',
                  ),
                  _buildFeatureItem(
                    icon: 'calculate',
                    title: 'Auto Calculate',
                    description: 'We handle all the math for you',
                  ),
                  _buildFeatureItem(
                    icon: 'payment',
                    title: 'Track Settlements',
                    description: 'Keep track of who owes what',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required String icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.primaryColor,
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTutorial(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => Container(
        height: 70.h,
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'How CamSplit Works',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            Expanded(
              child: ListView(
                children: [
                  _buildTutorialStep(
                    step: '1',
                    icon: 'camera_alt',
                    title: 'Capture Receipt',
                    description:
                        'Take a photo of your receipt using the camera button',
                  ),
                  _buildTutorialStep(
                    step: '2',
                    icon: 'auto_fix_high',
                    title: 'Auto Extract Items',
                    description:
                        'Our OCR technology automatically extracts items and prices',
                  ),
                  _buildTutorialStep(
                    step: '3',
                    icon: 'group_add',
                    title: 'Add Friends',
                    description:
                        'Select who was part of this expense from your groups',
                  ),
                  _buildTutorialStep(
                    step: '4',
                    icon: 'calculate',
                    title: 'Split & Calculate',
                    description:
                        'Choose how to split each item and we\'ll calculate the amounts',
                  ),
                  _buildTutorialStep(
                    step: '5',
                    icon: 'check_circle',
                    title: 'Track & Settle',
                    description:
                        'Keep track of balances and settle up when ready',
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialStep({
    required String step,
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.onPrimaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.primaryColor,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
