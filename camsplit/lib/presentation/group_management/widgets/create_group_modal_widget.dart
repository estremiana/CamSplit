import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';

import '../../../core/app_export.dart';
import '../../../services/group_service.dart';
import '../../../services/currency_service.dart';
import '../../../widgets/currency_selection_widget.dart';
import 'group_image_picker_widget.dart';

class CreateGroupModalWidget extends StatefulWidget {
  final Function(Group) onGroupCreated;

  const CreateGroupModalWidget({
    Key? key,
    required this.onGroupCreated,
  }) : super(key: key);

  @override
  State<CreateGroupModalWidget> createState() => _CreateGroupModalWidgetState();
}

class _CreateGroupModalWidgetState extends State<CreateGroupModalWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();

  Currency _selectedCurrency = CamSplitCurrencyService.getDefaultCurrency();
  final List<String> _inviteEmails = [];
  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;
  String? _selectedImagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addEmail() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty &&
        _isValidEmail(email) &&
        !_inviteEmails.contains(email)) {
      setState(() {
        _inviteEmails.add(email);
        _emailController.clear();
      });
    }
  }

  void _removeEmail(String email) {
    setState(() {
      _inviteEmails.remove(email);
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      // Create group using real service
      final newGroup = await GroupService.createGroup(
        _nameController.text.trim(),
        _inviteEmails,
        currency: _selectedCurrency,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        imagePath: _selectedImagePath,
      );

      // Call the callback to update the parent widget
      widget.onGroupCreated(newGroup);

      if (mounted) {
        Navigator.pop(context); // Close the modal
        
        // Navigate directly to the group detail page
        Navigator.pushNamed(
          context,
          AppRoutes.groupDetail,
          arguments: {
            'groupId': newGroup.id,
            'isNewGroup': true,
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isCreating = false;
      });
    }
  }


  void _retryCreation() {
    setState(() {
      _errorMessage = null;
    });
    _createGroup();
  }

  void _generateShareLink() {
    // Generate shareable link
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Group Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'https://camsplit.app/join/abc123',
                      style: AppTheme.getMonospaceStyle(
                        isLight: true,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Copy to clipboard
                    },
                    icon: CustomIconWidget(
                      iconName: 'copy',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Share this link with friends to invite them to your group',
              style: AppTheme.lightTheme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Share via system share
              Navigator.pop(context);
            },
            child: Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                IconButton(
                  onPressed: _isCreating ? null : () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: _isCreating 
                        ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                        : AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Text(
                    _getHeaderText(),
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 12.w), // Balance the close button
              ],
            ),
          ),
          Divider(color: AppTheme.lightTheme.dividerColor),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  String _getHeaderText() {
    if (_errorMessage != null) {
      return 'Creation Failed';
    }
    return 'Create New Group';
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorContent();
    }
    return _buildFormContent();
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupImageSection(),
            SizedBox(height: 3.h),
            _buildBasicInfo(),
            SizedBox(height: 3.h),
            _buildCurrencySelection(),
            SizedBox(height: 3.h),
            _buildInviteSection(),
            SizedBox(height: 4.h),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }


  Widget _buildErrorContent() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.errorLight,
            ),
            child: Icon(
              Icons.error_outline,
              size: 12.w,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Creation Failed',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.errorLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  child: Text('Edit Details'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _retryCreation,
                  child: Text('Try Again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Photo',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        Center(
          child: GroupImagePickerWidget(
            currentImageUrl: null,
            selectedImagePath: _selectedImagePath,
            groupName: _nameController.text.trim().isNotEmpty 
                ? _nameController.text.trim() 
                : 'New Group',
            onImageSelected: (String? imagePath) {
              setState(() {
                _selectedImagePath = imagePath;
              });
            },
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Add a photo to help identify your group',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Details',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Group Name',
            hintText: 'e.g., Roommates, Weekend Trip',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'group',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a group name';
            }
            if (value.trim().length < 2) {
              return 'Group name must be at least 2 characters';
            }
            return null;
          },
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description (Optional)',
            hintText: 'Brief description of the group',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'description',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildCurrencySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currency',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: () => _showCurrencyPicker(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Currency',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${_selectedCurrency.flag} ${_selectedCurrency.code} - ${_selectedCurrency.name}',
                        style: AppTheme.lightTheme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.textSecondaryLight,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => CurrencySelectionWidget(
        selectedCurrency: _selectedCurrency,
        onCurrencySelected: (Currency selectedCurrency) {
          setState(() {
            _selectedCurrency = selectedCurrency;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildInviteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Invite Members',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _generateShareLink,
              icon: CustomIconWidget(
                iconName: 'share',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 16,
              ),
              label: Text('Share Link'),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter email to invite',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'email',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                onFieldSubmitted: (_) => _addEmail(),
              ),
            ),
            SizedBox(width: 2.w),
            IconButton(
              onPressed: _addEmail,
              icon: CustomIconWidget(
                iconName: 'add',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
            ),
          ],
        ),
        if (_inviteEmails.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            'Invited Members (${_inviteEmails.length})',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _inviteEmails.map((email) {
              return Chip(
                label: Text(
                  email,
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
                deleteIcon: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                onDeleted: () => _removeEmail(email),
                backgroundColor:
                    AppTheme.lightTheme.colorScheme.secondaryContainer,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createGroup,
        child: _isCreating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 5.w,
                    height: 5.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text('Creating Group...'),
                ],
              )
            : Text('Create Group'),
      ),
    );
  }
}
