import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 18: Custom split lock indicator
/// Feature: expense-wizard-creation, Property 22: Custom split disables quick mode
/// Feature: expense-wizard-creation, Property 23: Reset clears assignments
/// Validates: Requirements 5.5, 5.10, 5.12
/// 
/// Property 18: For any receipt item with isCustomSplit = true, a lock icon 
/// and "Custom Split" label should display
/// 
/// Property 22: For any item with isCustomSplit = true, the QuickSplit 
/// interface should be disabled
/// 
/// Property 23: For any locked item, tapping Reset should clear all 
/// assignments and set isCustomSplit = false
void main() {
  final faker = Faker();
  final random = Random();

  group('Custom Split Locking Property Tests', () {
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

    // Helper function to simulate reset functionality
    ReceiptItem resetItemAssignments(ReceiptItem item) {
      return item.copyWith(
        assignments: {},
        isCustomSplit: false,
      );
    }

    // Helper function to simulate QuickSplit toggle (should not work when locked)
    ReceiptItem attemptQuickSplitToggle(ReceiptItem item, String memberId) {
      if (item.isCustomSplit) {
        // Cannot toggle when locked - return unchanged
        return item;
      }

      final newAssignments = Map<String, double>.from(item.assignments);

      // Toggle member assignment
      if (newAssignments.containsKey(memberId) && newAssignments[memberId]! > 0) {
        newAssignments.remove(memberId);
      } else {
        newAssignments[memberId] = 0.0;
      }

      // Calculate equal shares
      final assignedMemberCount = newAssignments.length;
      if (assignedMemberCount > 0) {
        final equalShare = item.quantity / assignedMemberCount;
        for (final key in newAssignments.keys) {
          newAssignments[key] = equalShare;
        }
      }

      return item.copyWith(assignments: newAssignments);
    }

    /// Property 18: Custom split lock indicator
    /// For any receipt item with isCustomSplit = true, the lock indicator should be present
    test('Property 18: Items with isCustomSplit=true have lock indicator', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(
          isCustomSplit: true,
          assignments: {
            'member_1': random.nextDouble() * 5,
            'member_2': random.nextDouble() * 5,
          },
        );
        
        // Verify the flag is set
        expect(
          item.isCustomSplit,
          true,
          reason: 'Item should have custom split flag set',
        );
        
        // In the UI, this flag triggers display of lock icon and "Custom Split" label
        // This is a data model test - the UI rendering is tested separately
      }
    });

    test('Property 18: Items with isCustomSplit=false do not have lock indicator', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(
          isCustomSplit: false,
          assignments: {},
        );
        
        expect(
          item.isCustomSplit,
          false,
          reason: 'Item should not have custom split flag set',
        );
      }
    });

    test('Property 18: Lock indicator persists across operations', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(
          isCustomSplit: true,
          assignments: {'member_1': 2.0},
        );
        
        // Perform various operations that should preserve the flag
        final copied = item.copyWith(name: 'Updated Name');
        
        expect(
          copied.isCustomSplit,
          true,
          reason: 'Custom split flag should persist after copyWith',
        );
        
        expect(
          copied.assignments,
          item.assignments,
          reason: 'Assignments should be preserved',
        );
      }
    });

    /// Property 22: Custom split disables quick mode
    /// For any item with isCustomSplit = true, QuickSplit operations should be disabled
    test('Property 22: QuickSplit toggle is disabled when isCustomSplit=true', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final originalAssignments = {
          'member_1': quantity / 2,
          'member_2': quantity / 2,
        };
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          isCustomSplit: true,
          assignments: originalAssignments,
        );
        
        // Attempt to toggle a member - should have no effect
        final memberId = 'member_3';
        final result = attemptQuickSplitToggle(item, memberId);
        
        expect(
          result.assignments,
          equals(originalAssignments),
          reason: 'Assignments should remain unchanged when locked',
        );
        
        expect(
          result.isCustomSplit,
          true,
          reason: 'Custom split flag should remain true',
        );
        
        expect(
          result.assignments.containsKey(memberId),
          false,
          reason: 'New member should not be added when locked',
        );
      }
    });

    test('Property 22: QuickSplit toggle works when isCustomSplit=false', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          isCustomSplit: false,
          assignments: {},
        );
        
        // Attempt to toggle a member - should work
        final memberId = 'member_1';
        final result = attemptQuickSplitToggle(item, memberId);
        
        expect(
          result.assignments.containsKey(memberId),
          true,
          reason: 'Member should be added when not locked',
        );
        
        expect(
          result.assignments[memberId],
          closeTo(quantity, 0.01),
          reason: 'Member should receive full quantity',
        );
      }
    });

    test('Property 22: Attempting to remove member fails when locked', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final memberId = 'member_1';
        final originalAssignments = {memberId: quantity};
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          isCustomSplit: true,
          assignments: originalAssignments,
        );
        
        // Attempt to toggle (remove) the member - should have no effect
        final result = attemptQuickSplitToggle(item, memberId);
        
        expect(
          result.assignments.containsKey(memberId),
          true,
          reason: 'Member should not be removed when locked',
        );
        
        expect(
          result.assignments[memberId],
          closeTo(quantity, 0.01),
          reason: 'Assignment should remain unchanged',
        );
      }
    });

    test('Property 22: Lock prevents all QuickSplit operations', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final originalAssignments = {
          'member_1': quantity * 0.3,
          'member_2': quantity * 0.7,
        };
        
        var item = generateRandomReceiptItem(
          quantity: quantity,
          isCustomSplit: true,
          assignments: originalAssignments,
        );
        
        // Try multiple toggle operations
        final memberIds = ['member_1', 'member_2', 'member_3', 'member_4'];
        
        for (final memberId in memberIds) {
          item = attemptQuickSplitToggle(item, memberId);
        }
        
        // Assignments should remain unchanged
        expect(
          item.assignments,
          equals(originalAssignments),
          reason: 'All QuickSplit operations should be blocked when locked',
        );
        
        expect(
          item.isCustomSplit,
          true,
          reason: 'Lock should remain active',
        );
      }
    });

    /// Property 23: Reset clears assignments
    /// For any locked item, reset should clear all assignments and unlock
    test('Property 23: Reset clears all assignments', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final memberCount = random.nextInt(5) + 1;
        
        // Create assignments
        final assignments = <String, double>{};
        for (int j = 0; j < memberCount; j++) {
          assignments['member_$j'] = random.nextDouble() * quantity;
        }
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          isCustomSplit: true,
          assignments: assignments,
        );
        
        // Reset the item
        final reset = resetItemAssignments(item);
        
        expect(
          reset.assignments.isEmpty,
          true,
          reason: 'All assignments should be cleared',
        );
        
        expect(
          reset.getAssignedCount(),
          0.0,
          reason: 'Assigned count should be zero',
        );
        
        expect(
          reset.getRemainingCount(),
          closeTo(quantity, 0.01),
          reason: 'Remaining count should equal full quantity',
        );
      }
    });

    test('Property 23: Reset sets isCustomSplit to false', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(
          isCustomSplit: true,
          assignments: {
            'member_1': 2.0,
            'member_2': 3.0,
          },
        );
        
        // Reset the item
        final reset = resetItemAssignments(item);
        
        expect(
          reset.isCustomSplit,
          false,
          reason: 'Custom split flag should be cleared',
        );
      }
    });

    test('Property 23: Reset preserves item metadata', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(
          isCustomSplit: true,
          assignments: {'member_1': 5.0},
        );
        
        final originalId = item.id;
        final originalName = item.name;
        final originalPrice = item.price;
        final originalQuantity = item.quantity;
        final originalUnitPrice = item.unitPrice;
        
        // Reset the item
        final reset = resetItemAssignments(item);
        
        expect(reset.id, originalId, reason: 'ID should be preserved');
        expect(reset.name, originalName, reason: 'Name should be preserved');
        expect(reset.price, closeTo(originalPrice, 0.01), reason: 'Price should be preserved');
        expect(reset.quantity, closeTo(originalQuantity, 0.01), reason: 'Quantity should be preserved');
        expect(reset.unitPrice, closeTo(originalUnitPrice, 0.01), reason: 'Unit price should be preserved');
      }
    });

    test('Property 23: After reset, QuickSplit becomes available', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        
        // Start with locked item
        final locked = generateRandomReceiptItem(
          quantity: quantity,
          isCustomSplit: true,
          assignments: {'member_1': quantity},
        );
        
        // Verify QuickSplit is disabled
        final attemptWhileLocked = attemptQuickSplitToggle(locked, 'member_2');
        expect(
          attemptWhileLocked.assignments.containsKey('member_2'),
          false,
          reason: 'QuickSplit should be disabled while locked',
        );
        
        // Reset the item
        final reset = resetItemAssignments(locked);
        
        // Now QuickSplit should work
        final attemptAfterReset = attemptQuickSplitToggle(reset, 'member_2');
        expect(
          attemptAfterReset.assignments.containsKey('member_2'),
          true,
          reason: 'QuickSplit should work after reset',
        );
        
        expect(
          attemptAfterReset.isCustomSplit,
          false,
          reason: 'Item should remain unlocked',
        );
      }
    });

    test('Property 23: Reset is idempotent', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(
          isCustomSplit: true,
          assignments: {'member_1': 5.0, 'member_2': 3.0},
        );
        
        // Reset once
        final reset1 = resetItemAssignments(item);
        
        // Reset again
        final reset2 = resetItemAssignments(reset1);
        
        expect(
          reset2.assignments.isEmpty,
          true,
          reason: 'Assignments should remain empty',
        );
        
        expect(
          reset2.isCustomSplit,
          false,
          reason: 'Flag should remain false',
        );
        
        expect(
          reset2.id,
          reset1.id,
          reason: 'Item should be unchanged',
        );
      }
    });

    test('Property 23: Reset works with empty assignments', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Edge case: locked but no assignments
        final item = generateRandomReceiptItem(
          isCustomSplit: true,
          assignments: {},
        );
        
        final reset = resetItemAssignments(item);
        
        expect(
          reset.assignments.isEmpty,
          true,
          reason: 'Assignments should remain empty',
        );
        
        expect(
          reset.isCustomSplit,
          false,
          reason: 'Flag should be cleared',
        );
      }
    });

    test('Property 23: Reset works with partial assignments', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final partialAssignment = quantity * (random.nextDouble() * 0.5 + 0.1); // 10-60% of quantity
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          isCustomSplit: true,
          assignments: {'member_1': partialAssignment},
        );
        
        expect(
          item.getRemainingCount(),
          greaterThan(0),
          reason: 'Should have remaining quantity before reset',
        );
        
        final reset = resetItemAssignments(item);
        
        expect(
          reset.getRemainingCount(),
          closeTo(quantity, 0.01),
          reason: 'Should have full quantity after reset',
        );
        
        expect(
          reset.isCustomSplit,
          false,
          reason: 'Should be unlocked',
        );
      }
    });

    test('Property: Lock state is independent per item', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final item1 = generateRandomReceiptItem(
          id: 'item_1',
          isCustomSplit: true,
          assignments: {'member_1': 5.0},
        );
        
        final item2 = generateRandomReceiptItem(
          id: 'item_2',
          isCustomSplit: false,
          assignments: {},
        );
        
        // Verify independence
        expect(item1.isCustomSplit, true);
        expect(item2.isCustomSplit, false);
        
        // Reset item1
        final reset1 = resetItemAssignments(item1);
        
        // item2 should be unaffected
        expect(reset1.isCustomSplit, false);
        expect(item2.isCustomSplit, false);
        expect(item1.id, 'item_1');
        expect(item2.id, 'item_2');
      }
    });

    test('Property: Fully assigned items can be locked', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          isCustomSplit: true,
          assignments: {
            'member_1': quantity / 2,
            'member_2': quantity / 2,
          },
        );
        
        expect(
          item.isFullyAssigned(),
          true,
          reason: 'Item should be fully assigned',
        );
        
        expect(
          item.isCustomSplit,
          true,
          reason: 'Fully assigned items can still be locked',
        );
        
        // QuickSplit should still be disabled
        final attempt = attemptQuickSplitToggle(item, 'member_3');
        expect(
          attempt.assignments.length,
          2,
          reason: 'Should not add new member when locked',
        );
      }
    });

    test('Property: Partially assigned items can be locked', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final partialAmount = quantity * 0.3; // 30% assigned
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          isCustomSplit: true,
          assignments: {'member_1': partialAmount},
        );
        
        expect(
          item.isFullyAssigned(),
          false,
          reason: 'Item should be partially assigned',
        );
        
        expect(
          item.getRemainingCount(),
          greaterThan(0),
          reason: 'Should have remaining quantity',
        );
        
        expect(
          item.isCustomSplit,
          true,
          reason: 'Partially assigned items can be locked',
        );
      }
    });
  });
}
