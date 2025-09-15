const Settlement = require('../../src/models/Settlement');
const Group = require('../../src/models/Group');
const User = require('../../src/models/User');
const GroupMember = require('../../src/models/GroupMember');
const db = require('../../database/connection');

describe('Settlement Model', () => {
  let testGroup, testUser1, testUser2, testMember1, testMember2;

  beforeAll(async () => {
    // Create test users
    testUser1 = await User.create({
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.settlement@test.com',
      password: 'Test@1234'
    });

    testUser2 = await User.create({
      first_name: 'Jane',
      last_name: 'Smith',
      email: 'jane.settlement@test.com',
      password: 'Test@1234'
    });

    // Create test group
    testGroup = await Group.create({
      name: 'Settlement Test Group',
      description: 'Test group for settlement operations'
    }, testUser1.id);

    // Add members to group
    testMember1 = await GroupMember.create({
      group_id: testGroup.id,
      user_id: testUser1.id,
      nickname: 'John',
      role: 'admin'
    });

    testMember2 = await GroupMember.create({
      group_id: testGroup.id,
      user_id: testUser2.id,
      nickname: 'Jane',
      role: 'member'
    });
  });

  afterAll(async () => {
    // Clean up test data
    await db.query('DELETE FROM settlements WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM group_members WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM groups WHERE id = $1', [testGroup.id]);
    await db.query('DELETE FROM users WHERE id IN ($1, $2)', [testUser1.id, testUser2.id]);
  });

  afterEach(async () => {
    // Clean up settlements after each test
    await db.query('DELETE FROM settlements WHERE group_id = $1', [testGroup.id]);
  });

  describe('Settlement Creation', () => {
    test('should create a new settlement with valid data', async () => {
      const settlementData = {
        group_id: testGroup.id,
        from_group_member_id: testMember1.id,
        to_group_member_id: testMember2.id,
        amount: 50.00,
        currency: 'EUR',
        status: 'active'
      };

      const settlement = await Settlement.create(settlementData);

      expect(settlement).toBeInstanceOf(Settlement);
      expect(settlement.group_id).toBe(testGroup.id);
      expect(settlement.from_group_member_id).toBe(testMember1.id);
      expect(settlement.to_group_member_id).toBe(testMember2.id);
      expect(parseFloat(settlement.amount)).toBe(50.00);
      expect(settlement.currency).toBe('EUR');
      expect(settlement.status).toBe('active');
    });

    test('should create settlement with default values', async () => {
      const settlementData = {
        group_id: testGroup.id,
        from_group_member_id: testMember1.id,
        to_group_member_id: testMember2.id,
        amount: 25.50
      };

      const settlement = await Settlement.create(settlementData);

      expect(settlement.currency).toBe('EUR');
      expect(settlement.status).toBe('active');
      expect(settlement.calculation_timestamp).toBeDefined();
    });

    test('should fail to create settlement with invalid data', async () => {
      const invalidData = {
        group_id: testGroup.id,
        from_group_member_id: testMember1.id,
        to_group_member_id: testMember2.id,
        amount: -10.00 // Invalid negative amount
      };

      await expect(Settlement.create(invalidData)).rejects.toThrow('Validation failed');
    });

    test('should fail when from and to members are the same', async () => {
      const invalidData = {
        group_id: testGroup.id,
        from_group_member_id: testMember1.id,
        to_group_member_id: testMember1.id, // Same as from_member
        amount: 50.00
      };

      await expect(Settlement.create(invalidData)).rejects.toThrow('From and to members cannot be the same');
    });
  });

  describe('Settlement Retrieval', () => {
    let testSettlement;

    beforeEach(async () => {
      testSettlement = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMember1.id,
        to_group_member_id: testMember2.id,
        amount: 75.00
      });
    });

    test('should find settlement by ID', async () => {
      const found = await Settlement.findById(testSettlement.id);

      expect(found).toBeInstanceOf(Settlement);
      expect(found.id).toBe(testSettlement.id);
      expect(parseFloat(found.amount)).toBe(75.00);
    });

    test('should return null for non-existent settlement', async () => {
      const found = await Settlement.findById(99999);
      expect(found).toBeNull();
    });

    test('should find settlement with member details', async () => {
      const settlement = await Settlement.findByIdWithDetails(testSettlement.id);

      expect(settlement).toBeDefined();
      expect(settlement.id).toBe(testSettlement.id);
      expect(settlement.from_member).toBeDefined();
      expect(settlement.from_member.nickname).toBe('John');
      expect(settlement.to_member).toBeDefined();
      expect(settlement.to_member.nickname).toBe('Jane');
    });

    test('should get settlements for group', async () => {
      // Create another settlement
      await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMember2.id,
        to_group_member_id: testMember1.id,
        amount: 30.00
      });

      const settlements = await Settlement.getSettlementsForGroup(testGroup.id);

      expect(settlements).toHaveLength(2);
      expect(settlements[0].from_member).toBeDefined();
      expect(settlements[0].to_member).toBeDefined();
    });

    test('should get settlements by status', async () => {
      // Mark one settlement as settled
      await testSettlement.updateStatus('settled', testUser1.id);

      const activeSettlements = await Settlement.getSettlementsForGroup(testGroup.id, 'active');
      const settledSettlements = await Settlement.getSettlementsForGroup(testGroup.id, 'settled');

      expect(activeSettlements).toHaveLength(0);
      expect(settledSettlements).toHaveLength(1);
    });
  });

  describe('Settlement Updates', () => {
    let testSettlement;

    beforeEach(async () => {
      testSettlement = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMember1.id,
        to_group_member_id: testMember2.id,
        amount: 100.00
      });
    });

    test('should update settlement status', async () => {
      await testSettlement.updateStatus('settled', testUser1.id);

      expect(testSettlement.status).toBe('settled');
      expect(testSettlement.settled_by).toBe(testUser1.id);
      expect(testSettlement.settled_at).toBeDefined();
    });

    test('should mark settlement as settled', async () => {
      await testSettlement.markAsSettled(testUser1.id, 123);

      expect(testSettlement.status).toBe('settled');
      expect(testSettlement.settled_by).toBe(testUser1.id);
      expect(testSettlement.created_expense_id).toBe(123);
      expect(testSettlement.settled_at).toBeDefined();
    });

    test('should update settlement details', async () => {
      await testSettlement.update({
        amount: 150.00,
        currency: 'USD'
      });

      expect(parseFloat(testSettlement.amount)).toBe(150.00);
      expect(testSettlement.currency).toBe('USD');
    });

    test('should fail to update with invalid status', async () => {
      await expect(testSettlement.updateStatus('invalid_status')).rejects.toThrow('Invalid settlement status');
    });
  });

  describe('Settlement Validation', () => {
    test('should validate correct settlement data', () => {
      const validData = {
        group_id: 1,
        from_group_member_id: 2,
        to_group_member_id: 3,
        amount: 50.00,
        currency: 'EUR',
        status: 'active'
      };

      const validation = Settlement.validate(validData);
      expect(validation.isValid).toBe(true);
      expect(validation.errors).toHaveLength(0);
    });

    test('should reject invalid settlement data', () => {
      const invalidData = {
        group_id: null,
        from_group_member_id: null,
        to_group_member_id: null,
        amount: -10,
        currency: 'INVALID',
        status: 'invalid_status'
      };

      const validation = Settlement.validate(invalidData);
      expect(validation.isValid).toBe(false);
      expect(validation.errors.length).toBeGreaterThan(0);
    });

    test('should validate currency codes', () => {
      expect(Settlement.isValidCurrency('EUR')).toBe(true);
      expect(Settlement.isValidCurrency('USD')).toBe(true);
      expect(Settlement.isValidCurrency('GBP')).toBe(true);
      expect(Settlement.isValidCurrency('INVALID')).toBe(false);
      expect(Settlement.isValidCurrency('eu')).toBe(false);
    });

    test('should validate status values', () => {
      expect(Settlement.isValidStatus('active')).toBe(true);
      expect(Settlement.isValidStatus('settled')).toBe(true);
      expect(Settlement.isValidStatus('obsolete')).toBe(true);
      expect(Settlement.isValidStatus('invalid')).toBe(false);
    });
  });

  describe('Settlement Utility Methods', () => {
    let settlement1, settlement2;

    beforeEach(async () => {
      settlement1 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMember1.id,
        to_group_member_id: testMember2.id,
        amount: 50.00
      });

      settlement2 = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMember2.id,
        to_group_member_id: testMember1.id,
        amount: 30.00
      });
    });

    test('should mark obsolete settlements', async () => {
      const obsoleteSettlements = await Settlement.markObsoleteSettlements(testGroup.id, [settlement1.id]);

      expect(obsoleteSettlements).toHaveLength(1);
      expect(obsoleteSettlements[0].id).toBe(settlement2.id);
      expect(obsoleteSettlements[0].status).toBe('obsolete');
    });

    test('should get settlement summary', async () => {
      await settlement1.updateStatus('settled', testUser1.id);

      const summary = await Settlement.getSettlementSummaryForGroup(testGroup.id);

      expect(summary).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ status: 'active', count: '1' }),
          expect.objectContaining({ status: 'settled', count: '1' })
        ])
      );
    });

    test('should check user involvement in settlement', async () => {
      const isInvolved = await Settlement.isUserInvolvedInSettlement(settlement1.id, testUser1.id);
      const isNotInvolved = await Settlement.isUserInvolvedInSettlement(settlement1.id, 99999);

      expect(isInvolved).toBe(true);
      expect(isNotInvolved).toBe(false);
    });

    test('should convert settlement to JSON', () => {
      const json = settlement1.toJSON();

      expect(json).toHaveProperty('id');
      expect(json).toHaveProperty('group_id');
      expect(json).toHaveProperty('amount');
      expect(typeof json.amount).toBe('number');
    });
  });

  describe('Settlement History', () => {
    test('should get settlement history for group', async () => {
      const settlement = await Settlement.create({
        group_id: testGroup.id,
        from_group_member_id: testMember1.id,
        to_group_member_id: testMember2.id,
        amount: 40.00
      });

      await settlement.markAsSettled(testUser1.id);

      const history = await Settlement.getSettlementHistory(testGroup.id);

      expect(history).toHaveLength(1);
      expect(history[0].status).toBe('settled');
    });
  });

  describe('Settlement Calculation and Storage', () => {
    let testExpense;

    beforeEach(async () => {
      // Create a test expense to generate settlements
      testExpense = await db.query(
        'INSERT INTO expenses (title, amount, currency, group_id, created_by, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, NOW(), NOW()) RETURNING *',
        ['Test Expense', 100.00, 'EUR', testGroup.id, testUser1.id]
      );

      // Add payer (testMember1 pays 100)
      await db.query(
        'INSERT INTO expense_payers (expense_id, group_member_id, amount_paid) VALUES ($1, $2, $3)',
        [testExpense.rows[0].id, testMember1.id, 100.00]
      );

      // Add splits (25 each for all 4 members)
      for (let i = 0; i < 4; i++) {
        await db.query(
          'INSERT INTO expense_splits (expense_id, group_member_id, amount_owed, split_type) VALUES ($1, $2, $3, $4)',
          [testExpense.rows[0].id, testMembers[i].id, 25.00, 'equal']
        );
      }
    });

    afterEach(async () => {
      // Clean up expense data
      if (testExpense && testExpense.rows[0]) {
        await db.query('DELETE FROM expense_splits WHERE expense_id = $1', [testExpense.rows[0].id]);
        await db.query('DELETE FROM expense_payers WHERE expense_id = $1', [testExpense.rows[0].id]);
        await db.query('DELETE FROM expenses WHERE id = $1', [testExpense.rows[0].id]);
      }
    });

    test('should calculate and store optimal settlements', async () => {
      const result = await Settlement.calculateOptimalSettlements(testGroup.id);

      expect(result.settlements).toHaveLength(3);
      expect(result.balances).toHaveLength(4);
      expect(result.summary.total_settlements).toBe(3);
      expect(result.summary.total_amount).toBe(75);

      // Verify settlements are stored in database
      const storedSettlements = await Settlement.getSettlementsForGroup(testGroup.id);
      expect(storedSettlements).toHaveLength(3);

      // Verify all settlements are to testMember1 (who paid)
      result.settlements.forEach(settlement => {
        expect(settlement.to_group_member_id).toBe(testMember1.id);
        expect(settlement.amount).toBe(25);
        expect(settlement.status).toBe('active');
      });
    });

    test('should mark obsolete settlements when recalculating', async () => {
      // Create initial settlements
      const initialResult = await Settlement.calculateOptimalSettlements(testGroup.id);
      expect(initialResult.settlements).toHaveLength(3);

      // Recalculate settlements (should mark previous ones as obsolete)
      const recalculatedResult = await Settlement.calculateOptimalSettlements(testGroup.id);
      expect(recalculatedResult.settlements).toHaveLength(3);

      // Check that obsolete settlements exist
      const obsoleteSettlements = await Settlement.getSettlementsForGroup(testGroup.id, 'obsolete');
      expect(obsoleteSettlements).toHaveLength(3);

      // Check that active settlements are the new ones
      const activeSettlements = await Settlement.getSettlementsForGroup(testGroup.id, 'active');
      expect(activeSettlements).toHaveLength(3);
    });

    test('should recalculate settlements with cleanup', async () => {
      // Create initial settlements
      await Settlement.calculateOptimalSettlements(testGroup.id);

      // Mark some settlements as obsolete manually (simulate old obsolete settlements)
      await db.query(
        'UPDATE settlements SET status = $1, updated_at = NOW() - INTERVAL \'8 days\' WHERE group_id = $2',
        ['obsolete', testGroup.id]
      );

      // Recalculate with cleanup
      const result = await Settlement.recalculateSettlements(testGroup.id, { cleanupObsoleteAfterDays: 7 });

      expect(result.settlements).toHaveLength(3);
      expect(result.summary.cleaned_up_settlements).toBeGreaterThan(0);
    });

    test('should get active settlements with metadata', async () => {
      await Settlement.calculateOptimalSettlements(testGroup.id);

      const result = await Settlement.getActiveSettlementsWithMetadata(testGroup.id);

      expect(result.settlements).toHaveLength(3);
      expect(result.metadata.calculation_timestamp).toBeDefined();
      expect(result.metadata.total_amount).toBe(75);
      expect(result.metadata.settlement_count).toBe(3);
      expect(result.metadata.members_involved).toBe(4);
    });

    test('should handle empty settlements with metadata', async () => {
      // No expenses, so no settlements should be generated
      await db.query('DELETE FROM expense_splits WHERE expense_id = $1', [testExpense.rows[0].id]);
      await db.query('DELETE FROM expense_payers WHERE expense_id = $1', [testExpense.rows[0].id]);
      await db.query('DELETE FROM expenses WHERE id = $1', [testExpense.rows[0].id]);

      const result = await Settlement.getActiveSettlementsWithMetadata(testGroup.id);

      expect(result.settlements).toHaveLength(0);
      expect(result.metadata.calculation_timestamp).toBeNull();
      expect(result.metadata.total_amount).toBe(0);
      expect(result.metadata.settlement_count).toBe(0);
      expect(result.metadata.members_involved).toBe(0);
    });

    test('should handle calculation errors gracefully', async () => {
      // Test with invalid group ID
      await expect(Settlement.calculateOptimalSettlements(99999)).rejects.toThrow();
    });

    test('should maintain transaction integrity on failure', async () => {
      // Mock a failure in the settlement creation process
      const originalCreate = Settlement.create;
      Settlement.create = jest.fn().mockRejectedValue(new Error('Database error'));

      await expect(Settlement.calculateOptimalSettlements(testGroup.id)).rejects.toThrow();

      // Verify no settlements were created due to rollback
      const settlements = await Settlement.getSettlementsForGroup(testGroup.id);
      expect(settlements).toHaveLength(0);

      // Restore original method
      Settlement.create = originalCreate;
    });
  });
});