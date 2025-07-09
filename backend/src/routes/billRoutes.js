const express = require('express');
const router = express.Router();
const billController = require('../controllers/billController');
const upload = require('../config/multer');

// POST /api/bills/upload
router.post('/upload', upload.single('image'), billController.uploadBill);

// GET /api/bills/:id
router.get('/:id', billController.getBill);

// GET /api/bills/:id/settle
router.get('/:id/settle', billController.settleBill);

module.exports = router;
