const ImageService = require('../services/imageService');

class ImageController {
  // Upload image to Cloudinary
  static async uploadImage(req, res) {
    try {
      const imageFile = req.file;
      
      if (!imageFile) {
        return res.status(400).json({
          success: false,
          message: 'Image file is required'
        });
      }

      console.log('Image upload request:', {
        originalName: imageFile.originalname,
        mimeType: imageFile.mimetype,
        size: imageFile.size
      });

      const uploadResult = await ImageService.uploadImageToCloudinary(imageFile);

      console.log('Image uploaded successfully:', uploadResult.secure_url);

      res.status(200).json({
        success: true,
        message: 'Image uploaded successfully',
        data: {
          image_url: uploadResult.secure_url,
          public_id: uploadResult.public_id,
          width: uploadResult.width,
          height: uploadResult.height,
          format: uploadResult.format
        }
      });
    } catch (error) {
      console.error('Image upload error:', error);
      res.status(500).json({
        success: false,
        message: error.message
      });
    }
  }
}

module.exports = ImageController;

