const SettlementHistoryService = require('../../src/services/SettlementHistoryService');
const Settlement = require('../../src/models/Settlement');
const User = require('../../src/models/User');
const Group = require('../../src/models/Group');
const GroupMember = require('../../src/models/GroupMember');
const Expense = require('../../src/models/Expense');
const db = require('../../database/connection');

describe('SettlementHistoryService', () => {
  let testGroup, testUsers, testMembers, testSettlements;

  beforeAll(async () => {
    // Create test users
    testUsers = [];
    for (let i = 1; i <= 3; i++) {
      const user = await User.create({
        first_name: `User${i}`,
        last_name: `Test`,
        email: `user${i}.history@test.com`,
        password: 'password123'
      });
      testUsers.push(user);
    }

    // Create test group
    testGroup = await Group.create({
      name: 'Settlement History Test Group',
      description: 'Test group for settlement history service',
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
    await db.query('DELETE FROM settlements WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM expenses WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM group_members WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM groups WHERE id = $1', [testGroup.id]);
    await db.query('DELETE FROM users WHERE id = ANY($1)', [testUsers.map(u => u.id)]);
  });

  beforeEach(async () => {
    // Create test settlements
    testSettlements = [];
    
    // Active settlement
    const activeSettlement = await Settlement.create({
      group_id: testGroup.id,
      from_group_member_id: testMembers[1].id,
      to_group_member_id: testMembers[0].id,
      amount: 50.00,
      status: 'active'
    });
    testSettlements.push(activeSettlement);

    // Settled settlement
    const settledSettlement = await Settlement.create({
      group_id: testGroup.id,
      from_group_member_id: testMembers[2].id,
      to_group_member_id: testMembers[0].id,
      amount: 75.00,
      status: 'settled',
      settled_at: new Date(),
      settled_by: testUsers[2].id
    });
    testSettlements.push(settledSettlement);

    // Obsolete settlement
    const obsoleteSettlement = await Settlement.create({
      group_id: testGroup.id,
      from_group_member_id: testMembers[1].id,
      to_group_member_id: testMembers[2].id,
      amount: 25.00,
      status: 'obsolete'
    });
    testSettlements.push(obsoleteSettlement);
  });

  afterEach(async () => {
    // Clean up settlements after each test
    await db.query('DELETE FROM settlements WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM expenses WHERE group_id = $1', [testGroup.id]);
  });

  describe('getSettlementHistory', () => {
    test('should get settlement history with default filters', async () => {
      const result = await SettlementHistoryService.getSettlementHistory(testGroup.id);

      expect(result.settlements).toHaveLength(1); // Only settled settlements by default
      expect(result.settlements[0].status).toBe('settled');
      expect(result.settlements[0].from_member).toBeDefined();
      expect(result.settlements[0].to_member).toBeDefined();
      expect(result.settlements[0].settled_by).toBeDefined();
      
      expect(result.pagination).toEqual({
        limit: 50,
        offset: 0,
        total: 1,
        has_more: false,
        page: 1,
        total_pages: 1
      });

      expect(result.filters.status).toBe('settled');
      expect(result.sorting.sort_by).toBe('settled_at');
      expect(result.sorting.sort_order).toBe('DESC');
    });

    test('should filter by status', async () => {
      const activeResult = await SettlementHistoryService.getSettlementHistory(
        testGroup.id,
        { status: 'active' }
      );

      expect(activeResult.settlements).toHaveLength(1);
      expect(activeResult.settlements[0].status).toBe('active');

      const obsoleteResult = await SettlementHistoryService.getSettlementHistory(
        testGroup.id,
        { status: 'obsolete' }
      );

      expect(obsoleteResult.settlements).toHaveLength(1);
      expect(obsoleteResult.settlements[0].status).toBe('obsolete');
    });

    test('should filter by date range', async () => {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);

      const result = await SettlementHistoryService.getSettlementHistory(
        testGroup.id,
        {
          status: 'settled',
          from_date: yesterday.toISOString(),
          to_date: tomorrow.toISOString()
        }
      );

      expect(result.settlements).toHaveLength(1);
      expect(result.filters.from_date).toBe(yesterday.toISOString());
      expect(result.filters.to_date).toBe(tomorrow.toISOString());
    });

    test('should filter by member IDs', async () => {
      const result = await SettlementHistoryService.getSettlementHistory(
        testGroup.id,
        {
          status: 'settled',
          from_member_id: testMembers[2].id
        }
      );

      expect(result.settlements).toHaveLength(1);
      expect(result.settlements[0].from_member.id).toBe(testMembers[2].id);
    });

    test('should filter by amount range', async () => {
      const result = await SettlementHistoryService.getSettlementHistory(
        testGroup.id,
        {
          status: 'settled',
          min_amount: 70,
          max_amount: 80
        }
      );

      expect(result.settlements).toHaveLength(1);
      expect(result.settlements[0].amount).toBe(75);
    });

    test('should include expense details when requested', async () => {
      // Create an expense for the settled settlement
      const expense = await Expense.create({
        title: 'Settlement Expense',
        amount: 75.00,
        currency: 'EUR',
        group_id: testGroup.id,
        created_by: testUsers[0].id,
        category: 'settlement'
      });

      // Update settlement to link to expense
      await db.query(
        'UPDATE settlements SET created_expense_id = $1 WHERE id = $2',
        [expense.id, testSettlements[1].id]
      );

      const result = await SettlementHistoryService.getSettlementHistory(
        testGroup.id,
        { include_expenses: true }
      );

      expect(result.settlements).toHaveLength(1);
      expect(result.settlements[0].created_expense).toBeDefined();
      expect(result.settlements[0].created_expense.title).toBe('Settlement Expense');
    });

    test('should support pagination', async () => {
      // Create more settlements
      for (let i = 0; i < 5; i++) {
        await Settlement.create({
          group_id: testGroup.id,
          from_group_member_id: testMembers[1].id,
          to_group_member_id: testMembers[0].id,
          amount: 10 + i,
          status: 'settled',
          settled_at: new Date(),
          settled_by: testUsers[1].id
        });
      }

      const result = await SettlementHistoryService.getSettlementHistory(
        testGroup.id,
        {},
        { limit: 3, offset: 0 }
      );

      expect(result.settlements).toHaveLength(3);
      expect(result.pagination.limit).toBe(3);
      expect(result.pagination.offset).toBe(0);
      expect(result.pagination.total).toBe(6); // 1 original + 5 new
      expect(result.pagination.has_more).toBe(true);
      expect(result.pagination.total_pages).toBe(2);
    });

    test('should support custom sorting', async () => {
      const result = await SettlementHistoryService.getSettlementHistory(
        testGroup.id,
        {},
        { sort_by: 'amount', sort_order: 'ASC' }
      );

      expect(result.sorting.sort_by).toBe('amount');
      expect(result.sorting.sort_order).toBe('ASC');
    });
  });

  describe('getSettlementAnalytics', () => {
    test('should get comprehensive settlement analytics', async () => {
      const analytics = await SettlementHistoryService.getSettlementAnalytics(testGroup.id);

      expect(analytics.overview).toEqual({
        total_settlements: 3,
        settled_count: 1,
        active_count: 1,
        obsolete_count: 1,
        total_settled_amount: 75,
        total_pending_amount: 50,
        avg_settlement_amount: 75,
        min_settlement_amount: 75,
        max_settlement_amount: 75,
        first_settlement_date: expect.any(Date),
        last_settlement_date: expect.any(Date),
        settlement_rate: '33.33'
      });

      expect(analytics.member_analytics).toHaveLength(3);
      
      // Check member analytics structure
      const memberAnalytic = analytics.member_analytics[0];
      expect(memberAnalytic).toHaveProperty('member_id');
      expect(memberAnalytic).toHaveProperty('nickname');
      expect(memberAnalytic).toHaveProperty('settlements_paid');
      expect(memberAnalytic).toHaveProperty('settlements_received');
      expect(memberAnalytic).toHaveProperty('total_paid');
      expect(memberAnalytic).toHaveProperty('total_received');
      expect(memberAnalytic).toHaveProperty('net_balance');
      expect(memberAnalytic).toHaveProperty('pending_to_pay');
      expect(memberAnalytic).toHaveProperty('pending_to_receive');

      expect(analytics.time_analytics).toBeDefined();
      expect(Array.isArray(analytics.time_analytics)).toBe(true);
    });

    test('should filter analytics by date range', async () => {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);

      const analytics = await SettlementHistoryService.getSettlementAnalytics(testGroup.id, {
        from_date: yesterday.toISOString(),
        to_date: tomorrow.toISOString()
      });

      expect(analytics.date_range.from_date).toBe(yesterday.toISOString());
      expect(analytics.date_range.to_date).toBe(tomorrow.toISOString());
    });

    test('should handle group with no settlements', async () => {
      // Create a new group with no settlements
      const emptyGroup = await Group.create({
        name: 'Empty Group',
        description: 'Group with no settlements',
        created_by: testUsers[0].id
      });

      const analytics = await SettlementHistoryService.getSettlementAnalytics(emptyGroup.id);

      expect(analytics.overview.total_settlements).toBe(0);
      expect(analytics.overview.settled_count).toBe(0);
      expect(analytics.overview.total_settled_amount).toBe(0);
      expect(analytics.overview.settlement_rate).toBe(0);

      // Clean up
      await db.query('DELETE FROM groups WHERE id = $1', [emptyGroup.id]);
    });
  });

  describe('getSettlementAuditTrail', () => {
    test('should get comprehensive audit trail for settlement', async () => {
      const settlementId = testSettlements[1].id; // Settled settlement

      const auditTrail = await SettlementHistoryService.getSettlementAuditTrail(settlementId);

      expect(auditTrail.settlement).toBeDefined();
      expect(auditTrail.settlement.id).toBe(settlementId);
      expect(auditTrail.settlement.lifecycle_stage).toBe('completed');
      expect(auditTrail.settlement.processing_time).toBeDefined();

      expect(auditTrail.calculation_batch).toBeDefined();
      expect(auditTrail.calculation_batch.timestamp).toBeDefined();
      expect(auditTrail.calculation_batch.batch_size).toBeGreaterThan(0);

      expect(auditTrail.group).toBeDefined();
      expect(auditTrail.group.id).toBe(testGroup.id);
      expect(auditTrail.group.name).toBe(testGroup.name);

      expect(auditTrail.metadata).toBeDefined();
      expect(auditTrail.metadata.audit_generated_at).toBeDefined();
      expect(auditTrail.metadata.settlement_age_days).toBeDefined();
    });

    test('should include related expense in audit trail', async () => {
      // Create an expense for the settlement
      const expense = await Expense.create({
        title: 'Audit Trail Expense',
        amount: 75.00,
        currency: 'EUR',
        group_id: testGroup.id,
        created_by: testUsers[0].id
      });

      // Update settlement to link to expense
      await db.query(
        'UPDATE settlements SET created_expense_id = $1 WHERE id = $2',
        [expense.id, testSettlements[1].id]
      );

      const auditTrail = await SettlementHistoryService.getSettlementAuditTrail(testSettlements[1].id);

      expect(auditTrail.related_expense).toBeDefined();
      expect(auditTrail.related_expense.id).toBe(expense.id);
      expect(auditTrail.related_expense.title).toBe('Audit Trail Expense');
    });

    test('should throw error for non-existent settlement', async () => {
      await expect(
        SettlementHistoryService.getSettlementAuditTrail(99999)
      ).rejects.toThrow('Settlement with ID 99999 not found');
    });
  });

  describe('exportSettlementHistory', () => {
    test('should export settlement history as CSV', async () => {
      const csvData = await SettlementHistoryService.exportSettlementHistory(testGroup.id);

      expect(typeof csvData).toBe('string');
      expect(csvData).toContain('Settlement ID');
      expect(csvData).toContain('From Member');
      expect(csvData).toContain('To Member');
      expect(csvData).toContain('Amount');
      expect(csvData).toContain('Currency');
      expect(csvData).toContain('Status');

      // Should contain data for settled settlement
      expect(csvData).toContain('User3'); // From member nickname
      expect(csvData).toContain('User1'); // To member nickname
      expect(csvData).toContain('75'); // Amount
      expect(csvData).toContain('settled'); // Status
    });

    test('should export with filters applied', async () => {
      const csvData = await SettlementHistoryService.exportSettlementHistory(
        testGroup.id,
        { status: 'active' }
      );

      expect(csvData).toContain('active');
      expect(csvData).not.toContain('settled');
    });

    test('should handle empty results', async () => {
      const csvData = await SettlementHistoryService.exportSettlementHistory(
        testGroup.id,
        { status: 'nonexistent' }
      );

      // Should still have headers
      expect(csvData).toContain('Settlement ID');
      
      // Should not have data rows (only header row)
      const lines = csvData.split('\n').filter(line => line.trim());
      expect(lines).toHaveLength(1); // Only header
    });
  });

  describe('Error Handling', () => {
    test('should handle database errors gracefully', async () => {
      // Mock database error
      const originalQuery = db.query;
      db.query = jest.fn().mockRejectedValue(new Error('Database connection failed'));

      await expect(
        SettlementHistoryService.getSettlementHistory(testGroup.id)
      ).rejects.toThrow();

      // Restore original method
      db.query = originalQuery;
    });

    test('should handle invalid group ID', async () => {
      const result = await SettlementHistoryService.getSettlementHistory(99999);
      
      expect(result.settlements).toHaveLength(0);
      expect(result.pagination.total).toBe(0);
    });
  });

  describe('getSettlementLifecycleStage', () => {
    test('should return correct lifecycle stages', () => {
      expect(SettlementHistoryService.getSettlementLifecycleStage({ status: 'active' }))
        .toBe('pending_settlement');
      
      expect(SettlementHistoryService.getSettlementLifecycleStage({ status: 'settled' }))
        .toBe('completed');
      
      expect(SettlementHistoryService.getSettlementLifecycleStage({ status: 'obsolete' }))
        .toBe('superseded');
      
      expect(SettlementHistoryService.getSettlementLifecycleStage({ status: 'unknown' }))
        .toBe('unknown');
    });
  });
});