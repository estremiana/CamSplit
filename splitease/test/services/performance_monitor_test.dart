import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/services/performance_monitor.dart';

void main() {
  group('PerformanceMonitor Tests', () {
    setUp(() {
      // Clear any existing performance data before each test
      PerformanceMonitor.clearPerformanceData();
      PerformanceMonitor.stopMonitoring();
    });

    tearDown(() {
      // Clean up after each test
      PerformanceMonitor.stopMonitoring();
      PerformanceMonitor.clearPerformanceData();
    });

    group('Monitoring Control', () {
      test('should start and stop monitoring correctly', () {
        expect(PerformanceMonitor.getPerformanceStats().animationStats, isEmpty);
        
        PerformanceMonitor.startMonitoring();
        PerformanceMonitor.recordAnimationDuration('test', const Duration(milliseconds: 100));
        
        final stats = PerformanceMonitor.getPerformanceStats();
        expect(stats.animationStats['test'], isNotNull);
        
        PerformanceMonitor.stopMonitoring();
        PerformanceMonitor.clearPerformanceData();
        
        final clearedStats = PerformanceMonitor.getPerformanceStats();
        expect(clearedStats.animationStats, isEmpty);
      });

      test('should not record data when monitoring is stopped', () {
        PerformanceMonitor.stopMonitoring();
        
        PerformanceMonitor.recordAnimationDuration('test', const Duration(milliseconds: 100));
        PerformanceMonitor.recordNavigationLatency(const Duration(milliseconds: 50));
        
        final stats = PerformanceMonitor.getPerformanceStats();
        expect(stats.animationStats, isEmpty);
        expect(stats.navigationLatency, isNull);
      });
    });

    group('Animation Duration Recording', () {
      test('should record animation durations correctly', () {
        PerformanceMonitor.startMonitoring();
        
        PerformanceMonitor.recordAnimationDuration('page_transition', const Duration(milliseconds: 300));
        PerformanceMonitor.recordAnimationDuration('page_transition', const Duration(milliseconds: 250));
        PerformanceMonitor.recordAnimationDuration('page_transition', const Duration(milliseconds: 350));
        
        final stats = PerformanceMonitor.getPerformanceStats();
        final animationStat = stats.animationStats['page_transition'];
        
        expect(animationStat, isNotNull);
        expect(animationStat!.sampleCount, equals(3));
        expect(animationStat.averageDuration.inMilliseconds, equals(300));
        expect(animationStat.maxDuration.inMilliseconds, equals(350));
        expect(animationStat.minDuration.inMilliseconds, equals(250));
      });

      test('should handle multiple animation types', () {
        PerformanceMonitor.startMonitoring();
        
        PerformanceMonitor.recordAnimationDuration('page_transition', const Duration(milliseconds: 300));
        PerformanceMonitor.recordAnimationDuration('swipe_gesture', const Duration(milliseconds: 150));
        PerformanceMonitor.recordAnimationDuration('button_tap', const Duration(milliseconds: 50));
        
        final stats = PerformanceMonitor.getPerformanceStats();
        
        expect(stats.animationStats.length, equals(3));
        expect(stats.animationStats['page_transition'], isNotNull);
        expect(stats.animationStats['swipe_gesture'], isNotNull);
        expect(stats.animationStats['button_tap'], isNotNull);
      });

      test('should limit animation duration samples to prevent memory buildup', () {
        PerformanceMonitor.startMonitoring();
        
        // Add more than 100 samples
        for (int i = 0; i < 150; i++) {
          PerformanceMonitor.recordAnimationDuration('test', Duration(milliseconds: i));
        }
        
        final stats = PerformanceMonitor.getPerformanceStats();
        final animationStat = stats.animationStats['test'];
        
        expect(animationStat, isNotNull);
        expect(animationStat!.sampleCount, equals(100)); // Should be limited to 100
      });
    });

    group('Navigation Latency Recording', () {
      test('should record navigation latency correctly', () {
        PerformanceMonitor.startMonitoring();
        
        PerformanceMonitor.recordNavigationLatency(const Duration(milliseconds: 10));
        PerformanceMonitor.recordNavigationLatency(const Duration(milliseconds: 15));
        PerformanceMonitor.recordNavigationLatency(const Duration(milliseconds: 8));
        
        final stats = PerformanceMonitor.getPerformanceStats();
        final latency = stats.navigationLatency;
        
        expect(latency, isNotNull);
        expect(latency!.sampleCount, equals(3));
        expect(latency.averageLatency.inMilliseconds, equals(11));
        expect(latency.maximumLatency.inMilliseconds, equals(15));
      });

      test('should limit navigation latency samples to prevent memory buildup', () {
        PerformanceMonitor.startMonitoring();
        
        // Add more than 50 samples
        for (int i = 0; i < 75; i++) {
          PerformanceMonitor.recordNavigationLatency(Duration(milliseconds: i));
        }
        
        final stats = PerformanceMonitor.getPerformanceStats();
        final latency = stats.navigationLatency;
        
        expect(latency, isNotNull);
        expect(latency!.sampleCount, equals(50)); // Should be limited to 50
      });
    });

    group('Performance Acceptance', () {
      test('should return true for acceptable performance', () {
        PerformanceMonitor.startMonitoring();
        
        // Add acceptable performance data
        PerformanceMonitor.recordAnimationDuration('page_transition', const Duration(milliseconds: 300));
        PerformanceMonitor.recordAnimationDuration('page_transition', const Duration(milliseconds: 250));
        
        expect(PerformanceMonitor.isPerformanceAcceptable(), isTrue);
      });

      test('should return false for unacceptable animation duration', () {
        PerformanceMonitor.startMonitoring();
        
        // Add unacceptable animation duration (over 400ms)
        PerformanceMonitor.recordAnimationDuration('page_transition', const Duration(milliseconds: 450));
        
        expect(PerformanceMonitor.isPerformanceAcceptable(), isFalse);
      });

      test('should handle empty performance data', () {
        PerformanceMonitor.startMonitoring();
        
        // No performance data recorded
        expect(PerformanceMonitor.isPerformanceAcceptable(), isTrue);
      });
    });

    group('Performance Report', () {
      test('should generate comprehensive performance report', () {
        PerformanceMonitor.startMonitoring();
        
        // Add some test data
        PerformanceMonitor.recordAnimationDuration('page_transition', const Duration(milliseconds: 300));
        PerformanceMonitor.recordAnimationDuration('swipe_gesture', const Duration(milliseconds: 150));
        PerformanceMonitor.recordNavigationLatency(const Duration(milliseconds: 10));
        
        final report = PerformanceMonitor.getPerformanceReport();
        
        expect(report, contains('=== Performance Report ==='));
        expect(report, contains('Monitoring Active: true'));
        expect(report, contains('Performance Acceptable: true'));
        expect(report, contains('Animation Statistics:'));
        expect(report, contains('Frame Rate Statistics:'));
        expect(report, contains('Navigation Latency:'));
        expect(report, contains('page_transition:'));
        expect(report, contains('swipe_gesture:'));
        expect(report, contains('Average: 300ms'));
        expect(report, contains('Average: 150ms'));
        expect(report, contains('Average: 10ms'));
      });

      test('should handle empty report gracefully', () {
        PerformanceMonitor.startMonitoring();
        
        final report = PerformanceMonitor.getPerformanceReport();
        
        expect(report, contains('=== Performance Report ==='));
        expect(report, contains('Monitoring Active: true'));
        expect(report, contains('Performance Acceptable: true'));
        expect(report, contains('Animation Statistics:'));
        expect(report, contains('Frame Rate Statistics:'));
        expect(report, contains('Navigation Latency:'));
      });
    });

    group('Data Management', () {
      test('should clear performance data correctly', () {
        PerformanceMonitor.startMonitoring();
        
        // Add some data
        PerformanceMonitor.recordAnimationDuration('test', const Duration(milliseconds: 100));
        PerformanceMonitor.recordNavigationLatency(const Duration(milliseconds: 50));
        
        // Verify data exists
        final statsBefore = PerformanceMonitor.getPerformanceStats();
        expect(statsBefore.animationStats, isNotEmpty);
        expect(statsBefore.navigationLatency, isNotNull);
        
        // Clear data
        PerformanceMonitor.clearPerformanceData();
        
        // Verify data is cleared
        final statsAfter = PerformanceMonitor.getPerformanceStats();
        expect(statsAfter.animationStats, isEmpty);
        expect(statsAfter.navigationLatency, isNull);
      });

      test('should handle multiple clear operations', () {
        PerformanceMonitor.startMonitoring();
        
        PerformanceMonitor.recordAnimationDuration('test', const Duration(milliseconds: 100));
        PerformanceMonitor.clearPerformanceData();
        PerformanceMonitor.clearPerformanceData(); // Second clear should not cause issues
        
        final stats = PerformanceMonitor.getPerformanceStats();
        expect(stats.animationStats, isEmpty);
      });
    });

    group('Edge Cases', () {
      test('should handle zero duration animations', () {
        PerformanceMonitor.startMonitoring();
        
        PerformanceMonitor.recordAnimationDuration('instant', Duration.zero);
        
        final stats = PerformanceMonitor.getPerformanceStats();
        final animationStat = stats.animationStats['instant'];
        
        expect(animationStat, isNotNull);
        expect(animationStat!.averageDuration, equals(Duration.zero));
        expect(animationStat.maxDuration, equals(Duration.zero));
        expect(animationStat.minDuration, equals(Duration.zero));
      });

      test('should handle very long duration animations', () {
        PerformanceMonitor.startMonitoring();
        
        PerformanceMonitor.recordAnimationDuration('long_animation', const Duration(seconds: 5));
        
        final stats = PerformanceMonitor.getPerformanceStats();
        final animationStat = stats.animationStats['long_animation'];
        
        expect(animationStat, isNotNull);
        expect(animationStat!.averageDuration.inSeconds, equals(5));
        expect(PerformanceMonitor.isPerformanceAcceptable(), isFalse);
      });

      test('should handle negative durations gracefully', () {
        PerformanceMonitor.startMonitoring();
        
        // This should not crash the system
        PerformanceMonitor.recordAnimationDuration('negative', const Duration(milliseconds: -100));
        
        final stats = PerformanceMonitor.getPerformanceStats();
        expect(stats.animationStats['negative'], isNotNull);
      });
    });
  });
} 