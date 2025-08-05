import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';
import 'group_service.dart';
import 'group_detail_service.dart';
import 'expense_detail_service.dart';
import 'profile_image_service.dart';
import 'icon_preloader.dart';
import '../utils/real_time_updates.dart';

/// Service responsible for clearing all user-related cache data
/// This ensures no sensitive data persists between user sessions
class CacheClearerService {
  /// Clear all user-related cache data
  /// This should be called during logout to ensure data privacy
  static Future<void> clearAllUserCache() async {
    try {
      print('Clearing all user cache data...');
      
      // Clear user service cache (includes in-memory and persistent cache)
      await UserService.clearCache();
      
      // Clear other service caches
      GroupService.clearCache();
      GroupDetailService.clearCache();
      ExpenseDetailService.clearCache();
      await ProfileImageService.clearCache();
      IconPreloader.clearCache();
      RealTimeUpdates.clearCachedGroupData();
      
      // Clear any additional SharedPreferences keys that might contain user data
      await _clearAdditionalUserData();
      
      print('All user cache data cleared successfully');
    } catch (e) {
      print('Error clearing user cache data: $e');
      // Continue with logout even if cache clearing fails
    }
  }
  
  /// Clear additional user-related data from SharedPreferences
  /// This catches any other cached data that might not be handled by services
  static Future<void> _clearAdditionalUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // List of potential user-related cache keys to clear
      final userRelatedKeys = [
        'cached_user_data',
        'user_cache_timestamp',
        'user_preferences',
        'user_settings',
        'last_sync_timestamp',
        'offline_data',
        'pending_actions',
        'user_notifications',
        'user_activity_log',
        'recent_searches',
        'favorite_items',
        'user_analytics',
      ];
      
      // Clear each key if it exists
      for (final key in userRelatedKeys) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
          print('Cleared cache key: $key');
        }
      }
      
      // Clear any keys that start with user-related prefixes
      final allKeys = prefs.getKeys();
      final keysToRemove = <String>[];
      
      for (final key in allKeys) {
        if (key.startsWith('user_') || 
            key.startsWith('cached_') || 
            key.startsWith('temp_') ||
            key.contains('user') ||
            key.contains('profile') ||
            key.contains('preference')) {
          keysToRemove.add(key);
        }
      }
      
      for (final key in keysToRemove) {
        await prefs.remove(key);
        print('Cleared additional cache key: $key');
      }
      
    } catch (e) {
      print('Error clearing additional user data: $e');
    }
  }
  
  /// Clear only authentication-related data (for partial logout scenarios)
  static Future<void> clearAuthDataOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      print('Authentication data cleared');
    } catch (e) {
      print('Error clearing authentication data: $e');
    }
  }
  
  /// Clear cache for a specific user ID (for multi-user scenarios)
  static Future<void> clearCacheForUser(String userId) async {
    try {
      // For now, clear all cache since we don't have user-specific caching
      // In the future, this could be enhanced to clear only specific user data
      await clearAllUserCache();
      print('Cache cleared for user: $userId');
    } catch (e) {
      print('Error clearing cache for user $userId: $e');
    }
  }
} 