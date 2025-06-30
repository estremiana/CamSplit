const express = require('express');
const router = express.Router();
const billController = require('../controllers/billController');

// Example endpoints
router.post('/upload', billController.uploadBill);
router.get('/:id', billController.getBill);

module.exports = router; 