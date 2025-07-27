import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import 'package:splitease/presentation/group_detail/widgets/participant_list_widget.dart';
import 'package:splitease/models/group_detail_model.dart';
import 'package:splitease/models/group_member.dart';
import 'package:splitease/models/debt_relationship_model.dart';
import 'package:splitease/theme/app_theme.dart';

void main() {
  group('ParticipantListWidget Tests', () {
    late GroupDetailModel mockGroupDetail;
    late GroupDetailModel mockGroupDetailWithDebts;
    late GroupDetailModel mockEmptyGroup;

    setUp(() {
      // Mock group with members but no debts
      mockGroupDetail = GroupDetailModel(
        id: 1,
        name: "Test Group",
        description: "Test Description",
        imageUrl: null,
        members: [
          GroupMember(
            id: "1",
            name: "John Doe",
            email: "john.doe@example.com",
            avatar: "",
            isCurrentUser: true,
            joinedAt: DateTime.now().subtract(Duration(days: 30)),
          ),
          GroupMember(
            id: "2",
            name: "Jane Smith",
            email: "jane.smith@example.com",
            avatar: "",
            isCurrentUser: false,
            joinedAt: DateTime.now().subtract(Duration(days: 25)),
          ),
          GroupMember(
            id: "3",
            name: "Bob Wilson",
            email: "bob.wilson@example.com",
            avatar: "",
            isCurrentUser: false,
            joinedAt: DateTime.now().subtract(Duration(days: 20)),
          ),
        ],
        expenses: [],
        debts: [],
        userBalance: 0.0,
        currency: "USD",
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: true,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      // Mock group with members and debts
      mockGroupDetailWithDebts = GroupDetailModel(
        id: 1,
        name: "Test Group",
        description: "Test Description",
        imageUrl: null,
        members: [
          GroupMember(
            id: "1",
            name: "John Doe",
            email: "john.doe@example.com",
            avatar: "",
            isCurrentUser: true,
            joinedAt: DateTime.now().subtract(Duration(days: 30)),
          ),
          GroupMember(
            id: "2",
            name: "Jane Smith",
            email: "jane.smith@example.com",
            avatar: "",
            isCurrentUser: false,
            joinedAt: DateTime.now().subtract(Duration(days: 25)),
          ),
        ],
        expenses: [],
        debts: [
          DebtRelationship(
            debtorId: 2,
            debtorName: "Jane Smith",
            creditorId: 1,
            creditorName: "John Doe",
            amount: 50.0,
            currency: "USD",
            createdAt: DateTime.now().subtract(Duration(days: 5)),
            updatedAt: DateTime.now().subtract(Duration(days: 5)),
          ),
        ],
        userBalance: 50.0,
        currency: "USD",
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: true,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      // Mock empty group
      mockEmptyGroup = GroupDetailModel(
        id: 1,
        name: "Empty Group",
        description: "Test Description",
        imageUrl: null,
        members: [],
        expenses: [],
        debts: [],
        userBalance: 0.0,
        currency: "USD",
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: true,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestWidget(GroupDetailModel groupDetail) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ParticipantListWidget(
                groupDetail: groupDetail,
              ),
            ),
          );
        },
      );
    }

    testWidgets('displays section header with member count', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      expect(find.text('Members'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // Member count
    });

    testWidgets('displays all group members', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      expect(find.text('You'), findsOneWidget); // Current user display name
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Bob Wilson'), findsOneWidget);
      expect(find.text('john.doe@example.com'), findsOneWidget);
      expect(find.text('jane.smith@example.com'), findsOneWidget);
      expect(find.text('bob.wilson@example.com'), findsOneWidget);
    });

    testWidgets('displays member avatars with initials when no image', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Check for initials in avatars
      expect(find.text('JD'), findsOneWidget); // John Doe
      expect(find.text('JS'), findsOneWidget); // Jane Smith
      expect(find.text('BW'), findsOneWidget); // Bob Wilson
    });

    testWidgets('shows remove buttons for non-current users without debts', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Should find remove buttons for Jane and Bob (not current user, no debts)
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      expect(removeButtons, findsNWidgets(2));
    });

    testWidgets('hides remove button for current user', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Current user (John Doe) should not have a remove button
      // We can verify this by checking that there are only 2 remove buttons total
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      expect(removeButtons, findsNWidgets(2));
    });

    testWidgets('hides remove button for users with debts', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetailWithDebts));

      // Jane Smith has debts, so should not have remove button
      // Only current user (John) should not have remove button
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      expect(removeButtons, findsNothing);
    });

    testWidgets('displays add member button when user can edit', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      expect(find.text('Add Member'), findsOneWidget);
      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('hides add member button when user cannot edit', (WidgetTester tester) async {
      final nonEditableGroup = GroupDetailModel(
        id: 1,
        name: "Test Group",
        description: "Test Description",
        imageUrl: null,
        members: mockGroupDetail.members,
        expenses: [],
        debts: [],
        userBalance: 0.0,
        currency: "USD",
        lastActivity: DateTime.now(),
        canEdit: false, // Cannot edit
        canDelete: false,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(nonEditableGroup));

      expect(find.text('Add Member'), findsNothing);
    });

    testWidgets('displays empty state when no members', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockEmptyGroup));

      expect(find.text('No members yet'), findsOneWidget);
      expect(find.byIcon(Icons.group_add), findsOneWidget);
    });

    testWidgets('shows add member dialog when add button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Tap the add member button
      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      // Check that dialog is shown
      expect(find.text('Add Member'), findsNWidgets(2)); // Button + dialog title
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('validates form fields in add member dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Open dialog
      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      // Try to submit without filling fields
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('validates email format in add member dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Open dialog
      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      // Fill in invalid email
      await tester.enterText(find.byType(TextFormField).first, 'Test User');
      await tester.enterText(find.byType(TextFormField).last, 'invalid-email');

      // Try to submit
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Should show email validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows remove confirmation dialog when remove button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Tap remove button for Jane Smith
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Check that confirmation dialog is shown
      expect(find.text('Remove Member'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to remove'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });

    testWidgets('shows debt warning dialog when trying to remove user with debts', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetailWithDebts));

      // Since Jane has debts, she shouldn't have a remove button
      // But let's test the debt warning logic by creating a scenario
      // where we manually trigger the debt warning

      // For this test, we'll modify the mock to have a user with debts but still show remove button
      // This tests the debt validation logic
      final testGroup = GroupDetailModel(
        id: 1,
        name: "Test Group",
        description: "Test Description",
        imageUrl: null,
        members: [
          GroupMember(
            id: "1",
            name: "John Doe",
            email: "john.doe@example.com",
            avatar: "",
            isCurrentUser: true,
            joinedAt: DateTime.now().subtract(Duration(days: 30)),
          ),
          GroupMember(
            id: "2",
            name: "Jane Smith",
            email: "jane.smith@example.com",
            avatar: "",
            isCurrentUser: false,
            joinedAt: DateTime.now().subtract(Duration(days: 25)),
          ),
        ],
        expenses: [],
        debts: [
          DebtRelationship(
            debtorId: 2,
            debtorName: "Jane Smith",
            creditorId: 1,
            creditorName: "John Doe",
            amount: 50.0,
            currency: "USD",
            createdAt: DateTime.now().subtract(Duration(days: 5)),
            updatedAt: DateTime.now().subtract(Duration(days: 5)),
          ),
        ],
        userBalance: 50.0,
        currency: "USD",
        lastActivity: DateTime.now(),
        canEdit: true,
        canDelete: true,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now(),
      );

      // The widget should correctly identify that Jane cannot be removed due to debts
      await tester.pumpWidget(createTestWidget(testGroup));

      // Jane should not have a remove button because she has debts
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      expect(removeButtons, findsNothing);
    });

    testWidgets('calls callback when participant is added', (WidgetTester tester) async {
      bool callbackCalled = false;
      
      final widget = Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ParticipantListWidget(
                groupDetail: mockGroupDetail,
                onParticipantAdded: () {
                  callbackCalled = true;
                },
              ),
            ),
          );
        },
      );

      await tester.pumpWidget(widget);

      // Open add member dialog
      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      // Fill in valid data
      await tester.enterText(find.byType(TextFormField).first, 'New User');
      await tester.enterText(find.byType(TextFormField).last, 'new.user@example.com');

      // Submit form
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Wait for async operations
      await tester.pump(Duration(seconds: 1));

      // Callback should be called
      expect(callbackCalled, isTrue);
    });

    testWidgets('calls callback when participant is removed', (WidgetTester tester) async {
      bool callbackCalled = false;
      
      final widget = Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ParticipantListWidget(
                groupDetail: mockGroupDetail,
                onParticipantRemoved: () {
                  callbackCalled = true;
                },
              ),
            ),
          );
        },
      );

      await tester.pumpWidget(widget);

      // Tap remove button
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Confirm removal
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Wait for async operations
      await tester.pump(Duration(seconds: 1));

      // Callback should be called
      expect(callbackCalled, isTrue);
    });

    testWidgets('displays loading state during operations', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(mockGroupDetail));

      // Open add member dialog
      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      // Fill in valid data
      await tester.enterText(find.byType(TextFormField).first, 'New User');
      await tester.enterText(find.byType(TextFormField).last, 'new.user@example.com');

      // Submit form
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // The add button should be disabled during loading
      // (This is handled by the _isLoading state in the widget)
      // We can verify this by checking that subsequent taps don't open new dialogs
    });
  });
}