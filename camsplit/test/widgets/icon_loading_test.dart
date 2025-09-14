import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/widgets/custom_icon_widget.dart';
import 'package:camsplit/widgets/enhanced_bottom_navigation.dart';
import 'package:camsplit/models/navigation_page_configurations.dart';

void main() {
  group('Icon Loading Tests', () {
    group('CustomIconWidget Tests', () {
      testWidgets('should load dashboard icon immediately', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomIconWidget(
                iconName: 'dashboard',
                size: 24,
                color: Colors.blue,
              ),
            ),
          ),
        );

        // Verify icon is displayed immediately
        expect(find.byType(Icon), findsOneWidget);
        
        // Verify it's not showing the fallback help icon
        expect(find.byIcon(Icons.help_outline), findsNothing);
        
        // Verify it's showing the dashboard icon
        expect(find.byIcon(Icons.dashboard), findsOneWidget);
      });

      testWidgets('should load group icon immediately', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomIconWidget(
                iconName: 'group',
                size: 24,
                color: Colors.blue,
              ),
            ),
          ),
        );

        // Verify icon is displayed immediately
        expect(find.byType(Icon), findsOneWidget);
        
        // Verify it's not showing the fallback help icon
        expect(find.byIcon(Icons.help_outline), findsNothing);
        
        // Verify it's showing the group icon
        expect(find.byIcon(Icons.group), findsOneWidget);
      });

      testWidgets('should load person_outline icon immediately', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomIconWidget(
                iconName: 'person_outline',
                size: 24,
                color: Colors.blue,
              ),
            ),
          ),
        );

        // Verify icon is displayed immediately
        expect(find.byType(Icon), findsOneWidget);
        
        // Verify it's not showing the fallback help icon
        expect(find.byIcon(Icons.help_outline), findsNothing);
        
        // Verify it's showing the person_outline icon
        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      });

      testWidgets('should show fallback icon for invalid icon name', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomIconWidget(
                iconName: 'invalid_icon_name',
                size: 24,
                color: Colors.blue,
              ),
            ),
          ),
        );

        // Verify fallback icon is displayed
        expect(find.byType(Icon), findsOneWidget);
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
      });

      testWidgets('should handle empty icon name gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomIconWidget(
                iconName: '',
                size: 24,
                color: Colors.blue,
              ),
            ),
          ),
        );

        // Verify fallback icon is displayed
        expect(find.byType(Icon), findsOneWidget);
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
      });
    });

    group('EnhancedBottomNavigation Icon Tests', () {
      testWidgets('should display all navigation icons immediately', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 0,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        // Verify all navigation items are present
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Groups'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);

        // Verify icons are displayed immediately (no loading states)
        expect(find.byType(Icon), findsNWidgets(3)); // 3 icons (one per tab)
        
        // Verify no fallback icons are shown
        expect(find.byIcon(Icons.help_outline), findsNothing);
        
        // Verify the correct icons are displayed (only one icon per tab is visible)
        expect(find.byIcon(Icons.dashboard), findsOneWidget); // Active dashboard
        expect(find.byIcon(Icons.group), findsOneWidget); // Inactive groups
        expect(find.byIcon(Icons.person_outline), findsOneWidget); // Inactive profile
      });

      testWidgets('should show correct active/inactive icons for each page', (WidgetTester tester) async {
        // Test Dashboard page (index 0)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 0,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        // Dashboard should show active dashboard icon
        expect(find.byIcon(Icons.dashboard), findsOneWidget);
        
        // Groups should show inactive group icon
        expect(find.byIcon(Icons.group), findsOneWidget);
        
        // Profile should show inactive person_outline icon
        expect(find.byIcon(Icons.person_outline), findsOneWidget);

        // Test Groups page (index 1)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 1,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        // Dashboard should show inactive dashboard icon
        expect(find.byIcon(Icons.dashboard), findsOneWidget);
        
        // Groups should show active groups icon
        expect(find.byIcon(Icons.groups), findsOneWidget);
        
        // Profile should show inactive person_outline icon
        expect(find.byIcon(Icons.person_outline), findsOneWidget);

        // Test Profile page (index 2)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 2,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        // Dashboard should show inactive dashboard icon
        expect(find.byIcon(Icons.dashboard), findsOneWidget);
        
        // Groups should show inactive group icon
        expect(find.byIcon(Icons.group), findsOneWidget);
        
        // Profile should show active person icon
        expect(find.byIcon(Icons.person), findsOneWidget);
      });

      testWidgets('should not show placeholder or loading indicators', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 0,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        // Verify no loading indicators are shown
        expect(find.byType(CircularProgressIndicator), findsNothing);
        
        // Verify no placeholder widgets are shown
        expect(find.byType(Placeholder), findsNothing);
        
        // Verify no question mark icons are shown
        expect(find.byIcon(Icons.help), findsNothing);
        expect(find.byIcon(Icons.help_outline), findsNothing);
        
        // Verify icons are immediately visible
        expect(find.byType(Icon), findsNWidgets(3));
      });

      testWidgets('should handle rapid page changes without icon loading issues', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EnhancedBottomNavigation(
                currentPageIndex: 0,
                onPageSelected: (index) {},
              ),
            ),
          ),
        );

        // Rapidly change pages
        for (int i = 0; i < 3; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                bottomNavigationBar: EnhancedBottomNavigation(
                  currentPageIndex: i,
                  onPageSelected: (index) {},
                ),
              ),
            ),
          );
          await tester.pump(); // Allow frame to complete
        }

        // Verify icons are still displayed correctly
        expect(find.byType(Icon), findsNWidgets(3));
        expect(find.byIcon(Icons.help_outline), findsNothing);
      });
    });

    group('Icon Performance Tests', () {
      testWidgets('should render icons without delay', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CustomIconWidget(iconName: 'dashboard', size: 24),
                  CustomIconWidget(iconName: 'group', size: 24),
                  CustomIconWidget(iconName: 'person_outline', size: 24),
                ],
              ),
            ),
          ),
        );
        
        stopwatch.stop();
        
        // Icon rendering should be very fast (less than 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        
        // Verify all icons are displayed
        expect(find.byType(Icon), findsNWidgets(3));
      });

      testWidgets('should handle multiple icon instances efficiently', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 100,
                itemBuilder: (context, index) {
                  return CustomIconWidget(
                    iconName: index % 3 == 0 ? 'dashboard' : 
                              index % 3 == 1 ? 'group' : 'person_outline',
                    size: 24,
                  );
                },
              ),
            ),
          ),
        );
        
        stopwatch.stop();
        
        // Even with 100 icons, rendering should be reasonably fast
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        
        // Verify all icons are displayed (ListView only shows visible items)
        expect(find.byType(Icon), findsNWidgets(25)); // ListView shows ~25 items at a time
      });
    });
  });
} 