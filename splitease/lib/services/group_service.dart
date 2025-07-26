import 'dart:convert';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/mock_group_data.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Service class for handling group-related operations
/// This class provides an abstraction layer for group data access
/// and is designed to easily transition from mock data to real API calls
/// 
/// BACKEND INTEGRATION NOTES:
/// - All methods are structured to match expected backend API responses
/// - Mock data format exactly matches the backend API specification
/// - Error handling is prepared for network failures and API errors
/// - Authentication tokens are handled automatically via ApiService
/// - All timestamps use ISO 8601 format as required by backend
/// - Group IDs and member IDs use UUID format for backend compatibility
class GroupService {
  // TODO: Replace mock data calls with actual backend API integration
  // 
  // Backend API endpoints (see backend/API_DETAILS.md for full specification):
  // - GET /api/groups - Get all user's groups sorted by most recent usage
  // - GET /api/groups/:id - Get specific group details  
  // - POST /api/groups - Create new group with member emails
  // - PUT /api/groups/:id - Update group name and details
  // - DELETE /api/groups/:id - Delete group (only if user is creator)
  // - POST /api/groups/:id/members - Add member to group by email
  // - DELETE /api/groups/:id/members/:memberId - Remove member from group
  // - PATCH /api/groups/:id/last-used - Update last used timestamp
  //
  // All endpoints require Authorization: Bearer {token} header
  // All responses include status, message, and timestamp fields
  // Error responses follow standard HTTP status codes with descriptive messages
  
  static final ApiService _apiService = ApiService.instance;
  static const Duration _requestTimeout = Duration(seconds: 30);
  
  // Cache for groups to avoid repeated API calls
  static List<Group>? _cachedGroups;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  /// Get all groups for the current user, sorted by most recent usage
  /// Returns groups ordered by last_used timestamp in descending order
  /// 
  /// BACKEND INTEGRATION: Replace this method with actual API call
  /// Expected API call: GET /api/groups
  /// Expected response format: { "groups": [...], "count": int, "message": string, "status": "success" }
  static Future<List<Group>> getAllGroups({bool forceRefresh = false}) async {
    // Check cache first (unless force refresh is requested)
    if (!forceRefresh && _isCacheValid()) {
      return _cachedGroups!;
    }
    
    // Simulate network delay for realistic testing
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      // TODO: Replace with actual API call when backend is ready
      // 
      // Future implementation:
      // final response = await _apiService.get('/groups');
      // if (response['status'] == 'success') {
      //   final groupsJson = response['groups'] as List;
      //   final groups = groupsJson.map((json) => Group.fromJson(json)).toList();
      //   _updateCache(groups);
      //   return groups;
      // } else {
      //   throw GroupServiceException(response['message'] ?? 'Failed to load groups');
      // }
      
      // Using mock data for now - this simulates the exact backend response format
      final mockResponse = MockGroupData.simulateGroupsApiResponse();
      final groupsJson = mockResponse['groups'] as List;
      final groups = groupsJson.map((json) => Group.fromJson(json)).toList();
      
      // Validate data integrity before returning
      if (!MockGroupData.validateMockData()) {
        throw GroupServiceException('Invalid mock data detected');
      }
      
      // Update cache
      _updateCache(groups);
      
      return groups;
    } catch (e) {
      throw GroupServiceException('Failed to load groups: $e');
    }
  }
  
  /// Get a specific group by ID
  /// 
  /// BACKEND INTEGRATION: Replace this method with actual API call
  /// Expected API call: GET /api/groups/:id
  /// Expected response format: { "group": {...}, "message": string, "status": "success" }
  static Future<Group?> getGroupById(String groupId) async {
    // Check cache first
    if (_isCacheValid()) {
      try {
        return _cachedGroups!.firstWhere((group) => group.id == groupId);
      } catch (e) {
        // Group not found in cache, continue to API call
      }
    }
    
    // Simulate network delay for realistic testing
    await Future.delayed(const Duration(milliseconds: 300));
    
    try {
      // TODO: Replace with actual API call when backend is ready
      // 
      // Future implementation:
      // final response = await _apiService.get('/groups/$groupId');
      // if (response['status'] == 'success') {
      //   return Group.fromJson(response['group']);
      // } else if (response['status'] == 'error' && response['message'].contains('not found')) {
      //   return null;
      // } else {
      //   throw GroupServiceException(response['message'] ?? 'Failed to load group');
      // }
      
      // Using mock data for now - this simulates the exact backend response format
      final mockResponse = MockGroupData.simulateGroupApiResponse(groupId);
      if (mockResponse.containsKey('error')) {
        if (mockResponse['message'].toString().contains('not found')) {
          return null;
        }
        throw GroupServiceException(mockResponse['message']);
      }
      
      return Group.fromJson(mockResponse['group']);
    } catch (e) {
      throw GroupServiceException('Failed to load group: $e');
    }
  }
  
  /// Create a new group with specified name and member emails
  /// 
  /// BACKEND INTEGRATION: Replace this method with actual API call
  /// Expected API call: POST /api/groups
  /// Request body: { "name": string, "member_emails": [string] }
  /// Expected response format: { "group": {...}, "message": string, "status": "success" }
  static Future<Group> createGroup(String groupName, List<String> memberEmails) async {
    // Simulate network delay for realistic testing
    await Future.delayed(const Duration(milliseconds: 800));
    
    // TODO: Replace with actual API call when backend is ready
    // 
    // Future implementation:
    // final response = await _apiService.post('/groups', data: {
    //   'name': groupName,
    //   'member_emails': memberEmails,
    // });
    // 
    // if (response['status'] == 'success') {
    //   final newGroup = Group.fromJson(response['group']);
    //   _invalidateCache(); // Clear cache to force refresh
    //   return newGroup;
    // } else {
    //   throw GroupServiceException(response['message'] ?? 'Failed to create group');
    // }
    
    // For now, throw UnimplementedError as per requirements
    throw UnimplementedError('Group creation will be implemented in a future update');
  }
  
  /// Update group details (name, etc.)
  /// 
  /// BACKEND INTEGRATION: Replace this method with actual API call
  /// Expected API call: PUT /api/groups/:id
  /// Request body: { "name": string }
  /// Expected response format: { "group": {...}, "message": string, "status": "success" }
  static Future<Group> updateGroup(String groupId, String groupName) async {
    // Simulate network delay for realistic testing
    await Future.delayed(const Duration(milliseconds: 600));
    
    // TODO: Replace with actual API call when backend is ready
    // 
    // Future implementation:
    // final response = await _apiService.put('/groups/$groupId', data: {
    //   'name': groupName,
    // });
    // 
    // if (response['status'] == 'success') {
    //   final updatedGroup = Group.fromJson(response['group']);
    //   _invalidateCache(); // Clear cache to force refresh
    //   return updatedGroup;
    // } else {
    //   throw GroupServiceException(response['message'] ?? 'Failed to update group');
    // }
    
    // For now, throw UnimplementedError as per requirements
    throw UnimplementedError('Group update will be implemented in a future update');
  }
  
  /// Delete a group (only if current user is the creator)
  /// 
  /// BACKEND INTEGRATION: Replace this method with actual API call
  /// Expected API call: DELETE /api/groups/:id
  /// Expected response format: { "message": string, "status": "success" }
  static Future<void> deleteGroup(String groupId) async {
    // Simulate network delay for realistic testing
    await Future.delayed(const Duration(milliseconds: 400));
    
    // TODO: Replace with actual API call when backend is ready
    // 
    // Future implementation:
    // final response = await _apiService.delete('/groups/$groupId');
    // 
    // if (response['status'] == 'success') {
    //   _invalidateCache(); // Clear cache to force refresh
    //   return;
    // } else {
    //   throw GroupServiceException(response['message'] ?? 'Failed to delete group');
    // }
    
    // For now, throw UnimplementedError as per requirements
    throw UnimplementedError('Group deletion will be implemented in a future update');
  }
  
  /// Add a member to a group by email
  /// 
  /// BACKEND INTEGRATION: Replace this method with actual API call
  /// Expected API call: POST /api/groups/:id/members
  /// Request body: { "email": string, "name": string }
  /// Expected response format: { "member": {...}, "message": string, "status": "success" }
  static Future<GroupMember> addMemberToGroup(String groupId, String memberEmail, String memberName) async {
    // Simulate network delay for realistic testing
    await Future.delayed(const Duration(milliseconds: 700));
    
    // TODO: Replace with actual API call when backend is ready
    // 
    // Future implementation:
    // final response = await _apiService.post('/groups/$groupId/members', data: {
    //   'email': memberEmail,
    //   'name': memberName,
    // });
    // 
    // if (response['status'] == 'success') {
    //   final newMember = GroupMember.fromJson(response['member']);
    //   _invalidateCache(); // Clear cache to force refresh
    //   return newMember;
    // } else {
    //   throw GroupServiceException(response['message'] ?? 'Failed to add member');
    // }
    
    // For now, throw UnimplementedError as per requirements
    throw UnimplementedError('Adding group members will be implemented in a future update');
  }
  
  /// Remove a member from a group
  /// 
  /// BACKEND INTEGRATION: Replace this method with actual API call
  /// Expected API call: DELETE /api/groups/:id/members/:memberId
  /// Expected response format: { "message": string, "status": "success" }
  static Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    // Simulate network delay for realistic testing
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Replace with actual API call when backend is ready
    // 
    // Future implementation:
    // final response = await _apiService.delete('/groups/$groupId/members/$memberId');
    // 
    // if (response['status'] == 'success') {
    //   _invalidateCache(); // Clear cache to force refresh
    //   return;
    // } else {
    //   throw GroupServiceException(response['message'] ?? 'Failed to remove member');
    // }
    
    // For now, throw UnimplementedError as per requirements
    throw UnimplementedError('Removing group members will be implemented in a future update');
  }
  
  /// Update the last used timestamp for a group
  /// This is called when a user selects a group for expense assignment
  /// 
  /// BACKEND INTEGRATION: Replace this method with actual API call
  /// Expected API call: PATCH /api/groups/:id/last-used
  /// Expected response format: { "message": string, "status": "success" }
  static Future<void> updateLastUsed(String groupId) async {
    // Simulate network delay for realistic testing
    await Future.delayed(const Duration(milliseconds: 200));
    
    try {
      // TODO: Replace with actual API call when backend is ready
      // 
      // Future implementation:
      // final response = await _apiService.patch('/groups/$groupId/last-used');
      // 
      // if (response['status'] == 'success') {
      //   _invalidateCache(); // Clear cache to force refresh with updated timestamp
      //   return;
      // } else {
      //   throw GroupServiceException(response['message'] ?? 'Failed to update last used timestamp');
      // }
      
      // For now, this is a no-op since we're using mock data
      // In the real implementation, this would update the backend
      // The mock data doesn't need to be updated since it's regenerated on each call
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
  
  /// Clear the groups cache manually (useful for testing or force refresh)
  static void clearCache() {
    _invalidateCache();
  }
  
  /// Get the most recently used group (for default selection)
  /// 
  /// BACKEND INTEGRATION: This uses the cached groups or fetches from API
  static Future<Group?> getMostRecentGroup() async {
    try {
      final groups = await getAllGroups();
      return groups.isNotEmpty ? groups.first : null;
    } catch (e) {
      throw GroupServiceException('Failed to get most recent group: $e');
    }
  }
  
  /// Search groups by name (for future search functionality)
  /// 
  /// BACKEND INTEGRATION: This could be enhanced with server-side search
  /// Expected API call: GET /api/groups?search=query
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