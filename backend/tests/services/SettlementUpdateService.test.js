const SettlementUpdateService = require('../../src/services/SettlementUpdateService');
const Settlement = require('../../src/models/Settlement');
const User = require('../../src/models/User');
const Group = require('../../src/models/Group');
const GroupMember = require('../../src/models/GroupMember');
const Expense = require('../../src/models/Expense');
const db = require('../../database/connection');

// Mock Settlement.recalculateSettlements to avoid actual database operations in debounce tests
jest.mock('../../src/models/Settlement');

describe('SettlementUpdateService', () => {
  let testGroup, testUsers, testMembers;

  beforeAll(async () => {
    // Create test users
    testUsers = [];
    for (let i = 1; i <= 3; i++) {
      const user = await User.create({
        first_name: `User${i}`,
        last_name: `Test`,
        email: `user${i}.update@test.com`,
        password: 'password123'
      });
      testUsers.push(user);
    }

    // Create test group
    testGroup = await Group.create({
      name: 'Settlement Update Test Group',
      description: 'Test group for settlement update service',
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
    await db.query('DELETE FROM group_members WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM groups WHERE id = $1', [testGroup.id]);
    await db.query('DELETE FROM users WHERE id = ANY($1)', [testUsers.map(u => u.id)]);
  });

  beforeEach(() => {
    // Clear all mocks and timers before each test
    jest.clearAllMocks();
    SettlementUpdateService.cleanup();
    
    // Mock Settlement.recalculateSettlements to return a predictable result
    Settlement.recalculateSettlements.mockResolvedValue({
      settlements: [],
      balances: [],
      summary: {
        total_settlements: 0,
        total_amount: 0,
        members_involved: 0
      }
    });
  });

  afterEach(() => {
    // Clean up any pending timers
    SettlementUpdateService.cleanup();
  });

  describe('triggerRecalculation', () => {
    test('should schedule debounced recalculation', async () => {
      const result = await SettlementUpdateService.triggerRecalculation(testGroup.id, 'expense_created');

      expect(result.scheduled).toBe(true);
      expect(result.groupId).toBe(testGroup.id);
      expect(result.changeType).toBe('expense_created');
      expect(result.delay).toBe(500);

      // Verify timer is set
      const pendingRecalculations = SettlementUpdateService.getPendingRecalculations();
      expect(pendingRecalculations).toContain(testGroup.id);
    });

    test('should execute immediate recalculation when requested', async () => {
      const result = await SettlementUpdateService.triggerRecalculation(
        testGroup.id, 
        'expense_deleted', 
        { immediate: true }
      );

      expect(Settlement.recalculateSettlements).toHaveBeenCalledWith(testGroup.id, {
        cleanupObsoleteAfterDays: 7
      });

      // Verify no timer is set for immediate execution
      const pendingRecalculations = SettlementUpdateService.getPendingRecalculations();
      expect(pendingRecalculations).not.toContain(testGroup.id);
    });

    test('should replace existing timer with new one', async () => {
      // Schedule first recalculation
      await SettlementUpdateService.triggerRecalculation(testGroup.id, 'expense_created');
      
      // Schedule second recalculation (should replace first)
      await SettlementUpdateService.triggerRecalculation(testGroup.id, 'expense_updated');

      // Should still have only one pending recalculation
      const pendingRecalculations = SettlementUpdateService.getPendingRecalculations();
      expect(pendingRecalculations).toHaveLength(1);
      expect(pendingRecalculations).toContain(testGroup.id);
    });

    test('should use custom delay when provided', async () => {
      const result = await SettlementUpdateService.triggerRecalculation(
        testGroup.id, 
        'expense_updated', 
        { delay: 1000 }
      );

      expect(result.delay).toBe(1000);
    });
  });

  describe('executeRecalculation', () => {
    test('should execute recalculation and log results', async () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();

      Settlement.recalculateSettlements.mockResolvedValue({
        settlements: [{ id: 1, amount: 50 }],
        balances: [{ member_id: 1, balance: 50 }],
        summary: {
          total_settlements: 1,
          total_amount: 50,
          members_involved: 2
        }
      });

      const result = await SettlementUpdateService.executeRecalculation(testGroup.id, 'test');

      expect(Settlement.recalculateSettlements).toHaveBeenCalledWith(testGroup.id, {
        cleanupObsoleteAfterDays: 7
      });

      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining(`Recalculating settlements for group ${testGroup.id}`)
      );

      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining(`Settlement recalculation completed for group ${testGroup.id}`),
        expect.objectContaining({
          settlements_count: 1,
          total_amount: 50,
          members_involved: 2
        })
      );

      consoleSpy.mockRestore();
    });

    test('should handle recalculation errors', async () => {
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
      const error = new Error('Recalculation failed');
      
      Settlement.recalculateSettlements.mockRejectedValue(error);

      await expect(
        SettlementUpdateService.executeRecalculation(testGroup.id, 'test')
      ).rejects.toThrow('Recalculation failed');

      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining(`Settlement recalculation failed for group ${testGroup.id}`),
        error
      );

      consoleSpy.mockRestore();
    });
  });

  describe('scheduleRecalculation', () => {
    test('should schedule recalculation with custom delay', async () => {
      const result = await SettlementUpdateService.scheduleRecalculation(testGroup.id, 2000, 'custom');

      expect(result.scheduled).toBe(true);
      expect(result.delay).toBe(2000);
      expect(result.changeType).toBe('custom');
    });
  });

  describe('Event Handlers', () => {
    test('handleExpenseCreated should trigger recalculation with delay', async () => {
      const expense = { id: 1, group_id: testGroup.id, amount: 100 };
      
      await SettlementUpdateService.handleExpenseCreated(expense);

      const pendingRecalculations = SettlementUpdateService.getPendingRecalculations();
      expect(pendingRecalculations).toContain(testGroup.id);
    });

    test('handleExpenseUpdated should trigger immediate recalculation for amount changes', async () => {
      const expense = { id: 1, group_id: testGroup.id, amount: 100 };
      const changes = { amount: 150 };
      
      await SettlementUpdateService.handleExpenseUpdated(expense, changes);

      expect(Settlement.recalculateSettlements).toHaveBeenCalledWith(testGroup.id, {
        cleanupObsoleteAfterDays: 7
      });
    });

    test('handleExpenseUpdated should trigger debounced recalculation for non-critical changes', async () => {
      const expense = { id: 1, group_id: testGroup.id, amount: 100 };
      const changes = { title: 'Updated title' };
      
      await SettlementUpdateService.handleExpenseUpdated(expense, changes);

      const pendingRecalculations = SettlementUpdateService.getPendingRecalculations();
      expect(pendingRecalculations).toContain(testGroup.id);
    });

    test('handleExpenseDeleted should trigger immediate recalculation', async () => {
      const expense = { id: 1, group_id: testGroup.id, amount: 100 };
      
      await SettlementUpdateService.handleExpenseDeleted(expense);

      expect(Settlement.recalculateSettlements).toHaveBeenCalledWith(testGroup.id, {
        cleanupObsoleteAfterDays: 7
      });
    });

    test('handlePayerChanges should trigger immediate recalculation when changes exist', async () => {
      const changes = [{ member_id: 1, amount: 50 }];
      
      await SettlementUpdateService.handlePayerChanges(1, testGroup.id, changes);

      expect(Settlement.recalculateSettlements).toHaveBeenCalledWith(testGroup.id, {
        cleanupObsoleteAfterDays: 7
      });
    });

    test('handleSplitChanges should trigger immediate recalculation when changes exist', async () => {
      const changes = [{ member_id: 1, amount: 25 }];
      
      await SettlementUpdateService.handleSplitChanges(1, testGroup.id, changes);

      expect(Settlement.recalculateSettlements).toHaveBeenCalledWith(testGroup.id, {
        cleanupObsoleteAfterDays: 7
      });
    });

    test('handleSettlementProcessed should trigger immediate recalculation', async () => {
      const settlement = { id: 1, group_id: testGroup.id, amount: 50 };
      
      await SettlementUpdateService.handleSettlementProcessed(settlement);

      expect(Settlement.recalculateSettlements).toHaveBeenCalledWith(testGroup.id, {
        cleanupObsoleteAfterDays: 7
      });
    });

    test('should not trigger recalculation for events without group_id', async () => {
      const expense = { id: 1, amount: 100 }; // No group_id
      
      await SettlementUpdateService.handleExpenseCreated(expense);

      const pendingRecalculations = SettlementUpdateService.getPendingRecalculations();
      expect(pendingRecalculations).toHaveLength(0);
    });
  });

  describe('Utility Methods', () => {
    test('getPendingRecalculations should return array of group IDs', async () => {
      await SettlementUpdateService.triggerRecalculation(testGroup.id, 'test1');
      await SettlementUpdateService.triggerRecalculation(999, 'test2');

      const pending = SettlementUpdateService.getPendingRecalculations();
      expect(pending).toContain(testGroup.id);
      expect(pending).toContain(999);
      expect(pending).toHaveLength(2);
    });

    test('cancelRecalculation should cancel pending recalculation', async () => {
      await SettlementUpdateService.triggerRecalculation(testGroup.id, 'test');
      
      const cancelled = SettlementUpdateService.cancelRecalculation(testGroup.id);
      expect(cancelled).toBe(true);

      const pending = SettlementUpdateService.getPendingRecalculations();
      expect(pending).not.toContain(testGroup.id);
    });

    test('cancelRecalculation should return false for non-existent timer', () => {
      const cancelled = SettlementUpdateService.cancelRecalculation(999);
      expect(cancelled).toBe(false);
    });

    test('forceRecalculation should execute immediate recalculation', async () => {
      await SettlementUpdateService.forceRecalculation(testGroup.id, 'manual');

      expect(Settlement.recalculateSettlements).toHaveBeenCalledWith(testGroup.id, {
        cleanupObsoleteAfterDays: 7
      });
    });

    test('getStatistics should return service statistics', async () => {
      await SettlementUpdateService.triggerRecalculation(testGroup.id, 'test');

      const stats = SettlementUpdateService.getStatistics();

      expect(stats.pending_recalculations).toBe(1);
      expect(stats.pending_groups).toContain(testGroup.id);
      expect(stats.debounce_delay).toBe(500);
      expect(stats.service_status).toBe('active');
    });

    test('cleanup should clear all pending timers', async () => {
      await SettlementUpdateService.triggerRecalculation(testGroup.id, 'test1');
      await SettlementUpdateService.triggerRecalculation(999, 'test2');

      expect(SettlementUpdateService.getPendingRecalculations()).toHaveLength(2);

      SettlementUpdateService.cleanup();

      expect(SettlementUpdateService.getPendingRecalculations()).toHaveLength(0);
    });
  });

  describe('Broadcasting and Notifications', () => {
    test('broadcastSettlementUpdate should log broadcast information', () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
      
      const settlements = [{ id: 1, amount: 50 }];
      SettlementUpdateService.broadcastSettlementUpdate(testGroup.id, settlements, 'expense_created');

      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining(`Broadcasting settlement update for group ${testGroup.id}`),
        expect.objectContaining({
          changeType: 'expense_created',
          settlements_count: 1
        })
      );

      consoleSpy.mockRestore();
    });

    test('storeUpdateNotification should log notification storage', () => {
      const consoleSpy = jest.spyOn(console, 'log').mockImplementation();
      
      const notification = {
        type: 'settlement_update',
        changeType: 'expense_created',
        settlements_count: 1,
        timestamp: new Date().toISOString()
      };

      SettlementUpdateService.storeUpdateNotification(testGroup.id, notification);

      expect(consoleSpy).toHaveBeenCalledWith(
        expect.stringContaining(`Stored update notification for group ${testGroup.id}`),
        notification
      );

      consoleSpy.mockRestore();
    });
  });

  describe('Debouncing Behavior', () => {
    test('should execute recalculation after debounce delay', (done) => {
      // Use a shorter delay for testing
      SettlementUpdateService.triggerRecalculation(testGroup.id, 'test', { delay: 100 });

      // Check that recalculation hasn't been called immediately
      expect(Settlement.recalculateSettlements).not.toHaveBeenCalled();

      // Wait for debounce delay and check that recalculation was called
      setTimeout(() => {
        expect(Settlement.recalculateSettlements).toHaveBeenCalledWith(testGroup.id, {
          cleanupObsoleteAfterDays: 7
        });
        done();
      }, 150);
    });

    test('should reset debounce timer on subsequent calls', (done) => {
      // Use a shorter delay for testing
      SettlementUpdateService.triggerRecalculation(testGroup.id, 'test1', { delay: 100 });

      setTimeout(() => {
        // Trigger another recalculation before the first one executes
        SettlementUpdateService.triggerRecalculation(testGroup.id, 'test2', { delay: 100 });
      }, 50);

      // Check after the first delay that recalculation hasn't been called
      setTimeout(() => {
        expect(Settlement.recalculateSettlements).not.toHaveBeenCalled();
      }, 120);

      // Check after the second delay that recalculation was called once
      setTimeout(() => {
        expect(Settlement.recalculateSettlements).toHaveBeenCalledTimes(1);
        done();
      }, 200);
    });
  });

  describe('Error Handling', () => {
    test('should handle errors in debounced execution', (done) => {
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
      const error = new Error('Recalculation failed');
      
      Settlement.recalculateSettlements.mockRejectedValue(error);

      SettlementUpdateService.triggerRecalculation(testGroup.id, 'test', { delay: 50 });

      setTimeout(() => {
        expect(consoleSpy).toHaveBeenCalledWith(
          expect.stringContaining(`Failed to recalculate settlements for group ${testGroup.id}`),
          error
        );

        // Verify timer was cleaned up
        const pending = SettlementUpdateService.getPendingRecalculations();
        expect(pending).not.toContain(testGroup.id);

        consoleSpy.mockRestore();
        done();
      }, 100);
    });
  });
});