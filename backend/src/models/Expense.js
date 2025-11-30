const db = require('../../database/connection');

class Expense {
  constructor(data) {
    this.id = data.id;
    this.title = data.title;
    this.total_amount = data.total_amount;
    this.currency = data.currency;
    this.date = data.date;
    this.category = data.category;
    this.notes = data.notes;
    this.group_id = data.group_id;
    this.split_type = data.split_type;
    this.receipt_image_url = data.receipt_image_url;
    this.created_by = data.created_by;
    this.created_by_name = data.created_by_name; // Add nickname support
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Create a new expense with payers and splits
  static async create(expenseData, payers, splits) {
    const { 
      title, total_amount, currency, date, category, notes, 
      group_id, split_type, receipt_image_url, created_by 
    } = expenseData;

    // Validate input
    const validation = Expense.validate(expenseData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    // Validate payers and splits
    const payersValidation = Expense.validatePayers(payers, total_amount);
    if (!payersValidation.isValid) {
      throw new Error(`Payers validation failed: ${payersValidation.errors.join(', ')}`);
    }

    const splitsValidation = Expense.validateSplits(splits, total_amount, split_type);
    if (!splitsValidation.isValid) {
      throw new Error(`Splits validation failed: ${splitsValidation.errors.join(', ')}`);
    }

    try {
      // Start transaction
      const client = await db.pool.connect();
      await client.query('BEGIN');

      try {
        // Create expense
        const expenseQuery = `
          INSERT INTO expenses (
            title, total_amount, currency, date, category, notes, 
            group_id, split_type, receipt_image_url, created_by, created_at, updated_at
          )
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW())
          RETURNING *
        `;
        
        const expenseValues = [
          title, total_amount, currency || 'EUR', date, category || 'Other', 
          notes, group_id, split_type || 'equal', receipt_image_url, created_by
        ];
        
        const expenseResult = await client.query(expenseQuery, expenseValues);
        const expense = new Expense(expenseResult.rows[0]);

        // Add payers
        for (const payer of payers) {
          const payerQuery = `
            INSERT INTO expense_payers (
              expense_id, group_member_id, amount_paid, payment_method, payment_date, created_at
            )
            VALUES ($1, $2, $3, $4, $5, NOW())
          `;
          
          const payerValues = [
            expense.id,
            payer.group_member_id,
            payer.amount_paid,
            payer.payment_method || 'unknown',
            payer.payment_date || new Date()
          ];
          
          await client.query(payerQuery, payerValues);
        }

        // Add splits
        for (const split of splits) {
          const splitQuery = `
            INSERT INTO expense_splits (
              expense_id, group_member_id, amount_owed, split_type, percentage, created_at
            )
            VALUES ($1, $2, $3, $4, $5, NOW())
          `;
          
          const splitValues = [
            expense.id,
            split.group_member_id,
            split.amount_owed,
            split_type || 'equal',
            split.percentage || null
          ];
          
          await client.query(splitQuery, splitValues);
        }

        await client.query('COMMIT');
        return expense;
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      throw new Error(`Failed to create expense: ${error.message}`);
    }
  }

  // Find expense by ID
  static async findById(id) {
    try {
      const query = 'SELECT * FROM expenses WHERE id = $1';
      const result = await db.query(query, [id]);
      if (result.rows.length === 0) {
        return null;
      }
      return new Expense(result.rows[0]);
    } catch (error) {
      throw new Error(`Failed to find expense: ${error.message}`);
    }
  }

  // Get expense with full details (payers and splits)
  static async findByIdWithDetails(id) {
    try {
      const expense = await Expense.findById(id);
      if (!expense) {
        return null;
      }

      const payers = await expense.getPayers();
      const splits = await expense.getSplits();
      
      // Get receipt images
      const receiptImagesQuery = `
        SELECT id, image_url, ocr_data, created_at
        FROM receipt_images
        WHERE expense_id = $1
        ORDER BY created_at DESC
      `;
      const receiptImagesResult = await db.query(receiptImagesQuery, [id]);
      const receipt_images = receiptImagesResult.rows;
      
      return {
        ...expense.toJSON(),
        payers,
        splits,
        receipt_images
      };
    } catch (error) {
      throw new Error(`Failed to find expense with details: ${error.message}`);
    }
  }

  // Get expenses for a group
  static async getExpensesForGroup(groupId, limit = 10, offset = 0) {
    try {
      const query = `
        SELECT e.*, gm.nickname as created_by_name
        FROM expenses e
        JOIN group_members gm ON e.created_by = gm.user_id AND e.group_id = gm.group_id
        WHERE e.group_id = $1
        ORDER BY e.created_at DESC
        LIMIT $2 OFFSET $3
      `;
      
      const result = await db.query(query, [groupId, limit, offset]);
      return result.rows.map(row => new Expense(row));
    } catch (error) {
      throw new Error(`Failed to get expenses for group: ${error.message}`);
    }
  }

  // Get expenses for a user (across all groups)
  static async getExpensesForUser(userId, limit = 10, offset = 0) {
    try {
      const query = `
        SELECT DISTINCT e.*, g.name as group_name, creator_gm.nickname as created_by_name
        FROM expenses e
        JOIN groups g ON e.group_id = g.id
        JOIN group_members gm ON g.id = gm.group_id
        JOIN group_members creator_gm ON e.created_by = creator_gm.user_id AND e.group_id = creator_gm.group_id
        WHERE gm.user_id = $1
        ORDER BY e.created_at DESC
        LIMIT $2 OFFSET $3
      `;
      
      const result = await db.query(query, [userId, limit, offset]);
      return result.rows.map(row => new Expense(row));
    } catch (error) {
      throw new Error(`Failed to get expenses for user: ${error.message}`);
    }
  }

  // Update expense
  async update(updateData) {
    const { 
      title, total_amount, currency, date, category, notes, 
      split_type, receipt_image_url, payers, participant_amounts 
    } = updateData;
    
    // Validate input
    const validation = Expense.validate(updateData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      const query = `
        UPDATE expenses 
        SET title = COALESCE($1, title),
            total_amount = COALESCE($2, total_amount),
            currency = COALESCE($3, currency),
            date = COALESCE($4, date),
            category = COALESCE($5, category),
            notes = COALESCE($6, notes),
            split_type = COALESCE($7, split_type),
            receipt_image_url = COALESCE($8, receipt_image_url),
            updated_at = NOW()
        WHERE id = $9
        RETURNING *
      `;
      
      const values = [
        title, total_amount, currency, date, category, notes, 
        split_type, receipt_image_url, this.id
      ];
      const result = await db.query(query, values);
      
      if (result.rows.length === 0) {
        throw new Error('Expense not found');
      }
      
      // Store old values for comparison
      const oldTotalAmount = this.total_amount;
      
      // Update current instance
      Object.assign(this, result.rows[0]);
      
      // If total_amount changed, recalculate splits to maintain consistency
      if (total_amount && parseFloat(total_amount) !== parseFloat(oldTotalAmount)) {
        await this.recalculateSplitsForAmountChange(parseFloat(oldTotalAmount), parseFloat(total_amount));
      }
      
      // Update payers if provided
      if (payers && Array.isArray(payers)) {
        await this.updatePayers(payers);
      }
      
      // Update splits if participant_amounts are provided
      if (participant_amounts && Array.isArray(participant_amounts)) {
        await this.updateSplits(participant_amounts);
      }
      
      return this;
    } catch (error) {
      throw new Error(`Failed to update expense: ${error.message}`);
    }
  }

  // Delete expense
  async delete() {
    try {
      const query = 'DELETE FROM expenses WHERE id = $1 RETURNING *';
      const result = await db.query(query, [this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Expense not found');
      }
      
      return true;
    } catch (error) {
      throw new Error(`Failed to delete expense: ${error.message}`);
    }
  }

  // Get expense payers
  async getPayers() {
    try {
      const query = `
        SELECT 
          ep.id,
          ep.amount_paid,
          ep.payment_method,
          ep.payment_date,
          gm.id as group_member_id,
          gm.nickname,
          gm.user_id,
          u.avatar as user_avatar
        FROM expense_payers ep
        JOIN group_members gm ON ep.group_member_id = gm.id
        LEFT JOIN users u ON gm.user_id = u.id
        WHERE ep.expense_id = $1
        ORDER BY ep.created_at ASC
      `;
      
      const result = await db.query(query, [this.id]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get expense payers: ${error.message}`);
    }
  }

  // Get expense splits
  async getSplits() {
    try {
      const query = `
        SELECT 
          es.id,
          es.amount_owed,
          es.split_type,
          es.percentage,
          gm.id as group_member_id,
          gm.nickname,
          gm.user_id,
          u.avatar as user_avatar
        FROM expense_splits es
        JOIN group_members gm ON es.group_member_id = gm.id
        LEFT JOIN users u ON gm.user_id = u.id
        WHERE es.expense_id = $1
        ORDER BY es.created_at ASC
      `;
      
      const result = await db.query(query, [this.id]);
      return result.rows;
    } catch (error) {
      throw new Error(`Failed to get expense splits: ${error.message}`);
    }
  }

  // Add payer to expense
  async addPayer(payerData) {
    const { group_member_id, amount_paid, payment_method, payment_date } = payerData;

    // Validate input
    const validation = Expense.validatePayer(payerData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      const query = `
        INSERT INTO expense_payers (
          expense_id, group_member_id, amount_paid, payment_method, payment_date, created_at
        )
        VALUES ($1, $2, $3, $4, $5, NOW())
        RETURNING *
      `;
      
      const values = [
        this.id,
        group_member_id,
        amount_paid,
        payment_method || 'unknown',
        payment_date || new Date()
      ];
      
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (error) {
      throw new Error(`Failed to add payer: ${error.message}`);
    }
  }

  // Remove payer from expense
  async removePayer(payerId) {
    try {
      const query = 'DELETE FROM expense_payers WHERE id = $1 AND expense_id = $2 RETURNING *';
      const result = await db.query(query, [payerId, this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Payer not found in this expense');
      }
      
      return result.rows[0];
    } catch (error) {
      throw new Error(`Failed to remove payer: ${error.message}`);
    }
  }

  // Update payers for expense (replace all existing payers)
  async updatePayers(payers) {
    try {
      // Validate payers
      const validation = Expense.validatePayers(payers, this.total_amount);
      if (!validation.isValid) {
        throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
      }

      // Start transaction
      const client = await db.pool.connect();
      
      try {
        await client.query('BEGIN');
        
        // Remove all existing payers for this expense
        await client.query('DELETE FROM expense_payers WHERE expense_id = $1', [this.id]);
        
        // Add new payers
        for (const payer of payers) {
          const { group_member_id, amount_paid, payment_method, payment_date } = payer;
          
          const insertQuery = `
            INSERT INTO expense_payers (
              expense_id, group_member_id, amount_paid, payment_method, payment_date, created_at
            )
            VALUES ($1, $2, $3, $4, $5, NOW())
          `;
          
          await client.query(insertQuery, [
            this.id,
            group_member_id,
            amount_paid,
            payment_method || 'unknown',
            payment_date || new Date()
          ]);
        }
        
        await client.query('COMMIT');
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      throw new Error(`Failed to update payers: ${error.message}`);
    }
  }

  // Update expense splits
  async updateSplits(participantAmounts) {
    try {
      // Start transaction
      const client = await db.pool.connect();
      
      try {
        await client.query('BEGIN');
        
        // Remove all existing splits for this expense
        await client.query('DELETE FROM expense_splits WHERE expense_id = $1', [this.id]);
        
        console.log('Processing participant amounts:', participantAmounts);
        
        // Add new splits based on participant amounts
        for (const participant of participantAmounts) {
          const { group_member_id, amount, percentage } = participant;
          
          // Validate that we have the required data
          if (!group_member_id) {
            console.warn(`Missing group_member_id for participant:`, participant);
            continue;
          }
          
          if (amount === undefined || amount === null) {
            console.warn(`Missing amount for participant:`, participant);
            continue;
          }
          
          // Use the percentage provided by frontend, or calculate if not provided
          let finalPercentage = percentage;
          if (finalPercentage === undefined || finalPercentage === null) {
            if (this.split_type === 'percentage' && this.total_amount > 0) {
              finalPercentage = (amount / this.total_amount) * 100;
            }
          }
          
          const insertQuery = `
            INSERT INTO expense_splits (
              expense_id, group_member_id, amount_owed, split_type, percentage, created_at
            )
            VALUES ($1, $2, $3, $4, $5, NOW())
          `;
          
          console.log(`Inserting split: expense_id=${this.id}, group_member_id=${group_member_id}, amount=${amount}, split_type=${this.split_type}, percentage=${finalPercentage}`);
          
          await client.query(insertQuery, [
            this.id,
            group_member_id,
            amount,
            this.split_type,
            finalPercentage
          ]);
        }
        
        await client.query('COMMIT');
      } catch (error) {
        await client.query('ROLLBACK');
        throw error;
      } finally {
        client.release();
      }
    } catch (error) {
      throw new Error(`Failed to update splits: ${error.message}`);
    }
  }

  // Add split to expense
  async addSplit(splitData) {
    const { group_member_id, amount_owed, percentage } = splitData;

    // Validate input
    const validation = Expense.validateSplit(splitData);
    if (!validation.isValid) {
      throw new Error(`Validation failed: ${validation.errors.join(', ')}`);
    }

    try {
      const query = `
        INSERT INTO expense_splits (
          expense_id, group_member_id, amount_owed, split_type, percentage, created_at
        )
        VALUES ($1, $2, $3, $4, $5, NOW())
        RETURNING *
      `;
      
      const values = [this.id, group_member_id, amount_owed, this.split_type, percentage || null];
      const result = await db.query(query, values);
      return result.rows[0];
    } catch (error) {
      throw new Error(`Failed to add split: ${error.message}`);
    }
  }

  // Remove split from expense
  async removeSplit(splitId) {
    try {
      const query = 'DELETE FROM expense_splits WHERE id = $1 AND expense_id = $2 RETURNING *';
      const result = await db.query(query, [splitId, this.id]);
      
      if (result.rows.length === 0) {
        throw new Error('Split not found in this expense');
      }
      
      return result.rows[0];
    } catch (error) {
      throw new Error(`Failed to remove split: ${error.message}`);
    }
  }

  // Get expense settlement (who owes what to whom)
  async getSettlement() {
    try {
      const payers = await this.getPayers();
      const splits = await this.getSplits();

      // Calculate net amounts for each member
      const memberBalances = new Map();

      // Initialize balances
      for (const split of splits) {
        memberBalances.set(split.group_member_id, {
          member_id: split.group_member_id,
          nickname: split.nickname,
          amount_owed: split.amount_owed,
          amount_paid: 0,
          balance: -split.amount_owed // Negative because they owe money
        });
      }

      // Add payments
      for (const payer of payers) {
        if (memberBalances.has(payer.group_member_id)) {
          const balance = memberBalances.get(payer.group_member_id);
          balance.amount_paid += parseFloat(payer.amount_paid);
          balance.balance += parseFloat(payer.amount_paid);
        } else {
          // Payer not in splits (overpayment)
          memberBalances.set(payer.group_member_id, {
            member_id: payer.group_member_id,
            nickname: payer.nickname,
            amount_owed: 0,
            amount_paid: parseFloat(payer.amount_paid),
            balance: parseFloat(payer.amount_paid)
          });
        }
      }

      return Array.from(memberBalances.values());
    } catch (error) {
      throw new Error(`Failed to get expense settlement: ${error.message}`);
    }
  }

  // Convert to JSON
  toJSON() {
    return {
      id: this.id,
      title: this.title,
      total_amount: this.total_amount,
      currency: this.currency,
      date: this.date,
      category: this.category,
      notes: this.notes,
      group_id: this.group_id,
      split_type: this.split_type,
      receipt_image_url: this.receipt_image_url,
      created_by: this.created_by,
      created_at: this.created_at,
      updated_at: this.updated_at
    };
  }

  // Static validation methods
  static validate(expenseData) {
    const errors = [];
    const { title, total_amount, currency, date, group_id, participant_amounts } = expenseData;

    // Title validation
    if (!title || title.trim().length < 2) {
      errors.push('Expense title must be at least 2 characters');
    }

    if (title && title.trim().length > 255) {
      errors.push('Expense title must be less than 255 characters');
    }

    // Total amount validation
    if (!total_amount || total_amount <= 0) {
      errors.push('Total amount must be greater than 0');
    }

    // Currency validation
    if (currency && !Expense.isValidCurrency(currency)) {
      errors.push('Invalid currency code (use 3-letter ISO code)');
    }

    // Date validation
    if (date && !Expense.isValidDate(date)) {
      errors.push('Invalid date format (YYYY-MM-DD)');
    }

    // Group ID validation
    if (!group_id) {
      errors.push('Group ID is required');
    }

    // Participant amounts validation
    if (participant_amounts && Array.isArray(participant_amounts)) {
      const participantValidation = Expense.validateParticipantAmounts(participant_amounts, total_amount);
      if (!participantValidation.isValid) {
        errors.push(...participantValidation.errors);
      }
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static validatePayers(payers, totalAmount) {
    const errors = [];

    if (!payers || payers.length === 0) {
      errors.push('At least one payer is required');
      return { isValid: false, errors };
    }

    let totalPaid = 0;
    for (const payer of payers) {
      if (!payer.group_member_id) {
        errors.push('Group member ID is required for each payer');
      }
      if (!payer.amount_paid || payer.amount_paid <= 0) {
        errors.push('Amount paid must be greater than 0 for each payer');
      }
      totalPaid += parseFloat(payer.amount_paid || 0);
    }

    // Check if total paid matches expense amount (with small tolerance for rounding)
    if (Math.abs(totalPaid - totalAmount) > 0.01) {
      errors.push(`Total amount paid (${totalPaid}) must equal expense amount (${totalAmount})`);
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static validateSplits(splits, totalAmount, splitType) {
    const errors = [];

    // For itemized expenses, splits can be empty if they will be calculated from item assignments
    // However, if splits are provided, they should still be validated
    if (!splits || splits.length === 0) {
      if (splitType !== 'itemized') {
        errors.push('At least one split is required');
        return { isValid: false, errors };
      }
      // For itemized expenses, empty splits are allowed (will be calculated from assignments)
      return { isValid: true, errors: [] };
    }

    let totalOwed = 0;
    for (const split of splits) {
      if (!split.group_member_id) {
        errors.push('Group member ID is required for each split');
      }
      if (!split.amount_owed || split.amount_owed <= 0) {
        errors.push('Amount owed must be greater than 0 for each split');
      }
      totalOwed += parseFloat(split.amount_owed || 0);
    }

    // Check if total owed matches expense amount (with small tolerance for rounding)
    if (Math.abs(totalOwed - totalAmount) > 0.01) {
      errors.push(`Total amount owed (${totalOwed}) must equal expense amount (${totalAmount})`);
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static validateParticipantAmounts(participantAmounts, totalAmount) {
    const errors = [];
    
    if (!Array.isArray(participantAmounts)) {
      errors.push('Participant amounts must be an array');
      return { isValid: false, errors };
    }

    if (participantAmounts.length === 0) {
      errors.push('At least one participant is required');
      return { isValid: false, errors };
    }

    let totalOwed = 0;
    const usedMemberIds = new Set();

    for (const participant of participantAmounts) {
      // Validate required fields
      if (!participant.group_member_id) {
        errors.push('Group member ID is required for each participant');
        continue;
      }

      if (usedMemberIds.has(participant.group_member_id)) {
        errors.push(`Duplicate group member ID: ${participant.group_member_id}`);
        continue;
      }
      usedMemberIds.add(participant.group_member_id);

      if (participant.amount === undefined || participant.amount === null) {
        errors.push(`Amount is required for participant with ID: ${participant.group_member_id}`);
        continue;
      }

      if (participant.amount < 0) {
        errors.push(`Amount cannot be negative for participant with ID: ${participant.group_member_id}`);
        continue;
      }

      totalOwed += parseFloat(participant.amount || 0);
    }

    // Check if total owed matches expense amount (with small tolerance for rounding)
    if (Math.abs(totalOwed - totalAmount) > 0.01) {
      errors.push(`Total amount owed (${totalOwed}) must equal expense amount (${totalAmount})`);
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static validatePayer(payerData) {
    const errors = [];
    const { group_member_id, amount_paid } = payerData;

    if (!group_member_id) {
      errors.push('Group member ID is required');
    }

    if (!amount_paid || amount_paid <= 0) {
      errors.push('Amount paid must be greater than 0');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  static validateSplit(splitData) {
    const errors = [];
    const { group_member_id, amount_owed } = splitData;

    if (!group_member_id) {
      errors.push('Group member ID is required');
    }

    if (!amount_owed || amount_owed <= 0) {
      errors.push('Amount owed must be greater than 0');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  // Helper validation methods
  static isValidCurrency(currency) {
    const currencyRegex = /^[A-Z]{3}$/;
    return currencyRegex.test(currency);
  }

  static isValidDate(dateString) {
    const date = new Date(dateString);
    return date instanceof Date && !isNaN(date) && dateString.match(/^\d{4}-\d{2}-\d{2}$/);
  }

  /**
   * Recalculate expense splits when the total amount changes
   * This maintains data integrity by proportionally adjusting splits
   */
  async recalculateSplitsForAmountChange(oldAmount, newAmount) {
    try {
      // Get current splits
      const splitsQuery = `
        SELECT id, group_member_id, amount_owed, split_type
        FROM expense_splits
        WHERE expense_id = $1
      `;
      const splitsResult = await db.query(splitsQuery, [this.id]);
      
      if (splitsResult.rows.length === 0) {
        return; // No splits to update
      }

      const splits = splitsResult.rows;
      const oldTotal = parseFloat(oldAmount);
      const newTotal = parseFloat(newAmount);

      // If the split type is 'equal', recalculate equal splits
      if (this.split_type === 'equal') {
        const equalAmount = Math.round((newTotal / splits.length) * 100) / 100;
        const remainder = Math.round((newTotal - (equalAmount * splits.length)) * 100) / 100;

        for (let i = 0; i < splits.length; i++) {
          const split = splits[i];
          let newSplitAmount = equalAmount;
          
          // Add remainder to the first split to handle rounding
          if (i === 0) {
            newSplitAmount += remainder;
          }

          await db.query(
            'UPDATE expense_splits SET amount_owed = $1 WHERE id = $2',
            [newSplitAmount, split.id]
          );
        }
      } else {
        // For custom splits, proportionally adjust each split
        const ratio = newTotal / oldTotal;
        
        let adjustedTotal = 0;
        const adjustedSplits = [];

        // Calculate proportional amounts
        for (const split of splits) {
          const oldSplitAmount = parseFloat(split.amount_owed);
          const newSplitAmount = Math.round((oldSplitAmount * ratio) * 100) / 100;
          adjustedSplits.push({ ...split, newAmount: newSplitAmount });
          adjustedTotal += newSplitAmount;
        }

        // Handle rounding differences by adjusting the largest split
        const difference = Math.round((newTotal - adjustedTotal) * 100) / 100;
        if (Math.abs(difference) > 0.01) {
          // Find the split with the largest amount to adjust
          const largestSplit = adjustedSplits.reduce((max, split) => 
            split.newAmount > max.newAmount ? split : max
          );
          largestSplit.newAmount += difference;
        }

        // Update all splits
        for (const split of adjustedSplits) {
          await db.query(
            'UPDATE expense_splits SET amount_owed = $1 WHERE id = $2',
            [split.newAmount, split.id]
          );
        }
      }

      console.log(`Recalculated expense splits for expense ${this.id}: ${oldAmount} -> ${newAmount}`);
    } catch (error) {
      console.error(`Failed to recalculate splits for expense ${this.id}:`, error.message);
      // Don't throw error to avoid breaking the expense update
    }
  }
}

module.exports = Expense; 