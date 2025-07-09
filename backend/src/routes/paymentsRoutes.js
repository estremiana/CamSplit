const express = require('express');
const router = express.Router();
const paymentsController = require('../controllers/paymentsController');

router.post('/payments/:paymentId/pay', paymentsController.markPaymentAsPaid);

module.exports = router;