const express = require('express');
const PaymentController = require('../controllers/paymentController');
const { authenticateToken, requireGroupMember, requireGroupAdmin } = require('../middleware/auth');

const router = express.Router();

// All payment routes require authentication
router.use(authenticateToken);

// Payment CRUD operations
router.post('/', PaymentController.createPayment);
router.get('/', PaymentController.getUserPayments);

// Individual payment operations
router.get('/:paymentId', PaymentController.getPayment);
router.get('/:paymentId/details', PaymentController.getPaymentWithDetails);
router.put('/:paymentId', PaymentController.updatePayment);
router.put('/:paymentId/status', PaymentController.updatePaymentStatus);
router.delete('/:paymentId', PaymentController.deletePayment);

// Payment status shortcuts
router.put('/:paymentId/complete', PaymentController.markPaymentCompleted);
router.put('/:paymentId/cancel', PaymentController.markPaymentCancelled);

// Group payments (requires group membership)
router.get('/group/:groupId', requireGroupMember, PaymentController.getGroupPayments);
router.get('/group/:groupId/pending', requireGroupMember, PaymentController.getPendingPayments);
router.get('/group/:groupId/summary', requireGroupMember, PaymentController.getGroupPaymentSummary);
router.get('/group/:groupId/debts', requireGroupMember, PaymentController.getGroupDebtRelationships);

// Settlement payments (requires group admin)
router.post('/group/:groupId/settle', requireGroupAdmin, PaymentController.createSettlementPayments);

module.exports = router; 