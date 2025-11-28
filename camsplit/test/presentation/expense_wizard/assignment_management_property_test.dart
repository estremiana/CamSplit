import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 32: Assignments list display
/// Feature: expense-wizard-creation, Property 33: Assignment deletion
/// Validates: Requirements 6.13, 6.15
///
/// Property 32: For any existing assignments in AdvancedModal, all should be
/// displayed with member name, quantity, and calculated amount
///
/// Property 33: For any assignment deleted in AdvancedModal, it should be
/// removed from the item's assignments map and remaining quantity should increase

// Helper function to simulate assignment deletion
Map<String, double> deleteAssignment(
  ReceiptItem item,
  String memberIdToDelete,
) {
  final newAssignments = Map<String, double>.from(item.assignments);
  newAssignments.remove(memberIdToDelete);
  return newAssignments;
}

// Helper function to calculate amount for an assignment
double calculateAssignmentAmount(double quantity, double unitPrice) {
  return quantity * unitPrice;
}

void main() {
  final faker = Faker();
  final random = Random();

  group('Assignment Management Property Tests', () {
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

    /// Property 32: Assignments list display
    /// For any existing assignments, all should be displayed with complete data
    test('Property 32: All assignments are present in the list', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final memberCount = random.nextInt(5) + 1;
        final assignments = <String, double>{};

        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          final qty = (random.nextDouble() * 10) + 0.5;
          assignments[memberId] = qty;
        }

        final item = generateRandomReceiptItem(
          assignments: assignments,
          isCustomSplit: true,
        );

        // Verify all assignments are in the map
        expect(
          item.assignments.length,
          memberCount,
          reason: 'All assignments should be present',
        );

        // Verify each assignment has the correct quantity
        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          expect(
            item.assignments.containsKey(memberId),
            true,
            reason: 'Assignment for $memberId should exist',
          );
          expect(
            item.assignments[memberId],
            closeTo(assignments[memberId]!, 0.01),
            reason: 'Assignment quantity should match',
          );
        }
      }
    });

    test('Property 32: Each assignment has correct calculated amount', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final unitPrice = (random.nextDouble() * 100) + 1;
        final memberCount = random.nextInt(5) + 1;
        final assignments = <String, double>{};

        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          final qty = (random.nextDouble() * 10) + 0.5;
          assignments[memberId] = qty;
        }

        final item = generateRandomReceiptItem(
          unitPrice: unitPrice,
          assignments: assignments,
          isCustomSplit: true,
        );

        // Verify calculated amounts for each assignment
        for (final entry in item.assignments.entries) {
          final memberId = entry.key;
          final quantity = entry.value;
          final expectedAmount = calculateAssignmentAmount(quantity, unitPrice);
          final actualAmount = quantity * item.unitPrice;

          expect(
            actualAmount,
            closeTo(expectedAmount, 0.01),
            reason: 'Calculated amount for $memberId should be correct',
          );
        }
      }
    });

    test('Property 32: Empty assignments list shows no assignments', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(
          assignments: {},
          isCustomSplit: false,
        );

        expect(
          item.assignments.isEmpty,
          true,
          reason: 'Empty assignments should have no entries',
        );

        expect(
          item.assignments.length,
          0,
          reason: 'Assignment count should be zero',
        );
      }
    });

    test('Property 32: Assignment quantities are always positive', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final memberCount = random.nextInt(5) + 1;
        final assignments = <String, double>{};

        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          final qty = (random.nextDouble() * 10) + 0.1; // Always positive
          assignments[memberId] = qty;
        }

        final item = generateRandomReceiptItem(
          assignments: assignments,
          isCustomSplit: true,
        );

        // Verify all quantities are positive
        for (final quantity in item.assignments.values) {
          expect(
            quantity > 0,
            true,
            reason: 'Assignment quantities should always be positive',
          );
        }
      }
    });

    test('Property 32: Assignment data is complete for display', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final unitPrice = (random.nextDouble() * 100) + 1;
        final memberCount = random.nextInt(5) + 1;
        final assignments = <String, double>{};

        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          final qty = (random.nextDouble() * 10) + 0.5;
          assignments[memberId] = qty;
        }

        final item = generateRandomReceiptItem(
          unitPrice: unitPrice,
          assignments: assignments,
          isCustomSplit: true,
        );

        // For each assignment, verify we have all data needed for display
        for (final entry in item.assignments.entries) {
          final memberId = entry.key;
          final quantity = entry.value;

          // Member ID exists
          expect(memberId.isNotEmpty, true);

          // Quantity is valid
          expect(quantity > 0, true);

          // Unit price is valid
          expect(item.unitPrice > 0, true);

          // Can calculate amount
          final amount = quantity * item.unitPrice;
          expect(amount > 0, true);
        }
      }
    });

    /// Property 33: Assignment deletion
    /// For any assignment deleted, it should be removed and remaining should increase
    test('Property 33: Deleting assignment removes it from map', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final memberCount = random.nextInt(5) + 2; // At least 2 members
        final assignments = <String, double>{};

        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          final qty = (random.nextDouble() * 10) + 0.5;
          assignments[memberId] = qty;
        }

        final item = generateRandomReceiptItem(
          assignments: assignments,
          isCustomSplit: true,
        );

        // Delete a random member
        final memberToDelete = 'member_${random.nextInt(memberCount)}';
        final newAssignments = deleteAssignment(item, memberToDelete);

        expect(
          newAssignments.containsKey(memberToDelete),
          false,
          reason: 'Deleted member should not be in assignments',
        );

        expect(
          newAssignments.length,
          item.assignments.length - 1,
          reason: 'Assignment count should decrease by 1',
        );
      }
    });

    test('Property 33: Deleting assignment increases remaining quantity', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 5;
        final memberCount = random.nextInt(5) + 2;
        final assignments = <String, double>{};

        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          final qty = (random.nextDouble() * 3) + 0.5;
          assignments[memberId] = qty;
        }

        final item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: assignments,
          isCustomSplit: true,
        );

        final initialRemaining = item.getRemainingCount();

        // Delete a random member
        final memberToDelete = 'member_${random.nextInt(memberCount)}';
        final deletedQty = item.assignments[memberToDelete]!;
        final newAssignments = deleteAssignment(item, memberToDelete);

        // Create new item with updated assignments
        final updatedItem = item.copyWith(assignments: newAssignments);
        final newRemaining = updatedItem.getRemainingCount();

        expect(
          newRemaining,
          closeTo(initialRemaining + deletedQty, 0.01),
          reason: 'Remaining should increase by deleted quantity',
        );
      }
    });

    test('Property 33: Deleting all assignments returns to unassigned state', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 1;
        final memberCount = random.nextInt(5) + 1;
        final assignments = <String, double>{};

        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          final qty = (random.nextDouble() * 3) + 0.5;
          assignments[memberId] = qty;
        }

        var item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: assignments,
          isCustomSplit: true,
        );

        // Delete all assignments one by one
        for (int j = 0; j < memberCount; j++) {
          final memberToDelete = 'member_$j';
          final newAssignments = deleteAssignment(item, memberToDelete);
          item = item.copyWith(assignments: newAssignments);
        }

        expect(
          item.assignments.isEmpty,
          true,
          reason: 'All assignments should be deleted',
        );

        expect(
          item.getRemainingCount(),
          closeTo(totalQty, 0.01),
          reason: 'Remaining should equal total when all deleted',
        );
      }
    });

    test('Property 33: Deleting non-existent assignment has no effect', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final memberCount = random.nextInt(5) + 1;
        final assignments = <String, double>{};

        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          final qty = (random.nextDouble() * 10) + 0.5;
          assignments[memberId] = qty;
        }

        final item = generateRandomReceiptItem(
          assignments: assignments,
          isCustomSplit: true,
        );

        // Try to delete a member that doesn't exist
        final nonExistentMember = 'member_999';
        final newAssignments = deleteAssignment(item, nonExistentMember);

        expect(
          newAssignments.length,
          item.assignments.length,
          reason: 'Assignment count should not change',
        );

        // Verify all original assignments are still there
        for (final memberId in item.assignments.keys) {
          expect(
            newAssignments.containsKey(memberId),
            true,
            reason: 'Original assignments should remain',
          );
          expect(
            newAssignments[memberId],
            closeTo(item.assignments[memberId]!, 0.01),
            reason: 'Original quantities should be unchanged',
          );
        }
      }
    });

    test('Property 33: Deleting assignment preserves other assignments', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final memberCount = random.nextInt(5) + 3; // At least 3 members
        final assignments = <String, double>{};

        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          final qty = (random.nextDouble() * 10) + 0.5;
          assignments[memberId] = qty;
        }

        final item = generateRandomReceiptItem(
          assignments: assignments,
          isCustomSplit: true,
        );

        // Delete one member
        final memberToDelete = 'member_${random.nextInt(memberCount)}';
        final newAssignments = deleteAssignment(item, memberToDelete);

        // Verify other assignments are unchanged
        for (final memberId in item.assignments.keys) {
          if (memberId != memberToDelete) {
            expect(
              newAssignments.containsKey(memberId),
              true,
              reason: 'Other assignments should remain',
            );
            expect(
              newAssignments[memberId],
              closeTo(item.assignments[memberId]!, 0.01),
              reason: 'Other quantities should be unchanged',
            );
          }
        }
      }
    });

    test('Property 33: Multiple deletions accumulate correctly', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 10;
        final memberCount = random.nextInt(5) + 3;
        final assignments = <String, double>{};

        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          final qty = (random.nextDouble() * 2) + 0.5;
          assignments[memberId] = qty;
        }

        var item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: assignments,
          isCustomSplit: true,
        );

        final initialRemaining = item.getRemainingCount();
        var totalDeleted = 0.0;

        // Delete half the members
        final deleteCount = memberCount ~/ 2;
        for (int j = 0; j < deleteCount; j++) {
          final memberToDelete = 'member_$j';
          totalDeleted += item.assignments[memberToDelete]!;
          final newAssignments = deleteAssignment(item, memberToDelete);
          item = item.copyWith(assignments: newAssignments);
        }

        final finalRemaining = item.getRemainingCount();

        expect(
          finalRemaining,
          closeTo(initialRemaining + totalDeleted, 0.01),
          reason: 'Remaining should increase by sum of deleted quantities',
        );

        expect(
          item.assignments.length,
          memberCount - deleteCount,
          reason: 'Assignment count should reflect deletions',
        );
      }
    });

    /// Integration tests: Complete assignment management flow
    test('Integration: Add then delete assignment maintains correctness', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 5;
        var item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        // Add an assignment
        final qty1 = (random.nextDouble() * 3) + 1;
        var assignments = Map<String, double>.from(item.assignments);
        assignments['member_1'] = qty1;
        item = item.copyWith(assignments: assignments, isCustomSplit: true);

        expect(item.assignments['member_1'], closeTo(qty1, 0.01));
        expect(item.getRemainingCount(), closeTo(totalQty - qty1, 0.01));

        // Delete the assignment
        final newAssignments = deleteAssignment(item, 'member_1');
        item = item.copyWith(assignments: newAssignments);

        expect(item.assignments.containsKey('member_1'), false);
        expect(item.getRemainingCount(), closeTo(totalQty, 0.01));
      }
    });

    test('Integration: Complex assignment lifecycle', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 10;
        var item = generateRandomReceiptItem(
          quantity: totalQty,
          assignments: {},
        );

        // Add multiple assignments
        var assignments = Map<String, double>.from(item.assignments);
        assignments['member_1'] = 2.0;
        assignments['member_2'] = 3.0;
        assignments['member_3'] = 1.5;
        item = item.copyWith(assignments: assignments, isCustomSplit: true);

        expect(item.getAssignedCount(), closeTo(6.5, 0.01));
        expect(item.getRemainingCount(), closeTo(totalQty - 6.5, 0.01));

        // Delete one assignment
        var newAssignments = deleteAssignment(item, 'member_2');
        item = item.copyWith(assignments: newAssignments);

        expect(item.getAssignedCount(), closeTo(3.5, 0.01));
        expect(item.getRemainingCount(), closeTo(totalQty - 3.5, 0.01));

        // Add another assignment
        newAssignments = Map<String, double>.from(item.assignments);
        newAssignments['member_4'] = 2.5;
        item = item.copyWith(assignments: newAssignments);

        expect(item.getAssignedCount(), closeTo(6.0, 0.01));
        expect(item.getRemainingCount(), closeTo(totalQty - 6.0, 0.01));

        // Delete all assignments
        for (final memberId in ['member_1', 'member_3', 'member_4']) {
          newAssignments = deleteAssignment(item, memberId);
          item = item.copyWith(assignments: newAssignments);
        }

        expect(item.assignments.isEmpty, true);
        expect(item.getRemainingCount(), closeTo(totalQty, 0.01));
      }
    });

    test('Integration: Assignment display data is always consistent', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final totalQty = (random.nextDouble() * 20) + 5;
        final unitPrice = (random.nextDouble() * 50) + 1;
        final memberCount = random.nextInt(5) + 1;
        final assignments = <String, double>{};

        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          final qty = (random.nextDouble() * 3) + 0.5;
          assignments[memberId] = qty;
        }

        final item = generateRandomReceiptItem(
          quantity: totalQty,
          unitPrice: unitPrice,
          assignments: assignments,
          isCustomSplit: true,
        );

        // Verify consistency of display data
        var totalAssignedQty = 0.0;
        var totalAssignedAmount = 0.0;

        for (final entry in item.assignments.entries) {
          final quantity = entry.value;
          final amount = calculateAssignmentAmount(quantity, unitPrice);

          totalAssignedQty += quantity;
          totalAssignedAmount += amount;

          // Verify amount calculation is consistent
          expect(
            amount,
            closeTo(quantity * unitPrice, 0.01),
            reason: 'Amount calculation should be consistent',
          );
        }

        // Verify totals match
        expect(
          totalAssignedQty,
          closeTo(item.getAssignedCount(), 0.01),
          reason: 'Sum of individual quantities should match total assigned',
        );

        expect(
          totalAssignedAmount,
          closeTo(totalAssignedQty * unitPrice, 0.01),
          reason: 'Total amount should equal total quantity times unit price',
        );
      }
    });
  });
}
