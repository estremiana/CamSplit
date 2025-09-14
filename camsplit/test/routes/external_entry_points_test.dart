import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/routes/app_routes.dart';
import 'package:camsplit/services/navigation_service.dart';

void main() {
  group('External Entry Points Routing Tests', () {
    group('Route Generation', () {
      test('should generate main navigation route with default page index', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(name: AppRoutes.mainNavigation),
        );
        
        expect(route, isNotNull);
        expect(route!.settings.name, equals(AppRoutes.mainNavigation));
      });
      
      test('should generate main navigation route with specific page index', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(
            name: AppRoutes.mainNavigation,
            arguments: {'pageIndex': AppRoutes.groupsPageIndex},
          ),
        );
        
        expect(route, isNotNull);
        expect(route!.settings.name, equals(AppRoutes.mainNavigation));
        expect(route.settings.arguments, equals({'pageIndex': AppRoutes.groupsPageIndex}));
      });
      
      test('should handle invalid page index gracefully', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(
            name: AppRoutes.mainNavigation,
            arguments: {'pageIndex': 99}, // Invalid page index
          ),
        );
        
        expect(route, isNotNull);
        expect(route!.settings.name, equals(AppRoutes.mainNavigation));
      });
      
      test('should generate legacy dashboard route', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(name: AppRoutes.expenseDashboard),
        );
        
        expect(route, isNotNull);
        expect(route!.settings.name, equals(AppRoutes.expenseDashboard));
      });
      
      test('should generate legacy groups route', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(name: AppRoutes.groupManagement),
        );
        
        expect(route, isNotNull);
        expect(route!.settings.name, equals(AppRoutes.groupManagement));
      });
      
      test('should generate legacy profile route', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(name: AppRoutes.profileSettings),
        );
        
        expect(route, isNotNull);
        expect(route!.settings.name, equals(AppRoutes.profileSettings));
      });
      
      test('should generate legacy routes with page index arguments', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(
            name: AppRoutes.expenseDashboard,
            arguments: {'pageIndex': AppRoutes.profilePageIndex},
          ),
        );
        
        expect(route, isNotNull);
        expect(route!.settings.name, equals(AppRoutes.expenseDashboard));
        expect(route.settings.arguments, equals({'pageIndex': AppRoutes.profilePageIndex}));
      });
      
      test('should return null for unknown routes', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(name: '/unknown-route'),
        );
        
        expect(route, isNull);
      });
    });
    
    group('Page Index Constants', () {
      test('should have correct page index constants', () {
        expect(AppRoutes.dashboardPageIndex, equals(0));
        expect(AppRoutes.groupsPageIndex, equals(1));
        expect(AppRoutes.profilePageIndex, equals(2));
      });
      
      test('should match NavigationService constants', () {
        expect(AppRoutes.dashboardPageIndex, equals(NavigationService.dashboardPageIndex));
        expect(AppRoutes.groupsPageIndex, equals(NavigationService.groupsPageIndex));
        expect(AppRoutes.profilePageIndex, equals(NavigationService.profilePageIndex));
      });
    });
    
    group('Route Names', () {
      test('should have correct route name constants', () {
        expect(AppRoutes.mainNavigation, equals('/main-navigation'));
        expect(AppRoutes.expenseDashboard, equals('/expense-dashboard'));
        expect(AppRoutes.groupManagement, equals('/group-management'));
        expect(AppRoutes.profileSettings, equals('/profile-settings'));
      });
    });
    
    group('Deep Linking Support', () {
      test('should support deep linking with page index parameters', () {
        final testCases = [
          {'route': AppRoutes.mainNavigation, 'pageIndex': 0},
          {'route': AppRoutes.mainNavigation, 'pageIndex': 1},
          {'route': AppRoutes.mainNavigation, 'pageIndex': 2},
        ];
        
        for (final testCase in testCases) {
          final route = AppRoutes.onGenerateRoute(
            RouteSettings(
              name: testCase['route'] as String,
              arguments: {'pageIndex': testCase['pageIndex']},
            ),
          );
          
          expect(route, isNotNull);
          expect(route!.settings.arguments, equals({'pageIndex': testCase['pageIndex']}));
        }
      });
      
      test('should support legacy route deep linking', () {
        final legacyRoutes = [
          AppRoutes.expenseDashboard,
          AppRoutes.groupManagement,
          AppRoutes.profileSettings,
        ];
        
        for (final routeName in legacyRoutes) {
          final route = AppRoutes.onGenerateRoute(
            RouteSettings(
              name: routeName,
              arguments: {'pageIndex': AppRoutes.profilePageIndex},
            ),
          );
          
          expect(route, isNotNull);
          expect(route!.settings.name, equals(routeName));
          expect(route.settings.arguments, equals({'pageIndex': AppRoutes.profilePageIndex}));
        }
      });
    });
    
    group('External Navigation Integration', () {
      test('should handle navigation from external widgets', () {
        // Test that external widgets can navigate using the service
        expect(NavigationService.dashboardPageIndex, equals(AppRoutes.dashboardPageIndex));
        expect(NavigationService.groupsPageIndex, equals(AppRoutes.groupsPageIndex));
        expect(NavigationService.profilePageIndex, equals(AppRoutes.profilePageIndex));
      });
      
      test('should support welcome button navigation flow', () {
        // Verify that the profile page index is correctly defined for welcome button navigation
        expect(AppRoutes.profilePageIndex, equals(2));
        expect(NavigationService.profilePageIndex, equals(2));
      });
    });
    
    group('Route Arguments Validation', () {
      test('should handle missing arguments gracefully', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(name: AppRoutes.mainNavigation),
        );
        
        expect(route, isNotNull);
        expect(route!.settings.name, equals(AppRoutes.mainNavigation));
      });
      
      test('should handle null arguments gracefully', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(
            name: AppRoutes.mainNavigation,
            arguments: null,
          ),
        );
        
        expect(route, isNotNull);
        expect(route!.settings.name, equals(AppRoutes.mainNavigation));
      });
      
      test('should handle empty arguments gracefully', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(
            name: AppRoutes.mainNavigation,
            arguments: <String, dynamic>{},
          ),
        );
        
        expect(route, isNotNull);
        expect(route!.settings.name, equals(AppRoutes.mainNavigation));
      });
      
      test('should handle invalid argument types gracefully', () {
        final route = AppRoutes.onGenerateRoute(
          const RouteSettings(
            name: AppRoutes.mainNavigation,
            arguments: {'pageIndex': 'invalid'}, // String instead of int
          ),
        );
        
        expect(route, isNotNull);
        expect(route!.settings.name, equals(AppRoutes.mainNavigation));
      });
    });
    
    group('Performance and Optimization', () {
      test('should create routes efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Generate multiple routes to test performance
        for (int i = 0; i < 100; i++) {
          AppRoutes.onGenerateRoute(
            RouteSettings(
              name: AppRoutes.mainNavigation,
              arguments: {'pageIndex': i % 3},
            ),
          );
        }
        
        stopwatch.stop();
        
        // Route generation should be fast (less than 100ms for 100 routes)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
      
      test('should handle rapid route generation requests', () {
        final routes = <Route>[];
        
        // Generate multiple routes rapidly
        for (int i = 0; i < 10; i++) {
          final route = AppRoutes.onGenerateRoute(
            RouteSettings(
              name: AppRoutes.mainNavigation,
              arguments: {'pageIndex': i % 3},
            ),
          );
          
          if (route != null) {
            routes.add(route);
          }
        }
        
        expect(routes.length, equals(10));
        
        // Verify all routes are properly configured
        for (final route in routes) {
          expect(route.settings.name, equals(AppRoutes.mainNavigation));
        }
      });
    });
    
    group('Backward Compatibility', () {
      test('should maintain backward compatibility with legacy routes', () {
        final legacyRouteMap = {
          AppRoutes.expenseDashboard: AppRoutes.dashboardPageIndex,
          AppRoutes.groupManagement: AppRoutes.groupsPageIndex,
          AppRoutes.profileSettings: AppRoutes.profilePageIndex,
        };
        
        for (final entry in legacyRouteMap.entries) {
          final route = AppRoutes.onGenerateRoute(
            RouteSettings(name: entry.key),
          );
          
          expect(route, isNotNull);
          expect(route!.settings.name, equals(entry.key));
        }
      });
      
      test('should support existing navigation patterns', () {
        // Test that existing navigation patterns still work
        final routes = AppRoutes.routes;
        
        expect(routes.containsKey(AppRoutes.mainNavigation), isTrue);
        expect(routes.containsKey(AppRoutes.expenseDashboard), isTrue);
        expect(routes.containsKey(AppRoutes.groupManagement), isTrue);
        expect(routes.containsKey(AppRoutes.profileSettings), isTrue);
      });
    });
  });
}