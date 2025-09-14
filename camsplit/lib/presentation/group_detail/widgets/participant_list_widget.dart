import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/group_detail_model.dart';
import '../../../models/group_member.dart';
import '../../../services/group_detail_service.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/custom_image_widget.dart';

class ParticipantListWidget extends StatefulWidget {
  final GroupDetailModel groupDetail;
  final VoidCallback? onParticipantAdded;
  final VoidCallback? onParticipantRemoved;

  const ParticipantListWidget({
    Key? key,
    required this.groupDetail,
    this.onParticipantAdded,
    this.onParticipantRemoved,
  }) : super(key: key);

  @override
  State<ParticipantListWidget> createState() => _ParticipantListWidgetState();
}

class _ParticipantListWidgetState extends State<ParticipantListWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      color: AppTheme.lightTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            SizedBox(height: 2.h),
            _buildParticipantsList(),
            SizedBox(height: 2.h),
            _buildAddParticipantButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Members',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            '${widget.groupDetail.memberCount}',
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsList() {
    if (widget.groupDetail.members.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: widget.groupDetail.members
          .map((member) => _buildParticipantItem(member))
          .toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'group_add',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 32,
          ),
          SizedBox(height: 1.h),
          Text(
            'No members yet',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem(GroupMember member) {
    final bool canRemove = widget.groupDetail.canEdit && 
                          !member.isCurrentUser && 
                          widget.groupDetail.canRemoveMember(member.id.toString());

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          // Avatar
          _buildMemberAvatar(member),
          SizedBox(width: 3.w),
          
          // Member info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (member.email?.isNotEmpty == true)
                  Text(
                    member.email ?? '',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          
          // Remove button (if applicable)
          if (canRemove)
            IconButton(
              onPressed: _isLoading ? null : () => _showRemoveConfirmation(member),
              icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.errorLight,
                    ),
                  )
                : CustomIconWidget(
                    iconName: 'remove_circle_outline',
                    color: AppTheme.errorLight,
                    size: 20,
                  ),
              tooltip: _isLoading ? 'Removing...' : 'Remove ${member.nickname}',
            ),
        ],
      ),
    );
  }

  Widget _buildMemberAvatar(GroupMember member) {
    // Debug logging
    print('ParticipantListWidget: Building avatar for member ${member.nickname}');
    print('ParticipantListWidget: Avatar URL: ${member.avatarUrl}');
    print('ParticipantListWidget: User ID: ${member.userId}');
    
    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.lightTheme.colorScheme.primaryContainer,
      ),
      child: ClipOval(
        child: CustomImageWidget(
          imageUrl: member.avatarUrl,
          width: 10.w,
          height: 10.w,
          userName: member.nickname,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildAddParticipantButton() {
    if (!widget.groupDetail.canEdit) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _showAddParticipantDialog,
        icon: _isLoading 
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            )
          : CustomIconWidget(
              iconName: 'person_add',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
        label: Text(_isLoading ? 'Adding...' : 'Add Member'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
        ),
      ),
    );
  }

  void _showAddParticipantDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Member'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter member name',
                    prefixIcon: CustomIconWidget(
                      iconName: 'person',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter member email',
                    prefixIcon: CustomIconWidget(
                      iconName: 'email',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  _addParticipant(
                    nameController.text.trim(),
                    emailController.text.trim(),
                  );
                }
              },
              child: _isLoading 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                    ),
                  )
                : Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveConfirmation(GroupMember member) {
    // Check if member has outstanding debts
    final bool hasDebts = !widget.groupDetail.canRemoveMember(member.id.toString());
    
    if (hasDebts) {
      _showDebtWarningDialog(member);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Member'),
          content: Text(
            'Are you sure you want to remove ${member.nickname} from this group?',
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () {
                Navigator.of(context).pop();
                _removeParticipant(member);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorLight,
                foregroundColor: AppTheme.lightTheme.colorScheme.onError,
              ),
              child: _isLoading 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.lightTheme.colorScheme.onError,
                    ),
                  )
                : Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showDebtWarningDialog(GroupMember member) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'warning',
                color: AppTheme.warningLight,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text('Cannot Remove Member'),
            ],
          ),
          content: Text(
            '${member.nickname} cannot be removed because they have outstanding debts in this group. Please settle all debts before removing this member.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addParticipant(String name, String email) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call the actual API to add member to group
      await GroupDetailService.addParticipant(
        widget.groupDetail.id, 
        email, 
        name
      );
      
      _showSuccessSnackBar('Member added successfully!');
      
      // Notify parent widget to refresh the UI
      widget.onParticipantAdded?.call();
    } catch (e) {
      _showErrorSnackBar('Failed to add member: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeParticipant(GroupMember member) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call the actual API to remove member from group
      final result = await GroupDetailService.removeParticipant(
        widget.groupDetail.id, 
        member.id.toString()
      );
      
      if (result['success']) {
        _showSuccessSnackBar('Member removed successfully!');
        // Notify parent widget to refresh the UI
        widget.onParticipantRemoved?.call();
      } else {
        if (result['hasDebts']) {
          _showErrorSnackBar('Cannot remove member with outstanding debts');
        } else {
          _showErrorSnackBar(result['message'] ?? 'Failed to remove member');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to remove member: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}