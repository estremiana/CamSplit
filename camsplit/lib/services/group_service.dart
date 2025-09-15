import 'dart:io';
import 'package:currency_picker/currency_picker.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/user_model.dart';
import '../models/mock_group_data.dart';
import 'api_service.dart';
import 'currency_service.dart';
import 'user_service.dart';
import 'user_stats_service.dart';

/// Service class for handling group-related operations
/// This class provides an abstraction layer for group data access
/// and uses real backend API calls
class GroupService {
  static final ApiService _apiService = ApiService.instance;
  static const Duration _requestTimeout = Duration(seconds: 30);
  
  // Cache for groups to avoid repeated API calls
  static List<Group>? _cachedGroups;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  /// Get all groups for the current user, sorted by creation time
  /// Returns groups ordered by created_at timestamp in descending order
  static Future<List<Group>> getAllGroups({bool forceRefresh = false}) async {
    // Check cache first (unless force refresh is requested)
    if (!forceRefresh && _isCacheValid()) {
      return _cachedGroups!;
    }
    
    try {
      final response = await _apiService.getGroups();
      
      if (response['success']) {
        final groupsData = response['data'] as List?;
        if (groupsData == null || groupsData.isEmpty) {
          // Return empty list if no groups
          _updateCache([]);
          return [];
        }
        
        List<Group> groups = [];
        for (final json in groupsData) {
          try {
            final group = Group.fromJson(json);
            
            // Fetch user balance for this group
            try {
              final balanceResponse = await _apiService.getUserBalanceForGroup(group.id.toString());
              if (balanceResponse['success'] && balanceResponse['data'] != null) {
                final balanceData = balanceResponse['data'];
                final balanceString = balanceData['balance']?.toString() ?? '0.0';
                final userBalance = double.tryParse(balanceString) ?? 0.0;
                
                // Create a new group with balance data
                final groupWithBalance = Group(
                  id: group.id,
                  name: group.name,
                  currency: group.currency,
                  description: group.description,
                  createdBy: group.createdBy,
                  members: group.members,
                  memberCountFromApi: group.memberCountFromApi,
                  lastUsed: group.lastUsed,
                  createdAt: group.createdAt,
                  updatedAt: group.updatedAt,
                  userBalance: userBalance,
                  imageUrl: group.imageUrl,
                );
                groups.add(groupWithBalance);
              } else {
                // If balance fetch fails, add group without balance
                groups.add(group);
              }
            } catch (balanceError) {
              print('Failed to fetch balance for group ${group.id}: $balanceError');
              // Add group without balance if balance fetch fails
              groups.add(group);
            }
          } catch (e) {
            print('Error parsing group JSON: $e');
            print('JSON data: $json');
            // Skip this group
          }
        }
        
        // Sort by created_at desc as the source of truth for ordering
        groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Update cache
        _updateCache(groups);
        
        return groups;
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to load groups');
      }
    } catch (e) {
      // For development/testing, fallback to mock data if API is not available
      print('API call failed, falling back to mock data: $e');
      final mockGroups = MockGroupData.getGroupsSortedByMostRecent();
      
      // Ensure mock groups have proper member counts by validating the data
      for (final group in mockGroups) {
        if (group.members.isEmpty) {
          print('WARNING: Group ${group.name} (ID: ${group.id}) has no members');
        }
      }
      
      return mockGroups;
    }
  }

  /// Get all groups with member data for the current user
  /// This method fetches member data for each group to display avatars
  static Future<List<Group>> getAllGroupsWithMembers({bool forceRefresh = false}) async {
    try {
      final groups = await getAllGroups(forceRefresh: forceRefresh);
      
      // Get current user data to populate avatars
      UserModel? currentUser;
      try {
        currentUser = await UserService.getCurrentUser();
        print('Current user avatar: ${currentUser.avatar}');
        print('Current user ID: ${currentUser.id}');
      } catch (e) {
        print('Failed to get current user: $e');
      }
      
      // If groups already have members, enhance them with current user avatar
      if (groups.isNotEmpty && groups.first.members.isNotEmpty) {
        return _enhanceGroupsWithCurrentUserAvatar(groups, currentUser);
      }
      
      // Otherwise, fetch member data for each group
      List<Group> groupsWithMembers = [];
      for (final group in groups) {
        try {
          final groupWithMembers = await getGroupWithMembers(group.id.toString());
          if (groupWithMembers != null) {
            // Create a new group with the original balance but updated members
            final updatedGroup = Group(
              id: group.id,
              name: group.name,
              currency: group.currency,
              description: group.description,
              createdBy: group.createdBy,
              members: groupWithMembers.members,
              memberCountFromApi: groupWithMembers.memberCountFromApi,
              lastUsed: group.lastUsed,
              createdAt: group.createdAt,
              updatedAt: group.updatedAt,
              userBalance: group.userBalance,
              imageUrl: group.imageUrl ?? groupWithMembers.imageUrl,
            );
            groupsWithMembers.add(updatedGroup);
          } else {
            // If we can't get members, use the original group
            groupsWithMembers.add(group);
          }
        } catch (e) {
          print('Failed to fetch members for group ${group.id}: $e');
          // Use the original group if member fetch fails
          groupsWithMembers.add(group);
        }
      }
      
      // Enhance all groups with current user avatar
      return _enhanceGroupsWithCurrentUserAvatar(groupsWithMembers, currentUser);
    } catch (e) {
      print('Failed to load groups with members: $e');
      // Fallback to regular groups
      return await getAllGroups(forceRefresh: forceRefresh);
    }
  }

  /// Enhance groups with current user's avatar for their GroupMember objects
  static List<Group> _enhanceGroupsWithCurrentUserAvatar(List<Group> groups, UserModel? currentUser) {
    if (currentUser == null) return groups;
    
    return groups.map((group) {
      // Get current user ID
      final currentUserId = int.tryParse(currentUser.id);
      if (currentUserId == null) return group;
      
      // Update members to include current user's avatar
      final enhancedMembers = group.members.map((member) {
        // If this member is the current user and doesn't have an avatar, use current user's avatar
        if (member.userId == currentUserId && (member.avatarUrl == null || member.avatarUrl!.isEmpty)) {
          print('Enhancing member ${member.nickname} with current user avatar: ${currentUser.avatar}');
          return member.copyWith(avatarUrl: currentUser.avatar);
        }
        return member;
      }).toList();
      
      // Return updated group
      return Group(
        id: group.id,
        name: group.name,
        currency: group.currency,
        description: group.description,
        createdBy: group.createdBy,
        members: enhancedMembers,
        memberCountFromApi: group.memberCountFromApi,
        lastUsed: group.lastUsed,
        createdAt: group.createdAt,
        updatedAt: group.updatedAt,
        userBalance: group.userBalance,
        imageUrl: group.imageUrl,
      );
    }).toList();
  }
  
  /// Get a specific group by ID
  static Future<Group?> getGroupById(String groupId) async {
    // Check cache first
    if (_isCacheValid()) {
      try {
        return _cachedGroups!.firstWhere((group) => group.id.toString() == groupId);
      } catch (e) {
        // Group not found in cache, continue to API call
      }
    }
    
    try {
      final response = await _apiService.getGroup(groupId);
      
      if (response['success']) {
        return Group.fromJson(response['data']);
      } else if (response['message']?.toString().contains('not found') == true) {
        return null;
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to load group');
      }
    } catch (e) {
      // For development/testing, fallback to mock data if API is not available
      print('API call failed, falling back to mock data: $e');
      try {
        return MockGroupData.getGroupById(groupId);
      } catch (mockError) {
        throw GroupServiceException('Failed to load group: $e');
      }
    }
  }

  /// Get a specific group by ID with members
  static Future<Group?> getGroupWithMembers(String groupId) async {
    try {
      final response = await _apiService.getGroupWithMembers(groupId);
      
      if (response['success']) {
        return Group.fromJson(response['data']);
      } else if (response['message']?.toString().contains('not found') == true) {
        return null;
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to load group with members');
      }
    } catch (e) {
      // For development/testing, fallback to mock data if API is not available
      print('API call failed, falling back to mock data: $e');
      try {
        return MockGroupData.getGroupById(groupId);
      } catch (mockError) {
        throw GroupServiceException('Failed to load group with members: $e');
      }
    }
  }
  
  /// Create a new group with specified name, currency, description, and member emails
  static Future<Group> createGroup(String groupName, List<String> memberEmails, {
    Currency? currency,
    String? description,
    String? imagePath,
  }) async {
    try {
      final selectedCurrency = currency ?? CamSplitCurrencyService.getDefaultCurrency();
      final groupDescription = description ?? '';
      
      final response = await _apiService.createGroup(
        groupName, 
        selectedCurrency.code, 
        groupDescription,
      );
      
      if (response['success']) {
        final newGroup = Group.fromJson(response['data']);
        
        // Upload image if provided
        if (imagePath != null) {
          try {
            final imageFile = File(imagePath);
            final imageResponse = await _apiService.uploadGroupImage(newGroup.id.toString(), imageFile);
            if (imageResponse['success']) {
              // Update the group with the new image URL
              final updatedGroup = Group.fromJson(imageResponse['data']['group']);
              _invalidateCache(); // Clear cache to force refresh
              return updatedGroup;
            }
          } catch (e) {
            // If image upload fails, still return the group without image
            print('Failed to upload group image: $e');
          }
        }
        
        _invalidateCache(); // Clear cache to force refresh
        
        // Optimistic update: Increment groups count
        UserStatsService.incrementGroupsCount();
        
        // Background refresh of stats
        UserStatsService.refreshStatsInBackground();
        
        return newGroup;
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to create group');
      }
    } catch (e) {
      throw GroupServiceException('Failed to create group: $e');
    }
  }
  
  /// Update group details (name, etc.)
  static Future<Group> updateGroup(String groupId, String groupName) async {
    try {
      final response = await _apiService.updateGroup(groupId, {
        'name': groupName,
      });
      
      if (response['success']) {
        final updatedGroup = Group.fromJson(response['data']);
        _invalidateCache(); // Clear cache to force refresh
        return updatedGroup;
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to update group');
      }
    } catch (e) {
      throw GroupServiceException('Failed to update group: $e');
    }
  }
  
  /// Update group currency
  static Future<Group> updateGroupCurrency(String groupId, Currency currency) async {
    try {
      final response = await _apiService.updateGroup(groupId, {
        'currency': currency.code,
      });
      
      if (response['success']) {
        final updatedGroup = Group.fromJson(response['data']);
        _invalidateCache(); // Clear cache to force refresh
        
        // Store the updated currency in the currency service
        await CamSplitCurrencyService.setGroupCurrency(updatedGroup.id, currency);
        
        return updatedGroup;
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to update group currency');
      }
    } catch (e) {
      throw GroupServiceException('Failed to update group currency: $e');
    }
  }
  
  /// Delete a group (only if current user is the creator)
  static Future<void> deleteGroup(String groupId) async {
    try {
      final response = await _apiService.deleteGroup(groupId);
      
      if (response['success']) {
        _invalidateCache(); // Clear cache to force refresh
        return;
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to delete group');
      }
    } catch (e) {
      throw GroupServiceException('Failed to delete group: $e');
    }
  }
  
  /// Delete a group with cascading deletes (removes all related data)
  static Future<void> deleteGroupWithCascade(String groupId) async {
    try {
      final response = await _apiService.deleteGroupWithCascade(groupId);
      
      if (response['success']) {
        _invalidateCache(); // Clear cache to force refresh
        
        // Optimistic update: Decrement groups count
        UserStatsService.decrementGroupsCount();
        
        // Background refresh of stats
        UserStatsService.refreshStatsInBackground();
        
        return;
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to delete group with cascade');
      }
    } catch (e) {
      throw GroupServiceException('Failed to delete group with cascade: $e');
    }
  }
  
  /// Exit a group (for regular members)
  static Future<Map<String, dynamic>> exitGroup(String groupId) async {
    try {
      final response = await _apiService.exitGroup(groupId);
      
      if (response['success']) {
        _invalidateCache(); // Clear cache to force refresh
        
        // Optimistic update: Decrement groups count
        UserStatsService.decrementGroupsCount();
        
        // Background refresh of stats
        UserStatsService.refreshStatsInBackground();
        
        return {
          'action': response['data']['action'],
          'message': response['message']
        };
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to exit group');
      }
    } catch (e) {
      throw GroupServiceException('Failed to exit group: $e');
    }
  }
  
  /// Check if a group should be auto-deleted (no registered users remain)
  static Future<bool> checkGroupAutoDeleteStatus(String groupId) async {
    try {
      final response = await _apiService.checkGroupAutoDeleteStatus(groupId);
      
      if (response['success']) {
        return response['data']['shouldAutoDelete'] ?? false;
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to check group auto-delete status');
      }
    } catch (e) {
      throw GroupServiceException('Failed to check group auto-delete status: $e');
    }
  }
  
  /// Add a member to a group by email
  static Future<GroupMember> addMemberToGroup(String groupId, String memberEmail, String memberName) async {
    try {
      final response = await _apiService.addGroupMember(groupId, {
        'email': memberEmail,
        'nickname': memberName,
      });
      
      if (response['success']) {
        final newMember = GroupMember.fromJson(response['data'], groupId: int.tryParse(groupId) ?? 0);
        _invalidateCache(); // Clear cache to force refresh
        return newMember;
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to add member');
      }
    } catch (e) {
      throw GroupServiceException('Failed to add member: $e');
    }
  }
  
  /// Remove a member from a group
  static Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    try {
      final response = await _apiService.removeGroupMember(groupId, memberId);
      
      if (response['success']) {
        _invalidateCache(); // Clear cache to force refresh
        return;
      } else {
        throw GroupServiceException(response['message'] ?? 'Failed to remove member');
      }
    } catch (e) {
      throw GroupServiceException('Failed to remove member: $e');
    }
  }
  
  /// Update the last used timestamp for a group
  /// This is called when a user selects a group for expense assignment
  /// For now, we'll just invalidate the cache to force a refresh
  static Future<void> updateLastUsed(String groupId) async {
    try {
      // Since there's no specific API endpoint for this, we'll just invalidate the cache
      // The next time groups are fetched, they'll have the updated timestamps
      _invalidateCache();
    } catch (e) {
      throw GroupServiceException('Failed to update last used timestamp: $e');
    }
  }
  
  // Cache management methods for better performance
  static bool _isCacheValid() {
    return _cachedGroups != null && 
           _cacheTimestamp != null && 
           DateTime.now().difference(_cacheTimestamp!) < _cacheExpiry;
  }
  
  static void _updateCache(List<Group> groups) {
    _cachedGroups = groups;
    _cacheTimestamp = DateTime.now();
  }
  
  static void _invalidateCache() {
    _cachedGroups = null;
    _cacheTimestamp = null;
  }
  
  /// Public method to clear the cache
  static void clearCache() {
    _invalidateCache();
  }
  
  /// Get the most recently used group (for default selection)
  static Future<Group?> getMostRecentGroup() async {
    try {
      final groups = await getAllGroups();
      return groups.isNotEmpty ? groups.first : null;
    } catch (e) {
      throw GroupServiceException('Failed to get most recent group: $e');
    }
  }
  
  /// Search groups by name (for future search functionality)
  static Future<List<Group>> searchGroups(String query) async {
    try {
      final groups = await getAllGroups();
      if (query.isEmpty) return groups;
      
      return groups.where((group) => 
        group.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      throw GroupServiceException('Failed to search groups: $e');
    }
  }
  
  /// Get groups with specific member count range (for filtering)
  static Future<List<Group>> getGroupsByMemberCount(int minMembers, int maxMembers) async {
    try {
      final groups = await getAllGroups();
      return groups.where((group) => 
        group.memberCount >= minMembers && group.memberCount <= maxMembers
      ).toList();
    } catch (e) {
      throw GroupServiceException('Failed to filter groups by member count: $e');
    }
  }
}

/// Custom exception class for group service errors
class GroupServiceException implements Exception {
  final String message;
  
  const GroupServiceException(this.message);
  
  @override
  String toString() => 'GroupServiceException: $message';
}