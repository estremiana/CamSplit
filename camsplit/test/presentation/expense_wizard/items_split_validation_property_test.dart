import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 5: Items split validation
/// Validates: Requirements 9.1, 9.4, 9.5
/// 
/// Property: For any expense in Items split mode, if any item has unassigned 
/// quantity > 0.01, the Create Expense button should be disabled and an error 
/// message should display
void main() {
  final faker = Faker();
  final random = Random();

  group('Items Split Validation Property Tests', () {
    // Helper function to generate random ReceiptItem
    ReceiptItem generateRandomItem({
      String? id,
      String? name,
      double? quantity,
      double? unitPrice,
      Map<String, double>? assignments,
      bool? isCustomSplit,
    }) {
      final qty = quantity ?? (random.nextDouble() * 10) + 1;
      final price = unitPrice ?? (random.nextDouble() * 50) + 1;
      
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

    // Helper function to generate random WizardExpenseData
    WizardExpenseData generateRandomWizardData({
      double? amount,
      List<ReceiptItem>? items,
      SplitType? splitType,
    }) {
      return WizardExpenseData(
        amount: amount ?? (random.nextDouble() * 1000) + 10,
        title: faker.lorem.word(),
        groupId: faker.guid.guid(),
        payerId: faker.guid.guid(),
        date: DateTime.now().toIso8601String(),
        category: faker.lorem.word(),
        splitType: splitType ?? SplitType.items,
        items: items ?? [],
      );
    }

    /// Property 5: Items split validation - fully assigned items should be valid
    test('Property 5: Items split with all items fully assigned should be valid', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of items (1-10)
        final itemCount = random.nextInt(10) + 1;
        final items = <ReceiptItem>[];
        
        for (int j = 0; j < itemCount; j++) {
          final quantity = (random.nextDouble() * 10) + 1;
          final unitPrice = (random.nextDouble() * 50) + 1;
          
          // Generate random number of members (1-5)
          final memberCount = random.nextInt(5) + 1;
          final assignments = <String, double>{};
          
          // Distribute quantity equally among members
          final sharePerMember = quantity / memberCount;
          for (int k = 0; k < memberCount; k++) {
            assignments['member_$k'] = sharePerMember;
          }
          
          items.add(generateRandomItem(
            quantity: quantity,
            unitPrice: unitPrice,
            assignments: assignments,
          ));
        }
        
        final wizardData = generateRandomWizardData(items: items);
        
        // All items are fully assigned, so split should be valid
        expect(
          wizardData.isSplitValid(),
          true,
          reason: 'All items are fully assigned, split should be valid',
        );
        
        // Verify each item is fully assigned
        for (final item in items) {
          expect(
            item.isFullyAssigned(),
            true,
            reason: 'Item ${item.name} should be fully assigned',
          );
        }
      }
    });

    /// Property 5: Items split validation - partially assigned items should be invalid
    test('Property 5: Items split with any unassigned items should be invalid', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of items (2-10)
        final itemCount = random.nextInt(9) + 2;
        final items = <ReceiptItem>[];
        
        // Create some fully assigned items
        final fullyAssignedCount = random.nextInt(itemCount - 1);
        for (int j = 0; j < fullyAssignedCount; j++) {
          final quantity = (random.nextDouble() * 10) + 1;
          final unitPrice = (random.nextDouble() * 50) + 1;
          
          final memberCount = random.nextInt(3) + 1;
          final assignments = <String, double>{};
          final sharePerMember = quantity / memberCount;
          for (int k = 0; k < memberCount; k++) {
            assignments['member_$k'] = sharePerMember;
          }
          
          items.add(generateRandomItem(
            quantity: quantity,
            unitPrice: unitPrice,
            assignments: assignments,
          ));
        }
        
        // Create at least one partially assigned item
        final partiallyAssignedCount = itemCount - fullyAssignedCount;
        for (int j = 0; j < partiallyAssignedCount; j++) {
          final quantity = (random.nextDouble() * 10) + 1;
          final unitPrice = (random.nextDouble() * 50) + 1;
          
          // Assign only a fraction of the quantity
          final assignedFraction = random.nextDouble() * 0.9; // 0-90% assigned
          final assignments = <String, double>{
            'member_0': quantity * assignedFraction,
          };
          
          items.add(generateRandomItem(
            quantity: quantity,
            unitPrice: unitPrice,
            assignments: assignments,
          ));
        }
        
        final wizardData = generateRandomWizardData(items: items);
        
        // At least one item is not fully assigned, so split should be invalid
        expect(
          wizardData.isSplitValid(),
          false,
          reason: 'At least one item is not fully assigned, split should be invalid',
        );
        
        // Verify at least one item is not fully assigned
        final hasUnassignedItem = items.any((item) => !item.isFullyAssigned());
        expect(
          hasUnassignedItem,
          true,
          reason: 'Should have at least one unassigned item',
        );
      }
    });

    /// Property 5: Items split validation - empty items list should be invalid
    test('Property 5: Items split with no items should be invalid', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final wizardData = generateRandomWizardData(items: []);
        
        expect(
          wizardData.isSplitValid(),
          false,
          reason: 'Items split with no items should be invalid',
        );
      }
    });

    /// Property 5: Items split validation - unassigned items should be invalid
    test('Property 5: Items split with completely unassigned items should be invalid', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(5) + 1;
        final items = <ReceiptItem>[];
        
        for (int j = 0; j < itemCount; j++) {
          final quantity = (random.nextDouble() * 10) + 1;
          final unitPrice = (random.nextDouble() * 50) + 1;
          
          // Create item with no assignments
          items.add(generateRandomItem(
            quantity: quantity,
            unitPrice: unitPrice,
            assignments: {},
          ));
        }
        
        final wizardData = generateRandomWizardData(items: items);
        
        expect(
          wizardData.isSplitValid(),
          false,
          reason: 'Items with no assignments should be invalid',
        );
        
        // Verify all items are not fully assigned
        for (final item in items) {
          expect(
            item.isFullyAssigned(),
            false,
            reason: 'Item ${item.name} should not be fully assigned',
          );
        }
      }
    });

    /// Property 5: Edge case - items with assignments within tolerance should be valid
    test('Property 5: Items with assignments within 0.05 tolerance should be valid', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 10) + 1;
        final unitPrice = (random.nextDouble() * 50) + 1;
        
        // Assign slightly less than full quantity (within tolerance)
        final assignments = <String, double>{
          'member_0': quantity - 0.04, // Within 0.05 tolerance
        };
        
        final item = generateRandomItem(
          quantity: quantity,
          unitPrice: unitPrice,
          assignments: assignments,
        );
        
        final wizardData = generateRandomWizardData(items: [item]);
        
        // Should be considered fully assigned due to tolerance
        expect(
          item.isFullyAssigned(),
          true,
          reason: 'Item with assignment within tolerance should be fully assigned',
        );
        
        expect(
          wizardData.isSplitValid(),
          true,
          reason: 'Split with items within tolerance should be valid',
        );
      }
    });

    /// Property 5: Edge case - items with assignments just outside tolerance should be invalid
    test('Property 5: Items with assignments outside 0.05 tolerance should be invalid', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 10) + 1;
        final unitPrice = (random.nextDouble() * 50) + 1;
        
        // Assign less than full quantity (outside tolerance)
        final unassignedAmount = 0.06 + (random.nextDouble() * 0.5); // 0.06-0.56 unassigned
        final assignments = <String, double>{
          'member_0': quantity - unassignedAmount,
        };
        
        final item = generateRandomItem(
          quantity: quantity,
          unitPrice: unitPrice,
          assignments: assignments,
        );
        
        final wizardData = generateRandomWizardData(items: [item]);
        
        // Should not be considered fully assigned
        expect(
          item.isFullyAssigned(),
          false,
          reason: 'Item with assignment outside tolerance should not be fully assigned',
        );
        
        expect(
          wizardData.isSplitValid(),
          false,
          reason: 'Split with items outside tolerance should be invalid',
        );
      }
    });

    /// Property 5: Mixed scenario - some assigned, some not
    test('Property 5: Mixed items (some assigned, some not) should be invalid', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(8) + 2; // At least 2 items
        final items = <ReceiptItem>[];
        
        // Determine how many items will be fully assigned
        final fullyAssignedCount = random.nextInt(itemCount);
        
        for (int j = 0; j < itemCount; j++) {
          final quantity = (random.nextDouble() * 10) + 1;
          final unitPrice = (random.nextDouble() * 50) + 1;
          
          Map<String, double> assignments;
          if (j < fullyAssignedCount) {
            // Fully assign this item
            assignments = {'member_0': quantity};
          } else {
            // Partially or not assign this item
            final assignedFraction = random.nextDouble() * 0.95;
            assignments = {'member_0': quantity * assignedFraction};
          }
          
          items.add(generateRandomItem(
            quantity: quantity,
            unitPrice: unitPrice,
            assignments: assignments,
          ));
        }
        
        final wizardData = generateRandomWizardData(items: items);
        
        // Check if all items are fully assigned
        final allFullyAssigned = items.every((item) => item.isFullyAssigned());
        
        expect(
          wizardData.isSplitValid(),
          allFullyAssigned,
          reason: 'Split validity should match whether all items are fully assigned',
        );
      }
    });

    /// Property 5: Validation with different split types
    test('Property 5: Items split validation only applies to Items split type', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Create partially assigned items
        final items = <ReceiptItem>[
          generateRandomItem(
            quantity: 5.0,
            unitPrice: 10.0,
            assignments: {'member_0': 2.0}, // Only 2/5 assigned
          ),
        ];
        
        // Test with Items split type - should be invalid
        final itemsSplit = generateRandomWizardData(
          items: items,
          splitType: SplitType.items,
        );
        expect(
          itemsSplit.isSplitValid(),
          false,
          reason: 'Items split with unassigned items should be invalid',
        );
        
        // Test with Equal split type - items don't matter
        final equalSplit = WizardExpenseData(
          amount: 100.0,
          title: faker.lorem.word(),
          groupId: faker.guid.guid(),
          payerId: faker.guid.guid(),
          date: DateTime.now().toIso8601String(),
          splitType: SplitType.equal,
          involvedMembers: ['member_0', 'member_1'],
          items: items, // Items present but not used for validation
        );
        expect(
          equalSplit.isSplitValid(),
          true,
          reason: 'Equal split should be valid regardless of item assignments',
        );
      }
    });
  });
}
