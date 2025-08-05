/**
 * Simple in-memory rate limiting middleware
 * For production, consider using Redis or a dedicated rate limiting service
 */

class RateLimiter {
  constructor() {
    this.requests = new Map(); // Store requests by IP
    this.cleanupInterval = setInterval(() => this.cleanup(), 60000); // Cleanup every minute
  }

  cleanup() {
    const now = Date.now();
    for (const [ip, data] of this.requests.entries()) {
      // Remove expired entries
      data.requests = data.requests.filter(timestamp => now - timestamp < data.windowMs);
      if (data.requests.length === 0) {
        this.requests.delete(ip);
      }
    }
  }

  isAllowed(ip, windowMs, maxRequests) {
    const now = Date.now();
    
    if (!this.requests.has(ip)) {
      this.requests.set(ip, {
        requests: [now],
        windowMs
      });
      return { allowed: true, remaining: maxRequests - 1, resetTime: now + windowMs };
    }

    const data = this.requests.get(ip);
    
    // Remove expired requests
    data.requests = data.requests.filter(timestamp => now - timestamp < windowMs);
    
    if (data.requests.length >= maxRequests) {
      const oldestRequest = Math.min(...data.requests);
      const resetTime = oldestRequest + windowMs;
      return { 
        allowed: false, 
        remaining: 0, 
        resetTime,
        retryAfter: Math.ceil((resetTime - now) / 1000)
      };
    }

    data.requests.push(now);
    const remaining = maxRequests - data.requests.length;
    const oldestRequest = Math.min(...data.requests);
    const resetTime = oldestRequest + windowMs;

    return { allowed: true, remaining, resetTime };
  }

  destroy() {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }
    this.requests.clear();
  }
}

// Global rate limiter instance
const globalRateLimiter = new RateLimiter();

// Graceful shutdown
process.on('SIGTERM', () => {
  globalRateLimiter.destroy();
});

process.on('SIGINT', () => {
  globalRateLimiter.destroy();
});

/**
 * Create a rate limiting middleware
 * @param {Object} options - Rate limiting options
 * @param {number} options.windowMs - Time window in milliseconds (default: 15 minutes)
 * @param {number} options.max - Maximum number of requests per window (default: 100)
 * @param {string} options.message - Error message when rate limit is exceeded
 * @param {Function} options.keyGenerator - Function to generate rate limit key (default: uses IP)
 * @param {boolean} options.standardHeaders - Whether to send standard rate limit headers (default: true)
 * @param {boolean} options.legacyHeaders - Whether to send legacy rate limit headers (default: false)
 */
const createRateLimit = (options = {}) => {
  const {
    windowMs = 15 * 60 * 1000, // 15 minutes
    max = 100,
    message = 'Too many requests from this IP, please try again later.',
    keyGenerator = (req) => req.ip || req.connection.remoteAddress || req.socket.remoteAddress,
    standardHeaders = true,
    legacyHeaders = false
  } = options;

  return (req, res, next) => {
    try {
      const key = keyGenerator(req);
      const result = globalRateLimiter.isAllowed(key, windowMs, max);

      // Set rate limit headers
      if (standardHeaders) {
        res.set({
          'RateLimit-Limit': max,
          'RateLimit-Remaining': result.remaining,
          'RateLimit-Reset': new Date(result.resetTime).toISOString()
        });
      }

      if (legacyHeaders) {
        res.set({
          'X-RateLimit-Limit': max,
          'X-RateLimit-Remaining': result.remaining,
          'X-RateLimit-Reset': Math.ceil(result.resetTime / 1000)
        });
      }

      if (!result.allowed) {
        if (standardHeaders) {
          res.set('RateLimit-Reset', new Date(result.resetTime).toISOString());
        }
        
        if (legacyHeaders) {
          res.set('X-RateLimit-Reset', Math.ceil(result.resetTime / 1000));
        }

        const error = new Error(message);
        error.status = 429;
        error.retryAfter = result.retryAfter;
        
        return res.status(429).json({
          error: true,
          message,
          retryAfter: result.retryAfter
        });
      }

      next();
    } catch (error) {
      console.error('Rate limiting error:', error);
      // If rate limiting fails, allow the request to proceed
      next();
    }
  };
};

/**
 * Predefined rate limiters for common use cases
 */
const presets = {
  // Strict rate limiting for sensitive operations
  strict: createRateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // 5 requests per 15 minutes
    message: 'Too many requests for this sensitive operation. Please try again later.'
  }),

  // Moderate rate limiting for API endpoints
  moderate: createRateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // 100 requests per 15 minutes
    message: 'Too many API requests. Please try again later.'
  }),

  // Lenient rate limiting for general use
  lenient: createRateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 1000, // 1000 requests per 15 minutes
    message: 'Rate limit exceeded. Please try again later.'
  }),

  // Per-minute rate limiting
  perMinute: (max = 60) => createRateLimit({
    windowMs: 60 * 1000, // 1 minute
    max,
    message: `Too many requests per minute. Limit: ${max} requests per minute.`
  }),

  // Per-hour rate limiting
  perHour: (max = 1000) => createRateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max,
    message: `Too many requests per hour. Limit: ${max} requests per hour.`
  })
};

/**
 * Get rate limiting statistics
 */
const getStats = () => {
  return {
    activeIPs: globalRateLimiter.requests.size,
    totalRequests: Array.from(globalRateLimiter.requests.values())
      .reduce((total, data) => total + data.requests.length, 0)
  };
};

/**
 * Clear rate limiting data for a specific key
 */
const clearKey = (key) => {
  return globalRateLimiter.requests.delete(key);
};

/**
 * Clear all rate limiting data
 */
const clearAll = () => {
  globalRateLimiter.requests.clear();
};

module.exports = {
  createRateLimit,
  presets,
  getStats,
  clearKey,
  clearAll
};