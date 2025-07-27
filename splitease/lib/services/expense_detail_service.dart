import '../models/expense_detail_model.dart';
import '../models/participant_amount.dart';
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
  static const Duration _requestTimeout = Duration(seconds: 30);
  
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
      // TODO: Replace with actual API call when backend is ready
      // Expected API call: GET /api/expenses/{expenseId}
      // Expected response format: { "expense": ExpenseDetailModel, "status": "success" }
      
      // Simulate network delay and potential failures
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simulate network errors for testing (remove in production)
      if (expenseId == 9999) {
        throw NetworkException('Connection timeout');
      }
      
      // Handle invalid expense ID for testing
      if (expenseId < 0) {
        throw ExpenseDetailServiceException('Invalid expense ID: $expenseId');
      }
      
      // Simulate not found error
      if (expenseId > 1000) {
        throw ExpenseDetailServiceException('Expense not found');
      }
      
      // Generate mock expense detail data
      final mockExpenseDetail = _generateMockExpenseDetail(expenseId);
      
      // Validate data integrity
      if (!mockExpenseDetail.isValid()) {
        throw ExpenseDetailServiceException('Invalid expense detail data received from server');
      }
      
      // Update cache
      _updateDetailCache(expenseId, mockExpenseDetail);
      
      return mockExpenseDetail;
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
      // TODO: Replace with actual API call when backend is ready
      // Expected API call: PUT /api/expenses/{expenseId}
      // Request body: ExpenseUpdateRequest.toJson()
      // Expected response format: { "expense": ExpenseDetailModel, "status": "success" }
      
      // Simulate network delay and potential failures
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Simulate various error conditions for testing
      if (request.expenseId == 998) {
        throw NetworkException('Connection timeout during save');
      }
      
      if (request.expenseId == 997) {
        throw ExpenseDetailServiceException('Expense was modified by another user');
      }
      
      if (request.expenseId > 1000) {
        throw ExpenseDetailServiceException('Expense not found');
      }
      
      // Get current expense data (this may throw if expense doesn't exist)
      final currentExpense = await getExpenseById(request.expenseId);
      
      // Check if expense can still be edited
      if (!currentExpense.canBeEdited) {
        throw ExpenseDetailServiceException('Expense is too old to be edited');
      }
      
      // Create updated expense (preserving read-only fields)
      final updatedExpense = currentExpense.copyWith(
        title: request.title,
        amount: request.amount,
        currency: request.currency,
        date: request.date,
        category: request.category,
        notes: request.notes,
        splitType: request.splitType,
        participantAmounts: request.participantAmounts,
        updatedAt: DateTime.now(),
      );
      
      // Validate updated expense
      if (!updatedExpense.isValid()) {
        throw ExpenseDetailServiceException('Updated expense data failed validation');
      }
      
      // Additional business rule validation
      final validationResult = validateExpenseUpdate(updatedExpense);
      if (!validationResult['isValid']) {
        final errors = validationResult['errors'] as List<String>;
        throw ExpenseDetailServiceException('Validation failed: ${errors.join(', ')}');
      }
      
      // Update cache
      _updateDetailCache(request.expenseId, updatedExpense);
      
      return updatedExpense;
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
        
        if (participant.name.trim().isEmpty) {
          errors.add('Participant ${i + 1} name is required');
        } else if (participant.name.trim().length > 50) {
          errors.add('Participant ${i + 1} name cannot exceed 50 characters');
        } else if (participantNames.contains(participant.name)) {
          errors.add('Duplicate participant name: ${participant.name}');
        } else {
          participantNames.add(participant.name);
        }
        
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

  /// Generate mock expense detail data for testing
  /// This will be replaced with actual API calls
  static ExpenseDetailModel _generateMockExpenseDetail(int expenseId) {
    // Mock data based on expense ID for consistency
    final mockData = {
      1: {
        'title': 'Dinner at Italian Restaurant',
        'amount': 85.50,
        'category': 'Food & Dining',
        'notes': 'Great pasta and wine',
        'payer_name': 'John Doe',
        'payer_id': 123,
        'split_type': 'custom',
        'participant_amounts': [
          {'name': 'John Doe', 'amount': 35.50},
          {'name': 'Jane Smith', 'amount': 25.00},
          {'name': 'Bob Wilson', 'amount': 25.00},
        ],
      },
      2: {
        'title': 'Uber to Airport',
        'amount': 45.00,
        'category': 'Transportation',
        'notes': 'Shared ride to catch flight',
        'payer_name': 'Jane Smith',
        'payer_id': 456,
        'split_type': 'equal',
        'participant_amounts': [
          {'name': 'John Doe', 'amount': 15.00},
          {'name': 'Jane Smith', 'amount': 15.00},
          {'name': 'Bob Wilson', 'amount': 15.00},
        ],
      },
      3: {
        'title': 'Concert Tickets',
        'amount': 120.00,
        'category': 'Entertainment',
        'notes': 'Amazing show!',
        'payer_name': 'Bob Wilson',
        'payer_id': 789,
        'split_type': 'equal',
        'participant_amounts': [
          {'name': 'John Doe', 'amount': 40.00},
          {'name': 'Jane Smith', 'amount': 40.00},
          {'name': 'Bob Wilson', 'amount': 40.00},
        ],
      },
    };
    
    final data = mockData[expenseId] ?? mockData[1]!;
    
    return ExpenseDetailModel(
      id: expenseId,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      currency: 'EUR',
      date: DateTime.now().subtract(Duration(days: expenseId)),
      category: data['category'] as String,
      notes: data['notes'] as String,
      groupId: '1',
      groupName: 'Weekend Getaway 🏖️',
      payerName: data['payer_name'] as String,
      payerId: data['payer_id'] as int,
      splitType: data['split_type'] as String,
      participantAmounts: (data['participant_amounts'] as List)
          .map((p) => ParticipantAmount.fromJson(p as Map<String, dynamic>))
          .toList(),
      receiptImageUrl: expenseId == 1 ? 'https://images.pexels.com/photos/4386321/pexels-photo-4386321.jpeg' : null,
      createdAt: DateTime.now().subtract(Duration(days: expenseId, hours: 2)),
      updatedAt: DateTime.now().subtract(Duration(days: expenseId, hours: 1)),
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
  
  static void _invalidateDetailCache(int expenseId) {
    _detailCache.remove(expenseId);
    _cacheTimestamps.remove(expenseId);
  }
  
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
}

/// Custom exception class for expense detail service errors
class ExpenseDetailServiceException implements Exception {
  final String message;
  
  const ExpenseDetailServiceException(this.message);
  
  @override
  String toString() => 'ExpenseDetailServiceException: $message';
}