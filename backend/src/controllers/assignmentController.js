const AssignmentService = require('../services/assignmentService');

class AssignmentController {
  // Create assignment
  static async createAssignment(req, res) {
    try {
      const { expenseId } = req.params;
      const assignmentData = {
        ...req.body,
        expense_id: parseInt(expenseId)
      };

      const result = await AssignmentService.createAssignment(assignmentData, req.user.id);

      res.status(201).json({
        success: true,
        message: result.message,
        data: result.assignment
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get assignments for an expense
  static async getExpenseAssignments(req, res) {
    try {
      const { expenseId } = req.params;
      const result = await AssignmentService.getExpenseAssignments(parseInt(expenseId), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.assignments
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get specific assignment
  static async getAssignment(req, res) {
    try {
      const { assignmentId } = req.params;
      const result = await AssignmentService.getAssignment(parseInt(assignmentId), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.assignment
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Update assignment
  static async updateAssignment(req, res) {
    try {
      const { assignmentId } = req.params;
      const updateData = req.body;

      const result = await AssignmentService.updateAssignment(parseInt(assignmentId), updateData, req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.assignment
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Delete assignment
  static async deleteAssignment(req, res) {
    try {
      const { assignmentId } = req.params;
      const result = await AssignmentService.deleteAssignment(parseInt(assignmentId), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Add users to assignment
  static async addUsersToAssignment(req, res) {
    try {
      const { assignmentId } = req.params;
      const { user_ids } = req.body;

      if (!user_ids || !Array.isArray(user_ids) || user_ids.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'User IDs array is required and cannot be empty'
        });
      }

      const result = await AssignmentService.addUsersToAssignment(parseInt(assignmentId), user_ids, req.user.id);

      res.status(200).json({
        success: true,
        message: result.message
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Remove user from assignment
  static async removeUserFromAssignment(req, res) {
    try {
      const { assignmentId, userId } = req.params;
      const result = await AssignmentService.removeUserFromAssignment(parseInt(assignmentId), parseInt(userId), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get assignment summary for an expense
  static async getAssignmentSummary(req, res) {
    try {
      const { expenseId } = req.params;
      const result = await AssignmentService.getAssignmentSummary(parseInt(expenseId), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.summary
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }
}

module.exports = AssignmentController; 