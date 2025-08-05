import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sizer/sizer.dart';

import '../../../lib/presentation/group_management/group_management.dart';
import '../../../lib/presentation/group_management/widgets/create_group_modal_widget.dart';
import '../../../lib/models/group.dart';
import '../../../lib/services/group_service.dart';
import '../../../lib/routes/app_routes.dart';

class MockGroupService extends Mock implements GroupService {}

void main() {
  group('Group Creation Navigation Flow', () {
    late MockGroupService mockGroupService;

    setUp(() {
      mockGroupService = MockGroupService();
    });

    testWidgets('should show create group modal when FAB is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GroupManagement(),
        ),
      );

      // Wait for the widget to load
      await tester.pumpAndSettle();

      // Tap the floating action button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify the modal is shown
      expect(find.text('Create New Group'), findsOneWidget);
      expect(find.byType(CreateGroupModalWidget), findsOneWidget);
    });

    testWidgets('should show progress steps during group creation', (tester) async {
      // Mock successful group creation
      final mockGroup = Group(
        id: 1,
        name: 'Test Group',
        description: 'Test Description',
        currency: 'USD',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockGroupService.createGroup(any, any))
          .thenAnswer((_) async => mockGroup);

      await tester.pumpWidget(
        MaterialApp(
          home: GroupManagement(),
        ),
      );

      await tester.pumpAndSettle();

      // Open create group modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in group details
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Group Name'),
        'Test Group',
      );

      // Tap create button
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      // Verify progress steps are shown
      expect(find.text('Creating Group...'), findsOneWidget);
      expect(find.text('Creating your group...'), findsOneWidget);
      expect(find.text('Validating group details'), findsOneWidget);
      expect(find.text('Creating group'), findsOneWidget);
      expect(find.text('Sending invitations'), findsOneWidget);
      expect(find.text('Setting up group settings'), findsOneWidget);
    });

    testWidgets('should show success state after group creation', (tester) async {
      final mockGroup = Group(
        id: 1,
        name: 'Test Group',
        description: 'Test Description',
        currency: 'USD',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockGroupService.createGroup(any, any))
          .thenAnswer((_) async => mockGroup);

      await tester.pumpWidget(
        MaterialApp(
          home: GroupManagement(),
        ),
      );

      await tester.pumpAndSettle();

      // Open create group modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in group details
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Group Name'),
        'Test Group',
      );

      // Tap create button
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      // Wait for creation to complete
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Verify success state
      expect(find.text('Group Created!'), findsOneWidget);
      expect(find.text('Group Created Successfully!'), findsOneWidget);
      expect(find.text('Redirecting to your new group...'), findsOneWidget);
    });

    testWidgets('should show error state with retry options on failure', (tester) async {
      when(mockGroupService.createGroup(any, any))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        MaterialApp(
          home: GroupManagement(),
        ),
      );

      await tester.pumpAndSettle();

      // Open create group modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in group details
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Group Name'),
        'Test Group',
      );

      // Tap create button
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      // Wait for error to occur
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Verify error state
      expect(find.text('Creation Failed'), findsOneWidget);
      expect(find.text('Edit Details'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('should disable close button during creation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GroupManagement(),
        ),
      );

      await tester.pumpAndSettle();

      // Open create group modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in group details
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Group Name'),
        'Test Group',
      );

      // Tap create button
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      // Verify close button is disabled
      final closeButton = find.byIcon(Icons.close);
      expect(tester.widget<IconButton>(closeButton).onPressed, isNull);
    });

    testWidgets('should auto-navigate to group detail after successful creation', (tester) async {
      final mockGroup = Group(
        id: 1,
        name: 'Test Group',
        description: 'Test Description',
        currency: 'USD',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockGroupService.createGroup(any, any))
          .thenAnswer((_) async => mockGroup);

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (context) => GroupManagement(),
            AppRoutes.groupDetail: (context) => Scaffold(
              body: Text('Group Detail Page'),
            ),
          },
        ),
      );

      await tester.pumpAndSettle();

      // Open create group modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in group details
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Group Name'),
        'Test Group',
      );

      // Tap create button
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      // Wait for creation and navigation
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      // Verify navigation to group detail page
      expect(find.text('Group Detail Page'), findsOneWidget);
    });
  });
} 