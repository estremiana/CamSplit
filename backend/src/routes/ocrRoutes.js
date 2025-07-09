const express = require('express');
const router = express.Router();
const ocrController = require('../controllers/ocrController');

// POST /api/ocr/extract
router.post('/extract', ocrController.extractItems);

module.exports = router; 