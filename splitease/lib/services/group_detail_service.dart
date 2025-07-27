import 'dart:convert';
import '../models/group_detail_model.dart';
import '../models/debt_relationship_model.dart';
import '../models/group_member.dart';
import '../models/mock_group_detail_data.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Service class for handling group detail operations
/// This service provides comprehensive group detail functionality including:
/// - Fetching detailed group information
/// - Managing user balance retrieval
/// - Handling debt relationships
/// - Participant management (add/remove members)
/// - Group management actions (share/exit/delete)
/// 
/// All methods include proper error handling and loading states
class GroupDetailService {
  static final ApiService _apiService = ApiService.instance;
  static const Duration _requestTimeout = Duration(seconds: 30);
  
  // Cache for group details to avoid repeated API calls
  static final Map<int, GroupDetailModel> _detailCache = {};
  static final Map<int, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Fetch detailed group information including expenses, members, and debts
  /// 
  /// This method retrieves comprehensive group data needed for the detail view
  /// including all expenses, member information, debt relationships, and user permissions
  /// 
  /// [groupId] - The ID of the group to fetch details for
  /// [forceRefresh] - Whether to bypass cache and fetch fresh data
  /// 
  /// Returns [GroupDetailModel] with complete group information
  /// Throws [GroupDetailServiceException] on API errors or network failures
  static Future<GroupDetailModel> getGroupDetails(int groupId, {bool forceRefresh = false}) async {
    // Check cache first (unless force refresh is requested)
    if (!forceRefresh && _isDetailCacheValid(groupId)) {
      return _detailCache[groupId]!;
    }

    try {
      // TODO: Replace with actual API call when backend is ready
      // Expected API call: GET /api/groups/{groupId}/details
      // Expected response format: { "group": GroupDetailModel, "status": "success" }
      
      final response = await _apiService.getGroup(groupId.toString());
      
      if (response.containsKey('group')) {
        final groupDetail = GroupDetailModel.fromJson(response['group']);
        
        // Validate data integrity
        if (!groupDetail.isValid()) {
          throw GroupDetailServiceException('Invalid group detail data received');
        }
        
        // Update cache
        _updateDetailCache(groupId, groupDetail);
        
        return groupDetail;
      } else {
        throw GroupDetailServiceException(response['message'] ?? 'Failed to load group details');
      }
    } catch (e) {
      if (e is GroupDetailServiceException) {
        rethrow;
      }
      throw GroupDetailServiceException('Failed to load group details: $e');
    }
  }

  /// Retrieve user's balance for a specific group
  /// 
  /// This method fetches the current user's net balance within the group,
  /// which is used to display whether they owe money or are owed money
  /// 
  /// [groupId] - The ID of the group to get balance for
  /// 
  /// Returns [Map] containing balance amount and currency
  /// Throws [GroupDetailServiceException] on API errors
  static Future<Map<String, dynamic>> getUserBalance(int groupId) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // Expected API call: GET /api/groups/{groupId}/balance
      // Expected response format: { "balance": double, "currency": string, "status": "success" }
      
      final response = await _apiService.getGroup(groupId.toString());
      
      if (response.containsKey('group')) {
        final groupData = response['group'];
        return {
          'balance': (groupData['user_balance'] ?? 0).toDouble(),
          'currency': groupData['currency'] ?? 'EUR',
        };
      } else {
        throw GroupDetailServiceException(response['message'] ?? 'Failed to load user balance');
      }
    } catch (e) {
      if (e is GroupDetailServiceException) {
        rethrow;
      }
      throw GroupDetailServiceException('Failed to load user balance: $e');
    }
  }

  /// Fetch debt relationships for a specific group
  /// 
  /// This method retrieves all debt relationships within the group,
  /// showing who owes money to whom and the amounts
  /// 
  /// [groupId] - The ID of the group to get debt relationships for
  /// 
  /// Returns [List<DebtRelationship>] containing all debt relationships
  /// Throws [GroupDetailServiceException] on API errors
  static Future<List<DebtRelationship>> getDebtRelationships(int groupId) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // Expected API call: GET /api/groups/{groupId}/debts
      // Expected response format: { "debts": List<DebtRelationship>, "status": "success" }
      
      final response = await _apiService.getGroup(groupId.toString());
      
      if (response.containsKey('group')) {
        final groupData = response['group'];
        final debtsJson = groupData['debts'] as List<dynamic>? ?? [];
        
        final debts = debtsJson
            .map((debtJson) => DebtRelationship.fromJson(debtJson))
            .toList();
        
        // Validate all debt relationships
        for (final debt in debts) {
          if (!debt.isValid()) {
            throw GroupDetailServiceException('Invalid debt relationship data received');
          }
        }
        
        return debts;
      } else {
        throw GroupDetailServiceException(response['message'] ?? 'Failed to load debt relationships');
      }
    } catch (e) {
      if (e is GroupDetailServiceException) {
        rethrow;
      }
      throw GroupDetailServiceException('Failed to load debt relationships: $e');
    }
  }

  /// Add a new participant to the group
  /// 
  /// This method adds a new member to the group by email and name.
  /// The backend will handle user lookup and invitation if needed.
  /// 
  /// [groupId] - The ID of the group to add member to
  /// [email] - Email address of the new member
  /// [name] - Display name of the new member
  /// 
  /// Returns [GroupMember] representing the newly added member
  /// Throws [GroupDetailServiceException] on API errors or validation failures
  static Future<GroupMember> addParticipant(int groupId, String email, String name) async {
    // Validate input parameters
    if (email.isEmpty || name.isEmpty) {
      throw GroupDetailServiceException('Email and name are required');
    }
    
    if (!_isValidEmail(email)) {
      throw GroupDetailServiceException('Invalid email format');
    }

    try {
      // TODO: Replace with actual API call when backend is ready
      // Expected API call: POST /api/groups/{groupId}/members
      // Request body: { "email": string, "name": string }
      // Expected response format: { "member": GroupMember, "status": "success" }
      
      final response = await _apiService.addGroupMember(
        groupId.toString(),
        email,
        name,
      );
      
      if (response.containsKey('member')) {
        final newMember = GroupMember.fromJson(response['member']);
        
        // Validate member data
        if (!newMember.isValid()) {
          throw GroupDetailServiceException('Invalid member data received');
        }
        
        // Invalidate cache to force refresh
        _invalidateDetailCache(groupId);
        
        return newMember;
      } else {
        throw GroupDetailServiceException(response['message'] ?? 'Failed to add participant');
      }
    } catch (e) {
      if (e is GroupDetailServiceException) {
        rethrow;
      }
      throw GroupDetailServiceException('Failed to add participant: $e');
    }
  }

  /// Remove a participant from the group
  /// 
  /// This method removes a member from the group after validating they have no outstanding debts.
  /// The backend will perform debt validation before allowing removal.
  /// 
  /// [groupId] - The ID of the group to remove member from
  /// [memberId] - The ID of the member to remove
  /// 
  /// Returns [Map] containing success status and any debt information
  /// Throws [GroupDetailServiceException] on API errors or if member has debts
  static Future<Map<String, dynamic>> removeParticipant(int groupId, String memberId) async {
    if (memberId.isEmpty) {
      throw GroupDetailServiceException('Member ID is required');
    }

    try {
      // TODO: Replace with actual API call when backend is ready
      // Expected API call: DELETE /api/groups/{groupId}/members/{memberId}
      // Expected response format: { "success": boolean, "hasDebts": boolean, "message": string }
      
      final response = await _apiService.removeGroupMember(
        groupId.toString(),
        memberId,
      );
      
      if (response['status'] == 'success') {
        // Invalidate cache to force refresh
        _invalidateDetailCache(groupId);
        
        return {
          'success': true,
          'hasDebts': false,
          'message': response['message'] ?? 'Member removed successfully',
        };
      } else {
        // Check if removal failed due to outstanding debts
        final message = response['message'] ?? 'Failed to remove participant';
        final hasDebts = message.toLowerCase().contains('debt') || 
                        message.toLowerCase().contains('owe');
        
        return {
          'success': false,
          'hasDebts': hasDebts,
          'message': message,
        };
      }
    } catch (e) {
      if (e is GroupDetailServiceException) {
        rethrow;
      }
      throw GroupDetailServiceException('Failed to remove participant: $e');
    }
  }

  /// Share group with others
  /// 
  /// This method generates a shareable link or invitation for the group
  /// that can be sent to potential new members.
  /// 
  /// [groupId] - The ID of the group to share
  /// 
  /// Returns [Map] containing share information (link, code, etc.)
  /// Throws [GroupDetailServiceException] on API errors
  static Future<Map<String, dynamic>> shareGroup(int groupId) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // Expected API call: POST /api/groups/{groupId}/share
      // Expected response format: { "shareLink": string, "shareCode": string, "status": "success" }
      
      // For now, simulate share functionality
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Generate mock share data
      final shareLink = 'https://splitease.app/join/${groupId}';
      final shareCode = 'GROUP${groupId.toString().padLeft(6, '0')}';
      
      return {
        'shareLink': shareLink,
        'shareCode': shareCode,
        'message': 'Group share link generated successfully',
      };
    } catch (e) {
      throw GroupDetailServiceException('Failed to share group: $e');
    }
  }

  /// Exit/leave the group
  /// 
  /// This method removes the current user from the group.
  /// The backend will validate that the user has no outstanding debts before allowing exit.
  /// 
  /// [groupId] - The ID of the group to exit
  /// 
  /// Returns [Map] containing exit status and any validation messages
  /// Throws [GroupDetailServiceException] on API errors or if user has debts
  static Future<Map<String, dynamic>> exitGroup(int groupId) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // Expected API call: POST /api/groups/{groupId}/leave
      // Expected response format: { "success": boolean, "hasDebts": boolean, "message": string }
      
      // Get current user ID
      final userId = await _apiService.getUserId();
      if (userId == null) {
        throw GroupDetailServiceException('User not authenticated');
      }
      
      // For now, simulate exit functionality with debt validation
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Check if user has outstanding debts (mock validation)
      final debts = await getDebtRelationships(groupId);
      final userIdInt = int.tryParse(userId) ?? 0;
      final hasDebts = debts.any((debt) => debt.involvesUser(userIdInt));
      
      if (hasDebts) {
        return {
          'success': false,
          'hasDebts': true,
          'message': 'Cannot leave group while you have outstanding debts. Please settle all debts first.',
        };
      }
      
      // Invalidate cache
      _invalidateDetailCache(groupId);
      
      return {
        'success': true,
        'hasDebts': false,
        'message': 'Successfully left the group',
      };
    } catch (e) {
      if (e is GroupDetailServiceException) {
        rethrow;
      }
      throw GroupDetailServiceException('Failed to exit group: $e');
    }
  }

  /// Delete the group
  /// 
  /// This method deletes the entire group. Only the group creator can perform this action.
  /// The backend will validate permissions and ensure all debts are settled before deletion.
  /// 
  /// [groupId] - The ID of the group to delete
  /// 
  /// Returns [Map] containing deletion status and validation messages
  /// Throws [GroupDetailServiceException] on API errors or permission issues
  static Future<Map<String, dynamic>> deleteGroup(int groupId) async {
    try {
      // TODO: Replace with actual API call when backend is ready
      // Expected API call: DELETE /api/groups/{groupId}
      // Expected response format: { "success": boolean, "message": string }
      
      final response = await _apiService.deleteGroup(groupId.toString());
      
      if (response['status'] == 'success') {
        // Invalidate cache
        _invalidateDetailCache(groupId);
        
        return {
          'success': true,
          'message': response['message'] ?? 'Group deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to delete group',
        };
      }
    } catch (e) {
      if (e is GroupDetailServiceException) {
        rethrow;
      }
      throw GroupDetailServiceException('Failed to delete group: $e');
    }
  }

  // Cache management methods for better performance
  static bool _isDetailCacheValid(int groupId) {
    return _detailCache.containsKey(groupId) && 
           _cacheTimestamps.containsKey(groupId) &&
           DateTime.now().difference(_cacheTimestamps[groupId]!) < _cacheExpiry;
  }
  
  static void _updateDetailCache(int groupId, GroupDetailModel detail) {
    _detailCache[groupId] = detail;
    _cacheTimestamps[groupId] = DateTime.now();
  }
  
  static void _invalidateDetailCache(int groupId) {
    _detailCache.remove(groupId);
    _cacheTimestamps.remove(groupId);
  }
  
  /// Clear all cached group details (useful for testing or force refresh)
  static void clearCache() {
    _detailCache.clear();
    _cacheTimestamps.clear();
  }

  /// Refresh group details and return updated data
  /// 
  /// This is a convenience method that forces a cache refresh
  /// and returns the updated group details
  static Future<GroupDetailModel> refreshGroupDetails(int groupId) async {
    return getGroupDetails(groupId, forceRefresh: true);
  }

  // Utility methods
  static bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
}

/// Custom exception class for group detail service errors
class GroupDetailServiceException implements Exception {
  final String message;
  
  const GroupDetailServiceException(this.message);
  
  @override
  String toString() => 'GroupDetailServiceException: $message';
}