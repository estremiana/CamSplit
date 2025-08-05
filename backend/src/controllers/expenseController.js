const ExpenseService = require('../services/expenseService');
const SettlementUpdateService = require('../services/SettlementUpdateService');

class ExpenseController {
  // Create expense (with or without items)
  static async createExpense(req, res) {
    try {
      const expenseData = req.body;

      // Check if expense includes items
      if (expenseData.items && Array.isArray(expenseData.items)) {
        // Use the new method that handles items and assignments
        const result = await ExpenseService.createExpenseWithItems(expenseData, req.user.id);

        // Trigger settlement recalculation
        if (result.expense && result.expense.group_id) {
          SettlementUpdateService.handleExpenseCreated(result.expense);
        }

        res.status(201).json({
          success: true,
          message: result.message,
          data: {
            expense: result.expense,
            items: result.items,
            assignments: result.assignments
          }
        });
      } else {
        // Use the existing method for expenses without items
        const { payers, splits, ...expenseOnlyData } = expenseData;
        const result = await ExpenseService.createExpense(expenseOnlyData, payers, splits, req.user.id);

        // Trigger settlement recalculation
        if (result.expense && result.expense.group_id) {
          SettlementUpdateService.handleExpenseCreated(result.expense);
        }

        res.status(201).json({
          success: true,
          message: result.message,
          data: result.expense
        });
      }
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get expense by ID
  static async getExpense(req, res) {
    try {
      const { expenseId } = req.params;
      const result = await ExpenseService.getExpense(parseInt(expenseId), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.expense
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get expense with full details
  static async getExpenseWithDetails(req, res) {
    try {
      const { expenseId } = req.params;
      const result = await ExpenseService.getExpenseWithDetails(parseInt(expenseId), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get expenses for a group
  static async getGroupExpenses(req, res) {
    try {
      const { groupId } = req.params;
      const { limit = 10, offset = 0 } = req.query;
      const result = await ExpenseService.getGroupExpenses(parseInt(groupId), req.user.id, parseInt(limit), parseInt(offset));

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.expenses
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get expenses for a user
  static async getUserExpenses(req, res) {
    try {
      const { limit = 10, offset = 0 } = req.query;
      const result = await ExpenseService.getUserExpenses(req.user.id, parseInt(limit), parseInt(offset));

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.expenses
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Update expense
  static async updateExpense(req, res) {
    try {
      const { expenseId } = req.params;
      const updateData = req.body;

      const result = await ExpenseService.updateExpense(parseInt(expenseId), updateData, req.user.id);

      // Trigger settlement recalculation
      if (result.expense && result.expense.group_id) {
        SettlementUpdateService.handleExpenseUpdated(result.expense, updateData);
      }

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.expense
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Delete expense
  static async deleteExpense(req, res) {
    try {
      const { expenseId } = req.params;
      
      // Get expense before deletion for settlement recalculation
      const expenseResult = await ExpenseService.getExpense(parseInt(expenseId), req.user.id);
      const expense = expenseResult.expense;
      
      const result = await ExpenseService.deleteExpense(parseInt(expenseId), req.user.id);

      // Trigger settlement recalculation
      if (expense && expense.group_id) {
        SettlementUpdateService.handleExpenseDeleted(expense);
      }

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

  // Add payer to expense
  static async addPayer(req, res) {
    try {
      const { expenseId } = req.params;
      const payerData = req.body;

      const result = await ExpenseService.addPayer(parseInt(expenseId), payerData, req.user.id);

      // Trigger settlement recalculation
      if (result.payer && result.payer.expense_id) {
        const expenseResult = await ExpenseService.getExpense(parseInt(expenseId), req.user.id);
        if (expenseResult.expense && expenseResult.expense.group_id) {
          SettlementUpdateService.handlePayerChanges(parseInt(expenseId), expenseResult.expense.group_id, [result.payer]);
        }
      }

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.payer
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Remove payer from expense
  static async removePayer(req, res) {
    try {
      const { expenseId, payerId } = req.params;
      
      // Get expense for settlement recalculation
      const expenseResult = await ExpenseService.getExpense(parseInt(expenseId), req.user.id);
      
      const result = await ExpenseService.removePayer(parseInt(expenseId), parseInt(payerId), req.user.id);

      // Trigger settlement recalculation
      if (expenseResult.expense && expenseResult.expense.group_id) {
        SettlementUpdateService.handlePayerChanges(parseInt(expenseId), expenseResult.expense.group_id, [{ removed: true, payer_id: parseInt(payerId) }]);
      }

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

  // Add split to expense
  static async addSplit(req, res) {
    try {
      const { expenseId } = req.params;
      const splitData = req.body;

      const result = await ExpenseService.addSplit(parseInt(expenseId), splitData, req.user.id);

      // Trigger settlement recalculation
      if (result.split && result.split.expense_id) {
        const expenseResult = await ExpenseService.getExpense(parseInt(expenseId), req.user.id);
        if (expenseResult.expense && expenseResult.expense.group_id) {
          SettlementUpdateService.handleSplitChanges(parseInt(expenseId), expenseResult.expense.group_id, [result.split]);
        }
      }

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.split
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Remove split from expense
  static async removeSplit(req, res) {
    try {
      const { expenseId, splitId } = req.params;
      
      // Get expense for settlement recalculation
      const expenseResult = await ExpenseService.getExpense(parseInt(expenseId), req.user.id);
      
      const result = await ExpenseService.removeSplit(parseInt(expenseId), parseInt(splitId), req.user.id);

      // Trigger settlement recalculation
      if (expenseResult.expense && expenseResult.expense.group_id) {
        SettlementUpdateService.handleSplitChanges(parseInt(expenseId), expenseResult.expense.group_id, [{ removed: true, split_id: parseInt(splitId) }]);
      }

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

  // Get expense settlement
  static async getExpenseSettlement(req, res) {
    try {
      const { expenseId } = req.params;
      const result = await ExpenseService.getExpenseSettlement(parseInt(expenseId), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.settlement
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Search expenses
  static async searchExpenses(req, res) {
    try {
      const { q: searchTerm } = req.query;
      const { limit = 10 } = req.query;

      if (!searchTerm || searchTerm.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Search term is required'
        });
      }

      const result = await ExpenseService.searchExpenses(searchTerm.trim(), req.user.id, parseInt(limit));

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.expenses
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }

  // Get expense statistics for a group
  static async getGroupExpenseStats(req, res) {
    try {
      const { groupId } = req.params;
      const result = await ExpenseService.getGroupExpenseStats(parseInt(groupId), req.user.id);

      res.status(200).json({
        success: true,
        message: result.message,
        data: result.stats
      });
    } catch (error) {
      res.status(400).json({
        success: false,
        message: error.message
      });
    }
  }
}

module.exports = ExpenseController; 