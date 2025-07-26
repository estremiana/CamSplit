import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

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
      onError: (error, handler) {
        print('API Error: ${error.message}');
        handler.next(error);
      },
    ));
  }
  
  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }
  
  // Auth endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/users/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.statusCode == 200) {
        // Store token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.data['token']);
        await prefs.setString('user_id', response.data['user']['id'].toString());
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      final response = await _dio.post('/users/register', data: {
        'email': email,
        'password': password,
        'name': name,
      });
      
      if (response.statusCode == 201) {
        // Store token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.data['token']);
        await prefs.setString('user_id', response.data['user']['id'].toString());
      }
      
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Bill endpoints
  Future<Map<String, dynamic>> uploadBill(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
      });
      final response = await _dio.post('/bills/upload', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getBill(String billId) async {
    try {
      final response = await _dio.get('/bills/$billId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> settleBill(String billId) async {
    try {
      final response = await _dio.get('/bills/$billId/settle');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // OCR endpoints
  Future<Map<String, dynamic>> extractItems(String imageUrl) async {
    try {
      final response = await _dio.post('/ocr/extract', data: {
        'imageUrl': imageUrl,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Assignment endpoints
  Future<Map<String, dynamic>> assignItem(String itemId, String participantId) async {
    try {
      final response = await _dio.post('/assignments', data: {
        'itemId': itemId,
        'participantId': participantId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getAssignments(String billId) async {
    try {
      final response = await _dio.get('/assignments?billId=$billId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Participant endpoints
  Future<Map<String, dynamic>> addParticipant(String billId, String name, String email) async {
    try {
      final response = await _dio.post('/participants', data: {
        'billId': billId,
        'name': name,
        'email': email,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getParticipants(String billId) async {
    try {
      final response = await _dio.get('/participants?billId=$billId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Item endpoints
  Future<Map<String, dynamic>> updateItem(String itemId, Map<String, dynamic> itemData) async {
    try {
      final response = await _dio.put('/items/$itemId', data: itemData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> deleteItem(String itemId) async {
    try {
      final response = await _dio.delete('/items/$itemId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Payment endpoints
  Future<Map<String, dynamic>> getPayments(String billId) async {
    try {
      final response = await _dio.get('/payments?billId=$billId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> createPayment(Map<String, dynamic> paymentData) async {
    try {
      final response = await _dio.post('/payments', data: paymentData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  // Group endpoints
  // TODO: Implement these methods when backend group endpoints are ready
  Future<Map<String, dynamic>> getGroups() async {
    try {
      final response = await _dio.get('/groups');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> getGroup(String groupId) async {
    try {
      final response = await _dio.get('/groups/$groupId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> createGroup(String name, List<String> memberEmails) async {
    try {
      final response = await _dio.post('/groups', data: {
        'name': name,
        'member_emails': memberEmails,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateGroup(String groupId, String name) async {
    try {
      final response = await _dio.put('/groups/$groupId', data: {
        'name': name,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> deleteGroup(String groupId) async {
    try {
      final response = await _dio.delete('/groups/$groupId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> addGroupMember(String groupId, String email, String name) async {
    try {
      final response = await _dio.post('/groups/$groupId/members', data: {
        'email': email,
        'name': name,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> removeGroupMember(String groupId, String memberId) async {
    try {
      final response = await _dio.delete('/groups/$groupId/members/$memberId');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
  
  Future<Map<String, dynamic>> updateGroupLastUsed(String groupId) async {
    try {
      final response = await _dio.patch('/groups/$groupId/last-used');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Utility methods
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
  }
  
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }
  
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
  
  // Error handling
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