const express = require('express');
const AssignmentController = require('../controllers/assignmentController');
const { authenticateToken, requireGroupMember } = require('../middleware/auth');

const router = express.Router();

// All assignment routes require authentication
router.use(authenticateToken);

// Assignment CRUD operations (requires group membership)
router.get('/expense/:expenseId', requireGroupMember, AssignmentController.getExpenseAssignments);
router.post('/expense/:expenseId', requireGroupMember, AssignmentController.createAssignment);
router.get('/:assignmentId', requireGroupMember, AssignmentController.getAssignment);
router.put('/:assignmentId', requireGroupMember, AssignmentController.updateAssignment);
router.delete('/:assignmentId', requireGroupMember, AssignmentController.deleteAssignment);

// Assignment user management
router.post('/:assignmentId/users', requireGroupMember, AssignmentController.addUsersToAssignment);
router.delete('/:assignmentId/users/:userId', requireGroupMember, AssignmentController.removeUserFromAssignment);

// Assignment summary
router.get('/expense/:expenseId/summary', requireGroupMember, AssignmentController.getAssignmentSummary);

module.exports = router; 