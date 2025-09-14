import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:camsplit/models/group_detail_model.dart';
import 'package:camsplit/models/group_member.dart';
import 'package:camsplit/models/debt_relationship_model.dart';
import 'package:camsplit/presentation/group_detail/widgets/group_actions_widget.dart';
import 'package:camsplit/theme/app_theme.dart';

void main() {
  group('GroupActionsWidget Tests', () {
    late GroupDetailModel mockGroupDetail;
    late GroupDetailModel mockGroupDetailCannotDelete;

    setUp(() {
      // Mock group detail with basic permissions
      mockGroupDetail = GroupDetailModel(
        id: 1,
        name: 'Test Group',
        description: 'Test group description',
        imageUrl: null,
        members: [
          GroupMember(
            id: '1',
            name: 'John Doe',
            email: 'john@example.com',
            avatar: '',
            isCurrentUser: true,
            joinedAt: DateTime.now(),
          ),
          GroupMember(
            id: '2',
            name: 'Jane Smith',
            email: 'jane@example.com',
            avatar: '',
            isCurrentUser: false,
            joinedAt: DateTime.now(),
          ),
        ],
        expenses: [],
        debts: [],
        userBalance: 0.0,
        currency: 'USD',
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock group detail without delete permission
      mockGroupDetailCannotDelete = GroupDetailModel(
        id: 3,
        name: 'No Delete Permission',
        description: 'Test group without delete permission',
        imageUrl: null,
        members: [
          GroupMember(
            id: '1',
            name: 'John Doe',
            email: 'john@example.com',
            avatar: '',
            isCurrentUser: true,
            joinedAt: DateTime.now(),
          ),
        ],
        expenses: [],
        debts: [],
        userBalance: 25.0,
        currency: 'EUR',
        lastActivity: DateTime.now(),
        canEdit: false,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestWidget(GroupDetailModel groupDetail, {
      VoidCallback? onGroupUpdated,
      VoidCallback? onGroupDeleted,
    }) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: GroupActionsWidget(
                groupDetail: groupDetail,
                onGroupUpdated: onGroupUpdated,
                onGroupDeleted: onGroupDeleted,
              ),
            ),
          );
        },
      );
    }

    testWidgets('should display group actions title and handle bar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Verify title is displayed
      expect(find.text('Group Actions'), findsOneWidget);
      
      // Verify handle bar is present
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should display share group action', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Verify share action is displayed
      expect(find.text('Share Group'), findsOneWidget);
      
      // Verify share icon is present
      final shareListTile = find.ancestor(
        of: find.text('Share Group'),
        matching: find.byType(ListTile),
      );
      expect(shareListTile, findsOneWidget);
    });

    testWidgets('should display exit group action', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Verify exit action is displayed
      expect(find.text('Exit Group'), findsOneWidget);
      
      // Verify exit icon is present
      final exitListTile = find.ancestor(
        of: find.text('Exit Group'),
        matching: find.byType(ListTile),
      );
      expect(exitListTile, findsOneWidget);
    });

    testWidgets('should display delete group action when user has permission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Verify delete action is displayed
      expect(find.text('Delete Group'), findsOneWidget);
      
      // Verify delete icon is present
      final deleteListTile = find.ancestor(
        of: find.text('Delete Group'),
        matching: find.byType(ListTile),
      );
      expect(deleteListTile, findsOneWidget);
    });

    testWidgets('should not display delete group action when user lacks permission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetailCannotDelete));

      // Verify delete action is not displayed
      expect(find.text('Delete Group'), findsNothing);
    });

    testWidgets('should show exit confirmation dialog when exit group is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Tap exit group action
      await tester.tap(find.text('Exit Group'));
      await tester.pumpAndSettle();

      // Verify exit confirmation dialog is shown
      expect(find.text('Exit Group'), findsNWidgets(2)); // One in widget, one in dialog
      expect(find.textContaining('Are you sure you want to exit'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should close exit dialog when cancel is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Tap exit group action
      await tester.tap(find.text('Exit Group'));
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.textContaining('Are you sure you want to exit'), findsNothing);
    });

    testWidgets('should show delete confirmation dialog when delete group is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Tap delete group action
      await tester.tap(find.text('Delete Group'));
      await tester.pumpAndSettle();

      // Verify delete confirmation dialog is shown
      expect(find.text('Delete Group'), findsNWidgets(2)); // One in widget, one in dialog
      expect(find.textContaining('Are you sure you want to permanently delete'), findsOneWidget);
      expect(find.textContaining('This action cannot be undone'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should close delete dialog when cancel is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Tap delete group action
      await tester.tap(find.text('Delete Group'));
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.textContaining('Are you sure you want to permanently delete'), findsNothing);
    });

    testWidgets('should handle share group action tap', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Tap share group action
      await tester.tap(find.text('Share Group'));
      await tester.pumpAndSettle();

      // Note: We can't easily test the actual sharing functionality in unit tests
      // as it depends on platform-specific implementations. The test verifies
      // that the tap is handled without errors.
    });

    testWidgets('should apply correct styling to action tiles', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Verify ListTile widgets are present with correct styling
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(3)); // Share, Exit, Delete

      // Verify rounded border shape is applied
      for (int i = 0; i < 3; i++) {
        final listTile = tester.widget<ListTile>(listTiles.at(i));
        expect(listTile.shape, isA<RoundedRectangleBorder>());
      }
    });
  });
}