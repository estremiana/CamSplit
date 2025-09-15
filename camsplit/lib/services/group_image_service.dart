import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../config/api_config.dart';
import '../widgets/initials_avatar_widget.dart';
import 'api_service.dart';

class GroupImageService {
  static final GroupImageService _instance = GroupImageService._internal();
  factory GroupImageService() => _instance;
  GroupImageService._internal();

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

  /// Compress image for group picture
  Future<File> compressImage(File imageFile, {int quality = 85}) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if too large (max 800x800 for group images)
      img.Image resized = image;
      if (image.width > 800 || image.height > 800) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 800 : null,
          height: image.height > image.width ? 800 : null,
          maintainAspect: true,
        );
      }

      // Encode with compression
      final List<int> compressedBytes = img.encodeJpg(resized, quality: quality);
      
      // Save to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/compressed_group_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Crop image to square for group picture
  Future<File> cropToSquare(File imageFile, {int size = 400}) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate crop dimensions for square
      final int minDimension = image.width < image.height ? image.width : image.height;
      final int offsetX = (image.width - minDimension) ~/ 2;
      final int offsetY = (image.height - minDimension) ~/ 2;

      // Crop to square
      final img.Image cropped = img.copyCrop(
        image,
        x: offsetX,
        y: offsetY,
        width: minDimension,
        height: minDimension,
      );

      // Resize to target size
      final img.Image resized = img.copyResize(
        cropped,
        width: size,
        height: size,
      );

      // Save to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/cropped_group_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File croppedFile = File(tempPath);
      await croppedFile.writeAsBytes(img.encodeJpg(resized, quality: 90));
      
      return croppedFile;
    } catch (e) {
      throw Exception('Failed to crop image: $e');
    }
  }

  /// Upload group image to server
  Future<String> uploadGroupImage(String groupId, File imageFile) async {
    try {
      // Process image: crop to square and compress in one step
      final File processedImage = await _processImageForUpload(imageFile);
      
      // Create form data with proper content type
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          processedImage.path,
          filename: 'group_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      // Upload to server
      final response = await _apiService.dio.put(
        '${ApiConfig.baseUrl}/groups/$groupId/image',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['data']['image_url'];
      } else {
        throw Exception(response.data['message'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Failed to upload group image: $e');
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
      final int minDimension = image.width < image.height ? image.width : image.height;
      final int offsetX = (image.width - minDimension) ~/ 2;
      final int offsetY = (image.height - minDimension) ~/ 2;

      // Crop to square
      final img.Image cropped = img.copyCrop(
        image,
        x: offsetX,
        y: offsetY,
        width: minDimension,
        height: minDimension,
      );

      // Resize to 400x400 for group images
      final img.Image resized = img.copyResize(
        cropped,
        width: 400,
        height: 400,
      );

      // Save to temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/processed_group_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File processedFile = File(tempPath);
      await processedFile.writeAsBytes(img.encodeJpg(resized, quality: 85));
      
      return processedFile;
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  /// Clear image cache
  static Future<void> clearCache() async {
    try {
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      // Ignore cache clearing errors
    }
  }

  /// Build group avatar widget
  static Widget buildGroupAvatar({
    required String? imageUrl,
    required String groupName,
    double size = 60.0,
    Color? backgroundColor,
    Color? textColor,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: size,
              height: size,
              color: Colors.grey.shade200,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => InitialsAvatarWidget(
              name: groupName,
              size: size,
              backgroundColor: backgroundColor,
              textColor: textColor,
            ),
          ),
        ),
      );
    } else {
      return InitialsAvatarWidget(
        name: groupName,
        size: size,
        backgroundColor: backgroundColor,
        textColor: textColor,
      );
    }
  }
}
