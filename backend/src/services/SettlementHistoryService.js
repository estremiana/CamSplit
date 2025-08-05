const Settlement = require('../models/Settlement');
const Expense = require('../models/Expense');
const Group = require('../models/Group');
const db = require('../../database/connection');
const { SettlementErrorFactory, SettlementErrorHandler } = require('../utils/settlementErrors');

class SettlementHistoryService {
  /**
   * Get comprehensive settlement history with advanced filtering
   * @param {number} groupId - Group ID
   * @param {Object} filters - Filtering options
   * @param {Object} pagination - Pagination options
   * @returns {Promise<Object>} Settlement history with metadata
   */
  static async getSettlementHistory(groupId, filters = {}, pagination = {}) {
    try {
      const {
        status = 'settled',
        from_date,
        to_date,
        from_member_id,
        to_member_id,
        min_amount,
        max_amount,
        settled_by_user_id,
        include_expenses = false
      } = filters;

      const {
        limit = 50,
        offset = 0,
        sort_by = 'settled_at',
        sort_order = 'DESC'
      } = pagination;

      // Build dynamic query
      let query = `
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
          to_user.avatar as to_user_avatar,
          settled_user.first_name as settled_by_first_name,
          settled_user.last_name as settled_by_last_name,
          settled_user.avatar as settled_by_avatar
          ${include_expenses ? ', e.title as expense_title, e.description as expense_description, e.amount as expense_amount' : ''}
        FROM settlements s
        JOIN group_members from_member ON s.from_group_member_id = from_member.id
        JOIN group_members to_member ON s.to_group_member_id = to_member.id
        LEFT JOIN users from_user ON from_member.user_id = from_user.id
        LEFT JOIN users to_user ON to_member.user_id = to_user.id
        LEFT JOIN users settled_user ON s.settled_by = settled_user.id
        ${include_expenses ? 'LEFT JOIN expenses e ON s.created_expense_id = e.id' : ''}
        WHERE s.group_id = $1
      `;

      const queryParams = [groupId];
      let paramIndex = 2;

      // Add status filter
      if (status) {
        query += ` AND s.status = $${paramIndex}`;
        queryParams.push(status);
        paramIndex++;
      }

      // Add date range filters
      if (from_date) {
        query += ` AND s.settled_at >= $${paramIndex}`;
        queryParams.push(from_date);
        paramIndex++;
      }

      if (to_date) {
        query += ` AND s.settled_at <= $${paramIndex}`;
        queryParams.push(to_date);
        paramIndex++;
      }

      // Add member filters
      if (from_member_id) {
        query += ` AND s.from_group_member_id = $${paramIndex}`;
        queryParams.push(from_member_id);
        paramIndex++;
      }

      if (to_member_id) {
        query += ` AND s.to_group_member_id = $${paramIndex}`;
        queryParams.push(to_member_id);
        paramIndex++;
      }

      // Add amount range filters
      if (min_amount) {
        query += ` AND s.amount >= $${paramIndex}`;
        queryParams.push(min_amount);
        paramIndex++;
      }

      if (max_amount) {
        query += ` AND s.amount <= $${paramIndex}`;
        queryParams.push(max_amount);
        paramIndex++;
      }

      // Add settled by filter
      if (settled_by_user_id) {
        query += ` AND s.settled_by = $${paramIndex}`;
        queryParams.push(settled_by_user_id);
        paramIndex++;
      }

      // Add sorting
      const validSortColumns = ['settled_at', 'amount', 'created_at'];
      const validSortOrders = ['ASC', 'DESC'];
      
      const sortColumn = validSortColumns.includes(sort_by) ? sort_by : 'settled_at';
      const sortOrderValue = validSortOrders.includes(sort_order.toUpperCase()) ? sort_order.toUpperCase() : 'DESC';
      
      query += ` ORDER BY s.${sortColumn} ${sortOrderValue}`;

      // Add pagination
      query += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
      queryParams.push(limit, offset);

      const result = await db.query(query, queryParams);

      // Format results
      const settlements = result.rows.map(row => ({
        id: row.id,
        group_id: row.group_id,
        amount: parseFloat(row.amount),
        currency: row.currency,
        status: row.status,
        calculation_timestamp: row.calculation_timestamp,
        settled_at: row.settled_at,
        created_at: row.created_at,
        updated_at: row.updated_at,
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
        },
        settled_by: {
          user_id: row.settled_by,
          user_name: row.settled_by_first_name && row.settled_by_last_name 
            ? `${row.settled_by_first_name} ${row.settled_by_last_name}`.trim() 
            : null,
          user_avatar: row.settled_by_avatar
        },
        ...(include_expenses && row.expense_title && {
          created_expense: {
            id: row.created_expense_id,
            title: row.expense_title,
            description: row.expense_description,
            amount: parseFloat(row.expense_amount)
          }
        })
      }));

      // Get total count for pagination
      const countQuery = `
        SELECT COUNT(*) as total
        FROM settlements s
        WHERE s.group_id = $1 AND s.status = $2
        ${from_date ? 'AND s.settled_at >= $3' : ''}
        ${to_date ? `AND s.settled_at <= $${from_date ? 4 : 3}` : ''}
      `;

      const countParams = [groupId, status];
      if (from_date) countParams.push(from_date);
      if (to_date) countParams.push(to_date);

      const countResult = await db.query(countQuery, countParams);
      const totalCount = parseInt(countResult.rows[0].total);

      return {
        settlements,
        pagination: {
          limit,
          offset,
          total: totalCount,
          has_more: offset + limit < totalCount,
          page: Math.floor(offset / limit) + 1,
          total_pages: Math.ceil(totalCount / limit)
        },
        filters: {
          status,
          from_date,
          to_date,
          from_member_id,
          to_member_id,
          min_amount,
          max_amount,
          settled_by_user_id,
          include_expenses
        },
        sorting: {
          sort_by: sortColumn,
          sort_order: sortOrderValue
        }
      };
    } catch (error) {
      throw SettlementErrorFactory.fromDatabaseError(error, {
        operation: 'get settlement history',
        entityId: groupId
      });
    }
  }

  /**
   * Get settlement analytics for a group
   * @param {number} groupId - Group ID
   * @param {Object} dateRange - Date range for analytics
   * @returns {Promise<Object>} Settlement analytics
   */
  static async getSettlementAnalytics(groupId, dateRange = {}) {
    try {
      const { from_date, to_date } = dateRange;

      // Base analytics query
      let analyticsQuery = `
        SELECT 
          COUNT(*) as total_settlements,
          COUNT(CASE WHEN status = 'settled' THEN 1 END) as settled_count,
          COUNT(CASE WHEN status = 'active' THEN 1 END) as active_count,
          COUNT(CASE WHEN status = 'obsolete' THEN 1 END) as obsolete_count,
          SUM(CASE WHEN status = 'settled' THEN amount ELSE 0 END) as total_settled_amount,
          SUM(CASE WHEN status = 'active' THEN amount ELSE 0 END) as total_pending_amount,
          AVG(CASE WHEN status = 'settled' THEN amount END) as avg_settlement_amount,
          MIN(CASE WHEN status = 'settled' THEN amount END) as min_settlement_amount,
          MAX(CASE WHEN status = 'settled' THEN amount END) as max_settlement_amount,
          MIN(CASE WHEN status = 'settled' THEN settled_at END) as first_settlement_date,
          MAX(CASE WHEN status = 'settled' THEN settled_at END) as last_settlement_date
        FROM settlements
        WHERE group_id = $1
      `;

      const analyticsParams = [groupId];
      let paramIndex = 2;

      if (from_date) {
        analyticsQuery += ` AND created_at >= $${paramIndex}`;
        analyticsParams.push(from_date);
        paramIndex++;
      }

      if (to_date) {
        analyticsQuery += ` AND created_at <= $${paramIndex}`;
        analyticsParams.push(to_date);
        paramIndex++;
      }

      const analyticsResult = await db.query(analyticsQuery, analyticsParams);
      const analytics = analyticsResult.rows[0];

      // Get member-specific analytics
      const memberAnalyticsQuery = `
        SELECT 
          gm.id as member_id,
          gm.nickname,
          gm.user_id,
          u.first_name,
          u.last_name,
          u.avatar,
          COUNT(CASE WHEN s.from_group_member_id = gm.id AND s.status = 'settled' THEN 1 END) as settlements_paid,
          COUNT(CASE WHEN s.to_group_member_id = gm.id AND s.status = 'settled' THEN 1 END) as settlements_received,
          SUM(CASE WHEN s.from_group_member_id = gm.id AND s.status = 'settled' THEN s.amount ELSE 0 END) as total_paid,
          SUM(CASE WHEN s.to_group_member_id = gm.id AND s.status = 'settled' THEN s.amount ELSE 0 END) as total_received,
          COUNT(CASE WHEN s.from_group_member_id = gm.id AND s.status = 'active' THEN 1 END) as pending_to_pay,
          COUNT(CASE WHEN s.to_group_member_id = gm.id AND s.status = 'active' THEN 1 END) as pending_to_receive,
          SUM(CASE WHEN s.from_group_member_id = gm.id AND s.status = 'active' THEN s.amount ELSE 0 END) as pending_pay_amount,
          SUM(CASE WHEN s.to_group_member_id = gm.id AND s.status = 'active' THEN s.amount ELSE 0 END) as pending_receive_amount
        FROM group_members gm
        LEFT JOIN users u ON gm.user_id = u.id
        LEFT JOIN settlements s ON (s.from_group_member_id = gm.id OR s.to_group_member_id = gm.id) AND s.group_id = gm.group_id
        WHERE gm.group_id = $1
        GROUP BY gm.id, gm.nickname, gm.user_id, u.first_name, u.last_name, u.avatar
        ORDER BY total_paid DESC
      `;

      const memberAnalyticsResult = await db.query(memberAnalyticsQuery, [groupId]);

      // Get time-based analytics (monthly breakdown)
      const timeAnalyticsQuery = `
        SELECT 
          DATE_TRUNC('month', settled_at) as month,
          COUNT(*) as settlements_count,
          SUM(amount) as total_amount,
          AVG(amount) as avg_amount
        FROM settlements
        WHERE group_id = $1 AND status = 'settled' AND settled_at IS NOT NULL
        GROUP BY DATE_TRUNC('month', settled_at)
        ORDER BY month DESC
        LIMIT 12
      `;

      const timeAnalyticsResult = await db.query(timeAnalyticsQuery, [groupId]);

      return {
        overview: {
          total_settlements: parseInt(analytics.total_settlements),
          settled_count: parseInt(analytics.settled_count),
          active_count: parseInt(analytics.active_count),
          obsolete_count: parseInt(analytics.obsolete_count),
          total_settled_amount: parseFloat(analytics.total_settled_amount) || 0,
          total_pending_amount: parseFloat(analytics.total_pending_amount) || 0,
          avg_settlement_amount: parseFloat(analytics.avg_settlement_amount) || 0,
          min_settlement_amount: parseFloat(analytics.min_settlement_amount) || 0,
          max_settlement_amount: parseFloat(analytics.max_settlement_amount) || 0,
          first_settlement_date: analytics.first_settlement_date,
          last_settlement_date: analytics.last_settlement_date,
          settlement_rate: analytics.total_settlements > 0 
            ? (parseInt(analytics.settled_count) / parseInt(analytics.total_settlements) * 100).toFixed(2)
            : 0
        },
        member_analytics: memberAnalyticsResult.rows.map(row => ({
          member_id: row.member_id,
          nickname: row.nickname,
          user_id: row.user_id,
          user_name: row.first_name && row.last_name 
            ? `${row.first_name} ${row.last_name}`.trim() 
            : null,
          user_avatar: row.avatar,
          settlements_paid: parseInt(row.settlements_paid),
          settlements_received: parseInt(row.settlements_received),
          total_paid: parseFloat(row.total_paid) || 0,
          total_received: parseFloat(row.total_received) || 0,
          net_balance: (parseFloat(row.total_received) || 0) - (parseFloat(row.total_paid) || 0),
          pending_to_pay: parseInt(row.pending_to_pay),
          pending_to_receive: parseInt(row.pending_to_receive),
          pending_pay_amount: parseFloat(row.pending_pay_amount) || 0,
          pending_receive_amount: parseFloat(row.pending_receive_amount) || 0
        })),
        time_analytics: timeAnalyticsResult.rows.map(row => ({
          month: row.month,
          settlements_count: parseInt(row.settlements_count),
          total_amount: parseFloat(row.total_amount),
          avg_amount: parseFloat(row.avg_amount)
        })),
        date_range: {
          from_date,
          to_date
        }
      };
    } catch (error) {
      throw SettlementErrorFactory.fromDatabaseError(error, {
        operation: 'get settlement analytics',
        entityId: groupId
      });
    }
  }

  /**
   * Get settlement audit trail
   * @param {number} settlementId - Settlement ID
   * @returns {Promise<Object>} Settlement audit trail
   */
  static async getSettlementAuditTrail(settlementId) {
    try {
      // Get settlement details with all related information
      const settlement = await Settlement.findByIdWithDetails(settlementId);
      
      if (!settlement) {
        throw SettlementErrorFactory.createNotFoundError(settlementId);
      }

      // Get related expense if settlement was processed
      let relatedExpense = null;
      if (settlement.created_expense_id) {
        relatedExpense = await Expense.findById(settlement.created_expense_id);
      }

      // Get calculation history (settlements with same calculation timestamp)
      const calculationHistoryQuery = `
        SELECT 
          s.*,
          from_member.nickname as from_nickname,
          to_member.nickname as to_nickname
        FROM settlements s
        JOIN group_members from_member ON s.from_group_member_id = from_member.id
        JOIN group_members to_member ON s.to_group_member_id = to_member.id
        WHERE s.group_id = $1 
          AND s.calculation_timestamp = $2
          AND s.id != $3
        ORDER BY s.amount DESC
      `;

      const calculationHistoryResult = await db.query(calculationHistoryQuery, [
        settlement.group_id,
        settlement.calculation_timestamp,
        settlementId
      ]);

      // Get group information
      const group = await Group.findById(settlement.group_id);

      return {
        settlement: {
          ...settlement,
          lifecycle_stage: this.getSettlementLifecycleStage(settlement),
          processing_time: settlement.settled_at && settlement.created_at
            ? new Date(settlement.settled_at) - new Date(settlement.created_at)
            : null
        },
        related_expense: relatedExpense ? {
          id: relatedExpense.id,
          title: relatedExpense.title,
          description: relatedExpense.description,
          amount: relatedExpense.amount,
          currency: relatedExpense.currency,
          created_at: relatedExpense.created_at
        } : null,
        calculation_batch: {
          timestamp: settlement.calculation_timestamp,
          related_settlements: calculationHistoryResult.rows.map(row => ({
            id: row.id,
            from_nickname: row.from_nickname,
            to_nickname: row.to_nickname,
            amount: parseFloat(row.amount),
            status: row.status
          })),
          batch_size: calculationHistoryResult.rows.length + 1
        },
        group: {
          id: group.id,
          name: group.name,
          created_at: group.created_at
        },
        metadata: {
          audit_generated_at: new Date().toISOString(),
          settlement_age_days: settlement.created_at 
            ? Math.floor((new Date() - new Date(settlement.created_at)) / (1000 * 60 * 60 * 24))
            : null
        }
      };
    } catch (error) {
      if (error.name && error.name.includes('Settlement')) {
        throw error;
      }
      throw SettlementErrorFactory.fromDatabaseError(error, {
        operation: 'get settlement audit trail',
        entityId: settlementId
      });
    }
  }

  /**
   * Export settlement history to CSV format
   * @param {number} groupId - Group ID
   * @param {Object} filters - Export filters
   * @returns {Promise<string>} CSV data
   */
  static async exportSettlementHistory(groupId, filters = {}) {
    try {
      const historyData = await this.getSettlementHistory(groupId, {
        ...filters,
        include_expenses: true
      }, { limit: 10000, offset: 0 }); // Large limit for export

      const csvHeaders = [
        'Settlement ID',
        'From Member',
        'To Member',
        'Amount',
        'Currency',
        'Status',
        'Created At',
        'Settled At',
        'Settled By',
        'Related Expense',
        'Processing Time (hours)'
      ];

      const csvRows = historyData.settlements.map(settlement => {
        const processingTime = settlement.settled_at && settlement.created_at
          ? ((new Date(settlement.settled_at) - new Date(settlement.created_at)) / (1000 * 60 * 60)).toFixed(2)
          : '';

        return [
          settlement.id,
          settlement.from_member.nickname,
          settlement.to_member.nickname,
          settlement.amount,
          settlement.currency,
          settlement.status,
          settlement.created_at,
          settlement.settled_at || '',
          settlement.settled_by.user_name || '',
          settlement.created_expense?.title || '',
          processingTime
        ];
      });

      // Convert to CSV format
      const csvContent = [
        csvHeaders.join(','),
        ...csvRows.map(row => row.map(field => `"${field}"`).join(','))
      ].join('\n');

      return csvContent;
    } catch (error) {
      throw SettlementErrorFactory.createProcessingError(
        `Failed to export settlement history: ${error.message}`,
        null
      );
    }
  }

  /**
   * Get settlement lifecycle stage
   * @private
   */
  static getSettlementLifecycleStage(settlement) {
    switch (settlement.status) {
      case 'active':
        return 'pending_settlement';
      case 'settled':
        return 'completed';
      case 'obsolete':
        return 'superseded';
      default:
        return 'unknown';
    }
  }
}

module.exports = SettlementHistoryService;