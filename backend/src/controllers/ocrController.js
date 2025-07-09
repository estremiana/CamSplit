const ocrService = require('../services/ocrService');

exports.extractItems = async (req, res) => {
  try {
    const { imageUrl } = req.body;

    // Basic validation
    if (!imageUrl) {
      return res.status(400).json({ message: 'Image URL is required.' });
    }

    // Extract items using OCR
    const { items, total } = await ocrService.extractBillData(imageUrl);

    res.status(200).json({ 
      message: 'Items extracted successfully.',
      items: items,
      count: items.length,
      total: total
    });
  } catch (err) {
    console.error('OCR extraction error:', err);
    res.status(500).json({ message: 'Server error during OCR extraction.' });
  }
}; 