const express = require('express');
const ItemController = require('../controllers/itemController');
const { authenticateToken, requireGroupMember } = require('../middleware/auth');

const router = express.Router();

// All item routes require authentication
router.use(authenticateToken);

// Item CRUD operations (requires group membership)
router.get('/expense/:expenseId', requireGroupMember, ItemController.getExpenseItems);
router.post('/expense/:expenseId', requireGroupMember, ItemController.createItem);
router.get('/:itemId', requireGroupMember, ItemController.getItem);
router.put('/:itemId', requireGroupMember, ItemController.updateItem);
router.delete('/:itemId', requireGroupMember, ItemController.deleteItem);

// Special operations
router.post('/expense/:expenseId/ocr', requireGroupMember, ItemController.createItemsFromOCR);
router.get('/expense/:expenseId/stats', requireGroupMember, ItemController.getItemStats);
router.get('/expense/:expenseId/search', requireGroupMember, ItemController.searchItems);

module.exports = router; 