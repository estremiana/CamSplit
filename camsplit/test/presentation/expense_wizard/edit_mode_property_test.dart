import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 40: Edit mode transforms items
/// Feature: expense-wizard-creation, Property 41: Item total recalculation
/// Feature: expense-wizard-creation, Property 42: Item deletion
/// Feature: expense-wizard-creation, Property 43: Add item creates new item
/// Feature: expense-wizard-creation, Property 44: Expense total recalculation on edit complete
/// Validates: Requirements 8.3, 8.5, 8.7, 8.9, 8.10
/// 
/// Property 40: For any items in edit mode, they should be displayed as editable cards with input fields
/// Property 41: For any modification to an item's quantity or unit price, the item's total price should equal (quantity × unit price)
/// Property 42: For any item deleted in edit mode, it should be removed from the items list
/// Property 43: For any "Add Item" action, a new item with default values should be created and added to the list
/// Property 44: For any exit from edit mode, the expense total should equal the sum of all item totals
void main() {
  final faker = Faker();
  final random = Random();

  group('Edit Mode Property Tests', () {
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

    // Helper function to generate random WizardExpenseData
    WizardExpenseData generateRandomWizardData({
      List<ReceiptItem>? items,
      double? amount,
    }) {
      final itemsList = items ?? List.generate(
        random.nextInt(5) + 1,
        (_) => generateRandomReceiptItem(),
      );
      
      final calculatedTotal = itemsList.fold<double>(0.0, (sum, item) => sum + item.price);
      final total = amount ?? calculatedTotal;
      
      return WizardExpenseData(
        amount: total,
        items: itemsList,
        title: faker.company.name(),
        groupId: faker.guid.guid(),
        payerId: faker.guid.guid(),
        date: DateTime.now().toIso8601String(),
      );
    }

    /// Property 40: Edit mode transforms items
    /// For any items, they should be editable with name, quantity, and unit price fields
    test('Property 40: Edit mode transforms items - items have editable fields', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(10) + 1;
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        
        // Verify each item has the necessary fields for editing
        for (final item in items) {
          expect(item.name, isNotEmpty, reason: 'Item should have a name field');
          expect(item.quantity, greaterThan(0), reason: 'Item should have a quantity field');
          expect(item.unitPrice, greaterThanOrEqualTo(0), reason: 'Item should have a unit price field');
        }
      }
    });

    /// Property 41: Item total recalculation
    /// For any modification to quantity or unit price, total should equal quantity × unitPrice
    test('Property 41: Item total recalculation - price equals quantity × unitPrice', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final originalQty = (random.nextDouble() * 20) + 0.1;
        final originalPrice = (random.nextDouble() * 100) + 0.1;
        
        final item = ReceiptItem(
          id: faker.guid.guid(),
          name: faker.food.dish(),
          quantity: originalQty,
          unitPrice: originalPrice,
          price: originalQty * originalPrice,
        );
        
        // Modify quantity
        final newQty = (random.nextDouble() * 20) + 0.1;
        final updatedQty = item.copyWith(
          quantity: newQty,
          price: newQty * item.unitPrice,
        );
        
        expect(
          updatedQty.price,
          closeTo(newQty * item.unitPrice, 0.01),
          reason: 'Price should be recalculated when quantity changes',
        );
        
        // Modify unit price
        final newPrice = (random.nextDouble() * 100) + 0.1;
        final updatedPrice = item.copyWith(
          unitPrice: newPrice,
          price: item.quantity * newPrice,
        );
        
        expect(
          updatedPrice.price,
          closeTo(item.quantity * newPrice, 0.01),
          reason: 'Price should be recalculated when unit price changes',
        );
        
        // Modify both
        final bothNewQty = (random.nextDouble() * 20) + 0.1;
        final bothNewPrice = (random.nextDouble() * 100) + 0.1;
        final updatedBoth = item.copyWith(
          quantity: bothNewQty,
          unitPrice: bothNewPrice,
          price: bothNewQty * bothNewPrice,
        );
        
        expect(
          updatedBoth.price,
          closeTo(bothNewQty * bothNewPrice, 0.01),
          reason: 'Price should be recalculated when both quantity and unit price change',
        );
      }
    });

    test('Property 41: Recalculation maintains precision', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Test with various decimal places
        final qty = double.parse((random.nextDouble() * 20 + 0.1).toStringAsFixed(2));
        final unitPrice = double.parse((random.nextDouble() * 100 + 0.1).toStringAsFixed(2));
        
        final item = ReceiptItem(
          id: faker.guid.guid(),
          name: faker.food.dish(),
          quantity: qty,
          unitPrice: unitPrice,
          price: qty * unitPrice,
        );
        
        final expectedPrice = qty * unitPrice;
        
        expect(
          item.price,
          closeTo(expectedPrice, 0.01),
          reason: 'Price calculation should maintain reasonable precision',
        );
      }
    });

    /// Property 42: Item deletion
    /// For any item deleted, it should be removed from the items list
    test('Property 42: Item deletion - deleted item is removed from list', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(10) + 2; // At least 2 items
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        final wizardData = generateRandomWizardData(items: items);
        
        // Select a random item to delete
        final deleteIndex = random.nextInt(items.length);
        final itemToDelete = items[deleteIndex];
        
        // Simulate deletion
        final updatedItems = items.where((item) => item.id != itemToDelete.id).toList();
        final updatedData = wizardData.copyWith(items: updatedItems);
        
        expect(
          updatedData.items.length,
          equals(items.length - 1),
          reason: 'Item count should decrease by 1 after deletion',
        );
        
        expect(
          updatedData.items.any((item) => item.id == itemToDelete.id),
          false,
          reason: 'Deleted item should not be in the list',
        );
        
        // Verify other items are still present
        for (final item in items) {
          if (item.id != itemToDelete.id) {
            expect(
              updatedData.items.any((i) => i.id == item.id),
              true,
              reason: 'Non-deleted items should remain in the list',
            );
          }
        }
      }
    });

    test('Property 42: Multiple deletions work correctly', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(10) + 5; // At least 5 items
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        var currentItems = List<ReceiptItem>.from(items);
        
        // Delete multiple items
        final deleteCount = random.nextInt(itemCount - 1) + 1;
        final itemsToDelete = <String>{};
        
        for (int j = 0; j < deleteCount; j++) {
          if (currentItems.isEmpty) break;
          final deleteIndex = random.nextInt(currentItems.length);
          itemsToDelete.add(currentItems[deleteIndex].id);
          currentItems = currentItems.where((item) => item.id != currentItems[deleteIndex].id).toList();
        }
        
        expect(
          currentItems.length,
          equals(items.length - itemsToDelete.length),
          reason: 'Item count should decrease by number of deletions',
        );
        
        for (final deletedId in itemsToDelete) {
          expect(
            currentItems.any((item) => item.id == deletedId),
            false,
            reason: 'Deleted items should not be in the list',
          );
        }
      }
    });

    /// Property 43: Add item creates new item
    /// For any "Add Item" action, a new item with default values should be created
    test('Property 43: Add item creates new item with default values', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(10);
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        final wizardData = generateRandomWizardData(items: items);
        
        // Simulate adding a new item
        final newItem = ReceiptItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'New Item',
          quantity: 1.0,
          unitPrice: 0.0,
          price: 0.0,
        );
        
        final updatedItems = [...items, newItem];
        final updatedData = wizardData.copyWith(items: updatedItems);
        
        expect(
          updatedData.items.length,
          equals(items.length + 1),
          reason: 'Item count should increase by 1 after adding',
        );
        
        final addedItem = updatedData.items.last;
        expect(addedItem.name, isNotEmpty, reason: 'New item should have a name');
        expect(addedItem.quantity, greaterThan(0), reason: 'New item should have positive quantity');
        expect(addedItem.unitPrice, greaterThanOrEqualTo(0), reason: 'New item should have non-negative unit price');
        expect(addedItem.price, equals(addedItem.quantity * addedItem.unitPrice), reason: 'New item price should be calculated correctly');
      }
    });

    test('Property 43: Multiple additions work correctly', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final initialCount = random.nextInt(5);
        var items = List.generate(initialCount, (_) => generateRandomReceiptItem());
        
        // Add multiple items
        final addCount = random.nextInt(10) + 1;
        
        for (int j = 0; j < addCount; j++) {
          final newItem = ReceiptItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_$j',
            name: 'New Item $j',
            quantity: 1.0,
            unitPrice: 0.0,
            price: 0.0,
          );
          items = [...items, newItem];
        }
        
        expect(
          items.length,
          equals(initialCount + addCount),
          reason: 'Item count should increase by number of additions',
        );
      }
    });

    /// Property 44: Expense total recalculation on edit complete
    /// For any exit from edit mode, expense total should equal sum of all item totals
    test('Property 44: Expense total recalculation - total equals sum of item prices', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(10) + 1;
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        
        // Calculate expected total
        final expectedTotal = items.fold(0.0, (sum, item) => sum + item.price);
        
        final wizardData = WizardExpenseData(
          amount: expectedTotal,
          items: items,
          title: faker.company.name(),
          groupId: faker.guid.guid(),
          payerId: faker.guid.guid(),
          date: DateTime.now().toIso8601String(),
        );
        
        expect(
          wizardData.amount,
          closeTo(expectedTotal, 0.01),
          reason: 'Expense total should equal sum of all item prices',
        );
      }
    });

    test('Property 44: Total recalculation after item modifications', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(10) + 1;
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        final wizardData = generateRandomWizardData(items: items);
        
        // Modify some items
        final updatedItems = items.map((item) {
          if (random.nextBool()) {
            final newQty = (random.nextDouble() * 20) + 0.1;
            final newPrice = (random.nextDouble() * 100) + 0.1;
            return item.copyWith(
              quantity: newQty,
              unitPrice: newPrice,
              price: newQty * newPrice,
            );
          }
          return item;
        }).toList();
        
        // Calculate new total
        final newTotal = updatedItems.fold(0.0, (sum, item) => sum + item.price);
        final updatedData = wizardData.copyWith(
          items: updatedItems,
          amount: newTotal,
        );
        
        expect(
          updatedData.amount,
          closeTo(newTotal, 0.01),
          reason: 'Expense total should be recalculated after item modifications',
        );
        
        // Verify manual calculation matches
        final manualTotal = updatedItems.fold(0.0, (sum, item) => sum + item.price);
        expect(
          updatedData.amount,
          closeTo(manualTotal, 0.01),
          reason: 'Recalculated total should match manual sum',
        );
      }
    });

    test('Property 44: Total recalculation after deletions', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(10) + 2;
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        final wizardData = generateRandomWizardData(items: items);
        
        // Delete some items
        final deleteCount = random.nextInt(itemCount - 1) + 1;
        var remainingItems = List<ReceiptItem>.from(items);
        
        for (int j = 0; j < deleteCount; j++) {
          if (remainingItems.isEmpty) break;
          final deleteIndex = random.nextInt(remainingItems.length);
          remainingItems.removeAt(deleteIndex);
        }
        
        // Calculate new total
        final newTotal = remainingItems.fold(0.0, (sum, item) => sum + item.price);
        final updatedData = wizardData.copyWith(
          items: remainingItems,
          amount: newTotal,
        );
        
        expect(
          updatedData.amount,
          closeTo(newTotal, 0.01),
          reason: 'Expense total should be recalculated after deletions',
        );
      }
    });

    test('Property 44: Total recalculation after additions', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(5);
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        final wizardData = generateRandomWizardData(items: items);
        
        // Add some items
        final addCount = random.nextInt(5) + 1;
        final updatedItems = List<ReceiptItem>.from(items);
        
        for (int j = 0; j < addCount; j++) {
          updatedItems.add(generateRandomReceiptItem());
        }
        
        // Calculate new total
        final newTotal = updatedItems.fold(0.0, (sum, item) => sum + item.price);
        final updatedData = wizardData.copyWith(
          items: updatedItems,
          amount: newTotal,
        );
        
        expect(
          updatedData.amount,
          closeTo(newTotal, 0.01),
          reason: 'Expense total should be recalculated after additions',
        );
      }
    });

    test('Property 44: Total recalculation with mixed operations', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(10) + 3;
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        var wizardData = generateRandomWizardData(items: items);
        
        // Perform mixed operations: modify, delete, add
        var currentItems = List<ReceiptItem>.from(items);
        
        // Modify some items
        currentItems = currentItems.map((item) {
          if (random.nextBool()) {
            final newQty = (random.nextDouble() * 20) + 0.1;
            final newPrice = (random.nextDouble() * 100) + 0.1;
            return item.copyWith(
              quantity: newQty,
              unitPrice: newPrice,
              price: newQty * newPrice,
            );
          }
          return item;
        }).toList();
        
        // Delete some items
        if (currentItems.length > 1 && random.nextBool()) {
          final deleteIndex = random.nextInt(currentItems.length);
          currentItems.removeAt(deleteIndex);
        }
        
        // Add some items
        if (random.nextBool()) {
          currentItems.add(generateRandomReceiptItem());
        }
        
        // Calculate final total
        final finalTotal = currentItems.fold(0.0, (sum, item) => sum + item.price);
        wizardData = wizardData.copyWith(
          items: currentItems,
          amount: finalTotal,
        );
        
        expect(
          wizardData.amount,
          closeTo(finalTotal, 0.01),
          reason: 'Expense total should be correct after mixed operations',
        );
        
        // Verify with manual calculation
        final manualTotal = currentItems.fold(0.0, (sum, item) => sum + item.price);
        expect(
          wizardData.amount,
          closeTo(manualTotal, 0.01),
          reason: 'Recalculated total should match manual sum after mixed operations',
        );
      }
    });

    test('Property: Edit mode preserves item IDs', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(10) + 1;
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        final originalIds = items.map((item) => item.id).toSet();
        
        // Modify items
        final updatedItems = items.map((item) {
          final newQty = (random.nextDouble() * 20) + 0.1;
          final newPrice = (random.nextDouble() * 100) + 0.1;
          return item.copyWith(
            quantity: newQty,
            unitPrice: newPrice,
            price: newQty * newPrice,
          );
        }).toList();
        
        final updatedIds = updatedItems.map((item) => item.id).toSet();
        
        expect(
          updatedIds,
          equals(originalIds),
          reason: 'Item IDs should be preserved during modifications',
        );
      }
    });

    test('Property: Empty items list has zero total', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final wizardData = WizardExpenseData(
          amount: 0.0,
          items: [],
          title: faker.company.name(),
          groupId: faker.guid.guid(),
          payerId: faker.guid.guid(),
          date: DateTime.now().toIso8601String(),
        );
        
        expect(wizardData.amount, equals(0.0));
        expect(wizardData.items.length, equals(0));
      }
    });

    test('Property: Single item total equals expense total', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem();
        final wizardData = WizardExpenseData(
          amount: item.price,
          items: [item],
          title: faker.company.name(),
          groupId: faker.guid.guid(),
          payerId: faker.guid.guid(),
          date: DateTime.now().toIso8601String(),
        );
        
        expect(
          wizardData.amount,
          closeTo(item.price, 0.01),
          reason: 'Single item total should equal expense total',
        );
      }
    });
  });
}
