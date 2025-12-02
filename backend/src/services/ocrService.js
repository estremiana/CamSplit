const ocrService = require('../ai/ocrService');
const parserService = require('../ai/parserService');
const ImageService = require('./imageService');
const db = require('../../database/connection');

class OCRService {
  // Process receipt image and extract structured data
  async processReceiptImage(imageFile, groupId, userId) {
    try {
      // Upload image to Cloudinary
      const uploadResult = await ImageService.uploadImageToCloudinary(imageFile);
      
      // Extract structured data using OCR
      const ocrData = await ocrService.extractStructuredDataFromImage(uploadResult.secure_url);
      
      // Parse and validate the OCR data
      const parsedData = parserService.parseReceiptData(ocrData);
      
      // Get group members for suggestions
      const Group = require('../models/Group');
      const group = await Group.findById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }
      
      const members = await group.getMembers();
      
      // Enhance data with group context
      const enhancedData = parserService.enhanceOCRData(parsedData, members);
      
      // Store receipt image record
      const receiptImageId = await this.storeReceiptImage(uploadResult.secure_url, ocrData, null);
      
      return {
        success: true,
        data: {
          ...enhancedData,
          receipt_image_id: receiptImageId,
          image_url: uploadResult.secure_url
        },
        validation: parsedData.validation
      };
    } catch (error) {
      console.error('Receipt processing error:', error);
      throw new Error(`Failed to process receipt: ${error.message}`);
    }
  }

  // Upload image to Cloudinary - DEPRECATED: Use ImageService directly
  async uploadImageToCloudinary(imageFile) {
    return ImageService.uploadImageToCloudinary(imageFile);
  }

  // Store receipt image record in database
  async storeReceiptImage(imageUrl, ocrData, expenseId = null) {
    try {
      const query = `
        INSERT INTO receipt_images (expense_id, image_url, ocr_data, created_at)
        VALUES ($1, $2, $3, NOW())
        RETURNING id
      `;
      
      const result = await db.query(query, [
        expenseId,
        imageUrl,
        JSON.stringify(ocrData)
      ]);

      return result.rows[0].id;
    } catch (error) {
      console.error('Database error storing receipt image:', error);
      throw new Error('Failed to store receipt image');
    }
  }

  // Link receipt image to expense
  async linkReceiptImageToExpense(receiptImageId, expenseId) {
    try {
      const query = `
        UPDATE receipt_images 
        SET expense_id = $1, updated_at = NOW()
        WHERE id = $2
      `;
      
      await db.query(query, [expenseId, receiptImageId]);
    } catch (error) {
      console.error('Database error linking receipt image:', error);
      throw new Error('Failed to link receipt image to expense');
    }
  }

  // Get receipt images for an expense
  async getReceiptImagesForExpense(expenseId) {
    try {
      const query = `
        SELECT id, image_url, ocr_data, created_at
        FROM receipt_images
        WHERE expense_id = $1
        ORDER BY created_at DESC
      `;
      
      const result = await db.query(query, [expenseId]);
      return result.rows;
    } catch (error) {
      console.error('Database error getting receipt images:', error);
      throw new Error('Failed to get receipt images');
    }
  }

  // Delete receipt image
  async deleteReceiptImage(receiptImageId) {
    try {
      // Get image URL before deletion
      const query = `
        SELECT image_url FROM receipt_images WHERE id = $1
      `;
      
      const result = await db.query(query, [receiptImageId]);
      if (result.rows.length === 0) {
        throw new Error('Receipt image not found');
      }

      const imageUrl = result.rows[0].image_url;

      // Delete from Cloudinary
      if (imageUrl) {
        await ImageService.deleteImage(imageUrl);
      }

      // Delete from database
      await db.query('DELETE FROM receipt_images WHERE id = $1', [receiptImageId]);

      return { success: true, message: 'Receipt image deleted successfully' };
    } catch (error) {
      console.error('Error deleting receipt image:', error);
      throw new Error(`Failed to delete receipt image: ${error.message}`);
    }
  }

  // Extract public ID from Cloudinary URL - DEPRECATED: Use ImageService directly
  extractPublicIdFromUrl(url) {
    return ImageService.extractPublicIdFromUrl(url);
  }

  // Re-process OCR for an existing receipt image
  async reprocessReceiptImage(receiptImageId) {
    try {
      // Get receipt image data
      const query = `
        SELECT image_url, ocr_data FROM receipt_images WHERE id = $1
      `;
      
      const result = await db.query(query, [receiptImageId]);
      if (result.rows.length === 0) {
        throw new Error('Receipt image not found');
      }

      const { image_url, ocr_data } = result.rows[0];

      // Re-extract structured data
      const newOcrData = await ocrService.extractStructuredDataFromImage(image_url);
      
      // Parse the new data
      const parsedData = parserService.parseReceiptData(newOcrData);
      
      // Update the database with new OCR data
      await db.query(`
        UPDATE receipt_images 
        SET ocr_data = $1, updated_at = NOW()
        WHERE id = $2
      `, [JSON.stringify(newOcrData), receiptImageId]);

      return {
        success: true,
        data: parsedData,
        validation: parsedData.validation
      };
    } catch (error) {
      console.error('Error reprocessing receipt image:', error);
      throw new Error(`Failed to reprocess receipt image: ${error.message}`);
    }
  }

  // Get OCR statistics
  async getOCRStats() {
    try {
      const query = `
        SELECT 
          COUNT(*) as total_receipts,
          COUNT(CASE WHEN expense_id IS NOT NULL THEN 1 END) as linked_receipts,
          COUNT(CASE WHEN expense_id IS NULL THEN 1 END) as unlinked_receipts,
          AVG(EXTRACT(EPOCH FROM (updated_at - created_at))) as avg_processing_time
        FROM receipt_images
      `;
      
      const result = await db.query(query);
      return result.rows[0];
    } catch (error) {
      console.error('Error getting OCR stats:', error);
      throw new Error('Failed to get OCR statistics');
    }
  }

  // Validate OCR configuration
  async validateOCRConfiguration() {
    const config = {
      azure: false,
      google: false,
      cloudinary: false,
      errors: []
    };

    try {
      // Check Azure Form Recognizer
      if (process.env.AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT && process.env.AZURE_DOCUMENT_INTELLIGENCE_KEY) {
        config.azure = true;
      } else {
        config.errors.push('Azure Form Recognizer not configured');
      }

      // Check Google Cloud Vision
      if (process.env.GOOGLE_CLOUD_VISION_API_KEY) {
        config.google = true;
      } else {
        config.errors.push('Google Cloud Vision not configured');
      }

      // Check Cloudinary
      if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY && process.env.CLOUDINARY_API_SECRET) {
        config.cloudinary = true;
      } else {
        config.errors.push('Cloudinary not configured');
      }

      return config;
  } catch (error) {
      config.errors.push(`Configuration validation error: ${error.message}`);
      return config;
    }
  }
}

module.exports = new OCRService();
