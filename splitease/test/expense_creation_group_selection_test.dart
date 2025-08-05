import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/models/receipt_mode_data.dart';
import 'package:splitease/models/participant_amount.dart';

void main() {
  group('ExpenseCreation Group Selection Tests', () {
    test('should preserve selected group information in receipt data', () {
      // Create test receipt data with a specific group
      final receiptData = ReceiptModeData(
        total: 100.0,
        participantAmounts: [
          ParticipantAmount(name: 'John', amount: 50.0),
          ParticipantAmount(name: 'Jane', amount: 50.0),
        ],
        mode: 'receipt',
        isEqualSplit: true,
        items: [
          {
            'id': 1,
            'name': 'Test Item',
            'totalPrice': 100.0,
            'quantity': 1,
          }
        ],
        groupMembers: [
          {'id': 1, 'name': 'John', 'isCurrentUser': true},
          {'id': 2, 'name': 'Jane', 'isCurrentUser': false},
        ],
        selectedGroupId: '2',
        selectedGroupName: 'Group B',
      );

      // Verify that the selected group information is preserved
      expect(receiptData.selectedGroupId, equals('2'));
      expect(receiptData.selectedGroupName, equals('Group B'));
      expect(receiptData.groupMembers.length, equals(2));
      expect(receiptData.total, equals(100.0));
      
      // Verify validation passes
      final validationError = receiptData.validate();
      expect(validationError, isNull);
    });

    test('ReceiptModeData should preserve selected group information', () {
      final receiptData = ReceiptModeData(
        total: 100.0,
        participantAmounts: [],
        mode: 'receipt',
        isEqualSplit: true,
        items: [],
        groupMembers: [],
        selectedGroupId: '2',
        selectedGroupName: 'Group B',
      );

      expect(receiptData.selectedGroupId, equals('2'));
      expect(receiptData.selectedGroupName, equals('Group B'));
    });

    test('ReceiptModeData JSON serialization should preserve group information', () {
      final receiptData = ReceiptModeData(
        total: 100.0,
        participantAmounts: [],
        mode: 'receipt',
        isEqualSplit: true,
        items: [],
        groupMembers: [],
        selectedGroupId: '2',
        selectedGroupName: 'Group B',
      );

      final json = receiptData.toJson();
      final deserialized = ReceiptModeData.fromJson(json);

      expect(deserialized.selectedGroupId, equals('2'));
      expect(deserialized.selectedGroupName, equals('Group B'));
    });
  });
} 