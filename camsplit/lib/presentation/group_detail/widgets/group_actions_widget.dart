import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/app_export.dart';
import '../../../models/group_detail_model.dart';
import '../../../services/group_service.dart';

import '../../../utils/loading_overlay.dart';
import '../../../utils/snackbar_utils.dart';


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
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
          
          // Share Group Action (formerly Generate Invite Link)
          _buildActionTile(
            context: context,
            icon: 'share',
            title: 'Share Group',
            color: AppTheme.lightTheme.colorScheme.secondary,
            onTap: () => _handleGenerateInviteLink(context),
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
          
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
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
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      ),
    );
  }

  /// Handle invite link generation
  Future<void> _handleGenerateInviteLink(BuildContext context) async {
    Navigator.pop(context);
    
    try {
      final loadingOverlay = LoadingOverlayManager();
      loadingOverlay.show(context: context, message: 'Generating invite link...');
      
      final apiService = ApiService.instance;
      final response = await apiService.generateInviteLink(groupDetail.id.toString());
      
      loadingOverlay.hide();
      
      if (response['success']) {
        final inviteUrl = response['data']['inviteUrl'];
        final expiresAt = response['data']['expiresAt'];
        
        // Show invite link dialog
        _showInviteLinkDialog(context, inviteUrl, expiresAt);
      } else {
        SnackBarUtils.showError(context, response['message'] ?? 'Failed to generate invite link');
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to generate invite link: ${e.toString()}');
    }
  }

  /// Show invite link dialog with copy and share options
  void _showInviteLinkDialog(BuildContext context, String inviteUrl, String? expiresAt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Invite Link Generated',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this link with others to invite them to join your group:',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: SelectableText(
                inviteUrl,
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ),
            if (expiresAt != null) ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'schedule',
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    size: 16,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Expires: $expiresAt',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Share.share(
                'Join my CamSplit group "${groupDetail.name}"!\n\n$inviteUrl',
                subject: 'Invitation to join CamSplit group',
              );
            },
            icon: CustomIconWidget(
              iconName: 'share',
              color: Colors.white,
              size: 18,
            ),
            label: Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
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
      
      final result = await GroupService.exitGroup(groupDetail.id.toString());
      
      // Clear any cached data first
      GroupService.clearCache();
      
      // Hide loading message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Prepare success message
      String successMessage;
      if (result['action'] == 'group_deleted') {
        successMessage = 'Group deleted as no members remain';
      } else {
        successMessage = 'Successfully exited group';
      }
      
      // Close the modal bottom sheet first
      Navigator.pop(context);
      
      // Then close the group detail page
      Navigator.pop(context);
      
      // Notify parent widget if callback provided
      onGroupUpdated?.call();
      
      // Navigate to groups page with a fresh instance and pass success message
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.groupManagement,
        (route) => false, // Remove all previous routes
        arguments: {
          'refresh': true, // Trigger refresh
          'successMessage': successMessage, // Pass success message
        },
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Log the full error for debugging
      print('Exit group error: $e');
      _showErrorSnackBar(context, 'Failed to exit group: ${e.toString()}');
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
                    'This action cannot be undone. All group data, expenses, settlements, and member information will be permanently deleted.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.errorLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (groupDetail.hasSettlements) ...[
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
                      'This group has active settlements. Members will lose access to settlement information.',
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
      
      await GroupService.deleteGroupWithCascade(groupDetail.id.toString());
      
      // Clear any cached data first
      GroupService.clearCache();
      
      // Hide loading message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      // Close the modal bottom sheet first
      Navigator.pop(context);
      
      // Then close the group detail page
      Navigator.pop(context);
      
      // Notify parent widget if callback provided
      onGroupDeleted?.call();
      
      // Navigate to groups page with a fresh instance and pass success message
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.groupManagement,
        (route) => false, // Remove all previous routes
        arguments: {
          'refresh': true, // Trigger refresh
          'successMessage': 'Group deleted successfully', // Pass success message
        },
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Log the full error for debugging
      print('Delete group error: $e');
      _showErrorSnackBar(context, 'Failed to delete group: ${e.toString()}');
    }
  }

  /// Show loading snack bar
  void _showLoadingSnackBar(BuildContext context, String message) {
    try {
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
    } catch (e) {
      // Context is no longer valid, ignore the error
      debugPrint('GroupActionsWidget: Context is no longer valid - $message');
    }
  }

  /// Show success snack bar
  void _showSuccessSnackBar(BuildContext context, String message) {
    try {
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
    } catch (e) {
      // Context is no longer valid, ignore the error
      debugPrint('GroupActionsWidget: Context is no longer valid - $message');
    }
  }

  /// Show error snack bar
  void _showErrorSnackBar(BuildContext context, String message) {
    try {
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
    } catch (e) {
      // Context is no longer valid, ignore the error
      debugPrint('GroupActionsWidget: Context is no longer valid - $message');
    }
  }
}