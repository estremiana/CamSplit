import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/group.dart';
import '../models/expense.dart';
import '../models/payment.dart';
import '../models/item.dart';
import '../models/assignment.dart';
import '../models/receipt_image.dart';
import '../models/dashboard_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_clearer_service.dart';

class ApiService {
  late Dio _dio;
  static ApiService? _instance;
  
  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        print('API Error: ${error.message}');
        
        // Handle token expiration
        if (error.response?.statusCode == 401) {
          // Clear expired token
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
          await prefs.remove('user_id');
          print('Token expired - cleared from storage');
        }
        
        handler.next(error);
      },
    ));
  }
  
  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }
  
  /// Get the Dio instance for direct HTTP requests
  Dio get dio => _dio;
  
  // ==================== USER ENDPOINTS ====================
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(ApiConfig.loginEndpoint, data: {
        'email': email,
        'password': password,
      });
      
      if (response.statusCode == 200 && response.data['success']) {
        // Store token and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.data['data']['token']);
        await prefs.setString('user_id', response.data['data']['user']['id'].toString());
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> register(
    String email, 
    String password, 
    String firstName,
    String lastName,
    String? phone,
  ) async {
    try {
      final response = await _dio.post(ApiConfig.registerEndpoint, data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
      });
      
      if (response.statusCode == 201 && response.data['success']) {
        // Store token and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.data['data']['token']);
        await prefs.setString('user_id', response.data['data']['user']['id'].toString());
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get(ApiConfig.profileEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _dio.put(ApiConfig.updateProfileEndpoint, data: profileData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> updatePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _dio.put(ApiConfig.updatePasswordEndpoint, data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _dio.get(ApiConfig.dashboardEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<DashboardModel> getDashboardModel() async {
    try {
      final response = await _dio.get(ApiConfig.dashboardEndpoint);
      final data = response.data['data'] as Map<String, dynamic>;
      return DashboardModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> searchUsers(String query) async {
    try {
      final response = await _dio.get('${ApiConfig.searchUsersEndpoint}?q=$query');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> checkUserExists(String email) async {
    try {
      final response = await _dio.get('${ApiConfig.userExistsEndpoint}?email=$email');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _dio.get(ApiConfig.userStatsEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final response = await _dio.delete(ApiConfig.deleteAccountEndpoint, data: {
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> verifyToken() async {
    try {
      final response = await _dio.get(ApiConfig.verifyTokenEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // ==================== GROUP ENDPOINTS ====================
  
  Future<Map<String, dynamic>> getGroups() async {
    try {
      final response = await _dio.get(ApiConfig.groupsEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getGroup(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupsEndpoint}/$groupId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getGroupWithMembers(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupsEndpoint}/$groupId/with-members');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> createGroup(String name, String currency, String description) async {
    try {
      final response = await _dio.post(ApiConfig.groupsEndpoint, data: {
        'name': name,
        'currency': currency,
        'description': description,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateGroup(String groupId, Map<String, dynamic> groupData) async {
    try {
      final response = await _dio.put('${ApiConfig.groupsEndpoint}/$groupId', data: groupData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> deleteGroup(String groupId) async {
    try {
      final response = await _dio.delete('${ApiConfig.groupsEndpoint}/$groupId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> deleteGroupWithCascade(String groupId) async {
    try {
      final response = await _dio.delete('${ApiConfig.groupsEndpoint}/$groupId/cascade');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> exitGroup(String groupId) async {
    try {
      final response = await _dio.post('${ApiConfig.groupsEndpoint}/$groupId/exit');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> checkGroupAutoDeleteStatus(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupsEndpoint}/$groupId/auto-delete-status');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> addGroupMember(String groupId, Map<String, dynamic> memberData) async {
    try {
      final response = await _dio.post('${ApiConfig.groupsEndpoint}/$groupId/members', data: memberData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> removeGroupMember(String groupId, String memberId) async {
    try {
      final response = await _dio.delete('${ApiConfig.groupsEndpoint}/$groupId/members/$memberId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> claimGroupMember(String groupId, String memberId, String email, String password) async {
    try {
      final response = await _dio.post('${ApiConfig.groupsEndpoint}/$groupId/members/$memberId/claim', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getGroupMembers(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupsEndpoint}/$groupId/members');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getGroupExpenses(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupsEndpoint}/$groupId/expenses');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getGroupPaymentSummary(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupsEndpoint}/$groupId/payment-summary');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getUserBalanceForGroup(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupsEndpoint}/$groupId/user-balance');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> searchGroups(String query) async {
    try {
      final response = await _dio.get('${ApiConfig.searchGroupsEndpoint}?q=$query');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getGroupStats(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupsEndpoint}/$groupId/stats');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> inviteUserToGroup(String groupId, String email) async {
    try {
      final response = await _dio.post('${ApiConfig.groupsEndpoint}/$groupId/invite', data: {
        'email': email,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getInvitableGroups() async {
    try {
      final response = await _dio.get(ApiConfig.invitableGroupsEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> checkGroupPermission(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupsEndpoint}/$groupId/permission');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // ==================== INVITE ENDPOINTS ====================
  
  // Generate invite link for a group
  Future<Map<String, dynamic>> generateInviteLink(String groupId, {String? expiresAt, int? maxUses}) async {
    try {
      final data = <String, dynamic>{};
      if (expiresAt != null) data['expiresAt'] = expiresAt;
      if (maxUses != null) data['maxUses'] = maxUses;
      
      final response = await _dio.post('/invites/groups/$groupId/generate', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Get invite details (public endpoint)
  Future<Map<String, dynamic>> getInviteDetails(String inviteCode) async {
    try {
      final response = await _dio.get('/invites/$inviteCode');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Get available members for claiming (public endpoint)
  Future<Map<String, dynamic>> getAvailableMembers(String inviteCode) async {
    try {
      final response = await _dio.get('/invites/$inviteCode/members');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Join group by claiming existing member
  Future<Map<String, dynamic>> joinByClaimingMember(String inviteCode, int memberId) async {
    try {
      final response = await _dio.post('/invites/$inviteCode/join/claim', data: {
        'memberId': memberId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Join group by creating new member
  Future<Map<String, dynamic>> joinByCreatingMember(String inviteCode, String nickname, {String? email}) async {
    try {
      final data = {'nickname': nickname};
      if (email != null) data['email'] = email;
      
      final response = await _dio.post('/invites/$inviteCode/join/create', data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Get all invites for a group
  Future<Map<String, dynamic>> getGroupInvites(String groupId) async {
    try {
      final response = await _dio.get('/invites/groups/$groupId/invites');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Deactivate invite
  Future<Map<String, dynamic>> deactivateInvite(int inviteId) async {
    try {
      final response = await _dio.put('/invites/invites/$inviteId/deactivate');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // ==================== EXPENSE ENDPOINTS ====================
  
  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> expenseData) async {
    try {
      final response = await _dio.post(ApiConfig.expensesEndpoint, data: expenseData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getExpense(String expenseId) async {
    try {
      final response = await _dio.get('${ApiConfig.expensesEndpoint}/$expenseId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getExpenseWithDetails(String expenseId) async {
    try {
      final response = await _dio.get('${ApiConfig.expensesEndpoint}/$expenseId/details');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateExpense(String expenseId, Map<String, dynamic> expenseData) async {
    try {
      final response = await _dio.put('${ApiConfig.expensesEndpoint}/$expenseId', data: expenseData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> deleteExpense(String expenseId) async {
    try {
      final response = await _dio.delete('${ApiConfig.expensesEndpoint}/$expenseId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> addExpensePayer(String expenseId, Map<String, dynamic> payerData) async {
    try {
      final response = await _dio.post('${ApiConfig.expensesEndpoint}/$expenseId/payers', data: payerData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> removeExpensePayer(String expenseId, String payerId) async {
    try {
      final response = await _dio.delete('${ApiConfig.expensesEndpoint}/$expenseId/payers/$payerId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> addExpenseSplit(String expenseId, Map<String, dynamic> splitData) async {
    try {
      final response = await _dio.post('${ApiConfig.expensesEndpoint}/$expenseId/splits', data: splitData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> removeExpenseSplit(String expenseId, String splitId) async {
    try {
      final response = await _dio.delete('${ApiConfig.expensesEndpoint}/$expenseId/splits/$splitId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getExpenseSettlement(String expenseId) async {
    try {
      final response = await _dio.get('${ApiConfig.expensesEndpoint}/$expenseId/settlement');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getGroupExpensesList(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupExpensesEndpoint2.replaceAll('{groupId}', groupId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getUserExpenses() async {
    try {
      final response = await _dio.get(ApiConfig.userExpensesEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> searchExpenses(String query) async {
    try {
      final response = await _dio.get('${ApiConfig.searchExpensesEndpoint}?q=$query');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getGroupExpenseStats(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupExpenseStatsEndpoint.replaceAll('{groupId}', groupId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // ==================== PAYMENT ENDPOINTS ====================
  
  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> paymentData) async {
    try {
      final response = await _dio.post(ApiConfig.paymentsEndpoint, data: paymentData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    try {
      final response = await _dio.get('${ApiConfig.paymentsEndpoint}/$paymentId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getPaymentWithDetails(String paymentId) async {
    try {
      final response = await _dio.get('${ApiConfig.paymentsEndpoint}/$paymentId/details');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> updatePayment(String paymentId, Map<String, dynamic> paymentData) async {
    try {
      final response = await _dio.put('${ApiConfig.paymentsEndpoint}/$paymentId', data: paymentData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> deletePayment(String paymentId) async {
    try {
      final response = await _dio.delete('${ApiConfig.paymentsEndpoint}/$paymentId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> updatePaymentStatus(String paymentId, String status) async {
    try {
      final response = await _dio.patch('${ApiConfig.paymentsEndpoint}/$paymentId/status', data: {
        'status': status,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getGroupPayments(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupPaymentsEndpoint2.replaceAll('{groupId}', groupId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getUserPayments() async {
    try {
      final response = await _dio.get(ApiConfig.userPaymentsEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getPendingPayments() async {
    try {
      final response = await _dio.get(ApiConfig.pendingPaymentsEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getGroupSettlements(String groupId) async {
    try {
      final response = await _dio.get('${ApiConfig.groupSettlementsEndpoint.replaceAll('{groupId}', groupId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Process a settlement by converting it to an expense
  /// POST /api/settlements/:settlementId/settle
  Future<Map<String, dynamic>> processSettlement(String settlementId) async {
    try {
      final response = await _dio.post('${ApiConfig.settlementsEndpoint}/$settlementId/settle');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get settlement details with additional information
  /// GET /api/settlements/:settlementId
  Future<Map<String, dynamic>> getSettlementDetails(String settlementId) async {
    try {
      final response = await _dio.get('${ApiConfig.settlementsEndpoint}/$settlementId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get settlement history for a group
  /// GET /api/groups/:groupId/settlements/history
  Future<Map<String, dynamic>> getSettlementHistory(String groupId, {
    int? limit,
    int? offset,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;
      if (status != null) queryParams['status'] = status;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;

      final response = await _dio.get(
        '${ApiConfig.groupSettlementsEndpoint.replaceAll('{groupId}', groupId)}/history',
        queryParameters: queryParams,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Send a reminder for a settlement
  /// POST /api/settlements/:settlementId/remind
  Future<Map<String, dynamic>> sendSettlementReminder(String settlementId) async {
    try {
      final response = await _dio.post('${ApiConfig.settlementsEndpoint}/$settlementId/remind');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> createSettlementPayments(String groupId) async {
    try {
      final response = await _dio.post(ApiConfig.createSettlementPaymentsEndpoint, data: {
        'group_id': groupId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> markPaymentCompleted(String paymentId) async {
    try {
      final response = await _dio.patch('${ApiConfig.markPaymentCompletedEndpoint.replaceAll('{paymentId}', paymentId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> markPaymentCancelled(String paymentId) async {
    try {
      final response = await _dio.patch('${ApiConfig.markPaymentCancelledEndpoint.replaceAll('{paymentId}', paymentId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // ==================== ITEM ENDPOINTS ====================
  
  Future<Map<String, dynamic>> createItem(Map<String, dynamic> itemData) async {
    try {
      final response = await _dio.post(ApiConfig.itemsEndpoint, data: itemData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getExpenseItems(String expenseId) async {
    try {
      final response = await _dio.get('${ApiConfig.expenseItemsEndpoint.replaceAll('{expenseId}', expenseId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getItem(String itemId) async {
    try {
      final response = await _dio.get('${ApiConfig.itemsEndpoint}/$itemId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateItem(String itemId, Map<String, dynamic> itemData) async {
    try {
      final response = await _dio.put('${ApiConfig.itemsEndpoint}/$itemId', data: itemData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> deleteItem(String itemId) async {
    try {
      final response = await _dio.delete('${ApiConfig.itemsEndpoint}/$itemId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> createItemsFromOCR(Map<String, dynamic> ocrData) async {
    try {
      final response = await _dio.post(ApiConfig.createItemsFromOCREndpoint, data: ocrData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getItemStats() async {
    try {
      final response = await _dio.get(ApiConfig.itemStatsEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> searchItems(String query) async {
    try {
      final response = await _dio.get('${ApiConfig.searchItemsEndpoint}?q=$query');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // ==================== ASSIGNMENT ENDPOINTS ====================
  
  Future<Map<String, dynamic>> createAssignment(Map<String, dynamic> assignmentData) async {
    try {
      final response = await _dio.post(ApiConfig.assignmentsEndpoint, data: assignmentData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getExpenseAssignments(String expenseId) async {
    try {
      final response = await _dio.get('${ApiConfig.expenseAssignmentsEndpoint.replaceAll('{expenseId}', expenseId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getAssignment(String assignmentId) async {
    try {
      final response = await _dio.get('${ApiConfig.assignmentsEndpoint}/$assignmentId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateAssignment(String assignmentId, Map<String, dynamic> assignmentData) async {
    try {
      final response = await _dio.put('${ApiConfig.assignmentsEndpoint}/$assignmentId', data: assignmentData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> deleteAssignment(String assignmentId) async {
    try {
      final response = await _dio.delete('${ApiConfig.assignmentsEndpoint}/$assignmentId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> addUsersToAssignment(String assignmentId, List<String> userIds) async {
    try {
      final response = await _dio.post('${ApiConfig.addUsersToAssignmentEndpoint.replaceAll('{assignmentId}', assignmentId)}', data: {
        'user_ids': userIds,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> removeUserFromAssignment(String assignmentId, String userId) async {
    try {
      final response = await _dio.delete('${ApiConfig.removeUserFromAssignmentEndpoint.replaceAll('{assignmentId}', assignmentId).replaceAll('{userId}', userId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getAssignmentSummary(String assignmentId) async {
    try {
      final response = await _dio.get('${ApiConfig.assignmentSummaryEndpoint.replaceAll('{assignmentId}', assignmentId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // ==================== OCR ENDPOINTS ====================
  
  Future<Map<String, dynamic>> processReceipt(File imageFile) async {
    try {
      // Determine MIME type from file extension
      String mimeType = 'image/jpeg'; // default
      final fileName = imageFile.path.toLowerCase();
      if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }
      
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
          contentType: MediaType.parse(mimeType),
        ),
      });
      final response = await _dio.post(ApiConfig.processReceiptSimpleEndpoint, data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> processReceiptFromUrl(String imageUrl) async {
    try {
      final response = await _dio.post(ApiConfig.processReceiptFromUrlEndpoint, data: {
        'image_url': imageUrl,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getReceiptImages(String expenseId) async {
    try {
      final response = await _dio.get('${ApiConfig.expenseReceiptImagesEndpoint.replaceAll('{expenseId}', expenseId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> deleteReceiptImage(String receiptImageId) async {
    try {
      final response = await _dio.delete('${ApiConfig.receiptImageEndpoint.replaceAll('{receiptImageId}', receiptImageId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> reprocessReceiptImage(String receiptImageId) async {
    try {
      final response = await _dio.post('${ApiConfig.reprocessReceiptImageEndpoint.replaceAll('{receiptImageId}', receiptImageId)}');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getOCRStats() async {
    try {
      final response = await _dio.get(ApiConfig.ocrStatsEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> validateOCRConfiguration() async {
    try {
      final response = await _dio.get(ApiConfig.ocrConfigEndpoint);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Legacy OCR endpoint for backward compatibility
  Future<Map<String, dynamic>> extractItems(String imageUrl) async {
    try {
      final response = await _dio.post(ApiConfig.extractItemsEndpoint, data: {
        'imageUrl': imageUrl,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // ==================== UTILITY METHODS ====================
  
  // Test method to verify API connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      // Create a temporary Dio instance for health check (without /api prefix)
      final tempDio = Dio(BaseOptions(
        baseUrl: ApiConfig.backendUrl,
        connectTimeout: Duration(seconds: 5),
        receiveTimeout: Duration(seconds: 5),
      ));
      
      final response = await tempDio.get('/health');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<void> logout() async {
    // Clear authentication tokens
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    
    // Clear all user-related cache data using the dedicated service
    await CacheClearerService.clearAllUserCache();
  }
  
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      return false;
    }
    
    // Validate token by making a profile API call (which requires authentication)
    try {
      final response = await _dio.get(ApiConfig.profileEndpoint);
      return response.statusCode == 200 && response.data['success'];
    } catch (error) {
      // Token is invalid or expired - tokens are already cleared by the error interceptor
      return false;
    }
  }
  
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
  
  // ==================== ERROR HANDLING ====================
  
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error occurred';
        
        switch (statusCode) {
          case 400:
            return Exception('Bad request: $message');
          case 401:
            return Exception('Unauthorized: Please login again');
          case 403:
            return Exception('Forbidden: You don\'t have permission to perform this action');
          case 404:
            return Exception('Resource not found');
          case 422:
            return Exception('Validation error: $message');
          case 500:
            return Exception('Server error: Please try again later');
          default:
            return Exception('Error $statusCode: $message');
        }
      
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      
      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network settings.');
      
      case DioExceptionType.badCertificate:
        return Exception('SSL certificate error');
      
      case DioExceptionType.unknown:
      default:
        return Exception('An unexpected error occurred');
    }
  }
} 