import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../presentation/create_expense_wizard/models/scanned_receipt_data.dart';

/// Service for scanning receipts using camera or file picker
/// Integrates with AI/OCR service to extract receipt data
class ReceiptScannerService {
  static final ReceiptScannerService _instance = ReceiptScannerService._();
  static ReceiptScannerService get instance => _instance;

  ReceiptScannerService._();

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from camera
  Future<File?> pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print('Error picking image from camera: $e');
      rethrow;
    }
  }

  /// Pick an image from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      print('Error picking image from gallery: $e');
      rethrow;
    }
  }

  /// Process receipt image with AI/OCR
  /// This is a placeholder that will be integrated with actual AI service
  Future<ScannedReceiptData> processReceiptImage(File imageFile) async {
    try {
      // TODO: Integrate with actual AI/OCR service (Google Vision, AWS Textract, etc.)
      // For now, return mock data for testing
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing time

      // Mock response - in production, this would come from AI service
      return ScannedReceiptData(
        total: 45.99,
        merchant: 'Sample Restaurant',
        date: DateTime.now().toIso8601String(),
        category: 'Food & Dining',
        items: [
          ScannedItem(name: 'Burger', price: 12.99, quantity: 1),
          ScannedItem(name: 'Fries', price: 4.99, quantity: 2),
          ScannedItem(name: 'Drink', price: 3.99, quantity: 3),
        ],
      );
    } catch (e) {
      print('Error processing receipt image: $e');
      rethrow;
    }
  }

  /// Show source selection dialog (camera or gallery)
  Future<File?> showSourceSelectionDialog() async {
    // This will be called from the UI layer
    // The UI will show a dialog and call either pickFromCamera or pickFromGallery
    throw UnimplementedError('This method should be called from UI layer');
  }
}
