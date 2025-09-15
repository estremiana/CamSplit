const SettlementProcessorService = require('../../src/services/SettlementProcessorService');
const Settlement = require('../../src/models/Settlement');
const Expense = require('../../src/models/Expense');
const User = require('../../src/models/User');
const Group = require('../../src/models/Group');
const GroupMember = require('../../src/models/GroupMember');
const db = require('../../database/connection');

describe('SettlementProcessorService', () => {
  let testGroup, testUsers, testMembers, testSettlement;

  beforeAll(async () => {
    // Create test users
    testUsers = [];
    for (let i = 1; i <= 3; i++) {
      const user = await User.create({
        first_name: `User${i}`,
        last_name: `Test`,
        email: `user${i}.processor@test.com`,
        password: 'Test@1234'
      });
      testUsers.push(user);
    }

    // Create test group
    testGroup = await Group.create({
      name: 'Settlement Processor Test Group',
      description: 'Test group for settlement processor'
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

  beforeEach(async () => {
    // Create a test settlement for each test
    testSettlement = await Settlement.create({
      group_id: testGroup.id,
      from_group_member_id: testMembers[1].id, // User2 owes
      to_group_member_id: testMembers[0].id,   // User1 receives
      amount: 50.00,
      currency: 'EUR',
      status: 'active'
    });
  });

  afterEach(async () => {
    // Clean up after each test
    await db.query('DELETE FROM expense_splits WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [testGroup.id]);
    await db.query('DELETE FROM expense_payers WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [testGroup.id]);
    await db.query('DELETE FROM expenses WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM settlements WHERE group_id = $1', [testGroup.id]);
  });

  describe('processSettlement', () => {
    test('should successfully process a settlement by involved user', async () => {
      const result = await SettlementProcessorService.processSettlement(testSettlement.id, testUsers[1].id);

      expect(result.settlement).toBeDefined();
      expect(result.expense).toBeDefined();
      expect(result.message).toBe('Settlement processed successfully');

      // Verify settlement is marked as settled
      expect(result.settlement.status).toBe('settled');
      expect(result.settlement.settled_by).toBe(testUsers[1].id);
      expect(result.settlement.created_expense_id).toBe(result.expense.id);

      // Verify expense was created correctly
      expect(result.expense.title).toContain('Settlement: User2 → User1');
      expect(result.expense.amount).toBe(50.00);
      expect(result.expense.category).toBe('settlement');
      expect(result.expense.is_settlement).toBe(true);

      // Verify expense payer and split
      const payers = await db.query('SELECT * FROM expense_payers WHERE expense_id = $1', [result.expense.id]);
      const splits = await db.query('SELECT * FROM expense_splits WHERE expense_id = $1', [result.expense.id]);

      expect(payers.rows).toHaveLength(1);
      expect(payers.rows[0].group_member_id).toBe(testMembers[1].id); // User2 pays
      expect(parseFloat(payers.rows[0].amount)).toBe(50.00);

      expect(splits.rows).toHaveLength(1);
      expect(splits.rows[0].group_member_id).toBe(testMembers[0].id); // User1 benefits
      expect(parseFloat(splits.rows[0].amount)).toBe(50.00);
      expect(splits.rows[0].split_type).toBe('settlement');
    });

    test('should successfully process a settlement by group admin', async () => {
      const result = await SettlementProcessorService.processSettlement(testSettlement.id, testUsers[0].id);

      expect(result.settlement.status).toBe('settled');
      expect(result.settlement.settled_by).toBe(testUsers[0].id);
      expect(result.expense).toBeDefined();
    });

    test('should fail to process settlement by unauthorized user', async () => {
      await expect(
        SettlementProcessorService.processSettlement(testSettlement.id, testUsers[2].id)
      ).rejects.toThrow('You do not have permission to settle this debt');
    });

    test('should fail to process non-existent settlement', async () => {
      await expect(
        SettlementProcessorService.processSettlement(99999, testUsers[0].id)
      ).rejects.toThrow('Settlement not found');
    });

    test('should fail to process already settled settlement', async () => {
      // First, settle the settlement
      await testSettlement.markAsSettled(testUsers[1].id);

      await expect(
        SettlementProcessorService.processSettlement(testSettlement.id, testUsers[1].id)
      ).rejects.toThrow('Settlement is not active and cannot be processed');
    });

    test('should maintain transaction integrity on failure', async () => {
      // Mock Expense.create to fail
      const originalCreate = Expense.create;
      Expense.create = jest.fn().mockRejectedValue(new Error('Database error'));

      await expect(
        SettlementProcessorService.processSettlement(testSettlement.id, testUsers[1].id)
      ).rejects.toThrow('Failed to process settlement');

      // Verify settlement was not marked as settled due to rollback
      const settlement = await Settlement.findById(testSettlement.id);
      expect(settlement.status).toBe('active');

      // Restore original method
      Expense.create = originalCreate;
    });
  });

  describe('createSettlementExpense', () => {
    test('should create expense with correct details', async () => {
      const settlementData = {
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 75.50,
        currency: 'EUR',
        from_member: {
          id: testMembers[1].id,
          nickname: 'User2',
          user_id: testUsers[1].id
        },
        to_member: {
          id: testMembers[0].id,
          nickname: 'User1',
          user_id: testUsers[0].id
        }
      };

      const expense = await SettlementProcessorService.createSettlementExpense(settlementData, testUsers[0].id);

      expect(expense.title).toBe('Settlement: User2 → User1');
      expect(expense.description).toContain('Settlement payment of 75.5 EUR from User2 to User1');
      expect(expense.amount).toBe(75.50);
      expect(expense.currency).toBe('EUR');
      expect(expense.group_id).toBe(testGroup.id);
      expect(expense.created_by).toBe(testUsers[0].id);
      expect(expense.category).toBe('settlement');
      expect(expense.is_settlement).toBe(true);
    });

    test('should use default currency when not specified', async () => {
      const settlementData = {
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 25.00,
        from_member: { nickname: 'User2' },
        to_member: { nickname: 'User1' }
      };

      const expense = await SettlementProcessorService.createSettlementExpense(settlementData, testUsers[0].id);
      expect(expense.currency).toBe('EUR');
    });
  });

  describe('validateSettlementForProcessing', () => {
    test('should validate active settlement for involved user', async () => {
      const validation = await SettlementProcessorService.validateSettlementForProcessing(
        testSettlement.id, 
        testUsers[1].id
      );

      expect(validation.isValid).toBe(true);
      expect(validation.errors).toHaveLength(0);
      expect(validation.settlement).toBeDefined();
      expect(validation.permissions.isInvolved).toBe(true);
      expect(validation.permissions.canSettle).toBe(true);
    });

    test('should validate active settlement for group admin', async () => {
      const validation = await SettlementProcessorService.validateSettlementForProcessing(
        testSettlement.id, 
        testUsers[0].id
      );

      expect(validation.isValid).toBe(true);
      expect(validation.permissions.isAdmin).toBe(true);
      expect(validation.permissions.canSettle).toBe(true);
    });

    test('should reject validation for unauthorized user', async () => {
      const validation = await SettlementProcessorService.validateSettlementForProcessing(
        testSettlement.id, 
        testUsers[2].id
      );

      expect(validation.isValid).toBe(false);
      expect(validation.errors).toContain('You do not have permission to settle this debt');
      expect(validation.permissions.canSettle).toBe(false);
    });

    test('should reject validation for non-existent settlement', async () => {
      const validation = await SettlementProcessorService.validateSettlementForProcessing(
        99999, 
        testUsers[0].id
      );

      expect(validation.isValid).toBe(false);
      expect(validation.errors).toContain('Settlement not found');
      expect(validation.settlement).toBeNull();
    });

    test('should reject validation for inactive settlement', async () => {
      await testSettlement.updateStatus('settled', testUsers[1].id);

      const validation = await SettlementProcessorService.validateSettlementForProcessing(
        testSettlement.id, 
        testUsers[1].id
      );

      expect(validation.isValid).toBe(false);
      expect(validation.errors).toContain('Settlement is not active');
    });
  });

  describe('getSettlementProcessingPreview', () => {
    test('should generate preview for valid settlement', async () => {
      const preview = await SettlementProcessorService.getSettlementProcessingPreview(
        testSettlement.id, 
        testUsers[1].id
      );

      expect(preview.canProcess).toBe(true);
      expect(preview.errors).toHaveLength(0);
      expect(preview.preview).toBeDefined();
      expect(preview.preview.settlement.amount).toBe(50.00);
      expect(preview.preview.expense_to_create.title).toContain('Settlement: User2 → User1');
      expect(preview.preview.effects.settlement_will_be_marked_settled).toBe(true);
      expect(preview.preview.effects.new_expense_will_be_created).toBe(true);
      expect(preview.preview.effects.group_settlements_will_be_recalculated).toBe(true);
    });

    test('should reject preview for invalid settlement', async () => {
      const preview = await SettlementProcessorService.getSettlementProcessingPreview(
        testSettlement.id, 
        testUsers[2].id
      );

      expect(preview.canProcess).toBe(false);
      expect(preview.errors.length).toBeGreaterThan(0);
      expect(preview.preview).toBeNull();
    });
  });

  describe('processMultipleSettlements', () => {
    let settlement2, settlement3;

    beforeEach(async () => {
      settlement2 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[2].id,
        to_group_member_id: testMembers[0].id,
        amount: 30.00,
        currency: 'EUR',
        status: 'active'
      });

      settlement3 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[2].id,
        amount: 20.00,
        currency: 'EUR',
        status: 'active'
      });
    });

    test('should process multiple settlements successfully', async () => {
      const settlementIds = [testSettlement.id, settlement2.id];
      const result = await SettlementProcessorService.processMultipleSettlements(settlementIds, testUsers[0].id);

      expect(result.summary.total).toBe(2);
      expect(result.summary.successful_count).toBe(2);
      expect(result.summary.failed_count).toBe(0);
      expect(result.summary.total_amount_settled).toBe(80.00);
      expect(result.successful).toHaveLength(2);
      expect(result.failed).toHaveLength(0);
    });

    test('should handle partial failures in batch processing', async () => {
      // Mark one settlement as already settled
      await settlement2.markAsSettled(testUsers[0].id);

      const settlementIds = [testSettlement.id, settlement2.id, settlement3.id];
      const result = await SettlementProcessorService.processMultipleSettlements(settlementIds, testUsers[0].id);

      expect(result.summary.total).toBe(3);
      expect(result.summary.successful_count).toBe(2);
      expect(result.summary.failed_count).toBe(1);
      expect(result.successful).toHaveLength(2);
      expect(result.failed).toHaveLength(1);
      expect(result.failed[0].settlement_id).toBe(settlement2.id);
    });
  });

  describe('getProcessingStatistics', () => {
    test('should get processing statistics for group', async () => {
      // Create some settlements with different statuses
      await testSettlement.markAsSettled(testUsers[1].id, 123);
      
      const settlement2 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[2].id,
        to_group_member_id: testMembers[0].id,
        amount: 30.00,
        status: 'active'
      });

      const settlement3 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[2].id,
        amount: 20.00,
        status: 'obsolete'
      });

      const stats = await SettlementProcessorService.getProcessingStatistics(testGroup.id);

      expect(stats.by_status).toHaveLength(3); // active, settled, obsolete
      expect(stats.totals.all_settlements).toBe(3);
      expect(stats.totals.total_amount).toBe(100.00);
      expect(stats.totals.settled_settlements).toBe(1);
      expect(stats.totals.settlements_with_expenses).toBe(1);

      // Check individual status stats
      const activeStats = stats.by_status.find(s => s.status === 'active');
      const settledStats = stats.by_status.find(s => s.status === 'settled');
      const obsoleteStats = stats.by_status.find(s => s.status === 'obsolete');

      expect(activeStats.count).toBe(1);
      expect(settledStats.count).toBe(1);
      expect(obsoleteStats.count).toBe(1);
    });

    test('should return empty statistics for group with no settlements', async () => {
      // Clean up existing settlements
      await db.query('DELETE FROM settlements WHERE group_id = $1', [testGroup.id]);

      const stats = await SettlementProcessorService.getProcessingStatistics(testGroup.id);

      expect(stats.by_status).toHaveLength(0);
      expect(stats.totals.all_settlements).toBe(0);
      expect(stats.totals.total_amount).toBe(0);
    });
  });

  describe('cleanupObsoleteSettlements', () => {
    test('should cleanup old obsolete settlements', async () => {
      // Create obsolete settlement and make it old
      const obsoleteSettlement = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 25.00,
        status: 'obsolete'
      });

      // Make it appear old
      await db.query(
        'UPDATE settlements SET updated_at = NOW() - INTERVAL \'31 days\' WHERE id = $1',
        [obsoleteSettlement.id]
      );

      const deletedCount = await SettlementProcessorService.cleanupObsoleteSettlements(testGroup.id, 30);

      expect(deletedCount).toBe(1);

      // Verify settlement was deleted
      const settlement = await Settlement.findById(obsoleteSettlement.id);
      expect(settlement).toBeNull();
    });

    test('should not cleanup recent obsolete settlements', async () => {
      const obsoleteSettlement = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 25.00,
        status: 'obsolete'
      });

      const deletedCount = await SettlementProcessorService.cleanupObsoleteSettlements(testGroup.id, 30);

      expect(deletedCount).toBe(0);

      // Verify settlement still exists
      const settlement = await Settlement.findById(obsoleteSettlement.id);
      expect(settlement).not.toBeNull();
    });
  });

  describe('Error Handling', () => {
    test('should handle database errors gracefully', async () => {
      // Mock database error
      const originalQuery = db.query;
      db.query = jest.fn().mockRejectedValue(new Error('Database connection failed'));

      await expect(
        SettlementProcessorService.processSettlement(testSettlement.id, testUsers[1].id)
      ).rejects.toThrow('Failed to process settlement');

      // Restore original method
      db.query = originalQuery;
    });

    test('should handle validation errors in createSettlementExpense', async () => {
      const invalidSettlementData = {
        group_id: null, // Invalid
        from_group_member_id: testMembers[1].id,
        to_group_member_id: testMembers[0].id,
        amount: 50.00,
        from_member: { nickname: 'User2' },
        to_member: { nickname: 'User1' }
      };

      await expect(
        SettlementProcessorService.createSettlementExpense(invalidSettlementData, testUsers[0].id)
      ).rejects.toThrow('Failed to create settlement expense');
    });
  });
});