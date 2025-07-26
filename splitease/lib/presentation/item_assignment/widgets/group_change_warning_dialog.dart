import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Dialog that warns users when changing groups will reset existing assignments.
/// Shows when user attempts to change groups and has existing item assignments.
class GroupChangeWarningDialog extends StatelessWidget {
  /// Callback when user confirms the group change
  final VoidCallback onConfirm;
  
  /// Callback when user cancels the group change
  final VoidCallback onCancel;

  const GroupChangeWarningDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  /// Shows the warning dialog and returns true if user confirms, false if cancelled
  static Future<bool?> show({
    required BuildContext context,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return GroupChangeWarningDialog(
          onConfirm: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          onCancel: () {
            Navigator.of(context).pop(false);
            onCancel();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Group change warning dialog',
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
        actionsPadding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
        
        // Dialog title
        title: Semantics(
          header: true,
          child: Text(
            'Change Group?',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ),
        
        // Dialog content/message
        content: Semantics(
          label: 'Warning message about assignment reset',
          child: Text(
            'Changing groups will reset all current assignments. This action cannot be undone.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        
        // Dialog action buttons
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cancel button
              Semantics(
                label: 'Cancel group change',
                button: true,
                child: TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8.0),
              
              // Confirm button
              Semantics(
                label: 'Confirm group change and reset assignments',
                button: true,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Change Group',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}