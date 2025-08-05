const OCRService = require('../services/ocrService');
const { authenticateToken, requireGroupMember } = require('../middleware/auth');

class OCRController {
  // Process receipt image without group context (for camera flow)
  static async processReceiptSimple(req, res) {
    try {
      const userId = req.user.id;
      const imageFile = req.file;

      console.log('OCR processing request:', {
        userId,
        hasFile: !!imageFile,
        fileInfo: imageFile ? {
          originalname: imageFile.originalname,
          mimetype: imageFile.mimetype,
          size: imageFile.size,
          buffer: imageFile.buffer ? 'Buffer present' : 'No buffer'
        } : 'No file'
      });

      if (!imageFile) {
        return res.status(400).json({
          success: false,
          message: 'Image file is required'
        });
      }

      // Upload image to Cloudinary first
      const cloudinary = require('../config/cloudinary');
      
      // Handle Flutter's application/octet-stream MIME type
      let mimeType = imageFile.mimetype;
      if (mimeType === 'application/octet-stream') {
        const fileName = imageFile.originalname.toLowerCase();
        if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (fileName.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (fileName.endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (fileName.endsWith('.webp')) {
          mimeType = 'image/webp';
        }
        console.log('Corrected MIME type from application/octet-stream to:', mimeType);
      }
      
      // Convert buffer to base64 for Cloudinary upload
      const base64Image = imageFile.buffer.toString('base64');
      const dataURI = `data:${mimeType};base64,${base64Image}`;
      
      console.log('Uploading to Cloudinary...');
      const uploadResult = await cloudinary.uploader.upload(dataURI, {
        folder: 'receipts',
        resource_type: 'image',
        transformation: [
          { quality: 'auto:good' },
          { fetch_format: 'auto' }
        ]
      });

      console.log('Cloudinary upload successful:', uploadResult.secure_url);

      // Use the OCR service to process the image URL
      const ocrService = require('../ai/ocrService');
      const ocrData = await ocrService.extractStructuredDataFromImage(uploadResult.secure_url);
      
      const parserService = require('../ai/parserService');
      const parsedData = parserService.parseReceiptData(ocrData);

      console.log('OCR processing completed successfully');

      res.status(200).json({
        success: true,
        message: 'Receipt processed successfully',
        data: {
          title: parsedData.merchant ? `Receipt from ${parsedData.merchant}` : 'Receipt',
          total_amount: parsedData.total_amount,
          date: parsedData.date,
          merchant: parsedData.merchant,
          category: parsedData.category,
          items: parsedData.items,
          confidence: 0.8, // Default confidence
          validation: parsedData.validation,
          image_url: uploadResult.secure_url
        },
        validation: parsedData.validation
      });
    } catch (error) {
      console.error('OCR processing error:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Process receipt image and extract data
  static async processReceipt(req, res) {
    try {
      const userId = req.user.id;
      const { groupId } = req.params;
      const imageFile = req.file;

      if (!imageFile) {
        return res.status(400).json({
          success: false,
          message: 'Image file is required'
        });
      }

      if (!groupId) {
        return res.status(400).json({
          success: false,
          message: 'Group ID is required'
        });
      }

      const result = await OCRService.processReceiptImage(imageFile, groupId, userId);

      res.status(200).json({
        success: true,
        message: 'Receipt processed successfully',
        data: result.data,
        validation: result.validation
      });
    } catch (error) {
      console.error('OCR processing error:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Process receipt from URL (for testing/development)
  static async processReceiptFromUrl(req, res) {
    try {
      const userId = req.user.id;
      const { groupId } = req.params;
      const { imageUrl } = req.body;

      if (!imageUrl) {
        return res.status(400).json({
          success: false,
          message: 'Image URL is required'
        });
      }

      if (!groupId) {
        return res.status(400).json({
          success: false,
          message: 'Group ID is required'
        });
      }

      // Create a mock file object for the URL
      const mockFile = {
        path: imageUrl,
        originalname: 'receipt.jpg'
      };

      const result = await OCRService.processReceiptImage(mockFile, groupId, userId);

      res.status(200).json({
        success: true,
        message: 'Receipt processed successfully',
        data: result.data,
        validation: result.validation
      });
    } catch (error) {
      console.error('OCR processing error:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get receipt images for an expense
  static async getReceiptImages(req, res) {
    try {
      const { expenseId } = req.params;
      const userId = req.user.id;

      if (!expenseId) {
        return res.status(400).json({
          success: false,
          message: 'Expense ID is required'
        });
      }

      const receiptImages = await OCRService.getReceiptImagesForExpense(expenseId);

      res.status(200).json({
        success: true,
        data: receiptImages
      });
    } catch (error) {
      console.error('Error getting receipt images:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Delete receipt image
  static async deleteReceiptImage(req, res) {
    try {
      const { receiptImageId } = req.params;
      const userId = req.user.id;

      if (!receiptImageId) {
        return res.status(400).json({
          success: false,
          message: 'Receipt image ID is required'
        });
      }

      const result = await OCRService.deleteReceiptImage(receiptImageId);

      res.status(200).json({
        success: true,
        message: result.message
      });
    } catch (error) {
      console.error('Error deleting receipt image:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Re-process OCR for an existing receipt image
  static async reprocessReceiptImage(req, res) {
    try {
      const { receiptImageId } = req.params;
      const userId = req.user.id;

      if (!receiptImageId) {
        return res.status(400).json({
          success: false,
          message: 'Receipt image ID is required'
        });
      }

      const result = await OCRService.reprocessReceiptImage(receiptImageId);

      res.status(200).json({
        success: true,
        message: 'Receipt image reprocessed successfully',
        data: result.data,
        validation: result.validation
      });
    } catch (error) {
      console.error('Error reprocessing receipt image:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get OCR statistics
  static async getOCRStats(req, res) {
    try {
      const stats = await OCRService.getOCRStats();

      res.status(200).json({
        success: true,
        data: stats
      });
    } catch (error) {
      console.error('Error getting OCR stats:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Validate OCR configuration
  static async validateConfiguration(req, res) {
    try {
      const config = await OCRService.validateOCRConfiguration();

      res.status(200).json({
        success: true,
        data: config
      });
    } catch (error) {
      console.error('Error validating OCR configuration:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }

  // Legacy endpoint for backward compatibility
  static async extractItems(req, res) {
    try {
      const { imageUrl } = req.body;

      if (!imageUrl) {
        return res.status(400).json({
          success: false,
          message: 'Image URL is required'
        });
      }

      // Use the new OCR service
      const ocrService = require('../ai/ocrService');
      const ocrData = await ocrService.extractStructuredDataFromImage(imageUrl);
      
      const parserService = require('../ai/parserService');
      const parsedData = parserService.parseReceiptData(ocrData);

      res.status(200).json({
        success: true,
        message: 'Items extracted successfully',
        data: {
          items: parsedData.items,
          total: parsedData.total_amount,
          merchant: parsedData.merchant,
          date: parsedData.date,
          category: parsedData.category
        },
        validation: parsedData.validation
      });
    } catch (error) {
      console.error('OCR extraction error:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }
}

module.exports = OCRController; 