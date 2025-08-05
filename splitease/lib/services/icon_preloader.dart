import 'package:flutter/material.dart';

/// Icon preloading service to ensure navigation icons are cached and ready
/// immediately on app startup, preventing any loading delays or placeholders.
class IconPreloader {
  static const String _tag = 'IconPreloader';
  
  /// Set of preloaded icon names to ensure they're cached
  static const Set<String> _navigationIcons = {
    'dashboard',
    'group',
    'groups',
    'person',
    'person_outline',
  };
  
  /// Cache for preloaded icons
  static final Map<String, IconData> _iconCache = {};
  
  /// Flag to track if preloading is complete
  static bool _isPreloaded = false;
  
  /// Preload all navigation icons to ensure immediate availability
  /// This method should be called during app initialization
  static void preloadNavigationIcons() {
    if (_isPreloaded) return;
    
    try {
      // Preload all navigation icons
      for (final iconName in _navigationIcons) {
        _preloadIcon(iconName);
      }
      
      _isPreloaded = true;
      debugPrint('IconPreloader: Navigation icons preloaded successfully');
    } catch (e) {
      debugPrint('IconPreloader: Error preloading icons: $e');
    }
  }
  
  /// Preload a specific icon by name
  static void _preloadIcon(String iconName) {
    final iconData = _getIconData(iconName);
    if (iconData != null) {
      _iconCache[iconName] = iconData;
    }
  }
  
  /// Get icon data for a specific icon name
  static IconData? _getIconData(String iconName) {
    // Map of available icons (subset of CustomIconWidget map)
    final Map<String, IconData> iconMap = {
      'dashboard': Icons.dashboard,
      'group': Icons.group,
      'groups': Icons.groups,
      'person': Icons.person,
      'person_outline': Icons.person_outline,
    };
    
    return iconMap[iconName];
  }
  
  /// Check if an icon is preloaded
  static bool isIconPreloaded(String iconName) {
    return _iconCache.containsKey(iconName);
  }
  
  /// Get a preloaded icon
  static IconData? getPreloadedIcon(String iconName) {
    return _iconCache[iconName];
  }
  
  /// Check if all navigation icons are preloaded
  static bool get isNavigationIconsPreloaded => _isPreloaded;
  
  /// Get the number of preloaded icons
  static int get preloadedIconCount => _iconCache.length;
  
  /// Clear the icon cache (useful for testing)
  static void clearCache() {
    _iconCache.clear();
    _isPreloaded = false;
  }
  
  /// Get a list of all preloaded icon names
  static List<String> get preloadedIconNames => _iconCache.keys.toList();
  
  /// Verify that all required navigation icons are available
  static bool verifyNavigationIcons() {
    final missingIcons = <String>[];
    
    for (final iconName in _navigationIcons) {
      if (!_iconCache.containsKey(iconName)) {
        missingIcons.add(iconName);
      }
    }
    
    if (missingIcons.isNotEmpty) {
      debugPrint('IconPreloader: Missing icons: $missingIcons');
      return false;
    }
    
    return true;
  }
  
  /// Get a status report of the preloading state
  static String getStatusReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Icon Preloader Status ===');
    buffer.writeln('Preloading Complete: $_isPreloaded');
    buffer.writeln('Preloaded Icons: ${_iconCache.length}');
    buffer.writeln('Required Icons: ${_navigationIcons.length}');
    buffer.writeln('Navigation Icons Verified: ${verifyNavigationIcons()}');
    buffer.writeln();
    
    buffer.writeln('Preloaded Icons:');
    for (final iconName in _iconCache.keys) {
      buffer.writeln('  - $iconName');
    }
    
    return buffer.toString();
  }
} 