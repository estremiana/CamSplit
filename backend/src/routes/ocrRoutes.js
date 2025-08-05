const express = require('express');
const multer = require('multer');
const OCRController = require('../controllers/ocrController');
const { authenticateToken, requireGroupMember } = require('../middleware/auth');

const router = express.Router();

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    console.log('File upload attempt:', {
      originalname: file.originalname,
      mimetype: file.mimetype,
      size: file.size
    });
    
    // More robust file type validation for Flutter compatibility
    const allowedMimeTypes = [
      'image/jpeg',
      'image/jpg', 
      'image/png',
      'image/gif',
      'image/webp',
      'application/octet-stream' // Allow this for Flutter compatibility
    ];
    
    // Check if mimetype is allowed
    if (allowedMimeTypes.includes(file.mimetype)) {
      // For application/octet-stream, check the file extension
      if (file.mimetype === 'application/octet-stream') {
        const fileName = file.originalname.toLowerCase();
        const isImageFile = fileName.endsWith('.jpg') || 
                           fileName.endsWith('.jpeg') || 
                           fileName.endsWith('.png') || 
                           fileName.endsWith('.gif') || 
                           fileName.endsWith('.webp');
        
        if (isImageFile) {
          console.log('File accepted - application/octet-stream with image extension:', fileName);
          cb(null, true);
        } else {
          console.log('File rejected - application/octet-stream with non-image extension:', fileName);
          cb(new Error(`Invalid file type. Only image files are allowed. Received: ${file.mimetype} with filename: ${file.originalname}`), false);
        }
      } else {
        console.log('File accepted - valid image mimetype:', file.mimetype);
        cb(null, true);
      }
    } else {
      console.log('File rejected - mimetype:', file.mimetype);
      cb(new Error(`Invalid file type. Only image files are allowed. Received: ${file.mimetype || 'unknown'}`), false);
    }
  }
});

// All OCR routes require authentication
router.use(authenticateToken);

// Process receipt image without group context (for camera flow)
router.post('/process-simple', upload.single('image'), OCRController.processReceiptSimple);

// Process receipt image (file upload)
router.post('/process/:groupId', requireGroupMember, upload.single('image'), OCRController.processReceipt);

// Process receipt from URL (for testing/development)
router.post('/process/:groupId/url', requireGroupMember, OCRController.processReceiptFromUrl);

// Get receipt images for an expense
router.get('/expense/:expenseId/images', OCRController.getReceiptImages);

// Delete receipt image
router.delete('/images/:receiptImageId', OCRController.deleteReceiptImage);

// Re-process OCR for existing receipt image
router.post('/images/:receiptImageId/reprocess', OCRController.reprocessReceiptImage);

// OCR statistics and configuration
router.get('/stats', OCRController.getOCRStats);
router.get('/config', OCRController.validateConfiguration);

// Legacy endpoint for backward compatibility
router.post('/extract', OCRController.extractItems);

// Error handling for file upload
router.use((error, req, res, next) => {
  console.log('OCR route error:', error.message);
  
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: 'File size too large. Maximum size is 10MB.'
      });
    }
  }
  
  if (error.message.includes('Only image files are allowed')) {
    return res.status(400).json({
      success: false,
      message: error.message
    });
  }
  
  next(error);
});

module.exports = router; 