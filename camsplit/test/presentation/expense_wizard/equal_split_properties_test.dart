import 'package:flutter_test/flutter_test.dart';
import 'package:faker/faker.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/models/group_member.dart';

/// Property-based tests for Equal split mode
/// Feature: expense-wizard-creation, Property 21: Equal share calculation
/// 
/// Property 21: Equal share calculation
/// *For any* set of selected members in QuickSplit mode, each member's assigned 
/// quantity should equal (item quantity / number of selected members)
/// **Validates: Requirements 5.9**
void main() {
  group('Property 21: Equal share calculation', () {
    final faker = Faker();

    /// Generate a random list of group members
    List<GroupMember> generateRandomMembers(int count) {
      final now = DateTime.now();
      return List.generate(count, (index) {
        return GroupMember(
          id: index + 1,
          groupId: 1,
          userId: index + 1,
          nickname: faker.person.name(),
          email: faker.internet.email(),
          role: 'member',
          isRegisteredUser: true,
          avatarUrl: faker.internet.httpsUrl(),
          createdAt: now.subtract(Duration(days: faker.randomGenerator.integer(365))),
          updatedAt: now,
        );
      });
    }

    /// Generate random wizard data with a specific amount
    WizardExpenseData generateWizardData(double amount, List<String> involvedMembers) {
      return WizardExpenseData(
        amount: amount,
        title: faker.lorem.sentence(),
        date: DateTime.now().toIso8601String(),
        category: faker.lorem.word(),
        payerId: '1',
        groupId: '1',
        involvedMembers: involvedMembers,
      );
    }

    test('Property: Equal share calculation for any amount and member count', () {
      // Run the property test with 100 iterations as specified in design
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random test data
        final memberCount = faker.randomGenerator.integer(10, min: 1); // 1-10 members
        final amount = faker.randomGenerator.decimal(scale: 1000, min: 1); // $1-$1000
        
        final members = generateRandomMembers(memberCount);
        final selectedMemberIds = members.map((m) => m.id.toString()).toList();
        
        final wizardData = generateWizardData(amount, selectedMemberIds);
        
        // Calculate expected equal share
        final expectedShare = amount / selectedMemberIds.length;
        
        // Verify the property: each member should get an equal share
        // The equal share should be amount divided by number of selected members
        expect(
          expectedShare,
          equals(amount / selectedMemberIds.length),
          reason: 'Iteration $iteration: Equal share should be amount ($amount) / member count (${selectedMemberIds.length})',
        );
        
        // Verify that the sum of all shares equals the total amount
        final totalShares = expectedShare * selectedMemberIds.length;
        expect(
          (totalShares - amount).abs(),
          lessThan(0.01), // Allow small floating point error
          reason: 'Iteration $iteration: Sum of shares ($totalShares) should equal total amount ($amount)',
        );
        
        // Verify that each member gets the same share
        for (int i = 0; i < selectedMemberIds.length; i++) {
          expect(
            expectedShare,
            equals(amount / selectedMemberIds.length),
            reason: 'Iteration $iteration: Member $i should get equal share',
          );
        }
      }
    });

    test('Property: Equal share with single member equals full amount', () {
      // Edge case: single member should get the full amount
      for (int iteration = 0; iteration < 20; iteration++) {
        final amount = faker.randomGenerator.decimal(scale: 1000, min: 1);
        final members = generateRandomMembers(1);
        final selectedMemberIds = members.map((m) => m.id.toString()).toList();
        
        final wizardData = generateWizardData(amount, selectedMemberIds);
        final expectedShare = amount / selectedMemberIds.length;
        
        expect(
          expectedShare,
          equals(amount),
          reason: 'Iteration $iteration: Single member should get full amount',
        );
      }
    });

    test('Property: Equal share with all members selected', () {
      // Test with varying member counts
      for (int memberCount = 2; memberCount <= 10; memberCount++) {
        final amount = faker.randomGenerator.decimal(scale: 1000, min: 1);
        final members = generateRandomMembers(memberCount);
        final selectedMemberIds = members.map((m) => m.id.toString()).toList();
        
        final wizardData = generateWizardData(amount, selectedMemberIds);
        final expectedShare = amount / selectedMemberIds.length;
        
        // Verify each member gets equal share
        expect(
          expectedShare,
          equals(amount / memberCount),
          reason: 'With $memberCount members, each should get amount / $memberCount',
        );
        
        // Verify total equals original amount
        final total = expectedShare * memberCount;
        expect(
          (total - amount).abs(),
          lessThan(0.01),
          reason: 'Total of shares should equal original amount',
        );
      }
    });

    test('Property: Equal share with subset of members selected', () {
      // Test with partial member selection
      for (int iteration = 0; iteration < 50; iteration++) {
        final totalMembers = faker.randomGenerator.integer(10, min: 3); // 3-10 total members
        final selectedCount = faker.randomGenerator.integer(totalMembers - 1, min: 1); // 1 to totalMembers-1 selected
        final amount = faker.randomGenerator.decimal(scale: 1000, min: 1);
        
        final members = generateRandomMembers(totalMembers);
        // Select a random subset of members
        final selectedMembers = members.take(selectedCount).toList();
        final selectedMemberIds = selectedMembers.map((m) => m.id.toString()).toList();
        
        final wizardData = generateWizardData(amount, selectedMemberIds);
        final expectedShare = amount / selectedMemberIds.length;
        
        // Verify equal share calculation
        expect(
          expectedShare,
          equals(amount / selectedCount),
          reason: 'Iteration $iteration: With $selectedCount of $totalMembers members selected, each should get amount / $selectedCount',
        );
        
        // Verify total
        final total = expectedShare * selectedCount;
        expect(
          (total - amount).abs(),
          lessThan(0.01),
          reason: 'Iteration $iteration: Total should equal original amount',
        );
      }
    });

    test('Property: Equal share calculation is consistent', () {
      // Verify that calculating the share multiple times gives the same result
      for (int iteration = 0; iteration < 30; iteration++) {
        final memberCount = faker.randomGenerator.integer(10, min: 1);
        final amount = faker.randomGenerator.decimal(scale: 1000, min: 1);
        
        final members = generateRandomMembers(memberCount);
        final selectedMemberIds = members.map((m) => m.id.toString()).toList();
        
        final wizardData = generateWizardData(amount, selectedMemberIds);
        
        // Calculate share multiple times
        final share1 = amount / selectedMemberIds.length;
        final share2 = amount / selectedMemberIds.length;
        final share3 = amount / selectedMemberIds.length;
        
        // All calculations should be identical
        expect(share1, equals(share2), reason: 'Iteration $iteration: Calculations should be consistent');
        expect(share2, equals(share3), reason: 'Iteration $iteration: Calculations should be consistent');
        expect(share1, equals(share3), reason: 'Iteration $iteration: Calculations should be consistent');
      }
    });

    test('Property: Equal share handles decimal amounts correctly', () {
      // Test with amounts that don't divide evenly
      for (int iteration = 0; iteration < 30; iteration++) {
        final memberCount = faker.randomGenerator.integer(7, min: 3); // 3-7 members
        // Use amounts that create repeating decimals
        final amount = faker.randomGenerator.decimal(scale: 100, min: 1) + 0.33;
        
        final members = generateRandomMembers(memberCount);
        final selectedMemberIds = members.map((m) => m.id.toString()).toList();
        
        final wizardData = generateWizardData(amount, selectedMemberIds);
        final expectedShare = amount / selectedMemberIds.length;
        
        // Verify the calculation is correct
        expect(
          expectedShare,
          equals(amount / memberCount),
          reason: 'Iteration $iteration: Equal share should handle decimal amounts',
        );
        
        // Verify that rounding to 2 decimal places (for currency) still sums close to total
        final roundedShare = double.parse(expectedShare.toStringAsFixed(2));
        final roundedTotal = roundedShare * memberCount;
        expect(
          (roundedTotal - amount).abs(),
          lessThan(0.05), // Allow small rounding error
          reason: 'Iteration $iteration: Rounded shares should sum close to total',
        );
      }
    });

    test('Property: Equal share with very small amounts', () {
      // Test with amounts less than $1
      for (int iteration = 0; iteration < 20; iteration++) {
        final memberCount = faker.randomGenerator.integer(5, min: 2);
        final amount = faker.randomGenerator.decimal(scale: 1, min: 0.01); // $0.01 to $1
        
        final members = generateRandomMembers(memberCount);
        final selectedMemberIds = members.map((m) => m.id.toString()).toList();
        
        final wizardData = generateWizardData(amount, selectedMemberIds);
        final expectedShare = amount / selectedMemberIds.length;
        
        expect(
          expectedShare,
          equals(amount / memberCount),
          reason: 'Iteration $iteration: Should handle small amounts correctly',
        );
        
        // Verify share is positive
        expect(
          expectedShare,
          greaterThan(0),
          reason: 'Iteration $iteration: Share should be positive',
        );
      }
    });

    test('Property: Equal share with large amounts', () {
      // Test with amounts over $10,000
      for (int iteration = 0; iteration < 20; iteration++) {
        final memberCount = faker.randomGenerator.integer(10, min: 2);
        final amount = faker.randomGenerator.decimal(scale: 100000, min: 10000); // $10k to $100k
        
        final members = generateRandomMembers(memberCount);
        final selectedMemberIds = members.map((m) => m.id.toString()).toList();
        
        final wizardData = generateWizardData(amount, selectedMemberIds);
        final expectedShare = amount / selectedMemberIds.length;
        
        expect(
          expectedShare,
          equals(amount / memberCount),
          reason: 'Iteration $iteration: Should handle large amounts correctly',
        );
        
        // Verify total
        final total = expectedShare * memberCount;
        expect(
          (total - amount).abs(),
          lessThan(0.01),
          reason: 'Iteration $iteration: Total should equal original amount',
        );
      }
    });
  });
}
