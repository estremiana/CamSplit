const Settlement = require('../models/Settlement');
const SettlementProcessorService = require('../services/SettlementProcessorService');
const SettlementHistoryService = require('../services/SettlementHistoryService');
const Group = require('../models/Group');
const { SettlementErrorHandler } = require('../utils/settlementErrors');

class SettlementController {
  /**
   * Get active settlements for a group
   * GET /api/groups/:groupId/settlements
   */
  static getGroupSettlements = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { groupId } = req.params;
    const userId = req.user.id;

    // Verify group exists and user is member
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    const isMember = await group.isUserMember(userId);
    if (!isMember) {
      return res.status(403).json({
        success: false,
        message: 'You must be a member of the group to view settlements'
      });
    }

    // Get settlements with metadata
    const result = await Settlement.getActiveSettlementsWithMetadata(groupId);

    res.json({
      success: true,
      message: 'Settlements retrieved successfully',
      data: {
        settlements: result.settlements,
        metadata: result.metadata,
        group: {
          id: group.id,
          name: group.name
        }
      }
    });
  });

  /**
   * Mark a settlement as settled
   * POST /api/settlements/:settlementId/settle
   */
  static settleSettlement = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { settlementId } = req.params;
    const userId = req.user.id;

    // Validate settlement before processing
    const validation = await SettlementProcessorService.validateSettlementForProcessing(
      settlementId, 
      userId
    );

    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Settlement cannot be processed',
        errors: validation.errors
      });
    }

    // Process the settlement
    const result = await SettlementProcessorService.processSettlement(settlementId, userId);

    res.json({
      success: true,
      message: result.message,
      data: {
        settlement: result.settlement,
        expense: result.expense,
        processing_info: {
          processed_by: userId,
          processed_at: new Date().toISOString()
        }
      }
    });
  });

  /**
   * Send a reminder for a settlement
   * POST /api/settlements/:settlementId/remind
   */
  static sendSettlementReminder = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { settlementId } = req.params;
    const userId = req.user.id;

    // Get settlement with details
    const settlement = await Settlement.findByIdWithDetails(settlementId);
    if (!settlement) {
      return res.status(404).json({
        success: false,
        message: 'Settlement not found'
      });
    }

    // Verify user has permission to send reminder (must be involved in the settlement or group admin)
    const isInvolved = await Settlement.isUserInvolvedInSettlement(settlementId, userId);
    const group = await Group.findById(settlement.group_id);
    const isAdmin = await group.isUserAdmin(userId);

    if (!isInvolved && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to send reminders for this settlement'
      });
    }

    // Verify settlement is active
    if (settlement.status !== 'active') {
      return res.status(400).json({
        success: false,
        message: 'Can only send reminders for active settlements'
      });
    }

    // Send reminder (this would integrate with notification service)
    try {
      // TODO: Integrate with notification service to send actual reminders
      // For now, just log the reminder action
      console.log(`Reminder sent for settlement ${settlementId} by user ${userId}`);
      
      // You could also store reminder history in the database
      // await SettlementReminderService.createReminder(settlementId, userId);

      res.json({
        success: true,
        message: 'Reminder sent successfully',
        data: {
          settlement_id: settlementId,
          reminded_by: userId,
          reminded_at: new Date().toISOString()
        }
      });
    } catch (error) {
      console.error('Error sending settlement reminder:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to send reminder'
      });
    }
  });

  /**
   * Get settlement history for a group
   * GET /api/groups/:groupId/settlements/history
   */
  static getSettlementHistory = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { groupId } = req.params;
    const userId = req.user.id;
    const { limit = 50, offset = 0, from_date, to_date } = req.query;

    // Verify group exists and user is member
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    const isMember = await group.isUserMember(userId);
    if (!isMember) {
      return res.status(403).json({
        success: false,
        message: 'You must be a member of the group to view settlement history'
      });
    }

    // Get enhanced settlement history
    const filters = {
      status: req.query.status || 'settled',
      from_date,
      to_date,
      from_member_id: req.query.from_member_id,
      to_member_id: req.query.to_member_id,
      min_amount: req.query.min_amount,
      max_amount: req.query.max_amount,
      settled_by_user_id: req.query.settled_by_user_id,
      include_expenses: req.query.include_expenses === 'true'
    };

    const pagination = {
      limit: parseInt(limit),
      offset: parseInt(offset),
      sort_by: req.query.sort_by || 'settled_at',
      sort_order: req.query.sort_order || 'DESC'
    };

    const historyData = await SettlementHistoryService.getSettlementHistory(
      groupId,
      filters,
      pagination
    );

    res.json({
      success: true,
      message: 'Settlement history retrieved successfully',
      data: {
        ...historyData,
        group: {
          id: group.id,
          name: group.name
        }
      }
    });
  });

  /**
   * Force recalculation of settlements for a group
   * POST /api/groups/:groupId/settlements/recalculate
   */
  static recalculateSettlements = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { groupId } = req.params;
    const userId = req.user.id;
    const { cleanup_obsolete = true, cleanup_days = 7 } = req.body;

    // Verify group exists and user is admin
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    const isAdmin = await group.isUserAdmin(userId);
    if (!isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Only group administrators can recalculate settlements'
      });
    }

    // Recalculate settlements
    const result = await Settlement.recalculateSettlements(groupId, {
      cleanupObsoleteAfterDays: cleanup_obsolete ? parseInt(cleanup_days) : 0
    });

    res.json({
      success: true,
      message: 'Settlements recalculated successfully',
      data: {
        settlements: result.settlements,
        balances: result.balances,
        summary: result.summary,
        recalculated_by: userId,
        recalculated_at: new Date().toISOString()
      }
    });
  });

  /**
   * Get settlement processing preview
   * GET /api/settlements/:settlementId/preview
   */
  static getSettlementPreview = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { settlementId } = req.params;
    const userId = req.user.id;

    const preview = await SettlementProcessorService.getSettlementProcessingPreview(
      settlementId, 
      userId
    );

    if (!preview.canProcess) {
      return res.status(400).json({
        success: false,
        message: 'Settlement cannot be processed',
        errors: preview.errors,
        preview: null
      });
    }

    res.json({
      success: true,
      message: 'Settlement preview generated successfully',
      data: {
        preview: preview.preview,
        permissions: preview.permissions,
        can_process: preview.canProcess
      }
    });
  });

  /**
   * Process multiple settlements in batch
   * POST /api/groups/:groupId/settlements/batch-settle
   */
  static batchSettleSettlements = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { groupId } = req.params;
    const { settlement_ids } = req.body;
    const userId = req.user.id;

    // Validate input
    if (!Array.isArray(settlement_ids) || settlement_ids.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'settlement_ids must be a non-empty array'
      });
    }

    // Verify group exists and user is member/admin
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    const isMember = await group.isUserMember(userId);
    if (!isMember) {
      return res.status(403).json({
        success: false,
        message: 'You must be a member of the group to settle settlements'
      });
    }

    // Process settlements in batch
    const result = await SettlementProcessorService.processMultipleSettlements(
      settlement_ids, 
      userId
    );

    const statusCode = result.summary.failed_count > 0 ? 207 : 200; // 207 Multi-Status for partial success

    res.status(statusCode).json({
      success: result.summary.failed_count !== result.summary.total,
      message: `Batch processing completed: ${result.summary.successful_count} successful, ${result.summary.failed_count} failed`,
      data: {
        results: result,
        processed_by: userId,
        processed_at: new Date().toISOString()
      }
    });
  });

  /**
   * Get settlement details by ID
   * GET /api/settlements/:settlementId
   */
  static getSettlementDetails = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { settlementId } = req.params;
    const userId = req.user.id;

    const settlement = await Settlement.findByIdWithDetails(settlementId);
    if (!settlement) {
      return res.status(404).json({
        success: false,
        message: 'Settlement not found'
      });
    }

    // Verify user has access to this settlement
    const group = await Group.findById(settlement.group_id);
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    const isMember = await group.isUserMember(userId);
    if (!isMember) {
      return res.status(403).json({
        success: false,
        message: 'You must be a member of the group to view this settlement'
      });
    }

    res.json({
      success: true,
      message: 'Settlement details retrieved successfully',
      data: {
        settlement,
        group: {
          id: group.id,
          name: group.name
        }
      }
    });
  });

  /**
   * Get settlement statistics for a group
   * GET /api/groups/:groupId/settlements/statistics
   */
  static getSettlementStatistics = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { groupId } = req.params;
    const userId = req.user.id;

    // Verify group exists and user is member
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    const isMember = await group.isUserMember(userId);
    if (!isMember) {
      return res.status(403).json({
        success: false,
        message: 'You must be a member of the group to view settlement statistics'
      });
    }

    // Get processing statistics
    const statistics = await SettlementProcessorService.getProcessingStatistics(groupId);

    // Get settlement summary
    const summary = await Settlement.getSettlementSummaryForGroup(groupId);

    res.json({
      success: true,
      message: 'Settlement statistics retrieved successfully',
      data: {
        statistics,
        summary,
        group: {
          id: group.id,
          name: group.name
        }
      }
    });
  });

  /**
   * Get settlement analytics for a group
   * GET /api/groups/:groupId/settlements/analytics
   */
  static getSettlementAnalytics = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { groupId } = req.params;
    const userId = req.user.id;
    const { from_date, to_date } = req.query;

    // Verify group exists and user is member
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    const isMember = await group.isUserMember(userId);
    if (!isMember) {
      return res.status(403).json({
        success: false,
        message: 'You must be a member of the group to view settlement analytics'
      });
    }

    const analytics = await SettlementHistoryService.getSettlementAnalytics(groupId, {
      from_date,
      to_date
    });

    res.json({
      success: true,
      message: 'Settlement analytics retrieved successfully',
      data: {
        analytics,
        group: {
          id: group.id,
          name: group.name
        }
      }
    });
  });

  /**
   * Get settlement audit trail
   * GET /api/settlements/:settlementId/audit
   */
  static getSettlementAuditTrail = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { settlementId } = req.params;
    const userId = req.user.id;

    // Get settlement to verify access
    const settlement = await Settlement.findByIdWithDetails(settlementId);
    if (!settlement) {
      return res.status(404).json({
        success: false,
        message: 'Settlement not found'
      });
    }

    // Verify user has access to this settlement
    const group = await Group.findById(settlement.group_id);
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    const isMember = await group.isUserMember(userId);
    if (!isMember) {
      return res.status(403).json({
        success: false,
        message: 'You must be a member of the group to view settlement audit trail'
      });
    }

    const auditTrail = await SettlementHistoryService.getSettlementAuditTrail(settlementId);

    res.json({
      success: true,
      message: 'Settlement audit trail retrieved successfully',
      data: auditTrail
    });
  });

  /**
   * Export settlement history
   * GET /api/groups/:groupId/settlements/export
   */
  static exportSettlementHistory = SettlementErrorHandler.asyncHandler(async (req, res) => {
    const { groupId } = req.params;
    const userId = req.user.id;

    // Verify group exists and user is member
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({
        success: false,
        message: 'Group not found'
      });
    }

    const isMember = await group.isUserMember(userId);
    if (!isMember) {
      return res.status(403).json({
        success: false,
        message: 'You must be a member of the group to export settlement history'
      });
    }

    const filters = {
      status: req.query.status || 'settled',
      from_date: req.query.from_date,
      to_date: req.query.to_date,
      from_member_id: req.query.from_member_id,
      to_member_id: req.query.to_member_id,
      min_amount: req.query.min_amount,
      max_amount: req.query.max_amount
    };

    const csvData = await SettlementHistoryService.exportSettlementHistory(groupId, filters);

    // Set CSV headers
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename="settlement-history-${group.name}-${new Date().toISOString().split('T')[0]}.csv"`);

    res.send(csvData);
  });
}

module.exports = SettlementController;