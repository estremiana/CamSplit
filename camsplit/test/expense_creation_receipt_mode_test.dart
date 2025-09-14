import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/models/receipt_mode_data.dart';
import 'package:camsplit/models/participant_amount.dart';
import 'package:camsplit/models/receipt_mode_config.dart';

void main() {
  group('Receipt Mode Data Models Tests', () {
    late ReceiptModeData testReceiptData;

    setUp(() {
      testReceiptData = ReceiptModeData(
        total: 50.0,
        participantAmounts: [
          ParticipantAmount(name: 'Alice', amount: 25.0),
          ParticipantAmount(name: 'Bob', amount: 25.0),
        ],
        mode: 'receipt',
        isEqualSplit: false,
        items: [
          {
            'id': 1,
            'name': 'Pizza',
            'totalPrice': 30.0,
            'quantity': 1,
          },
          {
            'id': 2,
            'name': 'Drinks',
            'totalPrice': 20.0,
            'quantity': 2,
          },
        ],
        groupMembers: [
          {
            'id': 1,
            'name': 'Alice',
            'avatar': 'https://example.com/alice.jpg',
          },
          {
            'id': 2,
            'name': 'Bob',
            'avatar': 'https://example.com/bob.jpg',
          },
        ],
      );
    });

    test('ReceiptModeData validation should work correctly', () {
      // Test valid data
      expect(testReceiptData.validate(), isNull);
      expect(testReceiptData.isValid, isTrue);

      // Test invalid data - negative total
      final invalidData1 = testReceiptData.copyWith(total: -10.0);
      expect(invalidData1.validate(), isNotNull);
      expect(invalidData1.validate(), contains('Total amount must be greater than zero'));
      expect(invalidData1.isValid, isFalse);

      // Test invalid data - empty participant amounts
      final invalidData2 = testReceiptData.copyWith(participantAmounts: []);
      expect(invalidData2.validate(), isNotNull);
      expect(invalidData2.validate(), contains('Participant amounts cannot be empty'));
      expect(invalidData2.isValid, isFalse);

      // Test invalid data - mismatched totals
      final invalidData3 = testReceiptData.copyWith(
        participantAmounts: [
          ParticipantAmount(name: 'Alice', amount: 10.0),
          ParticipantAmount(name: 'Bob', amount: 10.0),
        ],
      );
      expect(invalidData3.validate(), isNotNull);
      expect(invalidData3.validate(), contains('Sum of participant amounts'));
      expect(invalidData3.isValid, isFalse);

      // Test invalid data - empty group members
      final invalidData4 = testReceiptData.copyWith(groupMembers: []);
      expect(invalidData4.validate(), isNotNull);
      expect(invalidData4.validate(), contains('Group members cannot be empty'));
      expect(invalidData4.isValid, isFalse);

      // Test invalid data - empty items
      final invalidData5 = testReceiptData.copyWith(items: []);
      expect(invalidData5.validate(), isNotNull);
      expect(invalidData5.validate(), contains('Items list cannot be empty'));
      expect(invalidData5.isValid, isFalse);
    });

    test('ReceiptModeData serialization should work correctly', () {
      // Test toJson and fromJson
      final json = testReceiptData.toJson();
      final recreatedData = ReceiptModeData.fromJson(json);
      
      expect(recreatedData.total, equals(testReceiptData.total));
      expect(recreatedData.mode, equals(testReceiptData.mode));
      expect(recreatedData.isEqualSplit, equals(testReceiptData.isEqualSplit));
      expect(recreatedData.participantAmounts.length, equals(testReceiptData.participantAmounts.length));
      expect(recreatedData.items.length, equals(testReceiptData.items.length));
      expect(recreatedData.groupMembers.length, equals(testReceiptData.groupMembers.length));
    });

    test('ParticipantAmount should work correctly', () {
      final participant = ParticipantAmount(name: 'Alice', amount: 25.0);
      
      // Test properties
      expect(participant.name, equals('Alice'));
      expect(participant.amount, equals(25.0));
      
      // Test serialization
      final json = participant.toJson();
      final recreated = ParticipantAmount.fromJson(json);
      expect(recreated.name, equals(participant.name));
      expect(recreated.amount, equals(participant.amount));
      
      // Test copyWith
      final updated = participant.copyWith(amount: 30.0);
      expect(updated.name, equals('Alice'));
      expect(updated.amount, equals(30.0));
    });

    test('ReceiptModeConfig should provide correct configurations', () {
      // Test receipt mode config
      const receiptConfig = ReceiptModeConfig.receiptMode;
      expect(receiptConfig.isGroupEditable, isFalse);
      expect(receiptConfig.isTotalEditable, isFalse);
      expect(receiptConfig.isSplitTypeEditable, isFalse);
      expect(receiptConfig.areCustomAmountsEditable, isFalse);
      expect(receiptConfig.defaultSplitType, equals('custom'));
      
      // Test manual mode config
      const manualConfig = ReceiptModeConfig.manualMode;
      expect(manualConfig.isGroupEditable, isTrue);
      expect(manualConfig.isTotalEditable, isTrue);
      expect(manualConfig.isSplitTypeEditable, isTrue);
      expect(manualConfig.areCustomAmountsEditable, isTrue);
      expect(manualConfig.defaultSplitType, equals('equal'));
    });

    test('ReceiptModeData copyWith should work correctly', () {
      final updated = testReceiptData.copyWith(
        total: 100.0,
        mode: 'manual',
      );
      
      expect(updated.total, equals(100.0));
      expect(updated.mode, equals('manual'));
      expect(updated.isEqualSplit, equals(testReceiptData.isEqualSplit));
      expect(updated.participantAmounts, equals(testReceiptData.participantAmounts));
    });

    test('ReceiptModeData equality should work correctly', () {
      // Test that copyWith with no changes creates equal object
      final identical1 = testReceiptData.copyWith();
      
      final different = testReceiptData.copyWith(total: 100.0);
      
      expect(testReceiptData == identical1, isTrue);
      expect(testReceiptData == different, isFalse);
      expect(testReceiptData.hashCode == identical1.hashCode, isTrue);
      expect(testReceiptData.hashCode == different.hashCode, isFalse);
    });
  });
}