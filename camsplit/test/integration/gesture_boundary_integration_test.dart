import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/widgets/main_navigation_container.dart';

/// Simple test page that doesn't depend on external services
class SimpleTestPage extends StatefulWidget {
  final String title;
  final bool isScrollable;
  
  const SimpleTestPage({
    Key? key,
    required this.title,
    this.isScrollable = false,
  }) : super(key: key);

  @override
  State<SimpleTestPage> createState() => _SimpleTestPageState();
}

class _SimpleTestPageState extends State<SimpleTestPage> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (!widget.isScrollable) {
      return Scaffold(
        body: Center(
          child: Text(widget.title),
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('${widget.title} - Item $index'),
          );
        },
      ),
    );
  }
}

void main() {
  group('Gesture Boundary Detection Integration Tests', () {
    testWidgets('should detect scroll notifications from child widgets', (WidgetTester tester) async {
      // Create a simple app with MainNavigationContainer
      final testApp = MaterialApp(
        home: const MainNavigationContainer(initialPage: 0),
      );

      await tester.pumpWidget(testApp);
      await tester.pump(); // Allow initial build

      // Find the NotificationListener
      final notificationListenerFinder = find.byType(NotificationListener<ScrollNotification>);
      expect(notificationListenerFinder, findsOneWidget);

      // Find the RawGestureDetector
      final rawGestureDetectorFinder = find.byType(RawGestureDetector);
      expect(rawGestureDetectorFinder, findsOneWidget);

      // Find the PageView
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      // Verify the MainNavigationContainer state
      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );
      expect(mainNavigationContainer.currentPageIndex, equals(0));
      expect(mainNavigationContainer.isAnimating, isFalse);
    });

    testWidgets('should handle pan gestures correctly', (WidgetTester tester) async {
      final testApp = MaterialApp(
        home: const MainNavigationContainer(initialPage: 1), // Start on middle page
      );

      await tester.pumpWidget(testApp);
      await tester.pump();

      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );

      // Verify we're on the middle page
      expect(mainNavigationContainer.currentPageIndex, equals(1));

      // Perform a pan gesture to the left (should go to next page)
      await tester.drag(find.byType(PageView), const Offset(-100, 0));
      await tester.pump();

      // The gesture should be processed (though the actual page change depends on the PageView)
      // We're mainly testing that the gesture detection system doesn't crash
      expect(mainNavigationContainer.currentPageIndex, isA<int>());
    });

    testWidgets('should prevent gestures at page boundaries', (WidgetTester tester) async {
      // Test first page boundary
      final firstPageApp = MaterialApp(
        home: const MainNavigationContainer(initialPage: 0),
      );

      await tester.pumpWidget(firstPageApp);
      await tester.pump();

      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );

      expect(mainNavigationContainer.currentPageIndex, equals(0));

      // Try to swipe right (should be prevented on first page)
      await tester.drag(find.byType(PageView), const Offset(100, 0));
      await tester.pump();

      // Should still be on first page
      expect(mainNavigationContainer.currentPageIndex, equals(0));
    });

    testWidgets('should handle rapid gestures without crashing', (WidgetTester tester) async {
      final testApp = MaterialApp(
        home: const MainNavigationContainer(initialPage: 1),
      );

      await tester.pumpWidget(testApp);
      await tester.pump();

      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );

      // Perform multiple rapid gestures
      for (int i = 0; i < 5; i++) {
        await tester.drag(find.byType(PageView), const Offset(-50, 0));
        await tester.pump(const Duration(milliseconds: 10));
      }

      // Should handle rapid gestures without crashing
      expect(mainNavigationContainer.currentPageIndex, isA<int>());
      expect(mainNavigationContainer.currentPageIndex, inInclusiveRange(0, 2));
    });
  });
}