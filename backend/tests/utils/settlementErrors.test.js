const {
  SettlementError,
  SettlementValidationError,
  SettlementNotFoundError,
  SettlementPermissionError,
  SettlementCalculationError,
  SettlementProcessingError,
  SettlementStateError,
  SettlementTimeoutError,
  SettlementConcurrencyError,
  SettlementDataIntegrityError,
  SettlementErrorFactory,
  SettlementErrorHandler
} = require('../../src/utils/settlementErrors');

describe('Settlement Errors', () => {
  describe('SettlementError', () => {
    test('should create basic settlement error', () => {
      const error = new SettlementError('Test error');
      
      expect(error.name).toBe('SettlementError');
      expect(error.message).toBe('Test error');
      expect(error.code).toBe('SETTLEMENT_ERROR');
      expect(error.statusCode).toBe(500);
      expect(error.timestamp).toBeDefined();
    });

    test('should create settlement error with custom properties', () => {
      const error = new SettlementError(
        'Custom error',
        'CUSTOM_CODE',
        400,
        { custom: 'details' }
      );
      
      expect(error.code).toBe('CUSTOM_CODE');
      expect(error.statusCode).toBe(400);
      expect(error.details).toEqual({ custom: 'details' });
    });

    test('should serialize to JSON correctly', () => {
      const error = new SettlementError('Test error', 'TEST_CODE', 400);
      const json = error.toJSON();
      
      expect(json).toEqual({
        error: true,
        name: 'SettlementError',
        message: 'Test error',
        code: 'TEST_CODE',
        statusCode: 400,
        details: null,
        timestamp: expect.any(String)
      });
    });
  });

  describe('SettlementValidationError', () => {
    test('should create validation error with errors array', () => {
      const validationErrors = ['Field is required', 'Invalid format'];
      const error = new SettlementValidationError('Validation failed', validationErrors);
      
      expect(error.name).toBe('SettlementValidationError');
      expect(error.statusCode).toBe(400);
      expect(error.code).toBe('SETTLEMENT_VALIDATION_ERROR');
      expect(error.validationErrors).toEqual(validationErrors);
      expect(error.details).toEqual(validationErrors);
    });
  });

  describe('SettlementNotFoundError', () => {
    test('should create not found error with settlement ID', () => {
      const error = new SettlementNotFoundError(123);
      
      expect(error.name).toBe('SettlementNotFoundError');
      expect(error.message).toBe('Settlement with ID 123 not found');
      expect(error.statusCode).toBe(404);
      expect(error.code).toBe('SETTLEMENT_NOT_FOUND');
      expect(error.settlementId).toBe(123);
    });
  });

  describe('SettlementPermissionError', () => {
    test('should create permission error with default message', () => {
      const error = new SettlementPermissionError();
      
      expect(error.name).toBe('SettlementPermissionError');
      expect(error.message).toBe('Insufficient permissions for settlement operation');
      expect(error.statusCode).toBe(403);
      expect(error.code).toBe('SETTLEMENT_PERMISSION_ERROR');
    });

    test('should create permission error with custom message', () => {
      const error = new SettlementPermissionError('Custom permission error');
      
      expect(error.message).toBe('Custom permission error');
    });
  });

  describe('SettlementCalculationError', () => {
    test('should create calculation error', () => {
      const error = new SettlementCalculationError('Calculation failed', 123);
      
      expect(error.name).toBe('SettlementCalculationError');
      expect(error.message).toBe('Calculation failed');
      expect(error.statusCode).toBe(500);
      expect(error.code).toBe('SETTLEMENT_CALCULATION_ERROR');
      expect(error.groupId).toBe(123);
    });
  });

  describe('SettlementProcessingError', () => {
    test('should create processing error', () => {
      const error = new SettlementProcessingError('Processing failed', 456);
      
      expect(error.name).toBe('SettlementProcessingError');
      expect(error.message).toBe('Processing failed');
      expect(error.statusCode).toBe(500);
      expect(error.code).toBe('SETTLEMENT_PROCESSING_ERROR');
      expect(error.settlementId).toBe(456);
    });
  });

  describe('SettlementStateError', () => {
    test('should create state error', () => {
      const error = new SettlementStateError('Invalid state', 'settled', 'active');
      
      expect(error.name).toBe('SettlementStateError');
      expect(error.message).toBe('Invalid state');
      expect(error.statusCode).toBe(400);
      expect(error.code).toBe('SETTLEMENT_STATE_ERROR');
      expect(error.currentState).toBe('settled');
      expect(error.expectedState).toBe('active');
    });
  });

  describe('SettlementTimeoutError', () => {
    test('should create timeout error', () => {
      const error = new SettlementTimeoutError('calculation', 5000);
      
      expect(error.name).toBe('SettlementTimeoutError');
      expect(error.message).toBe('calculation timed out');
      expect(error.statusCode).toBe(408);
      expect(error.code).toBe('SETTLEMENT_TIMEOUT_ERROR');
      expect(error.operation).toBe('calculation');
      expect(error.timeout).toBe(5000);
    });
  });

  describe('SettlementConcurrencyError', () => {
    test('should create concurrency error', () => {
      const error = new SettlementConcurrencyError('Concurrent modification');
      
      expect(error.name).toBe('SettlementConcurrencyError');
      expect(error.message).toBe('Concurrent modification');
      expect(error.statusCode).toBe(409);
      expect(error.code).toBe('SETTLEMENT_CONCURRENCY_ERROR');
    });
  });

  describe('SettlementDataIntegrityError', () => {
    test('should create data integrity error', () => {
      const dataIssues = [{ type: 'foreign_key', field: 'group_id' }];
      const error = new SettlementDataIntegrityError('Data integrity violation', dataIssues);
      
      expect(error.name).toBe('SettlementDataIntegrityError');
      expect(error.message).toBe('Data integrity violation');
      expect(error.statusCode).toBe(422);
      expect(error.code).toBe('SETTLEMENT_DATA_INTEGRITY_ERROR');
      expect(error.dataIssues).toEqual(dataIssues);
    });
  });
});

describe('SettlementErrorFactory', () => {
  test('should create validation error', () => {
    const error = SettlementErrorFactory.createValidationError('Validation failed', ['Error 1']);
    
    expect(error).toBeInstanceOf(SettlementValidationError);
    expect(error.message).toBe('Validation failed');
    expect(error.validationErrors).toEqual(['Error 1']);
  });

  test('should create not found error', () => {
    const error = SettlementErrorFactory.createNotFoundError(123);
    
    expect(error).toBeInstanceOf(SettlementNotFoundError);
    expect(error.settlementId).toBe(123);
  });

  test('should create permission error', () => {
    const error = SettlementErrorFactory.createPermissionError('Access denied');
    
    expect(error).toBeInstanceOf(SettlementPermissionError);
    expect(error.message).toBe('Access denied');
  });

  test('should create calculation error', () => {
    const error = SettlementErrorFactory.createCalculationError('Calc failed', 123);
    
    expect(error).toBeInstanceOf(SettlementCalculationError);
    expect(error.groupId).toBe(123);
  });

  test('should create processing error', () => {
    const error = SettlementErrorFactory.createProcessingError('Process failed', 456);
    
    expect(error).toBeInstanceOf(SettlementProcessingError);
    expect(error.settlementId).toBe(456);
  });

  test('should create state error', () => {
    const error = SettlementErrorFactory.createStateError('Bad state', 'settled', 'active');
    
    expect(error).toBeInstanceOf(SettlementStateError);
    expect(error.currentState).toBe('settled');
    expect(error.expectedState).toBe('active');
  });

  test('should create timeout error', () => {
    const error = SettlementErrorFactory.createTimeoutError('operation', 1000);
    
    expect(error).toBeInstanceOf(SettlementTimeoutError);
    expect(error.operation).toBe('operation');
    expect(error.timeout).toBe(1000);
  });

  test('should create concurrency error', () => {
    const error = SettlementErrorFactory.createConcurrencyError('Concurrent access');
    
    expect(error).toBeInstanceOf(SettlementConcurrencyError);
    expect(error.message).toBe('Concurrent access');
  });

  test('should create data integrity error', () => {
    const issues = [{ type: 'constraint' }];
    const error = SettlementErrorFactory.createDataIntegrityError('Integrity error', issues);
    
    expect(error).toBeInstanceOf(SettlementDataIntegrityError);
    expect(error.dataIssues).toEqual(issues);
  });

  describe('fromDatabaseError', () => {
    test('should handle foreign key violation', () => {
      const dbError = {
        code: '23503',
        detail: 'Key (group_id)=(123) is not present in table "groups".'
      };
      
      const error = SettlementErrorFactory.fromDatabaseError(dbError, {
        operation: 'create settlement'
      });
      
      expect(error).toBeInstanceOf(SettlementDataIntegrityError);
      expect(error.message).toContain('Foreign key constraint violation');
    });

    test('should handle unique violation', () => {
      const dbError = {
        code: '23505',
        detail: 'Key (id)=(123) already exists.'
      };
      
      const error = SettlementErrorFactory.fromDatabaseError(dbError);
      
      expect(error).toBeInstanceOf(SettlementDataIntegrityError);
      expect(error.message).toContain('Unique constraint violation');
    });

    test('should handle check constraint violation', () => {
      const dbError = {
        code: '23514',
        detail: 'Check constraint "amount_positive" violated.'
      };
      
      const error = SettlementErrorFactory.fromDatabaseError(dbError);
      
      expect(error).toBeInstanceOf(SettlementValidationError);
      expect(error.message).toContain('Check constraint violation');
    });

    test('should handle serialization failure', () => {
      const dbError = {
        code: '40001',
        message: 'could not serialize access due to concurrent update'
      };
      
      const error = SettlementErrorFactory.fromDatabaseError(dbError);
      
      expect(error).toBeInstanceOf(SettlementConcurrencyError);
      expect(error.message).toContain('Concurrent modification detected');
    });

    test('should handle connection errors', () => {
      const dbError = {
        code: 'ECONNREFUSED',
        message: 'Connection refused'
      };
      
      const error = SettlementErrorFactory.fromDatabaseError(dbError);
      
      expect(error).toBeInstanceOf(SettlementError);
      expect(error.statusCode).toBe(503);
      expect(error.message).toBe('Database connection failed');
    });

    test('should handle generic database errors', () => {
      const dbError = {
        code: 'UNKNOWN',
        message: 'Unknown database error'
      };
      
      const error = SettlementErrorFactory.fromDatabaseError(dbError, {
        operation: 'test operation'
      });
      
      expect(error).toBeInstanceOf(SettlementError);
      expect(error.message).toContain('Database error in test operation');
      expect(error.details.originalError).toBe('Unknown database error');
    });
  });

  describe('fromValidationResult', () => {
    test('should return null for valid result', () => {
      const validationResult = { isValid: true, errors: [] };
      const error = SettlementErrorFactory.fromValidationResult(validationResult);
      
      expect(error).toBeNull();
    });

    test('should create validation error for invalid result', () => {
      const validationResult = {
        isValid: false,
        errors: ['Field is required', 'Invalid format']
      };
      
      const error = SettlementErrorFactory.fromValidationResult(validationResult, 'test validation');
      
      expect(error).toBeInstanceOf(SettlementValidationError);
      expect(error.message).toBe('Validation failed for test validation');
      expect(error.validationErrors).toHaveLength(2);
    });
  });
});

describe('SettlementErrorHandler', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      url: '/test',
      method: 'GET',
      user: { id: 1 }
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    next = jest.fn();
  });

  describe('handleError', () => {
    test('should handle settlement error', () => {
      const error = new SettlementValidationError('Validation failed', ['Error 1']);
      const result = SettlementErrorHandler.handleError(error, req);
      
      expect(result.statusCode).toBe(400);
      expect(result.body.error).toBe(true);
      expect(result.body.name).toBe('SettlementValidationError');
      expect(result.body.message).toBe('Validation failed');
    });

    test('should handle generic error', () => {
      const error = new Error('Generic error');
      const result = SettlementErrorHandler.handleError(error, req);
      
      expect(result.statusCode).toBe(500);
      expect(result.body.error).toBe(true);
      expect(result.body.name).toBe('InternalServerError');
      expect(result.body.message).toBe('An unexpected error occurred');
    });

    test('should include debug info in development', () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development';
      
      const error = new Error('Generic error');
      const result = SettlementErrorHandler.handleError(error, req);
      
      expect(result.body.details).toBe('Generic error');
      expect(result.body.stack).toBeDefined();
      
      process.env.NODE_ENV = originalEnv;
    });
  });

  describe('expressErrorHandler', () => {
    test('should create express error handler middleware', () => {
      const middleware = SettlementErrorHandler.expressErrorHandler();
      expect(typeof middleware).toBe('function');
      
      const error = new SettlementNotFoundError(123);
      middleware(error, req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(404);
      expect(res.json).toHaveBeenCalledWith(expect.objectContaining({
        error: true,
        name: 'SettlementNotFoundError'
      }));
    });
  });

  describe('asyncHandler', () => {
    test('should wrap async function and catch errors', async () => {
      const asyncFn = jest.fn().mockRejectedValue(new Error('Async error'));
      const wrappedFn = SettlementErrorHandler.asyncHandler(asyncFn);
      
      await wrappedFn(req, res, next);
      
      expect(next).toHaveBeenCalledWith(expect.any(Error));
    });

    test('should pass through successful async function', async () => {
      const asyncFn = jest.fn().mockResolvedValue('success');
      const wrappedFn = SettlementErrorHandler.asyncHandler(asyncFn);
      
      await wrappedFn(req, res, next);
      
      expect(asyncFn).toHaveBeenCalledWith(req, res, next);
      expect(next).not.toHaveBeenCalled();
    });
  });

  describe('validateOrThrow', () => {
    test('should not throw for valid result', () => {
      const validationResult = { isValid: true, errors: [] };
      
      expect(() => {
        SettlementErrorHandler.validateOrThrow(validationResult);
      }).not.toThrow();
    });

    test('should throw for invalid result', () => {
      const validationResult = { isValid: false, errors: ['Error'] };
      
      expect(() => {
        SettlementErrorHandler.validateOrThrow(validationResult, 'test');
      }).toThrow(SettlementValidationError);
    });
  });

  describe('assert', () => {
    test('should not throw for truthy condition', () => {
      expect(() => {
        SettlementErrorHandler.assert(true, SettlementErrorFactory.createNotFoundError, 123);
      }).not.toThrow();
    });

    test('should throw for falsy condition', () => {
      expect(() => {
        SettlementErrorHandler.assert(false, SettlementErrorFactory.createNotFoundError, 123);
      }).toThrow(SettlementNotFoundError);
    });
  });

  describe('wrapDatabaseOperation', () => {
    test('should return result for successful operation', async () => {
      const operation = jest.fn().mockResolvedValue('success');
      
      const result = await SettlementErrorHandler.wrapDatabaseOperation(operation);
      
      expect(result).toBe('success');
    });

    test('should wrap database error', async () => {
      const dbError = { code: '23503', detail: 'Foreign key violation' };
      const operation = jest.fn().mockRejectedValue(dbError);
      
      await expect(
        SettlementErrorHandler.wrapDatabaseOperation(operation, { operation: 'test' })
      ).rejects.toThrow(SettlementDataIntegrityError);
    });
  });

  describe('withTimeout', () => {
    test('should resolve if promise completes within timeout', async () => {
      const promise = Promise.resolve('success');
      
      const result = await SettlementErrorHandler.withTimeout(promise, 1000);
      
      expect(result).toBe('success');
    });

    test('should reject with timeout error if promise takes too long', async () => {
      const promise = new Promise(resolve => setTimeout(() => resolve('success'), 200));
      
      await expect(
        SettlementErrorHandler.withTimeout(promise, 100, 'test operation')
      ).rejects.toThrow(SettlementTimeoutError);
    });
  });
});