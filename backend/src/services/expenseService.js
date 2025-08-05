const Expense = require('../models/Expense');
const Group = require('../models/Group');
const User = require('../models/User');
const Item = require('../models/Item');
const Assignment = require('../models/Assignment');
const db = require('../../database/connection');

class ExpenseService {
  // Create expense with items and assignments
  static async createExpenseWithItems(expenseData, userId) {
    const client = await db.pool.connect();
    
    try {
      await client.query('BEGIN');

      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(expenseData.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to create expenses');
      }

      // Extract items and assignments from expense data
      const { items, ...expenseOnlyData } = expenseData;
      
      // Add created_by to expense data
      expenseOnlyData.created_by = userId;

      // Create expense with payers and splits
      const expense = await Expense.create(expenseOnlyData, expenseData.payers || [], expenseData.splits || []);

      // Create items and assignments if provided
      const createdItems = [];
      const createdAssignments = [];

      if (items && Array.isArray(items)) {
        for (const itemData of items) {
          // Create item
          const item = await Item.create({
            ...itemData,
            expense_id: expense.id
          });

          createdItems.push(item.toJSON());

          // Create assignments if provided
          if (itemData.assignments && Array.isArray(itemData.assignments)) {
            for (const assignmentData of itemData.assignments) {
              const assignment = await Assignment.create({
                ...assignmentData,
                expense_id: expense.id,
                item_id: item.id,
                unit_price: itemData.unit_price // Use the item's unit price
              });

              createdAssignments.push(assignment.toJSON());
            }
          }
        }
      }

      // Link receipt image to expense if provided
      if (expenseData.receipt_image_id) {
        const OCRService = require('./ocrService');
        await OCRService.linkReceiptImageToExpense(expenseData.receipt_image_id, expense.id);
      }

      await client.query('COMMIT');

      return {
        expense: expense.toJSON(),
        items: createdItems,
        assignments: createdAssignments,
        message: 'Expense created successfully with items and assignments'
      };

    } catch (error) {
      await client.query('ROLLBACK');
      throw new Error(`Failed to create expense with items: ${error.message}`);
    } finally {
      client.release();
    }
  }

  // Create expense (existing method - keep for backward compatibility)
  static async createExpense(expenseData, payers, splits, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(expenseData.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to create expenses');
      }

      // Add created_by to expense data
      expenseData.created_by = userId;

      // Create expense with payers and splits
      const expense = await Expense.create(expenseData, payers, splits);

      // Link receipt image to expense if provided
      if (expenseData.receipt_image_id) {
        const OCRService = require('./ocrService');
        await OCRService.linkReceiptImageToExpense(expenseData.receipt_image_id, expense.id);
      }

      return {
        expense: expense.toJSON(),
        message: 'Expense created successfully'
      };
    } catch (error) {
      throw new Error(`Failed to create expense: ${error.message}`);
    }
  }

  // Get expense (basic with smart detection)
  static async getExpense(expenseId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get expense
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view this expense');
      }

      // Check if expense has items
      const items = await Item.findByExpenseId(expenseId);
      const hasItems = items.length > 0;

      // If expense has items, include them with assignments
      let itemsWithAssignments = [];
      if (hasItems) {
        itemsWithAssignments = await Item.findByExpenseIdWithAssignments(expenseId);
      }

      // Get payers for the expense
      const payers = await expense.getPayers();
      
      // Process payers to include email information
      const processedPayers = await Promise.all(payers.map(async (payer) => {
        let email = null;
        if (payer.user_id) {
          try {
            const user = await User.findById(payer.user_id);
            email = user?.email;
          } catch (error) {
            console.warn(`Failed to fetch email for user ${payer.user_id}:`, error.message);
          }
        }
        
        return {
          id: payer.group_member_id,
          name: payer.user_name || payer.nickname,
          email: email
        };
      }));
      
      const response = {
        expense: {
          ...expense.toJSON(),
          payers: processedPayers
        },
        message: 'Expense retrieved successfully'
      };

      // Only include items if they exist
      if (hasItems) {
        response.items = itemsWithAssignments;
        response.message = 'Expense with items retrieved successfully';
      }

      return response;
    } catch (error) {
      throw new Error(`Failed to get expense: ${error.message}`);
    }
  }

  // Get expense with full details
  static async getExpenseWithDetails(expenseId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get expense with details
      const expenseDetails = await Expense.findByIdWithDetails(expenseId);
      if (!expenseDetails) {
        throw new Error('Expense not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(expenseDetails.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view this expense');
      }

      // Process payers to include email information (payers are already included in expenseDetails)
      const processedPayers = await Promise.all((expenseDetails.payers || []).map(async (payer) => {
        let email = null;
        if (payer.user_id) {
          try {
            const user = await User.findById(payer.user_id);
            email = user?.email;
          } catch (error) {
            console.warn(`Failed to fetch email for user ${payer.user_id}:`, error.message);
          }
        }
        
        return {
          id: payer.group_member_id,
          name: payer.user_name || payer.nickname,
          email: email
        };
      }));

      // Get items with assignments
      const items = await Item.findByExpenseIdWithAssignments(expenseId);

      return {
        expense: {
          ...expenseDetails,
          payers: processedPayers
        },
        items: items,
        message: 'Expense with details retrieved successfully'
      };
    } catch (error) {
      throw new Error(`Failed to get expense with details: ${error.message}`);
    }
  }

  // Get expenses for a group
  static async getGroupExpenses(groupId, userId, limit = 10, offset = 0) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view expenses');
      }

      // Get expenses for group
      const expenses = await Expense.getExpensesForGroup(groupId, limit, offset);

      // Process expenses to include payer information
      const expensesWithPayers = await Promise.all(expenses.map(async (expense) => {
        const payers = await expense.getPayers();
        
        // Process payers to include email information
        const processedPayers = await Promise.all(payers.map(async (payer) => {
          let email = null;
          if (payer.user_id) {
            try {
              const user = await User.findById(payer.user_id);
              email = user?.email;
            } catch (error) {
              console.warn(`Failed to fetch email for user ${payer.user_id}:`, error.message);
            }
          }
          
          return {
            id: payer.group_member_id,
            name: payer.user_name || payer.nickname,
            email: email
          };
        }));

        return {
          ...expense.toJSON(),
          payers: processedPayers
        };
      }));

      return {
        expenses: expensesWithPayers,
        message: 'Group expenses retrieved successfully'
      };
    } catch (error) {
      throw new Error(`Failed to get group expenses: ${error.message}`);
    }
  }

  // Get expenses for a user
  static async getUserExpenses(userId, limit = 10, offset = 0) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get expenses for user
      const expenses = await Expense.getExpensesForUser(userId, limit, offset);

      // Process expenses to include payer information
      const expensesWithPayers = await Promise.all(expenses.map(async (expense) => {
        const payers = await expense.getPayers();
        
        // Process payers to include email information
        const processedPayers = await Promise.all(payers.map(async (payer) => {
          let email = null;
          if (payer.user_id) {
            try {
              const user = await User.findById(payer.user_id);
              email = user?.email;
            } catch (error) {
              console.warn(`Failed to fetch email for user ${payer.user_id}:`, error.message);
            }
          }
          
          return {
            id: payer.group_member_id,
            name: payer.user_name || payer.nickname,
            email: email
          };
        }));

        return {
          ...expense.toJSON(),
          payers: processedPayers
        };
      }));

      return {
        expenses: expensesWithPayers,
        message: 'User expenses retrieved successfully'
      };
    } catch (error) {
      throw new Error(`Failed to get user expenses: ${error.message}`);
    }
  }

  // Update expense
  static async updateExpense(expenseId, updateData, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get expense
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to update this expense');
      }

      // Update expense
      const updatedExpense = await expense.update(updateData);

      // Get payers for the updated expense
      const payers = await updatedExpense.getPayers();
      
      // Process payers to include email information
      const processedPayers = await Promise.all(payers.map(async (payer) => {
        let email = null;
        if (payer.user_id) {
          try {
            const user = await User.findById(payer.user_id);
            email = user?.email;
          } catch (error) {
            console.warn(`Failed to fetch email for user ${payer.user_id}:`, error.message);
          }
        }
        
        return {
          id: payer.group_member_id,
          name: payer.user_name || payer.nickname,
          email: email
        };
      }));

      return {
        expense: {
          ...updatedExpense.toJSON(),
          payers: processedPayers
        },
        message: 'Expense updated successfully'
      };
    } catch (error) {
      throw new Error(`Failed to update expense: ${error.message}`);
    }
  }

  // Delete expense
  static async deleteExpense(expenseId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get expense
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to delete this expense');
      }

      // Delete expense
      await expense.delete();

      return {
        message: 'Expense deleted successfully'
      };
    } catch (error) {
      throw new Error(`Failed to delete expense: ${error.message}`);
    }
  }

  // Add payer to expense
  static async addPayer(expenseId, payerData, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get expense
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to modify this expense');
      }

      // Add payer
      const payer = await expense.addPayer(payerData);

      return {
        payer: payer,
        message: 'Payer added successfully'
      };
    } catch (error) {
      throw new Error(`Failed to add payer: ${error.message}`);
    }
  }

  // Remove payer from expense
  static async removePayer(expenseId, payerId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get expense
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to modify this expense');
      }

      // Remove payer
      await expense.removePayer(payerId);

      return {
        message: 'Payer removed successfully'
      };
    } catch (error) {
      throw new Error(`Failed to remove payer: ${error.message}`);
    }
  }

  // Add split to expense
  static async addSplit(expenseId, splitData, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get expense
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to modify this expense');
      }

      // Add split
      const split = await expense.addSplit(splitData);

      return {
        split: split,
        message: 'Split added successfully'
      };
    } catch (error) {
      throw new Error(`Failed to add split: ${error.message}`);
    }
  }

  // Remove split from expense
  static async removeSplit(expenseId, splitId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get expense
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to modify this expense');
      }

      // Remove split
      await expense.removeSplit(splitId);

      return {
        message: 'Split removed successfully'
      };
    } catch (error) {
      throw new Error(`Failed to remove split: ${error.message}`);
    }
  }

  // Get expense settlement
  static async getExpenseSettlement(expenseId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Get expense
      const expense = await Expense.findById(expenseId);
      if (!expense) {
        throw new Error('Expense not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(expense.group_id);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view this expense');
      }

      // Get settlement
      const settlement = await expense.getSettlement();

      return {
        settlement: settlement,
        message: 'Expense settlement retrieved successfully'
      };
    } catch (error) {
      throw new Error(`Failed to get expense settlement: ${error.message}`);
    }
  }

  // Search expenses
  static async searchExpenses(searchTerm, userId, limit = 10) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Search expenses
      const expenses = await Expense.searchExpenses(searchTerm, userId, limit);

      return {
        expenses: expenses.map(expense => expense.toJSON()),
        message: `Found ${expenses.length} expenses matching "${searchTerm}"`
      };
    } catch (error) {
      throw new Error(`Failed to search expenses: ${error.message}`);
    }
  }

  // Get expense statistics for a group
  static async getGroupExpenseStats(groupId, userId) {
    try {
      // Verify user exists
      const user = await User.findById(userId);
      if (!user) {
        throw new Error('User not found');
      }

      // Verify group exists and user is member
      const group = await Group.findById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const isMember = await group.isUserMember(userId);
      if (!isMember) {
        throw new Error('You must be a member of the group to view expense statistics');
      }

      // Get expense statistics
      const stats = await Expense.getGroupExpenseStats(groupId);

      return {
        stats: stats,
        message: 'Group expense statistics retrieved successfully'
      };
    } catch (error) {
      throw new Error(`Failed to get group expense stats: ${error.message}`);
    }
  }
}

module.exports = ExpenseService; 