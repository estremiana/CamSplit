const Assignment = require('../models/Assignment');
const Item = require('../models/Item');
const Expense = require('../models/Expense');
const Group = require('../models/Group');
const User = require('../models/User');
const db = require('../../database/connection');

class AssignmentService {
  // Create assignment
  static async createAssignment(assignmentData, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(assignmentData.expense_id);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to create assignments');
      }

      // Verify item exists and belongs to the expense
      const item = await Item.findById(assignmentData.item_id);
      if (!item) {
        throw new Error('Item not found');
      }

      if (item.expense_id !== assignmentData.expense_id) {
        throw new Error('Item does not belong to the specified expense');
      }

      // Check if quantity is available
      const remainingQuantity = await item.getRemainingQuantity();
      if (assignmentData.quantity > remainingQuantity) {
        throw new Error(`Only ${remainingQuantity} units available for this item`);
      }

      // Verify all user_ids are valid group members
      if (assignmentData.user_ids && assignmentData.user_ids.length > 0) {
        const groupMembers = await group.getMembers();
        const validMemberIds = groupMembers.map(member => member.id);
        
        for (const userId of assignmentData.user_ids) {
          if (!validMemberIds.includes(userId)) {
            throw new Error(`Group member with ID ${userId} not found`);
          }
        }
      }

      // Create the assignment
      const assignment = await Assignment.create(assignmentData);

      return {
        assignment: assignment.toJSON(),
        message: 'Assignment created successfully'
      };
    } catch (error) {
      throw new Error(`Failed to create assignment: ${error.message}`);
    }
  }

  // Get assignments for an expense
  static async getExpenseAssignments(expenseId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view assignments');
      }

      // Get assignments with users
      const assignments = await Assignment.findByExpenseId(expenseId);

      return {
        assignments,
        message: 'Assignments retrieved successfully'
      };
    } catch (error) {
      throw new Error(`Failed to get expense assignments: ${error.message}`);
    }
  }

  // Get specific assignment
  static async getAssignment(assignmentId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get assignment with users
      const assignment = await Assignment.findByIdWithUsers(assignmentId);
      if (!assignment) {
        throw new Error('Assignment not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(assignment.expense_id);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view this assignment');
      }

      return {
        assignment,
        message: 'Assignment retrieved successfully'
      };
    } catch (error) {
      throw new Error(`Failed to get assignment: ${error.message}`);
    }
  }

  // Update assignment
  static async updateAssignment(assignmentId, updateData, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get assignment
      const assignment = await Assignment.findById(assignmentId);
      if (!assignment) {
        throw new Error('Assignment not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(assignment.expense_id);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to update assignments');
      }

      // Check quantity constraints if quantity is being updated
      if (updateData.quantity !== undefined) {
        const item = await Item.findById(assignment.item_id);
        if (!item) {
          throw new Error('Item not found');
        }

        // Calculate how much is already assigned to this assignment
        const currentAssignedQuantity = assignment.quantity;
        const otherAssignmentsQuantity = await this.getOtherAssignmentsQuantity(assignment.item_id, assignmentId);
        const availableQuantity = item.max_quantity - otherAssignmentsQuantity;

        if (updateData.quantity > availableQuantity) {
          throw new Error(`Only ${availableQuantity} units available for this item`);
        }
      }

      // Update the assignment
      const updatedAssignment = await assignment.update(updateData);

      return {
        assignment: updatedAssignment.toJSON(),
        message: 'Assignment updated successfully'
      };
    } catch (error) {
      throw new Error(`Failed to update assignment: ${error.message}`);
    }
  }

  // Delete assignment
  static async deleteAssignment(assignmentId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get assignment
      const assignment = await Assignment.findById(assignmentId);
      if (!assignment) {
        throw new Error('Assignment not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(assignment.expense_id);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to delete assignments');
      }

      // Delete the assignment
      await assignment.delete();

      return {
        message: 'Assignment deleted successfully'
      };
    } catch (error) {
      throw new Error(`Failed to delete assignment: ${error.message}`);
    }
  }

  // Add users to assignment
  static async addUsersToAssignment(assignmentId, userIds, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get assignment
      const assignment = await Assignment.findById(assignmentId);
      if (!assignment) {
        throw new Error('Assignment not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(assignment.expense_id);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to modify assignments');
      }

      // Verify all user_ids are valid group members
      const groupMembers = await group.getMembers();
      const validMemberIds = groupMembers.map(member => member.id);
      
      for (const memberId of userIds) {
        if (!validMemberIds.includes(memberId)) {
          throw new Error(`Group member with ID ${memberId} not found`);
        }
      }

      // Add users to assignment
      await assignment.addUsers(userIds);

      return {
        message: 'Users added to assignment successfully'
      };
    } catch (error) {
      throw new Error(`Failed to add users to assignment: ${error.message}`);
    }
  }

  // Remove user from assignment
  static async removeUserFromAssignment(assignmentId, memberId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get assignment
      const assignment = await Assignment.findById(assignmentId);
      if (!assignment) {
        throw new Error('Assignment not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(assignment.expense_id);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to modify assignments');
      }

      // Remove user from assignment
      const removed = await assignment.removeUser(memberId);

      if (!removed) {
        throw new Error('User is not assigned to this assignment');
      }

      return {
        message: 'User removed from assignment successfully'
      };
    } catch (error) {
      throw new Error(`Failed to remove user from assignment: ${error.message}`);
    }
  }

  // Get assignment summary for an expense
  static async getAssignmentSummary(expenseId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify expense exists and user has access
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Check if user is member of the expense's group
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view assignment summary');
      }

      // Get assignments with users
      const assignments = await Assignment.findByExpenseId(expenseId);

      // Calculate summary
      const summary = {
        total_assignments: assignments.length,
        total_assigned_quantity: 0,
        total_assigned_value: 0,
        assignments_by_member: {},
        assignments_by_item: {}
      };

      for (const assignment of assignments) {
        summary.total_assigned_quantity += assignment.quantity;
        summary.total_assigned_value += assignment.total_price;

        // Group by member
        for (const user of assignment.assigned_users) {
          if (!summary.assignments_by_member[user.group_member_id]) {
            summary.assignments_by_member[user.group_member_id] = {
              nickname: user.nickname,
              assignments: [],
              total_quantity: 0,
              total_value: 0
            };
          }
          summary.assignments_by_member[user.group_member_id].assignments.push(assignment);
          summary.assignments_by_member[user.group_member_id].total_quantity += assignment.quantity;
          summary.assignments_by_member[user.group_member_id].total_value += assignment.total_price;
        }

        // Group by item
        if (!summary.assignments_by_item[assignment.item_id]) {
          summary.assignments_by_item[assignment.item_id] = {
            assignments: [],
            total_quantity: 0,
            total_value: 0
          };
        }
        summary.assignments_by_item[assignment.item_id].assignments.push(assignment);
        summary.assignments_by_item[assignment.item_id].total_quantity += assignment.quantity;
        summary.assignments_by_item[assignment.item_id].total_value += assignment.total_price;
      }

      return {
        summary,
        message: 'Assignment summary retrieved successfully'
      };
    } catch (error) {
      throw new Error(`Failed to get assignment summary: ${error.message}`);
    }
  }

  // Helper method to get quantity assigned by other assignments for an item
  static async getOtherAssignmentsQuantity(itemId, excludeAssignmentId) {
    try {
      const query = `
        SELECT COALESCE(SUM(quantity), 0) as total_quantity
        FROM assignments
        WHERE item_id = $1 AND id != $2
      `;
      
      const result = await db.query(query, [itemId, excludeAssignmentId]);
      return parseFloat(result.rows[0].total_quantity);
    } catch (error) {
      throw new Error(`Failed to get other assignments quantity: ${error.message}`);
    }
  }
}

module.exports = AssignmentService; 