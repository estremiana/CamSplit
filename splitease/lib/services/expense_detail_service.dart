import '../models/expense_detail_model.dart';
import '../models/participant_amount.dart';
import '../models/expense.dart';
import '../models/group_member.dart';
import 'api_service.dart';

/// Custom exception for network-related errors in service layer
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// Service class for handling expense detail operations
/// 
/// This service provides functionality for:
/// - Fetching detailed expense information
/// - Updating expense data
/// - Validating expense changes
/// 
/// All methods include proper error handling and data validation
class ExpenseDetailService {
  static final ApiService _apiService = ApiService.instance;
  
  // Cache for expense details to avoid repeated API calls
  static final Map<int, ExpenseDetailModel> _detailCache = {};
  static final Map<int, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Fetch detailed expense information by ID
  /// 
  /// This method retrieves comprehensive expense data including
  /// all participant amounts, split information, and metadata
  /// 
  /// [expenseId] - The ID of the expense to fetch details for
  /// [forceRefresh] - Whether to bypass cache and fetch fresh data
  /// 
  /// Returns [ExpenseDetailModel] with complete expense information
  /// Throws [ExpenseDetailServiceException] on API errors or network failures
  static Future<ExpenseDetailModel> getExpenseById(int expenseId, {bool forceRefresh = false}) async {
    // Validate input
    if (expenseId <= 0) {
      throw ExpenseDetailServiceException('Invalid expense ID: $expenseId');
    }

    // Check cache first (unless force refresh is requested)
    if (!forceRefresh && _isDetailCacheValid(expenseId)) {
      return _detailCache[expenseId]!;
    }

    try {
      final response = await _apiService.getExpenseWithDetails(expenseId.toString());
      
      if (response['success']) {
        final data = response['data'];
        final expenseData = data['expense'] ?? data; // Handle both nested and direct response
        final expense = Expense.fromJson(expenseData);
        
        // Convert Expense to ExpenseDetailModel
        final expenseDetail = _convertExpenseToDetailModel(expense);
        
        // Enhance with group information
        final enhancedExpenseDetail = await _enhanceWithGroupInfo(expenseDetail);
        
        // Validate data integrity
        if (!enhancedExpenseDetail.isValid()) {
          throw ExpenseDetailServiceException('Invalid expense detail data received from server');
        }
        
        // Update cache
        _updateDetailCache(expenseId, enhancedExpenseDetail);
        
        return enhancedExpenseDetail;
      } else {
        throw ExpenseDetailServiceException(response['message'] ?? 'Failed to load expense details');
      }
    } on ExpenseDetailServiceException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      // Convert unknown errors to appropriate exception types
      if (e.toString().contains('timeout') || 
          e.toString().contains('connection') ||
          e.toString().contains('network')) {
        throw NetworkException('Network error: ${e.toString()}');
      }
      throw ExpenseDetailServiceException('Failed to load expense details: $e');
    }
  }

  /// Update expense data
  /// 
  /// This method updates an existing expense with new data.
  /// The group field cannot be changed as per requirements.
  /// 
  /// [request] - The expense update request containing new data
  /// 
  /// Returns [ExpenseDetailModel] with updated expense information
  /// Throws [ExpenseDetailServiceException] on API errors or validation failures
  static Future<ExpenseDetailModel> updateExpense(ExpenseUpdateRequest request) async {
    // Validate request data
    if (!request.isValid()) {
      throw ExpenseDetailServiceException('Invalid expense update data: missing required fields');
    }

    // Additional validation
    if (request.expenseId <= 0) {
      throw ExpenseDetailServiceException('Invalid expense ID');
    }

    try {
      // Use the request's toJson method which includes proper formatting
      final updateData = request.toJson();
      
      final response = await _apiService.updateExpense(request.expenseId.toString(), updateData);
      
      if (response['success']) {
        final data = response['data'];
        final expenseData = data['expense'] ?? data; // Handle both nested and direct response
        final expense = Expense.fromJson(expenseData);
        
        // Convert Expense to ExpenseDetailModel
        final expenseDetail = _convertExpenseToDetailModel(expense);
        
        // Note: Backend doesn't return splits in update response, so we need to
        // create a proper ExpenseDetailModel with the participant amounts from the request
        final updatedExpenseDetail = expenseDetail.copyWith(
          participantAmounts: request.participantAmounts,
        );
        
        // Only validate basic fields that should be returned
        if (updatedExpenseDetail.title.isEmpty || updatedExpenseDetail.amount <= 0) {
          throw ExpenseDetailServiceException('Backend returned invalid expense data');
        }
        
        // Update cache
        _updateDetailCache(request.expenseId, updatedExpenseDetail);
        
        return updatedExpenseDetail;
      } else {
        throw ExpenseDetailServiceException(response['message'] ?? 'Failed to update expense');
      }
    } on ExpenseDetailServiceException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      // Convert unknown errors to appropriate exception types
      if (e.toString().contains('timeout') || 
          e.toString().contains('connection') ||
          e.toString().contains('network')) {
        throw NetworkException('Network error during save: ${e.toString()}');
      }
      throw ExpenseDetailServiceException('Failed to update expense: $e');
    }
  }

  /// Validate expense update data
  /// 
  /// This method performs comprehensive validation of expense data
  /// before attempting to update it
  /// 
  /// [data] - The expense data to validate
  /// 
  /// Returns [Map] containing validation results and any error messages
  static Map<String, dynamic> validateExpenseUpdate(ExpenseDetailModel data) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Basic field validation
    if (data.title.trim().isEmpty) {
      errors.add('Title is required');
    } else if (data.title.trim().length < 3) {
      errors.add('Title must be at least 3 characters long');
    } else if (data.title.trim().length > 100) {
      errors.add('Title cannot exceed 100 characters');
    }
    
    // Amount validation
    if (data.amount <= 0) {
      errors.add('Amount must be greater than zero');
    } else if (data.amount > 999999.99) {
      errors.add('Amount cannot exceed 999,999.99');
    } else if (data.amount < 0.01) {
      errors.add('Amount must be at least 0.01');
    }
    
    // Currency validation
    if (data.currency.trim().isEmpty) {
      errors.add('Currency is required');
    } else if (data.currency.length != 3) {
      errors.add('Currency must be a valid 3-letter code');
    }
    
    // Category validation
    if (data.category.trim().isEmpty) {
      errors.add('Category is required');
    }
    
    // Notes validation
    if (data.notes.length > 500) {
      errors.add('Notes cannot exceed 500 characters');
    }
    
    // Date validation
    final now = DateTime.now();
    final maxFutureDate = now.add(const Duration(days: 1));
    final maxPastDate = now.subtract(const Duration(days: 365));
    
    if (data.date.isAfter(maxFutureDate)) {
      errors.add('Date cannot be more than 1 day in the future');
    } else if (data.date.isBefore(maxPastDate)) {
      errors.add('Date cannot be more than 1 year in the past');
    }
    
    // Split type validation
    if (!['equal', 'custom', 'percentage'].contains(data.splitType)) {
      errors.add('Invalid split type');
    }
    
    // Participant amounts validation
    if (data.participantAmounts.isEmpty) {
      errors.add('At least one participant is required');
    } else if (data.participantAmounts.length > 50) {
      errors.add('Too many participants (maximum 50 allowed)');
    } else {
      // Check individual participant amounts
      final participantNames = <String>{};
      for (int i = 0; i < data.participantAmounts.length; i++) {
        final participant = data.participantAmounts[i];
        
        if (participant.name?.trim().isEmpty ?? true) {
          errors.add('Participant name cannot be empty');
          continue;
        } else if ((participant.name?.trim().length ?? 0) > 50) {
          errors.add('Participant name cannot exceed 50 characters');
          continue;
        }
        
        // Check for duplicate names
        if (participantNames.contains(participant.name)) {
          errors.add('Duplicate participant name: ${participant.name}');
          continue;
        }
        participantNames.add(participant.name ?? 'Unknown');
        
        if (participant.amount < 0) {
          errors.add('Participant ${i + 1} amount cannot be negative');
        } else if (participant.amount > data.amount) {
          errors.add('Participant ${i + 1} amount cannot exceed total amount');
        }
      }
      
      // Split type specific validation
      switch (data.splitType) {
        case 'custom':
          final calculatedTotal = data.calculatedTotal;
          if ((calculatedTotal - data.amount).abs() > 0.01) {
            errors.add('Participant amounts (${calculatedTotal.toStringAsFixed(2)}) do not match total amount (${data.amount.toStringAsFixed(2)})');
          }
          
          // Check for zero amounts in custom split
          final zeroAmounts = data.participantAmounts.where((p) => p.amount == 0);
          if (zeroAmounts.isNotEmpty) {
            warnings.add('Some participants have zero amounts in custom split');
          }
          break;
          
        case 'equal':
          // Warn if amount doesn't divide evenly
          final remainder = data.amount % data.participantAmounts.length;
          if (remainder > 0.01) {
            warnings.add('Amount doesn\'t divide evenly among participants');
          }
          break;
          
        case 'percentage':
          // This validation would be done on the UI side for percentage splits
          // since the service receives calculated amounts
          break;
      }
    }
    
    // Business rule validation
    if (!data.canBeEdited) {
      errors.add('Expense is too old to be edited (older than 30 days)');
    }
    
    // Group validation
    if (data.groupId.trim().isEmpty) {
      errors.add('Group ID is required');
    }
    
    if (data.groupName.trim().isEmpty) {
      errors.add('Group name is required');
    }
    
    // Payer validation
    if (data.payerName.trim().isEmpty) {
      errors.add('Payer name is required');
    }
    
    if (data.payerId <= 0) {
      errors.add('Valid payer ID is required');
    }
    
    // Timestamp validation
    if (data.createdAt.isAfter(now)) {
      errors.add('Created date cannot be in the future');
    }
    
    if (data.updatedAt.isBefore(data.createdAt)) {
      errors.add('Updated date cannot be before created date');
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'hasWarnings': warnings.isNotEmpty,
      'warnings': warnings,
    };
  }

  /// Enhance expense detail with group information
  /// This method fetches the group details to get the actual group name
  static Future<ExpenseDetailModel> _enhanceWithGroupInfo(ExpenseDetailModel expenseDetail, {String? groupName}) async {
    // If group name is already provided, use it
    if (groupName != null && groupName.isNotEmpty && groupName != 'Unknown Group') {
      return expenseDetail.copyWith(groupName: groupName);
    }
    
    try {
      final groupId = int.tryParse(expenseDetail.groupId);
      if (groupId != null && groupId > 0) {
        final groupResponse = await _apiService.getGroup(groupId.toString());
        if (groupResponse['success'] && groupResponse['data'] != null) {
          final groupData = groupResponse['data'];
          final fetchedGroupName = groupData['name'] ?? 'Unknown Group';
          
          return expenseDetail.copyWith(groupName: fetchedGroupName);
        }
      }
    } catch (e) {
      // If group fetch fails, continue with the original expense detail
      print('Failed to fetch group info: $e');
    }
    
    return expenseDetail;
  }

  /// Convert Expense model to ExpenseDetailModel
  /// 
  /// This is a helper method that converts the backend Expense model
  /// but the frontend expects ExpenseDetailModel objects
  static ExpenseDetailModel _convertExpenseToDetailModel(Expense expense, {String? groupName}) {
    // Convert expense splits to participant amounts
    final participantAmounts = expense.splits.map((split) {
      return ParticipantAmount(
        name: split.displayName, // Use the actual member name from the split
        amount: split.amountOwed,
        percentage: split.percentage, // Include percentage data from the split
        groupMemberId: split.groupMemberId, // Include group member ID for better mapping
      );
    }).toList();
    
    // Get payer information from expense payers
    String payerName = 'Unknown Payer';
    int payerId = 0;
    if (expense.payers.isNotEmpty) {
      final primaryPayer = expense.payers.first;
      payerId = primaryPayer.groupMemberId;
      payerName = primaryPayer.displayName; // Use the actual payer name from the model
      print('Converted expense payer - groupMemberId: ${primaryPayer.groupMemberId}, displayName: ${primaryPayer.displayName}');
    }
    
    // Get receipt image URL if available
    String? receiptImageUrl;
    if (expense.receiptImages.isNotEmpty) {
      receiptImageUrl = expense.receiptImages.first.imageUrl;
    }
    
    // Use the actual split type from the expense
    String splitType = expense.splitType;
    
    return ExpenseDetailModel(
      id: expense.id,
      title: expense.title.isNotEmpty ? expense.title : 'Expense',
      amount: expense.totalAmount,
      currency: expense.currency.isNotEmpty ? expense.currency : 'EUR',
      date: expense.date ?? DateTime.now(),
      category: expense.category?.isNotEmpty == true ? expense.category! : 'Other',
      notes: expense.description ?? '',
      groupId: expense.groupId.toString(),
      groupName: groupName ?? 'Group ${expense.groupId}', // Use provided group name or fallback
      payerName: payerName,
      payerId: payerId,
      splitType: splitType,
      participantAmounts: participantAmounts,
      receiptImageUrl: receiptImageUrl,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
  }

  // Cache management methods for better performance
  static bool _isDetailCacheValid(int expenseId) {
    return _detailCache.containsKey(expenseId) && 
           _cacheTimestamps.containsKey(expenseId) &&
           DateTime.now().difference(_cacheTimestamps[expenseId]!) < _cacheExpiry;
  }
  
  static void _updateDetailCache(int expenseId, ExpenseDetailModel detail) {
    _detailCache[expenseId] = detail;
    _cacheTimestamps[expenseId] = DateTime.now();
  }
  
  // Removed unused method
  
  /// Clear all cached expense details (useful for testing or force refresh)
  static void clearCache() {
    _detailCache.clear();
    _cacheTimestamps.clear();
  }

  /// Refresh expense details and return updated data
  /// 
  /// This is a convenience method that forces a cache refresh
  /// and returns the updated expense details
  static Future<ExpenseDetailModel> refreshExpenseDetails(int expenseId) async {
    return getExpenseById(expenseId, forceRefresh: true);
  }

  /// Get expense details with enhanced member information
  /// 
  /// This method fetches expense details and enhances them with
  /// actual member names from the group
  /// 
  /// [expenseId] - The ID of the expense to fetch
  /// [groupId] - The ID of the group to get member information from
  /// 
  /// Returns [ExpenseDetailModel] with enhanced member information
  static Future<ExpenseDetailModel> getExpenseWithMemberDetails(int expenseId, int groupId) async {
    try {
      // Get the basic expense details
      final expenseDetail = await getExpenseById(expenseId);
      
      // Get group details to enhance member names
      final groupResponse = await _apiService.getGroupWithMembers(groupId.toString());
      if (groupResponse['success']) {
        final groupData = groupResponse['data'];
        final groupName = groupData['name'] ?? 'Unknown Group'; // Get the actual group name
        final members = (groupData['members'] as List<dynamic>?)
            ?.map((memberJson) => GroupMember.fromJson(memberJson, groupId: groupId))
            .toList() ?? [];
        
        // Create a map of member ID to member name for quick lookup
        final memberMap = <int, String>{};
        for (final member in members) {
          memberMap[member.id] = member.nickname;
        }
        
        // The participant amounts should already have the correct names from the backend
        // No need to enhance them since they come from the expense splits
        final enhancedParticipantAmounts = expenseDetail.participantAmounts;
        
        // Enhance payer name if needed
        String enhancedPayerName = expenseDetail.payerName;
        if (expenseDetail.payerId > 0 && memberMap.containsKey(expenseDetail.payerId)) {
          enhancedPayerName = memberMap[expenseDetail.payerId]!;
        }
        
        // Return enhanced expense detail with actual group name
        return expenseDetail.copyWith(
          participantAmounts: enhancedParticipantAmounts,
          payerName: enhancedPayerName,
          groupName: groupName, // Use the actual group name
        );
      }
      
      return expenseDetail;
    } catch (e) {
      // If group details fail, return the basic expense detail
      return await getExpenseById(expenseId);
    }
  }
}

/// Custom exception class for expense detail service errors
class ExpenseDetailServiceException implements Exception {
  final String message;
  
  const ExpenseDetailServiceException(this.message);
  
  @override
  String toString() => 'ExpenseDetailServiceException: $message';
}