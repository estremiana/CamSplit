import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:splitease/presentation/group_detail/widgets/group_header_widget.dart';
import 'package:splitease/models/group_detail_model.dart';
import 'package:splitease/models/group_member.dart';
import 'package:splitease/models/debt_relationship_model.dart';
import 'package:splitease/theme/app_theme.dart';

void main() {
  group('GroupHeaderWidget Tests', () {
    late GroupDetailModel testGroupDetail;

    setUp(() {
      final testMember = GroupMember(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatar: 'avatar.jpg',
        isCurrentUser: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      testGroupDetail = GroupDetailModel(
        id: 1,
        name: 'Test Group',
        description: 'A test group for unit testing',
        imageUrl: 'https://example.com/group.jpg',
        members: [testMember],
        expenses: [],
        debts: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
    });

    Widget createTestWidget(GroupDetailModel groupDetail) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: GroupHeaderWidget(groupDetail: groupDetail),
            ),
          );
        },
      );
    }

    testWidgets('should display group name correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testGroupDetail));

      expect(find.text('Test Group'), findsOneWidget);
    });

    testWidgets('should display group description correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testGroupDetail));

      expect(find.text('A test group for unit testing'), findsOneWidget);
    });

    testWidgets('should display "No description" when description is empty', (WidgetTester tester) async {
      final groupWithoutDescription = GroupDetailModel(
        id: 1,
        name: 'Test Group',
        description: '',
        members: testGroupDetail.members,
        expenses: [],
        debts: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(groupWithoutDescription));

      expect(find.text('No description'), findsOneWidget);
    });

    testWidgets('should display correct member count for single member', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testGroupDetail));

      expect(find.text('1 member'), findsOneWidget);
    });

    testWidgets('should display correct member count for multiple members', (WidgetTester tester) async {
      final multiMemberGroup = GroupDetailModel(
        id: 1,
        name: 'Test Group',
        description: 'Test description',
        members: [
          GroupMember(
            id: '1',
            name: 'User 1',
            email: 'user1@example.com',
            avatar: 'avatar1.jpg',
            isCurrentUser: true,
            joinedAt: DateTime.now(),
          ),
          GroupMember(
            id: '2',
            name: 'User 2',
            email: 'user2@example.com',
            avatar: 'avatar2.jpg',
            isCurrentUser: false,
            joinedAt: DateTime.now(),
          ),
          GroupMember(
            id: '3',
            name: 'User 3',
            email: 'user3@example.com',
            avatar: 'avatar3.jpg',
            isCurrentUser: false,
            joinedAt: DateTime.now(),
          ),
        ],
        expenses: [],
        debts: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(multiMemberGroup));

      expect(find.text('3 members'), findsOneWidget);
    });

    testWidgets('should display "Just now" for very recent activity', (WidgetTester tester) async {
      final recentActivityGroup = GroupDetailModel(
        id: 1,
        name: 'Test Group',
        description: 'Test description',
        members: testGroupDetail.members,
        expenses: [],
        debts: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now().subtract(const Duration(seconds: 30)),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(recentActivityGroup));

      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('should display minutes ago for recent activity', (WidgetTester tester) async {
      final minutesAgoGroup = GroupDetailModel(
        id: 1,
        name: 'Test Group',
        description: 'Test description',
        members: testGroupDetail.members,
        expenses: [],
        debts: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now().subtract(const Duration(minutes: 15)),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(minutesAgoGroup));

      expect(find.text('15m ago'), findsOneWidget);
    });

    testWidgets('should display hours ago for activity within a day', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testGroupDetail));

      expect(find.text('2h ago'), findsOneWidget);
    });

    testWidgets('should display days ago for older activity', (WidgetTester tester) async {
      final daysAgoGroup = GroupDetailModel(
        id: 1,
        name: 'Test Group',
        description: 'Test description',
        members: testGroupDetail.members,
        expenses: [],
        debts: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now().subtract(const Duration(days: 3)),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(daysAgoGroup));

      expect(find.text('3d ago'), findsOneWidget);
    });

    testWidgets('should display fallback icon when no image URL is provided', (WidgetTester tester) async {
      final groupWithoutImage = GroupDetailModel(
        id: 1,
        name: 'Test Group',
        description: 'Test description',
        imageUrl: null,
        members: testGroupDetail.members,
        expenses: [],
        debts: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(groupWithoutImage));

      // Verify that the CircleAvatar is present (fallback icon container)
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('should display group image when URL is provided', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testGroupDetail));

      // Verify that the CircleAvatar is present (image container)
      expect(find.byType(CircleAvatar), findsOneWidget);
      // Verify that ClipOval is present (image clipping)
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('should have proper card styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testGroupDetail));

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);

      final Card card = tester.widget(cardFinder);
      expect(card.elevation, 1.0);
      expect(card.color, AppTheme.lightTheme.cardColor);
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('should handle long group names with ellipsis', (WidgetTester tester) async {
      final longNameGroup = GroupDetailModel(
        id: 1,
        name: 'This is a very long group name that should be truncated with ellipsis',
        description: 'Test description',
        members: testGroupDetail.members,
        expenses: [],
        debts: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(longNameGroup));

      final textFinder = find.text('This is a very long group name that should be truncated with ellipsis');
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget(textFinder);
      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should handle long descriptions with ellipsis', (WidgetTester tester) async {
      final longDescriptionGroup = GroupDetailModel(
        id: 1,
        name: 'Test Group',
        description: 'This is a very long description that should be truncated with ellipsis when it exceeds the maximum number of lines allowed for the description text widget',
        members: testGroupDetail.members,
        expenses: [],
        debts: [],
        userBalance: 0.00,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(longDescriptionGroup));

      final textFinder = find.text('This is a very long description that should be truncated with ellipsis when it exceeds the maximum number of lines allowed for the description text widget');
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget(textFinder);
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should display group and schedule icons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testGroupDetail));

      // Should find multiple group icons (one for avatar fallback, one for member count)
      // and one schedule icon for last activity
      expect(find.byType(Icon), findsAtLeastNWidgets(2));
    });

    testWidgets('should use correct text styles from theme', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(testGroupDetail));

      // Find the group name text widget
      final groupNameFinder = find.text('Test Group');
      expect(groupNameFinder, findsOneWidget);

      final Text groupNameWidget = tester.widget(groupNameFinder);
      expect(groupNameWidget.style?.fontWeight, FontWeight.w600);

      // Find the description text widget
      final descriptionFinder = find.text('A test group for unit testing');
      expect(descriptionFinder, findsOneWidget);

      final Text descriptionWidget = tester.widget(descriptionFinder);
      expect(descriptionWidget.style?.color, AppTheme.lightTheme.colorScheme.onSurfaceVariant);
    });
  });
}