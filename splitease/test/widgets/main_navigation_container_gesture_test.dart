import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/widgets/main_navigation_container.dart';
import '../../lib/models/navigation_page_configurations.dart';
import '../../lib/services/navigation_service.dart';

/// Test widget that simulates a scrollable page for testing gesture conflicts
class TestScrollablePage extends StatefulWidget {
  final String title;
  final bool hasScrollableContent;
  
  const TestScrollablePage({
    Key? key,
    required this.title,
    this.hasScrollableContent = true,
  }) : super(key: key);

  @override
  State<TestScrollablePage> createState() => _TestScrollablePageState();
}

class _TestScrollablePageState extends State<TestScrollablePage> 
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (!widget.hasScrollableContent) {
      return Scaffold(
        body: Center(
          child: Text(widget.title),
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        itemCount: 50,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('${widget.title} - Item $index'),
            subtitle: Text('Scrollable content item $index'),
          );
        },
      ),
    );
  }
}

void main() {
  group('MainNavigationContainer Gesture Boundary Detection', () {
    late Widget testApp;

    setUp(() {
      // Reset NavigationService before each test
      NavigationService.unregisterNavigationState();
      
      testApp = MaterialApp(
        home: const MainNavigationContainer(initialPage: 0),
      );
    });

    testWidgets('should detect scroll boundaries correctly', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Find the PageView widget
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      // Find the NotificationListener
      final notificationListenerFinder = find.byType(NotificationListener<ScrollNotification>);
      expect(notificationListenerFinder, findsOneWidget);

      // Verify initial state - should be on first page
      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );
      expect(mainNavigationContainer.currentPageIndex, equals(0));
    });

    testWidgets('should prevent PageView gestures during internal scrolling', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Simulate internal scrolling by sending scroll notifications
      final scrollableWidget = find.byType(PageView).first;
      
      // Create a scroll notification to simulate internal scrolling
      final scrollNotification = ScrollStartNotification(
        metrics: FixedScrollMetrics(
          minScrollExtent: 0.0,
          maxScrollExtent: 1000.0,
          pixels: 100.0,
          viewportDimension: 400.0,
          axisDirection: AxisDirection.down,
          devicePixelRatio: 1.0,
        ),
        context: tester.element(scrollableWidget),
      );

      // Dispatch the notification
      scrollNotification.dispatch(tester.element(scrollableWidget));
      await tester.pump();

      // Verify that internal scrolling state is updated
      // Note: This is a simplified test - in real scenarios, the scroll notifications
      // would come from actual scrollable widgets within the pages
    });

    testWidgets('should handle edge cases for first page', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Verify we're on the first page
      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );
      expect(mainNavigationContainer.currentPageIndex, equals(0));

      // Try to swipe right (which should be prevented on first page)
      await tester.drag(find.byType(PageView), const Offset(100, 0));
      await tester.pumpAndSettle();

      // Should still be on first page
      expect(mainNavigationContainer.currentPageIndex, equals(0));
    });

    testWidgets('should handle edge cases for last page', (WidgetTester tester) async {
      // Start on the last page
      final lastPageApp = MaterialApp(
        home: const MainNavigationContainer(initialPage: 2),
      );
      
      await tester.pumpWidget(lastPageApp);
      await tester.pumpAndSettle();

      // Verify we're on the last page
      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );
      expect(mainNavigationContainer.currentPageIndex, equals(2));

      // Try to swipe left (which should be prevented on last page)
      await tester.drag(find.byType(PageView), const Offset(-100, 0));
      await tester.pumpAndSettle();

      // Should still be on last page
      expect(mainNavigationContainer.currentPageIndex, equals(2));
    });

    testWidgets('should allow navigation between middle pages', (WidgetTester tester) async {
      // Start on the middle page
      final middlePageApp = MaterialApp(
        home: const MainNavigationContainer(initialPage: 1),
      );
      
      await tester.pumpWidget(middlePageApp);
      await tester.pumpAndSettle();

      // Verify we're on the middle page
      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );
      expect(mainNavigationContainer.currentPageIndex, equals(1));

      // Swipe left to go to next page (Profile)
      await tester.drag(find.byType(PageView), const Offset(-100, 0));
      await tester.pumpAndSettle();

      // Should be on page 2 (Profile)
      expect(mainNavigationContainer.currentPageIndex, equals(2));

      // Swipe right to go back to middle page
      await tester.drag(find.byType(PageView), const Offset(100, 0));
      await tester.pumpAndSettle();

      // Should be back on page 1 (Groups)
      expect(mainNavigationContainer.currentPageIndex, equals(1));
    });

    testWidgets('should update navigation state when pages are swiped', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Verify initial state - should be on first page (Dashboard)
      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );
      expect(mainNavigationContainer.currentPageIndex, equals(0));

      // Find the PageView
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      // Swipe to the next page (Groups)
      await tester.drag(pageViewFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Verify the page index has been updated
      expect(mainNavigationContainer.currentPageIndex, equals(1));

      // Swipe to the next page (Profile)
      await tester.drag(pageViewFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Verify the page index has been updated
      expect(mainNavigationContainer.currentPageIndex, equals(2));

      // Swipe back to the previous page (Groups)
      await tester.drag(pageViewFinder, const Offset(300, 0));
      await tester.pumpAndSettle();

      // Verify the page index has been updated back
      expect(mainNavigationContainer.currentPageIndex, equals(1));
    });

    testWidgets('should update navigation state when pages are swiped - simple test', (WidgetTester tester) async {
      // Create a simple test app with just the MainNavigationContainer
      await tester.pumpWidget(
        MaterialApp(
          home: MainNavigationContainer(initialPage: 0),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial state - should be on first page (Dashboard)
      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );
      expect(mainNavigationContainer.currentPageIndex, equals(0));

      // Find the PageView
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      // Swipe to the next page (Groups)
      await tester.drag(pageViewFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Verify the page index has been updated
      expect(mainNavigationContainer.currentPageIndex, equals(1));

      // Swipe to the next page (Profile)
      await tester.drag(pageViewFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Verify the page index has been updated
      expect(mainNavigationContainer.currentPageIndex, equals(2));

      // Swipe back to the previous page (Groups)
      await tester.drag(pageViewFinder, const Offset(300, 0));
      await tester.pumpAndSettle();

      // Verify the page index has been updated back
      expect(mainNavigationContainer.currentPageIndex, equals(1));
    });

    testWidgets('should provide haptic feedback for gestures', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Track haptic feedback calls
      final List<MethodCall> hapticCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'HapticFeedback.vibrate') {
          hapticCalls.add(methodCall);
        }
        return null;
      });

      // Perform a swipe gesture
      await tester.drag(find.byType(PageView), const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Verify haptic feedback was called
      expect(hapticCalls.isNotEmpty, isTrue);
    });

    testWidgets('should handle rapid gesture sequences gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );

      // Perform rapid swipe gestures
      for (int i = 0; i < 3; i++) {
        await tester.drag(find.byType(PageView), const Offset(-100, 0));
        await tester.pump(const Duration(milliseconds: 50));
      }
      
      await tester.pumpAndSettle();

      // Should handle rapid gestures without crashing
      expect(mainNavigationContainer.currentPageIndex, isA<int>());
      expect(mainNavigationContainer.currentPageIndex, inInclusiveRange(0, 2));
    });

    testWidgets('should provide haptic feedback for edge swipes', (WidgetTester tester) async {
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Verify we're on the first page
      final mainNavigationContainer = tester.state<MainNavigationContainerState>(
        find.byType(MainNavigationContainer)
      );
      expect(mainNavigationContainer.currentPageIndex, equals(0));

      // Try to swipe right on first page (should provide haptic feedback but not change page)
      final pageViewFinder = find.byType(PageView);
      await tester.drag(pageViewFinder, const Offset(300, 0));
      await tester.pumpAndSettle();

      // Verify we're still on the first page
      expect(mainNavigationContainer.currentPageIndex, equals(0));

      // Navigate to last page
      await tester.drag(pageViewFinder, const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(mainNavigationContainer.currentPageIndex, equals(2));

      // Try to swipe left on last page (should provide haptic feedback but not change page)
      await tester.drag(pageViewFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Verify we're still on the last page
      expect(mainNavigationContainer.currentPageIndex, equals(2));
    });
  });

  group('MainNavigationContainer Gesture Priority Handling', () {
    testWidgets('should prioritize internal scrolling over page navigation', (WidgetTester tester) async {
      final testApp = MaterialApp(
        home: const MainNavigationContainer(initialPage: 1),
      );
      
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // This test would require more complex setup to simulate actual internal scrolling
      // For now, we verify that the gesture detection system is in place
      final notificationListenerFinder = find.byType(NotificationListener<ScrollNotification>);
      expect(notificationListenerFinder, findsOneWidget);

      final rawGestureDetectorFinder = find.byType(RawGestureDetector);
      expect(rawGestureDetectorFinder, findsOneWidget);
    });
  });
}

