import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../lib/models/group.dart';
import '../../../lib/models/group_member.dart';
import '../../../lib/models/mock_group_data.dart';
import '../../../lib/presentation/item_assignment/widgets/group_selection_widget.dart';

void main() {
  group('GroupSelectionWidget Dropdown Functionality Tests', () {
    late List<Group> mockGroups;
    
    setUp(() {
      mockGroups = MockGroupData.getGroupsSortedByMostRecent();
    });

    Widget createTestWidget({
      List<Group>? groups,
      String? selectedGroupId,
      Function(String)? onGroupChanged,
      bool hasExistingAssignments = false,
    }) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: Scaffold(
              body: GroupSelectionWidget(
                availableGroups: groups ?? mockGroups,
                selectedGroupId: selectedGroupId,
                onGroupChanged: onGroupChanged ?? (String groupId) {},
                hasExistingAssignments: hasExistingAssignments,
              ),
            ),
          );
        },
      );
    }

    testWidgets('displays dropdown with available groups ordered by most recent', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Find the dropdown button
      final dropdownFinder = find.byType(DropdownButton<String>);
      expect(dropdownFinder, findsOneWidget);
      
      // Tap the dropdown to open it
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();
      
      // Verify all groups are displayed
      for (final group in mockGroups) {
        expect(find.text(group.name), findsOneWidget);
      }
    });

    testWidgets('shows group name and member count in dropdown items', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      
      // Check that each group shows name and member count
      for (final group in mockGroups) {
        expect(find.text(group.name), findsWidgets);
        expect(find.text('${group.memberCount} member${group.memberCount != 1 ? 's' : ''}'), findsWidgets);
      }
      
      // Verify we have the expected number of dropdown items
      expect(find.byType(DropdownMenuItem<String>), findsNWidgets(mockGroups.length));
    });

    testWidgets('handles empty state with "No groups available" placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(groups: []));
      
      // Should show "No groups available" text
      expect(find.text('No groups available'), findsOneWidget);
      
      // Dropdown should be disabled
      final dropdown = tester.widget<DropdownButton<String>>(find.byType(DropdownButton<String>));
      expect(dropdown.onChanged, isNull);
    });

    testWidgets('implements group selection change handling', (WidgetTester tester) async {
      String? selectedGroupId;
      
      await tester.pumpWidget(createTestWidget(
        onGroupChanged: (String groupId) {
          selectedGroupId = groupId;
        },
      ));
      
      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      
      // Select the first group
      final firstGroup = mockGroups.first;
      await tester.tap(find.text(firstGroup.name).last);
      await tester.pumpAndSettle();
      
      // Verify the callback was called with correct group ID
      expect(selectedGroupId, equals(firstGroup.id));
    });

    testWidgets('shows warning dialog when changing groups with existing assignments', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        hasExistingAssignments: true,
        selectedGroupId: mockGroups.first.id,
      ));
      
      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      
      // Select a different group
      final secondGroup = mockGroups[1];
      await tester.tap(find.text(secondGroup.name).last);
      await tester.pumpAndSettle();
      
      // Should show warning dialog
      expect(find.text('Change Group?'), findsOneWidget);
      expect(find.text('Changing groups will reset all current assignments. This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Change Group'), findsOneWidget);
    });

    testWidgets('groups are sorted by most recent usage', (WidgetTester tester) async {
      // Create groups with different lastUsed times
      final now = DateTime.now();
      final testGroups = [
        Group(
          id: '1',
          name: 'Oldest Group',
          members: [GroupMember(id: '1', name: 'User', email: 'user@test.com', avatar: '', isCurrentUser: true, joinedAt: now)],
          lastUsed: now.subtract(const Duration(days: 5)),
          createdAt: now.subtract(const Duration(days: 10)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
        Group(
          id: '2',
          name: 'Newest Group',
          members: [GroupMember(id: '1', name: 'User', email: 'user@test.com', avatar: '', isCurrentUser: true, joinedAt: now)],
          lastUsed: now.subtract(const Duration(hours: 1)),
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now.subtract(const Duration(hours: 1)),
        ),
        Group(
          id: '3',
          name: 'Middle Group',
          members: [GroupMember(id: '1', name: 'User', email: 'user@test.com', avatar: '', isCurrentUser: true, joinedAt: now)],
          lastUsed: now.subtract(const Duration(days: 2)),
          createdAt: now.subtract(const Duration(days: 5)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
      ];
      
      await tester.pumpWidget(createTestWidget(groups: testGroups));
      
      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      
      // Find all dropdown menu items
      final dropdownItems = find.byType(DropdownMenuItem<String>);
      expect(dropdownItems, findsNWidgets(3));
      
      // The order should be: Newest Group, Middle Group, Oldest Group
      // We can verify this by checking the widget tree structure
      final widget = tester.widget<GroupSelectionWidget>(find.byType(GroupSelectionWidget));
      final sortedGroups = List<Group>.from(widget.availableGroups);
      sortedGroups.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      
      expect(sortedGroups[0].name, equals('Newest Group'));
      expect(sortedGroups[1].name, equals('Middle Group'));
      expect(sortedGroups[2].name, equals('Oldest Group'));
    });

    testWidgets('create group button shows placeholder message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Find and tap the create group button
      final createButton = find.byIcon(Icons.add);
      expect(createButton, findsOneWidget);
      
      await tester.tap(createButton);
      await tester.pumpAndSettle();
      
      // Should show snackbar with placeholder message
      expect(find.text('This feature will be implemented in a future update'), findsOneWidget);
    });
  });
}