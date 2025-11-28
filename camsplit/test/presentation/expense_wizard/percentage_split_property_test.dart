import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 6: Percentage split validation
/// Feature: expense-wizard-creation, Property 8: Valid split enables submission
/// Validates: Requirements 9.2, 9.4, 9.5, 9.6
///
/// Property 6: For any expense in Percentage split mode, if the sum of all 
/// percentages does not equal 100% (within 0.1% tolerance), the Create Expense 
/// button should be disabled and an error message should display
///
/// Property 8: For any expense with valid split configuration, the Create 
/// Expense button should be enabled
void main() {
  final faker = Faker();
  final random = Random();

  group('Percentage Split Property Tests', () {
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
        splitType: SplitType.percentage,
        splitDetails: splitDetails ?? {},
      );
    }

    /// Property 6: Percentage split validation
    /// For any expense in Percentage split mode, if the sum of all percentages
    /// does not equal 100% (within 0.1% tolerance), isSplitValid should return false
    test('Property 6: Invalid percentage splits (sum != 100%) should be invalid', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of members (2-10)
        final memberCount = random.nextInt(9) + 2;
        final members = List.generate(memberCount, (i) => 'member_$i');
        
        // Create invalid percentage split where sum != 100
        final percentages = <String, double>{};
        
        // Generate random percentages that don't sum to 100
        // Use a target that's clearly not 100 (outside tolerance)
        final targetSum = random.nextBool()
            ? random.nextDouble() * 80 // Too low (0-80)
            : 100 + (random.nextDouble() * 50) + 1; // Too high (101-150)
        
        double remaining = targetSum;
        for (int j = 0; j < memberCount - 1; j++) {
          final pct = random.nextDouble() * (remaining / 2);
          percentages[members[j]] = pct;
          remaining -= pct;
        }
        percentages[members.last] = remaining;
        
        final wizardData = generateRandomWizardData(
          splitDetails: percentages,
        );
        
        final totalPct = percentages.values.fold(0.0, (sum, pct) => sum + pct);
        
        // Only test if sum is clearly outside tolerance
        if ((totalPct - 100.0).abs() > 0.1) {
          expect(
            wizardData.isSplitValid(),
            false,
            reason: 'Percentage sum $totalPct should be invalid (not 100%)',
          );
        }
      }
    });

    test('Property 6: Valid percentage splits (sum = 100%) should be valid', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of members (2-10)
        final memberCount = random.nextInt(9) + 2;
        final members = List.generate(memberCount, (i) => 'member_$i');
        
        // Create valid percentage split where sum = 100
        final percentages = <String, double>{};
        double remaining = 100.0;
        
        for (int j = 0; j < memberCount - 1; j++) {
          // Ensure we don't take too much from remaining
          final maxPct = remaining - (memberCount - j - 1) * 0.1;
          final pct = random.nextDouble() * maxPct;
          percentages[members[j]] = pct;
          remaining -= pct;
        }
        // Last member gets exactly what's remaining to sum to 100
        percentages[members.last] = remaining;
        
        final wizardData = generateRandomWizardData(
          splitDetails: percentages,
        );
        
        final totalPct = percentages.values.fold(0.0, (sum, pct) => sum + pct);
        
        expect(
          wizardData.isSplitValid(),
          true,
          reason: 'Percentage sum $totalPct should be valid (equals 100%)',
        );
        
        // Verify sum is actually 100 (within tolerance)
        expect(
          (totalPct - 100.0).abs(),
          lessThanOrEqualTo(0.1),
          reason: 'Total percentage should be within 0.1% of 100%',
        );
      }
    });

    test('Property 6: Edge cases at 100% boundary', () {
      // Test exact 100%
      final exact100 = generateRandomWizardData(
        splitDetails: {
          'member_1': 50.0,
          'member_2': 50.0,
        },
      );
      expect(exact100.isSplitValid(), true);
      
      // Test 100% + 0.1% (at tolerance boundary - should be valid)
      final at100Plus = generateRandomWizardData(
        splitDetails: {
          'member_1': 50.05,
          'member_2': 50.05,
        },
      );
      expect(at100Plus.isSplitValid(), true);
      
      // Test 100% - 0.1% (at tolerance boundary - should be valid)
      final at100Minus = generateRandomWizardData(
        splitDetails: {
          'member_1': 49.95,
          'member_2': 49.95,
        },
      );
      expect(at100Minus.isSplitValid(), true);
      
      // Test 100% + 0.2% (outside tolerance - should be invalid)
      final outside100Plus = generateRandomWizardData(
        splitDetails: {
          'member_1': 50.1,
          'member_2': 50.1,
        },
      );
      expect(outside100Plus.isSplitValid(), false);
      
      // Test 100% - 0.2% (outside tolerance - should be invalid)
      final outside100Minus = generateRandomWizardData(
        splitDetails: {
          'member_1': 49.9,
          'member_2': 49.9,
        },
      );
      expect(outside100Minus.isSplitValid(), false);
    });

    test('Property 6: Empty split details should be invalid', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final wizardData = generateRandomWizardData(
          splitDetails: {},
        );
        
        expect(
          wizardData.isSplitValid(),
          false,
          reason: 'Empty split details should be invalid',
        );
      }
    });

    /// Property 8: Valid split enables submission
    /// For any expense with valid split configuration, isSplitValid should return true
    test('Property 8: Valid percentage configuration enables submission', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of members
        final memberCount = random.nextInt(8) + 2;
        final members = List.generate(memberCount, (i) => 'member_$i');
        
        // Create valid percentage split
        final percentages = <String, double>{};
        double remaining = 100.0;
        
        for (int j = 0; j < memberCount - 1; j++) {
          final maxPct = remaining - (memberCount - j - 1) * 0.1;
          final pct = random.nextDouble() * maxPct;
          percentages[members[j]] = pct;
          remaining -= pct;
        }
        percentages[members.last] = remaining;
        
        final wizardData = generateRandomWizardData(
          amount: (random.nextDouble() * 1000) + 10,
          groupId: faker.guid.guid(),
          payerId: faker.guid.guid(),
          date: DateTime.now().toIso8601String(),
          splitDetails: percentages,
        );
        
        // Valid split should enable submission
        expect(
          wizardData.isSplitValid(),
          true,
          reason: 'Valid percentage split should enable submission',
        );
      }
    });

    test('Property 8: Invalid percentage configuration disables submission', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random number of members
        final memberCount = random.nextInt(8) + 2;
        final members = List.generate(memberCount, (i) => 'member_$i');
        
        // Create invalid percentage split (clearly not 100%)
        final percentages = <String, double>{};
        for (final member in members) {
          // Random percentages that won't sum to 100
          percentages[member] = random.nextDouble() * 30;
        }
        
        final wizardData = generateRandomWizardData(
          splitDetails: percentages,
        );
        
        final totalPct = percentages.values.fold(0.0, (sum, pct) => sum + pct);
        
        // Only test if clearly outside tolerance
        if ((totalPct - 100.0).abs() > 0.1) {
          expect(
            wizardData.isSplitValid(),
            false,
            reason: 'Invalid percentage split should disable submission',
          );
        }
      }
    });

    test('Property: Percentage values can be any non-negative number', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        // Test with various percentage distributions
        final testCases = [
          // Unequal distribution
          {'member_1': 70.0, 'member_2': 30.0},
          // Very unequal
          {'member_1': 99.0, 'member_2': 1.0},
          // Three members
          {'member_1': 33.33, 'member_2': 33.33, 'member_3': 33.34},
          // Many members with small percentages
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
        ];
        
        for (final testCase in testCases) {
          final wizardData = generateRandomWizardData(
            splitDetails: testCase,
          );
          
          final totalPct = testCase.values.fold(0.0, (sum, pct) => sum + pct);
          final isValid = (totalPct - 100.0).abs() <= 0.1;
          
          expect(
            wizardData.isSplitValid(),
            isValid,
            reason: 'Split with total $totalPct should be ${isValid ? "valid" : "invalid"}',
          );
        }
      }
    });
  });
}
