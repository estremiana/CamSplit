import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/group_image_service.dart';
import '../../camera_capture/flexible_camera_capture.dart';
import '../../camera_capture/config/camera_capture_config.dart';
import '../../camera_capture/config/camera_capture_mode.dart';
import '../../camera_capture/config/camera_capture_theme.dart';

class GroupImagePickerWidget extends StatefulWidget {
  final String? currentImageUrl;
  final String? selectedImagePath;
  final String? groupName;
  final Function(String?) onImageSelected;
  final Function(String)? onImageUploaded;
  final String? groupId; // For uploading existing group images

  const GroupImagePickerWidget({
    super.key,
    this.currentImageUrl,
    this.selectedImagePath,
    this.groupName,
    required this.onImageSelected,
    this.onImageUploaded,
    this.groupId,
  });

  @override
  State<GroupImagePickerWidget> createState() => _GroupImagePickerWidgetState();
}

class _GroupImagePickerWidgetState extends State<GroupImagePickerWidget> {
  final GroupImageService _groupImageService = GroupImageService();
  bool _isUploading = false;
  String? _tempImagePath;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildImagePreview(),
        SizedBox(height: 2.h),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: _showImageOptions,
      child: Container(
        width: 20.w,
        height: 20.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.outline,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: _buildImageContent(),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    // Show uploading indicator
    if (_isUploading) {
      return Container(
        color: AppTheme.lightTheme.colorScheme.surface,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.lightTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    // Show temporary image if selected
    if (_tempImagePath != null) {
      return Image.file(
        File(_tempImagePath!),
        width: 20.w,
        height: 20.w,
        fit: BoxFit.cover,
      );
    }

    // Show current image URL
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return GroupImageService.buildGroupAvatar(
        imageUrl: widget.currentImageUrl,
        groupName: widget.groupName ?? 'Group',
        size: 20.w,
      );
    }

    // Show default group avatar
    return GroupImageService.buildGroupAvatar(
      imageUrl: null,
      groupName: widget.groupName ?? 'Group',
      size: 20.w,
      backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
      textColor: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(
          icon: 'camera_alt',
          label: 'Camera',
          onTap: _openCamera,
        ),
        SizedBox(width: 4.w),
        _buildActionButton(
          icon: 'photo_library',
          label: 'Gallery',
          onTap: _openGallery,
        ),
        if (_tempImagePath != null || (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty)) ...[
          SizedBox(width: 4.w),
          _buildActionButton(
            icon: 'delete',
            label: 'Remove',
            onTap: _removePhoto,
            isDestructive: true,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: _isUploading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isDestructive 
              ? AppTheme.errorLight.withOpacity(0.1)
              : AppTheme.lightTheme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isDestructive 
                ? AppTheme.errorLight
                : AppTheme.lightTheme.colorScheme.outline,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isDestructive 
                  ? AppTheme.errorLight
                  : AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: isDestructive 
                    ? AppTheme.errorLight
                    : AppTheme.lightTheme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageOptions() {
    if (_isUploading) return;
    
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
              width: 8.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Group Photo',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    icon: 'camera_alt',
                    label: 'Take Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _openCamera();
                    },
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildOptionButton(
                    icon: 'photo_library',
                    label: 'Choose from Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _openGallery();
                    },
                  ),
                ),
              ],
            ),
            if (_tempImagePath != null || (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty)) ...[
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: _buildOptionButton(
                  icon: 'delete',
                  label: 'Remove Photo',
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                  isDestructive: true,
                ),
              ),
            ],
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: CustomIconWidget(
        iconName: icon,
        color: isDestructive 
            ? Colors.white
            : AppTheme.lightTheme.colorScheme.primary,
        size: 20,
      ),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive 
            ? AppTheme.errorLight
            : AppTheme.lightTheme.colorScheme.surface,
        foregroundColor: isDestructive 
            ? Colors.white
            : AppTheme.lightTheme.colorScheme.primary,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: isDestructive 
                ? AppTheme.errorLight
                : AppTheme.lightTheme.colorScheme.outline,
          ),
        ),
      ),
    );
  }

  void _openGallery() async {
    try {
      HapticFeedback.selectionClick();
      
      final File? imageFile = await _groupImageService.pickFromGallery();
      if (imageFile != null) {
        await _processSelectedImage(imageFile);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _openCamera() async {
    try {
      HapticFeedback.selectionClick();
      
      // Create camera configuration for group photo
      final config = CameraCaptureConfig(
        title: 'Group Photo',
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
          instructionText: 'Position the group within the frame and capture',
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
      // Process the captured image
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

      // If we have a groupId, upload the image directly
      if (widget.groupId != null) {
        await _uploadImage(imageFile);
      } else {
        // For new groups, just notify parent about the selected image
        widget.onImageSelected(imageFile.path);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to process image: $e');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    if (widget.groupId == null) return;
    
    setState(() {
      _isUploading = true;
    });

    try {
      final String imageUrl = await _groupImageService.uploadGroupImage(widget.groupId!, imageFile);
      
      // Clear cache to ensure fresh image is loaded
      await GroupImageService.clearCache();
      
      // Notify parent about the uploaded image URL
      if (widget.onImageUploaded != null) {
        widget.onImageUploaded!(imageUrl);
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
              'Group photo updated successfully',
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
