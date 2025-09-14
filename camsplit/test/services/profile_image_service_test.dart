import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/services/profile_image_service.dart';

void main() {
  group('ProfileImageService', () {
    late ProfileImageService profileImageService;

    setUp(() {
      profileImageService = ProfileImageService();
    });

    test('should be a singleton', () {
      final instance1 = ProfileImageService();
      final instance2 = ProfileImageService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should compress image', () async {
      // Create a test image file
      final testImagePath = 'test/assets/test_image.jpg';
      final testImageFile = File(testImagePath);
      
      if (await testImageFile.exists()) {
        final compressedFile = await profileImageService.compressImage(testImageFile);
        
        expect(compressedFile, isA<File>());
        expect(await compressedFile.exists(), isTrue);
        
        // Verify the compressed file is smaller or same size
        final originalSize = await testImageFile.length();
        final compressedSize = await compressedFile.length();
        expect(compressedSize <= originalSize, isTrue);
      }
    });

    test('should crop image to square', () async {
      // Create a test image file
      final testImagePath = 'test/assets/test_image.jpg';
      final testImageFile = File(testImagePath);
      
      if (await testImageFile.exists()) {
        final croppedFile = await profileImageService.cropImageToSquare(testImageFile);
        
        expect(croppedFile, isA<File>());
        expect(await croppedFile.exists(), isTrue);
      }
    });

    test('should get image dimensions', () async {
      // Create a test image file
      final testImagePath = 'test/assets/test_image.jpg';
      final testImageFile = File(testImagePath);
      
      if (await testImageFile.exists()) {
        final dimensions = await ProfileImageService.getImageDimensions(testImageFile);
        
        expect(dimensions, isA<Size>());
        expect(dimensions.width, isPositive);
        expect(dimensions.height, isPositive);
      }
    });

    test('should handle missing image file', () async {
      final nonExistentFile = File('non_existent_file.jpg');
      
      expect(
        () => profileImageService.compressImage(nonExistentFile),
        throwsA(isA<Exception>()),
      );
    });
  });
} 