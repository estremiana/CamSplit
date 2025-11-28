import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 3: Amount validation
/// Validates: Requirements 2.2, 2.10
/// 
/// Property: For any amount value, if it is less than or equal to zero, 
/// the Next button should be disabled (isAmountValid should return false)
void main() {
  final faker = Faker();
  final random = Random();

  group('WizardExpenseData Property Tests', () {
    // Helper function to generate random WizardExpenseData
    WizardExpenseData generateRandomWizardData({
      double? amount,
      String? title,
      String? groupId,
      String? payerId,
      String? date,
      SplitType? splitType,
      Map<String, double>? splitDetails,
      List<String>? involvedMembers,
      List<ReceiptItem>? items,
    }) {
      return WizardExpenseData(
        amount: amount ?? (random.nextDouble() * 1000),
        title: title ?? faker.lorem.word(),
        groupId: groupId ?? faker.guid.guid(),
        payerId: payerId ?? faker.guid.guid(),
        date: date ?? DateTime.now().toIso8601String(),
        category: faker.lorem.word(),
        splitType: splitType ?? SplitType.equal,
        splitDetails: splitDetails ?? {},
        involvedMembers: involvedMembers ?? [],
        items: items ?? [],
      );
    }

    /// Property 3: Amount validation
    /// For any amount value, if it is less than or equal to zero,
    /// isAmountValid should return false
    test('Property 3: Amount validation - amounts <= 0 should be invalid', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random invalid amounts (negative or zero)
        final invalidAmount = random.nextBool() 
            ? 0.0 
            : -(random.nextDouble() * 1000);
        
        final wizardData = generateRandomWizardData(amount: invalidAmount);
        
        expect(
          wizardData.isAmountValid(),
          false,
          reason: 'Amount $invalidAmount should be invalid',
        );
      }
    });

    test('Property 3: Amount validation - amounts > 0 should be valid', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random valid amounts (positive)
        final validAmount = (random.nextDouble() * 10000) + 0.01;
        
        final wizardData = generateRandomWizardData(amount: validAmount);
        
        expect(
          wizardData.isAmountValid(),
          true,
          reason: 'Amount $validAmount should be valid',
        );
      }
    });

    test('Property 3: Amount validation - edge case at zero boundary', () {
      // Test exact zero
      final zeroData = generateRandomWizardData(amount: 0.0);
      expect(zeroData.isAmountValid(), false);
      
      // Test very small positive amount
      final tinyPositive = generateRandomWizardData(amount: 0.0001);
      expect(tinyPositive.isAmountValid(), true);
      
      // Test very small negative amount
      final tinyNegative = generateRandomWizardData(amount: -0.0001);
      expect(tinyNegative.isAmountValid(), false);
    });

    test('Property: Details validation requires groupId, payerId, and date', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Test with all fields present
        final validData = generateRandomWizardData(
          groupId: faker.guid.guid(),
          payerId: faker.guid.guid(),
          date: DateTime.now().toIso8601String(),
        );
        expect(validData.isDetailsValid(), true);
        
        // Test with missing groupId
        final noGroupId = generateRandomWizardData(
          groupId: '',
          payerId: faker.guid.guid(),
          date: DateTime.now().toIso8601String(),
        );
        expect(noGroupId.isDetailsValid(), false);
        
        // Test with missing payerId
        final noPayerId = generateRandomWizardData(
          groupId: faker.guid.guid(),
          payerId: '',
          date: DateTime.now().toIso8601String(),
        );
        expect(noPayerId.isDetailsValid(), false);
        
        // Test with missing date
        final noDate = generateRandomWizardData(
          groupId: faker.guid.guid(),
          payerId: faker.guid.guid(),
          date: '',
        );
        expect(noDate.isDetailsValid(), false);
      }
    });

    test('Property: Equal split validation requires involved members', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Valid equal split with members
        final memberCount = random.nextInt(10) + 1;
        final members = List.generate(
          memberCount,
          (index) => faker.guid.guid(),
        );
        
        final validSplit = generateRandomWizardData(
          splitType: SplitType.equal,
          involvedMembers: members,
        );
        expect(validSplit.isSplitValid(), true);
        
        // Invalid equal split without members
        final invalidSplit = generateRandomWizardData(
          splitType: SplitType.equal,
          involvedMembers: [],
        );
        expect(invalidSplit.isSplitValid(), false);
      }
    });

    test('Property: Percentage split validation requires sum = 100%', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of members
        final memberCount = random.nextInt(5) + 2;
        final members = List.generate(memberCount, (i) => 'member_$i');
        
        // Create valid percentage split (sum = 100)
        final percentages = <String, double>{};
        double remaining = 100.0;
        for (int j = 0; j < memberCount - 1; j++) {
          final pct = random.nextDouble() * remaining;
          percentages[members[j]] = pct;
          remaining -= pct;
        }
        percentages[members.last] = remaining;
        
        final validSplit = generateRandomWizardData(
          splitType: SplitType.percentage,
          splitDetails: percentages,
        );
        expect(validSplit.isSplitValid(), true);
        
        // Create invalid percentage split (sum != 100)
        final invalidPercentages = <String, double>{};
        for (final member in members) {
          invalidPercentages[member] = random.nextDouble() * 50;
        }
        
        final invalidSplit = generateRandomWizardData(
          splitType: SplitType.percentage,
          splitDetails: invalidPercentages,
        );
        
        final totalPct = invalidPercentages.values.fold(0.0, (sum, pct) => sum + pct);
        if ((totalPct - 100.0).abs() > 0.1) {
          expect(invalidSplit.isSplitValid(), false);
        }
      }
    });

    test('Property: Custom split validation requires sum = total amount', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final totalAmount = (random.nextDouble() * 1000) + 10;
        final memberCount = random.nextInt(5) + 2;
        final members = List.generate(memberCount, (i) => 'member_$i');
        
        // Create valid custom split (sum = total)
        final amounts = <String, double>{};
        double remaining = totalAmount;
        for (int j = 0; j < memberCount - 1; j++) {
          final amt = random.nextDouble() * remaining;
          amounts[members[j]] = amt;
          remaining -= amt;
        }
        amounts[members.last] = remaining;
        
        final validSplit = generateRandomWizardData(
          amount: totalAmount,
          splitType: SplitType.custom,
          splitDetails: amounts,
        );
        expect(validSplit.isSplitValid(), true);
        
        // Create invalid custom split (sum != total)
        final invalidAmounts = <String, double>{};
        for (final member in members) {
          invalidAmounts[member] = random.nextDouble() * 100;
        }
        
        final invalidSplit = generateRandomWizardData(
          amount: totalAmount,
          splitType: SplitType.custom,
          splitDetails: invalidAmounts,
        );
        
        final totalSplit = invalidAmounts.values.fold(0.0, (sum, amt) => sum + amt);
        if ((totalSplit - totalAmount).abs() > 0.05) {
          expect(invalidSplit.isSplitValid(), false);
        }
      }
    });

    test('Property: Items split validation requires all items fully assigned', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(5) + 1;
        final items = <ReceiptItem>[];
        
        // Create items with full assignments
        for (int j = 0; j < itemCount; j++) {
          final quantity = (random.nextDouble() * 10) + 1;
          final unitPrice = (random.nextDouble() * 50) + 1;
          
          // Fully assign the item
          final assignments = <String, double>{
            'member_1': quantity / 2,
            'member_2': quantity / 2,
          };
          
          items.add(ReceiptItem(
            id: 'item_$j',
            name: faker.food.dish(),
            quantity: quantity,
            unitPrice: unitPrice,
            price: quantity * unitPrice,
            assignments: assignments,
          ));
        }
        
        final validSplit = generateRandomWizardData(
          splitType: SplitType.items,
          items: items,
        );
        expect(validSplit.isSplitValid(), true);
        
        // Create items with partial assignments
        final partialItems = <ReceiptItem>[];
        for (int j = 0; j < itemCount; j++) {
          final quantity = (random.nextDouble() * 10) + 1;
          final unitPrice = (random.nextDouble() * 50) + 1;
          
          // Partially assign the item
          final assignments = <String, double>{
            'member_1': quantity / 3, // Only 1/3 assigned
          };
          
          partialItems.add(ReceiptItem(
            id: 'item_$j',
            name: faker.food.dish(),
            quantity: quantity,
            unitPrice: unitPrice,
            price: quantity * unitPrice,
            assignments: assignments,
          ));
        }
        
        final invalidSplit = generateRandomWizardData(
          splitType: SplitType.items,
          items: partialItems,
        );
        expect(invalidSplit.isSplitValid(), false);
      }
    });

    test('Property: copyWith preserves unchanged fields', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final original = generateRandomWizardData();
        
        // Copy with only amount changed
        final copied = original.copyWith(amount: 999.99);
        
        expect(copied.amount, 999.99);
        expect(copied.title, original.title);
        expect(copied.groupId, original.groupId);
        expect(copied.payerId, original.payerId);
        expect(copied.date, original.date);
        expect(copied.splitType, original.splitType);
      }
    });

    test('Property: toJson and fromJson round trip preserves data', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final original = generateRandomWizardData(
          amount: (random.nextDouble() * 1000) + 1,
          groupId: faker.guid.guid(),
          payerId: faker.guid.guid(),
          date: DateTime.now().toIso8601String(),
        );
        
        final json = original.toJson();
        final restored = WizardExpenseData.fromJson(json);
        
        expect(restored.amount, closeTo(original.amount, 0.01));
        expect(restored.title, original.title);
        expect(restored.groupId, original.groupId);
        expect(restored.payerId, original.payerId);
        expect(restored.date, original.date);
        expect(restored.splitType, original.splitType);
      }
    });
  });
}
