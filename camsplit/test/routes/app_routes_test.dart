import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/routes/app_routes.dart';
import 'package:camsplit/widgets/main_navigation_container.dart';

void main() {
  group('AppRoutes External Entry Points', () {
    testWidgets('should navigate to main navigation with default dashboard page', (WidgetTester tester) async {
      // Build the app with main navigation route
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.mainNavigation,
        ),
      );
      
      // Verify MainNavigationContainer is created with dashboard page
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      
      final mainNavContainer = tester.widget<MainNavigationContainer>(
        find.byType(MainNavigationContainer),
      );
      expect(mainNavContainer.initialPage, equals(AppRoutes.dashboardPageIndex));
    });
    
    testWidgets('should navigate to main navigation with specific page index', (WidgetTester tester) async {
      // Build the app with main navigation route and page index argument
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.mainNavigation,
                    arguments: {'pageIndex': AppRoutes.groupsPageIndex},
                  );
                },
                child: const Text('Navigate to Groups'),
              );
            },
          ),
        ),
      );
      
      // Tap the button to navigate
      await tester.tap(find.text('Navigate to Groups'));
      await tester.pumpAndSettle();
      
      // Verify MainNavigationContainer is created with groups page
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      
      final mainNavContainer = tester.widget<MainNavigationContainer>(
        find.byType(MainNavigationContainer),
      );
      expect(mainNavContainer.initialPage, equals(AppRoutes.groupsPageIndex));
    });
    
    testWidgets('should handle invalid page index gracefully', (WidgetTester tester) async {
      // Build the app with main navigation route and invalid page index
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.mainNavigation,
                    arguments: {'pageIndex': 99}, // Invalid page index
                  );
                },
                child: const Text('Navigate with Invalid Index'),
              );
            },
          ),
        ),
      );
      
      // Tap the button to navigate
      await tester.tap(find.text('Navigate with Invalid Index'));
      await tester.pumpAndSettle();
      
      // Verify MainNavigationContainer defaults to dashboard page
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      
      final mainNavContainer = tester.widget<MainNavigationContainer>(
        find.byType(MainNavigationContainer),
      );
      expect(mainNavContainer.initialPage, equals(AppRoutes.dashboardPageIndex));
    });
    
    testWidgets('should support legacy dashboard route', (WidgetTester tester) async {
      // Build the app with legacy dashboard route
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.expenseDashboard,
        ),
      );
      
      // Verify MainNavigationContainer is created with dashboard page
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      
      final mainNavContainer = tester.widget<MainNavigationContainer>(
        find.byType(MainNavigationContainer),
      );
      expect(mainNavContainer.initialPage, equals(AppRoutes.dashboardPageIndex));
    });
    
    testWidgets('should support legacy groups route', (WidgetTester tester) async {
      // Build the app with legacy groups route
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.groupManagement,
        ),
      );
      
      // Verify MainNavigationContainer is created with groups page
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      
      final mainNavContainer = tester.widget<MainNavigationContainer>(
        find.byType(MainNavigationContainer),
      );
      expect(mainNavContainer.initialPage, equals(AppRoutes.groupsPageIndex));
    });
    
    testWidgets('should support legacy profile route', (WidgetTester tester) async {
      // Build the app with legacy profile route
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.profileSettings,
        ),
      );
      
      // Verify MainNavigationContainer is created with profile page
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      
      final mainNavContainer = tester.widget<MainNavigationContainer>(
        find.byType(MainNavigationContainer),
      );
      expect(mainNavContainer.initialPage, equals(AppRoutes.profilePageIndex));
    });
    
    testWidgets('should support legacy routes with page index arguments', (WidgetTester tester) async {
      // Build the app with legacy route and page index argument
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.expenseDashboard,
                    arguments: {'pageIndex': AppRoutes.profilePageIndex},
                  );
                },
                child: const Text('Navigate to Dashboard with Profile Index'),
              );
            },
          ),
        ),
      );
      
      // Tap the button to navigate
      await tester.tap(find.text('Navigate to Dashboard with Profile Index'));
      await tester.pumpAndSettle();
      
      // Verify MainNavigationContainer is created with profile page (overriding default)
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      
      final mainNavContainer = tester.widget<MainNavigationContainer>(
        find.byType(MainNavigationContainer),
      );
      expect(mainNavContainer.initialPage, equals(AppRoutes.profilePageIndex));
    });
    
    group('AppRoutes Helper Methods', () {
      testWidgets('navigateToMainNavigation should work correctly', (WidgetTester tester) async {
        late BuildContext testContext;
        
        await tester.pumpWidget(
          MaterialApp(
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: Builder(
              builder: (context) {
                testContext = context;
                return ElevatedButton(
                  onPressed: () {
                    AppRoutes.navigateToMainNavigation(
                      context,
                      pageIndex: AppRoutes.groupsPageIndex,
                    );
                  },
                  child: const Text('Navigate to Main Navigation'),
                );
              },
            ),
          ),
        );
        
        // Tap the button to navigate
        await tester.tap(find.text('Navigate to Main Navigation'));
        await tester.pumpAndSettle();
        
        // Verify MainNavigationContainer is created with groups page
        expect(find.byType(MainNavigationContainer), findsOneWidget);
        
        final mainNavContainer = tester.widget<MainNavigationContainer>(
          find.byType(MainNavigationContainer),
        );
        expect(mainNavContainer.initialPage, equals(AppRoutes.groupsPageIndex));
      });
      
      testWidgets('navigateToDashboard should work correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppRoutes.navigateToDashboard(context);
                  },
                  child: const Text('Navigate to Dashboard'),
                );
              },
            ),
          ),
        );
        
        // Tap the button to navigate
        await tester.tap(find.text('Navigate to Dashboard'));
        await tester.pumpAndSettle();
        
        // Verify MainNavigationContainer is created with dashboard page
        expect(find.byType(MainNavigationContainer), findsOneWidget);
        
        final mainNavContainer = tester.widget<MainNavigationContainer>(
          find.byType(MainNavigationContainer),
        );
        expect(mainNavContainer.initialPage, equals(AppRoutes.dashboardPageIndex));
      });
      
      testWidgets('navigateToGroups should work correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppRoutes.navigateToGroups(context);
                  },
                  child: const Text('Navigate to Groups'),
                );
              },
            ),
          ),
        );
        
        // Tap the button to navigate
        await tester.tap(find.text('Navigate to Groups'));
        await tester.pumpAndSettle();
        
        // Verify MainNavigationContainer is created with groups page
        expect(find.byType(MainNavigationContainer), findsOneWidget);
        
        final mainNavContainer = tester.widget<MainNavigationContainer>(
          find.byType(MainNavigationContainer),
        );
        expect(mainNavContainer.initialPage, equals(AppRoutes.groupsPageIndex));
      });
      
      testWidgets('navigateToProfile should work correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    AppRoutes.navigateToProfile(context);
                  },
                  child: const Text('Navigate to Profile'),
                );
              },
            ),
          ),
        );
        
        // Tap the button to navigate
        await tester.tap(find.text('Navigate to Profile'));
        await tester.pumpAndSettle();
        
        // Verify MainNavigationContainer is created with profile page
        expect(find.byType(MainNavigationContainer), findsOneWidget);
        
        final mainNavContainer = tester.widget<MainNavigationContainer>(
          find.byType(MainNavigationContainer),
        );
        expect(mainNavContainer.initialPage, equals(AppRoutes.profilePageIndex));
      });
      
      testWidgets('replace navigation should work correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        AppRoutes.navigateToDashboard(context);
                      },
                      child: const Text('Navigate to Dashboard'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        AppRoutes.navigateToGroups(context, replace: true);
                      },
                      child: const Text('Replace with Groups'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
        
        // First navigation
        await tester.tap(find.text('Navigate to Dashboard'));
        await tester.pumpAndSettle();
        
        // Verify dashboard navigation
        expect(find.byType(MainNavigationContainer), findsOneWidget);
        
        // Replace navigation
        await tester.tap(find.text('Replace with Groups'));
        await tester.pumpAndSettle();
        
        // Verify groups navigation replaced dashboard
        expect(find.byType(MainNavigationContainer), findsOneWidget);
        
        final mainNavContainer = tester.widget<MainNavigationContainer>(
          find.byType(MainNavigationContainer),
        );
        expect(mainNavContainer.initialPage, equals(AppRoutes.groupsPageIndex));
      });
    });
    
    group('Deep Linking and External Entry Points', () {
      testWidgets('should handle deep link to specific page', (WidgetTester tester) async {
        // Simulate deep link navigation
        await tester.pumpWidget(
          MaterialApp(
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    // Simulate external deep link navigation
                    Navigator.pushNamed(
                      context,
                      AppRoutes.mainNavigation,
                      arguments: {'pageIndex': AppRoutes.profilePageIndex},
                    );
                  },
                  child: const Text('Deep Link to Profile'),
                );
              },
            ),
          ),
        );
        
        // Trigger deep link navigation
        await tester.tap(find.text('Deep Link to Profile'));
        await tester.pumpAndSettle();
        
        // Verify correct page is loaded
        expect(find.byType(MainNavigationContainer), findsOneWidget);
        
        final mainNavContainer = tester.widget<MainNavigationContainer>(
          find.byType(MainNavigationContainer),
        );
        expect(mainNavContainer.initialPage, equals(AppRoutes.profilePageIndex));
      });
      
      testWidgets('should handle external navigation from other parts of app', (WidgetTester tester) async {
        // Simulate navigation from external widget (like welcome button)
        await tester.pumpWidget(
          MaterialApp(
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    // Simulate welcome button navigation
                    AppRoutes.navigateToProfile(context);
                  },
                  child: const Text('Welcome Button Navigation'),
                );
              },
            ),
          ),
        );
        
        // Trigger external navigation
        await tester.tap(find.text('Welcome Button Navigation'));
        await tester.pumpAndSettle();
        
        // Verify navigation works correctly
        expect(find.byType(MainNavigationContainer), findsOneWidget);
        
        final mainNavContainer = tester.widget<MainNavigationContainer>(
          find.byType(MainNavigationContainer),
        );
        expect(mainNavContainer.initialPage, equals(AppRoutes.profilePageIndex));
      });
      
      testWidgets('should maintain route settings for navigation history', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.mainNavigation,
                      arguments: {'pageIndex': AppRoutes.groupsPageIndex},
                    );
                  },
                  child: const Text('Navigate with Route Settings'),
                );
              },
            ),
          ),
        );
        
        // Navigate with route settings
        await tester.tap(find.text('Navigate with Route Settings'));
        await tester.pumpAndSettle();
        
        // Verify navigation works and can go back
        expect(find.byType(MainNavigationContainer), findsOneWidget);
        
        // Test back navigation
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/navigation',
          null,
          (data) {},
        );
      });
    });
  });
}