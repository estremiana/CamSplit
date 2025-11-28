import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 20: Quick toggle assignment
/// Feature: expense-wizard-creation, Property 21: Equal share calculation
/// Validates: Requirements 5.8, 5.9
/// 
/// Property 20: For any member avatar tapped in QuickSplit mode (when not locked),
/// that member's assignment should toggle
/// 
/// Property 21: For any set of selected members in QuickSplit mode, each member's
/// assigned quantity should equal (item quantity / number of selected members)
void main() {
  final faker = Faker();
  final random = Random();

  group('QuickSplit Property Tests', () {
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

    // Helper function to simulate member toggle in QuickSplit
    ReceiptItem toggleMemberInQuickSplit(ReceiptItem item, String memberId) {
      if (item.isCustomSplit) {
        // Cannot toggle when locked
        return item;
      }

      final newAssignments = Map<String, double>.from(item.assignments);

      // Toggle member assignment
      if (newAssignments.containsKey(memberId) && newAssignments[memberId]! > 0) {
        // Remove member
        newAssignments.remove(memberId);
      } else {
        // Add member - will be recalculated below
        newAssignments[memberId] = 0.0;
      }

      // Calculate equal shares for all assigned members
      final assignedMemberCount = newAssignments.length;
      if (assignedMemberCount > 0) {
        final equalShare = item.quantity / assignedMemberCount;
        for (final key in newAssignments.keys) {
          newAssignments[key] = equalShare;
        }
      }

      return item.copyWith(assignments: newAssignments);
    }

    /// Property 20: Quick toggle assignment
    /// For any member, toggling should add them if not present, remove if present
    test('Property 20: Toggling a member adds them if not assigned', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: false,
        );
        
        final memberId = 'member_${random.nextInt(100)}';
        
        // Toggle to add member
        final updated = toggleMemberInQuickSplit(item, memberId);
        
        expect(
          updated.assignments.containsKey(memberId),
          true,
          reason: 'Member should be added to assignments',
        );
        
        expect(
          updated.assignments[memberId],
          closeTo(quantity, 0.01),
          reason: 'Single member should get full quantity',
        );
      }
    });

    test('Property 20: Toggling a member removes them if already assigned', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final memberId = 'member_${random.nextInt(100)}';
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {memberId: quantity},
          isCustomSplit: false,
        );
        
        // Toggle to remove member
        final updated = toggleMemberInQuickSplit(item, memberId);
        
        expect(
          updated.assignments.containsKey(memberId),
          false,
          reason: 'Member should be removed from assignments',
        );
        
        expect(
          updated.assignments.isEmpty,
          true,
          reason: 'Assignments should be empty after removing only member',
        );
      }
    });

    test('Property 20: Toggle does not work when item is locked (isCustomSplit)', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final memberId = 'member_${random.nextInt(100)}';
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: true, // Locked
        );
        
        // Try to toggle - should have no effect
        final updated = toggleMemberInQuickSplit(item, memberId);
        
        expect(
          updated.assignments.isEmpty,
          true,
          reason: 'Assignments should remain empty when locked',
        );
        
        expect(
          updated.isCustomSplit,
          true,
          reason: 'Custom split flag should remain true',
        );
      }
    });

    /// Property 21: Equal share calculation
    /// For any set of selected members, each should get equal share
    test('Property 21: Equal share calculation - single member gets full quantity', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: false,
        );
        
        final memberId = 'member_1';
        final updated = toggleMemberInQuickSplit(item, memberId);
        
        expect(
          updated.assignments[memberId],
          closeTo(quantity, 0.01),
          reason: 'Single member should receive full quantity',
        );
      }
    });

    test('Property 21: Equal share calculation - two members split equally', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: false,
        );
        
        // Add first member
        final withMember1 = toggleMemberInQuickSplit(item, 'member_1');
        // Add second member
        final withBoth = toggleMemberInQuickSplit(withMember1, 'member_2');
        
        final expectedShare = quantity / 2;
        
        expect(
          withBoth.assignments['member_1'],
          closeTo(expectedShare, 0.01),
          reason: 'First member should get half',
        );
        
        expect(
          withBoth.assignments['member_2'],
          closeTo(expectedShare, 0.01),
          reason: 'Second member should get half',
        );
        
        // Verify total equals quantity
        final total = withBoth.assignments.values.fold(0.0, (sum, qty) => sum + qty);
        expect(
          total,
          closeTo(quantity, 0.01),
          reason: 'Total assigned should equal item quantity',
        );
      }
    });

    test('Property 21: Equal share calculation - multiple members split equally', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final memberCount = random.nextInt(8) + 2; // 2-9 members
        
        var item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: false,
        );
        
        // Add members one by one
        for (int j = 0; j < memberCount; j++) {
          item = toggleMemberInQuickSplit(item, 'member_$j');
        }
        
        final expectedShare = quantity / memberCount;
        
        // Verify each member has equal share
        for (int j = 0; j < memberCount; j++) {
          expect(
            item.assignments['member_$j'],
            closeTo(expectedShare, 0.01),
            reason: 'Member $j should have equal share',
          );
        }
        
        // Verify total equals quantity
        final total = item.assignments.values.fold(0.0, (sum, qty) => sum + qty);
        expect(
          total,
          closeTo(quantity, 0.01),
          reason: 'Total assigned should equal item quantity',
        );
      }
    });

    test('Property 21: Removing a member recalculates shares for remaining', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        
        var item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: false,
        );
        
        // Add three members
        item = toggleMemberInQuickSplit(item, 'member_1');
        item = toggleMemberInQuickSplit(item, 'member_2');
        item = toggleMemberInQuickSplit(item, 'member_3');
        
        // Each should have 1/3
        expect(item.assignments['member_1'], closeTo(quantity / 3, 0.01));
        expect(item.assignments['member_2'], closeTo(quantity / 3, 0.01));
        expect(item.assignments['member_3'], closeTo(quantity / 3, 0.01));
        
        // Remove one member
        item = toggleMemberInQuickSplit(item, 'member_2');
        
        // Remaining two should have 1/2 each
        expect(item.assignments['member_1'], closeTo(quantity / 2, 0.01));
        expect(item.assignments['member_3'], closeTo(quantity / 2, 0.01));
        expect(item.assignments.containsKey('member_2'), false);
        
        // Verify total
        final total = item.assignments.values.fold(0.0, (sum, qty) => sum + qty);
        expect(total, closeTo(quantity, 0.01));
      }
    });

    test('Property 21: Adding and removing members maintains equal distribution', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        
        var item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: false,
        );
        
        // Randomly add and remove members
        final operations = random.nextInt(10) + 5;
        final memberIds = List.generate(5, (i) => 'member_$i');
        
        for (int op = 0; op < operations; op++) {
          final memberId = memberIds[random.nextInt(memberIds.length)];
          item = toggleMemberInQuickSplit(item, memberId);
          
          // After each operation, verify equal distribution
          if (item.assignments.isNotEmpty) {
            final memberCount = item.assignments.length;
            final expectedShare = quantity / memberCount;
            
            for (final share in item.assignments.values) {
              expect(
                share,
                closeTo(expectedShare, 0.01),
                reason: 'All members should have equal share after toggle',
              );
            }
            
            // Verify total
            final total = item.assignments.values.fold(0.0, (sum, qty) => sum + qty);
            expect(
              total,
              closeTo(quantity, 0.01),
              reason: 'Total should always equal quantity',
            );
          }
        }
      }
    });

    test('Property 21: Equal shares work with fractional quantities', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Use fractional quantities (e.g., 2.5 pizzas)
        final quantity = (random.nextDouble() * 10) + 0.5;
        final memberCount = random.nextInt(5) + 2;
        
        var item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: false,
        );
        
        // Add members
        for (int j = 0; j < memberCount; j++) {
          item = toggleMemberInQuickSplit(item, 'member_$j');
        }
        
        final expectedShare = quantity / memberCount;
        
        // Verify each member has equal fractional share
        for (int j = 0; j < memberCount; j++) {
          expect(
            item.assignments['member_$j'],
            closeTo(expectedShare, 0.01),
            reason: 'Member $j should have equal fractional share',
          );
        }
      }
    });

    test('Property 21: Equal shares work with very small quantities', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = random.nextDouble() * 0.5 + 0.1; // 0.1 to 0.6
        final memberCount = random.nextInt(3) + 2; // 2-4 members
        
        var item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: false,
        );
        
        // Add members
        for (int j = 0; j < memberCount; j++) {
          item = toggleMemberInQuickSplit(item, 'member_$j');
        }
        
        final expectedShare = quantity / memberCount;
        
        // Verify distribution
        for (int j = 0; j < memberCount; j++) {
          expect(
            item.assignments['member_$j'],
            closeTo(expectedShare, 0.001),
            reason: 'Small quantities should still distribute equally',
          );
        }
      }
    });

    test('Property 21: Equal shares work with large quantities', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 1000) + 100; // 100-1100
        final memberCount = random.nextInt(10) + 2; // 2-11 members
        
        var item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: false,
        );
        
        // Add members
        for (int j = 0; j < memberCount; j++) {
          item = toggleMemberInQuickSplit(item, 'member_$j');
        }
        
        final expectedShare = quantity / memberCount;
        
        // Verify distribution
        for (int j = 0; j < memberCount; j++) {
          expect(
            item.assignments['member_$j'],
            closeTo(expectedShare, 0.1),
            reason: 'Large quantities should still distribute equally',
          );
        }
      }
    });

    test('Property: Toggle preserves item metadata', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(isCustomSplit: false);
        final originalId = item.id;
        final originalName = item.name;
        final originalPrice = item.price;
        final originalUnitPrice = item.unitPrice;
        final originalQuantity = item.quantity;
        
        final updated = toggleMemberInQuickSplit(item, 'member_1');
        
        expect(updated.id, originalId);
        expect(updated.name, originalName);
        expect(updated.price, closeTo(originalPrice, 0.01));
        expect(updated.unitPrice, closeTo(originalUnitPrice, 0.01));
        expect(updated.quantity, closeTo(originalQuantity, 0.01));
        expect(updated.isCustomSplit, false);
      }
    });

    test('Property: Toggling all members off results in empty assignments', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final memberCount = random.nextInt(5) + 2;
        
        var item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: false,
        );
        
        // Add all members
        final memberIds = <String>[];
        for (int j = 0; j < memberCount; j++) {
          final memberId = 'member_$j';
          memberIds.add(memberId);
          item = toggleMemberInQuickSplit(item, memberId);
        }
        
        // Remove all members
        for (final memberId in memberIds) {
          item = toggleMemberInQuickSplit(item, memberId);
        }
        
        expect(
          item.assignments.isEmpty,
          true,
          reason: 'All assignments should be removed',
        );
        
        expect(
          item.getAssignedCount(),
          0.0,
          reason: 'Assigned count should be zero',
        );
        
        expect(
          item.getRemainingCount(),
          closeTo(quantity, 0.01),
          reason: 'Remaining should equal full quantity',
        );
      }
    });

    test('Property: Idempotent toggle - toggling twice returns to original state', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final memberId = 'member_${random.nextInt(100)}';
        
        final original = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {},
          isCustomSplit: false,
        );
        
        // Toggle on then off
        final toggled = toggleMemberInQuickSplit(original, memberId);
        final toggledBack = toggleMemberInQuickSplit(toggled, memberId);
        
        expect(
          toggledBack.assignments.isEmpty,
          original.assignments.isEmpty,
          reason: 'Should return to original state',
        );
        
        expect(
          toggledBack.getAssignedCount(),
          closeTo(original.getAssignedCount(), 0.01),
          reason: 'Assigned count should match original',
        );
      }
    });
  });
}
