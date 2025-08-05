/**
 * Custom error classes for settlement-specific errors
 */

class SettlementError extends Error {
  constructor(message, code = 'SETTLEMENT_ERROR', statusCode = 500, details = null) {
    super(message);
    this.name = 'SettlementError';
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
    this.timestamp = new Date().toISOString();
  }

  toJSON() {
    return {
      error: true,
      name: this.name,
      message: this.message,
      code: this.code,
      statusCode: this.statusCode,
      details: this.details,
      timestamp: this.timestamp
    };
  }
}

class SettlementValidationError extends SettlementError {
  constructor(message, validationErrors = []) {
    super(message, 'SETTLEMENT_VALIDATION_ERROR', 400, validationErrors);
    this.name = 'SettlementValidationError';
    this.validationErrors = validationErrors;
  }
}

class SettlementNotFoundError extends SettlementError {
  constructor(settlementId) {
    super(`Settlement with ID ${settlementId} not found`, 'SETTLEMENT_NOT_FOUND', 404);
    this.name = 'SettlementNotFoundError';
    this.settlementId = settlementId;
  }
}

class SettlementPermissionError extends SettlementError {
  constructor(message = 'Insufficient permissions for settlement operation') {
    super(message, 'SETTLEMENT_PERMISSION_ERROR', 403);
    this.name = 'SettlementPermissionError';
  }
}

class SettlementCalculationError extends SettlementError {
  constructor(message, groupId = null) {
    super(message, 'SETTLEMENT_CALCULATION_ERROR', 500);
    this.name = 'SettlementCalculationError';
    this.groupId = groupId;
  }
}

class SettlementProcessingError extends SettlementError {
  constructor(message, settlementId = null) {
    super(message, 'SETTLEMENT_PROCESSING_ERROR', 500);
    this.name = 'SettlementProcessingError';
    this.settlementId = settlementId;
  }
}

class SettlementStateError extends SettlementError {
  constructor(message, currentState = null, expectedState = null) {
    super(message, 'SETTLEMENT_STATE_ERROR', 400);
    this.name = 'SettlementStateError';
    this.currentState = currentState;
    this.expectedState = expectedState;
  }
}

class SettlementTimeoutError extends SettlementError {
  constructor(operation = 'settlement operation', timeout = null) {
    super(`${operation} timed out`, 'SETTLEMENT_TIMEOUT_ERROR', 408);
    this.name = 'SettlementTimeoutError';
    this.operation = operation;
    this.timeout = timeout;
  }
}

class SettlementConcurrencyError extends SettlementError {
  constructor(message = 'Settlement operation failed due to concurrent modification') {
    super(message, 'SETTLEMENT_CONCURRENCY_ERROR', 409);
    this.name = 'SettlementConcurrencyError';
  }
}

class SettlementDataIntegrityError extends SettlementError {
  constructor(message, dataIssues = []) {
    super(message, 'SETTLEMENT_DATA_INTEGRITY_ERROR', 422);
    this.name = 'SettlementDataIntegrityError';
    this.dataIssues = dataIssues;
  }
}

/**
 * Error factory for creating appropriate settlement errors
 */
class SettlementErrorFactory {
  static createValidationError(message, errors = []) {
    return new SettlementValidationError(message, errors);
  }

  static createNotFoundError(settlementId) {
    return new SettlementNotFoundError(settlementId);
  }

  static createPermissionError(message) {
    return new SettlementPermissionError(message);
  }

  static createCalculationError(message, groupId) {
    return new SettlementCalculationError(message, groupId);
  }

  static createProcessingError(message, settlementId) {
    return new SettlementProcessingError(message, settlementId);
  }

  static createStateError(message, currentState, expectedState) {
    return new SettlementStateError(message, currentState, expectedState);
  }

  static createTimeoutError(operation, timeout) {
    return new SettlementTimeoutError(operation, timeout);
  }

  static createConcurrencyError(message) {
    return new SettlementConcurrencyError(message);
  }

  static createDataIntegrityError(message, dataIssues) {
    return new SettlementDataIntegrityError(message, dataIssues);
  }

  /**
   * Create error from database error
   */
  static fromDatabaseError(dbError, context = {}) {
    const { operation = 'database operation', entityId = null } = context;

    // Handle specific database error codes
    switch (dbError.code) {
      case '23503': // Foreign key violation
        return new SettlementDataIntegrityError(
          `Foreign key constraint violation in ${operation}`,
          [{ type: 'foreign_key_violation', details: dbError.detail }]
        );

      case '23505': // Unique violation
        return new SettlementDataIntegrityError(
          `Unique constraint violation in ${operation}`,
          [{ type: 'unique_violation', details: dbError.detail }]
        );

      case '23514': // Check constraint violation
        return new SettlementValidationError(
          `Check constraint violation in ${operation}`,
          [{ type: 'check_violation', details: dbError.detail }]
        );

      case '40001': // Serialization failure (deadlock)
        return new SettlementConcurrencyError(
          `Concurrent modification detected in ${operation}`
        );

      case 'ECONNREFUSED':
      case 'ENOTFOUND':
        return new SettlementError(
          'Database connection failed',
          'DATABASE_CONNECTION_ERROR',
          503
        );

      default:
        return new SettlementError(
          `Database error in ${operation}: ${dbError.message}`,
          'DATABASE_ERROR',
          500,
          { originalError: dbError.message, code: dbError.code }
        );
    }
  }

  /**
   * Create error from validation result
   */
  static fromValidationResult(validationResult, operation = 'validation') {
    if (validationResult.isValid) {
      return null;
    }

    return new SettlementValidationError(
      `Validation failed for ${operation}`,
      validationResult.errors.map(error => ({
        type: 'validation_error',
        message: error
      }))
    );
  }
}

/**
 * Error handler utility functions
 */
class SettlementErrorHandler {
  /**
   * Handle and format error for API response
   */
  static handleError(error, req = null) {
    // Log error for debugging
    console.error('Settlement error:', {
      name: error.name,
      message: error.message,
      code: error.code,
      stack: error.stack,
      url: req?.url,
      method: req?.method,
      user: req?.user?.id,
      timestamp: new Date().toISOString()
    });

    // Return formatted error response
    if (error instanceof SettlementError) {
      return {
        statusCode: error.statusCode,
        body: error.toJSON()
      };
    }

    // Handle generic errors
    return {
      statusCode: 500,
      body: {
        error: true,
        name: 'InternalServerError',
        message: 'An unexpected error occurred',
        code: 'INTERNAL_SERVER_ERROR',
        timestamp: new Date().toISOString(),
        ...(process.env.NODE_ENV === 'development' && {
          details: error.message,
          stack: error.stack
        })
      }
    };
  }

  /**
   * Express error handler middleware
   */
  static expressErrorHandler() {
    return (error, req, res, next) => {
      const { statusCode, body } = SettlementErrorHandler.handleError(error, req);
      res.status(statusCode).json(body);
    };
  }

  /**
   * Async error wrapper for route handlers
   */
  static asyncHandler(fn) {
    return (req, res, next) => {
      Promise.resolve(fn(req, res, next)).catch(next);
    };
  }

  /**
   * Validate and throw error if validation fails
   */
  static validateOrThrow(validationResult, operation = 'operation') {
    const error = SettlementErrorFactory.fromValidationResult(validationResult, operation);
    if (error) {
      throw error;
    }
  }

  /**
   * Assert condition or throw error
   */
  static assert(condition, errorFactory, ...args) {
    if (!condition) {
      throw errorFactory(...args);
    }
  }

  /**
   * Wrap database operations with error handling
   */
  static async wrapDatabaseOperation(operation, context = {}) {
    try {
      return await operation();
    } catch (error) {
      throw SettlementErrorFactory.fromDatabaseError(error, context);
    }
  }

  /**
   * Timeout wrapper for operations
   */
  static withTimeout(promise, timeoutMs, operation = 'operation') {
    return Promise.race([
      promise,
      new Promise((_, reject) => {
        setTimeout(() => {
          reject(new SettlementTimeoutError(operation, timeoutMs));
        }, timeoutMs);
      })
    ]);
  }
}

module.exports = {
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
};