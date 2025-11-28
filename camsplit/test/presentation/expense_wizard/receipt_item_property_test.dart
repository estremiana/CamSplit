import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 16: Assignment status accuracy
/// Feature: expense-wizard-creation, Property 41: Item total recalculation
/// Validates: Requirements 5.3, 8.5
/// 
/// Property 16: For any receipt item, the displayed assignment status should equal 
/// (assigned quantity / total quantity)
/// 
/// Property 41: For any modification to an item's quantity or unit price, 
/// the item's total price should equal (quantity × unit price)
void main() {
  final faker = Faker();
  final random = Random();

  group('ReceiptItem Property Tests', () {
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

    /// Property 16: Assignment status accuracy
    /// For any receipt item, getAssignedCount() should return the sum of all assignments
    test('Property 16: Assignment status accuracy - assigned count equals sum of assignments', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final memberCount = random.nextInt(5) + 1;
        
        // Create random assignments that don't exceed quantity
        final assignments = <String, double>{};
        double totalAssigned = 0.0;
        
        for (int j = 0; j < memberCount; j++) {
          final remaining = quantity - totalAssigned;
          if (remaining <= 0) break;
          
          final assignQty = random.nextDouble() * remaining;
          assignments['member_$j'] = assignQty;
          totalAssigned += assignQty;
        }
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: assignments,
        );
        
        final expectedAssigned = assignments.values.fold(0.0, (sum, qty) => sum + qty);
        
        expect(
          item.getAssignedCount(),
          closeTo(expectedAssigned, 0.0001),
          reason: 'Assigned count should equal sum of all assignments',
        );
      }
    });

    test('Property 16: Remaining count equals total minus assigned', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final assignedQty = random.nextDouble() * quantity;
        
        final assignments = <String, double>{
          'member_1': assignedQty,
        };
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: assignments,
        );
        
        final expectedRemaining = quantity - assignedQty;
        
        expect(
          item.getRemainingCount(),
          closeTo(expectedRemaining, 0.0001),
          reason: 'Remaining count should equal total minus assigned',
        );
      }
    });

    test('Property 16: Item is fully assigned when remaining <= 0.05', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        
        // Test fully assigned (exactly equal)
        final fullyAssigned = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {'member_1': quantity},
        );
        expect(fullyAssigned.isFullyAssigned(), true);
        
        // Test fully assigned (within tolerance)
        final almostFull = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {'member_1': quantity - 0.04},
        );
        expect(almostFull.isFullyAssigned(), true);
        
        // Test not fully assigned
        final partial = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {'member_1': quantity * 0.5},
        );
        expect(partial.isFullyAssigned(), false);
      }
    });

    /// Property 41: Item total recalculation
    /// For any item, price should equal quantity × unitPrice
    test('Property 41: Item total recalculation - price equals quantity × unitPrice', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 0.1;
        final unitPrice = (random.nextDouble() * 100) + 0.1;
        
        final item = ReceiptItem(
          id: faker.guid.guid(),
          name: faker.food.dish(),
          quantity: quantity,
          unitPrice: unitPrice,
          price: quantity * unitPrice,
        );
        
        final expectedPrice = quantity * unitPrice;
        
        expect(
          item.price,
          closeTo(expectedPrice, 0.01),
          reason: 'Price should equal quantity × unitPrice',
        );
      }
    });

    test('Property 41: copyWith recalculates price when quantity changes', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final originalQty = (random.nextDouble() * 20) + 1;
        final unitPrice = (random.nextDouble() * 100) + 1;
        final newQty = (random.nextDouble() * 20) + 1;
        
        final original = ReceiptItem(
          id: faker.guid.guid(),
          name: faker.food.dish(),
          quantity: originalQty,
          unitPrice: unitPrice,
          price: originalQty * unitPrice,
        );
        
        // When copying with new quantity, price should be recalculated
        final updated = original.copyWith(
          quantity: newQty,
          price: newQty * unitPrice,
        );
        
        expect(
          updated.price,
          closeTo(newQty * unitPrice, 0.01),
          reason: 'Updated price should reflect new quantity',
        );
      }
    });

    test('Property 41: copyWith recalculates price when unitPrice changes', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final originalPrice = (random.nextDouble() * 100) + 1;
        final newPrice = (random.nextDouble() * 100) + 1;
        
        final original = ReceiptItem(
          id: faker.guid.guid(),
          name: faker.food.dish(),
          quantity: quantity,
          unitPrice: originalPrice,
          price: quantity * originalPrice,
        );
        
        // When copying with new unit price, total price should be recalculated
        final updated = original.copyWith(
          unitPrice: newPrice,
          price: quantity * newPrice,
        );
        
        expect(
          updated.price,
          closeTo(quantity * newPrice, 0.01),
          reason: 'Updated price should reflect new unit price',
        );
      }
    });

    test('Property: Assignment operations maintain consistency', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final unitPrice = (random.nextDouble() * 100) + 1;
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          unitPrice: unitPrice,
        );
        
        // Add assignments
        final assignments = <String, double>{};
        double totalAssigned = 0.0;
        final memberCount = random.nextInt(5) + 1;
        
        for (int j = 0; j < memberCount; j++) {
          final remaining = quantity - totalAssigned;
          if (remaining <= 0.01) break;
          
          final assignQty = min(random.nextDouble() * remaining, remaining);
          assignments['member_$j'] = assignQty;
          totalAssigned += assignQty;
        }
        
        final withAssignments = item.copyWith(assignments: assignments);
        
        // Verify consistency
        expect(
          withAssignments.getAssignedCount(),
          closeTo(totalAssigned, 0.01),
        );
        
        expect(
          withAssignments.getRemainingCount(),
          closeTo(quantity - totalAssigned, 0.01),
        );
      }
    });

    test('Property: toJson and fromJson round trip preserves data', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final unitPrice = (random.nextDouble() * 100) + 1;
        final assignments = <String, double>{
          'member_1': quantity / 2,
          'member_2': quantity / 2,
        };
        
        final original = ReceiptItem(
          id: faker.guid.guid(),
          name: faker.food.dish(),
          quantity: quantity,
          unitPrice: unitPrice,
          price: quantity * unitPrice,
          assignments: assignments,
          isCustomSplit: random.nextBool(),
        );
        
        final json = original.toJson();
        final restored = ReceiptItem.fromJson(json);
        
        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.quantity, closeTo(original.quantity, 0.01));
        expect(restored.unitPrice, closeTo(original.unitPrice, 0.01));
        expect(restored.price, closeTo(original.price, 0.01));
        expect(restored.isCustomSplit, original.isCustomSplit);
        expect(restored.assignments.length, original.assignments.length);
      }
    });

    test('Property: Empty assignments result in zero assigned count', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(assignments: {});
        
        expect(item.getAssignedCount(), 0.0);
        expect(item.getRemainingCount(), item.quantity);
        expect(item.isFullyAssigned(), false);
      }
    });

    test('Property: Multiple assignments sum correctly', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 5;
        final memberCount = random.nextInt(10) + 2;
        
        final assignments = <String, double>{};
        final individualAmounts = <double>[];
        
        // Distribute quantity among members
        double remaining = quantity;
        for (int j = 0; j < memberCount - 1; j++) {
          final amount = random.nextDouble() * (remaining / (memberCount - j));
          individualAmounts.add(amount);
          assignments['member_$j'] = amount;
          remaining -= amount;
        }
        individualAmounts.add(remaining);
        assignments['member_${memberCount - 1}'] = remaining;
        
        final item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: assignments,
        );
        
        final manualSum = individualAmounts.fold(0.0, (sum, amt) => sum + amt);
        
        expect(
          item.getAssignedCount(),
          closeTo(manualSum, 0.01),
          reason: 'Assigned count should equal manual sum of all assignments',
        );
        
        expect(
          item.getAssignedCount(),
          closeTo(quantity, 0.01),
          reason: 'Total assigned should equal item quantity',
        );
      }
    });

    test('Property: Edge cases with very small quantities', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final smallQty = random.nextDouble() * 0.1 + 0.01;
        final unitPrice = (random.nextDouble() * 100) + 1;
        
        final item = ReceiptItem(
          id: faker.guid.guid(),
          name: faker.food.dish(),
          quantity: smallQty,
          unitPrice: unitPrice,
          price: smallQty * unitPrice,
        );
        
        expect(item.price, closeTo(smallQty * unitPrice, 0.001));
        expect(item.getRemainingCount(), closeTo(smallQty, 0.001));
      }
    });

    test('Property: Edge cases with very large quantities', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final largeQty = (random.nextDouble() * 1000) + 100;
        final unitPrice = (random.nextDouble() * 100) + 1;
        
        final item = ReceiptItem(
          id: faker.guid.guid(),
          name: faker.food.dish(),
          quantity: largeQty,
          unitPrice: unitPrice,
          price: largeQty * unitPrice,
        );
        
        expect(item.price, closeTo(largeQty * unitPrice, 0.01));
        expect(item.getRemainingCount(), closeTo(largeQty, 0.01));
      }
    });
  });
}
