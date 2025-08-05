const request = require('supertest');
const express = require('express');
const settlementRoutes = require('../../src/routes/settlementRoutes');
const SettlementController = require('../../src/controllers/settlementController');
const authMiddleware = require('../../src/middleware/auth');

// Mock the controller methods
jest.mock('../../src/controllers/settlementController');

// Mock the auth middleware
jest.mock('../../src/middleware/auth', () => ({
  authenticateToken: jest.fn((req, res, next) => {
    req.user = { id: 1, email: 'test@example.com' };
    next();
  })
}));

describe('Settlement Routes', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api', settlementRoutes);
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/groups/:groupId/settlements', () => {
    test('should call getGroupSettlements controller with valid parameters', async () => {
      SettlementController.getGroupSettlements.mockImplementation((req, res) => {
        res.json({ success: true, data: [] });
      });

      const response = await request(app)
        .get('/api/groups/123/settlements')
        .expect(200);

      expect(SettlementController.getGroupSettlements).toHaveBeenCalledTimes(1);
      expect(authMiddleware.authenticateToken).toHaveBeenCalledTimes(1);
    });

    test('should reject invalid group ID', async () => {
      const response = await request(app)
        .get('/api/groups/invalid/settlements')
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Validation failed');
      expect(response.body.details).toContain("Parameter 'groupId' must be a valid integer");
    });

    test('should reject negative group ID', async () => {
      const response = await request(app)
        .get('/api/groups/-1/settlements')
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.details).toContain("Parameter 'groupId' must be at least 1");
    });
  });

  describe('GET /api/groups/:groupId/settlements/history', () => {
    test('should call getSettlementHistory with valid parameters', async () => {
      SettlementController.getSettlementHistory.mockImplementation((req, res) => {
        res.json({ success: true, data: [] });
      });

      const response = await request(app)
        .get('/api/groups/123/settlements/history?limit=10&offset=0')
        .expect(200);

      expect(SettlementController.getSettlementHistory).toHaveBeenCalledTimes(1);
    });

    test('should apply default query parameters', async () => {
      SettlementController.getSettlementHistory.mockImplementation((req, res) => {
        expect(req.query.limit).toBe(50);
        expect(req.query.offset).toBe(0);
        res.json({ success: true, data: [] });
      });

      await request(app)
        .get('/api/groups/123/settlements/history')
        .expect(200);
    });

    test('should validate query parameter ranges', async () => {
      const response = await request(app)
        .get('/api/groups/123/settlements/history?limit=200')
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.details).toContain("Query parameter 'limit' must be at most 100");
    });

    test('should validate date format', async () => {
      const response = await request(app)
        .get('/api/groups/123/settlements/history?from_date=invalid-date')
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.details).toContain("Query parameter 'from_date' must be a valid date");
    });
  });

  describe('POST /api/groups/:groupId/settlements/recalculate', () => {
    test('should call recalculateSettlements with valid data', async () => {
      SettlementController.recalculateSettlements.mockImplementation((req, res) => {
        res.json({ success: true });
      });

      const response = await request(app)
        .post('/api/groups/123/settlements/recalculate')
        .send({ cleanup_obsolete: true, cleanup_days: 7 })
        .expect(200);

      expect(SettlementController.recalculateSettlements).toHaveBeenCalledTimes(1);
    });

    test('should apply default body parameters', async () => {
      SettlementController.recalculateSettlements.mockImplementation((req, res) => {
        expect(req.body.cleanup_obsolete).toBe(true);
        expect(req.body.cleanup_days).toBe(7);
        res.json({ success: true });
      });

      await request(app)
        .post('/api/groups/123/settlements/recalculate')
        .send({})
        .expect(200);
    });

    test('should validate cleanup_days range', async () => {
      const response = await request(app)
        .post('/api/groups/123/settlements/recalculate')
        .send({ cleanup_days: 500 })
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.details).toContain("Body parameter 'cleanup_days' must be at most 365");
    });
  });

  describe('POST /api/groups/:groupId/settlements/batch-settle', () => {
    test('should call batchSettleSettlements with valid data', async () => {
      SettlementController.batchSettleSettlements.mockImplementation((req, res) => {
        res.json({ success: true });
      });

      const response = await request(app)
        .post('/api/groups/123/settlements/batch-settle')
        .send({ settlement_ids: [1, 2, 3] })
        .expect(200);

      expect(SettlementController.batchSettleSettlements).toHaveBeenCalledTimes(1);
    });

    test('should require settlement_ids array', async () => {
      const response = await request(app)
        .post('/api/groups/123/settlements/batch-settle')
        .send({})
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.details).toContain("Body parameter 'settlement_ids' is required");
    });

    test('should validate settlement_ids is array', async () => {
      const response = await request(app)
        .post('/api/groups/123/settlements/batch-settle')
        .send({ settlement_ids: "not-an-array" })
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.details).toContain("Body parameter 'settlement_ids' must be an array");
    });

    test('should validate array length limits', async () => {
      const response = await request(app)
        .post('/api/groups/123/settlements/batch-settle')
        .send({ settlement_ids: [] })
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.details).toContain("Body parameter 'settlement_ids' must have at least 1 items");
    });

    test('should validate array item types', async () => {
      const response = await request(app)
        .post('/api/groups/123/settlements/batch-settle')
        .send({ settlement_ids: [1, "invalid", 3] })
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.details).toContain("Body parameter 'settlement_ids[1]' must be a valid integer");
    });

    test('should validate array item ranges', async () => {
      const response = await request(app)
        .post('/api/groups/123/settlements/batch-settle')
        .send({ settlement_ids: [1, 0, 3] })
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.details).toContain("Body parameter 'settlement_ids[1]' must be at least 1");
    });

    test('should enforce maximum array length', async () => {
      const largeArray = Array.from({ length: 51 }, (_, i) => i + 1);
      
      const response = await request(app)
        .post('/api/groups/123/settlements/batch-settle')
        .send({ settlement_ids: largeArray })
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.details).toContain("Body parameter 'settlement_ids' must have at most 50 items");
    });
  });

  describe('GET /api/settlements/:settlementId', () => {
    test('should call getSettlementDetails with valid parameters', async () => {
      SettlementController.getSettlementDetails.mockImplementation((req, res) => {
        res.json({ success: true, data: {} });
      });

      const response = await request(app)
        .get('/api/settlements/123')
        .expect(200);

      expect(SettlementController.getSettlementDetails).toHaveBeenCalledTimes(1);
    });

    test('should reject invalid settlement ID', async () => {
      const response = await request(app)
        .get('/api/settlements/invalid')
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.details).toContain("Parameter 'settlementId' must be a valid integer");
    });
  });

  describe('GET /api/settlements/:settlementId/preview', () => {
    test('should call getSettlementPreview with valid parameters', async () => {
      SettlementController.getSettlementPreview.mockImplementation((req, res) => {
        res.json({ success: true, data: {} });
      });

      const response = await request(app)
        .get('/api/settlements/123/preview')
        .expect(200);

      expect(SettlementController.getSettlementPreview).toHaveBeenCalledTimes(1);
    });
  });

  describe('POST /api/settlements/:settlementId/settle', () => {
    test('should call settleSettlement with valid parameters', async () => {
      SettlementController.settleSettlement.mockImplementation((req, res) => {
        res.json({ success: true });
      });

      const response = await request(app)
        .post('/api/settlements/123/settle')
        .expect(200);

      expect(SettlementController.settleSettlement).toHaveBeenCalledTimes(1);
    });
  });

  describe('GET /api/groups/:groupId/settlements/statistics', () => {
    test('should call getSettlementStatistics with valid parameters', async () => {
      SettlementController.getSettlementStatistics.mockImplementation((req, res) => {
        res.json({ success: true, data: {} });
      });

      const response = await request(app)
        .get('/api/groups/123/settlements/statistics')
        .expect(200);

      expect(SettlementController.getSettlementStatistics).toHaveBeenCalledTimes(1);
    });
  });

  describe('Authentication', () => {
    test('should require authentication for all routes', async () => {
      // Mock auth middleware to reject
      authMiddleware.authenticateToken.mockImplementation((req, res, next) => {
        res.status(401).json({ error: true, message: 'Authentication required' });
      });

      const routes = [
        '/api/groups/123/settlements',
        '/api/groups/123/settlements/history',
        '/api/settlements/123',
        '/api/settlements/123/preview'
      ];

      for (const route of routes) {
        await request(app)
          .get(route)
          .expect(401);
      }

      const postRoutes = [
        '/api/groups/123/settlements/recalculate',
        '/api/groups/123/settlements/batch-settle',
        '/api/settlements/123/settle'
      ];

      for (const route of postRoutes) {
        await request(app)
          .post(route)
          .send({})
          .expect(401);
      }
    });
  });

  describe('Error Handling', () => {
    test('should handle controller errors gracefully', async () => {
      SettlementController.getGroupSettlements.mockImplementation((req, res, next) => {
        const error = new Error('Controller error');
        error.status = 500;
        next(error);
      });

      const response = await request(app)
        .get('/api/groups/123/settlements')
        .expect(500);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Internal server error');
    });

    test('should handle validation errors', async () => {
      const response = await request(app)
        .get('/api/groups/abc/settlements')
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Validation failed');
    });

    test('should handle 404 errors', async () => {
      SettlementController.getGroupSettlements.mockImplementation((req, res, next) => {
        const error = new Error('Not found');
        error.status = 404;
        next(error);
      });

      const response = await request(app)
        .get('/api/groups/123/settlements')
        .expect(404);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Resource not found');
    });

    test('should handle 403 errors', async () => {
      SettlementController.getGroupSettlements.mockImplementation((req, res, next) => {
        const error = new Error('Forbidden');
        error.status = 403;
        next(error);
      });

      const response = await request(app)
        .get('/api/groups/123/settlements')
        .expect(403);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Insufficient permissions');
    });

    test('should handle database connection errors', async () => {
      SettlementController.getGroupSettlements.mockImplementation((req, res, next) => {
        const error = new Error('Connection refused');
        error.code = 'ECONNREFUSED';
        next(error);
      });

      const response = await request(app)
        .get('/api/groups/123/settlements')
        .expect(503);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Service temporarily unavailable');
    });
  });
});