const cloudinary = require('../config/cloudinary');

class ImageService {
  // Upload image to Cloudinary
  async uploadImageToCloudinary(imageFile) {
    try {
      // Check if imageFile is a buffer (from multer memory storage)
      if (imageFile.buffer) {
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
          console.log('ImageService: Corrected MIME type from application/octet-stream to:', mimeType);
        }

        // Convert buffer to base64 for Cloudinary upload
        const base64Image = imageFile.buffer.toString('base64');
        const dataURI = `data:${mimeType};base64,${base64Image}`;

        console.log('ImageService: Uploading buffer to Cloudinary...');
        const uploadResult = await cloudinary.uploader.upload(dataURI, {
          folder: 'receipts',
          resource_type: 'image',
          transformation: [
            { quality: 'auto:good' },
            { fetch_format: 'auto' }
          ]
        });
        return uploadResult;
      } 
      // Check if imageFile has a path (from multer disk storage or file system)
      else if (imageFile.path) {
        console.log('ImageService: Uploading file path to Cloudinary...');
        const uploadResult = await cloudinary.uploader.upload(imageFile.path, {
          folder: 'receipts',
          resource_type: 'image',
          transformation: [
            { quality: 'auto:good' },
            { fetch_format: 'auto' }
          ]
        });
        return uploadResult;
      } else {
        throw new Error('Invalid image file object: missing buffer or path');
      }
    } catch (error) {
      console.error('Cloudinary upload error:', error);
      throw new Error('Failed to upload image');
    }
  }

  // Extract public ID from Cloudinary URL
  extractPublicIdFromUrl(url) {
    try {
      const urlParts = url.split('/');
      const filename = urlParts[urlParts.length - 1];
      const publicId = filename.split('.')[0];
      return `receipts/${publicId}`;
    } catch (error) {
      console.error('Error extracting public ID:', error);
      return null;
    }
  }
  
  // Delete image from Cloudinary
  async deleteImage(imageUrl) {
    try {
      if (imageUrl) {
        const publicId = this.extractPublicIdFromUrl(imageUrl);
        if (publicId) {
          await cloudinary.uploader.destroy(publicId);
          return true;
        }
      }
      return false;
    } catch (error) {
      console.error('Error deleting image from Cloudinary:', error);
      throw new Error('Failed to delete image');
    }
  }
}

module.exports = new ImageService();

