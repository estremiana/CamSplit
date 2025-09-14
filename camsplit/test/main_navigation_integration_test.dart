import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/routes/app_routes.dart';
import '../lib/widgets/main_navigation_container.dart';
import '../lib/services/navigation_service.dart';
import '../lib/services/haptic_feedback_service.dart';
import '../lib/services/animation_service.dart';
import '../lib/services/icon_preloader.dart';

void main() {
  group('Main Navigation Integration Tests', () {
    testWidgets('Main navigation container can be created', (WidgetTester tester) async {
      // Build the main navigation container
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationContainer(initialPage: 0),
        ),
      );
      await tester.pump();

      // Verify that the container builds without errors
      expect(find.byType(MainNavigationContainer), findsOneWidget);
    });

    test('Navigation services can be initialized', () {
      // Test that services can be accessed without errors
      expect(() => NavigationService.initialize(), returnsNormally);
      expect(() => HapticFeedbackService.initialize(), returnsNormally);
      expect(() => AnimationService.initialize(), returnsNormally);
      expect(() => IconPreloader.preloadNavigationIcons(), returnsNormally);
    });

    test('App routes are properly configured', () {
      // Verify that main navigation route exists
      final routes = AppRoutes.routes;
      expect(routes.containsKey('/main-navigation'), isTrue);
      expect(routes.containsKey('/expense-dashboard'), isTrue);
      expect(routes.containsKey('/group-management'), isTrue);
      expect(routes.containsKey('/profile-settings'), isTrue);
    });

    test('Navigation service can be called', () {
      // Test navigation service functionality (without actual navigation)
      expect(() => NavigationService.navigateToPage(1), returnsNormally);
      expect(() => NavigationService.navigateToDashboard(), returnsNormally);
      expect(() => NavigationService.navigateToGroups(), returnsNormally);
      expect(() => NavigationService.navigateToProfile(), returnsNormally);
    });

    test('Haptic feedback service is functional', () {
      // Test haptic feedback methods
      expect(() => HapticFeedbackService.pageChange(), returnsNormally);
      expect(() => HapticFeedbackService.swipeGesture(), returnsNormally);
      expect(() => HapticFeedbackService.boundaryReached(), returnsNormally);
      expect(() => HapticFeedbackService.welcomeButtonNavigation(), returnsNormally);
      
      // Test enable/disable functionality
      HapticFeedbackService.setEnabled(false);
      expect(HapticFeedbackService.isEnabled, isFalse);
      
      HapticFeedbackService.setEnabled(true);
      expect(HapticFeedbackService.isEnabled, isTrue);
    });

    test('Animation service provides correct configurations', () {
      // Test animation curves
      expect(AnimationService.pageTransitionCurve, isNotNull);
      expect(AnimationService.swipeGestureCurve, isNotNull);
      expect(AnimationService.bounceBackCurve, isNotNull);
      expect(AnimationService.quickTransitionCurve, isNotNull);
      
      // Test animation durations
      expect(AnimationService.pageTransitionDuration, isNotNull);
      expect(AnimationService.swipeGestureDuration, isNotNull);
      expect(AnimationService.quickTransitionDuration, isNotNull);
      expect(AnimationService.bounceBackDuration, isNotNull);
      expect(AnimationService.visualFeedbackDuration, isNotNull);
    });

    test('Icon preloader can be called', () {
      // Test icon preloading
      expect(() => IconPreloader.preloadNavigationIcons(), returnsNormally);
      
      // Test that preloading can be called multiple times safely
      expect(() => IconPreloader.preloadNavigationIcons(), returnsNormally);
      
      // Test cache management
      expect(() => IconPreloader.clearCache(), returnsNormally);
    });

    testWidgets('App routes can be accessed', (WidgetTester tester) async {
      // Build a simple MaterialApp to provide context
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Container()),
        ),
      );
      
      // Test that routes can be accessed without errors
      final routes = AppRoutes.routes;
      expect(routes, isNotNull);
      expect(routes.isNotEmpty, isTrue);
      
      // Test that main navigation route builder works
      final mainNavBuilder = routes['/main-navigation'];
      expect(mainNavBuilder, isNotNull);
      
      // Test that the builder can create a widget
      final widget = mainNavBuilder!(tester.element(find.byType(MaterialApp)));
      expect(widget, isNotNull);
    });
  });
} 