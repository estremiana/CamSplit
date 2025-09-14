import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/performance_optimizer.dart';

void main() {
  group('PerformanceOptimizer Tests', () {
    setUp(() {
      // Initialize the optimizer for each test
      PerformanceOptimizer.initialize();
    });

    tearDown(() {
      // Clean up after each test
      PerformanceOptimizer.dispose();
    });

    test('should initialize correctly', () {
      // Test that initialization works without errors
      expect(() => PerformanceOptimizer.initialize(), returnsNormally);
      
      // Test that optimization is enabled by default
      expect(PerformanceOptimizer.isOptimizationEnabled, isTrue);
    });

    test('should enable and disable optimization', () {
      // Test enabling optimization
      PerformanceOptimizer.setOptimizationEnabled(true);
      expect(PerformanceOptimizer.isOptimizationEnabled, isTrue);
      
      // Test disabling optimization
      PerformanceOptimizer.setOptimizationEnabled(false);
      expect(PerformanceOptimizer.isOptimizationEnabled, isFalse);
      
      // Test re-enabling optimization
      PerformanceOptimizer.setOptimizationEnabled(true);
      expect(PerformanceOptimizer.isOptimizationEnabled, isTrue);
    });

    test('should record frame rate data', () {
      // Record various frame rates
      PerformanceOptimizer.recordFrameRate(60.0);
      PerformanceOptimizer.recordFrameRate(55.0);
      PerformanceOptimizer.recordFrameRate(50.0);
      PerformanceOptimizer.recordFrameRate(45.0);
      
      // Get performance stats
      final stats = PerformanceOptimizer.getPerformanceStats();
      final frameRateStats = stats['frameRate'];
      
      // Verify frame rate data is recorded
      expect(frameRateStats['samples'], equals(4));
      expect(frameRateStats['current'], equals(45.0));
      expect(frameRateStats['average'], equals(52.5));
      expect(frameRateStats['min'], equals(45.0));
    });

    test('should record animation duration data', () {
      // Record various animation durations
      PerformanceOptimizer.recordAnimationDuration(300);
      PerformanceOptimizer.recordAnimationDuration(350);
      PerformanceOptimizer.recordAnimationDuration(400);
      PerformanceOptimizer.recordAnimationDuration(450);
      
      // Get performance stats
      final stats = PerformanceOptimizer.getPerformanceStats();
      final animationStats = stats['animationDuration'];
      
      // Verify animation duration data is recorded
      expect(animationStats['samples'], equals(4));
      expect(animationStats['current'], equals(450));
      expect(animationStats['average'], equals(375.0));
      expect(animationStats['max'], equals(450));
    });

    test('should provide memory statistics', () {
      // Get memory stats (simulated)
      final memoryStats = PerformanceOptimizer.getMemoryStats();
      
      // Verify memory stats structure
      expect(memoryStats, contains('current'));
      expect(memoryStats, contains('average'));
      expect(memoryStats, contains('max'));
      expect(memoryStats, contains('min'));
      expect(memoryStats, contains('samples'));
      
      // Verify all values are numbers
      expect(memoryStats['current'], isA<double>());
      expect(memoryStats['average'], isA<double>());
      expect(memoryStats['max'], isA<double>());
      expect(memoryStats['min'], isA<double>());
      expect(memoryStats['samples'], isA<int>());
    });

    test('should provide performance statistics', () {
      // Record some test data
      PerformanceOptimizer.recordFrameRate(60.0);
      PerformanceOptimizer.recordAnimationDuration(300);
      
      // Get performance stats
      final stats = PerformanceOptimizer.getPerformanceStats();
      
      // Verify stats structure
      expect(stats, contains('frameRate'));
      expect(stats, contains('animationDuration'));
      expect(stats, contains('isLowEndDeviceMode'));
      expect(stats, contains('isOptimizationEnabled'));
      
      // Verify frame rate stats
      final frameRateStats = stats['frameRate'];
      expect(frameRateStats, contains('current'));
      expect(frameRateStats, contains('average'));
      expect(frameRateStats, contains('min'));
      expect(frameRateStats, contains('samples'));
      
      // Verify animation stats
      final animationStats = stats['animationDuration'];
      expect(animationStats, contains('current'));
      expect(animationStats, contains('average'));
      expect(animationStats, contains('max'));
      expect(animationStats, contains('samples'));
    });

    test('should handle empty data gracefully', () {
      // Dispose and reinitialize to start with empty data
      PerformanceOptimizer.dispose();
      PerformanceOptimizer.initialize();
      
      // Get stats with no data
      final memoryStats = PerformanceOptimizer.getMemoryStats();
      final performanceStats = PerformanceOptimizer.getPerformanceStats();
      
      // Verify empty stats return zero values
      expect(memoryStats['current'], equals(0.0));
      expect(memoryStats['average'], equals(0.0));
      expect(memoryStats['max'], equals(0.0));
      expect(memoryStats['min'], equals(0.0));
      expect(memoryStats['samples'], equals(0));
      
      expect(performanceStats['frameRate']['current'], equals(0.0));
      expect(performanceStats['frameRate']['average'], equals(0.0));
      expect(performanceStats['frameRate']['min'], equals(0.0));
      expect(performanceStats['frameRate']['samples'], equals(0));
      
      expect(performanceStats['animationDuration']['current'], equals(0));
      expect(performanceStats['animationDuration']['average'], equals(0.0));
      expect(performanceStats['animationDuration']['max'], equals(0));
      expect(performanceStats['animationDuration']['samples'], equals(0));
    });

    test('should limit history size to prevent memory leaks', () {
      // Record more data than the max history size
      for (int i = 0; i < 150; i++) {
        PerformanceOptimizer.recordFrameRate(60.0 + (i % 10));
        PerformanceOptimizer.recordAnimationDuration(300 + (i % 50));
      }
      
      // Get stats
      final memoryStats = PerformanceOptimizer.getMemoryStats();
      final performanceStats = PerformanceOptimizer.getPerformanceStats();
      
      // Verify history is limited
      expect(memoryStats['samples'], lessThanOrEqualTo(100));
      expect(performanceStats['frameRate']['samples'], lessThanOrEqualTo(100));
      expect(performanceStats['animationDuration']['samples'], lessThanOrEqualTo(100));
    });

    test('should detect low-end device mode', () {
      // Test that low-end device mode can be detected
      // Note: This is simulated in the current implementation
      final stats = PerformanceOptimizer.getPerformanceStats();
      
      // Verify low-end device mode is tracked
      expect(stats, contains('isLowEndDeviceMode'));
      expect(stats['isLowEndDeviceMode'], isA<bool>());
    });

    test('should provide status report', () {
      // Record some test data
      PerformanceOptimizer.recordFrameRate(60.0);
      PerformanceOptimizer.recordAnimationDuration(300);
      
      // Get status report
      final statusReport = PerformanceOptimizer.getStatusReport();
      
      // Verify status report contains expected sections
      expect(statusReport, contains('Performance Optimizer Status'));
      expect(statusReport, contains('Optimization Enabled'));
      expect(statusReport, contains('Low-End Device Mode'));
      expect(statusReport, contains('Memory Monitoring'));
      expect(statusReport, contains('Memory Statistics'));
      expect(statusReport, contains('Performance Statistics'));
    });

    test('should handle rapid data recording', () {
      // Record data rapidly to test performance
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 1000; i++) {
        PerformanceOptimizer.recordFrameRate(60.0);
        PerformanceOptimizer.recordAnimationDuration(300);
      }
      
      stopwatch.stop();
      
      // Verify rapid recording doesn't cause performance issues
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast
      
      // Verify data is still recorded correctly
      final stats = PerformanceOptimizer.getPerformanceStats();
      expect(stats['frameRate']['samples'], greaterThan(0));
      expect(stats['animationDuration']['samples'], greaterThan(0));
    });

    test('should handle concurrent access', () {
      // Test concurrent access to the optimizer
      final futures = <Future<void>>[];
      
      for (int i = 0; i < 10; i++) {
        futures.add(Future(() {
          for (int j = 0; j < 100; j++) {
            PerformanceOptimizer.recordFrameRate(60.0);
            PerformanceOptimizer.recordAnimationDuration(300);
          }
        }));
      }
      
      // Wait for all concurrent operations to complete
      return Future.wait(futures).then((_) {
        // Verify data is recorded correctly
        final stats = PerformanceOptimizer.getPerformanceStats();
        expect(stats['frameRate']['samples'], greaterThan(0));
        expect(stats['animationDuration']['samples'], greaterThan(0));
      });
    });

    test('should dispose resources correctly', () {
      // Record some data
      PerformanceOptimizer.recordFrameRate(60.0);
      PerformanceOptimizer.recordAnimationDuration(300);
      
      // Verify data exists
      final statsBefore = PerformanceOptimizer.getPerformanceStats();
      expect(statsBefore['frameRate']['samples'], greaterThan(0));
      
      // Dispose
      PerformanceOptimizer.dispose();
      
      // Reinitialize
      PerformanceOptimizer.initialize();
      
      // Verify data is cleared
      final statsAfter = PerformanceOptimizer.getPerformanceStats();
      expect(statsAfter['frameRate']['samples'], equals(0));
      expect(statsAfter['animationDuration']['samples'], equals(0));
    });

    test('should handle optimization state changes', () {
      // Test optimization state changes
      expect(PerformanceOptimizer.isOptimizationEnabled, isTrue);
      
      PerformanceOptimizer.setOptimizationEnabled(false);
      expect(PerformanceOptimizer.isOptimizationEnabled, isFalse);
      
      PerformanceOptimizer.setOptimizationEnabled(true);
      expect(PerformanceOptimizer.isOptimizationEnabled, isTrue);
      
      // Verify state is reflected in stats
      final stats = PerformanceOptimizer.getPerformanceStats();
      expect(stats['isOptimizationEnabled'], isTrue);
    });

    test('should calculate statistics correctly', () {
      // Record known values for testing calculations
      PerformanceOptimizer.recordFrameRate(50.0);
      PerformanceOptimizer.recordFrameRate(60.0);
      PerformanceOptimizer.recordFrameRate(70.0);
      
      PerformanceOptimizer.recordAnimationDuration(200);
      PerformanceOptimizer.recordAnimationDuration(300);
      PerformanceOptimizer.recordAnimationDuration(400);
      
      // Get stats
      final stats = PerformanceOptimizer.getPerformanceStats();
      final frameRateStats = stats['frameRate'];
      final animationStats = stats['animationDuration'];
      
      // Verify calculations
      expect(frameRateStats['current'], equals(70.0));
      expect(frameRateStats['average'], equals(60.0));
      expect(frameRateStats['min'], equals(50.0));
      expect(frameRateStats['samples'], equals(3));
      
      expect(animationStats['current'], equals(400));
      expect(animationStats['average'], equals(300.0));
      expect(animationStats['max'], equals(400));
      expect(animationStats['samples'], equals(3));
    });
  });
} 