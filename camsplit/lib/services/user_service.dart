import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'currency_migration_service.dart';

class UserService {
  static const String _userCacheKey = 'cached_user_data';
  static const String _userCacheTimestampKey = 'user_cache_timestamp';
  static const Duration _cacheValidDuration = Duration(hours: 24);
  
  static UserModel? _cachedUser;
  
  /// Get user data with caching
  /// Returns cached data if available and valid, otherwise fetches from API
  static Future<UserModel> getCurrentUser() async {
    // Get current authenticated user ID
    final apiService = ApiService.instance;
    final currentUserId = await apiService.getUserId();
    
    // If no user is authenticated, clear cache and throw error
    if (currentUserId == null) {
      await clearCache();
      throw Exception('No authenticated user found');
    }
    
    // Return in-memory cache if available and belongs to current user
    if (_cachedUser != null) {
      // Validate that cached user matches current authenticated user
      if (_cachedUser!.id.toString() == currentUserId) {
        return _cachedUser!;
      } else {
        // Cached user doesn't match current user, clear cache
        print('Cached user (${_cachedUser!.id}) doesn\'t match current user ($currentUserId), clearing cache');
        await clearCache();
      }
    }
    
    // Check persistent cache
    final cachedUser = await _getCachedUser();
    if (cachedUser != null) {
      // Validate that cached user matches current authenticated user
      if (cachedUser.id.toString() == currentUserId) {
        _cachedUser = cachedUser;
        return cachedUser;
      } else {
        // Cached user doesn't match current user, clear cache
        print('Persistent cached user (${cachedUser.id}) doesn\'t match current user ($currentUserId), clearing cache');
        await clearCache();
      }
    }
    
    // Fetch from API and cache
    final user = await _fetchUserFromApi();
    await _cacheUser(user);
    _cachedUser = user;
    
    return user;
  }
  
  /// Force refresh user data from API
  static Future<UserModel> refreshUser() async {
    final user = await _fetchUserFromApi();
    await _cacheUser(user);
    _cachedUser = user;
    return user;
  }

  /// Get user by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      final apiService = ApiService.instance;
      final response = await apiService.getUserById(userId);
      
      if (response['success'] == true) {
        return UserModel.fromJson(response['data']);
      } else {
        return null;
      }
    } catch (e) {
      print('Failed to get user by ID $userId: $e');
      return null;
    }
  }
  
  /// Update user data and refresh cache
  static Future<UserModel> updateUser(Map<String, dynamic> updates) async {
    try {
      final apiService = ApiService.instance;
      final response = await apiService.updateProfile(updates);
      
      if (response['success'] == true) {
        final user = UserModel.fromJson(response['data']);
        await _cacheUser(user);
        _cachedUser = user;
        return user;
      } else {
        throw Exception('Failed to update user: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Update user profile with separate fields
  static Future<UserModel> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? avatar,
    String? timezone,
    Map<String, dynamic>? preferences,
  }) async {
    final updates = <String, dynamic>{};
    
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (phone != null) updates['phone'] = phone;
    if (bio != null) updates['bio'] = bio;
    if (avatar != null) updates['avatar'] = avatar;
    if (timezone != null) updates['timezone'] = timezone;
    if (preferences != null) updates['preferences'] = preferences;
    
    return updateUser(updates);
  }
  
  /// Clear user cache
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userCacheKey);
    await prefs.remove(_userCacheTimestampKey);
    _cachedUser = null;
  }
  
  /// Check if cached data is still valid
  static Future<bool> _isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_userCacheTimestampKey);
    
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    return now.difference(cacheTime) < _cacheValidDuration;
  }
  
  /// Get cached user data if valid
  static Future<UserModel?> _getCachedUser() async {
    if (!await _isCacheValid()) {
      return null;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_userCacheKey);
    
    if (cachedData == null) return null;
    
    try {
      final userData = jsonDecode(cachedData);
      return UserModel.fromJson(userData);
    } catch (e) {
      // Invalid cached data, remove it
      await clearCache();
      return null;
    }
  }
  
  /// Cache user data
  static Future<void> _cacheUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = jsonEncode(user.toJson());
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    await prefs.setString(_userCacheKey, userData);
    await prefs.setInt(_userCacheTimestampKey, timestamp);
  }
  
  /// Fetch user data from API
  static Future<UserModel> _fetchUserFromApi() async {
    try {
      final apiService = ApiService.instance;
      final response = await apiService.getProfile();
      
      if (response['success'] == true) {
        return UserModel.fromJson(response['data']);
      } else {
        throw Exception('Failed to fetch user: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      // For development, return mock user data
      print('API call failed, using mock user data: $e');
      return _getMockUser();
    }
  }
  
  /// Mock user data for development
  static UserModel _getMockUser() {
    return UserModel(
      id: '1',
      name: 'John Doe',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      avatar: 'https://ui-avatars.com/api/?name=John+Doe&background=4F46E5&color=fff',
      phone: '+1 (555) 123-4567',
      bio: 'Expense sharing made simple',
      birthdate: DateTime(1990, 5, 15),
      timezone: 'UTC-5',
      memberSince: DateTime(2023, 1, 15),
      isEmailVerified: true,
      preferences: UserPreferences(
        currency: CurrencyMigrationService.parseFromBackend('USD'),
        language: 'en',
        notifications: true,
        emailNotifications: true,
        darkMode: false,
        biometricAuth: true,
        autoSync: true,
      ),
      createdAt: DateTime(2023, 1, 15),
      updatedAt: DateTime.now(),
    );
  }
}