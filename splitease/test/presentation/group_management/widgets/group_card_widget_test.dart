import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../../lib/presentation/group_management/widgets/group_card_widget.dart';
import '../../../../lib/core/app_export.dart';

void main() {
  group('GroupCardWidget', () {
    late Map<String, dynamic> mockGroup;

    setUp(() {
      mockGroup = {
        'id': 1,
        'name': 'Test Group',
        'description': 'Test Description',
        'totalBalance': 25.50,
        'isPositive': true,
        'currency': 'EUR',
        'memberCount': 3,
        'lastActivity': DateTime.now().subtract(Duration(hours: 2)),
        'members': [
          {
            'id': 1,
            'name': 'John Doe',
            'email': 'john@example.com',
            'avatar': null,
            'balance': 10.0,
            'isPositive': true,
          },
          {
            'id': 2,
            'name': 'Jane Smith',
            'email': 'jane@example.com',
            'avatar': null,
            'balance': -5.0,
            'isPositive': false,
          },
          {
            'id': 3,
            'name': 'Bob Johnson',
            'email': 'bob@example.com',
            'avatar': null,
            'balance': 0.0,
            'isPositive': true,
          },
        ],
        'recentExpenses': [
          {
            'id': 1,
            'title': 'Dinner',
            'amount': 45.0,
            'date': DateTime.now().subtract(Duration(hours: 1)),
          },
          {
            'id': 2,
            'title': 'Coffee',
            'amount': 12.0,
            'date': DateTime.now().subtract(Duration(days: 1)),
          },
        ],
      };
    });

    Widget createTestWidget({
      VoidCallback? onViewDetails,
      VoidCallback? onInvite,
      VoidCallback? onTap,
      VoidCallback? onLongPress,
      bool isMultiSelectMode = false,
    }) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  height: 800, // Provide enough height for expanded content
                  child: GroupCardWidget(
                    group: mockGroup,
                    isMultiSelectMode: isMultiSelectMode,
                    onViewDetails: onViewDetails,
                    onInvite: onInvite,
                    onTap: onTap,
                    onLongPress: onLongPress,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    testWidgets('should display group basic information', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Test Group'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.text('3 members'), findsOneWidget);
      expect(find.text('\$25.50'), findsOneWidget);
    });

    testWidgets('should expand and collapse when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially collapsed - should not show expanded content
      expect(find.text('Members'), findsNothing);
      expect(find.text('Recent Activity'), findsNothing);
      expect(find.text('View Details'), findsNothing);

      // Tap to expand
      await tester.tap(find.byKey(Key('group_card_main_inkwell')));
      await tester.pumpAndSettle();

      // Should show expanded content
      expect(find.text('Members'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Invite'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.byKey(Key('group_card_main_inkwell')));
      await tester.pumpAndSettle();

      // Should hide expanded content
      expect(find.text('Members'), findsNothing);
      expect(find.text('Recent Activity'), findsNothing);
      expect(find.text('View Details'), findsNothing);
    });

    testWidgets('should display members list in expanded state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand the card
      await tester.tap(find.byKey(Key('group_card_main_inkwell')));
      await tester.pumpAndSettle();

      // Check members are displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
      expect(find.text('Bob Johnson'), findsOneWidget);
      expect(find.text('Settled'), findsOneWidget);
      expect(find.text('+\$10.00'), findsOneWidget);
      expect(find.text('-\$5.00'), findsOneWidget);
    });

    testWidgets('should display recent activity in expanded state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand the card
      await tester.tap(find.byKey(Key('group_card_main_inkwell')));
      await tester.pumpAndSettle();

      // Check recent expenses are displayed
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('\$45.00'), findsOneWidget);
      expect(find.text('\$12.00'), findsOneWidget);
    });

    testWidgets('should show action buttons in expanded state', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand the card
      await tester.tap(find.byKey(Key('group_card_main_inkwell')));
      await tester.pumpAndSettle();

      // Check action buttons are present
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Invite'), findsOneWidget);
    });

    testWidgets('should call onViewDetails when View Details button is tapped', (WidgetTester tester) async {
      bool viewDetailsCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onViewDetails: () => viewDetailsCalled = true,
      ));
      await tester.pumpAndSettle();

      // Expand the card
      await tester.tap(find.byKey(Key('group_card_main_inkwell')));
      await tester.pumpAndSettle();

      // Scroll to make the button visible
      await tester.scrollUntilVisible(
        find.text('View Details'),
        500.0,
      );

      // Tap View Details button
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      expect(viewDetailsCalled, isTrue);
    });

    testWidgets('should call onInvite when Invite button is tapped', (WidgetTester tester) async {
      bool inviteCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onInvite: () => inviteCalled = true,
      ));
      await tester.pumpAndSettle();

      // Expand the card
      await tester.tap(find.byKey(Key('group_card_main_inkwell')));
      await tester.pumpAndSettle();

      // Scroll to make the button visible
      await tester.scrollUntilVisible(
        find.text('Invite'),
        500.0,
      );

      // Tap Invite button
      await tester.tap(find.text('Invite'));
      await tester.pumpAndSettle();

      expect(inviteCalled, isTrue);
    });

    testWidgets('should not expand when in multi-select mode', (WidgetTester tester) async {
      bool tapCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        isMultiSelectMode: true,
        onTap: () => tapCalled = true,
      ));
      await tester.pumpAndSettle();

      // Tap the card in multi-select mode
      await tester.tap(find.byKey(Key('group_card_main_inkwell')));
      await tester.pumpAndSettle();

      // Should call onTap instead of expanding
      expect(tapCalled, isTrue);
      expect(find.text('Members'), findsNothing);
      expect(find.text('Recent Activity'), findsNothing);
    });

    testWidgets('should show expand/collapse icon correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially should show expand_more icon
      expect(find.byWidgetPredicate((widget) => 
        widget is CustomIconWidget && widget.iconName == 'expand_more'
      ), findsOneWidget);

      // Tap to expand
      await tester.tap(find.byKey(Key('group_card_main_inkwell')));
      await tester.pumpAndSettle();

      // Should show expand_less icon
      expect(find.byWidgetPredicate((widget) => 
        widget is CustomIconWidget && widget.iconName == 'expand_less'
      ), findsOneWidget);
    });

    testWidgets('should handle long press correctly', (WidgetTester tester) async {
      bool longPressCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        onLongPress: () => longPressCalled = true,
      ));
      await tester.pumpAndSettle();

      // Long press the card
      await tester.longPress(find.byKey(Key('group_card_main_inkwell')));
      await tester.pumpAndSettle();

      expect(longPressCalled, isTrue);
    });

    testWidgets('should display correct balance colors', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the balance text widget
      final balanceText = tester.widget<Text>(find.text('\$25.50'));
      
      // Should be green for positive balance
      expect(balanceText.style?.color, AppTheme.successLight);
    });

    testWidgets('should display negative balance correctly', (WidgetTester tester) async {
      mockGroup['totalBalance'] = -15.75;
      mockGroup['isPositive'] = false;
      
      await tester.pumpWidget(createTestWidget());

      expect(find.text('\$15.75'), findsOneWidget);
      
      // Find the balance text widget
      final balanceText = tester.widget<Text>(find.text('\$15.75'));
      
      // Should be red for negative balance
      expect(balanceText.style?.color, AppTheme.errorLight);
    });

    testWidgets('should display zero balance correctly', (WidgetTester tester) async {
      mockGroup['totalBalance'] = 0.0;
      
      await tester.pumpWidget(createTestWidget());

      expect(find.text('\$0.00'), findsOneWidget);
      
      // Find the balance text widget
      final balanceText = tester.widget<Text>(find.text('\$0.00'));
      
      // Should be default color for zero balance
      expect(balanceText.style?.color, AppTheme.lightTheme.colorScheme.onSurface);
    });
  });
}