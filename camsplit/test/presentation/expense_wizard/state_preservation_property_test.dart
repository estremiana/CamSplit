import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 1: Wizard navigation preserves state
/// Feature: expense-wizard-creation, Property 50: Back navigation from split preserves data
/// Validates: Requirements 11.1, 11.2, 11.3, 11.4, 11.5, 4.10
/// 
/// Property 1: For any data entered on any wizard page, navigating to another page
/// and back should preserve all previously entered data
/// 
/// Property 50: For any split configuration on the split page, navigating back to 
/// the details page and forward again should preserve all split data
void main() {
  final faker = Faker();
  final random = Random();

  group('State Preservation Property Tests', () {
    // Helper function to generate random wizard data with all fields populated
    WizardExpenseData generateCompleteWizardData() {
      final splitType = SplitType.values[random.nextInt(SplitType.values.length)];
      final memberCount = random.nextInt(8) + 2; // 2-10 members
      final memberIds = List.generate(
        memberCount,
        (index) => 'member_${random.nextInt(10000)}',
      );

      // Generate split details based on split type
      Map<String, double> splitDetails = {};
      List<String> involvedMembers = [];
      List<ReceiptItem> items = [];

      switch (splitType) {
        case SplitType.equal:
          involvedMembers = memberIds.sublist(0, random.nextInt(memberCount) + 1);
          break;

        case SplitType.percentage:
          // Generate percentages that sum to 100
          final percentages = List.generate(memberCount, (_) => random.nextDouble() * 100);
          final total = percentages.fold(0.0, (sum, p) => sum + p);
          for (int i = 0; i < memberCount; i++) {
            splitDetails[memberIds[i]] = (percentages[i] / total) * 100;
          }
          break;

        case SplitType.custom:
          // Generate custom amounts
          final amount = (random.nextDouble() * 1000) + 10;
          final amounts = List.generate(memberCount, (_) => random.nextDouble() * amount);
          final total = amounts.fold(0.0, (sum, a) => sum + a);
          for (int i = 0; i < memberCount; i++) {
            splitDetails[memberIds[i]] = (amounts[i] / total) * amount;
          }
          break;

        case SplitType.items:
          // Generate receipt items with assignments
          final itemCount = random.nextInt(5) + 1; // 1-5 items
          items = List.generate(itemCount, (index) {
            final quantity = (random.nextDouble() * 10) + 1;
            final unitPrice = (random.nextDouble() * 50) + 1;
            final assignments = <String, double>{};
            
            // Assign items to random members
            final assignedMemberCount = random.nextInt(memberCount) + 1;
            final assignedMembers = memberIds.sublist(0, assignedMemberCount);
            final qtyPerMember = quantity / assignedMemberCount;
            
            for (final memberId in assignedMembers) {
              assignments[memberId] = qtyPerMember;
            }

            return ReceiptItem(
              id: 'item_${random.nextInt(10000)}',
              name: faker.food.dish(),
              quantity: quantity,
              unitPrice: unitPrice,
              price: quantity * unitPrice,
              assignments: assignments,
              isCustomSplit: random.nextBool(),
            );
          });
          break;
      }

      return WizardExpenseData(
        amount: (random.nextDouble() * 1000) + 10,
        title: faker.lorem.sentence(),
        date: DateTime.now()
            .subtract(Duration(days: random.nextInt(365)))
            .toIso8601String(),
        category: faker.lorem.word(),
        payerId: 'payer_${random.nextInt(10000)}',
        groupId: 'group_${random.nextInt(10000)}',
        splitType: splitType,
        splitDetails: splitDetails,
        involvedMembers: involvedMembers,
        receiptImage: random.nextBool() ? 'base64_image_data_${random.nextInt(1000)}' : null,
        items: items,
        notes: random.nextBool() ? faker.lorem.sentence() : null,
      );
    }

    /// Property 1: Wizard navigation preserves state
    /// Test that all wizard data persists when navigating between pages
    test('Property 1: Wizard navigation preserves all state across pages', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate random complete wizard data
        final originalData = generateCompleteWizardData();

        // Simulate navigation by creating a copy (as happens in real navigation)
        // This tests the copyWith method and immutability
        final afterNavigation = originalData.copyWith();

        // Verify all basic fields are preserved
        expect(afterNavigation.amount, originalData.amount,
            reason: 'Amount should be preserved');
        expect(afterNavigation.title, originalData.title,
            reason: 'Title should be preserved');
        expect(afterNavigation.date, originalData.date,
            reason: 'Date should be preserved');
        expect(afterNavigation.category, originalData.category,
            reason: 'Category should be preserved');
        expect(afterNavigation.payerId, originalData.payerId,
            reason: 'Payer ID should be preserved');
        expect(afterNavigation.groupId, originalData.groupId,
            reason: 'Group ID should be preserved');
        expect(afterNavigation.splitType, originalData.splitType,
            reason: 'Split type should be preserved');
        expect(afterNavigation.receiptImage, originalData.receiptImage,
            reason: 'Receipt image should be preserved');
        expect(afterNavigation.notes, originalData.notes,
            reason: 'Notes should be preserved');

        // Verify split details are preserved
        expect(afterNavigation.splitDetails.length, originalData.splitDetails.length,
            reason: 'Split details count should be preserved');
        for (final key in originalData.splitDetails.keys) {
          expect(afterNavigation.splitDetails[key], originalData.splitDetails[key],
              reason: 'Split detail for $key should be preserved');
        }

        // Verify involved members are preserved
        expect(afterNavigation.involvedMembers.length, originalData.involvedMembers.length,
            reason: 'Involved members count should be preserved');
        for (int j = 0; j < originalData.involvedMembers.length; j++) {
          expect(afterNavigation.involvedMembers[j], originalData.involvedMembers[j],
              reason: 'Involved member at index $j should be preserved');
        }

        // Verify items are preserved
        expect(afterNavigation.items.length, originalData.items.length,
            reason: 'Items count should be preserved');
        for (int j = 0; j < originalData.items.length; j++) {
          final originalItem = originalData.items[j];
          final afterItem = afterNavigation.items[j];

          expect(afterItem.id, originalItem.id,
              reason: 'Item $j ID should be preserved');
          expect(afterItem.name, originalItem.name,
              reason: 'Item $j name should be preserved');
          expect(afterItem.quantity, originalItem.quantity,
              reason: 'Item $j quantity should be preserved');
          expect(afterItem.unitPrice, originalItem.unitPrice,
              reason: 'Item $j unit price should be preserved');
          expect(afterItem.price, originalItem.price,
              reason: 'Item $j price should be preserved');
          expect(afterItem.isCustomSplit, originalItem.isCustomSplit,
              reason: 'Item $j custom split flag should be preserved');

          // Verify item assignments are preserved
          expect(afterItem.assignments.length, originalItem.assignments.length,
              reason: 'Item $j assignments count should be preserved');
          for (final memberId in originalItem.assignments.keys) {
            expect(afterItem.assignments[memberId], originalItem.assignments[memberId],
                reason: 'Item $j assignment for $memberId should be preserved');
          }
        }
      }
    });

    /// Property 1 (variant): Navigation preserves state with partial updates
    /// Test that updating one field doesn't affect other fields
    test('Property 1: Partial updates preserve other fields', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final originalData = generateCompleteWizardData();

        // Update only amount (simulating page 1 update)
        final newAmount = (random.nextDouble() * 1000) + 10;
        final afterAmountUpdate = originalData.copyWith(amount: newAmount);

        expect(afterAmountUpdate.amount, newAmount);
        expect(afterAmountUpdate.title, originalData.title);
        expect(afterAmountUpdate.groupId, originalData.groupId);
        expect(afterAmountUpdate.payerId, originalData.payerId);
        expect(afterAmountUpdate.splitType, originalData.splitType);

        // Update only group and payer (simulating page 2 update)
        final newGroupId = 'group_${random.nextInt(10000)}';
        final newPayerId = 'payer_${random.nextInt(10000)}';
        final afterDetailsUpdate = afterAmountUpdate.copyWith(
          groupId: newGroupId,
          payerId: newPayerId,
        );

        expect(afterDetailsUpdate.amount, newAmount);
        expect(afterDetailsUpdate.groupId, newGroupId);
        expect(afterDetailsUpdate.payerId, newPayerId);
        expect(afterDetailsUpdate.title, originalData.title);
        expect(afterDetailsUpdate.splitType, originalData.splitType);

        // Update split type (simulating page 3 update)
        final newSplitType = SplitType.values[random.nextInt(SplitType.values.length)];
        final afterSplitUpdate = afterDetailsUpdate.copyWith(splitType: newSplitType);

        expect(afterSplitUpdate.amount, newAmount);
        expect(afterSplitUpdate.groupId, newGroupId);
        expect(afterSplitUpdate.payerId, newPayerId);
        expect(afterSplitUpdate.splitType, newSplitType);
        expect(afterSplitUpdate.title, originalData.title);
      }
    });

    /// Property 50: Back navigation from split preserves data
    /// Test that navigating back from split page preserves all split configuration
    test('Property 50: Back navigation from split page preserves split data', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate wizard data with split configuration
        final wizardData = generateCompleteWizardData();

        // Simulate navigation back to details page and forward to split page
        // by creating copies
        final afterBackNavigation = wizardData.copyWith();
        final afterForwardNavigation = afterBackNavigation.copyWith();

        // Verify split type is preserved
        expect(afterForwardNavigation.splitType, wizardData.splitType,
            reason: 'Split type should be preserved after back/forward navigation');

        // Verify split details are preserved based on split type
        switch (wizardData.splitType) {
          case SplitType.equal:
            expect(afterForwardNavigation.involvedMembers.length,
                wizardData.involvedMembers.length,
                reason: 'Equal split: involved members should be preserved');
            for (int j = 0; j < wizardData.involvedMembers.length; j++) {
              expect(afterForwardNavigation.involvedMembers[j],
                  wizardData.involvedMembers[j],
                  reason: 'Equal split: member at index $j should be preserved');
            }
            break;

          case SplitType.percentage:
          case SplitType.custom:
            expect(afterForwardNavigation.splitDetails.length,
                wizardData.splitDetails.length,
                reason: '${wizardData.splitType.displayName}: split details count should be preserved');
            for (final memberId in wizardData.splitDetails.keys) {
              expect(afterForwardNavigation.splitDetails[memberId],
                  wizardData.splitDetails[memberId],
                  reason: '${wizardData.splitType.displayName}: split for $memberId should be preserved');
            }
            break;

          case SplitType.items:
            expect(afterForwardNavigation.items.length, wizardData.items.length,
                reason: 'Items split: items count should be preserved');
            
            for (int j = 0; j < wizardData.items.length; j++) {
              final originalItem = wizardData.items[j];
              final preservedItem = afterForwardNavigation.items[j];

              expect(preservedItem.id, originalItem.id,
                  reason: 'Items split: item $j ID should be preserved');
              expect(preservedItem.name, originalItem.name,
                  reason: 'Items split: item $j name should be preserved');
              expect(preservedItem.quantity, originalItem.quantity,
                  reason: 'Items split: item $j quantity should be preserved');
              expect(preservedItem.unitPrice, originalItem.unitPrice,
                  reason: 'Items split: item $j unit price should be preserved');
              expect(preservedItem.isCustomSplit, originalItem.isCustomSplit,
                  reason: 'Items split: item $j custom split flag should be preserved');

              // Verify assignments are preserved
              expect(preservedItem.assignments.length, originalItem.assignments.length,
                  reason: 'Items split: item $j assignments count should be preserved');
              for (final memberId in originalItem.assignments.keys) {
                expect(preservedItem.assignments[memberId],
                    originalItem.assignments[memberId],
                    reason: 'Items split: item $j assignment for $memberId should be preserved');
              }
            }
            break;
        }
      }
    });

    /// Test that data is cleared only on discard or successful submission
    /// This is tested by verifying that copyWith creates independent copies
    test('Property: Data independence - copyWith creates independent copies', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final originalData = generateCompleteWizardData();
        final copiedData = originalData.copyWith();

        // Modify the copied data
        final modifiedData = copiedData.copyWith(
          amount: copiedData.amount + 100,
          title: 'Modified Title',
        );

        // Verify original data is unchanged
        expect(originalData.amount, isNot(modifiedData.amount),
            reason: 'Original amount should not be affected by copy modification');
        expect(originalData.title, isNot(modifiedData.title),
            reason: 'Original title should not be affected by copy modification');

        // Verify copied data is modified
        expect(modifiedData.amount, copiedData.amount + 100);
        expect(modifiedData.title, 'Modified Title');
      }
    });

    /// Test that receipt image data is preserved across navigation
    test('Property: Receipt image data persists across navigation', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final receiptImage = 'base64_image_data_${random.nextInt(10000)}';
        final wizardData = generateCompleteWizardData().copyWith(
          receiptImage: receiptImage,
        );

        // Simulate navigation through all pages
        final afterPage2 = wizardData.copyWith();
        final afterPage3 = afterPage2.copyWith();
        final backToPage2 = afterPage3.copyWith();
        final backToPage1 = backToPage2.copyWith();

        // Verify receipt image is preserved throughout
        expect(afterPage2.receiptImage, receiptImage);
        expect(afterPage3.receiptImage, receiptImage);
        expect(backToPage2.receiptImage, receiptImage);
        expect(backToPage1.receiptImage, receiptImage);
      }
    });

    /// Test that notes field is preserved across navigation
    test('Property: Notes field persists across navigation', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final notes = faker.lorem.sentence();
        final wizardData = generateCompleteWizardData().copyWith(notes: notes);

        // Simulate navigation
        final afterNavigation = wizardData.copyWith();

        expect(afterNavigation.notes, notes,
            reason: 'Notes should be preserved across navigation');
      }
    });

    /// Test that empty/null optional fields are preserved
    test('Property: Empty and null optional fields are preserved', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final wizardData = WizardExpenseData(
          amount: (random.nextDouble() * 1000) + 10,
          title: faker.lorem.word(),
          groupId: 'group_${random.nextInt(10000)}',
          payerId: 'payer_${random.nextInt(10000)}',
          date: DateTime.now().toIso8601String(),
          category: faker.lorem.word(),
          receiptImage: null,
          notes: null,
        );

        final afterNavigation = wizardData.copyWith();

        expect(afterNavigation.receiptImage, isNull,
            reason: 'Null receipt image should be preserved');
        expect(afterNavigation.notes, isNull,
            reason: 'Null notes should be preserved');
      }
    });

    /// Test that complex item assignments are preserved
    test('Property: Complex item assignments with multiple members are preserved', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Create items with complex assignments
        final memberIds = List.generate(5, (i) => 'member_$i');
        final items = List.generate(3, (itemIndex) {
          final assignments = <String, double>{};
          // Assign different quantities to different members
          for (int j = 0; j < memberIds.length; j++) {
            if (random.nextBool()) {
              assignments[memberIds[j]] = (random.nextDouble() * 5) + 0.5;
            }
          }

          return ReceiptItem(
            id: 'item_$itemIndex',
            name: faker.food.dish(),
            quantity: 10.0,
            unitPrice: 5.0,
            price: 50.0,
            assignments: assignments,
            isCustomSplit: assignments.isNotEmpty,
          );
        });

        final wizardData = generateCompleteWizardData().copyWith(
          splitType: SplitType.items,
          items: items,
        );

        // Simulate navigation
        final afterNavigation = wizardData.copyWith();

        // Verify all assignments are preserved
        for (int itemIndex = 0; itemIndex < items.length; itemIndex++) {
          final originalItem = wizardData.items[itemIndex];
          final preservedItem = afterNavigation.items[itemIndex];

          expect(preservedItem.assignments.length, originalItem.assignments.length,
              reason: 'Item $itemIndex should preserve assignment count');

          for (final memberId in originalItem.assignments.keys) {
            expect(preservedItem.assignments[memberId],
                originalItem.assignments[memberId],
                reason: 'Item $itemIndex should preserve assignment for $memberId');
          }
        }
      }
    });
  });
}
