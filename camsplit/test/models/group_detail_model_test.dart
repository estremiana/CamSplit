import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/models/group_detail_model.dart';
import 'package:camsplit/models/group_member.dart';
import 'package:camsplit/models/debt_relationship_model.dart';
import 'package:camsplit/services/currency_service.dart';

void main() {
  group('GroupExpense Model Tests', () {
    test('should create GroupExpense from JSON correctly', () {
      final json = {
        'id': 1,
        'title': 'Dinner at Restaurant',
        'amount': 45.50,
        'currency': 'EUR',
        'date': '2024-01-15T19:30:00.000Z',
        'payer_name': 'John Doe',
        'payer_id': 123,
        'created_at': '2024-01-15T19:35:00.000Z',
      };

      final expense = GroupExpense.fromJson(json);

      expect(expense.id, 1);
      expect(expense.title, 'Dinner at Restaurant');
      expect(expense.amount, 45.50);
      expect(expense.currency, 'EUR');
      expect(expense.payerName, 'John Doe');
      expect(expense.payerId, 123);
    });

    test('should convert GroupExpense to JSON correctly', () {
      final expense = GroupExpense(
        id: 1,
        title: 'Lunch',
        amount: 25.00,
        currency: 'EUR',
        date: DateTime.parse('2024-01-15T12:00:00.000Z'),
        payerName: 'Jane Smith',
        payerId: 456,
        createdAt: DateTime.parse('2024-01-15T12:05:00.000Z'),
      );

      final json = expense.toJson();

      expect(json['id'], 1);
      expect(json['title'], 'Lunch');
      expect(json['amount'], 25.00);
      expect(json['currency'], 'EUR');
      expect(json['payer_name'], 'Jane Smith');
      expect(json['payer_id'], 456);
    });

    test('should validate GroupExpense correctly', () {
      final validExpense = GroupExpense(
        id: 1,
        title: 'Valid Expense',
        amount: 10.00,
        currency: 'EUR',
        date: DateTime.now().subtract(const Duration(hours: 1)),
        payerName: 'Test User',
        payerId: 1,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(validExpense.isValid(), true);

      final invalidExpense = GroupExpense(
        id: 0,
        title: '',
        amount: -5.00,
        currency: '',
        date: DateTime.now().add(const Duration(days: 2)),
        payerName: '',
        payerId: 0,
        createdAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(invalidExpense.isValid(), false);
    });

    test('should handle equality and hashCode correctly', () {
      final expense1 = GroupExpense(
        id: 1,
        title: 'Test',
        amount: 10.00,
        currency: 'EUR',
        date: DateTime.now(),
        payerName: 'User',
        payerId: 1,
        createdAt: DateTime.now(),
      );

      final expense2 = GroupExpense(
        id: 1,
        title: 'Different Title',
        amount: 20.00,
        currency: 'USD',
        date: DateTime.now(),
        payerName: 'Different User',
        payerId: 2,
        createdAt: DateTime.now(),
      );

      final expense3 = GroupExpense(
        id: 2,
        title: 'Test',
        amount: 10.00,
        currency: 'EUR',
        date: DateTime.now(),
        payerName: 'User',
        payerId: 1,
        createdAt: DateTime.now(),
      );

      expect(expense1, equals(expense2)); // Same ID
      expect(expense1, isNot(equals(expense3))); // Different ID
      expect(expense1.hashCode, equals(expense2.hashCode));
      expect(expense1.hashCode, isNot(equals(expense3.hashCode)));
    });
  });

  group('GroupDetailModel Model Tests', () {
    late GroupMember testMember;
    late GroupExpense testExpense;

    setUp(() {
      testMember = GroupMember(
        id: 1,
        groupId: 1,
        nickname: 'Test User',
        email: 'test@example.com',
        role: 'member',
        isRegisteredUser: true,
        avatarUrl: 'avatar.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      testExpense = GroupExpense(
        id: 1,
        title: 'Test Expense',
        amount: 30.00,
        currency: 'EUR',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        payerName: 'Test User',
        payerId: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );


    });

    test('should create GroupDetailModel from JSON correctly', () {
      final json = {
        'id': 1,
        'name': 'Test Group',
        'description': 'A test group',
        'image_url': 'group.jpg',
        'members': [
          {
            'id': '1',
            'name': 'Test User',
            'email': 'test@example.com',
            'avatar': 'avatar.jpg',
            'is_current_user': true,
            'joined_at': '2024-01-01T00:00:00.000Z',
          }
        ],
        'expenses': [
          {
            'id': 1,
            'title': 'Test Expense',
            'amount': 30.00,
            'currency': 'EUR',
            'date': '2024-01-15T12:00:00.000Z',
            'payer_name': 'Test User',
            'payer_id': 1,
            'created_at': '2024-01-15T12:05:00.000Z',
          }
        ],

        'user_balance': 15.00,
        'currency': 'EUR',
        'last_activity': '2024-01-15T15:00:00.000Z',
        'can_edit': true,
        'can_delete': false,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-15T15:00:00.000Z',
      };

      final groupDetail = GroupDetailModel.fromJson(json);

      expect(groupDetail.id, 1);
      expect(groupDetail.name, 'Test Group');
      expect(groupDetail.description, 'A test group');
      expect(groupDetail.imageUrl, 'group.jpg');
      expect(groupDetail.members.length, 1);
      expect(groupDetail.expenses.length, 1);
      expect(groupDetail.userBalance, 15.00);
      expect(groupDetail.currency, 'EUR');
      expect(groupDetail.canEdit, true);
      expect(groupDetail.canDelete, false);
    });

    test('should convert GroupDetailModel to JSON correctly', () {
      final groupDetail = GroupDetailModel(
        id: 1,
        name: 'Test Group',
        description: 'A test group',
        imageUrl: 'group.jpg',
        members: [testMember],
        expenses: [testExpense],
        settlements: [],
        userBalance: 15.00,
        currency: 'EUR',
        lastActivity: DateTime.parse('2024-01-15T15:00:00.000Z'),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T15:00:00.000Z'),
      );

      final json = groupDetail.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Test Group');
      expect(json['description'], 'A test group');
      expect(json['image_url'], 'group.jpg');
      expect(json['members'], isA<List>());
      expect(json['expenses'], isA<List>());
      expect(json['settlements'], isA<List>());
      expect(json['user_balance'], 15.00);
      expect(json['currency'], 'EUR');
      expect(json['can_edit'], true);
      expect(json['can_delete'], false);
    });

    test('should validate GroupDetailModel correctly', () {
      final validGroupDetail = GroupDetailModel(
        id: 1,
        name: 'Valid Group',
        description: 'Valid description',
        members: [testMember],
        expenses: [testExpense],
        settlements: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(validGroupDetail.isValid(), true);
      expect(validGroupDetail.hasValidTimestamps(), true);

      final invalidGroupDetail = GroupDetailModel(
        id: 0,
        name: '',
        description: '',
        members: [],
        expenses: [],
        settlements: [],
        userBalance: 0.00,
        currency: '',
        lastActivity: DateTime.now(),
        canEdit: false,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(invalidGroupDetail.isValid(), false);
      expect(invalidGroupDetail.hasValidTimestamps(), false);
    });

    test('should provide correct helper methods', () {
      final groupDetail = GroupDetailModel(
        id: 1,
        name: 'Test Group',
        description: 'Test description',
        members: [testMember],
        expenses: [testExpense],
        settlements: [],
        userBalance: 15.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      );

      expect(groupDetail.memberCount, 1);
      expect(groupDetail.expenseCount, 1);
      expect(groupDetail.hasExpenses, true);
      expect(groupDetail.hasSettlements, false);
      expect(groupDetail.isSettledUp, false);
      expect(groupDetail.currentUser, equals(testMember));
    });

    test('should provide correct balance status messages', () {
      final positiveBalance = GroupDetailModel(
        id: 1,
        name: 'Test',
        description: '',
        members: [testMember],
        expenses: [],
        settlements: [],
        userBalance: 25.50,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: false,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final negativeBalance = GroupDetailModel(
        id: 1,
        name: 'Test',
        description: '',
        members: [testMember],
        expenses: [],
        settlements: [],
        userBalance: -15.75,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: false,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final zeroBalance = GroupDetailModel(
        id: 1,
        name: 'Test',
        description: '',
        members: [testMember],
        expenses: [],
        settlements: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: false,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(positiveBalance.balanceStatus, 'You are owed 25.50EUR');
      expect(negativeBalance.balanceStatus, 'You owe 15.75EUR');
      expect(zeroBalance.balanceStatus, 'You are settled up');
    });

    test('should sort expenses by date correctly', () {
      final oldExpense = GroupExpense(
        id: 1,
        title: 'Old Expense',
        amount: 10.00,
        currency: 'EUR',
        date: DateTime.now().subtract(const Duration(days: 2)),
        payerName: 'User',
        payerId: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      final newExpense = GroupExpense(
        id: 2,
        title: 'New Expense',
        amount: 20.00,
        currency: 'EUR',
        date: DateTime.now().subtract(const Duration(hours: 1)),
        payerName: 'User',
        payerId: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final groupDetail = GroupDetailModel(
        id: 1,
        name: 'Test',
        description: '',
        members: [testMember],
        expenses: [oldExpense, newExpense],
        settlements: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: false,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final sortedExpenses = groupDetail.sortedExpenses;
      expect(sortedExpenses.first.id, 2); // New expense first
      expect(sortedExpenses.last.id, 1); // Old expense last
    });

    test('should check member removal permissions correctly', () {
      final groupDetail = GroupDetailModel(
        id: 1,
        name: 'Test',
        description: '',
        members: [testMember],
        expenses: [],
        settlements: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(groupDetail.canRemoveMember('2'), true); // No active settlements
      expect(groupDetail.canRemoveMember('3'), true); // No active settlements

      final noEditPermission = GroupDetailModel(
        id: 1,
        name: 'Test',
        description: '',
        members: [testMember],
        expenses: [],
        settlements: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: false,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(noEditPermission.canRemoveMember('3'), false); // No edit permission
    });

    test('should handle equality and hashCode correctly', () {
      final groupDetail1 = GroupDetailModel(
        id: 1,
        name: 'Test',
        description: '',
        members: [],
        expenses: [],
        settlements: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: false,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final groupDetail2 = GroupDetailModel(
        id: 1,
        name: 'Different Name',
        description: 'Different description',
        members: [],
        expenses: [],
        settlements: [],
        userBalance: 100.00,
        currency: 'USD',
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final groupDetail3 = GroupDetailModel(
        id: 2,
        name: 'Test',
        description: '',
        members: [],
        expenses: [],
        settlements: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: false,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(groupDetail1, equals(groupDetail2)); // Same ID
      expect(groupDetail1, isNot(equals(groupDetail3))); // Different ID
      expect(groupDetail1.hashCode, equals(groupDetail2.hashCode));
      expect(groupDetail1.hashCode, isNot(equals(groupDetail3.hashCode)));
    });
  });
}