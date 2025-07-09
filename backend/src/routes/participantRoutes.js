const express = require('express');
const router = express.Router();
const participantController = require('../controllers/participantController');

router.post('/bills/:billId/participants', participantController.addParticipant);
router.get('/bills/:billId/participants', participantController.getParticipants);
router.post('/bills/:billId/payments', participantController.setPaymentsForBill);

module.exports = router; 