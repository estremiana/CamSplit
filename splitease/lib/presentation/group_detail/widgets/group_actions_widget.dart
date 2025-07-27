import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/app_export.dart';
import '../../../models/group_detail_model.dart';
import '../../../services/group_service.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget that provides group management actions through a bottom sheet interface
/// Includes share, exit, and delete group functionality with proper permission checks
class GroupActionsWidget extends StatelessWidget {
  final GroupDetailModel groupDetail;
  final VoidCallback? onGroupUpdated;
  final VoidCallback? onGroupDeleted;

  const GroupActionsWidget({
    Key? key,
    required this.groupDetail,
    this.onGroupUpdated,
    this.onGroupDeleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 3.h),
          
          // Title
          Text(
            'Group Actions',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          
          // Share Group Action
          _buildActionTile(
            context: context,
            icon: 'share',
            title: 'Share Group',
            color: AppTheme.lightTheme.colorScheme.primary,
            onTap: () => _handleShareGroup(context),
          ),
          
          // Exit Group Action
          _buildActionTile(
            context: context,
            icon: 'exit_to_app',
            title: 'Exit Group',
            color: AppTheme.lightTheme.colorScheme.error,
            onTap: () => _handleExitGroup(context),
          ),
          
          // Delete Group Action (only if user has permission)
          if (groupDetail.canDelete)
            _buildActionTile(
              context: context,
              icon: 'delete',
              title: 'Delete Group',
              color: AppTheme.errorLight,
              onTap: () => _handleDeleteGroup(context),
            ),
          
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        color: color,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// Handle share group functionality with platform-specific sharing
  void _handleShareGroup(BuildContext context) {
    Navigator.pop(context);
    
    try {
      final shareText = _buildShareText();
      Share.share(
        shareText,
        subject: 'Join my SplitEase group: ${groupDetail.name}',
      );
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to share group. Please try again.');
    }
  }

  /// Build the text content for sharing
  String _buildShareText() {
    final memberCount = groupDetail.memberCount;
    final memberText = memberCount == 1 ? 'member' : 'members';
    
    return '''
Join my SplitEase group "${groupDetail.name}"!

${groupDetail.description.isNotEmpty ? '${groupDetail.description}\n\n' : ''}Current members: $memberCount $memberText

Download SplitEase to manage shared expenses easily:
[App Store/Play Store Link]
''';
  }

  /// Handle exit group functionality with confirmation dialog
  void _handleExitGroup(BuildContext context) {
    Navigator.pop(context);
    
    showDialog(
      context: context,
      builder: (context) => _buildExitConfirmationDialog(context),
    );
  }

  /// Build exit group confirmation dialog
  Widget _buildExitConfirmationDialog(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Exit Group',
        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to exit "${groupDetail.name}"?',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          SizedBox(height: 2.h),
          if (groupDetail.userBalance != 0)
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.warningLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'warning',
                    color: AppTheme.warningLight,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      groupDetail.userBalance > 0
                          ? 'You are owed ${groupDetail.userBalance.toStringAsFixed(2)} ${groupDetail.currency}. Exiting will forfeit this amount.'
                          : 'You owe ${(-groupDetail.userBalance).toStringAsFixed(2)} ${groupDetail.currency}. Please settle your debts before exiting.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _confirmExitGroup(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            foregroundColor: AppTheme.lightTheme.colorScheme.onError,
          ),
          child: Text('Exit Group'),
        ),
      ],
    );
  }

  /// Confirm and execute exit group action
  Future<void> _confirmExitGroup(BuildContext context) async {
    Navigator.pop(context); // Close dialog
    
    try {
      _showLoadingSnackBar(context, 'Exiting group...');
      
      // TODO: Replace with actual API call when backend is ready
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSuccessSnackBar(context, 'Successfully exited group');
      
      // Navigate back to groups page
      Navigator.pop(context);
      
      // Notify parent widget if callback provided
      onGroupUpdated?.call();
      
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar(context, 'Failed to exit group. Please try again.');
    }
  }

  /// Handle delete group functionality with confirmation dialog
  void _handleDeleteGroup(BuildContext context) {
    Navigator.pop(context);
    
    showDialog(
      context: context,
      builder: (context) => _buildDeleteConfirmationDialog(context),
    );
  }

  /// Build delete group confirmation dialog
  Widget _buildDeleteConfirmationDialog(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Delete Group',
        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppTheme.errorLight,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to permanently delete "${groupDetail.name}"?',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.errorLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.errorLight.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'warning',
                  color: AppTheme.errorLight,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'This action cannot be undone. All group data, expenses, and member information will be permanently deleted.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.errorLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (groupDetail.hasDebts) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.warningLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningLight.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info',
                    color: AppTheme.warningLight,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'This group has outstanding debts. Members will lose access to debt information.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _confirmDeleteGroup(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorLight,
            foregroundColor: AppTheme.lightTheme.colorScheme.onError,
          ),
          child: Text('Delete Group'),
        ),
      ],
    );
  }

  /// Confirm and execute delete group action
  Future<void> _confirmDeleteGroup(BuildContext context) async {
    Navigator.pop(context); // Close dialog
    
    try {
      _showLoadingSnackBar(context, 'Deleting group...');
      
      // TODO: Replace with actual API call when backend is ready
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSuccessSnackBar(context, 'Group deleted successfully');
      
      // Navigate back to groups page
      Navigator.pop(context);
      
      // Notify parent widget if callback provided
      onGroupDeleted?.call();
      
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar(context, 'Failed to delete group. Please try again.');
    }
  }

  /// Show loading snack bar
  void _showLoadingSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.colorScheme.onInverseSurface,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Text(message),
          ],
        ),
        duration: Duration(seconds: 30), // Long duration for loading
      ),
    );
  }

  /// Show success snack bar
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.successLight,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.successLight,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Show error snack bar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              color: AppTheme.lightTheme.colorScheme.onError,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.errorLight,
        duration: Duration(seconds: 4),
      ),
    );
  }
}