import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/profile_image_service.dart';
import '../../camera_capture/flexible_camera_capture.dart';
import '../../camera_capture/config/camera_capture_config.dart';
import '../../camera_capture/config/camera_capture_mode.dart';
import '../../camera_capture/config/camera_capture_theme.dart';

class ProfileImagePickerWidget extends StatefulWidget {
  final String? currentImageUrl;
  final String? selectedImagePath;
  final String? userName;
  final Function(String?) onImageSelected;
  final Function(String)? onImageUploaded;

  const ProfileImagePickerWidget({
    super.key,
    this.currentImageUrl,
    this.selectedImagePath,
    this.userName,
    required this.onImageSelected,
    this.onImageUploaded,
  });

  @override
  State<ProfileImagePickerWidget> createState() => _ProfileImagePickerWidgetState();
}

class _ProfileImagePickerWidgetState extends State<ProfileImagePickerWidget> {
  final ProfileImageService _profileImageService = ProfileImageService();
  bool _isUploading = false;
  String? _tempImagePath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTheme.primaryColor,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _buildImageWidget(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploading ? null : () => _showImagePickerOptions(context),
                  child: Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: _isUploading 
                          ? Colors.grey 
                          : AppTheme.lightTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.cardColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowLight,
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isUploading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : CustomIconWidget(
                            iconName: 'camera_alt',
                            color: Colors.white,
                            size: 16,
                          ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          TextButton(
            onPressed: _isUploading ? null : () => _showImagePickerOptions(context),
            child: Text(
              _isUploading ? 'Uploading...' : 'Change Photo',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: _isUploading 
                    ? AppTheme.textSecondaryLight
                    : AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_tempImagePath != null) {
      return Image.file(
        File(_tempImagePath!),
        width: 30.w,
        height: 30.w,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    } else if (widget.selectedImagePath != null) {
      return Image.asset(
        widget.selectedImagePath!,
        width: 30.w,
        height: 30.w,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    } else {
      return ProfileImageService.getCachedImage(
        imageUrl: widget.currentImageUrl,
        size: 30.w,
        fit: BoxFit.cover,
        userName: widget.userName,
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 30.w,
      height: 30.w,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 12.w,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    HapticFeedback.selectionClick();
    
    // Check if user has existing photo to show remove option
    final bool hasExistingPhoto = widget.currentImageUrl != null || 
                                 widget.selectedImagePath != null || 
                                 _tempImagePath != null;
    
    if (hasExistingPhoto) {
      // Show options for existing photo (camera or remove)
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        builder: (context) => Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                'Change Profile Photo',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: CustomIconWidget(
                    iconName: 'camera_alt',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 24,
                  ),
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _openCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: AppTheme.errorLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: CustomIconWidget(
                    iconName: 'delete',
                    color: AppTheme.errorLight,
                    size: 24,
                  ),
                ),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
              SizedBox(height: 1.h),
            ],
          ),
        ),
      );
    } else {
      // No existing photo, go directly to camera
      _openCamera();
    }
  }

  void _openCamera() async {
    try {
      HapticFeedback.selectionClick();
      
      // Create camera configuration for profile photo
      final config = CameraCaptureConfig(
        title: 'Profile Photo',
        subtitle: 'Take a photo or choose from gallery',
        mode: CameraCaptureMode.general,
        enableCrop: true,
        enableGallery: true,
        enableFlash: true,
        enableCameraSwitch: true,
        showInstructions: true,
        theme: CameraCaptureTheme.general.copyWith(
          primaryColor: AppTheme.lightTheme.primaryColor,
          backgroundColor: Colors.black,
          textColor: Colors.white,
          instructionText: 'Position your face within the frame and capture',
        ),
        onImageCaptured: _handleImageCaptured,
        onCancel: () {
          Navigator.pop(context);
        },
        onError: (error) {
          _showErrorSnackBar('Camera error: $error');
        },
      );
      
      // Navigate to the new camera widget
      await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => FlexibleCameraCapture(config: config),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to open camera: $e');
    }
  }

  Future<void> _handleImageCaptured(File imageFile) async {
    try {
      // Process the captured image through cropping
      await _processSelectedImage(imageFile);
      
      // Close the camera screen
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to process image: $e');
    }
  }

  Future<void> _processSelectedImage(File imageFile) async {
    try {
      // Set the temporary image path for preview
      setState(() {
        _tempImagePath = imageFile.path;
      });

      // Upload the image directly without cropping
      await _uploadImage(imageFile);
    } catch (e) {
      _showErrorSnackBar('Failed to process image: $e');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final String avatarUrl = await _profileImageService.uploadProfileImage(imageFile);
      
      // Clear cache to ensure fresh image is loaded
      await ProfileImageService.clearCache();
      
      // Notify parent about the uploaded image URL
      if (widget.onImageUploaded != null) {
        widget.onImageUploaded!(avatarUrl);
      }
      
      // Update the widget state
      setState(() {
        _tempImagePath = null;
        _isUploading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile photo updated successfully',
              style: AppTheme.lightTheme.snackBarTheme.contentTextStyle,
            ),
            backgroundColor: AppTheme.successLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorSnackBar('Failed to upload image: $e');
    }
  }

  void _removePhoto() {
    HapticFeedback.selectionClick();
    setState(() {
      _tempImagePath = null;
    });
    widget.onImageSelected(null);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
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
  }
}
