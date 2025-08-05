const db = require('../../database/connection');

class Payment {
  constructor(data) {
    this.id = data.id;
    this.group_id = data.group_id;
    this.from_group_member_id = data.from_group_member_id;
    this.to_group_member_id = data.to_group_member_id;
    this.amount = data.amount;
    this.currency = data.currency;
    this.status = data.status;
    this.payment_method = data.payment_method;
    this.notes = data.notes;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Create a new payment
  static async create(paymentData) {
    const { 
      group_id, from_group_member_id, to_group_member_id, amount, 
      currency, payment_method, notes 
    } = paymentData;

    // Validate input
    const validation = Payment.validate(paymentData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      const query = `
        INSERT INTO payments (
          group_id, from_group_member_id, to_group_member_id, amount, 
          currency, status, payment_method, notes, created_at, updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
        RETURNING *
      `;
      
      const values = [
        group_id,
        from_group_member_id,
        to_group_member_id,
        amount,
        currency || 'EUR',
        'pending',
        payment_method,
        notes
      ];
      
      const result = await db.query(query, values);
      return new Payment(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to create payment: ${error.message}`);
    }
  }

  // Find payment by ID
  static async findById(id) {
    try {
      const query = 'SELECT * FROM payments WHERE id = $1';
      const result = await db.query(query, [id]);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      return new Payment(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to find payment: ${error.message}`);
    }
  }

  // Get payment with member details
  static async findByIdWithDetails(id) {
    try {
      const query = `
        SELECT 
          p.*,
          from_member.nickname as from_nickname,
          from_member.user_id as from_user_id,
          from_user.name as from_user_name,
          from_user.avatar as from_user_avatar,
          to_member.nickname as to_nickname,
          to_member.user_id as to_user_id,
          to_user.name as to_user_name,
          to_user.avatar as to_user_avatar
        FROM payments p
        JOIN group_members from_member ON p.from_group_member_id = from_member.id
        JOIN group_members to_member ON p.to_group_member_id = to_member.id
        LEFT JOIN users from_user ON from_member.user_id = from_user.id
        LEFT JOIN users to_user ON to_member.user_id = to_user.id
        WHERE p.id = $1
      `;
      
      const result = await db.query(query, [id]);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      return {
        ...new Payment(result.rows[0]).toJSON(),
        from_member: {
          id: result.rows[0].from_group_member_id,
          nickname: result.rows[0].from_nickname,
          user_id: result.rows[0].from_user_id,
          user_name: result.rows[0].from_user_name,
          user_avatar: result.rows[0].from_user_avatar
        },
        to_member: {
          id: result.rows[0].to_group_member_id,
          nickname: result.rows[0].to_nickname,
          user_id: result.rows[0].to_user_id,
          user_name: result.rows[0].to_user_name,
          user_avatar: result.rows[0].to_user_avatar
        }
      };
    } catch (error) {
      throw new Error(`Failed to find payment with details: ${error.message}`);
    }
  }

  // Get payments for a group
  static async getPaymentsForGroup(groupId, limit = 10, offset = 0) {
    try {
      const query = `
        SELECT 
          p.*,
          from_member.nickname as from_nickname,
          to_member.nickname as to_nickname
        FROM payments p
        JOIN group_members from_member ON p.from_group_member_id = from_member.id
        JOIN group_members to_member ON p.to_group_member_id = to_member.id
        WHERE p.group_id = $1
        ORDER BY p.created_at DESC
        LIMIT $2 OFFSET $3
      `;
      
      const result = await db.query(query, [groupId, limit, offset]);
      return result.rows.map(row => new Payment(row));
    } catch (error) {
      throw new Error(`Failed to get payments for group: ${error.message}`);
    }
  }

  // Get payments for a user (across all groups)
  static async getPaymentsForUser(userId, limit = 10, offset = 0) {
    try {
      const query = `
        SELECT 
          p.*,
          g.name as group_name,
          from_member.nickname as from_nickname,
          to_member.nickname as to_nickname
        FROM payments p
        JOIN groups g ON p.group_id = g.id
        JOIN group_members from_member ON p.from_group_member_id = from_member.id
        JOIN group_members to_member ON p.to_group_member_id = to_member.id
        WHERE from_member.user_id = $1 OR to_member.user_id = $1
        ORDER BY p.created_at DESC
        LIMIT $2 OFFSET $3
      `;
      
      const result = await db.query(query, [userId, limit, offset]);
      return result.rows.map(row => new Payment(row));
    } catch (error) {
      throw new Error(`Failed to get payments for user: ${error.message}`);
    }
  }

  // Get pending payments for a group
  static async getPendingPaymentsForGroup(groupId) {
    try {
      const query = `
        SELECT 
          p.*,
          from_member.nickname as from_nickname,
          to_member.nickname as to_nickname
        FROM payments p
        JOIN group_members from_member ON p.from_group_member_id = from_member.id
        JOIN group_members to_member ON p.to_group_member_id = to_member.id
        WHERE p.group_id = $1 AND p.status = 'pending'
        ORDER BY p.created_at ASC
      `;
      
      const result = await db.query(query, [groupId]);
      return result.rows.map(row => new Payment(row));
    } catch (error) {
      throw new Error(`Failed to get pending payments: ${error.message}`);
    }
  }

  // Update payment status
  async updateStatus(status) {
    if (!Payment.isValidStatus(status)) {
      throw new Error('Invalid payment status');
    }

    try {
      const query = `
        UPDATE payments 
        SET status = $1, updated_at = NOW()
        WHERE id = $2
        RETURNING *
      `;
      
      const result = await db.query(query, [status, this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Payment not found');
      }
      
      // Update current instance
      Object.assign(this, result.rows[0]);
      return this;
    } catch (error) {
      throw new Error(`Failed to update payment status: ${error.message}`);
    }
  }

  // Update payment details
  async update(updateData) {
    const { amount, currency, payment_method, notes } = updateData;
    
    // Validate input
    const validation = Payment.validate(updateData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      const query = `
        UPDATE payments 
        SET amount = COALESCE($1, amount),
            currency = COALESCE($2, currency),
            payment_method = COALESCE($3, payment_method),
            notes = COALESCE($4, notes),
            updated_at = NOW()
        WHERE id = $5
        RETURNING *
      `;
      
      const values = [amount, currency, payment_method, notes, this.id];
      const result = await db.query(query, values);
      
      if (result.rows.length === 0) {
        throw new Error('Payment not found');
      }
      
      // Update current instance
      Object.assign(this, result.rows[0]);
      return this;
    } catch (error) {
      throw new Error(`Failed to update payment: ${error.message}`);
    }
  }

  // Delete payment
  async delete() {
    try {
      const query = 'DELETE FROM payments WHERE id = $1 RETURNING *';
      const result = await db.query(query, [this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Payment not found');
      }
      
      return true;
    } catch (error) {
      throw new Error(`Failed to delete payment: ${error.message}`);
    }
  }

  // Mark payment as completed
  async markCompleted() {
    return this.updateStatus('completed');
  }

  // Mark payment as cancelled
  async markCancelled() {
    return this.updateStatus('cancelled');
  }

  // Get payment summary for a group
  static async getPaymentSummaryForGroup(groupId) {
    try {
      const query = `
        SELECT 
          status,
          COUNT(*) as count,
          SUM(amount) as total_amount
        FROM payments
        WHERE group_id = $1
        GROUP BY status
        ORDER BY status
      `;
      
      const result = await db.query(query, [groupId]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get payment summary: ${error.message}`);
    }
  }

  // Get debt relationships for a group (who owes what to whom)
  static async getDebtRelationships(groupId) {
    try {
      const query = `
        SELECT 
          from_member.id as from_member_id,
          from_member.nickname as from_nickname,
          to_member.id as to_member_id,
          to_member.nickname as to_nickname,
          SUM(p.amount) as total_amount,
          COUNT(*) as payment_count
        FROM payments p
        JOIN group_members from_member ON p.from_group_member_id = from_member.id
        JOIN group_members to_member ON p.to_group_member_id = to_member.id
        WHERE p.group_id = $1 AND p.status = 'pending'
        GROUP BY from_member.id, from_member.nickname, to_member.id, to_member.nickname
        HAVING SUM(p.amount) > 0
        ORDER BY total_amount DESC
      `;
      
      const result = await db.query(query, [groupId]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get debt relationships: ${error.message}`);
    }
  }

  // Convert to JSON
  toJSON() {
    return {
      id: this.id,
      group_id: this.group_id,
      from_group_member_id: this.from_group_member_id,
      to_group_member_id: this.to_group_member_id,
      amount: this.amount,
      currency: this.currency,
      status: this.status,
      payment_method: this.payment_method,
      notes: this.notes,
      created_at: this.created_at,
      updated_at: this.updated_at
    };
  }

  // Static validation methods
  static validate(paymentData) {
    const errors = [];
    const { group_id, from_group_member_id, to_group_member_id, amount, currency } = paymentData;

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
    if (currency && !Payment.isValidCurrency(currency)) {
      errors.push('Invalid currency code (use 3-letter ISO code)');
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
    const validStatuses = ['pending', 'completed', 'cancelled'];
    return validStatuses.includes(status);
  }

  static isValidCurrency(currency) {
    const currencyRegex = /^[A-Z]{3}$/;
    return currencyRegex.test(currency);
  }

  // Create settlement payments from group balances
  static async createSettlementPayments(groupId) {
    try {
      // Get group payment summary to calculate balances
      const Group = require('./Group');
      const group = await Group.findById(groupId);
      if (!group) {
        throw new Error('Group not found');
      }

      const paymentSummary = await group.getPaymentSummary();
      
      // Separate positive and negative balances
      const creditors = paymentSummary.filter(member => member.balance > 0);
      const debtors = paymentSummary.filter(member => member.balance < 0);

      const payments = [];

      // Create payments from debtors to creditors
      for (const debtor of debtors) {
        let remainingDebt = Math.abs(debtor.balance);

        for (const creditor of creditors) {
          if (remainingDebt <= 0 || creditor.balance <= 0) break;

          const paymentAmount = Math.min(remainingDebt, creditor.balance);

          const paymentData = {
            group_id: groupId,
            from_group_member_id: debtor.member_id,
            to_group_member_id: creditor.member_id,
            amount: paymentAmount,
            currency: group.currency,
            payment_method: 'settlement',
            notes: 'Automatic settlement payment'
          };

          const payment = await Payment.create(paymentData);
          payments.push(payment);

          remainingDebt -= paymentAmount;
          creditor.balance -= paymentAmount;
        }
      }

      return payments;
    } catch (error) {
      throw new Error(`Failed to create settlement payments: ${error.message}`);
    }
  }

  // Check if user is involved in a payment
  static async isUserInvolvedInPayment(paymentId, userId) {
    try {
      const query = `
        SELECT id FROM payments p
        JOIN group_members gm1 ON p.from_group_member_id = gm1.id
        JOIN group_members gm2 ON p.to_group_member_id = gm2.id
        WHERE p.id = $1 AND (gm1.user_id = $2 OR gm2.user_id = $2)
      `;
      
      const result = await db.query(query, [paymentId, userId]);
      return result.rows.length > 0;
    } catch (error) {
      throw new Error(`Failed to check user involvement: ${error.message}`);
    }
  }
}

module.exports = Payment; 
module.exports = Payment; 