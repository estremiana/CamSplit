import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../widgets/initials_avatar_widget.dart';
import 'api_service.dart';

class ProfileImageService {
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService.instance;

  /// Pick image from camera
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Compress image for profile picture
  Future<File> compressImage(File imageFile) async {
    try {
      // Read image
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to 400x400 for profile picture
      final img.Image resized = img.copyResize(
        image,
        width: 400,
        height: 400,
        interpolation: img.Interpolation.cubic,
      );

      // Compress with good quality
      final Uint8List compressedBytes = img.encodeJpg(resized, quality: 85);
      
      // Save to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Crop image to square aspect ratio
  Future<File> cropImageToSquare(File imageFile) async {
    try {
      // Read image
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate crop dimensions for square
      final int size = image.width < image.height ? image.width : image.height;
      final int x = (image.width - size) ~/ 2;
      final int y = (image.height - size) ~/ 2;

      // Crop to square
      final img.Image cropped = img.copyCrop(
        image,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      // Save to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File croppedFile = File(tempPath);
      await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));
      
      return croppedFile;
    } catch (e) {
      throw Exception('Failed to crop image: $e');
    }
  }

  /// Upload profile image to server
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      // Process image: crop to square and compress in one step
      final File processedImage = await _processImageForUpload(imageFile);
      
      // Create form data with proper content type
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          processedImage.path,
          filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      // Upload to server
      final response = await _apiService.dio.post(
        '${ApiConfig.baseUrl}/users/profile/avatar',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['data']['avatar_url'];
      } else {
        throw Exception(response.data['message'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Process image for upload: crop to square and compress
  Future<File> _processImageForUpload(File imageFile) async {
    try {
      // Read image
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate crop dimensions for square
      final int size = image.width < image.height ? image.width : image.height;
      final int x = (image.width - size) ~/ 2;
      final int y = (image.height - size) ~/ 2;

      // Crop to square
      final img.Image cropped = img.copyCrop(
        image,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      // Resize to 400x400 for profile picture
      final img.Image resized = img.copyResize(
        cropped,
        width: 400,
        height: 400,
        interpolation: img.Interpolation.cubic,
      );

      // Compress with good quality
      final Uint8List compressedBytes = img.encodeJpg(resized, quality: 85);
      
      // Save to temporary file with proper extension
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File processedFile = File(tempPath);
      await processedFile.writeAsBytes(compressedBytes);
      
      return processedFile;
    } catch (e) {
      throw Exception('Failed to process image for upload: $e');
    }
  }

  /// Get cached image widget with fallback
  static Widget getCachedImage({
    required String? imageUrl,
    required double size,
    BoxFit fit = BoxFit.cover,
    String? placeholderText,
    String? userName,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholder(size, placeholderText, userName);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholder(size, placeholderText, userName),
      errorWidget: (context, url, error) => _buildPlaceholder(size, placeholderText, userName),
      memCacheWidth: (size * 2).toInt(),
      memCacheHeight: (size * 2).toInt(),
    );
  }

  /// Build placeholder widget
  static Widget _buildPlaceholder(double size, String? placeholderText, String? userName) {
    // If we have a user name, use initials avatar
    if (userName != null && userName.isNotEmpty) {
      return InitialsAvatarWidget(
        name: userName,
        size: size,
      );
    }
    
    // Otherwise use the default placeholder
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: size * 0.4,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// Clear image cache
  static Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache('');
  }

  /// Get image dimensions
  static Future<Size> getImageDimensions(File imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      
      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      throw Exception('Failed to get image dimensions: $e');
    }
  }
} 