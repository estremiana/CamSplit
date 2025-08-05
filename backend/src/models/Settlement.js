const db = require('../../database/connection');
const { SettlementErrorFactory, SettlementErrorHandler } = require('../utils/settlementErrors');

class Settlement {
  constructor(data) {
    this.id = data.id;
    this.group_id = data.group_id;
    this.from_group_member_id = data.from_group_member_id;
    this.to_group_member_id = data.to_group_member_id;
    this.amount = data.amount;
    this.currency = data.currency;
    this.status = data.status;
    this.calculation_timestamp = data.calculation_timestamp;
    this.settled_at = data.settled_at;
    this.settled_by = data.settled_by;
    this.created_expense_id = data.created_expense_id;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Create a new settlement
  static async create(settlementData) {
    const { 
      group_id, from_group_member_id, to_group_member_id, amount, 
      currency, status, calculation_timestamp 
    } = settlementData;

    // Validate input
    const validation = Settlement.validate(settlementData);
    SettlementErrorHandler.validateOrThrow(validation, 'settlement creation');

    try {
      const query = `
        INSERT INTO settlements (
          group_id, from_group_member_id, to_group_member_id, amount, 
          currency, status, calculation_timestamp, created_at, updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
        RETURNING *
      `;
      
      const values = [
        group_id,
        from_group_member_id,
        to_group_member_id,
        amount,
        currency || 'EUR',
        status || 'active',
        calculation_timestamp || new Date()
      ];
      
      const result = await db.query(query, values);
      return new Settlement(result.rows[0]);
    } catch (error) {
      if (error.name && error.name.includes('Settlement')) {
        throw error;
      }
      throw SettlementErrorFactory.fromDatabaseError(error, {
        operation: 'create settlement'
      });
    }
  }

  // Find settlement by ID
  static async findById(id) {
    try {
      const query = 'SELECT * FROM settlements WHERE id = $1';
      const result = await db.query(query, [id]);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      return new Settlement(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to find settlement: ${error.message}`);
    }
  }

  // Get settlement with member details
  static async findByIdWithDetails(id) {
    try {
      const query = `
        SELECT 
          s.*,
          from_member.nickname as from_nickname,
          from_member.user_id as from_user_id,
          from_user.first_name as from_first_name,
          from_user.last_name as from_last_name,
          from_user.avatar as from_user_avatar,
          to_member.nickname as to_nickname,
          to_member.user_id as to_user_id,
          to_user.first_name as to_first_name,
          to_user.last_name as to_last_name,
          to_user.avatar as to_user_avatar
        FROM settlements s
        JOIN group_members from_member ON s.from_group_member_id = from_member.id
        JOIN group_members to_member ON s.to_group_member_id = to_member.id
        LEFT JOIN users from_user ON from_member.user_id = from_user.id
        LEFT JOIN users to_user ON to_member.user_id = to_user.id
        WHERE s.id = $1
      `;
      
      const result = await db.query(query, [id]);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      const row = result.rows[0];
      return {
        ...new Settlement(row).toJSON(),
        from_member: {
          id: row.from_group_member_id,
          nickname: row.from_nickname,
          user_id: row.from_user_id,
          user_name: row.from_first_name && row.from_last_name 
            ? `${row.from_first_name} ${row.from_last_name}`.trim() 
            : null,
          user_avatar: row.from_user_avatar
        },
        to_member: {
          id: row.to_group_member_id,
          nickname: row.to_nickname,
          user_id: row.to_user_id,
          user_name: row.to_first_name && row.to_last_name 
            ? `${row.to_first_name} ${row.to_last_name}`.trim() 
            : null,
          user_avatar: row.to_user_avatar
        }
      };
    } catch (error) {
      throw new Error(`Failed to find settlement with details: ${error.message}`);
    }
  }

  // Get settlements for a group
  static async getSettlementsForGroup(groupId, status = 'active') {
    try {
      const query = `
        SELECT 
          s.*,
          from_member.nickname as from_nickname,
          from_member.user_id as from_user_id,
          from_user.first_name as from_first_name,
          from_user.last_name as from_last_name,
          from_user.avatar as from_user_avatar,
          to_member.nickname as to_nickname,
          to_member.user_id as to_user_id,
          to_user.first_name as to_first_name,
          to_user.last_name as to_last_name,
          to_user.avatar as to_user_avatar
        FROM settlements s
        JOIN group_members from_member ON s.from_group_member_id = from_member.id
        JOIN group_members to_member ON s.to_group_member_id = to_member.id
        LEFT JOIN users from_user ON from_member.user_id = from_user.id
        LEFT JOIN users to_user ON to_member.user_id = to_user.id
        WHERE s.group_id = $1 AND s.status = $2
        ORDER BY s.amount DESC, s.created_at ASC
      `;
      
      const result = await db.query(query, [groupId, status]);
      
      return result.rows.map(row => ({
        ...new Settlement(row).toJSON(),
        from_member: {
          id: row.from_group_member_id,
          nickname: row.from_nickname,
          user_id: row.from_user_id,
          user_name: row.from_first_name && row.from_last_name 
            ? `${row.from_first_name} ${row.from_last_name}`.trim() 
            : null,
          user_avatar: row.from_user_avatar
        },
        to_member: {
          id: row.to_group_member_id,
          nickname: row.to_nickname,
          user_id: row.to_user_id,
          user_name: row.to_first_name && row.to_last_name 
            ? `${row.to_first_name} ${row.to_last_name}`.trim() 
            : null,
          user_avatar: row.to_user_avatar
        }
      }));
    } catch (error) {
      throw new Error(`Failed to get settlements for group: ${error.message}`);
    }
  }

  // Get settlement history for a group
  static async getSettlementHistory(groupId, limit = 50, offset = 0) {
    try {
      const query = `
        SELECT 
          s.*,
          from_member.nickname as from_nickname,
          to_member.nickname as to_nickname,
          settled_user.first_name as settled_by_first_name,
          settled_user.last_name as settled_by_last_name,
          e.title as expense_title
        FROM settlements s
        JOIN group_members from_member ON s.from_group_member_id = from_member.id
        JOIN group_members to_member ON s.to_group_member_id = to_member.id
        LEFT JOIN users settled_user ON s.settled_by = settled_user.id
        LEFT JOIN expenses e ON s.created_expense_id = e.id
        WHERE s.group_id = $1 AND s.status = 'settled'
        ORDER BY s.settled_at DESC
        LIMIT $2 OFFSET $3
      `;
      
      const result = await db.query(query, [groupId, limit, offset]);
      return result.rows.map(row => new Settlement(row));
    } catch (error) {
      throw new Error(`Failed to get settlement history: ${error.message}`);
    }
  }

  // Update settlement status
  async updateStatus(status, userId = null) {
    if (!Settlement.isValidStatus(status)) {
      throw new Error('Invalid settlement status');
    }

    try {
      const query = `
        UPDATE settlements 
        SET status = $1, 
            settled_at = CASE WHEN $1 = 'settled' THEN NOW() ELSE settled_at END,
            settled_by = CASE WHEN $1 = 'settled' THEN $2 ELSE settled_by END,
            updated_at = NOW()
        WHERE id = $3
        RETURNING *
      `;
      
      const result = await db.query(query, [status, userId, this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Settlement not found');
      }
      
      // Update current instance
      Object.assign(this, result.rows[0]);
      return this;
    } catch (error) {
      throw new Error(`Failed to update settlement status: ${error.message}`);
    }
  }

  // Mark settlement as settled
  async markAsSettled(userId, createdExpenseId = null) {
    try {
      const query = `
        UPDATE settlements 
        SET status = 'settled',
            settled_at = NOW(),
            settled_by = $1,
            created_expense_id = $2,
            updated_at = NOW()
        WHERE id = $3
        RETURNING *
      `;
      
      const result = await db.query(query, [userId, createdExpenseId, this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Settlement not found');
      }
      
      // Update current instance
      Object.assign(this, result.rows[0]);
      return this;
    } catch (error) {
      throw new Error(`Failed to mark settlement as settled: ${error.message}`);
    }
  }

  // Update settlement details
  async update(updateData) {
    const { amount, currency, status } = updateData;
    
    // Validate input
    const validation = Settlement.validate(updateData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      const query = `
        UPDATE settlements 
        SET amount = COALESCE($1, amount),
            currency = COALESCE($2, currency),
            status = COALESCE($3, status),
            updated_at = NOW()
        WHERE id = $4
        RETURNING *
      `;
      
      const values = [amount, currency, status, this.id];
      const result = await db.query(query, values);
      
      if (result.rows.length === 0) {
        throw new Error('Settlement not found');
      }
      
      // Update current instance
      Object.assign(this, result.rows[0]);
      return this;
    } catch (error) {
      throw new Error(`Failed to update settlement: ${error.message}`);
    }
  }

  // Delete settlement
  async delete() {
    try {
      const query = 'DELETE FROM settlements WHERE id = $1 RETURNING *';
      const result = await db.query(query, [this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Settlement not found');
      }
      
      return true;
    } catch (error) {
      throw new Error(`Failed to delete settlement: ${error.message}`);
    }
  }

  // Mark obsolete settlements for a group
  static async markObsoleteSettlements(groupId, excludeIds = []) {
    try {
      let query = `
        UPDATE settlements 
        SET status = 'obsolete', updated_at = NOW()
        WHERE group_id = $1 AND status = 'active'
      `;
      
      const values = [groupId];
      
      if (excludeIds.length > 0) {
        const placeholders = excludeIds.map((_, index) => `$${index + 2}`).join(', ');
        query += ` AND id NOT IN (${placeholders})`;
        values.push(...excludeIds);
      }
      
      query += ' RETURNING *';
      
      const result = await db.query(query, values);
      return result.rows.map(row => new Settlement(row));
    } catch (error) {
      throw new Error(`Failed to mark obsolete settlements: ${error.message}`);
    }
  }

  // Delete obsolete settlements for a group (cleanup)
  static async deleteObsoleteSettlements(groupId, olderThanDays = 7) {
    try {
      const query = `
        DELETE FROM settlements 
        WHERE group_id = $1 
          AND status = 'obsolete' 
          AND updated_at < NOW() - INTERVAL '${olderThanDays} days'
        RETURNING *
      `;
      
      const result = await db.query(query, [groupId]);
      return result.rows.length;
    } catch (error) {
      throw new Error(`Failed to delete obsolete settlements: ${error.message}`);
    }
  }

  // Get settlement summary for a group
  static async getSettlementSummaryForGroup(groupId) {
    try {
      const query = `
        SELECT 
          status,
          COUNT(*) as count,
          SUM(amount) as total_amount
        FROM settlements
        WHERE group_id = $1
        GROUP BY status
        ORDER BY status
      `;
      
      const result = await db.query(query, [groupId]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get settlement summary: ${error.message}`);
    }
  }

  // Check if user is involved in a settlement
  static async isUserInvolvedInSettlement(settlementId, userId) {
    try {
      const query = `
        SELECT id FROM settlements s
        JOIN group_members gm1 ON s.from_group_member_id = gm1.id
        JOIN group_members gm2 ON s.to_group_member_id = gm2.id
        WHERE s.id = $1 AND (gm1.user_id = $2 OR gm2.user_id = $2)
      `;
      
      const result = await db.query(query, [settlementId, userId]);
      return result.rows.length > 0;
    } catch (error) {
      throw new Error(`Failed to check user involvement: ${error.message}`);
    }
  }

  // Calculate and store optimal settlements for a group
  static async calculateOptimalSettlements(groupId) {
    const SettlementCalculatorService = require('../services/SettlementCalculatorService');
    
    try {
      // Start transaction for atomic operation
      await db.query('BEGIN');

      // Calculate optimal settlements
      const calculationResult = await SettlementCalculatorService.calculateOptimalSettlements(groupId);
      const { settlements, balances, validation, summary } = calculationResult;

      if (!validation.isValid) {
        await db.query('ROLLBACK');
        throw new Error(`Settlement calculation validation failed: ${validation.errors.join(', ')}`);
      }

      // Mark existing active settlements as obsolete
      await Settlement.markObsoleteSettlements(groupId);

      // Create new settlements
      const createdSettlements = [];
      const calculationTimestamp = new Date();

      for (const settlementData of settlements) {
        const settlement = await Settlement.create({
          group_id: groupId,
          from_group_member_id: settlementData.from_group_member_id,
          to_group_member_id: settlementData.to_group_member_id,
          amount: settlementData.amount,
          currency: 'EUR', // Default currency
          status: 'active',
          calculation_timestamp: calculationTimestamp
        });

        // Add member details to the settlement
        const settlementWithDetails = {
          ...settlement.toJSON(),
          from_member: settlementData.from_member,
          to_member: settlementData.to_member
        };

        createdSettlements.push(settlementWithDetails);
      }

      // Commit transaction
      await db.query('COMMIT');

      return {
        settlements: createdSettlements,
        balances,
        summary: {
          ...summary,
          calculation_timestamp: calculationTimestamp,
          obsolete_settlements_count: 0 // Could track this if needed
        }
      };
    } catch (error) {
      await db.query('ROLLBACK');
      throw new Error(`Failed to calculate optimal settlements: ${error.message}`);
    }
  }

  // Recalculate settlements and clean up obsolete ones
  static async recalculateSettlements(groupId, options = {}) {
    const { preserveSettledSettlements = true, cleanupObsoleteAfterDays = 1 } = options;

    try {
      // Calculate new optimal settlements
      const result = await Settlement.calculateOptimalSettlements(groupId);

      // Clean up old obsolete settlements if requested
      if (cleanupObsoleteAfterDays > 0) {
        const deletedCount = await Settlement.deleteObsoleteSettlements(groupId, cleanupObsoleteAfterDays);
        result.summary.cleaned_up_settlements = deletedCount;
      }

      return result;
    } catch (error) {
      throw new Error(`Failed to recalculate settlements: ${error.message}`);
    }
  }

  // Get active settlements with calculation metadata
  static async getActiveSettlementsWithMetadata(groupId) {
    try {
      const settlements = await Settlement.getSettlementsForGroup(groupId, 'active');
      
      if (settlements.length === 0) {
        return {
          settlements: [],
          metadata: {
            calculation_timestamp: null,
            total_amount: 0,
            settlement_count: 0,
            members_involved: 0
          }
        };
      }

      // Get calculation metadata from the first settlement
      const calculationTimestamp = settlements[0].calculation_timestamp;
      const totalAmount = settlements.reduce((sum, s) => sum + s.amount, 0);
      const membersInvolved = new Set([
        ...settlements.map(s => s.from_group_member_id),
        ...settlements.map(s => s.to_group_member_id)
      ]).size;

      return {
        settlements,
        metadata: {
          calculation_timestamp: calculationTimestamp,
          total_amount: Math.round(totalAmount * 100) / 100,
          settlement_count: settlements.length,
          members_involved: membersInvolved
        }
      };
    } catch (error) {
      throw new Error(`Failed to get active settlements with metadata: ${error.message}`);
    }
  }

  // Convert to JSON
  toJSON() {
    return {
      id: this.id,
      group_id: this.group_id,
      from_group_member_id: this.from_group_member_id,
      to_group_member_id: this.to_group_member_id,
      amount: parseFloat(this.amount),
      currency: this.currency,
      status: this.status,
      calculation_timestamp: this.calculation_timestamp,
      settled_at: this.settled_at,
      settled_by: this.settled_by,
      created_expense_id: this.created_expense_id,
      created_at: this.created_at,
      updated_at: this.updated_at
    };
  }

  // Static validation methods
  static validate(settlementData) {
    const errors = [];
    const { group_id, from_group_member_id, to_group_member_id, amount, currency, status } = settlementData;

    // Group ID validation
    if (!group_id) {
      errors.push('Group ID is required');
    }

    // From member validation
    if (!from_group_member_id) {
      errors.push('From member ID is required');
    }

    // To member validation
    if (!to_group_member_id) {
      errors.push('To member ID is required');
    }

    // Amount validation
    if (!amount || amount <= 0) {
      errors.push('Amount must be greater than 0');
    }

    // Currency validation
    if (currency && !Settlement.isValidCurrency(currency)) {
      errors.push('Invalid currency code (use 3-letter ISO code)');
    }

    // Status validation
    if (status && !Settlement.isValidStatus(status)) {
      errors.push('Invalid settlement status');
    }

    // Check if from and to members are different
    if (from_group_member_id === to_group_member_id) {
      errors.push('From and to members cannot be the same');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // Helper validation methods
  static isValidStatus(status) {
    const validStatuses = ['active', 'settled', 'obsolete'];
    return validStatuses.includes(status);
  }

  static isValidCurrency(currency) {
    const currencyRegex = /^[A-Z]{3}$/;
    return currencyRegex.test(currency);
  }
}

module.exports = Settlement;