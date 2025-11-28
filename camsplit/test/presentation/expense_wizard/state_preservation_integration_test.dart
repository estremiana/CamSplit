import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';

/// Unit tests to verify state preservation through the data model
/// These tests verify that the copyWith method correctly preserves state
/// which is the mechanism used for state preservation during navigation
void main() {
  group('State Preservation Unit Tests', () {
    test('WizardExpenseData copyWith preserves all fields', () {
      final originalData = WizardExpenseData(
        amount: 100.0,
        title: 'Original Title',
        date: '2024-01-01',
        category: 'Food',
        payerId: 'payer123',
        groupId: 'group456',
        splitType: SplitType.equal,
        involvedMembers: ['member1', 'member2'],
        notes: 'Test notes',
      );

      // Create a copy
      final copiedData = originalData.copyWith();

      // Verify all fields are preserved
      expect(copiedData.amount, originalData.amount);
      expect(copiedData.title, originalData.title);
      expect(copiedData.date, originalData.date);
      expect(copiedData.category, originalData.category);
      expect(copiedData.payerId, originalData.payerId);
      expect(copiedData.groupId, originalData.groupId);
      expect(copiedData.splitType, originalData.splitType);
      expect(copiedData.involvedMembers, originalData.involvedMembers);
      expect(copiedData.notes, originalData.notes);

      // Create a copy with one field changed
      final modifiedData = originalData.copyWith(amount: 200.0);

      // Verify only the specified field changed
      expect(modifiedData.amount, 200.0);
      expect(modifiedData.title, originalData.title);
      expect(modifiedData.date, originalData.date);
      expect(modifiedData.category, originalData.category);

      // Verify original is unchanged
      expect(originalData.amount, 100.0);
    });

    test('WizardExpenseData copyWith preserves complex split details', () {
      final originalData = WizardExpenseData(
        amount: 100.0,
        title: 'Test',
        groupId: 'group1',
        payerId: 'payer1',
        date: '2024-01-01',
        category: 'Food',
        splitType: SplitType.percentage,
        splitDetails: {
          'member1': 50.0,
          'member2': 30.0,
          'member3': 20.0,
        },
      );

      final copiedData = originalData.copyWith();

      // Verify split details are preserved
      expect(copiedData.splitDetails.length, originalData.splitDetails.length);
      expect(copiedData.splitDetails['member1'], 50.0);
      expect(copiedData.splitDetails['member2'], 30.0);
      expect(copiedData.splitDetails['member3'], 20.0);
    });

    test('WizardExpenseData copyWith preserves receipt items with assignments', () {
      final items = [
        ReceiptItem(
          id: 'item1',
          name: 'Pizza',
          quantity: 2.0,
          unitPrice: 15.0,
          price: 30.0,
          assignments: {
            'member1': 1.0,
            'member2': 1.0,
          },
          isCustomSplit: true,
        ),
        ReceiptItem(
          id: 'item2',
          name: 'Soda',
          quantity: 3.0,
          unitPrice: 2.0,
          price: 6.0,
          assignments: {
            'member1': 1.5,
            'member2': 1.5,
          },
          isCustomSplit: false,
        ),
      ];

      final originalData = WizardExpenseData(
        amount: 36.0,
        title: 'Lunch',
        groupId: 'group1',
        payerId: 'payer1',
        date: '2024-01-01',
        category: 'Food',
        splitType: SplitType.items,
        items: items,
      );

      final copiedData = originalData.copyWith();

      // Verify items are preserved
      expect(copiedData.items.length, 2);
      expect(copiedData.items[0].id, 'item1');
      expect(copiedData.items[0].name, 'Pizza');
      expect(copiedData.items[0].quantity, 2.0);
      expect(copiedData.items[0].assignments['member1'], 1.0);
      expect(copiedData.items[0].assignments['member2'], 1.0);
      expect(copiedData.items[0].isCustomSplit, true);

      expect(copiedData.items[1].id, 'item2');
      expect(copiedData.items[1].name, 'Soda');
      expect(copiedData.items[1].quantity, 3.0);
      expect(copiedData.items[1].assignments['member1'], 1.5);
      expect(copiedData.items[1].assignments['member2'], 1.5);
      expect(copiedData.items[1].isCustomSplit, false);
    });

    test('WizardExpenseData copyWith creates independent copies', () {
      final originalData = WizardExpenseData(
        amount: 100.0,
        title: 'Original',
        groupId: 'group1',
        payerId: 'payer1',
        date: '2024-01-01',
        category: 'Food',
        splitDetails: {'member1': 50.0, 'member2': 50.0},
      );

      final copiedData = originalData.copyWith();

      // Modify the copied data
      final modifiedData = copiedData.copyWith(
        amount: 200.0,
        title: 'Modified',
        splitDetails: {'member1': 100.0, 'member2': 100.0},
      );

      // Verify original is unchanged
      expect(originalData.amount, 100.0);
      expect(originalData.title, 'Original');
      expect(originalData.splitDetails['member1'], 50.0);
      expect(originalData.splitDetails['member2'], 50.0);

      // Verify copied data is modified
      expect(modifiedData.amount, 200.0);
      expect(modifiedData.title, 'Modified');
      expect(modifiedData.splitDetails['member1'], 100.0);
      expect(modifiedData.splitDetails['member2'], 100.0);
    });

    test('WizardExpenseData copyWith preserves null and empty values', () {
      final originalData = WizardExpenseData(
        amount: 100.0,
        title: 'Test',
        groupId: 'group1',
        payerId: 'payer1',
        date: '2024-01-01',
        category: 'Food',
        receiptImage: null,
        notes: null,
      );

      final copiedData = originalData.copyWith();

      expect(copiedData.receiptImage, isNull);
      expect(copiedData.notes, isNull);
      expect(copiedData.items, isEmpty);
      expect(copiedData.splitDetails, isEmpty);
      expect(copiedData.involvedMembers, isEmpty);
    });

    test('ReceiptItem copyWith preserves all fields', () {
      final originalItem = ReceiptItem(
        id: 'item1',
        name: 'Pizza',
        quantity: 2.0,
        unitPrice: 15.0,
        price: 30.0,
        assignments: {
          'member1': 1.0,
          'member2': 1.0,
        },
        isCustomSplit: true,
      );

      final copiedItem = originalItem.copyWith();

      expect(copiedItem.id, originalItem.id);
      expect(copiedItem.name, originalItem.name);
      expect(copiedItem.quantity, originalItem.quantity);
      expect(copiedItem.unitPrice, originalItem.unitPrice);
      expect(copiedItem.price, originalItem.price);
      expect(copiedItem.isCustomSplit, originalItem.isCustomSplit);
      expect(copiedItem.assignments.length, originalItem.assignments.length);
      expect(copiedItem.assignments['member1'], 1.0);
      expect(copiedItem.assignments['member2'], 1.0);
    });

    test('ReceiptItem copyWith creates independent copies', () {
      final originalItem = ReceiptItem(
        id: 'item1',
        name: 'Pizza',
        quantity: 2.0,
        unitPrice: 15.0,
        price: 30.0,
        assignments: {'member1': 1.0},
      );

      final copiedItem = originalItem.copyWith();
      final modifiedItem = copiedItem.copyWith(
        name: 'Modified Pizza',
        assignments: {'member1': 2.0},
      );

      // Verify original is unchanged
      expect(originalItem.name, 'Pizza');
      expect(originalItem.assignments['member1'], 1.0);

      // Verify modified item has changes
      expect(modifiedItem.name, 'Modified Pizza');
      expect(modifiedItem.assignments['member1'], 2.0);
    });
  });
}
