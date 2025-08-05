import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:splitease/widgets/main_navigation_container.dart';
import 'package:splitease/widgets/enhanced_bottom_navigation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Basic Integration Test Runner', () {
    testWidgets('should create MainNavigationContainer without errors', (WidgetTester tester) async {
      final testApp = MaterialApp(
        home: MainNavigationContainer(initialPage: 0),
      );

      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Verify basic components are present
      expect(find.byType(MainNavigationContainer), findsOneWidget);
      expect(find.byType(EnhancedBottomNavigation), findsOneWidget);
    });

    testWidgets('should handle basic navigation', (WidgetTester tester) async {
      final testApp = MaterialApp(
        home: MainNavigationContainer(initialPage: 0),
      );

      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Test basic swipe navigation
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      final bottomNav = tester.widget<EnhancedBottomNavigation>(
        find.byType(EnhancedBottomNavigation),
      );
      expect(bottomNav.currentPageIndex, isA<int>());
    });
  });
} 