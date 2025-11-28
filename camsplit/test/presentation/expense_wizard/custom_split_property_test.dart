import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 7: Custom split validation
/// Validates: Requirements 9.3, 9.4, 9.5
///
/// Property 7: For any expense in Custom split mode, if the sum of all custom 
/// amounts does not equal the expense total (within 0.05 tolerance), the Create 
/// Expense button should be disabled and an error message should display
void main() {
  final faker = Faker();
  final random = Random();

  group('Custom Split Property Tests', () {
    // Helper function to generate random WizardExpenseData
    WizardExpenseData generateRandomWizardData({
      double? amount,
      String? groupId,
      String? payerId,
      String? date,
      Map<String, double>? splitDetails,
    }) {
      return WizardExpenseData(
        amount: amount ?? (random.nextDouble() * 1000) + 10,
        title: faker.lorem.word(),
        groupId: groupId ?? faker.guid.guid(),
        payerId: payerId ?? faker.guid.guid(),
        date: date ?? DateTime.now().toIso8601String(),
        category: faker.lorem.word(),
        splitType: SplitType.custom,
        splitDetails: splitDetails ?? {},
      );
    }

    /// Property 7: Custom split validation
    /// For any expense in Custom split mode, if the sum of all custom amounts
    /// does not equal the expense total (within 0.05 tolerance), isSplitValid 
    /// should return false
    test('Property 7: Invalid custom splits (sum != total) should be invalid', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random expense amount
        final totalAmount = (random.nextDouble() * 1000) + 10;
        
        // Generate random number of members (2-10)
        final memberCount = random.nextInt(9) + 2;
        final members = List.generate(memberCount, (i) => 'member_$i');
        
        // Create invalid custom split where sum != total
        final amounts = <String, double>{};
        
        // Generate random amounts that don't sum to total
        // Use a target that's clearly not equal to totalAmount (outside tolerance)
        final targetSum = random.nextBool()
            ? totalAmount * (random.nextDouble() * 0.5 + 0.1) // Too low (10%-60% of total)
            : totalAmount * (random.nextDouble() * 0.5 + 1.1); // Too high (110%-160% of total)
        
        double remaining = targetSum;
        for (int j = 0; j < memberCount - 1; j++) {
          final amt = random.nextDouble() * (remaining / 2);
          amounts[members[j]] = amt;
          remaining -= amt;
        }
        amounts[members.last] = remaining;
        
        final wizardData = generateRandomWizardData(
          amount: totalAmount,
          splitDetails: amounts,
        );
        
        final totalSplit = amounts.values.fold(0.0, (sum, amt) => sum + amt);
        
        // Only test if sum is clearly outside tolerance
        if ((totalSplit - totalAmount).abs() > 0.05) {
          expect(
            wizardData.isSplitValid(),
            false,
            reason: 'Amount sum \$${totalSplit.toStringAsFixed(2)} should be invalid (not equal to \$${totalAmount.toStringAsFixed(2)})',
          );
        }
      }
    });

    test('Property 7: Valid custom splits (sum = total) should be valid', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random expense amount
        final totalAmount = (random.nextDouble() * 1000) + 10;
        
        // Generate random number of members (2-10)
        final memberCount = random.nextInt(9) + 2;
        final members = List.generate(memberCount, (i) => 'member_$i');
        
        // Create valid custom split where sum = total
        final amounts = <String, double>{};
        double remaining = totalAmount;
        
        for (int j = 0; j < memberCount - 1; j++) {
          // Ensure we don't take too much from remaining
          final maxAmt = remaining - (memberCount - j - 1) * 0.01;
          final amt = random.nextDouble() * maxAmt;
          amounts[members[j]] = amt;
          remaining -= amt;
        }
        // Last member gets exactly what's remaining to sum to total
        amounts[members.last] = remaining;
        
        final wizardData = generateRandomWizardData(
          amount: totalAmount,
          splitDetails: amounts,
        );
        
        final totalSplit = amounts.values.fold(0.0, (sum, amt) => sum + amt);
        
        expect(
          wizardData.isSplitValid(),
          true,
          reason: 'Amount sum \$${totalSplit.toStringAsFixed(2)} should be valid (equals \$${totalAmount.toStringAsFixed(2)})',
        );
        
        // Verify sum is actually equal to total (within tolerance)
        expect(
          (totalSplit - totalAmount).abs(),
          lessThanOrEqualTo(0.05),
          reason: 'Total split amount should be within \$0.05 of expense total',
        );
      }
    });

    test('Property 7: Edge cases at total boundary', () {
      const totalAmount = 100.0;
      
      // Test exact total
      final exactTotal = generateRandomWizardData(
        amount: totalAmount,
        splitDetails: {
          'member_1': 50.0,
          'member_2': 50.0,
        },
      );
      expect(exactTotal.isSplitValid(), true);
      
      // Test total + 0.05 (at tolerance boundary - should be valid)
      final atTotalPlus = generateRandomWizardData(
        amount: totalAmount,
        splitDetails: {
          'member_1': 50.025,
          'member_2': 50.025,
        },
      );
      expect(atTotalPlus.isSplitValid(), true);
      
      // Test total - 0.05 (at tolerance boundary - should be valid)
      final atTotalMinus = generateRandomWizardData(
        amount: totalAmount,
        splitDetails: {
          'member_1': 49.975,
          'member_2': 49.975,
        },
      );
      expect(atTotalMinus.isSplitValid(), true);
      
      // Test total + 0.10 (outside tolerance - should be invalid)
      final outsideTotalPlus = generateRandomWizardData(
        amount: totalAmount,
        splitDetails: {
          'member_1': 50.05,
          'member_2': 50.05,
        },
      );
      expect(outsideTotalPlus.isSplitValid(), false);
      
      // Test total - 0.10 (outside tolerance - should be invalid)
      final outsideTotalMinus = generateRandomWizardData(
        amount: totalAmount,
        splitDetails: {
          'member_1': 49.95,
          'member_2': 49.95,
        },
      );
      expect(outsideTotalMinus.isSplitValid(), false);
    });

    test('Property 7: Empty split details should be invalid', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final totalAmount = (random.nextDouble() * 1000) + 10;
        final wizardData = generateRandomWizardData(
          amount: totalAmount,
          splitDetails: {},
        );
        
        expect(
          wizardData.isSplitValid(),
          false,
          reason: 'Empty split details should be invalid',
        );
      }
    });

    test('Property 7: Valid split enables submission', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random expense amount
        final totalAmount = (random.nextDouble() * 1000) + 10;
        
        // Generate random number of members
        final memberCount = random.nextInt(8) + 2;
        final members = List.generate(memberCount, (i) => 'member_$i');
        
        // Create valid custom split
        final amounts = <String, double>{};
        double remaining = totalAmount;
        
        for (int j = 0; j < memberCount - 1; j++) {
          final maxAmt = remaining - (memberCount - j - 1) * 0.01;
          final amt = random.nextDouble() * maxAmt;
          amounts[members[j]] = amt;
          remaining -= amt;
        }
        amounts[members.last] = remaining;
        
        final wizardData = generateRandomWizardData(
          amount: totalAmount,
          groupId: faker.guid.guid(),
          payerId: faker.guid.guid(),
          date: DateTime.now().toIso8601String(),
          splitDetails: amounts,
        );
        
        // Valid split should enable submission
        expect(
          wizardData.isSplitValid(),
          true,
          reason: 'Valid custom split should enable submission',
        );
      }
    });

    test('Property 7: Invalid custom configuration disables submission', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random expense amount
        final totalAmount = (random.nextDouble() * 1000) + 10;
        
        // Generate random number of members
        final memberCount = random.nextInt(8) + 2;
        final members = List.generate(memberCount, (i) => 'member_$i');
        
        // Create invalid custom split (clearly not equal to total)
        final amounts = <String, double>{};
        for (final member in members) {
          // Random amounts that won't sum to total
          amounts[member] = random.nextDouble() * (totalAmount / memberCount / 2);
        }
        
        final wizardData = generateRandomWizardData(
          amount: totalAmount,
          splitDetails: amounts,
        );
        
        final totalSplit = amounts.values.fold(0.0, (sum, amt) => sum + amt);
        
        // Only test if clearly outside tolerance
        if ((totalSplit - totalAmount).abs() > 0.05) {
          expect(
            wizardData.isSplitValid(),
            false,
            reason: 'Invalid custom split should disable submission',
          );
        }
      }
    });

    test('Property: Custom amounts can be any non-negative number', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final totalAmount = 100.0;
        
        // Test with various amount distributions
        final testCases = [
          // Unequal distribution
          {'member_1': 70.0, 'member_2': 30.0},
          // Very unequal
          {'member_1': 99.0, 'member_2': 1.0},
          // Three members
          {'member_1': 33.33, 'member_2': 33.33, 'member_3': 33.34},
          // Many members with small amounts
          {
            'member_1': 10.0,
            'member_2': 10.0,
            'member_3': 10.0,
            'member_4': 10.0,
            'member_5': 10.0,
            'member_6': 10.0,
            'member_7': 10.0,
            'member_8': 10.0,
            'member_9': 10.0,
            'member_10': 10.0,
          },
          // One member pays all
          {'member_1': 100.0},
          // Decimal amounts
          {'member_1': 33.33, 'member_2': 66.67},
        ];
        
        for (final testCase in testCases) {
          final wizardData = generateRandomWizardData(
            amount: totalAmount,
            splitDetails: testCase,
          );
          
          final totalSplit = testCase.values.fold(0.0, (sum, amt) => sum + amt);
          final isValid = (totalSplit - totalAmount).abs() <= 0.05;
          
          expect(
            wizardData.isSplitValid(),
            isValid,
            reason: 'Split with total \$${totalSplit.toStringAsFixed(2)} should be ${isValid ? "valid" : "invalid"}',
          );
        }
      }
    });

    test('Property: Custom split works with various expense amounts', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Test with various expense amounts
        final testAmounts = [
          0.01, // Very small
          1.00, // Small
          10.50, // Medium
          100.00, // Large
          999.99, // Very large
          1234.56, // Random decimal
        ];
        
        for (final totalAmount in testAmounts) {
          // Create valid split
          final amounts = {
            'member_1': totalAmount / 2,
            'member_2': totalAmount / 2,
          };
          
          final wizardData = generateRandomWizardData(
            amount: totalAmount,
            splitDetails: amounts,
          );
          
          expect(
            wizardData.isSplitValid(),
            true,
            reason: 'Valid split for amount \$${totalAmount.toStringAsFixed(2)} should be valid',
          );
        }
      }
    });

    test('Property: Zero amounts for some members are allowed', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final totalAmount = (random.nextDouble() * 1000) + 10;
        
        // Some members pay, others don't
        final amounts = {
          'member_1': totalAmount,
          'member_2': 0.0,
          'member_3': 0.0,
        };
        
        final wizardData = generateRandomWizardData(
          amount: totalAmount,
          splitDetails: amounts,
        );
        
        // Should be valid as long as total equals expense amount
        expect(
          wizardData.isSplitValid(),
          true,
          reason: 'Split with zero amounts for some members should be valid if total matches',
        );
      }
    });
  });
}
