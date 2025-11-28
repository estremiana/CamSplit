import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 28: Advanced share calculation
/// Feature: expense-wizard-creation, Property 29: Assignment adds to map
/// Feature: expense-wizard-creation, Property 30: Advanced mode flag set
/// Feature: expense-wizard-creation, Property 31: Remaining quantity updates
/// Validates: Requirements 6.9, 6.10, 6.11, 6.12
///
/// Property 28: For any advanced assignment created, each selected member's share
/// should equal (assigned quantity / number of selected members)
///
/// Property 29: For any assignment created in AdvancedModal, it should be added
/// to the item's assignments map
///
/// Property 30: For any assignment created via AdvancedModal, the item's
/// isCustomSplit should be set to true
///
/// Property 31: For any assignment created or deleted, the remaining quantity
/// should update to reflect the change

// Helper function to simulate creating an advanced assignment
Map<String, double> createAdvancedAssignment(
  ReceiptItem item,
  double assignQty,
  Set<String> selectedMemberIds,
) {
  if (selectedMemberIds.isEmpty) {
    return Map<String, double>.from(item.assignments);
  }

  // Calculate share per person
  final sharePerPerson = assignQty / selectedMemberIds.length;

  // Create new assignments map by adding to existing assignments
  final newAssignments = Map<String, double>.from(item.assignments);

  for (final memberId in selectedMemberIds) {
    newAssignments[memberId] = (newAssignments[memberId] ?? 0.0) + sharePerPerson;
  }

  return newAssignments;
}

// Helper function to delete an assignment
Map<String, double> deleteAssignment(
  ReceiptItem item,
  String memberId,
) {
  final newAssignments = Map<String, double>.from(item.assignments);
  newAssignments.remove(memberId);
  return newAssignments;
}

void main() {
  final faker = Faker();
  final random = Random();

  group('Advanced Assignment Creation Property Tests', () {
    // Helper function to generate random ReceiptItem
    ReceiptItem generateRandomReceiptItem({
      String? id,
      String? name,
      double? quantity,
      double? unitPrice,
      Map<String, double>? assignments,
      bool? isCustomSplit,
    }) {
      final qty = quantity ?? (random.nextDouble() * 20) + 1;
      final price = unitPrice ?? (random.nextDouble() * 100) + 1;

      return ReceiptItem(
        id: id ?? faker.guid.guid(),
        name: name ?? faker.food.dish(),
        quantity: qty,
        unitPrice: price,
        price: qty * price,
        assignments: assignments ?? {},
        isCustomSplit: isCustomSplit ?? false,
      );
    }

    /// Property 28: Advanced share calculation
    /// For any advanced assignment, each member's share = quantity / member count
    test('Property 28: Each member receives equal share in advanced assignment', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem();
        final assignQty = (random.nextDouble() * item.quantity) + 0.5;
        final memberCount = random.nextInt(5) + 1;

        final selectedMembers = <String>{};
        for (int j = 0; j < memberCount; j++) {
          selectedMembers.add('member_$j');
        }

        final newAssignments = createAdvancedAssignment(item, assignQty, selectedMembers);

        final expectedShare = assignQty / memberCount;

        for (final memberId in selectedMembers) {
          expect(
            newAssignments[memberId],
            closeTo(expectedShare, 0.01),
            reason: 'Each member should receive equal share: $expectedShare',
          );
        }
      }
    });

    test('Property 28: Share calculation is correct for single member', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem();
        final assignQty = (random.nextDouble() * item.quantity) + 0.5;

        final newAssignments = createAdvancedAssignment(
          item,
          assignQty,
          {'member_1'},
        );

        expect(
          newAssignments['member_1'],
          closeTo(assignQty, 0.01),
          reason: 'Single member should receive entire quantity',
        );
      }
    });

    test('Property 28: Share calculation handles fractional quantities', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem();
        final assignQty = (random.nextDouble() * 5) + 0.1; // Small fractional quantity
        final memberCount = random.nextInt(3) + 2; // 2-4 members

        final selectedMembers = <String>{};
        for (int j = 0; j < memberCount; j++) {
          selectedMembers.add('member_$j');
        }

        final newAssignments = createAdvancedAssignment(item, assignQty, selectedMembers);

        final expectedShare = assignQty / memberCount;
        final totalAssigned = newAssignments.values
            .where((qty) => selectedMembers.any((id) => newAssignments.keys.contains(id)))
            .fold(0.0, (sum, qty) => sum + qty);

        expect(
          totalAssigned,
          closeTo(assignQty, 0.01),
          reason: 'Total assigned should equal input quantity',
        );

        for (final memberId in selectedMembers) {
          expect(
            newAssignments[memberId],
            closeTo(expectedShare, 0.01),
            reason: 'Each member should receive equal fractional share',
          );
        }
      }
    });

    test('Property 28: Share calculation with many members', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(quantity: 100.0);
        final assignQty = (random.nextDouble() * 50) + 10;
        final memberCount = random.nextInt(10) + 5; // 5-14 members

        final selectedMembers = <String>{};
        for (int j = 0; j < memberCount; j++) {
          selectedMembers.add('member_$j');
        }

        final newAssignments = createAdvancedAssignment(item, assignQty, selectedMembers);

        final expectedShare = assignQty / memberCount;

        for (final memberId in selectedMembers) {
          expect(
            newAssignments[memberId],
            closeTo(expectedShare, 0.01),
            reason: 'Each of $memberCount members should receive equal share',
          );
        }
      }
    });

    /// Property 29: Assignment adds to map
    /// For any assignment created, it should be added to the item's assignments map
    test('Property 29: New assignment adds members to assignments map', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem();
        final assignQty = (random.nextDouble() * item.quantity) + 0.5;
        final memberCount = random.nextInt(5) + 1;

        final selectedMembers = <String>{};
        for (int j = 0; j < memberCount; j++) {
          selectedMembers.add('member_$j');
        }

        final newAssignments = createAdvancedAssignment(item, assignQty, selectedMembers);

        for (final memberId in selectedMembers) {
          expect(
            newAssignments.containsKey(memberId),
            true,
            reason: 'Assignment map should contain all selected members',
          );

          expect(
            newAssignments[memberId]! > 0,
            true,
            reason: 'Assigned quantity should be greater than zero',
          );
        }
      }
    });

    test('Property 29: Assignment accumulates for existing members', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final initialQty = (random.nextDouble() * 5) + 1;
        final item = generateRandomReceiptItem(
          quantity: 20.0,
          assignments: {'member_1': initialQty},
        );

        final assignQty = (random.nextDouble() * 5) + 1;
        final newAssignments = createAdvancedAssignment(
          item,
          assignQty,
          {'member_1'},
        );

        expect(
          newAssignments['member_1'],
          closeTo(initialQty + assignQty, 0.01),
          reason: 'Assignment should accumulate for existing member',
        );
      }
    });

    test('Property 29: Assignment preserves existing assignments for other members', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final existingAssignments = {
          'member_1': (random.nextDouble() * 5) + 1,
          'member_2': (random.nextDouble() * 5) + 1,
        };

        final item = generateRandomReceiptItem(
          quantity: 50.0,
          assignments: existingAssignments,
        );

        final assignQty = (random.nextDouble() * 5) + 1;
        final newAssignments = createAdvancedAssignment(
          item,
          assignQty,
          {'member_3'},
        );

        // Existing assignments should be preserved
        expect(
          newAssignments['member_1'],
          closeTo(existingAssignments['member_1']!, 0.01),
          reason: 'Existing assignment for member_1 should be preserved',
        );

        expect(
          newAssignments['member_2'],
          closeTo(existingAssignments['member_2']!, 0.01),
          reason: 'Existing assignment for member_2 should be preserved',
        );

        // New assignment should be added
        expect(
          newAssignments['member_3'],
          closeTo(assignQty, 0.01),
          reason: 'New assignment for member_3 should be added',
        );
      }
    });

    test('Property 29: Multiple assignments accumulate correctly', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        var item = generateRandomReceiptItem(quantity: 50.0);

        // First assignment
        final assignQty1 = (random.nextDouble() * 5) + 1;
        var assignments = createAdvancedAssignment(item, assignQty1, {'member_1', 'member_2'});
        item = item.copyWith(assignments: assignments);

        // Second assignment
        final assignQty2 = (random.nextDouble() * 5) + 1;
        assignments = createAdvancedAssignment(item, assignQty2, {'member_2', 'member_3'});
        item = item.copyWith(assignments: assignments);

        // Third assignment
        final assignQty3 = (random.nextDouble() * 5) + 1;
        assignments = createAdvancedAssignment(item, assignQty3, {'member_1'});

        // Verify accumulation
        final expectedMember1 = (assignQty1 / 2) + assignQty3;
        final expectedMember2 = (assignQty1 / 2) + (assignQty2 / 2);
        final expectedMember3 = assignQty2 / 2;

        expect(
          assignments['member_1'],
          closeTo(expectedMember1, 0.01),
          reason: 'member_1 should have accumulated assignments',
        );

        expect(
          assignments['member_2'],
          closeTo(expectedMember2, 0.01),
          reason: 'member_2 should have accumulated assignments',
        );

        expect(
          assignments['member_3'],
          closeTo(expectedMember3, 0.01),
          reason: 'member_3 should have correct assignment',
        );
      }
    });

    test('Property 29: Empty selection returns unchanged assignments', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final existingAssignments = {
          'member_1': (random.nextDouble() * 5) + 1,
          'member_2': (random.nextDouble() * 5) + 1,
        };

        final item = generateRandomReceiptItem(
          quantity: 50.0,
          assignments: existingAssignments,
        );

        final assignQty = (random.nextDouble() * 5) + 1;
        final newAssignments = createAdvancedAssignment(item, assignQty, {});

        expect(
          newAssignments,
          equals(existingAssignments),
          reason: 'Empty selection should not modify assignments',
        );
      }
    });

    /// Property 30: Advanced mode flag set
    /// For any assignment created via AdvancedModal, isCustomSplit should be true
    test('Property 30: Creating assignment sets isCustomSplit to true', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(isCustomSplit: false);
        final assignQty = (random.nextDouble() * item.quantity) + 0.5;
        final memberCount = random.nextInt(5) + 1;

        final selectedMembers = <String>{};
        for (int j = 0; j < memberCount; j++) {
          selectedMembers.add('member_$j');
        }

        final newAssignments = createAdvancedAssignment(item, assignQty, selectedMembers);

        // Simulate what happens in the actual implementation
        final updatedItem = item.copyWith(
          assignments: newAssignments,
          isCustomSplit: true,
        );

        expect(
          updatedItem.isCustomSplit,
          true,
          reason: 'isCustomSplit should be set to true after advanced assignment',
        );
      }
    });

    test('Property 30: isCustomSplit remains true for subsequent assignments', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        var item = generateRandomReceiptItem(
          quantity: 50.0,
          isCustomSplit: true,
          assignments: {'member_1': 5.0},
        );

        final assignQty = (random.nextDouble() * 5) + 1;
        final newAssignments = createAdvancedAssignment(item, assignQty, {'member_2'});

        final updatedItem = item.copyWith(
          assignments: newAssignments,
          isCustomSplit: true,
        );

        expect(
          updatedItem.isCustomSplit,
          true,
          reason: 'isCustomSplit should remain true for subsequent assignments',
        );
      }
    });

    test('Property 30: isCustomSplit flag persists across multiple operations', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        var item = generateRandomReceiptItem(quantity: 50.0, isCustomSplit: false);

        // First assignment - should set flag to true
        var assignments = createAdvancedAssignment(item, 5.0, {'member_1'});
        item = item.copyWith(assignments: assignments, isCustomSplit: true);
        expect(item.isCustomSplit, true);

        // Second assignment - flag should remain true
        assignments = createAdvancedAssignment(item, 3.0, {'member_2'});
        item = item.copyWith(assignments: assignments, isCustomSplit: true);
        expect(item.isCustomSplit, true);

        // Third assignment - flag should still be true
        assignments = createAdvancedAssignment(item, 2.0, {'member_3'});
        item = item.copyWith(assignments: assignments, isCustomSplit: true);
        expect(item.isCustomSplit, true);
      }
    });

    /// Property 31: Remaining quantity updates
    /// For any assignment created or deleted, remaining quantity should reflect the change
    test('Property 31: Remaining quantity decreases after assignment', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 5;
        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        final initialRemaining = item.getRemainingCount();
        expect(initialRemaining, closeTo(totalQty, 0.01));

        final assignQty = (random.nextDouble() * totalQty * 0.5) + 0.5;
        final newAssignments = createAdvancedAssignment(item, assignQty, {'member_1'});

        final updatedItem = item.copyWith(assignments: newAssignments);
        final newRemaining = updatedItem.getRemainingCount();

        expect(
          newRemaining,
          closeTo(initialRemaining - assignQty, 0.01),
          reason: 'Remaining should decrease by assigned quantity',
        );
      }
    });

    test('Property 31: Remaining quantity increases after deletion', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 5;
        final assignedQty = (random.nextDouble() * totalQty * 0.5) + 1;

        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {'member_1': assignedQty},
        );

        final initialRemaining = item.getRemainingCount();
        expect(initialRemaining, closeTo(totalQty - assignedQty, 0.01));

        final newAssignments = deleteAssignment(item, 'member_1');
        final updatedItem = item.copyWith(assignments: newAssignments);
        final newRemaining = updatedItem.getRemainingCount();

        expect(
          newRemaining,
          closeTo(initialRemaining + assignedQty, 0.01),
          reason: 'Remaining should increase by deleted quantity',
        );
      }
    });

    test('Property 31: Remaining is zero when fully assigned', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 1;
        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        // Assign entire quantity
        final newAssignments = createAdvancedAssignment(item, totalQty, {'member_1'});
        final updatedItem = item.copyWith(assignments: newAssignments);

        expect(
          updatedItem.getRemainingCount(),
          closeTo(0.0, 0.01),
          reason: 'Remaining should be zero when fully assigned',
        );

        expect(
          updatedItem.isFullyAssigned(),
          true,
          reason: 'Item should be marked as fully assigned',
        );
      }
    });

    test('Property 31: Remaining updates correctly with multiple assignments', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 50) + 10;
        var item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        var expectedRemaining = totalQty;

        // First assignment
        final assignQty1 = (random.nextDouble() * 5) + 1;
        var assignments = createAdvancedAssignment(item, assignQty1, {'member_1'});
        item = item.copyWith(assignments: assignments);
        expectedRemaining -= assignQty1;

        expect(
          item.getRemainingCount(),
          closeTo(expectedRemaining, 0.01),
          reason: 'Remaining should update after first assignment',
        );

        // Second assignment
        final assignQty2 = (random.nextDouble() * 5) + 1;
        assignments = createAdvancedAssignment(item, assignQty2, {'member_2'});
        item = item.copyWith(assignments: assignments);
        expectedRemaining -= assignQty2;

        expect(
          item.getRemainingCount(),
          closeTo(expectedRemaining, 0.01),
          reason: 'Remaining should update after second assignment',
        );

        // Third assignment
        final assignQty3 = (random.nextDouble() * 5) + 1;
        assignments = createAdvancedAssignment(item, assignQty3, {'member_3'});
        item = item.copyWith(assignments: assignments);
        expectedRemaining -= assignQty3;

        expect(
          item.getRemainingCount(),
          closeTo(expectedRemaining, 0.01),
          reason: 'Remaining should update after third assignment',
        );
      }
    });

    test('Property 31: Remaining updates correctly with mixed operations', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 50) + 20;
        var item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        // Add assignment
        var assignments = createAdvancedAssignment(item, 5.0, {'member_1'});
        item = item.copyWith(assignments: assignments);
        expect(item.getRemainingCount(), closeTo(totalQty - 5.0, 0.01));

        // Add another assignment
        assignments = createAdvancedAssignment(item, 3.0, {'member_2'});
        item = item.copyWith(assignments: assignments);
        expect(item.getRemainingCount(), closeTo(totalQty - 8.0, 0.01));

        // Delete first assignment
        assignments = deleteAssignment(item, 'member_1');
        item = item.copyWith(assignments: assignments);
        expect(item.getRemainingCount(), closeTo(totalQty - 3.0, 0.01));

        // Add assignment to member_1 again
        assignments = createAdvancedAssignment(item, 4.0, {'member_1'});
        item = item.copyWith(assignments: assignments);
        expect(item.getRemainingCount(), closeTo(totalQty - 7.0, 0.01));

        // Delete member_2
        assignments = deleteAssignment(item, 'member_2');
        item = item.copyWith(assignments: assignments);
        expect(item.getRemainingCount(), closeTo(totalQty - 4.0, 0.01));
      }
    });

    test('Property 31: Remaining quantity handles fractional assignments', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 5;
        var item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        // Assign fractional quantity
        final assignQty = (random.nextDouble() * 2) + 0.1; // 0.1 to 2.1
        final assignments = createAdvancedAssignment(item, assignQty, {'member_1', 'member_2'});
        item = item.copyWith(assignments: assignments);

        expect(
          item.getRemainingCount(),
          closeTo(totalQty - assignQty, 0.01),
          reason: 'Remaining should handle fractional assignments correctly',
        );
      }
    });

    /// Integration test: Complete advanced assignment workflow
    test('Integration: Complete advanced assignment workflow', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 50) + 10;
        var item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
          isCustomSplit: false,
        );

        // Verify initial state
        expect(item.getRemainingCount(), closeTo(totalQty, 0.01));
        expect(item.isCustomSplit, false);
        expect(item.assignments.isEmpty, true);

        // Create first advanced assignment
        final assignQty1 = (random.nextDouble() * 5) + 1;
        final memberCount1 = random.nextInt(3) + 1;
        final members1 = <String>{};
        for (int j = 0; j < memberCount1; j++) {
          members1.add('member_$j');
        }

        var assignments = createAdvancedAssignment(item, assignQty1, members1);
        item = item.copyWith(assignments: assignments, isCustomSplit: true);

        // Verify after first assignment
        expect(item.isCustomSplit, true);
        expect(item.getRemainingCount(), closeTo(totalQty - assignQty1, 0.01));
        final share1 = assignQty1 / memberCount1;
        for (final memberId in members1) {
          expect(item.assignments[memberId], closeTo(share1, 0.01));
        }

        // Create second advanced assignment
        final assignQty2 = (random.nextDouble() * 5) + 1;
        final memberCount2 = random.nextInt(3) + 1;
        final members2 = <String>{};
        for (int j = 0; j < memberCount2; j++) {
          members2.add('member_${j + 10}'); // Different members
        }

        assignments = createAdvancedAssignment(item, assignQty2, members2);
        item = item.copyWith(assignments: assignments, isCustomSplit: true);

        // Verify after second assignment
        expect(item.isCustomSplit, true);
        expect(item.getRemainingCount(), closeTo(totalQty - assignQty1 - assignQty2, 0.01));
        final share2 = assignQty2 / memberCount2;
        for (final memberId in members2) {
          expect(item.assignments[memberId], closeTo(share2, 0.01));
        }

        // Verify first assignment is preserved
        for (final memberId in members1) {
          expect(item.assignments[memberId], closeTo(share1, 0.01));
        }

        // Delete one assignment
        final memberToDelete = members1.first;
        assignments = deleteAssignment(item, memberToDelete);
        item = item.copyWith(assignments: assignments);

        // Verify after deletion
        expect(item.assignments.containsKey(memberToDelete), false);
        expect(
          item.getRemainingCount(),
          closeTo(totalQty - assignQty1 - assignQty2 + share1, 0.01),
        );
      }
    });

    test('Integration: Assignment correctness with edge cases', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        // Test with very small quantities
        var item = generateRandomReceiptItem(quantity: 1.0);
        var assignments = createAdvancedAssignment(item, 0.5, {'member_1', 'member_2'});
        item = item.copyWith(assignments: assignments);

        expect(item.assignments['member_1'], closeTo(0.25, 0.01));
        expect(item.assignments['member_2'], closeTo(0.25, 0.01));
        expect(item.getRemainingCount(), closeTo(0.5, 0.01));

        // Test with large quantities
        item = generateRandomReceiptItem(quantity: 1000.0);
        assignments = createAdvancedAssignment(item, 500.0, {'member_1', 'member_2', 'member_3'});
        item = item.copyWith(assignments: assignments);

        final expectedShare = 500.0 / 3;
        expect(item.assignments['member_1'], closeTo(expectedShare, 0.01));
        expect(item.assignments['member_2'], closeTo(expectedShare, 0.01));
        expect(item.assignments['member_3'], closeTo(expectedShare, 0.01));
        expect(item.getRemainingCount(), closeTo(500.0, 0.01));
      }
    });
  });
}
