const express = require('express');
const router = express.Router();
const SettlementController = require('../controllers/settlementController');
const authMiddleware = require('../middleware/auth');
const validationMiddleware = require('../middleware/validation');
const rateLimitMiddleware = require('../middleware/rateLimit');

// Apply authentication middleware to all settlement routes
router.use(authMiddleware.authenticateToken);

// Settlement validation schemas
const settlementValidationSchemas = {
  batchSettle: {
    body: {
      settlement_ids: {
        type: 'array',
        items: { type: 'integer', minimum: 1 },
        minItems: 1,
        maxItems: 50,
        required: true
      }
    }
  },
  recalculate: {
    body: {
      cleanup_obsolete: { type: 'boolean', default: true },
      cleanup_days: { type: 'integer', minimum: 1, maximum: 365, default: 7 }
    }
  },
  historyQuery: {
    query: {
      limit: { type: 'integer', minimum: 1, maximum: 100, default: 50 },
      offset: { type: 'integer', minimum: 0, default: 0 },
      from_date: { type: 'string', format: 'date', optional: true },
      to_date: { type: 'string', format: 'date', optional: true }
    }
  }
};

// Group-level settlement routes
router.get(
  '/groups/:groupId/settlements',
  validationMiddleware.validateParams({
    groupId: { type: 'integer', minimum: 1, required: true }
  }),
  rateLimitMiddleware.createRateLimit({ windowMs: 60000, max: 100 }), // 100 requests per minute
  SettlementController.getGroupSettlements
);

router.get(
  '/groups/:groupId/settlements/history',
  validationMiddleware.validateParams({
    groupId: { type: 'integer', minimum: 1, required: true }
  }),
  validationMiddleware.validateQuery(settlementValidationSchemas.historyQuery.query),
  rateLimitMiddleware.createRateLimit({ windowMs: 60000, max: 50 }), // 50 requests per minute
  SettlementController.getSettlementHistory
);

router.post(
  '/groups/:groupId/settlements/recalculate',
  validationMiddleware.validateParams({
    groupId: { type: 'integer', minimum: 1, required: true }
  }),
  validationMiddleware.validateBody(settlementValidationSchemas.recalculate.body),
  rateLimitMiddleware.createRateLimit({ windowMs: 300000, max: 10 }), // 10 requests per 5 minutes
  SettlementController.recalculateSettlements
);

router.post(
  '/groups/:groupId/settlements/batch-settle',
  validationMiddleware.validateParams({
    groupId: { type: 'integer', minimum: 1, required: true }
  }),
  validationMiddleware.validateBody(settlementValidationSchemas.batchSettle.body),
  rateLimitMiddleware.createRateLimit({ windowMs: 300000, max: 20 }), // 20 requests per 5 minutes
  SettlementController.batchSettleSettlements
);

router.get(
  '/groups/:groupId/settlements/statistics',
  validationMiddleware.validateParams({
    groupId: { type: 'integer', minimum: 1, required: true }
  }),
  rateLimitMiddleware.createRateLimit({ windowMs: 60000, max: 30 }), // 30 requests per minute
  SettlementController.getSettlementStatistics
);

router.get(
  '/groups/:groupId/settlements/analytics',
  validationMiddleware.validateParams({
    groupId: { type: 'integer', minimum: 1, required: true }
  }),
  validationMiddleware.validateQuery({
    from_date: { type: 'string', format: 'date', optional: true },
    to_date: { type: 'string', format: 'date', optional: true }
  }),
  rateLimitMiddleware.createRateLimit({ windowMs: 60000, max: 20 }), // 20 requests per minute
  SettlementController.getSettlementAnalytics
);

router.get(
  '/groups/:groupId/settlements/export',
  validationMiddleware.validateParams({
    groupId: { type: 'integer', minimum: 1, required: true }
  }),
  validationMiddleware.validateQuery({
    status: { type: 'string', optional: true },
    from_date: { type: 'string', format: 'date', optional: true },
    to_date: { type: 'string', format: 'date', optional: true },
    from_member_id: { type: 'integer', minimum: 1, optional: true },
    to_member_id: { type: 'integer', minimum: 1, optional: true },
    min_amount: { type: 'integer', minimum: 0, optional: true },
    max_amount: { type: 'integer', minimum: 0, optional: true }
  }),
  rateLimitMiddleware.createRateLimit({ windowMs: 300000, max: 5 }), // 5 exports per 5 minutes
  SettlementController.exportSettlementHistory
);

// Individual settlement routes
router.get(
  '/settlements/:settlementId',
  validationMiddleware.validateParams({
    settlementId: { type: 'integer', minimum: 1, required: true }
  }),
  rateLimitMiddleware.createRateLimit({ windowMs: 60000, max: 100 }), // 100 requests per minute
  SettlementController.getSettlementDetails
);

router.get(
  '/settlements/:settlementId/preview',
  validationMiddleware.validateParams({
    settlementId: { type: 'integer', minimum: 1, required: true }
  }),
  rateLimitMiddleware.createRateLimit({ windowMs: 60000, max: 50 }), // 50 requests per minute
  SettlementController.getSettlementPreview
);

router.post(
  '/settlements/:settlementId/settle',
  validationMiddleware.validateParams({
    settlementId: { type: 'integer', minimum: 1, required: true }
  }),
  rateLimitMiddleware.createRateLimit({ windowMs: 300000, max: 30 }), // 30 requests per 5 minutes
  SettlementController.settleSettlement
);

router.post(
  '/settlements/:settlementId/remind',
  validationMiddleware.validateParams({
    settlementId: { type: 'integer', minimum: 1, required: true }
  }),
  rateLimitMiddleware.createRateLimit({ windowMs: 300000, max: 10 }), // 10 reminders per 5 minutes
  SettlementController.sendSettlementReminder
);

router.get(
  '/settlements/:settlementId/audit',
  validationMiddleware.validateParams({
    settlementId: { type: 'integer', minimum: 1, required: true }
  }),
  rateLimitMiddleware.createRateLimit({ windowMs: 60000, max: 30 }), // 30 requests per minute
  SettlementController.getSettlementAuditTrail
);

// Import settlement error handler
const { SettlementErrorHandler } = require('../utils/settlementErrors');

// Error handling middleware for settlement routes
router.use(SettlementErrorHandler.expressErrorHandler());

module.exports = router;