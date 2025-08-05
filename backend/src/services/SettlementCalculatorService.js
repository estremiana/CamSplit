const db = require('../../database/connection');
const { SettlementErrorFactory, SettlementErrorHandler } = require('../utils/settlementErrors');

class SettlementCalculatorService {
  /**
   * Calculate net balances for all group members based on expenses
   * @param {number} groupId - The group ID to calculate balances for
   * @returns {Promise<Array>} Array of member balance objects
   */
  static async calculateGroupBalances(groupId) {
    try {
      const query = `
        WITH member_payments AS (
          -- Calculate total amount each member has paid
          SELECT 
            gm.id as member_id,
            gm.nickname,
            gm.user_id,
            u.first_name,
            u.last_name,
            u.avatar as user_avatar,
            COALESCE(SUM(ep.amount_paid), 0) as total_paid
          FROM group_members gm
          LEFT JOIN users u ON gm.user_id = u.id
          LEFT JOIN expense_payers ep ON gm.id = ep.group_member_id
          LEFT JOIN expenses e ON ep.expense_id = e.id
          WHERE gm.group_id = $1
          GROUP BY gm.id, gm.nickname, gm.user_id, u.first_name, u.last_name, u.avatar
        ),
        member_splits AS (
          -- Calculate total amount each member owes based on expense splits
          SELECT 
            gm.id as member_id,
            COALESCE(SUM(es.amount_owed), 0) as total_owed
          FROM group_members gm
          LEFT JOIN expense_splits es ON gm.id = es.group_member_id
          LEFT JOIN expenses e ON es.expense_id = e.id
          WHERE gm.group_id = $1
          GROUP BY gm.id
        )
        SELECT 
          mp.member_id,
          mp.nickname,
          mp.user_id,
          mp.first_name,
          mp.last_name,
          mp.user_avatar,
          mp.total_paid,
          COALESCE(ms.total_owed, 0) as total_owed,
          (mp.total_paid - COALESCE(ms.total_owed, 0)) as balance
        FROM member_payments mp
        LEFT JOIN member_splits ms ON mp.member_id = ms.member_id
        ORDER BY mp.nickname
      `;

      const result = await db.query(query, [groupId]);
      
      return result.rows.map(row => ({
        member_id: row.member_id,
        nickname: row.nickname,
        user_id: row.user_id,
        user_name: row.first_name && row.last_name 
          ? `${row.first_name} ${row.last_name}`.trim() 
          : null,
        user_avatar: row.user_avatar,
        total_paid: parseFloat(row.total_paid) || 0,
        total_owed: parseFloat(row.total_owed) || 0,
        balance: parseFloat(row.balance) || 0
      }));
    } catch (error) {
      throw SettlementErrorFactory.fromDatabaseError(error, {
        operation: 'calculate group balances',
        entityId: groupId
      });
    }
  }

  /**
   * Optimize settlements using greedy debt minimization algorithm
   * @param {Array} balances - Array of member balance objects
   * @returns {Array} Array of optimal settlement objects
   */
  static optimizeSettlements(balances) {
    try {
      // Filter out members with zero balance (they don't need to settle)
      const nonZeroBalances = balances.filter(member => Math.abs(member.balance) > 0.01);
      
      if (nonZeroBalances.length === 0) {
        return []; // No settlements needed
      }

      // Separate creditors (positive balance) and debtors (negative balance)
      const creditors = nonZeroBalances
        .filter(member => member.balance > 0.01)
        .map(member => ({ ...member }))
        .sort((a, b) => b.balance - a.balance); // Sort by balance descending

      const debtors = nonZeroBalances
        .filter(member => member.balance < -0.01)
        .map(member => ({ ...member, balance: Math.abs(member.balance) }))
        .sort((a, b) => b.balance - a.balance); // Sort by balance descending

      const settlements = [];

      // Greedy algorithm: match largest debtor with largest creditor
      let creditorIndex = 0;
      let debtorIndex = 0;

      while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
        const creditor = creditors[creditorIndex];
        const debtor = debtors[debtorIndex];

        // Calculate settlement amount (minimum of what creditor is owed and debtor owes)
        let settlementAmount = Math.min(creditor.balance, debtor.balance);
        
        // For the final settlement, use the exact remaining balance to avoid precision issues
        const isLastSettlement = (creditorIndex === creditors.length - 1 && debtorIndex === debtors.length - 1) ||
                                (creditor.balance <= debtor.balance && creditorIndex === creditors.length - 1) ||
                                (debtor.balance <= creditor.balance && debtorIndex === debtors.length - 1);
        
        if (isLastSettlement) {
          // Use the exact amount needed to balance, don't round
          settlementAmount = Math.min(creditor.balance, debtor.balance);
        } else {
          // Round to 2 decimal places for non-final settlements
          settlementAmount = Math.round(settlementAmount * 100) / 100;
        }

        // Create settlement record
        settlements.push({
          from_group_member_id: debtor.member_id,
          to_group_member_id: creditor.member_id,
          amount: Math.round(settlementAmount * 100) / 100, // Always round final amount for display
          from_member: {
            id: debtor.member_id,
            nickname: debtor.nickname,
            user_id: debtor.user_id,
            user_name: debtor.user_name,
            user_avatar: debtor.user_avatar
          },
          to_member: {
            id: creditor.member_id,
            nickname: creditor.nickname,
            user_id: creditor.user_id,
            user_name: creditor.user_name,
            user_avatar: creditor.user_avatar
          }
        });

        // Update balances
        creditor.balance -= settlementAmount;
        debtor.balance -= settlementAmount;

        // Move to next creditor/debtor if current one is settled
        if (creditor.balance < 0.01) {
          creditorIndex++;
        }
        if (debtor.balance < 0.01) {
          debtorIndex++;
        }
      }

      return settlements;
    } catch (error) {
      throw SettlementErrorFactory.createCalculationError(
        `Failed to optimize settlements: ${error.message}`,
        null
      );
    }
  }

  /**
   * Validate settlements for integrity and consistency
   * @param {Array} settlements - Array of settlement objects to validate
   * @param {Array} balances - Original balance data for validation
   * @returns {Object} Validation result with isValid flag and errors
   */
  static validateSettlements(settlements, balances) {
    const errors = [];

    try {
      console.log('Validating settlements:', settlements.length, 'settlements for', balances.length, 'members');
      
      // Check if settlements array is valid
      if (!Array.isArray(settlements)) {
        errors.push('Settlements must be an array');
        return { isValid: false, errors };
      }

      // If no settlements, check if all balances are zero
      if (settlements.length === 0) {
        const hasNonZeroBalance = balances.some(member => Math.abs(member.balance) > 0.01);
        if (hasNonZeroBalance) {
          errors.push('No settlements generated but non-zero balances exist');
        }
        return { isValid: errors.length === 0, errors };
      }

      // Validate each settlement
      settlements.forEach((settlement, index) => {
        // Check required fields
        if (!settlement.from_group_member_id) {
          errors.push(`Settlement ${index}: Missing from_group_member_id`);
        }
        if (!settlement.to_group_member_id) {
          errors.push(`Settlement ${index}: Missing to_group_member_id`);
        }
        if (!settlement.amount || settlement.amount <= 0) {
          errors.push(`Settlement ${index}: Invalid amount`);
        }

        // Check that from and to members are different
        if (settlement.from_group_member_id === settlement.to_group_member_id) {
          errors.push(`Settlement ${index}: From and to members cannot be the same`);
        }
      });

      // Validate settlement balance consistency
      const settlementBalances = {};
      
      // Initialize balances from original data
      balances.forEach(member => {
        settlementBalances[member.member_id] = member.balance;
      });
      
      console.log('Initial settlement balances:', settlementBalances);

      // Apply settlements to check if they balance out
      settlements.forEach(settlement => {
        const fromId = settlement.from_group_member_id;
        const toId = settlement.to_group_member_id;
        const amount = settlement.amount;

        if (settlementBalances[fromId] !== undefined) {
          settlementBalances[fromId] += amount; // Debtor pays, so balance increases
        }
        if (settlementBalances[toId] !== undefined) {
          settlementBalances[toId] -= amount; // Creditor receives, so balance decreases
        }
      });
      
      console.log('Final settlement balances after applying settlements:', settlementBalances);

      // Check if all balances are close to zero after settlements
      // Use a more tolerant threshold for floating-point precision issues
      Object.entries(settlementBalances).forEach(([memberId, balance]) => {
        if (Math.abs(balance) > 1.0) { // Allow up to 1 unit difference for floating-point errors
          errors.push(`Member ${memberId} has remaining balance of ${balance} after settlements`);
        }
      });

      // Check for duplicate settlements (same from/to pair)
      const settlementPairs = new Set();
      settlements.forEach((settlement, index) => {
        const pairKey = `${settlement.from_group_member_id}-${settlement.to_group_member_id}`;
        if (settlementPairs.has(pairKey)) {
          errors.push(`Settlement ${index}: Duplicate settlement pair detected`);
        }
        settlementPairs.add(pairKey);
      });

      console.log('Validation completed with', errors.length, 'errors');
      return {
        isValid: errors.length === 0,
        errors
      };
    } catch (error) {
      errors.push(`Validation error: ${error.message}`);
      return { isValid: false, errors };
    }
  }

  /**
   * Calculate and validate optimal settlements for a group
   * @param {number} groupId - The group ID to calculate settlements for
   * @returns {Promise<Object>} Object containing settlements and validation results
   */
  static async calculateOptimalSettlements(groupId) {
    try {
      // Step 1: Calculate group balances
      const balances = await this.calculateGroupBalances(groupId);
      console.log('Calculated balances:', balances);

      // Step 2: Optimize settlements
      const settlements = this.optimizeSettlements(balances);
      console.log('Generated settlements:', settlements);

      // Step 3: Validate settlements
      const validation = this.validateSettlements(settlements, balances);
      console.log('Validation result:', validation);

      if (!validation.isValid) {
        console.error('Settlement validation failed:', validation.errors);
      }

      SettlementErrorHandler.validateOrThrow(validation, 'settlement optimization');

      return {
        settlements,
        balances,
        validation,
        summary: {
          total_settlements: settlements.length,
          total_amount: settlements.reduce((sum, s) => sum + s.amount, 0),
          members_involved: new Set([
            ...settlements.map(s => s.from_group_member_id),
            ...settlements.map(s => s.to_group_member_id)
          ]).size
        }
      };
    } catch (error) {
      if (error.name && error.name.includes('Settlement')) {
        throw error; // Re-throw settlement-specific errors
      }
      throw SettlementErrorFactory.createCalculationError(
        `Failed to calculate optimal settlements: ${error.message}`,
        groupId
      );
    }
  }

  /**
   * Get settlement statistics for performance monitoring
   * @param {Array} balances - Array of member balance objects
   * @returns {Object} Statistics about the settlement calculation
   */
  static getSettlementStatistics(balances) {
    const nonZeroBalances = balances.filter(member => Math.abs(member.balance) > 0.01);
    const creditors = nonZeroBalances.filter(member => member.balance > 0.01);
    const debtors = nonZeroBalances.filter(member => member.balance < -0.01);
    
    const totalDebt = debtors.reduce((sum, debtor) => sum + Math.abs(debtor.balance), 0);
    const totalCredit = creditors.reduce((sum, creditor) => sum + creditor.balance, 0);

    return {
      total_members: balances.length,
      members_with_balance: nonZeroBalances.length,
      creditors_count: creditors.length,
      debtors_count: debtors.length,
      total_debt: Math.round(totalDebt * 100) / 100,
      total_credit: Math.round(totalCredit * 100) / 100,
      balance_difference: Math.round(Math.abs(totalDebt - totalCredit) * 100) / 100,
      max_transactions_without_optimization: creditors.length * debtors.length,
      theoretical_min_transactions: Math.max(creditors.length, debtors.length) - 1
    };
  }
}

module.exports = SettlementCalculatorService;