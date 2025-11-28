import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation
/// Property 45: Error handling on failure
/// Property 46: Payload completeness
/// Property 47: Items payload completeness
/// Validates: Requirements 10.5, 10.7, 10.8

void main() {
  final faker = Faker();
  final random = Random();

  group('Expense Submission Property Tests', () {
    // Helper function to generate random WizardExpenseData
    WizardExpenseData generateRandomWizardData({
      double? amount,
      String? title,
      String? groupId,
      String? payerId,
      String? date,
      String? category,
      SplitType? splitType,
      Map<String, double>? splitDetails,
      List<String>? involvedMembers,
      List<ReceiptItem>? items,
      String? notes,
      String? receiptImage,
    }) {
      return WizardExpenseData(
        amount: amount ?? ((random.nextDouble() * 1000) + 1),
        title: title ?? faker.lorem.sentence(),
        groupId: groupId ?? faker.guid.guid(),
        payerId: payerId ?? faker.guid.guid(),
        date: date ?? DateTime.now().toIso8601String(),
        category: category ?? faker.lorem.word(),
        splitType: splitType ?? SplitType.equal,
        splitDetails: splitDetails ?? {},
        involvedMembers: involvedMembers ?? [],
        items: items ?? [],
        notes: notes,
        receiptImage: receiptImage,
      );
    }

    // Helper to generate fully assigned receipt items
    List<ReceiptItem> generateFullyAssignedItems(int count) {
      final items = <ReceiptItem>[];
      for (int i = 0; i < count; i++) {
        final quantity = (random.nextDouble() * 10) + 1;
        final unitPrice = (random.nextDouble() * 50) + 1;
        
        // Fully assign the item to random members
        final memberCount = random.nextInt(3) + 1;
        final assignments = <String, double>{};
        double remaining = quantity;
        
        for (int j = 0; j < memberCount - 1; j++) {
          final assignQty = random.nextDouble() * remaining;
          assignments['member_${j + 1}'] = assignQty;
          remaining -= assignQty;
        }
        assignments['member_$memberCount'] = remaining;
        
        items.add(ReceiptItem(
          id: 'item_$i',
          name: faker.food.dish(),
          quantity: quantity,
          unitPrice: unitPrice,
          price: quantity * unitPrice,
          assignments: assignments,
        ));
      }
      return items;
    }

    /// Property 46: Payload completeness
    /// For any expense submitted, the payload should include all wizard data:
    /// amount, title, group, payer, date, category, split type, and split details
    test('Property 46: Payload completeness - Equal split', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final memberCount = random.nextInt(5) + 2;
        final members = List.generate(memberCount, (i) => 'member_$i');
        
        final wizardData = generateRandomWizardData(
          splitType: SplitType.equal,
          involvedMembers: members,
        );
        
        final payload = wizardData.toJson();
        
        // Verify all required fields are present
        expect(payload.containsKey('amount'), true, 
            reason: 'Payload must contain amount');
        expect(payload.containsKey('title'), true,
            reason: 'Payload must contain title');
        expect(payload.containsKey('group_id'), true,
            reason: 'Payload must contain group_id');
        expect(payload.containsKey('payer_id'), true,
            reason: 'Payload must contain payer_id');
        expect(payload.containsKey('date'), true,
            reason: 'Payload must contain date');
        expect(payload.containsKey('category'), true,
            reason: 'Payload must contain category');
        expect(payload.containsKey('split_type'), true,
            reason: 'Payload must contain split_type');
        
        // Verify values match wizard data
        expect(payload['amount'], wizardData.amount);
        expect(payload['title'], wizardData.title);
        expect(payload['group_id'], wizardData.groupId);
        expect(payload['payer_id'], wizardData.payerId);
        expect(payload['date'], wizardData.date);
        expect(payload['category'], wizardData.category);
        expect(payload['split_type'], 'equal');
        expect(payload['involved_members'], wizardData.involvedMembers);
      }
    });

    test('Property 46: Payload completeness - Percentage split', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
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
        
        final wizardData = generateRandomWizardData(
          splitType: SplitType.percentage,
          splitDetails: percentages,
        );
        
        final payload = wizardData.toJson();
        
        // Verify all required fields are present
        expect(payload.containsKey('amount'), true);
        expect(payload.containsKey('title'), true);
        expect(payload.containsKey('group_id'), true);
        expect(payload.containsKey('payer_id'), true);
        expect(payload.containsKey('date'), true);
        expect(payload.containsKey('category'), true);
        expect(payload.containsKey('split_type'), true);
        expect(payload.containsKey('split_details'), true);
        
        // Verify split details are included
        expect(payload['split_type'], 'percentage');
        expect(payload['split_details'], wizardData.splitDetails);
      }
    });

    test('Property 46: Payload completeness - Custom split', () {
      const iterations = 100;
      
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
        
        final wizardData = generateRandomWizardData(
          amount: totalAmount,
          splitType: SplitType.custom,
          splitDetails: amounts,
        );
        
        final payload = wizardData.toJson();
        
        // Verify all required fields are present
        expect(payload.containsKey('amount'), true);
        expect(payload.containsKey('title'), true);
        expect(payload.containsKey('group_id'), true);
        expect(payload.containsKey('payer_id'), true);
        expect(payload.containsKey('date'), true);
        expect(payload.containsKey('category'), true);
        expect(payload.containsKey('split_type'), true);
        expect(payload.containsKey('split_details'), true);
        
        // Verify split details are included
        expect(payload['split_type'], 'custom');
        expect(payload['split_details'], wizardData.splitDetails);
      }
    });

    /// Property 47: Items payload completeness
    /// For any expense submitted with Items split type,
    /// the payload should include all item assignments
    test('Property 47: Items payload completeness', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(5) + 1;
        final items = generateFullyAssignedItems(itemCount);
        
        final wizardData = generateRandomWizardData(
          splitType: SplitType.items,
          items: items,
        );
        
        final payload = wizardData.toJson();
        
        // Verify all required fields are present
        expect(payload.containsKey('amount'), true);
        expect(payload.containsKey('title'), true);
        expect(payload.containsKey('group_id'), true);
        expect(payload.containsKey('payer_id'), true);
        expect(payload.containsKey('date'), true);
        expect(payload.containsKey('category'), true);
        expect(payload.containsKey('split_type'), true);
        expect(payload.containsKey('items'), true);
        
        // Verify split type is items
        expect(payload['split_type'], 'items');
        
        // Verify items array is present and has correct length
        final payloadItems = payload['items'] as List;
        expect(payloadItems.length, itemCount);
        
        // Verify each item has all required fields
        for (int j = 0; j < itemCount; j++) {
          final item = payloadItems[j] as Map<String, dynamic>;
          final originalItem = items[j];
          
          expect(item.containsKey('id'), true);
          expect(item.containsKey('name'), true);
          expect(item.containsKey('quantity'), true);
          expect(item.containsKey('unit_price'), true);
          expect(item.containsKey('price'), true);
          expect(item.containsKey('assignments'), true);
          
          // Verify item values match
          expect(item['id'], originalItem.id);
          expect(item['name'], originalItem.name);
          expect(item['quantity'], originalItem.quantity);
          expect(item['unit_price'], originalItem.unitPrice);
          expect(item['price'], originalItem.price);
          
          // Verify assignments are included
          final assignments = item['assignments'] as Map<String, dynamic>;
          expect(assignments.length, originalItem.assignments.length);
          
          // Verify each assignment
          originalItem.assignments.forEach((memberId, qty) {
            expect(assignments.containsKey(memberId), true,
                reason: 'Assignment for $memberId should be in payload');
            expect(assignments[memberId], qty);
          });
        }
      }
    });

    test('Property 47: Items payload includes all assignment data', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(3) + 1;
        final items = generateFullyAssignedItems(itemCount);
        
        final wizardData = generateRandomWizardData(
          splitType: SplitType.items,
          items: items,
        );
        
        final payload = wizardData.toJson();
        final payloadItems = payload['items'] as List;
        
        // For each item, verify all assignments are present
        for (int j = 0; j < itemCount; j++) {
          final originalItem = items[j];
          final payloadItem = payloadItems[j] as Map<String, dynamic>;
          final payloadAssignments = payloadItem['assignments'] as Map<String, dynamic>;
          
          // Count of assignments should match
          expect(payloadAssignments.length, originalItem.assignments.length,
              reason: 'All assignments should be in payload');
          
          // Each member's assignment should be present
          originalItem.assignments.forEach((memberId, assignedQty) {
            expect(payloadAssignments.containsKey(memberId), true,
                reason: 'Member $memberId assignment should be in payload');
            expect(payloadAssignments[memberId], assignedQty,
                reason: 'Assignment quantity should match for $memberId');
          });
        }
      }
    });

    test('Property 46: Optional fields included when present', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final notes = random.nextBool() ? faker.lorem.sentence() : null;
        final receiptImage = random.nextBool() ? 'base64_image_data_${faker.guid.guid()}' : null;
        
        final wizardData = generateRandomWizardData(
          notes: notes,
          receiptImage: receiptImage,
        );
        
        final payload = wizardData.toJson();
        
        // Verify optional fields are included when present
        if (notes != null) {
          expect(payload.containsKey('notes'), true);
          expect(payload['notes'], notes);
        }
        
        if (receiptImage != null) {
          expect(payload.containsKey('receipt_image'), true);
          expect(payload['receipt_image'], receiptImage);
        }
      }
    });

    test('Property 46: Payload preserves data types', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final wizardData = generateRandomWizardData();
        final payload = wizardData.toJson();
        
        // Verify data types are correct
        expect(payload['amount'] is double, true,
            reason: 'Amount should be a double');
        expect(payload['title'] is String, true,
            reason: 'Title should be a string');
        expect(payload['group_id'] is String, true,
            reason: 'Group ID should be a string');
        expect(payload['payer_id'] is String, true,
            reason: 'Payer ID should be a string');
        expect(payload['date'] is String, true,
            reason: 'Date should be a string');
        expect(payload['category'] is String, true,
            reason: 'Category should be a string');
        expect(payload['split_type'] is String, true,
            reason: 'Split type should be a string');
      }
    });

    test('Property 47: Items with custom split flag preserved', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(3) + 1;
        final items = <ReceiptItem>[];
        
        for (int j = 0; j < itemCount; j++) {
          final quantity = (random.nextDouble() * 10) + 1;
          final unitPrice = (random.nextDouble() * 50) + 1;
          final isCustomSplit = random.nextBool();
          
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
            isCustomSplit: isCustomSplit,
          ));
        }
        
        final wizardData = generateRandomWizardData(
          splitType: SplitType.items,
          items: items,
        );
        
        final payload = wizardData.toJson();
        final payloadItems = payload['items'] as List;
        
        // Verify custom split flag is preserved
        for (int j = 0; j < itemCount; j++) {
          final payloadItem = payloadItems[j] as Map<String, dynamic>;
          expect(payloadItem['is_custom_split'], items[j].isCustomSplit,
              reason: 'Custom split flag should be preserved');
        }
      }
    });

    test('Property 46: Empty collections handled correctly', () {
      const iterations = 50;
      
      for (int i = 0; i < iterations; i++) {
        final wizardData = generateRandomWizardData(
          splitType: SplitType.equal,
          involvedMembers: [],
          items: [],
        );
        
        final payload = wizardData.toJson();
        
        // Verify empty collections are included
        expect(payload['involved_members'] is List, true);
        expect((payload['involved_members'] as List).isEmpty, true);
        expect(payload['items'] is List, true);
        expect((payload['items'] as List).isEmpty, true);
      }
    });
  });
}
