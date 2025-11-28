import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';

/// Integration test for expense submission functionality
/// Verifies that the submission flow works correctly
void main() {
  group('Expense Submission Integration Tests', () {
    test('Payload creation for equal split', () {
      final wizardData = WizardExpenseData(
        amount: 100.0,
        title: 'Test Expense',
        groupId: 'group_123',
        payerId: 'payer_456',
        date: '2024-01-01',
        category: 'Food',
        splitType: SplitType.equal,
        involvedMembers: ['member_1', 'member_2', 'member_3'],
      );

      final payload = wizardData.toJson();

      expect(payload['amount'], 100.0);
      expect(payload['title'], 'Test Expense');
      expect(payload['group_id'], 'group_123');
      expect(payload['payer_id'], 'payer_456');
      expect(payload['date'], '2024-01-01');
      expect(payload['category'], 'Food');
      expect(payload['split_type'], 'equal');
      expect(payload['involved_members'], ['member_1', 'member_2', 'member_3']);
    });

    test('Payload creation for percentage split', () {
      final wizardData = WizardExpenseData(
        amount: 100.0,
        title: 'Test Expense',
        groupId: 'group_123',
        payerId: 'payer_456',
        date: '2024-01-01',
        category: 'Food',
        splitType: SplitType.percentage,
        splitDetails: {
          'member_1': 50.0,
          'member_2': 30.0,
          'member_3': 20.0,
        },
      );

      final payload = wizardData.toJson();

      expect(payload['split_type'], 'percentage');
      expect(payload['split_details'], {
        'member_1': 50.0,
        'member_2': 30.0,
        'member_3': 20.0,
      });
    });

    test('Payload creation for custom split', () {
      final wizardData = WizardExpenseData(
        amount: 100.0,
        title: 'Test Expense',
        groupId: 'group_123',
        payerId: 'payer_456',
        date: '2024-01-01',
        category: 'Food',
        splitType: SplitType.custom,
        splitDetails: {
          'member_1': 50.0,
          'member_2': 30.0,
          'member_3': 20.0,
        },
      );

      final payload = wizardData.toJson();

      expect(payload['split_type'], 'custom');
      expect(payload['split_details'], {
        'member_1': 50.0,
        'member_2': 30.0,
        'member_3': 20.0,
      });
    });

    test('Validation prevents submission with invalid data', () {
      // Invalid amount
      final invalidAmount = WizardExpenseData(
        amount: 0.0,
        title: 'Test',
        groupId: 'group_123',
        payerId: 'payer_456',
        date: '2024-01-01',
      );
      expect(invalidAmount.isAmountValid(), false);

      // Invalid details (missing group)
      final invalidDetails = WizardExpenseData(
        amount: 100.0,
        title: 'Test',
        groupId: '',
        payerId: 'payer_456',
        date: '2024-01-01',
      );
      expect(invalidDetails.isDetailsValid(), false);

      // Invalid split (no members for equal split)
      final invalidSplit = WizardExpenseData(
        amount: 100.0,
        title: 'Test',
        groupId: 'group_123',
        payerId: 'payer_456',
        date: '2024-01-01',
        splitType: SplitType.equal,
        involvedMembers: [],
      );
      expect(invalidSplit.isSplitValid(), false);
    });

    test('Optional fields included in payload when present', () {
      final wizardData = WizardExpenseData(
        amount: 100.0,
        title: 'Test Expense',
        groupId: 'group_123',
        payerId: 'payer_456',
        date: '2024-01-01',
        category: 'Food',
        splitType: SplitType.equal,
        involvedMembers: ['member_1'],
        notes: 'Test notes',
        receiptImage: 'base64_image_data',
      );

      final payload = wizardData.toJson();

      expect(payload['notes'], 'Test notes');
      expect(payload['receipt_image'], 'base64_image_data');
    });

    test('Payload creation for items split with assignments', () {
      final items = [
        ReceiptItem(
          id: 'item_1',
          name: 'Pizza',
          quantity: 2.0,
          unitPrice: 15.0,
          price: 30.0,
          assignments: {
            'member_1': 1.0,
            'member_2': 1.0,
          },
        ),
        ReceiptItem(
          id: 'item_2',
          name: 'Soda',
          quantity: 3.0,
          unitPrice: 2.0,
          price: 6.0,
          assignments: {
            'member_1': 1.0,
            'member_2': 2.0,
          },
        ),
      ];

      final wizardData = WizardExpenseData(
        amount: 36.0,
        title: 'Lunch',
        groupId: 'group_123',
        payerId: 'payer_456',
        date: '2024-01-01',
        category: 'Food',
        splitType: SplitType.items,
        items: items,
      );

      final payload = wizardData.toJson();

      expect(payload['split_type'], 'items');
      expect(payload['items'], isA<List>());
      expect((payload['items'] as List).length, 2);

      final payloadItems = payload['items'] as List;
      final item1 = payloadItems[0] as Map<String, dynamic>;
      final item2 = payloadItems[1] as Map<String, dynamic>;

      // Verify first item
      expect(item1['name'], 'Pizza');
      expect(item1['quantity'], 2.0);
      expect(item1['unit_price'], 15.0);
      expect(item1['price'], 30.0);
      expect(item1['assignments'], {
        'member_1': 1.0,
        'member_2': 1.0,
      });

      // Verify second item
      expect(item2['name'], 'Soda');
      expect(item2['quantity'], 3.0);
      expect(item2['unit_price'], 2.0);
      expect(item2['price'], 6.0);
      expect(item2['assignments'], {
        'member_1': 1.0,
        'member_2': 2.0,
      });
    });

    test('Round trip: toJson and fromJson preserves all data', () {
      final original = WizardExpenseData(
        amount: 150.50,
        title: 'Dinner',
        groupId: 'group_abc',
        payerId: 'payer_xyz',
        date: '2024-01-15',
        category: 'Restaurant',
        splitType: SplitType.percentage,
        splitDetails: {
          'member_1': 40.0,
          'member_2': 35.0,
          'member_3': 25.0,
        },
        notes: 'Birthday dinner',
        receiptImage: 'base64_data',
      );

      final json = original.toJson();
      final restored = WizardExpenseData.fromJson(json);

      expect(restored.amount, original.amount);
      expect(restored.title, original.title);
      expect(restored.groupId, original.groupId);
      expect(restored.payerId, original.payerId);
      expect(restored.date, original.date);
      expect(restored.category, original.category);
      expect(restored.splitType, original.splitType);
      expect(restored.splitDetails, original.splitDetails);
      expect(restored.notes, original.notes);
      expect(restored.receiptImage, original.receiptImage);
    });
  });
}
