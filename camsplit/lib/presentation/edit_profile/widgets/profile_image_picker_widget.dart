import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/profile_image_service.dart';
import '../../../widgets/image_cropper_widget.dart';

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
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
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
                _takePhoto();
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.successLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CustomIconWidget(
                  iconName: 'photo_library',
                  color: AppTheme.successLight,
                  size: 24,
                ),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            if (widget.currentImageUrl != null || widget.selectedImagePath != null || _tempImagePath != null)
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
  }

  Future<void> _takePhoto() async {
    try {
      HapticFeedback.selectionClick();
      final File? photo = await _profileImageService.takePhoto();
      
      if (photo != null) {
        await _processSelectedImage(photo);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      HapticFeedback.selectionClick();
      final File? image = await _profileImageService.pickFromGallery();
      
      if (image != null) {
        await _processSelectedImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _processSelectedImage(File imageFile) async {
    try {
      // Show cropping interface
      final File? croppedImage = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropperWidget(
            imageFile: imageFile,
            aspectRatio: 1.0, // Square for profile pictures
            onCropComplete: (File croppedFile) {
              Navigator.pop(context, croppedFile);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        ),
      );

      if (croppedImage != null) {
        setState(() {
          _tempImagePath = croppedImage.path;
        });

        // Upload the cropped image
        await _uploadImage(croppedImage);
      }
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
