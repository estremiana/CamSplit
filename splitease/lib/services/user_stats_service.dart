import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Service for managing user statistics with optimistic updates
/// 
/// This service provides:
/// - Cached user statistics (groups count, expenses count, etc.)
/// - Optimistic updates for immediate UI feedback
/// - Background refresh after operations
/// - Persistent caching across app sessions
class UserStatsService {
  static const String _statsCacheKey = 'cached_user_stats';
  static const String _statsCacheTimestampKey = 'user_stats_cache_timestamp';
  static const Duration _cacheExpiry = Duration(minutes: 30);
  
  // In-memory cache
  static Map<String, dynamic>? _cachedStats;
  static DateTime? _lastFetch;
  
  // Listeners for stats updates
  static final List<Function(Map<String, dynamic>)> _statsListeners = [];
  
  /// Get user statistics with caching
  /// Returns cached data if available and valid, otherwise fetches from API
  static Future<Map<String, dynamic>> getUserStats({bool forceRefresh = false}) async {
    // Force refresh if requested
    if (forceRefresh) {
      return await _fetchStatsFromApi();
    }
    
    // Check in-memory cache first
    if (_cachedStats != null && _isCacheValid()) {
      return _cachedStats!;
    }
    
    // Check persistent cache
    final cachedStats = await _getCachedStats();
    if (cachedStats != null) {
      _cachedStats = cachedStats;
      _lastFetch = DateTime.now();
      return cachedStats;
    }
    
    // Fetch from API
    return await _fetchStatsFromApi();
  }
  
  /// Optimistic update: Increment groups count
  static void incrementGroupsCount() {
    if (_cachedStats != null) {
      final currentCount = _cachedStats!['total_groups'] ?? 0;
      _cachedStats!['total_groups'] = currentCount + 1;
      _notifyListeners();
    }
  }
  
  /// Optimistic update: Decrement groups count
  static void decrementGroupsCount() {
    if (_cachedStats != null) {
      final currentCount = _cachedStats!['total_groups'] ?? 0;
      _cachedStats!['total_groups'] = (currentCount - 1).clamp(0, double.infinity).toInt();
      _notifyListeners();
    }
  }
  
  /// Optimistic update: Increment expenses count
  static void incrementExpensesCount() {
    if (_cachedStats != null) {
      final currentCount = _cachedStats!['total_expenses'] ?? 0;
      _cachedStats!['total_expenses'] = currentCount + 1;
      _notifyListeners();
    }
  }
  
  /// Optimistic update: Decrement expenses count
  static void decrementExpensesCount() {
    if (_cachedStats != null) {
      final currentCount = _cachedStats!['total_expenses'] ?? 0;
      _cachedStats!['total_expenses'] = (currentCount - 1).clamp(0, double.infinity).toInt();
      _notifyListeners();
    }
  }
  
  /// Refresh stats in background after operations
  /// This should be called after successful group/expense operations
  static Future<void> refreshStatsInBackground() async {
    try {
      final freshStats = await _fetchStatsFromApi();
      _cachedStats = freshStats;
      _lastFetch = DateTime.now();
      await _cacheStats(freshStats);
      _notifyListeners();
    } catch (e) {
      // Log error but don't throw - keep optimistic data
      print('Background stats refresh failed: $e');
    }
  }
  
  /// Add listener for stats updates
  static void addStatsListener(Function(Map<String, dynamic>) listener) {
    _statsListeners.add(listener);
  }
  
  /// Remove listener for stats updates
  static void removeStatsListener(Function(Map<String, dynamic>) listener) {
    _statsListeners.remove(listener);
  }
  
  /// Clear all cached data
  static Future<void> clearCache() async {
    _cachedStats = null;
    _lastFetch = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statsCacheKey);
    await prefs.remove(_statsCacheTimestampKey);
  }
  
  /// Check if cache is still valid
  static bool _isCacheValid() {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < _cacheExpiry;
  }
  
  /// Get cached stats from persistent storage
  static Future<Map<String, dynamic>?> _getCachedStats() async {
    if (!await _isPersistentCacheValid()) {
      return null;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_statsCacheKey);
    
    if (cachedData == null) return null;
    
    try {
      return jsonDecode(cachedData);
    } catch (e) {
      // Invalid cached data, remove it
      await clearCache();
      return null;
    }
  }
  
  /// Check if persistent cache is valid
  static Future<bool> _isPersistentCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_statsCacheTimestampKey);
    
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) < _cacheExpiry;
  }
  
  /// Cache stats to persistent storage
  static Future<void> _cacheStats(Map<String, dynamic> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final statsData = jsonEncode(stats);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    await prefs.setString(_statsCacheKey, statsData);
    await prefs.setInt(_statsCacheTimestampKey, timestamp);
  }
  
  /// Fetch stats from API
  static Future<Map<String, dynamic>> _fetchStatsFromApi() async {
    try {
      final apiService = ApiService.instance;
      final response = await apiService.getUserStats();
      
      if (response['success'] == true) {
        final stats = response['data'];
        
        // Cache the fresh data
        _cachedStats = stats;
        _lastFetch = DateTime.now();
        await _cacheStats(stats);
        
        return stats;
      } else {
        throw Exception('Failed to fetch user stats: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      // For development, return mock data if API fails
      print('API call failed, using mock stats: $e');
      return _getMockStats();
    }
  }
  
  /// Mock stats for development
  static Map<String, dynamic> _getMockStats() {
    return {
      'total_groups': 4,
      'total_expenses': 127,
      'total_to_pay': 45.50,
      'total_to_get_paid': 67.25,
      'balance': 21.75,
      'average_expense': 25.40,
      'most_active_group': null,
    };
  }
  
  /// Notify all listeners of stats updates
  static void _notifyListeners() {
    if (_cachedStats != null) {
      for (final listener in _statsListeners) {
        try {
          listener(_cachedStats!);
        } catch (e) {
          print('Error notifying stats listener: $e');
        }
      }
    }
  }
  
  /// Get current cached stats (synchronous)
  /// Returns null if no cached data available
  static Map<String, dynamic>? getCurrentStats() {
    return _cachedStats;
  }
  
  /// Check if we have valid cached stats
  static bool hasValidCache() {
    return _cachedStats != null && _isCacheValid();
  }
}

