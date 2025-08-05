const Settlement = require('../models/Settlement');
const Expense = require('../models/Expense');
const Group = require('../models/Group');
const db = require('../../database/connection');
const { SettlementErrorFactory, SettlementErrorHandler } = require('../utils/settlementErrors');

class SettlementProcessorService {
  /**
   * Process a settlement by converting it to an expense record
   * @param {number} settlementId - The settlement ID to process
   * @param {number} userId - The user ID who is marking the settlement as settled
   * @returns {Promise<Object>} Object containing the created expense and updated settlement
   */
  static async processSettlement(settlementId, userId) {
    try {
      // Start transaction for atomic operation
      await db.query('BEGIN');

      // Get settlement with details
      const settlement = await Settlement.findByIdWithDetails(settlementId);
      SettlementErrorHandler.assert(
        settlement,
        SettlementErrorFactory.createNotFoundError,
        settlementId
      );

      // Verify settlement is active
      SettlementErrorHandler.assert(
        settlement.status === 'active',
        SettlementErrorFactory.createStateError,
        'Settlement is not active and cannot be processed',
        settlement.status,
        'active'
      );

      // Verify user has permission to settle (must be involved in the settlement or group admin)
      const isInvolved = await Settlement.isUserInvolvedInSettlement(settlementId, userId);
      const group = await Group.findById(settlement.group_id);
      const isAdmin = await group.isUserAdmin(userId);

      SettlementErrorHandler.assert(
        isInvolved || isAdmin,
        SettlementErrorFactory.createPermissionError,
        'You do not have permission to settle this debt'
      );

      // Create settlement expense
      const expense = await this.createSettlementExpense(settlement, userId);

      // Mark settlement as settled
      const settlementModel = await Settlement.findById(settlementId);
      await settlementModel.markAsSettled(userId, expense.id);

      // Recalculate settlements for the group to update remaining debts
      await Settlement.calculateOptimalSettlements(settlement.group_id);

      // Commit transaction
      await db.query('COMMIT');

      // Trigger settlement update notification
      const SettlementUpdateService = require('./SettlementUpdateService');
      SettlementUpdateService.handleSettlementProcessed(settlement);

      return {
        settlement: await Settlement.findByIdWithDetails(settlementId),
        expense: expense.toJSON(),
        message: 'Settlement processed successfully'
      };
    } catch (error) {
      await db.query('ROLLBACK');
      if (error.name && error.name.includes('Settlement')) {
        throw error; // Re-throw settlement-specific errors
      }
      throw SettlementErrorFactory.createProcessingError(
        `Failed to process settlement: ${error.message}`,
        settlementId
      );
    }
  }

  /**
   * Create an expense record from settlement data
   * @param {Object} settlementData - Settlement data with member details
   * @param {number} userId - User ID who is creating the expense
   * @returns {Promise<Object>} Created expense object
   */
  static async createSettlementExpense(settlementData, userId) {
    try {
      // Create expense with settlement details
      const expenseData = {
        title: `Settlement: ${settlementData.from_member.nickname} → ${settlementData.to_member.nickname}`,
        description: `Settlement payment of ${settlementData.amount} ${settlementData.currency} from ${settlementData.from_member.nickname} to ${settlementData.to_member.nickname}`,
        amount: settlementData.amount,
        currency: settlementData.currency || 'EUR',
        group_id: settlementData.group_id,
        created_by: userId,
        category: 'settlement',
        is_settlement: true
      };

      const expense = await Expense.create(expenseData);

      // Add payer (the debtor who is settling)
      await db.query(
        'INSERT INTO expense_payers (expense_id, group_member_id, amount_paid) VALUES ($1, $2, $3)',
        [expense.id, settlementData.from_group_member_id, settlementData.amount]
      );

      // Add split (only the creditor benefits from this settlement)
      await db.query(
        'INSERT INTO expense_splits (expense_id, group_member_id, amount_owed, split_type) VALUES ($1, $2, $3, $4)',
        [expense.id, settlementData.to_group_member_id, settlementData.amount, 'settlement']
      );

      return expense;
    } catch (error) {
      throw new Error(`Failed to create settlement expense: ${error.message}`);
    }
  }

  /**
   * Validate settlement before processing
   * @param {number} settlementId - Settlement ID to validate
   * @param {number} userId - User ID requesting the settlement
   * @returns {Promise<Object>} Validation result
   */
  static async validateSettlementForProcessing(settlementId, userId) {
    const errors = [];

    try {
      // Check if settlement exists
      const settlement = await Settlement.findByIdWithDetails(settlementId);
      if (!settlement) {
        errors.push('Settlement not found');
        return { isValid: false, errors, settlement: null };
      }

      // Check if settlement is active
      if (settlement.status !== 'active') {
        errors.push('Settlement is not active');
      }

      // Check if user has permission
      const isInvolved = await Settlement.isUserInvolvedInSettlement(settlementId, userId);
      const group = await Group.findById(settlement.group_id);
      const isAdmin = group ? await group.isUserAdmin(userId) : false;

      if (!isInvolved && !isAdmin) {
        errors.push('You do not have permission to settle this debt');
      }

      // Check if group exists and is active
      if (!group) {
        errors.push('Group not found');
      }

      // Check for reasonable amount
      if (settlement.amount <= 0) {
        errors.push('Settlement amount must be greater than zero');
      }

      return {
        isValid: errors.length === 0,
        errors,
        settlement,
        permissions: {
          isInvolved,
          isAdmin,
          canSettle: isInvolved || isAdmin
        }
      };
    } catch (error) {
      errors.push(`Validation error: ${error.message}`);
      return { isValid: false, errors, settlement: null };
    }
  }

  /**
   * Get settlement processing preview
   * @param {number} settlementId - Settlement ID to preview
   * @param {number} userId - User ID requesting the preview
   * @returns {Promise<Object>} Preview of what will happen when settlement is processed
   */
  static async getSettlementProcessingPreview(settlementId, userId) {
    try {
      const validation = await this.validateSettlementForProcessing(settlementId, userId);
      
      if (!validation.isValid) {
        return {
          canProcess: false,
          errors: validation.errors,
          preview: null
        };
      }

      const settlement = validation.settlement;

      const preview = {
        settlement: {
          id: settlement.id,
          amount: settlement.amount,
          currency: settlement.currency,
          from_member: settlement.from_member,
          to_member: settlement.to_member
        },
        expense_to_create: {
          title: `Settlement: ${settlement.from_member.nickname} → ${settlement.to_member.nickname}`,
          description: `Settlement payment of ${settlement.amount} ${settlement.currency} from ${settlement.from_member.nickname} to ${settlement.to_member.nickname}`,
          amount: settlement.amount,
          currency: settlement.currency,
          payer: settlement.from_member,
          beneficiary: settlement.to_member,
          category: 'settlement'
        },
        effects: {
          settlement_will_be_marked_settled: true,
          new_expense_will_be_created: true,
          group_settlements_will_be_recalculated: true
        }
      };

      return {
        canProcess: true,
        errors: [],
        preview,
        permissions: validation.permissions
      };
    } catch (error) {
      return {
        canProcess: false,
        errors: [`Failed to generate preview: ${error.message}`],
        preview: null
      };
    }
  }

  /**
   * Process multiple settlements in batch
   * @param {Array} settlementIds - Array of settlement IDs to process
   * @param {number} userId - User ID processing the settlements
   * @returns {Promise<Object>} Batch processing results
   */
  static async processMultipleSettlements(settlementIds, userId) {
    const results = {
      successful: [],
      failed: [],
      summary: {
        total: settlementIds.length,
        successful_count: 0,
        failed_count: 0,
        total_amount_settled: 0
      }
    };

    for (const settlementId of settlementIds) {
      try {
        const result = await this.processSettlement(settlementId, userId);
        results.successful.push({
          settlement_id: settlementId,
          expense_id: result.expense.id,
          amount: result.settlement.amount
        });
        results.summary.successful_count++;
        results.summary.total_amount_settled += result.settlement.amount;
      } catch (error) {
        results.failed.push({
          settlement_id: settlementId,
          error: error.message
        });
        results.summary.failed_count++;
      }
    }

    return results;
  }

  /**
   * Cleanup obsolete settlements after processing
   * @param {number} groupId - Group ID to clean up
   * @param {number} olderThanDays - Delete settlements older than this many days
   * @returns {Promise<number>} Number of settlements cleaned up
   */
  static async cleanupObsoleteSettlements(groupId, olderThanDays = 30) {
    try {
      const deletedCount = await Settlement.deleteObsoleteSettlements(groupId, olderThanDays);
      return deletedCount;
    } catch (error) {
      throw new Error(`Failed to cleanup obsolete settlements: ${error.message}`);
    }
  }

  /**
   * Get settlement processing statistics for a group
   * @param {number} groupId - Group ID to get statistics for
   * @returns {Promise<Object>} Processing statistics
   */
  static async getProcessingStatistics(groupId) {
    try {
      const query = `
        SELECT 
          status,
          COUNT(*) as count,
          SUM(amount) as total_amount,
          MIN(created_at) as earliest_settlement,
          MAX(created_at) as latest_settlement,
          COUNT(CASE WHEN settled_at IS NOT NULL THEN 1 END) as settled_count,
          COUNT(CASE WHEN created_expense_id IS NOT NULL THEN 1 END) as with_expense_count
        FROM settlements
        WHERE group_id = $1
        GROUP BY status
        ORDER BY status
      `;

      const result = await db.query(query, [groupId]);
      
      const statistics = {
        by_status: result.rows.map(row => ({
          status: row.status,
          count: parseInt(row.count),
          total_amount: parseFloat(row.total_amount) || 0,
          earliest_settlement: row.earliest_settlement,
          latest_settlement: row.latest_settlement,
          settled_count: parseInt(row.settled_count),
          with_expense_count: parseInt(row.with_expense_count)
        })),
        totals: {
          all_settlements: result.rows.reduce((sum, row) => sum + parseInt(row.count), 0),
          total_amount: result.rows.reduce((sum, row) => sum + (parseFloat(row.total_amount) || 0), 0),
          settled_settlements: result.rows.reduce((sum, row) => sum + parseInt(row.settled_count), 0),
          settlements_with_expenses: result.rows.reduce((sum, row) => sum + parseInt(row.with_expense_count), 0)
        }
      };

      return statistics;
    } catch (error) {
      throw new Error(`Failed to get processing statistics: ${error.message}`);
    }
  }
}

module.exports = SettlementProcessorService;