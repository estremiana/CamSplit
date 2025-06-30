const express = require('express');
const router = express.Router();
const assignmentController = require('../controllers/assignmentController');

// Example endpoints
router.post('/', assignmentController.assignItem);
router.get('/bill/:billId', assignmentController.getAssignmentsForBill);

module.exports = router; 