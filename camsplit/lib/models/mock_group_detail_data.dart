import 'group_detail_model.dart';
import 'group_member.dart';

/// Mock data provider for group detail functionality
/// This class provides realistic test data for group details including
/// expenses, debt relationships, and member information
/// 
/// Used for testing and development until backend integration is complete
class MockGroupDetailData {
  
  /// Generate mock group detail data for testing
  /// 
  /// [groupId] - The ID of the group to generate data for
  /// [userBalance] - Optional user balance override for testing different scenarios
  /// 
  /// Returns a complete [GroupDetailModel] with realistic test data
  static GroupDetailModel generateMockGroupDetail(int groupId, {double? userBalance}) {
    final now = DateTime.now();
    final members = _generateMockMembers(groupId);
    final expenses = _generateMockExpenses(groupId);
    
    return GroupDetailModel(
      id: groupId,
      name: _getGroupName(groupId),
      description: _getGroupDescription(groupId),
      imageUrl: _getGroupImageUrl(groupId),
      members: members,
      expenses: expenses,
      settlements: [],
      userBalance: userBalance ?? _calculateUserBalance(groupId),
      currency: 'EUR',
      lastActivity: now.subtract(Duration(hours: groupId % 24)),
      canEdit: true,
      canDelete: groupId == 1, // Only first group can be deleted for testing
      createdAt: now.subtract(Duration(days: 30 + groupId)),
      updatedAt: now.subtract(Duration(hours: groupId)),
    );
  }
  
  /// Generate mock API response format for group details
  static Map<String, dynamic> generateMockApiResponse(int groupId) {
    final groupDetail = generateMockGroupDetail(groupId);
    
    return {
      'group': groupDetail.toJson(),
      'status': 'success',
      'message': 'Group details retrieved successfully',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Generate mock balance API response
  static Map<String, dynamic> generateMockBalanceResponse(int groupId) {
            final balance = _calculateUserBalance(groupId);
    
    return {
      'balance': balance,
      'currency': 'EUR',
      'status': 'success',
      'message': 'User balance retrieved successfully',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  

  
  /// Generate mock member addition response
  static Map<String, dynamic> generateMockAddMemberResponse(String email, String name) {
    final now = DateTime.now();
    final memberId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final newMember = GroupMember(
      id: int.parse(memberId),
      groupId: 1, // Default group ID
      nickname: name,
      email: email,
      role: 'member',
      isRegisteredUser: true,
      createdAt: now,
      updatedAt: now,
    );
    
    return {
      'member': newMember.toJson(),
      'status': 'success',
      'message': 'Member added successfully',
      'timestamp': now.toIso8601String(),
    };
  }
  
  /// Generate mock member removal response
  static Map<String, dynamic> generateMockRemoveMemberResponse(int groupId, String memberId, {bool hasSettlements = false}) {
    if (hasSettlements) {
      return {
        'status': 'error',
        'message': 'Cannot remove member with active settlements',
        'hasSettlements': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    
    return {
      'status': 'success',
      'message': 'Member removed successfully',
      'hasDebts': false,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  // Private helper methods for generating mock data
  
  static List<GroupMember> _generateMockMembers(int groupId) {
    final now = DateTime.now();
    final memberData = [
      {'name': 'John Doe', 'email': 'john@example.com', 'isCurrentUser': true},
      {'name': 'Sarah Johnson', 'email': 'sarah@example.com', 'isCurrentUser': false},
      {'name': 'Mike Chen', 'email': 'mike@example.com', 'isCurrentUser': false},
      {'name': 'Emma Wilson', 'email': 'emma@example.com', 'isCurrentUser': false},
      {'name': 'Alex Rodriguez', 'email': 'alex@example.com', 'isCurrentUser': false},
    ];
    
    // Vary member count based on group ID
    final memberCount = 2 + (groupId % 4);
    
    return memberData.take(memberCount).map((data) {
      final memberId = (memberData.indexOf(data) + 1).toString();
      return GroupMember(
        id: int.parse(memberId),
        groupId: groupId,
        nickname: data['name'] as String,
        email: data['email'] as String,
        role: 'member',
        isRegisteredUser: true,
        createdAt: now.subtract(Duration(days: 10 + memberData.indexOf(data))),
        updatedAt: now.subtract(Duration(days: 10 + memberData.indexOf(data))),
      );
    }).toList();
  }
  
  static List<GroupExpense> _generateMockExpenses(int groupId) {
    final now = DateTime.now();
    final expenseData = [
      {'title': 'Dinner at Restaurant', 'amount': 85.50, 'payerName': 'John Doe', 'payerId': 1},
      {'title': 'Grocery Shopping', 'amount': 42.30, 'payerName': 'Sarah Johnson', 'payerId': 2},
      {'title': 'Movie Tickets', 'amount': 28.00, 'payerName': 'Mike Chen', 'payerId': 3},
      {'title': 'Gas for Trip', 'amount': 65.75, 'payerName': 'Emma Wilson', 'payerId': 4},
      {'title': 'Coffee Shop', 'amount': 15.20, 'payerName': 'John Doe', 'payerId': 1},
      {'title': 'Taxi Ride', 'amount': 22.50, 'payerName': 'Alex Rodriguez', 'payerId': 5},
    ];
    
    // Vary expense count based on group ID
    final expenseCount = 1 + (groupId % 5);
    
    return expenseData.take(expenseCount).map((data) {
      final expenseId = expenseData.indexOf(data) + 1;
      final daysAgo = expenseData.indexOf(data) + 1;
      
      return GroupExpense(
        id: expenseId,
        title: data['title'] as String,
        amount: data['amount'] as double,
        currency: 'EUR',
        date: now.subtract(Duration(days: daysAgo)),
        payerName: data['payerName'] as String,
        payerId: data['payerId'] as int,
        createdAt: now.subtract(Duration(days: daysAgo, hours: 2)),
      );
    }).toList();
  }
  

  
  static double _calculateUserBalance(int groupId) {
    // Calculate balance for user ID 1 (current user)
    // For now, return a mock balance based on group ID
    return (groupId % 3 - 1) * 25.0; // Returns -25, 0, or 25
  }
  
  static String _getGroupName(int groupId) {
    final names = [
      'Weekend Getaway',
      'Office Lunch Group',
      'Roommate Expenses',
      'Vacation Planning',
      'Study Group',
      'Family Dinner',
      'Book Club',
      'Hiking Adventures',
    ];
    
    return names[(groupId - 1) % names.length];
  }
  
  static String _getGroupDescription(int groupId) {
    final descriptions = [
      'Shared expenses for our weekend trip',
      'Daily lunch expenses at the office',
      'Monthly household and utility expenses',
      'Planning and expenses for summer vacation',
      'Study materials and group activities',
      'Weekly family dinner gatherings',
      'Monthly book purchases and meetups',
      'Gear and travel expenses for hiking trips',
    ];
    
    return descriptions[(groupId - 1) % descriptions.length];
  }
  
  static String? _getGroupImageUrl(int groupId) {
    // Some groups have images, others don't
    if (groupId % 3 == 0) {
      return null;
    }
    
    final imageIds = [
      'travel',
      'food',
      'home',
      'vacation',
      'study',
      'family',
      'books',
      'nature',
    ];
    
    final imageId = imageIds[(groupId - 1) % imageIds.length];
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(imageId)}&background=random&size=200';
  }
  
  /// Validate mock data integrity
  static bool validateMockData(GroupDetailModel groupDetail) {
    // Validate the group detail model
    if (!groupDetail.isValid()) {
      return false;
    }
    
    // Validate all members
    for (final member in groupDetail.members) {
      if (!member.isValid()) {
        return false;
      }
    }
    
    // Validate all expenses
    for (final expense in groupDetail.expenses) {
      if (!expense.isValid()) {
        return false;
      }
    }
    
    // Validate all settlements
    for (final settlement in groupDetail.settlements) {
      if (!settlement.isValid()) {
        return false;
      }
    }
    
    // Validate that current user exists in members
    final hasCurrentUser = groupDetail.members.any((member) => member.isCurrentUser);
    if (!hasCurrentUser) {
      return false;
    }
    
    // Validate balance calculation consistency
    const currentUserId = 1;
    double calculatedBalance = 0.0;
    
    for (final settlement in groupDetail.settlements) {
      if (settlement.toGroupMemberId == currentUserId) {
        calculatedBalance += settlement.amount;
      } else if (settlement.fromGroupMemberId == currentUserId) {
        calculatedBalance -= settlement.amount;
      }
    }
    
    // Allow small floating point differences
    if ((calculatedBalance - groupDetail.userBalance).abs() > 0.01) {
      return false;
    }
    
    return true;
  }
  
  /// Generate test scenarios for different group states
  static List<GroupDetailModel> generateTestScenarios() {
    return [
      // Scenario 1: Empty group (no expenses, no debts)
      GroupDetailModel(
        id: 100,
        name: 'Empty Group',
        description: 'A group with no activity',
        members: _generateMockMembers(100).take(2).toList(),
        expenses: [],
        settlements: [],
        userBalance: 0.0,
        currency: 'EUR',
        lastActivity: DateTime.now().subtract(Duration(days: 30)),
        canEdit: true,
        canDelete: true,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now().subtract(Duration(days: 30)),
      ),
      
      // Scenario 2: User owes money
      generateMockGroupDetail(101, userBalance: -45.50),
      
      // Scenario 3: User is owed money
      generateMockGroupDetail(102, userBalance: 32.75),
      
      // Scenario 4: User is settled up
      generateMockGroupDetail(103, userBalance: 0.0),
      
      // Scenario 5: Large group with many expenses
      generateMockGroupDetail(104),
    ];
  }
}