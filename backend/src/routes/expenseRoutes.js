const express = require('express');
const ExpenseController = require('../controllers/expenseController');
const { authenticateToken, requireGroupMember } = require('../middleware/auth');

const router = express.Router();

// All expense routes require authentication
router.use(authenticateToken);

// Expense CRUD operations
router.post('/', ExpenseController.createExpense);
router.get('/', ExpenseController.getUserExpenses);
router.get('/search', ExpenseController.searchExpenses);

// Individual expense operations (requires group membership)
router.get('/:expenseId', ExpenseController.getExpense);
router.get('/:expenseId/details', ExpenseController.getExpenseWithDetails);
router.put('/:expenseId', ExpenseController.updateExpense);
router.delete('/:expenseId', ExpenseController.deleteExpense);

// Expense settlement
router.get('/:expenseId/settlement', ExpenseController.getExpenseSettlement);

// Expense payers (requires group membership)
router.post('/:expenseId/payers', ExpenseController.addPayer);
router.delete('/:expenseId/payers/:payerId', ExpenseController.removePayer);

// Expense splits (requires group membership)
router.post('/:expenseId/splits', ExpenseController.addSplit);
router.delete('/:expenseId/splits/:splitId', ExpenseController.removeSplit);

// Group expenses (requires group membership)
router.get('/group/:groupId', requireGroupMember, ExpenseController.getGroupExpenses);
router.get('/group/:groupId/stats', requireGroupMember, ExpenseController.getGroupExpenseStats);

module.exports = router; 