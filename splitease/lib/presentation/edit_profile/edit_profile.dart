import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/profile_form_widget.dart';
import './widgets/profile_image_picker_widget.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;
  String? _selectedImagePath;
  String? _currentAvatarUrl;
  String _selectedCurrency = 'USD';
  String _selectedTimezone = 'UTC-5 (EST)';

  Map<String, dynamic>? _originalUserData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _originalUserData = Map<String, dynamic>.from(args);
        final fullName = (args['name'] as String).split(' ');
        _firstNameController.text = fullName.isNotEmpty ? fullName.first : '';
        _lastNameController.text =
            fullName.length > 1 ? fullName.sublist(1).join(' ') : '';
        _emailController.text = args['email'] as String? ?? '';
        _phoneController.text = args['phone'] as String? ?? '';
        _bioController.text = args['bio'] as String? ?? '';
        _currentAvatarUrl = args['avatar'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.cardColor,
        elevation: 1.0,
        leading: IconButton(
          onPressed: _handleBackNavigation,
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.textPrimaryLight,
            size: 24,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _hasChanges ? _saveProfile : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _hasChanges
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Form(
              key: _formKey,
              onChanged: _onFormChanged,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image Picker
                  ProfileImagePickerWidget(
                    currentImageUrl: _currentAvatarUrl,
                    selectedImagePath: _selectedImagePath,
                    onImageSelected: _onImageSelected,
                  ),

                  SizedBox(height: 4.h),

                  // Profile Form
                  ProfileFormWidget(
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    bioController: _bioController,
                    selectedCurrency: _selectedCurrency,
                    selectedTimezone: _selectedTimezone,
                    onCurrencyChanged: _onCurrencyChanged,
                    onTimezoneChanged: _onTimezoneChanged,
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.cardColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Saving Profile...',
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onFormChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _onImageSelected(String? imagePath) {
    setState(() {
      _selectedImagePath = imagePath;
      _hasChanges = true;
    });
  }

  void _onCurrencyChanged(String currency) {
    setState(() {
      _selectedCurrency = currency;
      _hasChanges = true;
    });
  }

  void _onTimezoneChanged(String timezone) {
    setState(() {
      _selectedTimezone = timezone;
      _hasChanges = true;
    });
  }

  void _handleBackNavigation() {
    if (_hasChanges) {
      _showUnsavedChangesDialog();
    } else {
      Navigator.pop(context);
    }
  }

  void _showUnsavedChangesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to profile
            },
            child: Text(
              'Discard Changes',
              style: TextStyle(color: AppTheme.errorLight),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully',
              style: AppTheme.lightTheme.snackBarTheme.contentTextStyle,
            ),
            backgroundColor: AppTheme.successLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        );

        // Haptic feedback for success
        HapticFeedback.lightImpact();

        // Go back to profile screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile. Please try again.',
              style: AppTheme.lightTheme.snackBarTheme.contentTextStyle,
            ),
            backgroundColor: AppTheme.errorLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
