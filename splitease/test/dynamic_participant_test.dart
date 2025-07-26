import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/presentation/item_assignment/widgets/quantity_assignment_widget.dart';
import 'package:splitease/presentation/item_assignment/widgets/assignment_summary_widget.dart';

void main() {
  group('Dynamic Participant List Updates', () {
    testWidgets('QuantityAssignmentWidget handles member list changes', (WidgetTester tester) async {
      // Initial member list
      List<Map<String, dynamic>> initialMembers = [
        {'id': 1, 'name': 'Alice', 'avatar': 'avatar1.jpg'},
        {'id': 2, 'name': 'Bob', 'avatar': 'avatar2.jpg'},
      ];

      // Updated member list
      List<Map<String, dynamic>> updatedMembers = [
        {'id': 3, 'name': 'Charlie', 'avatar': 'avatar3.jpg'},
        {'id': 4, 'name': 'Diana', 'avatar': 'avatar4.jpg'},
      ];

      Map<String, dynamic> testItem = {
        'id': 1,
        'name': 'Test Item',
        'unit_price': 10.0,
        'originalQuantity': 2,
        'remainingQuantity': 2,
        'quantityAssignments': <Map<String, dynamic>>[],
      };

      // Build widget with initial members
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityAssignmentWidget(
              item: testItem,
              members: initialMembers,
              onQuantityAssigned: (assignment) {},
              onAssignmentRemoved: (assignment) {},
              isExpanded: true,
              onToggleExpanded: () {},
            ),
          ),
        ),
      );

      // Verify initial members are displayed
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Update with new members
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityAssignmentWidget(
              item: testItem,
              members: updatedMembers,
              onQuantityAssigned: (assignment) {},
              onAssignmentRemoved: (assignment) {},
              isExpanded: true,
              onToggleExpanded: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify new members are displayed and old ones are gone
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsNothing);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('Diana'), findsOneWidget);
    });

    testWidgets('AssignmentSummaryWidget handles member list changes', (WidgetTester tester) async {
      // Initial member list
      List<Map<String, dynamic>> initialMembers = [
        {'id': 1, 'name': 'Alice', 'avatar': 'avatar1.jpg'},
        {'id': 2, 'name': 'Bob', 'avatar': 'avatar2.jpg'},
      ];

      // Updated member list
      List<Map<String, dynamic>> updatedMembers = [
        {'id': 3, 'name': 'Charlie', 'avatar': 'avatar3.jpg'},
        {'id': 4, 'name': 'Diana', 'avatar': 'avatar4.jpg'},
      ];

      List<Map<String, dynamic>> testItems = [
        {
          'id': 1,
          'name': 'Test Item',
          'total_price': 20.0,
          'assignedMembers': <String>[],
        }
      ];

      // Build widget with initial members
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssignmentSummaryWidget(
              items: testItems,
              members: initialMembers,
              isEqualSplit: false,
              onToggleEqualSplit: () {},
              hasExistingAssignments: false,
            ),
          ),
        ),
      );

      // Verify initial members are displayed
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Update with new members
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AssignmentSummaryWidget(
              items: testItems,
              members: updatedMembers,
              isEqualSplit: false,
              onToggleEqualSplit: () {},
              hasExistingAssignments: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify new members are displayed and old ones are gone
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Bob'), findsNothing);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('Diana'), findsOneWidget);
    });

    test('Member ID validation after group change', () {
      // Simulate member list change
      List<Map<String, dynamic>> oldMembers = [
        {'id': 1, 'name': 'Alice', 'avatar': 'avatar1.jpg'},
        {'id': 2, 'name': 'Bob', 'avatar': 'avatar2.jpg'},
      ];

      List<Map<String, dynamic>> newMembers = [
        {'id': 3, 'name': 'Charlie', 'avatar': 'avatar3.jpg'},
        {'id': 4, 'name': 'Diana', 'avatar': 'avatar4.jpg'},
      ];

      // Simulate selected member IDs from old member list
      Set<String> selectedMemberIds = {'1', '2'};

      // Get new member IDs
      final newMemberIds = newMembers.map((m) => m['id'].toString()).toSet();

      // Remove invalid member IDs (simulating didUpdateWidget logic)
      selectedMemberIds.removeWhere((memberId) => !newMemberIds.contains(memberId));

      // Verify that old member IDs are removed
      expect(selectedMemberIds.isEmpty, true);

      // Add new member IDs
      selectedMemberIds.addAll(['3', '4']);

      // Verify new member IDs are valid
      expect(selectedMemberIds.contains('3'), true);
      expect(selectedMemberIds.contains('4'), true);
      expect(selectedMemberIds.contains('1'), false);
      expect(selectedMemberIds.contains('2'), false);
    });
  });
}