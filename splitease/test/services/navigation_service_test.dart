import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/services/navigation_service.dart';
import 'package:splitease/interfaces/navigation_interface.dart';

/// Mock implementation of MainNavigationContainerStateInterface for testing
class MockMainNavigationContainerState implements MainNavigationContainerStateInterface {
  int _currentPageIndex = 0;
  bool _isAnimating = false;
  List<NavigationCall> navigationCalls = [];
  
  @override
  int get currentPageIndex => _currentPageIndex;
  
  @override
  bool get isAnimating => _isAnimating;
  
  @override
  void navigateToPage(int pageIndex, {bool animate = true}) {
    navigationCalls.add(NavigationCall(pageIndex, animate));
    _currentPageIndex = pageIndex;
  }
  
  /// Helper method to simulate animation state
  void setAnimating(bool animating) {
    _isAnimating = animating;
  }
  
  /// Helper method to set current page index
  void setCurrentPageIndex(int index) {
    _currentPageIndex = index;
  }
  
  /// Helper method to clear navigation calls history
  void clearNavigationCalls() {
    navigationCalls.clear();
  }
}

/// Helper class to track navigation calls
class NavigationCall {
  final int pageIndex;
  final bool animate;
  
  NavigationCall(this.pageIndex, this.animate);
  
  @override
  String toString() => 'NavigationCall(pageIndex: $pageIndex, animate: $animate)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationCall &&
        other.pageIndex == pageIndex &&
        other.animate == animate;
  }
  
  @override
  int get hashCode => pageIndex.hashCode ^ animate.hashCode;
}

void main() {
  group('NavigationService', () {
    late MockMainNavigationContainerState mockState;
    
    setUp(() {
      mockState = MockMainNavigationContainerState();
      // Reset the navigation state before each test
      NavigationService.unregisterNavigationState();
    });
    
    tearDown(() {
      // Clean up after each test
      NavigationService.unregisterNavigationState();
    });
    
    group('Constants', () {
      test('should have correct page indices', () {
        expect(NavigationService.dashboardPageIndex, equals(0));
        expect(NavigationService.groupsPageIndex, equals(1));
        expect(NavigationService.profilePageIndex, equals(2));
      });
      
      test('should have correct animation duration', () {
        expect(NavigationService.animationDuration, equals(const Duration(milliseconds: 300)));
      });
      
      test('should have correct animation curve', () {
        expect(NavigationService.animationCurve, equals(Curves.easeInOut));
      });
    });
    
    group('navigateToPage', () {
      test('should return false when navigation state is not available', () {
        final result = NavigationService.navigateToPage(0);
        expect(result, isFalse);
      });
      
      test('should return false for invalid page index (negative)', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToPage(-1);
        expect(result, isFalse);
        expect(mockState.navigationCalls, isEmpty);
      });
      
      test('should return false for invalid page index (too high)', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToPage(3);
        expect(result, isFalse);
        expect(mockState.navigationCalls, isEmpty);
      });
      
      test('should navigate to valid page index 0 with animation', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToPage(0);
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(0, true)));
      });
      
      test('should navigate to valid page index 1 with animation', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToPage(1);
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(1, true)));
      });
      
      test('should navigate to valid page index 2 with animation', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToPage(2);
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(2, true)));
      });
      
      test('should navigate without animation when animate is false', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToPage(1, animate: false);
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(1, false)));
      });
      
      test('should handle multiple navigation calls', () {
        NavigationService.registerNavigationState(mockState);
        
        NavigationService.navigateToPage(0);
        NavigationService.navigateToPage(1, animate: false);
        NavigationService.navigateToPage(2);
        
        expect(mockState.navigationCalls.length, equals(3));
        expect(mockState.navigationCalls[0], equals(NavigationCall(0, true)));
        expect(mockState.navigationCalls[1], equals(NavigationCall(1, false)));
        expect(mockState.navigationCalls[2], equals(NavigationCall(2, true)));
      });
    });
    
    group('navigateToDashboard', () {
      test('should navigate to dashboard page (index 0) with animation by default', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToDashboard();
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(0, true)));
      });
      
      test('should navigate to dashboard page without animation when specified', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToDashboard(animate: false);
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(0, false)));
      });
      
      test('should return false when navigation state is not available', () {
        final result = NavigationService.navigateToDashboard();
        expect(result, isFalse);
      });
    });
    
    group('navigateToGroups', () {
      test('should navigate to groups page (index 1) with animation by default', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToGroups();
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(1, true)));
      });
      
      test('should navigate to groups page without animation when specified', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToGroups(animate: false);
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(1, false)));
      });
      
      test('should return false when navigation state is not available', () {
        final result = NavigationService.navigateToGroups();
        expect(result, isFalse);
      });
    });
    
    group('navigateToProfile', () {
      test('should navigate to profile page (index 2) with animation by default', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToProfile();
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(2, true)));
      });
      
      test('should navigate to profile page without animation when specified', () {
        NavigationService.registerNavigationState(mockState);
        final result = NavigationService.navigateToProfile(animate: false);
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(2, false)));
      });
      
      test('should return false when navigation state is not available', () {
        final result = NavigationService.navigateToProfile();
        expect(result, isFalse);
      });
    });
    
    group('getCurrentPageIndex', () {
      test('should return null when navigation state is not available', () {
        final result = NavigationService.getCurrentPageIndex();
        expect(result, isNull);
      });
      
      test('should return current page index when available', () {
        NavigationService.registerNavigationState(mockState);
        mockState.setCurrentPageIndex(1);
        
        final result = NavigationService.getCurrentPageIndex();
        expect(result, equals(1));
      });
      
      test('should return updated page index after navigation', () {
        NavigationService.registerNavigationState(mockState);
        
        // Initial state
        expect(NavigationService.getCurrentPageIndex(), equals(0));
        
        // Navigate to groups
        NavigationService.navigateToGroups();
        expect(NavigationService.getCurrentPageIndex(), equals(1));
        
        // Navigate to profile
        NavigationService.navigateToProfile();
        expect(NavigationService.getCurrentPageIndex(), equals(2));
      });
    });
    
    group('isNavigationAvailable', () {
      test('should return false when navigation state is not available', () {
        expect(NavigationService.isNavigationAvailable, isFalse);
      });
      
      test('should return true when navigation state is available', () {
        NavigationService.registerNavigationState(mockState);
        expect(NavigationService.isNavigationAvailable, isTrue);
      });
    });
    
    group('isAnimating', () {
      test('should return false when navigation state is not available', () {
        expect(NavigationService.isAnimating, isFalse);
      });
      
      test('should return false when not animating', () {
        NavigationService.registerNavigationState(mockState);
        mockState.setAnimating(false);
        expect(NavigationService.isAnimating, isFalse);
      });
      
      test('should return true when animating', () {
        NavigationService.registerNavigationState(mockState);
        mockState.setAnimating(true);
        expect(NavigationService.isAnimating, isTrue);
      });
    });
    
    group('Animation Queuing', () {
      test('should queue navigation requests when animating', () {
        NavigationService.registerNavigationState(mockState);
        mockState.setAnimating(true);
        
        // Clear any existing queue
        NavigationService.clearNavigationQueue();
        
        // Make navigation request while animating
        final result = NavigationService.navigateToProfile();
        
        expect(result, isTrue);
        expect(NavigationService.queueSize, equals(1));
        expect(mockState.navigationCalls, isEmpty); // Should not call immediately
      });
      
      test('should clear navigation queue', () {
        NavigationService.registerNavigationState(mockState);
        mockState.setAnimating(true);
        
        // Add requests to queue
        NavigationService.navigateToProfile();
        NavigationService.navigateToGroups();
        
        expect(NavigationService.queueSize, equals(2));
        
        // Clear queue
        NavigationService.clearNavigationQueue();
        
        expect(NavigationService.queueSize, equals(0));
      });
      
      test('should remove duplicate page requests from queue', () {
        NavigationService.registerNavigationState(mockState);
        mockState.setAnimating(true);
        
        NavigationService.clearNavigationQueue();
        
        // Add multiple requests to same page
        NavigationService.navigateToProfile();
        NavigationService.navigateToProfile();
        NavigationService.navigateToGroups();
        NavigationService.navigateToProfile(); // Should replace previous profile requests
        
        expect(NavigationService.queueSize, equals(2)); // Only groups and latest profile
      });
      
      test('should execute navigation immediately when not animating', () {
        NavigationService.registerNavigationState(mockState);
        mockState.setAnimating(false);
        
        NavigationService.clearNavigationQueue();
        
        final result = NavigationService.navigateToProfile();
        
        expect(result, isTrue);
        expect(NavigationService.queueSize, equals(0)); // No queuing needed
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(2, true)));
      });
    });
    
    group('Integration scenarios', () {
      test('should handle welcome button navigation flow (requirement 3.1, 3.2)', () {
        NavigationService.registerNavigationState(mockState);
        
        // Simulate welcome button tap from dashboard
        mockState.setCurrentPageIndex(0); // Start on dashboard
        final result = NavigationService.navigateToProfile();
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(2, true)));
        expect(mockState.currentPageIndex, equals(2));
      });
      
      test('should handle rapid navigation requests with queuing', () {
        NavigationService.registerNavigationState(mockState);
        NavigationService.clearNavigationQueue();
        
        // First call should execute immediately
        mockState.setAnimating(false);
        final result1 = NavigationService.navigateToDashboard();
        expect(result1, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        
        // Simulate animation in progress
        mockState.setAnimating(true);
        
        // Subsequent calls should be queued
        final result2 = NavigationService.navigateToGroups();
        final result3 = NavigationService.navigateToProfile();
        final result4 = NavigationService.navigateToDashboard();
        
        // All calls should succeed (return true)
        expect([result2, result3, result4], everyElement(isTrue));
        
        // Only first call should have executed immediately
        expect(mockState.navigationCalls.length, equals(1));
        
        // Queue should contain the requests (3 total since we don't remove duplicates across different pages)
        expect(NavigationService.queueSize, equals(3));
      });
      
      test('should maintain state consistency across navigation calls', () {
        NavigationService.registerNavigationState(mockState);
        NavigationService.clearNavigationQueue();
        
        // Navigate through all pages
        NavigationService.navigateToDashboard();
        expect(NavigationService.getCurrentPageIndex(), equals(0));
        
        NavigationService.navigateToGroups();
        expect(NavigationService.getCurrentPageIndex(), equals(1));
        
        NavigationService.navigateToProfile();
        expect(NavigationService.getCurrentPageIndex(), equals(2));
        
        // Verify final state
        expect(NavigationService.isNavigationAvailable, isTrue);
        expect(mockState.navigationCalls.length, equals(3));
      });
      
      test('should handle external entry point navigation (requirement 2.1, 2.2, 2.3)', () {
        NavigationService.registerNavigationState(mockState);
        NavigationService.clearNavigationQueue();
        
        // Simulate external entry point navigation (like from app routes)
        final result = NavigationService.navigateToPage(1, animate: true);
        
        expect(result, isTrue);
        expect(mockState.navigationCalls.length, equals(1));
        expect(mockState.navigationCalls.first, equals(NavigationCall(1, true)));
        expect(mockState.currentPageIndex, equals(1));
      });
      
      test('should handle navigation from different app states', () {
        NavigationService.registerNavigationState(mockState);
        NavigationService.clearNavigationQueue();
        
        // Test navigation from various starting states
        final testCases = [
          {'from': 0, 'to': 1, 'animate': true},
          {'from': 1, 'to': 2, 'animate': false},
          {'from': 2, 'to': 0, 'animate': true},
        ];
        
        for (final testCase in testCases) {
          mockState.clearNavigationCalls();
          mockState.setCurrentPageIndex(testCase['from'] as int);
          
          final result = NavigationService.navigateToPage(
            testCase['to'] as int,
            animate: testCase['animate'] as bool,
          );
          
          expect(result, isTrue);
          expect(mockState.navigationCalls.length, equals(1));
          expect(mockState.navigationCalls.first, equals(
            NavigationCall(testCase['to'] as int, testCase['animate'] as bool),
          ));
        }
      });
    });
  });
}