const express = require('express');
const router = express.Router();
const itemController = require('../controllers/itemController');

// POST /api/bills/:billId/items
router.post('/bills/:billId/items', itemController.addItemsToBill);

// GET /api/bills/:billId/items
router.get('/bills/:billId/items', itemController.getItemsForBill);

module.exports = router; 