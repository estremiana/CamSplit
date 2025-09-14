import 'dart:convert';
import '../models/group_detail_model.dart';
import '../models/group_member.dart';
import '../models/group.dart';
import '../models/settlement.dart';
import '../config/api_config.dart';
import '../utils/real_time_updates.dart';
import '../utils/error_recovery.dart';
import 'api_service.dart';
import 'currency_migration_service.dart';

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
      final response = await _apiService.getGroupWithMembers(groupId.toString());
      
      if (response['success']) {
        final groupData = response['data'];
        final group = Group.fromJson(groupData);
        
        // Convert Group to GroupDetailModel
        final groupDetail = await _convertGroupToDetailModel(group);
        
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
      // Get user balance from settlements using the new endpoint
      final response = await _apiService.getUserBalanceForGroup(groupId.toString());
      
      if (response['success']) {
        final balanceData = response['data'];
        
        // Extract balance from the settlements-based calculation
        final balanceString = balanceData['balance']?.toString() ?? '0.0';
        final userBalance = double.tryParse(balanceString) ?? 0.0;
        
        return {
          'balance': userBalance,
          'currency': 'EUR', // TODO: Get currency from group data
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
      final memberData = {
        'email': email,
        'nickname': name,
      };
      
      final response = await _apiService.addGroupMember(
        groupId.toString(),
        memberData,
      );
      
      if (response['success']) {
        final memberData = response['data'];
        final newMember = GroupMember.fromJson(memberData, groupId: groupId);
        
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
      final response = await _apiService.removeGroupMember(
        groupId.toString(),
        memberId,
      );
      
      if (response['success']) {
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
      // For now, generate a simple share link
      // In the future, this could call a backend endpoint to generate unique codes
      final shareLink = 'https://camsplit.app/join/${groupId}';
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
      // Get current user ID
      final userId = await _apiService.getUserId();
      if (userId == null) {
        throw GroupDetailServiceException('User not authenticated');
      }
      
      // For now, simulate exit functionality
      // In the future, this would call a backend endpoint
      final response = await _apiService.removeGroupMember(
        groupId.toString(),
        userId,
      );
      
      if (response['success']) {
        // Invalidate cache
        _invalidateDetailCache(groupId);
        
        return {
          'success': true,
          'hasDebts': false,
          'message': 'Successfully left the group',
        };
      } else {
        return {
          'success': false,
          'hasDebts': false,
          'message': response['message'] ?? 'Failed to leave group',
        };
      }
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
      final response = await _apiService.deleteGroup(groupId.toString());
      
      if (response['success']) {
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

  /// Convert Group model to GroupDetailModel
  /// This is needed because the backend returns Group objects
  /// but the frontend expects GroupDetailModel objects
  static Future<GroupDetailModel> _convertGroupToDetailModel(Group group) async {
        // Fetch group expenses
    List<GroupExpense> expenses = [];
    try {
      final expensesResponse = await _apiService.getGroupExpensesList(group.id.toString());
      
      if (expensesResponse['success'] && expensesResponse['data'] != null) {
        final expensesData = expensesResponse['data'] as List<dynamic>;
        
        expenses = expensesData.map((expenseJson) {
          try {
            // Pass the original expense data to let GroupExpense.fromJson handle the payers array
            return GroupExpense.fromJson(expenseJson);
          } catch (e) {
            // Try to parse dates manually if DateTime.parse fails
            DateTime parseDate(dynamic dateValue) {
              if (dateValue == null) return DateTime.now();
              if (dateValue is DateTime) return dateValue;
              if (dateValue is String) {
                try {
                  return DateTime.parse(dateValue);
                } catch (e) {
                  return DateTime.now();
                }
              }
              return DateTime.now();
            }
            
            // Return a fallback expense to prevent the entire list from failing
            // Handle new backend structure with payers array
            String payerName = 'Unknown';
            int payerId = 0;
            
            if (expenseJson['payers'] != null && expenseJson['payers'] is List && (expenseJson['payers'] as List).isNotEmpty) {
              // Take the first payer from the array
              final firstPayer = expenseJson['payers'][0];
              payerName = firstPayer['name'] ?? 'Unknown';
              payerId = firstPayer['id'] ?? 0;
            } else {
              // Fallback to old structure if payers array is not present
              payerName = expenseJson['created_by_name'] ?? 'Unknown';
              payerId = expenseJson['created_by'] ?? 0;
            }
            
            return GroupExpense(
              id: expenseJson['id'] ?? 0,
              title: expenseJson['title'] ?? 'Expense',
              amount: _parseAmount(expenseJson['total_amount']),
              currency: expenseJson['currency'] ?? 'EUR',
              date: parseDate(expenseJson['date'] ?? expenseJson['created_at']),
              payerName: payerName,
              payerId: payerId,
              createdAt: parseDate(expenseJson['created_at']),
            );
          }
        }).toList();
      }
    } catch (e) {
      // Log error but don't fail the entire group detail fetch
      print('Failed to fetch group expenses: $e');
    }

    // Fetch settlements
    List<Settlement> settlements = [];
    try {
      final settlementsResponse = await _apiService.getGroupSettlements(group.id.toString());
      
      if (settlementsResponse['success'] && settlementsResponse['data'] != null) {
        final settlementsData = settlementsResponse['data']['settlements'] as List<dynamic>?;
        
        if (settlementsData != null) {
          settlements = settlementsData.map((settlementJson) {
            try {
              return Settlement.fromJson(settlementJson);
            } catch (e) {
              print('Failed to parse settlement: $e');
              return null;
            }
          }).where((settlement) => settlement != null).cast<Settlement>().toList();
        }
      }
    } catch (e) {
      // Log error but don't fail the entire group detail fetch
      print('Failed to fetch group settlements: $e');
    }

    // Calculate user balance from settlements
    double userBalance = 0.0;
    try {
      final balanceResponse = await _apiService.getUserBalanceForGroup(group.id.toString());
      
      if (balanceResponse['success'] && balanceResponse['data'] != null) {
        final balanceData = balanceResponse['data'];
        
        // Extract balance from the settlements-based calculation
        final balanceString = balanceData['balance']?.toString() ?? '0.0';
        userBalance = double.tryParse(balanceString) ?? 0.0;
      }
    } catch (e) {
      // Log error but don't fail the entire group detail fetch
      print('Failed to fetch user balance: $e');
    }

    return GroupDetailModel(
      id: group.id,
      name: group.name,
      description: group.description ?? '',
      currency: CurrencyMigrationService.prepareForBackend(group.currency, format: 'code'),
      members: group.members,
      expenses: expenses,
      settlements: settlements,
      userBalance: userBalance,
      lastActivity: group.lastUsed, // Use lastUsed as lastActivity
      canEdit: true, // TODO: Check user permissions
      canDelete: true, // TODO: Check if user is admin
      createdAt: group.createdAt,
      updatedAt: group.updatedAt,
    );
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
  /// and returns the updated group details. It also notifies
  /// real-time update listeners of the change.
  static Future<GroupDetailModel> refreshGroupDetails(int groupId) async {
    try {
      final groupDetail = await getGroupDetails(groupId, forceRefresh: true);
      
      // Notify real-time update listeners
      RealTimeUpdates.notifyGroupUpdate(groupId, groupDetail);
      
      return groupDetail;
    } catch (e) {
      // Log the error for debugging
      print('Failed to refresh group details: $e');
      rethrow;
    }
  }

  /// Update group details optimistically
  /// 
  /// This method updates the cached group data without making an API call
  /// and notifies listeners immediately. Useful for optimistic updates.
  static void updateGroupDetailsOptimistically(int groupId, GroupDetailModel groupDetail) {
    _updateDetailCache(groupId, groupDetail);
    RealTimeUpdates.notifyGroupUpdate(groupId, groupDetail);
  }

  /// Get group details with retry mechanism
  /// 
  /// This method includes automatic retry logic for network failures
  /// and provides better error handling.
  static Future<GroupDetailModel> getGroupDetailsWithRetry(
    int groupId, {
    bool forceRefresh = false,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    Duration retryDelay = Duration(seconds: 1);

    while (retryCount <= maxRetries) {
      try {
        return await getGroupDetails(groupId, forceRefresh: forceRefresh);
      } catch (e) {
        retryCount++;
        
        if (retryCount > maxRetries) {
          rethrow;
        }
        
        // Wait before retry with exponential backoff
        await Future.delayed(retryDelay);
        retryDelay = Duration(seconds: retryDelay.inSeconds * 2);
      }
    }
    
    throw GroupDetailServiceException('Failed to load group details after $maxRetries attempts');
  }

  // Utility methods
  static bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
  
  /// Parse amount from various formats (string, double, int) to double
  static double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) {
      try {
        return double.parse(amount);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}

/// Custom exception class for group detail service errors
class GroupDetailServiceException implements Exception {
  final String message;
  
  const GroupDetailServiceException(this.message);
  
  @override
  String toString() => 'GroupDetailServiceException: $message';
}