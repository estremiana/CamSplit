import 'group.dart';
import 'group_member.dart';

class MockGroupData {
  // TODO: Replace with actual backend API calls when backend integration is implemented
  // 
  // Expected backend API structure based on existing API patterns:
  // 
  // GET /api/groups
  // Response: {
  //   "groups": [
  //     {
  //       "id": "1",
  //       "name": "Weekend Getaway",
  //       "members": [
  //         {
  //           "id": "1",
  //           "name": "John Doe",
  //           "email": "john@example.com",
  //           "avatar": "https://...",
  //           "is_current_user": true,
  //           "joined_at": "2024-01-01T00:00:00.000Z"
  //         }
  //       ],
  //       "last_used": "2024-07-25T10:00:00.000Z",
  //       "created_at": "2024-07-20T00:00:00.000Z",
  //       "updated_at": "2024-07-25T10:00:00.000Z"
  //     }
  //   ],
  //   "count": 6,
  //   "message": "Groups retrieved successfully"
  // }
  //
  // GET /api/groups/:id
  // Response: {
  //   "group": { /* group object */ },
  //   "message": "Group retrieved successfully"
  // }
  //
  // POST /api/groups
  // Request: { "name": "New Group", "member_ids": ["1", "2"] }
  // Response: { "group": { /* created group */ }, "message": "Group created successfully" }
  //
  // PUT /api/groups/:id
  // Request: { "name": "Updated Name" }
  // Response: { "group": { /* updated group */ }, "message": "Group updated successfully" }
  //
  // DELETE /api/groups/:id
  // Response: { "message": "Group deleted successfully" }
  //
  // POST /api/groups/:id/members
  // Request: { "user_id": "3", "name": "Jane Doe", "email": "jane@example.com" }
  // Response: { "member": { /* added member */ }, "message": "Member added successfully" }
  //
  // DELETE /api/groups/:id/members/:memberId
  // Response: { "message": "Member removed successfully" }
  //
  // PATCH /api/groups/:id/last-used
  // Response: { "message": "Last used timestamp updated" }
  
  // This mock data simulates the expected backend response format for groups
  // Data format matches the Group and GroupMember models for seamless backend integration
  // All timestamps use ISO 8601 format as expected by the backend
  // Group IDs and member IDs are strings to match typical backend UUID format
  
  static List<Group> getMockGroups() {
    final now = DateTime.now();
    
    return [
      // Most recently used group - Weekend Trip
      Group(
        id: '1',
        name: 'Weekend Getaway 🏖️',
        members: [
          GroupMember(
            id: '1',
            name: 'You',
            email: 'you@example.com',
            avatar: 'https://ui-avatars.com/api/?name=You&background=4F46E5&color=fff',
            isCurrentUser: true,
            joinedAt: now.subtract(const Duration(days: 3)),
          ),
          GroupMember(
            id: '2',
            name: 'Sarah Johnson',
            email: 'sarah.johnson@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Sarah+Johnson&background=059669&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 2)),
          ),
          GroupMember(
            id: '3',
            name: 'Mike Chen',
            email: 'mike.chen@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Mike+Chen&background=DC2626&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 1)),
          ),
          GroupMember(
            id: '10',
            name: 'Jessica Taylor',
            email: 'jessica.taylor@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Jessica+Taylor&background=7C3AED&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(hours: 12)),
          ),
        ],
        lastUsed: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      
      // Second most recent - Office Lunch
      Group(
        id: '2',
        name: 'Office Lunch Squad 🍕',
        members: [
          GroupMember(
            id: '101',
            name: 'You',
            email: 'you@example.com',
            avatar: 'https://ui-avatars.com/api/?name=You&background=4F46E5&color=fff',
            isCurrentUser: true,
            joinedAt: now.subtract(const Duration(days: 7)),
          ),
          GroupMember(
            id: '4',
            name: 'Emma Wilson',
            email: 'emma.wilson@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Emma+Wilson&background=EA580C&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 6)),
          ),
          GroupMember(
            id: '5',
            name: 'Alex Rodriguez',
            email: 'alex.rodriguez@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Alex+Rodriguez&background=0891B2&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 5)),
          ),
          GroupMember(
            id: '6',
            name: 'Lisa Park',
            email: 'lisa.park@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Lisa+Park&background=BE185D&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 4)),
          ),
          GroupMember(
            id: '11',
            name: 'David Kim',
            email: 'david.kim@example.com',
            avatar: 'https://ui-avatars.com/api/?name=David+Kim&background=16A34A&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 3)),
          ),
        ],
        lastUsed: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      
      // Third - Family Dinner
      Group(
        id: '3',
        name: 'Family Dinner 👨‍👩‍👧‍👦',
        members: [
          GroupMember(
            id: '201',
            name: 'You',
            email: 'you@example.com',
            avatar: 'https://ui-avatars.com/api/?name=You&background=4F46E5&color=fff',
            isCurrentUser: true,
            joinedAt: now.subtract(const Duration(days: 14)),
          ),
          GroupMember(
            id: '7',
            name: 'Mom',
            email: 'mom@family.com',
            avatar: 'https://ui-avatars.com/api/?name=Mom&background=DB2777&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 14)),
          ),
          GroupMember(
            id: '8',
            name: 'Dad',
            email: 'dad@family.com',
            avatar: 'https://ui-avatars.com/api/?name=Dad&background=1F2937&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 14)),
          ),
          GroupMember(
            id: '9',
            name: 'Sister',
            email: 'sister@family.com',
            avatar: 'https://ui-avatars.com/api/?name=Sister&background=F59E0B&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 13)),
          ),
        ],
        lastUsed: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      
      // Fourth - Study Group
      Group(
        id: '4',
        name: 'Study Group 📚',
        members: [
          GroupMember(
            id: '301',
            name: 'You',
            email: 'you@example.com',
            avatar: 'https://ui-avatars.com/api/?name=You&background=4F46E5&color=fff',
            isCurrentUser: true,
            joinedAt: now.subtract(const Duration(days: 21)),
          ),
          GroupMember(
            id: '12',
            name: 'Rachel Green',
            email: 'rachel.green@university.edu',
            avatar: 'https://ui-avatars.com/api/?name=Rachel+Green&background=10B981&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 20)),
          ),
          GroupMember(
            id: '13',
            name: 'Tom Anderson',
            email: 'tom.anderson@university.edu',
            avatar: 'https://ui-avatars.com/api/?name=Tom+Anderson&background=8B5CF6&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 19)),
          ),
        ],
        lastUsed: now.subtract(const Duration(days: 8)),
        createdAt: now.subtract(const Duration(days: 21)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
      
      // Fifth - Roommates
      Group(
        id: '5',
        name: 'Roommates 🏠',
        members: [
          GroupMember(
            id: '401',
            name: 'You',
            email: 'you@example.com',
            avatar: 'https://ui-avatars.com/api/?name=You&background=4F46E5&color=fff',
            isCurrentUser: true,
            joinedAt: now.subtract(const Duration(days: 30)),
          ),
          GroupMember(
            id: '14',
            name: 'Chris Martinez',
            email: 'chris.martinez@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Chris+Martinez&background=EF4444&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 30)),
          ),
          GroupMember(
            id: '15',
            name: 'Amy Foster',
            email: 'amy.foster@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Amy+Foster&background=06B6D4&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 29)),
          ),
        ],
        lastUsed: now.subtract(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 12)),
      ),
      
      // Sixth - Book Club
      Group(
        id: '6',
        name: 'Book Club 📖',
        members: [
          GroupMember(
            id: '501',
            name: 'You',
            email: 'you@example.com',
            avatar: 'https://ui-avatars.com/api/?name=You&background=4F46E5&color=fff',
            isCurrentUser: true,
            joinedAt: now.subtract(const Duration(days: 45)),
          ),
          GroupMember(
            id: '16',
            name: 'Helen Davis',
            email: 'helen.davis@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Helen+Davis&background=84CC16&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 44)),
          ),
          GroupMember(
            id: '17',
            name: 'Robert Brown',
            email: 'robert.brown@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Robert+Brown&background=A855F7&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 43)),
          ),
          GroupMember(
            id: '18',
            name: 'Maria Garcia',
            email: 'maria.garcia@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Maria+Garcia&background=F97316&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 42)),
          ),
          GroupMember(
            id: '19',
            name: 'Kevin Lee',
            email: 'kevin.lee@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Kevin+Lee&background=14B8A6&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 41)),
          ),
        ],
        lastUsed: now.subtract(const Duration(days: 20)),
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 20)),
      ),
      
      // Seventh - Gym Buddies
      Group(
        id: '7',
        name: 'Gym Buddies 💪',
        members: [
          GroupMember(
            id: '601',
            name: 'You',
            email: 'you@example.com',
            avatar: 'https://ui-avatars.com/api/?name=You&background=4F46E5&color=fff',
            isCurrentUser: true,
            joinedAt: now.subtract(const Duration(days: 60)),
          ),
          GroupMember(
            id: '20',
            name: 'Marcus Johnson',
            email: 'marcus.johnson@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Marcus+Johnson&background=DC2626&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 58)),
          ),
          GroupMember(
            id: '21',
            name: 'Sophia Williams',
            email: 'sophia.williams@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Sophia+Williams&background=059669&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 55)),
          ),
        ],
        lastUsed: now.subtract(const Duration(days: 25)),
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 25)),
      ),
      
      // Eighth - Travel Squad (least recent)
      Group(
        id: '8',
        name: 'Travel Squad ✈️',
        members: [
          GroupMember(
            id: '701',
            name: 'You',
            email: 'you@example.com',
            avatar: 'https://ui-avatars.com/api/?name=You&background=4F46E5&color=fff',
            isCurrentUser: true,
            joinedAt: now.subtract(const Duration(days: 90)),
          ),
          GroupMember(
            id: '22',
            name: 'Oliver Thompson',
            email: 'oliver.thompson@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Oliver+Thompson&background=7C3AED&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 88)),
          ),
          GroupMember(
            id: '23',
            name: 'Isabella Martinez',
            email: 'isabella.martinez@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Isabella+Martinez&background=EA580C&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 85)),
          ),
          GroupMember(
            id: '24',
            name: 'Ethan Wilson',
            email: 'ethan.wilson@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Ethan+Wilson&background=0891B2&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 82)),
          ),
          GroupMember(
            id: '25',
            name: 'Ava Davis',
            email: 'ava.davis@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Ava+Davis&background=BE185D&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 80)),
          ),
          GroupMember(
            id: '26',
            name: 'Liam Anderson',
            email: 'liam.anderson@example.com',
            avatar: 'https://ui-avatars.com/api/?name=Liam+Anderson&background=16A34A&color=fff',
            isCurrentUser: false,
            joinedAt: now.subtract(const Duration(days: 78)),
          ),
        ],
        lastUsed: now.subtract(const Duration(days: 35)),
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 35)),
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
      return getMockGroups().firstWhere((group) => group.id == groupId);
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
  static Map<String, dynamic> simulateUpdateGroupApiResponse(String groupId, String groupName) {
    final group = getGroupById(groupId);
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
  static Map<String, dynamic> simulateDeleteGroupApiResponse(String groupId) {
    final group = getGroupById(groupId);
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