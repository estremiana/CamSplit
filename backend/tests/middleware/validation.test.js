const { validateParams, validateQuery, validateBody } = require('../../src/middleware/validation');

describe('Validation Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      params: {},
      query: {},
      body: {}
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    next = jest.fn();
  });

  describe('validateParams', () => {
    test('should validate required integer parameter', () => {
      const schema = {
        id: { type: 'integer', required: true, minimum: 1 }
      };
      req.params = { id: '123' };

      const middleware = validateParams(schema);
      middleware(req, res, next);

      expect(req.params.id).toBe(123);
      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });

    test('should reject missing required parameter', () => {
      const schema = {
        id: { type: 'integer', required: true }
      };
      req.params = {};

      const middleware = validateParams(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: ["Parameter 'id' is required"]
      });
      expect(next).not.toHaveBeenCalled();
    });

    test('should reject invalid integer parameter', () => {
      const schema = {
        id: { type: 'integer', required: true }
      };
      req.params = { id: 'abc' };

      const middleware = validateParams(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: ["Parameter 'id' must be a valid integer"]
      });
    });

    test('should validate integer range', () => {
      const schema = {
        id: { type: 'integer', required: true, minimum: 10, maximum: 100 }
      };
      req.params = { id: '5' };

      const middleware = validateParams(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: ["Parameter 'id' must be at least 10"]
      });
    });

    test('should validate string parameter', () => {
      const schema = {
        name: { type: 'string', required: true, minLength: 3, maxLength: 10 }
      };
      req.params = { name: 'test' };

      const middleware = validateParams(schema);
      middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });

    test('should reject string length violations', () => {
      const schema = {
        name: { type: 'string', required: true, minLength: 5 }
      };
      req.params = { name: 'ab' };

      const middleware = validateParams(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: ["Parameter 'name' must be at least 5 characters long"]
      });
    });

    test('should skip validation for optional missing parameters', () => {
      const schema = {
        id: { type: 'integer', required: false }
      };
      req.params = {};

      const middleware = validateParams(schema);
      middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });
  });

  describe('validateQuery', () => {
    test('should apply default values', () => {
      const schema = {
        limit: { type: 'integer', default: 10 },
        offset: { type: 'integer', default: 0 }
      };
      req.query = {};

      const middleware = validateQuery(schema);
      middleware(req, res, next);

      expect(req.query.limit).toBe(10);
      expect(req.query.offset).toBe(0);
      expect(next).toHaveBeenCalledTimes(1);
    });

    test('should validate date format', () => {
      const schema = {
        date: { type: 'string', format: 'date', optional: true }
      };
      req.query = { date: '2023-12-25' };

      const middleware = validateQuery(schema);
      middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });

    test('should reject invalid date format', () => {
      const schema = {
        date: { type: 'string', format: 'date', optional: true }
      };
      req.query = { date: 'invalid-date' };

      const middleware = validateQuery(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: ["Query parameter 'date' must be a valid date"]
      });
    });

    test('should validate integer ranges in query', () => {
      const schema = {
        limit: { type: 'integer', minimum: 1, maximum: 100 }
      };
      req.query = { limit: '200' };

      const middleware = validateQuery(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: ["Query parameter 'limit' must be at most 100"]
      });
    });
  });

  describe('validateBody', () => {
    test('should validate array with items', () => {
      const schema = {
        ids: {
          type: 'array',
          required: true,
          minItems: 1,
          maxItems: 5,
          items: { type: 'integer', minimum: 1 }
        }
      };
      req.body = { ids: ['1', '2', '3'] };

      const middleware = validateBody(schema);
      middleware(req, res, next);

      expect(req.body.ids).toEqual([1, 2, 3]);
      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });

    test('should reject non-array when array expected', () => {
      const schema = {
        ids: { type: 'array', required: true }
      };
      req.body = { ids: 'not-an-array' };

      const middleware = validateBody(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: ["Body parameter 'ids' must be an array"]
      });
    });

    test('should validate array length', () => {
      const schema = {
        ids: { type: 'array', required: true, minItems: 2 }
      };
      req.body = { ids: [1] };

      const middleware = validateBody(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: ["Body parameter 'ids' must have at least 2 items"]
      });
    });

    test('should validate array item types', () => {
      const schema = {
        ids: {
          type: 'array',
          required: true,
          items: { type: 'integer', minimum: 1 }
        }
      };
      req.body = { ids: [1, 'invalid', 3] };

      const middleware = validateBody(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: ["Body parameter 'ids[1]' must be a valid integer"]
      });
    });

    test('should validate array item ranges', () => {
      const schema = {
        ids: {
          type: 'array',
          required: true,
          items: { type: 'integer', minimum: 1, maximum: 10 }
        }
      };
      req.body = { ids: [1, 15, 3] };

      const middleware = validateBody(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: ["Body parameter 'ids[1]' must be at most 10"]
      });
    });

    test('should validate boolean values', () => {
      const schema = {
        enabled: { type: 'boolean', required: true }
      };
      req.body = { enabled: true };

      const middleware = validateBody(schema);
      middleware(req, res, next);

      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });

    test('should parse string boolean values', () => {
      const schema = {
        enabled: { type: 'boolean', required: true }
      };
      req.body = { enabled: 'true' };

      const middleware = validateBody(schema);
      middleware(req, res, next);

      expect(req.body.enabled).toBe(true);
      expect(next).toHaveBeenCalledTimes(1);
    });

    test('should reject invalid boolean values', () => {
      const schema = {
        enabled: { type: 'boolean', required: true }
      };
      req.body = { enabled: 'maybe' };

      const middleware = validateBody(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: ["Body parameter 'enabled' must be a boolean"]
      });
    });

    test('should apply default values for body parameters', () => {
      const schema = {
        limit: { type: 'integer', default: 10 },
        enabled: { type: 'boolean', default: true }
      };
      req.body = {};

      const middleware = validateBody(schema);
      middleware(req, res, next);

      expect(req.body.limit).toBe(10);
      expect(req.body.enabled).toBe(true);
      expect(next).toHaveBeenCalledTimes(1);
    });
  });

  describe('Error Handling', () => {
    test('should handle validation errors gracefully', () => {
      const schema = {
        id: { type: 'integer', required: true }
      };
      
      // Mock a scenario that would cause an error in validation logic
      req.params = null;

      const middleware = validateParams(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation error',
        details: expect.any(String)
      });
    });
  });

  describe('Multiple Validation Errors', () => {
    test('should collect multiple validation errors', () => {
      const schema = {
        id: { type: 'integer', required: true, minimum: 10 },
        name: { type: 'string', required: true, minLength: 5 }
      };
      req.params = { id: '5', name: 'ab' };

      const middleware = validateParams(schema);
      middleware(req, res, next);

      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Validation failed',
        details: [
          "Parameter 'id' must be at least 10",
          "Parameter 'name' must be at least 5 characters long"
        ]
      });
    });
  });
});