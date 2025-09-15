const SettlementCalculatorService = require('../../src/services/SettlementCalculatorService');
const db = require('../../database/connection');
const User = require('../../src/models/User');
const Group = require('../../src/models/Group');
const GroupMember = require('../../src/models/GroupMember');
const Expense = require('../../src/models/Expense');

describe('SettlementCalculatorService', () => {
  let testGroup, testUsers, testMembers;

  beforeAll(async () => {
    // Create test users
    testUsers = [];
    for (let i = 1; i <= 4; i++) {
      const user = await User.create({
        first_name: `User${i}`,
        last_name: `Test`,
        email: `user${i}.settlement@test.com`,
        password: 'Test@1234'
      });
      testUsers.push(user);
    }

    // Create test group
    testGroup = await Group.create({
      name: 'Settlement Calculator Test Group',
      description: 'Test group for settlement calculator'
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
    await db.query('DELETE FROM group_members WHERE group_id = $1', [testGroup.id]);
    await db.query('DELETE FROM groups WHERE id = $1', [testGroup.id]);
    await db.query('DELETE FROM users WHERE id = ANY($1)', [testUsers.map(u => u.id)]);
  });

  afterEach(async () => {
    // Clean up expenses after each test
    await db.query('DELETE FROM expense_splits WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [testGroup.id]);
    await db.query('DELETE FROM expense_payers WHERE expense_id IN (SELECT id FROM expenses WHERE group_id = $1)', [testGroup.id]);
    await db.query('DELETE FROM expenses WHERE group_id = $1', [testGroup.id]);
  });

  describe('calculateGroupBalances', () => {
    test('should calculate balances with no expenses', async () => {
      const balances = await SettlementCalculatorService.calculateGroupBalances(testGroup.id);

      expect(balances).toHaveLength(4);
      balances.forEach(balance => {
        expect(balance.total_paid).toBe(0);
        expect(balance.total_owed).toBe(0);
        expect(balance.balance).toBe(0);
        expect(balance.member_id).toBeDefined();
        expect(balance.nickname).toBeDefined();
      });
    });

    test('should calculate balances with simple expense', async () => {
      // Create expense: User1 pays 100, split equally among all 4 members (25 each)
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

      const balances = await SettlementCalculatorService.calculateGroupBalances(testGroup.id);

      expect(balances).toHaveLength(4);
      
      // User1 paid 100, owes 25, balance = 75
      const user1Balance = balances.find(b => b.member_id === testMembers[0].id);
      expect(user1Balance.total_paid).toBe(100);
      expect(user1Balance.total_owed).toBe(25);
      expect(user1Balance.balance).toBe(75);

      // Other users paid 0, owe 25 each, balance = -25
      for (let i = 1; i < 4; i++) {
        const userBalance = balances.find(b => b.member_id === testMembers[i].id);
        expect(userBalance.total_paid).toBe(0);
        expect(userBalance.total_owed).toBe(25);
        expect(userBalance.balance).toBe(-25);
      }
    });

    test('should calculate balances with multiple expenses and payers', async () => {
      // Expense 1: User1 pays 60, split equally (15 each)
      const expense1 = await Expense.create({
        title: 'Expense 1',
        amount: 60.00,
        currency: 'EUR',
        group_id: testGroup.id,
        created_by: testUsers[0].id
      });

      await db.query(
        'INSERT INTO expense_payers (expense_id, group_member_id, amount_paid) VALUES ($1, $2, $3)',
        [expense1.id, testMembers[0].id, 60.00]
      );

      for (let i = 0; i < 4; i++) {
        await db.query(
          'INSERT INTO expense_splits (expense_id, group_member_id, amount_owed, split_type) VALUES ($1, $2, $3, $4)',
          [expense1.id, testMembers[i].id, 15.00, 'equal']
        );
      }

      // Expense 2: User2 pays 40, split equally (10 each)
      const expense2 = await Expense.create({
        title: 'Expense 2',
        amount: 40.00,
        currency: 'EUR',
        group_id: testGroup.id,
        created_by: testUsers[1].id
      });

      await db.query(
        'INSERT INTO expense_payers (expense_id, group_member_id, amount_paid) VALUES ($1, $2, $3)',
        [expense2.id, testMembers[1].id, 40.00]
      );

      for (let i = 0; i < 4; i++) {
        await db.query(
          'INSERT INTO expense_splits (expense_id, group_member_id, amount_owed, split_type) VALUES ($1, $2, $3, $4)',
          [expense2.id, testMembers[i].id, 10.00, 'equal']
        );
      }

      const balances = await SettlementCalculatorService.calculateGroupBalances(testGroup.id);

      // User1: paid 60, owes 25, balance = 35
      const user1Balance = balances.find(b => b.member_id === testMembers[0].id);
      expect(user1Balance.balance).toBe(35);

      // User2: paid 40, owes 25, balance = 15
      const user2Balance = balances.find(b => b.member_id === testMembers[1].id);
      expect(user2Balance.balance).toBe(15);

      // User3 & User4: paid 0, owe 25 each, balance = -25
      const user3Balance = balances.find(b => b.member_id === testMembers[2].id);
      const user4Balance = balances.find(b => b.member_id === testMembers[3].id);
      expect(user3Balance.balance).toBe(-25);
      expect(user4Balance.balance).toBe(-25);
    });
  });

  describe('optimizeSettlements', () => {
    test('should return empty array for zero balances', () => {
      const balances = [
        { member_id: 1, nickname: 'User1', balance: 0 },
        { member_id: 2, nickname: 'User2', balance: 0 }
      ];

      const settlements = SettlementCalculatorService.optimizeSettlements(balances);
      expect(settlements).toHaveLength(0);
    });

    test('should create single settlement for simple case', () => {
      const balances = [
        { 
          member_id: 1, 
          nickname: 'User1', 
          user_id: 1,
          user_name: 'User One',
          user_avatar: null,
          balance: 50 
        },
        { 
          member_id: 2, 
          nickname: 'User2', 
          user_id: 2,
          user_name: 'User Two',
          user_avatar: null,
          balance: -50 
        }
      ];

      const settlements = SettlementCalculatorService.optimizeSettlements(balances);

      expect(settlements).toHaveLength(1);
      expect(settlements[0].from_group_member_id).toBe(2); // User2 owes
      expect(settlements[0].to_group_member_id).toBe(1);   // User1 receives
      expect(settlements[0].amount).toBe(50);
      expect(settlements[0].from_member.nickname).toBe('User2');
      expect(settlements[0].to_member.nickname).toBe('User1');
    });

    test('should optimize multiple settlements', () => {
      const balances = [
        { member_id: 1, nickname: 'User1', user_id: 1, user_name: 'User One', user_avatar: null, balance: 75 },
        { member_id: 2, nickname: 'User2', user_id: 2, user_name: 'User Two', user_avatar: null, balance: -25 },
        { member_id: 3, nickname: 'User3', user_id: 3, user_name: 'User Three', user_avatar: null, balance: -25 },
        { member_id: 4, nickname: 'User4', user_id: 4, user_name: 'User Four', user_avatar: null, balance: -25 }
      ];

      const settlements = SettlementCalculatorService.optimizeSettlements(balances);

      expect(settlements).toHaveLength(3); // Optimal: 3 settlements instead of 3x1=3
      
      // Verify total amounts balance
      const totalSettlements = settlements.reduce((sum, s) => sum + s.amount, 0);
      expect(totalSettlements).toBe(75);

      // Verify all debtors pay to User1
      settlements.forEach(settlement => {
        expect(settlement.to_group_member_id).toBe(1);
        expect([2, 3, 4]).toContain(settlement.from_group_member_id);
        expect(settlement.amount).toBe(25);
      });
    });

    test('should handle complex multi-creditor scenario', () => {
      const balances = [
        { member_id: 1, nickname: 'User1', user_id: 1, user_name: 'User One', user_avatar: null, balance: 60 },
        { member_id: 2, nickname: 'User2', user_id: 2, user_name: 'User Two', user_avatar: null, balance: 40 },
        { member_id: 3, nickname: 'User3', user_id: 3, user_name: 'User Three', user_avatar: null, balance: -30 },
        { member_id: 4, nickname: 'User4', user_id: 4, user_name: 'User Four', user_avatar: null, balance: -70 }
      ];

      const settlements = SettlementCalculatorService.optimizeSettlements(balances);

      expect(settlements).toHaveLength(3); // Should be optimal
      
      // Verify total amounts balance
      const totalSettlements = settlements.reduce((sum, s) => sum + s.amount, 0);
      expect(totalSettlements).toBe(100);

      // Verify settlement logic
      const user4Settlements = settlements.filter(s => s.from_group_member_id === 4);
      const user3Settlements = settlements.filter(s => s.from_group_member_id === 3);
      
      expect(user4Settlements.length).toBeGreaterThan(0); // User4 owes the most
      expect(user3Settlements.length).toBeGreaterThan(0); // User3 also owes
    });

    test('should round amounts to 2 decimal places', () => {
      const balances = [
        { member_id: 1, nickname: 'User1', user_id: 1, user_name: 'User One', user_avatar: null, balance: 33.333 },
        { member_id: 2, nickname: 'User2', user_id: 2, user_name: 'User Two', user_avatar: null, balance: -33.333 }
      ];

      const settlements = SettlementCalculatorService.optimizeSettlements(balances);

      expect(settlements).toHaveLength(1);
      expect(settlements[0].amount).toBe(33.33);
    });
  });

  describe('validateSettlements', () => {
    test('should validate empty settlements with zero balances', () => {
      const settlements = [];
      const balances = [
        { member_id: 1, balance: 0 },
        { member_id: 2, balance: 0 }
      ];

      const validation = SettlementCalculatorService.validateSettlements(settlements, balances);
      expect(validation.isValid).toBe(true);
      expect(validation.errors).toHaveLength(0);
    });

    test('should reject empty settlements with non-zero balances', () => {
      const settlements = [];
      const balances = [
        { member_id: 1, balance: 50 },
        { member_id: 2, balance: -50 }
      ];

      const validation = SettlementCalculatorService.validateSettlements(settlements, balances);
      expect(validation.isValid).toBe(false);
      expect(validation.errors).toContain('No settlements generated but non-zero balances exist');
    });

    test('should validate correct settlements', () => {
      const settlements = [
        {
          from_group_member_id: 2,
          to_group_member_id: 1,
          amount: 50
        }
      ];
      const balances = [
        { member_id: 1, balance: 50 },
        { member_id: 2, balance: -50 }
      ];

      const validation = SettlementCalculatorService.validateSettlements(settlements, balances);
      expect(validation.isValid).toBe(true);
      expect(validation.errors).toHaveLength(0);
    });

    test('should reject settlements with missing fields', () => {
      const settlements = [
        {
          from_group_member_id: null,
          to_group_member_id: 1,
          amount: 50
        }
      ];
      const balances = [
        { member_id: 1, balance: 50 },
        { member_id: 2, balance: -50 }
      ];

      const validation = SettlementCalculatorService.validateSettlements(settlements, balances);
      expect(validation.isValid).toBe(false);
      expect(validation.errors.some(e => e.includes('Missing from_group_member_id'))).toBe(true);
    });

    test('should reject settlements with same from and to members', () => {
      const settlements = [
        {
          from_group_member_id: 1,
          to_group_member_id: 1,
          amount: 50
        }
      ];
      const balances = [
        { member_id: 1, balance: 0 }
      ];

      const validation = SettlementCalculatorService.validateSettlements(settlements, balances);
      expect(validation.isValid).toBe(false);
      expect(validation.errors.some(e => e.includes('From and to members cannot be the same'))).toBe(true);
    });

    test('should reject settlements that don\'t balance', () => {
      const settlements = [
        {
          from_group_member_id: 2,
          to_group_member_id: 1,
          amount: 30 // Should be 50 to balance
        }
      ];
      const balances = [
        { member_id: 1, balance: 50 },
        { member_id: 2, balance: -50 }
      ];

      const validation = SettlementCalculatorService.validateSettlements(settlements, balances);
      expect(validation.isValid).toBe(false);
      expect(validation.errors.some(e => e.includes('remaining balance'))).toBe(true);
    });

    test('should reject duplicate settlement pairs', () => {
      const settlements = [
        {
          from_group_member_id: 2,
          to_group_member_id: 1,
          amount: 25
        },
        {
          from_group_member_id: 2,
          to_group_member_id: 1,
          amount: 25
        }
      ];
      const balances = [
        { member_id: 1, balance: 50 },
        { member_id: 2, balance: -50 }
      ];

      const validation = SettlementCalculatorService.validateSettlements(settlements, balances);
      expect(validation.isValid).toBe(false);
      expect(validation.errors.some(e => e.includes('Duplicate settlement pair'))).toBe(true);
    });
  });

  describe('calculateOptimalSettlements', () => {
    test('should calculate optimal settlements for group with expenses', async () => {
      // Create expense: User1 pays 100, split equally among all 4 members (25 each)
      const expense = await Expense.create({
        title: 'Test Expense',
        amount: 100.00,
        currency: 'EUR',
        group_id: testGroup.id,
        created_by: testUsers[0].id
      });

      await db.query(
        'INSERT INTO expense_payers (expense_id, group_member_id, amount_paid) VALUES ($1, $2, $3)',
        [expense.id, testMembers[0].id, 100.00]
      );

      for (let i = 0; i < 4; i++) {
        await db.query(
          'INSERT INTO expense_splits (expense_id, group_member_id, amount_owed, split_type) VALUES ($1, $2, $3, $4)',
          [expense.id, testMembers[i].id, 25.00, 'equal']
        );
      }

      const result = await SettlementCalculatorService.calculateOptimalSettlements(testGroup.id);

      expect(result.settlements).toHaveLength(3);
      expect(result.balances).toHaveLength(4);
      expect(result.validation.isValid).toBe(true);
      expect(result.summary.total_settlements).toBe(3);
      expect(result.summary.total_amount).toBe(75);
      expect(result.summary.members_involved).toBe(4);

      // Verify all settlements are to User1
      result.settlements.forEach(settlement => {
        expect(settlement.to_group_member_id).toBe(testMembers[0].id);
        expect(settlement.amount).toBe(25);
      });
    });

    test('should return empty settlements for balanced group', async () => {
      const result = await SettlementCalculatorService.calculateOptimalSettlements(testGroup.id);

      expect(result.settlements).toHaveLength(0);
      expect(result.balances).toHaveLength(4);
      expect(result.validation.isValid).toBe(true);
      expect(result.summary.total_settlements).toBe(0);
      expect(result.summary.total_amount).toBe(0);
    });
  });

  describe('getSettlementStatistics', () => {
    test('should calculate statistics for balanced group', () => {
      const balances = [
        { member_id: 1, balance: 0 },
        { member_id: 2, balance: 0 },
        { member_id: 3, balance: 0 },
        { member_id: 4, balance: 0 }
      ];

      const stats = SettlementCalculatorService.getSettlementStatistics(balances);

      expect(stats.total_members).toBe(4);
      expect(stats.members_with_balance).toBe(0);
      expect(stats.creditors_count).toBe(0);
      expect(stats.debtors_count).toBe(0);
      expect(stats.total_debt).toBe(0);
      expect(stats.total_credit).toBe(0);
    });

    test('should calculate statistics for unbalanced group', () => {
      const balances = [
        { member_id: 1, balance: 75 },
        { member_id: 2, balance: -25 },
        { member_id: 3, balance: -25 },
        { member_id: 4, balance: -25 }
      ];

      const stats = SettlementCalculatorService.getSettlementStatistics(balances);

      expect(stats.total_members).toBe(4);
      expect(stats.members_with_balance).toBe(4);
      expect(stats.creditors_count).toBe(1);
      expect(stats.debtors_count).toBe(3);
      expect(stats.total_debt).toBe(75);
      expect(stats.total_credit).toBe(75);
      expect(stats.balance_difference).toBe(0);
      expect(stats.max_transactions_without_optimization).toBe(3);
      expect(stats.theoretical_min_transactions).toBe(2);
    });
  });

  describe('Error Handling', () => {
    test('should handle invalid group ID', async () => {
      await expect(
        SettlementCalculatorService.calculateGroupBalances(99999)
      ).resolves.toEqual([]); // Should return empty array for non-existent group
    });

    test('should handle invalid balances in optimization', () => {
      expect(() => {
        SettlementCalculatorService.optimizeSettlements(null);
      }).toThrow('Failed to optimize settlements');
    });

    test('should handle validation errors gracefully', () => {
      const validation = SettlementCalculatorService.validateSettlements('invalid', []);
      expect(validation.isValid).toBe(false);
      expect(validation.errors).toContain('Settlements must be an array');
    });
  });
});