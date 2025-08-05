const { createRateLimit, presets, getStats, clearKey, clearAll } = require('../../src/middleware/rateLimit');

describe('Rate Limit Middleware', () => {
  let req, res, next;

  beforeEach(() => {
    req = {
      ip: '127.0.0.1',
      connection: { remoteAddress: '127.0.0.1' },
      socket: { remoteAddress: '127.0.0.1' }
    };
    res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
      set: jest.fn()
    };
    next = jest.fn();
    
    // Clear all rate limiting data before each test
    clearAll();
  });

  afterEach(() => {
    clearAll();
  });

  describe('createRateLimit', () => {
    test('should allow requests within limit', () => {
      const rateLimiter = createRateLimit({ windowMs: 60000, max: 5 });
      
      rateLimiter(req, res, next);
      
      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
      expect(res.set).toHaveBeenCalledWith({
        'RateLimit-Limit': 5,
        'RateLimit-Remaining': 4,
        'RateLimit-Reset': expect.any(String)
      });
    });

    test('should block requests exceeding limit', () => {
      const rateLimiter = createRateLimit({ windowMs: 60000, max: 2 });
      
      // Make requests up to the limit
      rateLimiter(req, res, next);
      rateLimiter(req, res, next);
      
      // This request should be blocked
      rateLimiter(req, res, next);
      
      expect(next).toHaveBeenCalledTimes(2);
      expect(res.status).toHaveBeenCalledWith(429);
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: 'Too many requests from this IP, please try again later.',
        retryAfter: expect.any(Number)
      });
    });

    test('should use custom message when provided', () => {
      const customMessage = 'Custom rate limit message';
      const rateLimiter = createRateLimit({ 
        windowMs: 60000, 
        max: 1, 
        message: customMessage 
      });
      
      // First request should pass
      rateLimiter(req, res, next);
      
      // Second request should be blocked with custom message
      rateLimiter(req, res, next);
      
      expect(res.json).toHaveBeenCalledWith({
        error: true,
        message: customMessage,
        retryAfter: expect.any(Number)
      });
    });

    test('should use custom key generator', () => {
      const customKeyGenerator = (req) => req.customKey || 'default';
      const rateLimiter = createRateLimit({ 
        windowMs: 60000, 
        max: 1,
        keyGenerator: customKeyGenerator
      });
      
      req.customKey = 'user123';
      
      rateLimiter(req, res, next);
      rateLimiter(req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(429);
    });

    test('should set legacy headers when enabled', () => {
      const rateLimiter = createRateLimit({ 
        windowMs: 60000, 
        max: 5,
        legacyHeaders: true
      });
      
      rateLimiter(req, res, next);
      
      expect(res.set).toHaveBeenCalledWith({
        'RateLimit-Limit': 5,
        'RateLimit-Remaining': 4,
        'RateLimit-Reset': expect.any(String)
      });
      
      expect(res.set).toHaveBeenCalledWith({
        'X-RateLimit-Limit': 5,
        'X-RateLimit-Remaining': 4,
        'X-RateLimit-Reset': expect.any(Number)
      });
    });

    test('should not set standard headers when disabled', () => {
      const rateLimiter = createRateLimit({ 
        windowMs: 60000, 
        max: 5,
        standardHeaders: false
      });
      
      rateLimiter(req, res, next);
      
      expect(res.set).not.toHaveBeenCalledWith(expect.objectContaining({
        'RateLimit-Limit': expect.any(Number)
      }));
    });

    test('should handle different IPs separately', () => {
      const rateLimiter = createRateLimit({ windowMs: 60000, max: 1 });
      
      // First IP
      req.ip = '127.0.0.1';
      rateLimiter(req, res, next);
      rateLimiter(req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(429);
      
      // Reset mocks
      res.status.mockClear();
      res.json.mockClear();
      next.mockClear();
      
      // Second IP should not be affected
      req.ip = '192.168.1.1';
      rateLimiter(req, res, next);
      
      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });

    test('should handle errors gracefully', () => {
      const rateLimiter = createRateLimit({ windowMs: 60000, max: 5 });
      
      // Simulate an error by providing invalid request object
      const invalidReq = null;
      
      rateLimiter(invalidReq, res, next);
      
      // Should call next() to allow request to proceed despite error
      expect(next).toHaveBeenCalledTimes(1);
    });
  });

  describe('Window expiration', () => {
    test('should reset count after window expires', (done) => {
      const rateLimiter = createRateLimit({ windowMs: 100, max: 1 });
      
      // First request should pass
      rateLimiter(req, res, next);
      expect(next).toHaveBeenCalledTimes(1);
      
      // Second request should be blocked
      rateLimiter(req, res, next);
      expect(res.status).toHaveBeenCalledWith(429);
      
      // Wait for window to expire
      setTimeout(() => {
        // Reset mocks
        res.status.mockClear();
        next.mockClear();
        
        // Request should pass again
        rateLimiter(req, res, next);
        expect(next).toHaveBeenCalledTimes(1);
        expect(res.status).not.toHaveBeenCalled();
        
        done();
      }, 150);
    });
  });

  describe('Presets', () => {
    test('should have strict preset', () => {
      expect(presets.strict).toBeDefined();
      expect(typeof presets.strict).toBe('function');
    });

    test('should have moderate preset', () => {
      expect(presets.moderate).toBeDefined();
      expect(typeof presets.moderate).toBe('function');
    });

    test('should have lenient preset', () => {
      expect(presets.lenient).toBeDefined();
      expect(typeof presets.lenient).toBe('function');
    });

    test('should have perMinute preset factory', () => {
      const perMinuteRateLimit = presets.perMinute(30);
      expect(typeof perMinuteRateLimit).toBe('function');
      
      perMinuteRateLimit(req, res, next);
      expect(next).toHaveBeenCalledTimes(1);
    });

    test('should have perHour preset factory', () => {
      const perHourRateLimit = presets.perHour(500);
      expect(typeof perHourRateLimit).toBe('function');
      
      perHourRateLimit(req, res, next);
      expect(next).toHaveBeenCalledTimes(1);
    });
  });

  describe('Utility functions', () => {
    test('getStats should return statistics', () => {
      const rateLimiter = createRateLimit({ windowMs: 60000, max: 5 });
      
      rateLimiter(req, res, next);
      
      const stats = getStats();
      expect(stats).toHaveProperty('activeIPs');
      expect(stats).toHaveProperty('totalRequests');
      expect(stats.activeIPs).toBe(1);
      expect(stats.totalRequests).toBe(1);
    });

    test('clearKey should remove specific IP data', () => {
      const rateLimiter = createRateLimit({ windowMs: 60000, max: 1 });
      
      rateLimiter(req, res, next);
      rateLimiter(req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(429);
      
      // Clear the key
      const cleared = clearKey('127.0.0.1');
      expect(cleared).toBe(true);
      
      // Reset mocks
      res.status.mockClear();
      next.mockClear();
      
      // Request should pass again
      rateLimiter(req, res, next);
      expect(next).toHaveBeenCalledTimes(1);
      expect(res.status).not.toHaveBeenCalled();
    });

    test('clearKey should return false for non-existent key', () => {
      const cleared = clearKey('non-existent-ip');
      expect(cleared).toBe(false);
    });

    test('clearAll should remove all rate limiting data', () => {
      const rateLimiter = createRateLimit({ windowMs: 60000, max: 5 });
      
      rateLimiter(req, res, next);
      
      let stats = getStats();
      expect(stats.activeIPs).toBe(1);
      
      clearAll();
      
      stats = getStats();
      expect(stats.activeIPs).toBe(0);
      expect(stats.totalRequests).toBe(0);
    });
  });

  describe('IP address resolution', () => {
    test('should use req.ip when available', () => {
      const rateLimiter = createRateLimit({ windowMs: 60000, max: 1 });
      
      req.ip = '192.168.1.100';
      delete req.connection;
      delete req.socket;
      
      rateLimiter(req, res, next);
      rateLimiter(req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(429);
    });

    test('should fallback to connection.remoteAddress', () => {
      const rateLimiter = createRateLimit({ windowMs: 60000, max: 1 });
      
      delete req.ip;
      req.connection.remoteAddress = '192.168.1.101';
      delete req.socket;
      
      rateLimiter(req, res, next);
      rateLimiter(req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(429);
    });

    test('should fallback to socket.remoteAddress', () => {
      const rateLimiter = createRateLimit({ windowMs: 60000, max: 1 });
      
      delete req.ip;
      delete req.connection;
      req.socket.remoteAddress = '192.168.1.102';
      
      rateLimiter(req, res, next);
      rateLimiter(req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(429);
    });
  });

  describe('Remaining count accuracy', () => {
    test('should accurately track remaining requests', () => {
      const rateLimiter = createRateLimit({ windowMs: 60000, max: 3 });
      
      // First request
      rateLimiter(req, res, next);
      expect(res.set).toHaveBeenCalledWith(expect.objectContaining({
        'RateLimit-Remaining': 2
      }));
      
      // Second request
      rateLimiter(req, res, next);
      expect(res.set).toHaveBeenCalledWith(expect.objectContaining({
        'RateLimit-Remaining': 1
      }));
      
      // Third request
      rateLimiter(req, res, next);
      expect(res.set).toHaveBeenCalledWith(expect.objectContaining({
        'RateLimit-Remaining': 0
      }));
      
      // Fourth request should be blocked
      rateLimiter(req, res, next);
      expect(res.status).toHaveBeenCalledWith(429);
    });
  });
});