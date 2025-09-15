const jwt = require('jsonwebtoken');
const User = require('../../src/models/User');
const Group = require('../../src/models/Group');
const GroupMember = require('../../src/models/GroupMember');

class TestHelpers {
  // Generate JWT token for testing
  static generateToken(userId) {
    return jwt.sign(
      { id: userId },
      process.env.JWT_SECRET || 'test-secret-key',
      { expiresIn: '1h' }
    );
  }

  // Create a test user
  static async createTestUser(userData = {}) {
    const defaultUser = {
      email: `test${Date.now()}@example.com`,
      password: 'Test@1234',
      first_name: 'Test',
      last_name: 'User',
      birthdate: '1990-01-01'
    };

    const user = await User.create({ ...defaultUser, ...userData });
    const token = this.generateToken(user.id);

    return { user, token };
  }

  // Create a test group
  static async createTestGroup(createdBy, groupData = {}) {
    const defaultGroup = {
      name: `Test Group ${Date.now()}`,
      description: 'Test group for testing'
    };

    const group = await Group.create({ ...defaultGroup, ...groupData }, createdBy);
    return group;
  }

  // Create a test group member
  static async createTestGroupMember(groupId, userId = null, memberData = {}) {
    const defaultMember = {
      group_id: groupId,
      user_id: userId,
      nickname: `TestUser${Date.now()}`,
      role: 'member',
      is_registered_user: !!userId
    };

    const member = await GroupMember.create({ ...defaultMember, ...memberData });
    return member;
  }

  // Create authenticated request headers
  static getAuthHeaders(token) {
    return {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };
  }

  // Clean up test data
  static async cleanupTestData() {
    const pool = require('../../src/config/db');
    
    // Clean up in proper order to avoid foreign key constraints
    await pool.query('DELETE FROM settlements');
    await pool.query('DELETE FROM payments');
    await pool.query('DELETE FROM expense_splits');
    await pool.query('DELETE FROM expense_payers');
    await pool.query('DELETE FROM assignment_users');
    await pool.query('DELETE FROM assignments');
    await pool.query('DELETE FROM items');
    await pool.query('DELETE FROM expenses');
    await pool.query('DELETE FROM group_invites');
    await pool.query('DELETE FROM group_members');
    await pool.query('DELETE FROM groups');
    await pool.query('DELETE FROM user_preferences');
    await pool.query('DELETE FROM users');
  }

  // Wait for a specified time (useful for async operations)
  static async wait(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // Generate random string
  static randomString(length = 8) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  // Generate random email
  static randomEmail() {
    return `test${this.randomString()}@example.com`;
  }

  // Mock request object for middleware testing
  static mockRequest(overrides = {}) {
    return {
      headers: {},
      body: {},
      params: {},
      query: {},
      user: null,
      ip: '127.0.0.1',
      ...overrides
    };
  }

  // Mock response object for middleware testing
  static mockResponse() {
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
      send: jest.fn().mockReturnThis(),
      cookie: jest.fn().mockReturnThis(),
      clearCookie: jest.fn().mockReturnThis(),
      locals: {}
    };
    return res;
  }

  // Mock next function for middleware testing
  static mockNext() {
    return jest.fn();
  }

  // Validate JWT token structure
  static isValidJWT(token) {
    try {
      const decoded = jwt.decode(token);
      return decoded && decoded.id && decoded.exp;
    } catch (error) {
      return false;
    }
  }

  // Create expense test data
  static async createTestExpense(groupId, createdBy, expenseData = {}) {
    const Expense = require('../../src/models/Expense');
    
    const defaultExpense = {
      title: `Test Expense ${Date.now()}`,
      total_amount: 100.00,
      currency: 'EUR',
      date: new Date().toISOString().split('T')[0],
      category: 'Food',
      group_id: groupId,
      created_by: createdBy
    };

    const expense = await Expense.create({ ...defaultExpense, ...expenseData });
    return expense;
  }

  // Assert response structure for API tests
  static assertApiResponse(response, expectedStatus = 200) {
    expect(response.status).toBe(expectedStatus);
    expect(response.body).toHaveProperty('success');
    
    if (response.body.success) {
      expect(response.body).toHaveProperty('data');
    } else {
      expect(response.body).toHaveProperty('message');
    }
  }

  // Assert error response structure
  static assertErrorResponse(response, expectedStatus, expectedMessage = null) {
    expect(response.status).toBe(expectedStatus);
    expect(response.body).toHaveProperty('success', false);
    expect(response.body).toHaveProperty('message');
    
    if (expectedMessage) {
      expect(response.body.message).toContain(expectedMessage);
    }
  }

  // Create test database connection for isolated tests
  static async createTestConnection() {
    const { Pool } = require('pg');
    
    const testPool = new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      database: process.env.DB_NAME || 'camsplit_test',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'password'
    });

    return testPool;
  }
}

module.exports = TestHelpers;