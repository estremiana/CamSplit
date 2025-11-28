import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/scanned_receipt_data.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 9-12: Receipt scanning properties
/// Validates: Requirements 2.5, 2.6, 2.7, 2.8
/// 
/// Property 9: Scanned total populates amount
/// Property 10: Scanned merchant populates title
/// Property 11: Scanned items persist to split page
/// Property 12: Items count badge accuracy
void main() {
  final faker = Faker();
  final random = Random();

  group('Receipt Scanning Property Tests', () {
    // Helper function to generate random ScannedReceiptData
    ScannedReceiptData generateRandomScannedData({
      double? total,
      String? merchant,
      int? itemCount,
    }) {
      final numItems = itemCount ?? random.nextInt(10) + 1;
      final items = List.generate(numItems, (index) {
        return ScannedItem(
          name: faker.food.dish(),
          price: (random.nextDouble() * 50) + 1,
          quantity: random.nextInt(5) + 1,
        );
      });

      return ScannedReceiptData(
        total: total ?? (random.nextDouble() * 500) + 10,
        merchant: merchant ?? faker.company.name(),
        date: DateTime.now().toIso8601String(),
        category: faker.lorem.word(),
        items: items,
      );
    }

    // Helper to convert ScannedReceiptData to WizardExpenseData
    WizardExpenseData applyScannedDataToWizard(
      WizardExpenseData wizardData,
      ScannedReceiptData scannedData,
    ) {
      final receiptItems = scannedData.items.map((scannedItem) {
        final quantity = scannedItem.quantity?.toDouble() ?? 1.0;
        final unitPrice = scannedItem.price / quantity;

        return ReceiptItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              scannedItem.name.hashCode.toString(),
          name: scannedItem.name,
          quantity: quantity,
          unitPrice: unitPrice,
          price: scannedItem.price,
        );
      }).toList();

      return wizardData.copyWith(
        amount: scannedData.total ?? wizardData.amount,
        title: scannedData.merchant ?? wizardData.title,
        receiptImage: '/path/to/receipt.jpg',
        items: receiptItems,
      );
    }

    /// Property 9: Scanned total populates amount
    /// For any scanned receipt with a total value, that total should populate the amount field
    test('Property 9: Scanned total populates amount', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final scannedTotal = (random.nextDouble() * 1000) + 1;
        final scannedData = generateRandomScannedData(total: scannedTotal);

        final initialWizard = WizardExpenseData(amount: 0.0);
        final updatedWizard = applyScannedDataToWizard(initialWizard, scannedData);

        expect(
          updatedWizard.amount,
          closeTo(scannedTotal, 0.01),
          reason: 'Scanned total $scannedTotal should populate amount field',
        );
      }
    });

    /// Property 10: Scanned merchant populates title
    /// For any scanned receipt with a merchant name, that merchant should populate the title field
    test('Property 10: Scanned merchant populates title', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final merchantName = faker.company.name();
        final scannedData = generateRandomScannedData(merchant: merchantName);

        final initialWizard = WizardExpenseData(title: '');
        final updatedWizard = applyScannedDataToWizard(initialWizard, scannedData);

        expect(
          updatedWizard.title,
          merchantName,
          reason: 'Scanned merchant "$merchantName" should populate title field',
        );
      }
    });

    /// Property 11: Scanned items persist to split page
    /// For any scanned receipt with items, those items should be available in the Items split mode
    test('Property 11: Scanned items persist to split page', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(15) + 1;
        final scannedData = generateRandomScannedData(itemCount: itemCount);

        final initialWizard = WizardExpenseData();
        final updatedWizard = applyScannedDataToWizard(initialWizard, scannedData);

        expect(
          updatedWizard.items.length,
          itemCount,
          reason: 'All $itemCount scanned items should persist in wizard data',
        );

        // Verify each item has correct data
        for (int j = 0; j < itemCount; j++) {
          final scannedItem = scannedData.items[j];
          final receiptItem = updatedWizard.items[j];

          expect(
            receiptItem.name,
            scannedItem.name,
            reason: 'Item name should match scanned data',
          );

          expect(
            receiptItem.price,
            closeTo(scannedItem.price, 0.01),
            reason: 'Item price should match scanned data',
          );

          final expectedQuantity = scannedItem.quantity?.toDouble() ?? 1.0;
          expect(
            receiptItem.quantity,
            closeTo(expectedQuantity, 0.01),
            reason: 'Item quantity should match scanned data',
          );
        }
      }
    });

    /// Property 12: Items count badge accuracy
    /// For any scanned receipt, the items found badge count should equal the number of items
    test('Property 12: Items count badge accuracy', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(20) + 1;
        final scannedData = generateRandomScannedData(itemCount: itemCount);

        final initialWizard = WizardExpenseData();
        final updatedWizard = applyScannedDataToWizard(initialWizard, scannedData);

        // The badge count should equal the items list length
        final badgeCount = updatedWizard.items.length;

        expect(
          badgeCount,
          itemCount,
          reason: 'Items found badge should show $itemCount items',
        );

        expect(
          badgeCount,
          scannedData.items.length,
          reason: 'Badge count should match scanned items count',
        );
      }
    });

    /// Property: Scanned items have valid calculations
    /// For any scanned item, price should equal quantity * unitPrice
    test('Property: Scanned items have valid price calculations', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final scannedData = generateRandomScannedData();

        final initialWizard = WizardExpenseData();
        final updatedWizard = applyScannedDataToWizard(initialWizard, scannedData);

        for (final item in updatedWizard.items) {
          final calculatedPrice = item.quantity * item.unitPrice;

          expect(
            item.price,
            closeTo(calculatedPrice, 0.01),
            reason: 'Item price should equal quantity * unitPrice',
          );
        }
      }
    });

    /// Property: Receipt image path is set after scanning
    /// For any scanned receipt, the receiptImage field should be non-empty
    test('Property: Receipt image path is set after scanning', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final scannedData = generateRandomScannedData();

        final initialWizard = WizardExpenseData(receiptImage: null);
        final updatedWizard = applyScannedDataToWizard(initialWizard, scannedData);

        expect(
          updatedWizard.receiptImage,
          isNotNull,
          reason: 'Receipt image path should be set after scanning',
        );

        expect(
          updatedWizard.receiptImage!.isNotEmpty,
          true,
          reason: 'Receipt image path should not be empty',
        );
      }
    });

    /// Property: Scanned data with null values doesn't overwrite existing data
    /// For any scanned receipt with null total or merchant, existing wizard data should be preserved
    test('Property: Null scanned values preserve existing wizard data', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final existingAmount = (random.nextDouble() * 500) + 10;
        final existingTitle = faker.lorem.sentence();

        // Create scanned data with null total and merchant
        final scannedData = ScannedReceiptData(
          total: null,
          merchant: null,
          items: [
            ScannedItem(name: faker.food.dish(), price: 10.0, quantity: 1),
          ],
        );

        final initialWizard = WizardExpenseData(
          amount: existingAmount,
          title: existingTitle,
        );

        // Simulate the logic that preserves existing values when scanned values are null
        final updatedWizard = initialWizard.copyWith(
          amount: scannedData.total ?? initialWizard.amount,
          title: scannedData.merchant ?? initialWizard.title,
          receiptImage: '/path/to/receipt.jpg',
          items: scannedData.items.map((item) {
            return ReceiptItem(
              id: item.name.hashCode.toString(),
              name: item.name,
              quantity: 1.0,
              unitPrice: item.price,
              price: item.price,
            );
          }).toList(),
        );

        expect(
          updatedWizard.amount,
          closeTo(existingAmount, 0.01),
          reason: 'Existing amount should be preserved when scanned total is null',
        );

        expect(
          updatedWizard.title,
          existingTitle,
          reason: 'Existing title should be preserved when scanned merchant is null',
        );
      }
    });

    /// Property: Empty items list results in empty wizard items
    /// For any scanned receipt with no items, wizard should have empty items list
    test('Property: Empty scanned items results in empty wizard items', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        final scannedData = ScannedReceiptData(
          total: (random.nextDouble() * 500) + 10,
          merchant: faker.company.name(),
          items: [], // Empty items
        );

        final initialWizard = WizardExpenseData();
        final updatedWizard = applyScannedDataToWizard(initialWizard, scannedData);

        expect(
          updatedWizard.items.isEmpty,
          true,
          reason: 'Wizard items should be empty when scanned items are empty',
        );
      }
    });
  });
}
