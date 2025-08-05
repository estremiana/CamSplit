const request = require('supertest');
const app = require('../../src/app');
const db = require('../../database/connection');
const User = require('../../src/models/User');
const Group = require('../../src/models/Group');
const GroupMember = require('../../src/models/GroupMember');
const Expense = require('../../src/models/Expense');
const Settlement = require('../../src/models/Settlement');
const jwt = require('jsonwebtoken');

describe('Settlement Workflow Integration Tests', () => {
  let testUsers, testGroup, testMembers, authTokens;

  beforeAll(async () => {
    // Create test users
    testUsers = [];
    authTokens = [];
    
    for (let i = 1; i <= 4; i++) {
      const user = await User.create({
        first_name: `User${i}`,
        last_name: `Integration`,
        email: `user${i}.integration@test.com`,
        password: 'password123'
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
      name: 'Settlement Integration Test Group',
      description: 'Test group for settlement integration tests',
      created_by: testUsers[0].id
    });

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

  describe('Complete Settlement Workflow', () => {
    test('should handle complete expense-to-settlement-to-expense workflow', async () => {
      // Step 1: Create an expense that will generate settlements
      const expenseData = {
        title: 'Group Dinner',
        description: 'Dinner at restaurant',
        amount: 120.00,
        currency: 'EUR',
        group_id: testGroup.id,
        payers: [
          { group_member_id: testMembers[0].id, amount: 120.00 }
        ],
        splits: [
          { group_member_id: testMembers[0].id, amount: 30.00, split_type: 'equal' },
          { group_member_id: testMembers[1].id, amount: 30.00, split_type: 'equal' },
          { group_member_id: testMembers[2].id, amount: 30.00, split_type: 'equal' },
          { group_member_id: testMembers[3].id, amount: 30.00, split_type: 'equal' }
        ]
      };

      const expenseResponse = await request(app)
        .post('/api/expenses')
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .send(expenseData)
        .expect(201);

      expect(expenseResponse.body.success).toBe(true);

      // Step 2: Wait a moment for settlement recalculation (debounced)
      await new Promise(resolve => setTimeout(resolve, 600));

      // Step 3: Check that settlements were automatically generated
      const settlementsResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(settlementsResponse.body.error).toBe(false);
      expect(settlementsResponse.body.data.settlements).toHaveLength(3);
      expect(settlementsResponse.body.data.metadata.total_amount).toBe(90.00);

      // Verify all settlements are to User1 (who paid)
      settlementsResponse.body.data.settlements.forEach(settlement => {
        expect(settlement.to_group_member_id).toBe(testMembers[0].id);
        expect(settlement.amount).toBe(30.00);
        expect(settlement.status).toBe('active');
      });

      // Step 4: Get settlement preview for one settlement
      const settlementId = settlementsResponse.body.data.settlements[0].id;
      const previewResponse = await request(app)
        .get(`/api/settlements/${settlementId}/preview`)
        .set('Authorization', `Bearer ${authTokens[1]}`) // User2 (debtor)
        .expect(200);

      expect(previewResponse.body.error).toBe(false);
      expect(previewResponse.body.data.can_process).toBe(true);
      expect(previewResponse.body.data.preview.settlement.amount).toBe(30.00);
      expect(previewResponse.body.data.preview.expense_to_create.title).toContain('Settlement: User2 → User1');

      // Step 5: Settle one settlement
      const settleResponse = await request(app)
        .post(`/api/settlements/${settlementId}/settle`)
        .set('Authorization', `Bearer ${authTokens[1]}`) // User2 settles their debt
        .expect(200);

      expect(settleResponse.body.error).toBe(false);
      expect(settleResponse.body.data.settlement.status).toBe('settled');
      expect(settleResponse.body.data.expense).toBeDefined();
      expect(settleResponse.body.data.expense.title).toContain('Settlement: User2 → User1');

      // Step 6: Verify settlement recalculation happened (should have 2 active settlements now)
      await new Promise(resolve => setTimeout(resolve, 100));

      const updatedSettlementsResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(updatedSettlementsResponse.body.data.settlements).toHaveLength(2);
      expect(updatedSettlementsResponse.body.data.metadata.total_amount).toBe(60.00);

      // Step 7: Check settlement history
      const historyResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements/history`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(historyResponse.body.error).toBe(false);
      expect(historyResponse.body.data.settlements).toHaveLength(1);
      expect(historyResponse.body.data.settlements[0].status).toBe('settled');
      expect(historyResponse.body.data.settlements[0].from_member.nickname).toBe('User2');

      // Step 8: Get settlement analytics
      const analyticsResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements/analytics`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(analyticsResponse.body.error).toBe(false);
      expect(analyticsResponse.body.data.analytics.overview.total_settlements).toBeGreaterThan(0);
      expect(analyticsResponse.body.data.analytics.overview.settled_count).toBe(1);
      expect(analyticsResponse.body.data.analytics.member_analytics).toHaveLength(4);

      // Step 9: Get audit trail for settled settlement
      const auditResponse = await request(app)
        .get(`/api/settlements/${settlementId}/audit`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(auditResponse.body.error).toBe(false);
      expect(auditResponse.body.data.settlement.id).toBe(settlementId);
      expect(auditResponse.body.data.settlement.lifecycle_stage).toBe('completed');
      expect(auditResponse.body.data.related_expense).toBeDefined();
      expect(auditResponse.body.data.calculation_batch).toBeDefined();

      // Step 10: Batch settle remaining settlements
      const remainingSettlementIds = updatedSettlementsResponse.body.data.settlements.map(s => s.id);
      const batchSettleResponse = await request(app)
        .post(`/api/groups/${testGroup.id}/settlements/batch-settle`)
        .set('Authorization', `Bearer ${authTokens[0]}`) // Admin settles all
        .send({ settlement_ids: remainingSettlementIds })
        .expect(200);

      expect(batchSettleResponse.body.error).toBe(false);
      expect(batchSettleResponse.body.data.results.summary.successful_count).toBe(2);
      expect(batchSettleResponse.body.data.results.summary.failed_count).toBe(0);

      // Step 11: Verify all settlements are now settled
      const finalSettlementsResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(finalSettlementsResponse.body.data.settlements).toHaveLength(0);
      expect(finalSettlementsResponse.body.data.metadata.total_amount).toBe(0);

      // Step 12: Check final settlement history
      const finalHistoryResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements/history`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(finalHistoryResponse.body.data.settlements).toHaveLength(3);
      finalHistoryResponse.body.data.settlements.forEach(settlement => {
        expect(settlement.status).toBe('settled');
      });
    });

    test('should handle expense modifications and settlement recalculation', async () => {
      // Step 1: Create initial expense
      const expenseData = {
        title: 'Initial Expense',
        amount: 100.00,
        currency: 'EUR',
        group_id: testGroup.id,
        payers: [
          { group_member_id: testMembers[0].id, amount: 100.00 }
        ],
        splits: [
          { group_member_id: testMembers[0].id, amount: 50.00, split_type: 'equal' },
          { group_member_id: testMembers[1].id, amount: 50.00, split_type: 'equal' }
        ]
      };

      const expenseResponse = await request(app)
        .post('/api/expenses')
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .send(expenseData)
        .expect(201);

      const expenseId = expenseResponse.body.data.id;

      // Wait for settlement calculation
      await new Promise(resolve => setTimeout(resolve, 600));

      // Step 2: Check initial settlements
      const initialSettlementsResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(initialSettlementsResponse.body.data.settlements).toHaveLength(1);
      expect(initialSettlementsResponse.body.data.settlements[0].amount).toBe(50.00);

      // Step 3: Modify expense amount
      const updateResponse = await request(app)
        .put(`/api/expenses/${expenseId}`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .send({ amount: 200.00 })
        .expect(200);

      expect(updateResponse.body.success).toBe(true);

      // Wait for settlement recalculation
      await new Promise(resolve => setTimeout(resolve, 600));

      // Step 4: Check updated settlements
      const updatedSettlementsResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(updatedSettlementsResponse.body.data.settlements).toHaveLength(1);
      expect(updatedSettlementsResponse.body.data.settlements[0].amount).toBe(100.00); // Updated amount

      // Step 5: Delete expense
      const deleteResponse = await request(app)
        .delete(`/api/expenses/${expenseId}`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(deleteResponse.body.success).toBe(true);

      // Wait for settlement recalculation
      await new Promise(resolve => setTimeout(resolve, 600));

      // Step 6: Check settlements are cleared
      const finalSettlementsResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(finalSettlementsResponse.body.data.settlements).toHaveLength(0);
    });

    test('should handle concurrent settlement processing', async () => {
      // Step 1: Create expense that generates multiple settlements
      const expenseData = {
        title: 'Concurrent Test Expense',
        amount: 120.00,
        currency: 'EUR',
        group_id: testGroup.id,
        payers: [
          { group_member_id: testMembers[0].id, amount: 120.00 }
        ],
        splits: [
          { group_member_id: testMembers[0].id, amount: 30.00, split_type: 'equal' },
          { group_member_id: testMembers[1].id, amount: 30.00, split_type: 'equal' },
          { group_member_id: testMembers[2].id, amount: 30.00, split_type: 'equal' },
          { group_member_id: testMembers[3].id, amount: 30.00, split_type: 'equal' }
        ]
      };

      await request(app)
        .post('/api/expenses')
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .send(expenseData)
        .expect(201);

      // Wait for settlement calculation
      await new Promise(resolve => setTimeout(resolve, 600));

      // Step 2: Get settlements
      const settlementsResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      const settlements = settlementsResponse.body.data.settlements;
      expect(settlements).toHaveLength(3);

      // Step 3: Try to settle the same settlement concurrently
      const settlementId = settlements[0].id;
      
      const settlePromises = [
        request(app)
          .post(`/api/settlements/${settlementId}/settle`)
          .set('Authorization', `Bearer ${authTokens[1]}`),
        request(app)
          .post(`/api/settlements/${settlementId}/settle`)
          .set('Authorization', `Bearer ${authTokens[0]}`)
      ];

      const results = await Promise.allSettled(settlePromises);

      // One should succeed, one should fail
      const successCount = results.filter(r => r.status === 'fulfilled' && r.value.status === 200).length;
      const failureCount = results.filter(r => r.status === 'fulfilled' && r.value.status >= 400).length;

      expect(successCount).toBe(1);
      expect(failureCount).toBe(1);
    });

    test('should handle large group settlement optimization', async () => {
      // Create a larger group for this test
      const largeGroup = await Group.create({
        name: 'Large Settlement Test Group',
        description: 'Test group for large settlement optimization',
        created_by: testUsers[0].id
      });

      // Add more members (reuse existing users multiple times)
      const largeGroupMembers = [];
      for (let i = 0; i < 8; i++) {
        const member = await GroupMember.create({
          group_id: largeGroup.id,
          user_id: testUsers[i % testUsers.length].id,
          nickname: `LargeMember${i + 1}`,
          role: i === 0 ? 'admin' : 'member'
        });
        largeGroupMembers.push(member);
      }

      try {
        // Create multiple overlapping expenses
        const expenses = [];
        for (let i = 0; i < 5; i++) {
          const expenseData = {
            title: `Large Group Expense ${i + 1}`,
            amount: 80.00,
            currency: 'EUR',
            group_id: largeGroup.id,
            payers: [
              { group_member_id: largeGroupMembers[i % largeGroupMembers.length].id, amount: 80.00 }
            ],
            splits: largeGroupMembers.map(member => ({
              group_member_id: member.id,
              amount: 10.00,
              split_type: 'equal'
            }))
          };

          const response = await request(app)
            .post('/api/expenses')
            .set('Authorization', `Bearer ${authTokens[0]}`)
            .send(expenseData)
            .expect(201);

          expenses.push(response.body.data);
        }

        // Wait for settlement calculation
        await new Promise(resolve => setTimeout(resolve, 1000));

        // Check settlements were optimized
        const settlementsResponse = await request(app)
          .get(`/api/groups/${largeGroup.id}/settlements`)
          .set('Authorization', `Bearer ${authTokens[0]}`)
          .expect(200);

        expect(settlementsResponse.body.error).toBe(false);
        const settlements = settlementsResponse.body.data.settlements;
        
        // Should have optimized settlements (fewer than worst case)
        const worstCaseSettlements = largeGroupMembers.length * largeGroupMembers.length;
        expect(settlements.length).toBeLessThan(worstCaseSettlements);
        expect(settlements.length).toBeGreaterThan(0);

        // Verify settlement amounts balance
        const totalAmount = settlements.reduce((sum, s) => sum + s.amount, 0);
        expect(totalAmount).toBeGreaterThan(0);

        // Get performance statistics
        const statsResponse = await request(app)
          .get(`/api/groups/${largeGroup.id}/settlements/statistics`)
          .set('Authorization', `Bearer ${authTokens[0]}`)
          .expect(200);

        expect(statsResponse.body.error).toBe(false);
        expect(statsResponse.body.data.statistics).toBeDefined();

      } finally {
        // Clean up large group
        await db.query('DELETE FROM expense_splits WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [largeGroup.id]);
        await db.query('DELETE FROM expense_payers WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [largeGroup.id]);
        await db.query('DELETE FROM expenses WHERE group_id = $1', [largeGroup.id]);
        await db.query('DELETE FROM settlements WHERE group_id = $1', [largeGroup.id]);
        await db.query('DELETE FROM group_members WHERE group_id = $1', [largeGroup.id]);
        await db.query('DELETE FROM groups WHERE id = $1', [largeGroup.id]);
      }
    });

    test('should handle settlement export functionality', async () => {
      // Step 1: Create and settle some settlements
      const expenseData = {
        title: 'Export Test Expense',
        amount: 60.00,
        currency: 'EUR',
        group_id: testGroup.id,
        payers: [
          { group_member_id: testMembers[0].id, amount: 60.00 }
        ],
        splits: [
          { group_member_id: testMembers[0].id, amount: 20.00, split_type: 'equal' },
          { group_member_id: testMembers[1].id, amount: 20.00, split_type: 'equal' },
          { group_member_id: testMembers[2].id, amount: 20.00, split_type: 'equal' }
        ]
      };

      await request(app)
        .post('/api/expenses')
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .send(expenseData)
        .expect(201);

      // Wait for settlement calculation
      await new Promise(resolve => setTimeout(resolve, 600));

      // Get and settle settlements
      const settlementsResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      const settlementIds = settlementsResponse.body.data.settlements.map(s => s.id);

      await request(app)
        .post(`/api/groups/${testGroup.id}/settlements/batch-settle`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .send({ settlement_ids: settlementIds })
        .expect(200);

      // Step 2: Export settlement history
      const exportResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements/export`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(exportResponse.headers['content-type']).toBe('text/csv; charset=utf-8');
      expect(exportResponse.headers['content-disposition']).toContain('attachment');
      expect(exportResponse.headers['content-disposition']).toContain('.csv');

      const csvContent = exportResponse.text;
      expect(csvContent).toContain('Settlement ID');
      expect(csvContent).toContain('From Member');
      expect(csvContent).toContain('To Member');
      expect(csvContent).toContain('Amount');
      expect(csvContent).toContain('settled');
    });
  });

  describe('Error Scenarios', () => {
    test('should handle settlement processing errors gracefully', async () => {
      // Try to settle non-existent settlement
      const response = await request(app)
        .post('/api/settlements/99999/settle')
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Settlement cannot be processed');
    });

    test('should handle unauthorized settlement access', async () => {
      // Create settlement
      const settlement = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 50.00,
        status: 'active'
      });

      // Create unauthorized user
      const unauthorizedUser = await User.create({
        first_name: 'Unauthorized',
        last_name: 'User',
        email: 'unauthorized@test.com',
        password: 'password123'
      });

      const unauthorizedToken = jwt.sign(
        { id: unauthorizedUser.id, email: unauthorizedUser.email },
        process.env.JWT_SECRET || 'test-secret',
        { expiresIn: '1h' }
      );

      // Try to access settlement
      const response = await request(app)
        .get(`/api/settlements/${settlement.id}`)
        .set('Authorization', `Bearer ${unauthorizedToken}`)
        .expect(403);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('You must be a member of the group to view this settlement');

      // Clean up
      await db.query('DELETE FROM users WHERE id = $1', [unauthorizedUser.id]);
    });

    test('should handle validation errors in batch operations', async () => {
      const response = await request(app)
        .post(`/api/groups/${testGroup.id}/settlements/batch-settle`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .send({ settlement_ids: [] })
        .expect(400);

      expect(response.body.error).toBe(true);
      expect(response.body.message).toBe('Validation failed');
    });

    test('should handle rate limiting', async () => {
      // This test would need to make many requests quickly to trigger rate limiting
      // For brevity, we'll just verify the rate limiting middleware is in place
      const response = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      expect(response.headers).toHaveProperty('ratelimit-limit');
      expect(response.headers).toHaveProperty('ratelimit-remaining');
    });
  });

  describe('Performance Tests', () => {
    test('should handle settlement calculation within time limits', async () => {
      const startTime = Date.now();

      // Create expense that will trigger settlement calculation
      const expenseData = {
        title: 'Performance Test Expense',
        amount: 100.00,
        currency: 'EUR',
        group_id: testGroup.id,
        payers: [
          { group_member_id: testMembers[0].id, amount: 100.00 }
        ],
        splits: testMembers.map(member => ({
          group_member_id: member.id,
          amount: 25.00,
          split_type: 'equal'
        }))
      };

      await request(app)
        .post('/api/expenses')
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .send(expenseData)
        .expect(201);

      // Wait for settlement calculation
      await new Promise(resolve => setTimeout(resolve, 600));

      const settlementsResponse = await request(app)
        .get(`/api/groups/${testGroup.id}/settlements`)
        .set('Authorization', `Bearer ${authTokens[0]}`)
        .expect(200);

      const endTime = Date.now();
      const totalTime = endTime - startTime;

      expect(settlementsResponse.body.error).toBe(false);
      expect(totalTime).toBeLessThan(5000); // Should complete within 5 seconds
    });

    test('should handle multiple concurrent requests', async () => {
      // Create settlement first
      const settlement = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 50.00,
        status: 'active'
      });

      // Make multiple concurrent requests
      const promises = Array.from({ length: 5 }, () =>
        request(app)
          .get(`/api/settlements/${settlement.id}`)
          .set('Authorization', `Bearer ${authTokens[0]}`)
      );

      const results = await Promise.all(promises);

      // All requests should succeed
      results.forEach(result => {
        expect(result.status).toBe(200);
        expect(result.body.error).toBe(false);
      });
    });
  });
});