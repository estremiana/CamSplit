import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/models/group_detail_model.dart';

import 'package:camsplit/models/group_member.dart';

void main() {
  group('Model Integration Tests', () {
    test('should create complete GroupDetailModel with all related models', () {
      // Create a group member
      final member = GroupMember(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatar: 'avatar.jpg',
        isCurrentUser: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      // Create a group expense
      final expense = GroupExpense(
        id: 1,
        title: 'Test Expense',
        amount: 30.00,
        currency: 'EUR',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        payerName: 'Test User',
        payerId: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );



      // Create the complete group detail model
      final groupDetail = GroupDetailModel(
        id: 1,
        name: 'Integration Test Group',
        description: 'A group for testing integration',
        imageUrl: 'group.jpg',
        members: [member],
        expenses: [expense],

        settlements: [],
        userBalance: 15.00,
        currency: 'EUR',
        lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      // Verify all components work together
      expect(groupDetail.isValid(), true);
      expect(groupDetail.memberCount, 1);
      expect(groupDetail.expenseCount, 1);

      expect(groupDetail.currentUser, equals(member));
      expect(groupDetail.balanceStatus, 'You are owed 15.00EUR');
      expect(groupDetail.canRemoveMember('2'), true); // No active settlements
      expect(groupDetail.sortedExpenses.first, equals(expense));

      // Test JSON serialization round-trip
      final json = groupDetail.toJson();
      final reconstructed = GroupDetailModel.fromJson(json);
      
      expect(reconstructed.id, groupDetail.id);
      expect(reconstructed.name, groupDetail.name);
      expect(reconstructed.memberCount, groupDetail.memberCount);
      expect(reconstructed.expenseCount, groupDetail.expenseCount);

      expect(reconstructed.userBalance, groupDetail.userBalance);
    });

    test('should handle empty collections correctly', () {
      final member = GroupMember(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatar: 'avatar.jpg',
        isCurrentUser: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      final emptyGroupDetail = GroupDetailModel(
        id: 1,
        name: 'Empty Group',
        description: 'A group with no expenses or debts',
        members: [member],
        expenses: [],

        settlements: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now().subtract(const Duration(minutes: 30)),
        canEdit: true,
        canDelete: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(emptyGroupDetail.isValid(), true);
      expect(emptyGroupDetail.hasExpenses, false);

      expect(emptyGroupDetail.isSettledUp, true);
      expect(emptyGroupDetail.balanceStatus, 'You are settled up');
      expect(emptyGroupDetail.canRemoveMember('2'), true); // No active settlements
      expect(emptyGroupDetail.sortedExpenses, isEmpty);
    });
  });
}