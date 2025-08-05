import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Performance monitoring service for tracking animation performance
/// and ensuring 60fps during page transitions
class PerformanceMonitor {
  static const String _tag = 'PerformanceMonitor';
  
  /// Frame rate monitoring
  static const int _targetFrameRate = 60;
  static const Duration _frameRateCheckInterval = Duration(milliseconds: 1000);
  
  /// Performance metrics
  static final Map<String, List<Duration>> _animationDurations = {};
  static final Map<String, List<int>> _frameRates = {};
  static final List<Duration> _navigationLatencies = [];
  
  /// Monitoring state
  static bool _isMonitoring = false;
  static Timer? _frameRateTimer;
  static int _frameCount = 0;
  static DateTime? _lastFrameTime;
  
  /// Performance thresholds
  static const Duration _maxAnimationDuration = Duration(milliseconds: 400);
  static const int _minAcceptableFrameRate = 55; // Allow small deviation from 60fps
  
  /// Start monitoring performance metrics
  static void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _startFrameRateMonitoring();
    
    if (kDebugMode) {
      developer.log('Performance monitoring started', name: _tag);
    }
  }
  
  /// Stop monitoring performance metrics
  static void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _frameRateTimer?.cancel();
    _frameRateTimer = null;
    
    if (kDebugMode) {
      developer.log('Performance monitoring stopped', name: _tag);
    }
  }
  
  /// Record animation duration for a specific animation type
  static void recordAnimationDuration(String animationType, Duration duration) {
    if (!_isMonitoring) return;
    
    _animationDurations.putIfAbsent(animationType, () => []).add(duration);
    
    // Keep only last 100 measurements to prevent memory buildup
    final durations = _animationDurations[animationType]!;
    if (durations.length > 100) {
      durations.removeRange(0, durations.length - 100);
    }
    
    // Log performance warnings
    if (duration > _maxAnimationDuration) {
      developer.log(
        'Animation duration exceeded threshold: $animationType took ${duration.inMilliseconds}ms',
        name: _tag,
        level: 900, // Warning level
      );
    }
  }
  
  /// Record navigation latency
  static void recordNavigationLatency(Duration latency) {
    if (!_isMonitoring) return;
    
    _navigationLatencies.add(latency);
    
    // Keep only last 50 measurements
    if (_navigationLatencies.length > 50) {
      _navigationLatencies.removeRange(0, _navigationLatencies.length - 50);
    }
  }
  
  /// Get performance statistics
  static PerformanceStats getPerformanceStats() {
    final stats = PerformanceStats();
    
    // Calculate animation duration statistics
    for (final entry in _animationDurations.entries) {
      final durations = entry.value;
      if (durations.isNotEmpty) {
        final totalDuration = durations.reduce((a, b) => a + b);
        final avgDuration = Duration(microseconds: totalDuration.inMicroseconds ~/ durations.length);
        final maxDuration = durations.reduce((a, b) => a > b ? a : b);
        final minDuration = durations.reduce((a, b) => a < b ? a : b);
        
        stats.animationStats[entry.key] = AnimationStats(
          averageDuration: avgDuration,
          maxDuration: maxDuration,
          minDuration: minDuration,
          sampleCount: durations.length,
        );
      }
    }
    
    // Calculate frame rate statistics
    for (final entry in _frameRates.entries) {
      final rates = entry.value;
      if (rates.isNotEmpty) {
        final avgRate = rates.reduce((a, b) => a + b) / rates.length;
        final minRate = rates.reduce((a, b) => a < b ? a : b);
        
        stats.frameRateStats[entry.key] = FrameRateStats(
          averageFrameRate: avgRate,
          minimumFrameRate: minRate,
          sampleCount: rates.length,
        );
      }
    }
    
    // Calculate navigation latency statistics
    if (_navigationLatencies.isNotEmpty) {
      final totalLatency = _navigationLatencies.reduce((a, b) => a + b);
      final avgLatency = Duration(microseconds: totalLatency.inMicroseconds ~/ _navigationLatencies.length);
      final maxLatency = _navigationLatencies.reduce((a, b) => a > b ? a : b);
      
      stats.navigationLatency = NavigationLatencyStats(
        averageLatency: avgLatency,
        maximumLatency: maxLatency,
        sampleCount: _navigationLatencies.length,
      );
    }
    
    return stats;
  }
  
  /// Check if performance meets requirements
  static bool isPerformanceAcceptable() {
    final stats = getPerformanceStats();
    
    // Check frame rates
    for (final frameRateStat in stats.frameRateStats.values) {
      if (frameRateStat.averageFrameRate < _minAcceptableFrameRate) {
        return false;
      }
    }
    
    // Check animation durations
    for (final animationStat in stats.animationStats.values) {
      if (animationStat.averageDuration > _maxAnimationDuration) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Start frame rate monitoring
  static void _startFrameRateMonitoring() {
    _frameRateTimer = Timer.periodic(_frameRateCheckInterval, (timer) {
      if (!_isMonitoring) {
        timer.cancel();
        return;
      }
      
      _recordFrameRate();
    });
    
    // Listen to frame callbacks for more accurate frame rate measurement
    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      if (!_isMonitoring) return;
      
      _frameCount++;
      _lastFrameTime = DateTime.now();
    });
  }
  
  /// Record current frame rate
  static void _recordFrameRate() {
    if (_frameCount == 0) return;
    
    final currentTime = DateTime.now();
    final frameRate = _frameCount; // Frames per second (since interval is 1 second)
    
    _frameRates.putIfAbsent('navigation', () => []).add(frameRate);
    
    // Keep only last 60 measurements (1 minute of data)
    final rates = _frameRates['navigation']!;
    if (rates.length > 60) {
      rates.removeRange(0, rates.length - 60);
    }
    
    // Log frame rate warnings
    if (frameRate < _minAcceptableFrameRate) {
      developer.log(
        'Frame rate below acceptable threshold: ${frameRate}fps',
        name: _tag,
        level: 900, // Warning level
      );
    }
    
    // Reset frame count for next measurement
    _frameCount = 0;
  }
  
  /// Clear all performance data
  static void clearPerformanceData() {
    _animationDurations.clear();
    _frameRates.clear();
    _navigationLatencies.clear();
  }
  
  /// Get a performance report for debugging
  static String getPerformanceReport() {
    final stats = getPerformanceStats();
    final buffer = StringBuffer();
    
    buffer.writeln('=== Performance Report ===');
    buffer.writeln('Monitoring Active: $_isMonitoring');
    buffer.writeln('Performance Acceptable: ${isPerformanceAcceptable()}');
    buffer.writeln();
    
    // Animation statistics
    buffer.writeln('Animation Statistics:');
    for (final entry in stats.animationStats.entries) {
      final stat = entry.value;
      buffer.writeln('  ${entry.key}:');
      buffer.writeln('    Average: ${stat.averageDuration.inMilliseconds}ms');
      buffer.writeln('    Max: ${stat.maxDuration.inMilliseconds}ms');
      buffer.writeln('    Min: ${stat.minDuration.inMilliseconds}ms');
      buffer.writeln('    Samples: ${stat.sampleCount}');
    }
    buffer.writeln();
    
    // Frame rate statistics
    buffer.writeln('Frame Rate Statistics:');
    for (final entry in stats.frameRateStats.entries) {
      final stat = entry.value;
      buffer.writeln('  ${entry.key}:');
      buffer.writeln('    Average: ${stat.averageFrameRate.toStringAsFixed(1)}fps');
      buffer.writeln('    Minimum: ${stat.minimumFrameRate}fps');
      buffer.writeln('    Samples: ${stat.sampleCount}');
    }
    buffer.writeln();
    
    // Navigation latency statistics
    if (stats.navigationLatency != null) {
      final latency = stats.navigationLatency!;
      buffer.writeln('Navigation Latency:');
      buffer.writeln('  Average: ${latency.averageLatency.inMilliseconds}ms');
      buffer.writeln('  Maximum: ${latency.maximumLatency.inMilliseconds}ms');
      buffer.writeln('  Samples: ${latency.sampleCount}');
    }
    
    return buffer.toString();
  }
}

/// Performance statistics data classes
class PerformanceStats {
  final Map<String, AnimationStats> animationStats = {};
  final Map<String, FrameRateStats> frameRateStats = {};
  NavigationLatencyStats? navigationLatency;
}

class AnimationStats {
  final Duration averageDuration;
  final Duration maxDuration;
  final Duration minDuration;
  final int sampleCount;
  
  AnimationStats({
    required this.averageDuration,
    required this.maxDuration,
    required this.minDuration,
    required this.sampleCount,
  });
}

class FrameRateStats {
  final double averageFrameRate;
  final int minimumFrameRate;
  final int sampleCount;
  
  FrameRateStats({
    required this.averageFrameRate,
    required this.minimumFrameRate,
    required this.sampleCount,
  });
}

class NavigationLatencyStats {
  final Duration averageLatency;
  final Duration maximumLatency;
  final int sampleCount;
  
  NavigationLatencyStats({
    required this.averageLatency,
    required this.maximumLatency,
    required this.sampleCount,
  });
} 