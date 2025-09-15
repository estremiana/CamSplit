const request = require('supertest');
const app = require('../../src/app');
const db = require('../../database/connection');
const User = require('../../src/models/User');
const Group = require('../../src/models/Group');
const GroupMember = require('../../src/models/GroupMember');
const Settlement = require('../../src/models/Settlement');
const Expense = require('../../src/models/Expense');
const jwt = require('jsonwebtoken');

describe('Settlement Controller', () => {
  let testUsers, testGroup, testMembers, authTokens;

  beforeAll(async () => {
    // Create test users
    testUsers = [];
    authTokens = [];
    
    for (let i = 1; i <= 4; i++) {
      const user = await User.create({
        first_name: `User${i}`,
        last_name: `Test`,
        email: `user${i}.settlement.controller@test.com`,
        password: 'Test@1234'
      });
      testUsers.push(user);
      
      // Create auth token
      const token = jwt.sign(
        { id: user.id, email: user.email },
        process.env.JWT_SECRET || 'test-secret',
        { expiresIn: '1h' }
      );
      authTokens.push(token);
    }

    // Create test group
    testGroup = await Group.create({
      name: 'Settlement Controller Test Group',
      description: 'Test group for settlement controller'
    }, testUsers[0].id);

    // Add members to group
    testMembers = [];
    for (let i = 0; i < testUsers.length; i++) {
      const member = await GroupMember.create({
        group_id: testGroup.id,
        user_id: testUsers[i].id,
        nickname: `User${i + 1}`,
        role: i === 0 ? 'admin' : 'member'
      });
      testMembers.push(member);
    }
  });

  afterAll(async () => {
    // Clean up test data
    await db.query('DELETE FROM expense_splits WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [testGroup.id]);
    await db.query('DELETE FROM expense_payers WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [testGroup.id]);
    await db.query('DELETE FROM expenses WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM settlements WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM group_members WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM groups WHERE id = $1', [testGroup.id]);
    await db.query('DELETE FROM users WHERE id = ANY($1)', [testUsers.map(u => u.id)]);
  });

  afterEach(async () => {
    // Clean up after each test
    await db.query('DELETE FROM expense_splits WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [testGroup.id]);
    await db.query('DELETE FROM expense_payers WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [testGroup.id]);
    await db.query('DELETE FROM expenses WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM settlements WHERE group_id = $1', [testGroup.id]);
  });

  describe('GET /api/groups/:groupId/settlements', () => {
    test('should get active settlements for group member', async () => {
      // Create test settlements
      const settlement1 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 50.00,
        status: 'active'
      });

      const settlement2 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[2].id,
        to_group_member_id: testMembers[0].id,
        amount: 30.00,
        status: 'active'
      });

      const response = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(response.body.error).toBe(false);
      expect(response.body.message).toBe('Settlements retrieved successfully');
      expect(response.body.data.settlements).toHaveLength(2);
      expect(response.body.data.metadata.settlement_count).toBe(2);
      expect(response.body.data.metadata.total_amount).toBe(80.00);
      expect(response.body.data.group.name).toBe(testGroup.name);
    });

    test('should return empty settlements for group with no debts', async () => {
      const response = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(response.body.error).toBe(false);
      expect(response.body.data.settlements).toHaveLength(0);
      expect(response.body.data.metadata.settlement_count).toBe(0);
      expect(response.body.data.metadata.total_amount).toBe(0);
    });

    test('should reject non-member access', async () => {
      // Create a user not in the group
      const outsideUser = await User.create({
        first_name: 'Outside',
        last_name: 'User',
        email: 'outside@test.com',
        password: 'Test@1234'
      });

      const outsideToken = jwt.sign(
        { id: outsideUser.id, email: outsideUser.email },
        process.env.JWT_SECRET || 'test-secret',
        { expiresIn: '1h' }
      );

      const response = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${outsideToken}`)
        .expect(403);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('You must be a member of the group to view settlements');

      // Clean up
      await db.query('DELETE FROM users WHERE id = $1', [outsideUser.id]);
    });

    test('should return 404 for non-existent group', async () => {
      const response = await request(app)
        .get('/api/groups/99999/settlements')
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(404);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Group not found');
    });

    test('should require authentication', async () => {
      await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .expect(401);
    });
  });

  describe('POST /api/settlements/:settlementId/settle', () => {
    let testSettlement;

    beforeEach(async () => {
      testSettlement = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 75.00,
        status: 'active'
      });
    });

    test('should settle settlement by involved user', async () => {
      const response = await request(app)
        .post(`/api/settlements/${testSettlement.id}/settle`)
        .set('Authorization', `Bearer ${authTokens[1]}`) // User2 (debtor)
        .expect(200);

      expect(response.body.error).toBe(false);
      expect(response.body.message).toBe('Settlement processed successfully');
      expect(response.body.data.settlement.status).toBe('settled');
      expect(response.body.data.settlement.settled_by).toBe(testUsers[1].id);
      expect(response.body.data.expense).toBeDefined();
      expect(response.body.data.expense.title).toContain('Settlement: User2 → User1');
      expect(response.body.data.processing_info.processed_by).toBe(testUsers[1].id);
    });

    test('should settle settlement by group admin', async () => {
      const response = await request(app)
        .post(`/api/settlements/${testSettlement.id}/settle`)
        .set('Authorization', `Bearer ${authTokens[0]}`) // User1 (admin)
        .expect(200);

      expect(response.body.error).toBe(false);
      expect(response.body.data.settlement.status).toBe('settled');
      expect(response.body.data.settlement.settled_by).toBe(testUsers[0].id);
    });

    test('should reject settlement by unauthorized user', async () => {
      const response = await request(app)
        .post(`/api/settlements/${testSettlement.id}/settle`)
        .set('Authorization', `Bearer ${authTokens[3]}`) // User4 (not involved)
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Settlement cannot be processed');
      expect(response.body.errors).toContain('You do not have permission to settle this debt');
    });

    test('should reject already settled settlement', async () => {
      // First settle the settlement
      await testSettlement.markAsSettled(testUsers[1].id);

      const response = await request(app)
        .post(`/api/settlements/${testSettlement.id}/settle`)
        .set('Authorization', `Bearer ${authTokens[1]}`)
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Settlement cannot be processed');
      expect(response.body.errors).toContain('Settlement is not active');
    });

    test('should return 404 for non-existent settlement', async () => {
      const response = await request(app)
        .post('/api/settlements/99999/settle')
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.errors).toContain('Settlement not found');
    });
  });

  describe('GET /api/groups/:groupId/settlements/history', () => {
    beforeEach(async () => {
      // Create and settle some settlements for history
      const settlement1 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 50.00,
        status: 'active'
      });

      const settlement2 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[2].id,
        to_group_member_id: testMembers[0].id,
        amount: 30.00,
        status: 'active'
      });

      await settlement1.markAsSettled(testUsers[1].id);
      await settlement2.markAsSettled(testUsers[2].id);
    });

    test('should get settlement history for group member', async () => {
      const response = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements/history`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(response.body.error).toBe(false);
      expect(response.body.message).toBe('Settlement history retrieved successfully');
      expect(response.body.data.history).toHaveLength(2);
      expect(response.body.data.pagination.total).toBe(2);
      expect(response.body.data.statistics).toBeDefined();
      expect(response.body.data.group.name).toBe(testGroup.name);
    });

    test('should support pagination', async () => {
      const response = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements/history?limit=1&offset=0`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(response.body.data.history).toHaveLength(1);
      expect(response.body.data.pagination.limit).toBe(1);
      expect(response.body.data.pagination.offset).toBe(0);
    });

    test('should reject non-member access', async () => {
      const outsideUser = await User.create({
        first_name: 'Outside',
        last_name: 'User',
        email: 'outside.history@test.com',
        password: 'Test@1234'
      });

      const outsideToken = jwt.sign(
        { id: outsideUser.id, email: outsideUser.email },
        process.env.JWT_SECRET || 'test-secret',
        { expiresIn: '1h' }
      );

      const response = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements/history`)
        .set('Authorization', `Bearer ${outsideToken}`)
        .expect(403);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('You must be a member of the group to view settlement history');

      await db.query('DELETE FROM users WHERE id = $1', [outsideUser.id]);
    });
  });

  describe('POST /api/groups/:groupId/settlements/recalculate', () => {
    beforeEach(async () => {
      // Create an expense to generate settlements
      const expense = await Expense.create({
        title: 'Test Expense',
        amount: 100.00,
        currency: 'EUR',
        group_id: testGroup.id,
        created_by: testUsers[0].id
      });

      // Add payer
      await db.query(
        'INSERT INTO expense_payers (expense_id, group_member_id, amount_paid) VALUES ($1, $2, $3)',
        [expense.id, testMembers[0].id, 100.00]
      );

      // Add splits
      for (let i = 0; i < 4; i++) {
        await db.query(
          'INSERT INTO expense_splits (expense_id, group_member_id, amount_owed, split_type) VALUES ($1, $2, $3, $4)',
          [expense.id, testMembers[i].id, 25.00, 'equal']
        );
      }
    });

    test('should recalculate settlements by group admin', async () => {
      const response = await request(app)
        .post(`/api/groups/${testGroup.id}/settlements/recalculate`)
        .set('Authorization', `Bearer ${authTokens[0]}`) // Admin
        .send({ cleanup_obsolete: true, cleanup_days: 7 })
        .expect(200);

      expect(response.body.error).toBe(false);
      expect(response.body.message).toBe('Settlements recalculated successfully');
      expect(response.body.data.settlements).toHaveLength(3);
      expect(response.body.data.summary.total_settlements).toBe(3);
      expect(response.body.data.recalculated_by).toBe(testUsers[0].id);
    });

    test('should reject recalculation by non-admin', async () => {
      const response = await request(app)
        .post(`/api/groups/${testGroup.id}/settlements/recalculate`)
        .set('Authorization', `Bearer ${authTokens[1]}`) // Non-admin
        .expect(403);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Only group administrators can recalculate settlements');
    });

    test('should return 404 for non-existent group', async () => {
      const response = await request(app)
        .post('/api/groups/99999/settlements/recalculate')
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(404);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Group not found');
    });
  });

  describe('GET /api/settlements/:settlementId/preview', () => {
    let testSettlement;

    beforeEach(async () => {
      testSettlement = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 60.00,
        status: 'active'
      });
    });

    test('should get settlement preview for authorized user', async () => {
      const response = await request(app)
        .get(`/api/settlements/${testSettlement.id}/preview`)
        .set('Authorization', `Bearer ${authTokens[1]}`) // Involved user
        .expect(200);

      expect(response.body.error).toBe(false);
      expect(response.body.message).toBe('Settlement preview generated successfully');
      expect(response.body.data.preview).toBeDefined();
      expect(response.body.data.preview.settlement.amount).toBe(60.00);
      expect(response.body.data.preview.expense_to_create.title).toContain('Settlement: User2 → User1');
      expect(response.body.data.preview.effects.settlement_will_be_marked_settled).toBe(true);
      expect(response.body.data.can_process).toBe(true);
      expect(response.body.data.permissions.isInvolved).toBe(true);
    });

    test('should reject preview for unauthorized user', async () => {
      const response = await request(app)
        .get(`/api/settlements/${testSettlement.id}/preview`)
        .set('Authorization', `Bearer ${authTokens[3]}`) // Not involved
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Settlement cannot be processed');
      expect(response.body.preview).toBeNull();
    });
  });

  describe('POST /api/groups/:groupId/settlements/batch-settle', () => {
    let settlements;

    beforeEach(async () => {
      settlements = [];
      for (let i = 1; i <= 3; i++) {
        const settlement = await Settlement.create({
          group_id: testGroup.id,
          from_group_member_id: testMembers[i].id,
          to_group_member_id: testMembers[0].id,
          amount: 25.00,
          status: 'active'
        });
        settlements.push(settlement);
      }
    });

    test('should batch settle settlements by group admin', async () => {
      const settlementIds = settlements.map(s => s.id);

      const response = await request(app)
        .post(`/api/groups/${testGroup.id}/settlements/batch-settle`)
        .set('Authorization', `Bearer ${authTokens[0]}`) // Admin
        .send({ settlement_ids: settlementIds })
        .expect(200);

      expect(response.body.error).toBe(false);
      expect(response.body.message).toContain('3 successful, 0 failed');
      expect(response.body.data.results.summary.successful_count).toBe(3);
      expect(response.body.data.results.summary.failed_count).toBe(0);
      expect(response.body.data.results.summary.total_amount_settled).toBe(75.00);
    });

    test('should handle partial failures in batch processing', async () => {
      // Mark one settlement as already settled
      await settlements[1].markAsSettled(testUsers[0].id);

      const settlementIds = settlements.map(s => s.id);

      const response = await request(app)
        .post(`/api/groups/${testGroup.id}/settlements/batch-settle`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .send({ settlement_ids: settlementIds })
        .expect(207); // Multi-status for partial success

      expect(response.body.error).toBe(false);
      expect(response.body.message).toContain('2 successful, 1 failed');
      expect(response.body.data.results.summary.successful_count).toBe(2);
      expect(response.body.data.results.summary.failed_count).toBe(1);
    });

    test('should reject invalid settlement_ids', async () => {
      const response = await request(app)
        .post(`/api/groups/${testGroup.id}/settlements/batch-settle`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .send({ settlement_ids: [] })
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('settlement_ids must be a non-empty array');
    });

    test('should reject non-member access', async () => {
      const outsideUser = await User.create({
        first_name: 'Outside',
        last_name: 'User',
        email: 'outside.batch@test.com',
        password: 'Test@1234'
      });

      const outsideToken = jwt.sign(
        { id: outsideUser.id, email: outsideUser.email },
        process.env.JWT_SECRET || 'test-secret',
        { expiresIn: '1h' }
      );

      const response = await request(app)
        .post(`/api/groups/${testGroup.id}/settlements/batch-settle`)
        .set('Authorization', `Bearer ${outsideToken}`)
        .send({ settlement_ids: [settlements[0].id] })
        .expect(403);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('You must be a member of the group to settle settlements');

      await db.query('DELETE FROM users WHERE id = $1', [outsideUser.id]);
    });
  });

  describe('GET /api/settlements/:settlementId', () => {
    let testSettlement;

    beforeEach(async () => {
      testSettlement = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 40.00,
        status: 'active'
      });
    });

    test('should get settlement details for group member', async () => {
      const response = await request(app)
        .get(`/api/settlements/${testSettlement.id}`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(response.body.error).toBe(false);
      expect(response.body.message).toBe('Settlement details retrieved successfully');
      expect(response.body.data.settlement.id).toBe(testSettlement.id);
      expect(response.body.data.settlement.amount).toBe(40.00);
      expect(response.body.data.group.name).toBe(testGroup.name);
    });

    test('should return 404 for non-existent settlement', async () => {
      const response = await request(app)
        .get('/api/settlements/99999')
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(404);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Settlement not found');
    });
  });

  describe('GET /api/groups/:groupId/settlements/statistics', () => {
    beforeEach(async () => {
      // Create settlements with different statuses
      const settlement1 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 50.00,
        status: 'active'
      });

      const settlement2 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[2].id,
        to_group_member_id: testMembers[0].id,
        amount: 30.00,
        status: 'active'
      });

      await settlement1.markAsSettled(testUsers[1].id);
    });

    test('should get settlement statistics for group member', async () => {
      const response = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements/statistics`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(response.body.error).toBe(false);
      expect(response.body.message).toBe('Settlement statistics retrieved successfully');
      expect(response.body.data.statistics).toBeDefined();
      expect(response.body.data.summary).toBeDefined();
      expect(response.body.data.group.name).toBe(testGroup.name);
    });

    test('should reject non-member access', async () => {
      const outsideUser = await User.create({
        first_name: 'Outside',
        last_name: 'User',
        email: 'outside.stats@test.com',
        password: 'Test@1234'
      });

      const outsideToken = jwt.sign(
        { id: outsideUser.id, email: outsideUser.email },
        process.env.JWT_SECRET || 'test-secret',
        { expiresIn: '1h' }
      );

      const response = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements/statistics`)
        .set('Authorization', `Bearer ${outsideToken}`)
        .expect(403);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('You must be a member of the group to view settlement statistics');

      await db.query('DELETE FROM users WHERE id = $1', [outsideUser.id]);
    });
  });

  describe('Error Handling', () => {
    test('should handle database errors gracefully', async () => {
      // Mock database error
      const originalQuery = db.query;
      db.query = jest.fn().mockRejectedValue(new Error('Database connection failed'));

      const response = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(500);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Failed to retrieve settlements');

      // Restore original method
      db.query = originalQuery;
    });

    test('should handle invalid JSON in request body', async () => {
      const response = await request(app)
        .post(`/api/groups/${testGroup.id}/settlements/batch-settle`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .set('Content-Type', 'application/json')
        .send('invalid json')
        .expect(400);

      expect(response.body.error).toBe(true);
    });
  });
});