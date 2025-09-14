import 'group.dart';
import 'group_member.dart';
import '../services/currency_migration_service.dart';

class MockGroupData {
  static List<Group> getMockGroups() {
    return [
      // Roommates Group
      Group(
        id: 1,
        name: 'Roommates',
        currency: CurrencyMigrationService.parseFromBackend('USD'),
        description: 'Apartment expenses with roommates',
        createdBy: 1,
        members: [
          GroupMember(
            id: 1,
            groupId: 1,
            userId: 1,
            nickname: 'You',
            email: 'you@example.com',
            role: 'admin',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 30)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 2,
            groupId: 1,
            userId: 2,
            nickname: 'Sarah Johnson',
            email: 'sarah@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 29)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 3,
            groupId: 1,
            userId: 3,
            nickname: 'Mike Chen',
            email: 'mike@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 28)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 4,
            groupId: 1,
            userId: 4,
            nickname: 'Jessica Taylor',
            email: 'jessica@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 27)),
            updatedAt: DateTime.now(),
          ),
        ],
        lastUsed: DateTime.now(),
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),

      // Work Team Group
      Group(
        id: 2,
        name: 'Work Team',
        currency: CurrencyMigrationService.parseFromBackend('USD'),
        description: 'Team lunch and coffee expenses',
        createdBy: 1,
        members: [
          GroupMember(
            id: 5,
            groupId: 2,
            userId: 1,
            nickname: 'You',
            email: 'you@example.com',
            role: 'admin',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 20)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 6,
            groupId: 2,
            userId: 5,
            nickname: 'Emma Wilson',
            email: 'emma@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 19)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 7,
            groupId: 2,
            userId: 6,
            nickname: 'Alex Rodriguez',
            email: 'alex@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 18)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 8,
            groupId: 2,
            userId: 7,
            nickname: 'Lisa Park',
            email: 'lisa@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 17)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 9,
            groupId: 2,
            userId: 8,
            nickname: 'David Kim',
            email: 'david@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 16)),
            updatedAt: DateTime.now(),
          ),
        ],
        lastUsed: DateTime.now().subtract(Duration(days: 1)),
        createdAt: DateTime.now().subtract(Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),

      // Family Group
      Group(
        id: 3,
        name: 'Family',
        currency: CurrencyMigrationService.parseFromBackend('USD'),
        description: 'Family expenses and groceries',
        createdBy: 1,
        members: [
          GroupMember(
            id: 10,
            groupId: 3,
            userId: 1,
            nickname: 'You',
            email: 'you@example.com',
            role: 'admin',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 60)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 11,
            groupId: 3,
            userId: null,
            nickname: 'Mom',
            email: 'mom@example.com',
            role: 'member',
            isRegisteredUser: false,
            createdAt: DateTime.now().subtract(Duration(days: 59)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 12,
            groupId: 3,
            userId: null,
            nickname: 'Dad',
            email: 'dad@example.com',
            role: 'member',
            isRegisteredUser: false,
            createdAt: DateTime.now().subtract(Duration(days: 58)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 13,
            groupId: 3,
            userId: null,
            nickname: 'Sister',
            email: 'sister@example.com',
            role: 'member',
            isRegisteredUser: false,
            createdAt: DateTime.now().subtract(Duration(days: 57)),
            updatedAt: DateTime.now(),
          ),
        ],
        lastUsed: DateTime.now().subtract(Duration(days: 3)),
        createdAt: DateTime.now().subtract(Duration(days: 60)),
        updatedAt: DateTime.now(),
      ),

      // Trip Group
      Group(
        id: 4,
        name: 'Weekend Trip',
        currency: CurrencyMigrationService.parseFromBackend('USD'),
        description: 'Weekend getaway expenses',
        createdBy: 1,
        members: [
          GroupMember(
            id: 14,
            groupId: 4,
            userId: 1,
            nickname: 'You',
            email: 'you@example.com',
            role: 'admin',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 10)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 15,
            groupId: 4,
            userId: 9,
            nickname: 'Rachel Green',
            email: 'rachel@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 9)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 16,
            groupId: 4,
            userId: 10,
            nickname: 'Tom Anderson',
            email: 'tom@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 8)),
            updatedAt: DateTime.now(),
          ),
        ],
        lastUsed: DateTime.now().subtract(Duration(days: 5)),
        createdAt: DateTime.now().subtract(Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),

      // Study Group
      Group(
        id: 5,
        name: 'Study Group',
        currency: CurrencyMigrationService.parseFromBackend('USD'),
        description: 'Study materials and coffee',
        createdBy: 1,
        members: [
          GroupMember(
            id: 17,
            groupId: 5,
            userId: 1,
            nickname: 'You',
            email: 'you@example.com',
            role: 'admin',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 15)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 18,
            groupId: 5,
            userId: 11,
            nickname: 'Chris Martinez',
            email: 'chris@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 14)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 19,
            groupId: 5,
            userId: 12,
            nickname: 'Amy Foster',
            email: 'amy@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 13)),
            updatedAt: DateTime.now(),
          ),
        ],
        lastUsed: DateTime.now().subtract(Duration(days: 2)),
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),

      // Gym Group
      Group(
        id: 6,
        name: 'Gym Buddies',
        currency: CurrencyMigrationService.parseFromBackend('USD'),
        description: 'Gym membership and supplements',
        createdBy: 1,
        members: [
          GroupMember(
            id: 20,
            groupId: 6,
            userId: 1,
            nickname: 'You',
            email: 'you@example.com',
            role: 'admin',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 45)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 21,
            groupId: 6,
            userId: 13,
            nickname: 'Helen Davis',
            email: 'helen@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 44)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 22,
            groupId: 6,
            userId: 14,
            nickname: 'Robert Brown',
            email: 'robert@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 43)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 23,
            groupId: 6,
            userId: 15,
            nickname: 'Maria Garcia',
            email: 'maria@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 42)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 24,
            groupId: 6,
            userId: 16,
            nickname: 'Kevin Lee',
            email: 'kevin@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 41)),
            updatedAt: DateTime.now(),
          ),
        ],
        lastUsed: DateTime.now().subtract(Duration(days: 1)),
        createdAt: DateTime.now().subtract(Duration(days: 45)),
        updatedAt: DateTime.now(),
      ),

      // Book Club
      Group(
        id: 7,
        name: 'Book Club',
        currency: CurrencyMigrationService.parseFromBackend('USD'),
        description: 'Book purchases and coffee meetings',
        createdBy: 1,
        members: [
          GroupMember(
            id: 25,
            groupId: 7,
            userId: 1,
            nickname: 'You',
            email: 'you@example.com',
            role: 'admin',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 25)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 26,
            groupId: 7,
            userId: 17,
            nickname: 'Marcus Johnson',
            email: 'marcus@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 24)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 27,
            groupId: 7,
            userId: 18,
            nickname: 'Sophia Williams',
            email: 'sophia@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 23)),
            updatedAt: DateTime.now(),
          ),
        ],
        lastUsed: DateTime.now().subtract(Duration(days: 4)),
        createdAt: DateTime.now().subtract(Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),

      // Cooking Club
      Group(
        id: 8,
        name: 'Cooking Club',
        currency: CurrencyMigrationService.parseFromBackend('USD'),
        description: 'Ingredients and cooking supplies',
        createdBy: 1,
        members: [
          GroupMember(
            id: 28,
            groupId: 8,
            userId: 1,
            nickname: 'You',
            email: 'you@example.com',
            role: 'admin',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 35)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 29,
            groupId: 8,
            userId: 19,
            nickname: 'Oliver Thompson',
            email: 'oliver@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 34)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 30,
            groupId: 8,
            userId: 20,
            nickname: 'Isabella Martinez',
            email: 'isabella@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 33)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 31,
            groupId: 8,
            userId: 21,
            nickname: 'Ethan Wilson',
            email: 'ethan@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 32)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 32,
            groupId: 8,
            userId: 22,
            nickname: 'Ava Davis',
            email: 'ava@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 31)),
            updatedAt: DateTime.now(),
          ),
          GroupMember(
            id: 33,
            groupId: 8,
            userId: 23,
            nickname: 'Liam Anderson',
            email: 'liam@example.com',
            role: 'member',
            isRegisteredUser: true,
            createdAt: DateTime.now().subtract(Duration(days: 30)),
            updatedAt: DateTime.now(),
          ),
        ],
        lastUsed: DateTime.now().subtract(Duration(days: 6)),
        createdAt: DateTime.now().subtract(Duration(days: 35)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  // Helper method to get groups sorted by most recent usage (as required by backend spec)
  static List<Group> getGroupsSortedByMostRecent() {
    final groups = getMockGroups();
    groups.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return groups;
  }

  // Helper method to get a specific group by ID
  static Group? getGroupById(String groupId) {
    try {
      final id = int.tryParse(groupId);
      if (id == null) return null;
      return getMockGroups().firstWhere((group) => group.id == id);
    } catch (e) {
      return null;
    }
  }

  // Helper method to validate mock data integrity
  static bool validateMockData() {
    final groups = getMockGroups();
    
    // Check that all groups are valid
    for (final group in groups) {
      if (!group.isValid() || !group.hasValidTimestamps()) {
        return false;
      }
    }
    
    // Check that each group has at least one current user
    for (final group in groups) {
      if (!group.hasCurrentUser) {
        return false;
      }
    }
    
    // Check for unique group IDs
    final groupIds = groups.map((g) => g.id).toSet();
    if (groupIds.length != groups.length) {
      return false;
    }
    
    return true;
  }

  // Helper method to get the most recently used group (default selection)
  static Group? getMostRecentGroup() {
    final groups = getGroupsSortedByMostRecent();
    return groups.isNotEmpty ? groups.first : null;
  }

  // Helper method to search groups by name (for future search functionality)
  static List<Group> searchGroupsByName(String query) {
    if (query.isEmpty) return getGroupsSortedByMostRecent();
    
    final groups = getMockGroups();
    return groups.where((group) => 
      group.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Helper method to get groups with specific member count range
  static List<Group> getGroupsByMemberCount(int minMembers, int maxMembers) {
    final groups = getMockGroups();
    return groups.where((group) => 
      group.memberCount >= minMembers && group.memberCount <= maxMembers
    ).toList();
  }

  // Simulate backend response format for groups endpoint
  // This matches the expected API response structure for easy backend integration
  static Map<String, dynamic> simulateGroupsApiResponse() {
    return {
      'groups': getGroupsSortedByMostRecent().map((group) => group.toJson()).toList(),
      'count': getMockGroups().length,
      'message': 'Groups retrieved successfully',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'success',
    };
  }

  // Simulate paginated groups response (for future pagination support)
  static Map<String, dynamic> simulateGroupsApiResponsePaginated({
    int page = 1,
    int limit = 10,
  }) {
    final allGroups = getGroupsSortedByMostRecent();
    final startIndex = (page - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, allGroups.length);
    final paginatedGroups = allGroups.sublist(startIndex, endIndex);
    
    return {
      'groups': paginatedGroups.map((group) => group.toJson()).toList(),
      'pagination': {
        'current_page': page,
        'per_page': limit,
        'total': allGroups.length,
        'total_pages': (allGroups.length / limit).ceil(),
        'has_next': endIndex < allGroups.length,
        'has_prev': page > 1,
      },
      'message': 'Groups retrieved successfully',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'success',
    };
  }

  // Simulate backend response format for single group endpoint
  static Map<String, dynamic> simulateGroupApiResponse(String groupId) {
    final group = getGroupById(groupId);
    if (group == null) {
      return {
        'error': 'Group not found',
        'message': 'Group with ID $groupId not found',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'error',
      };
    }
    
    return {
      'group': group.toJson(),
      'message': 'Group retrieved successfully',
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'success',
    };
  }

  // Simulate backend response for group creation
  static Map<String, dynamic> simulateCreateGroupApiResponse(String groupName, List<String> memberIds) {
    // This would be replaced with actual API call
    return {
      'error': 'Not implemented',
      'message': 'Group creation will be implemented in a future update',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Simulate backend response for group update
  static Map<String, dynamic> simulateUpdateGroupApiResponse(int groupId, String groupName) {
    final group = getGroupById(groupId.toString());
    if (group == null) {
      return {
        'error': 'Group not found',
        'message': 'Group with ID $groupId does not exist',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    
    return {
      'error': 'Not implemented',
      'message': 'Group update will be implemented in a future update',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Simulate backend response for group deletion
  static Map<String, dynamic> simulateDeleteGroupApiResponse(int groupId) {
    final group = getGroupById(groupId.toString());
    if (group == null) {
      return {
        'error': 'Group not found',
        'message': 'Group with ID $groupId does not exist',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    
    return {
      'error': 'Not implemented',
      'message': 'Group deletion will be implemented in a future update',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}