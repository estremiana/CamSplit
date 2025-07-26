import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/models/receipt_mode_data.dart';
import 'package:splitease/models/participant_amount.dart';
import 'package:splitease/models/receipt_mode_config.dart';

void main() {
  group('ParticipantAmount', () {
    test('should create ParticipantAmount with valid data', () {
      final participant = ParticipantAmount(name: 'John', amount: 25.50);
      
      expect(participant.name, 'John');
      expect(participant.amount, 25.50);
    });

    test('should serialize to and from JSON correctly', () {
      final participant = ParticipantAmount(name: 'Jane', amount: 30.75);
      final json = participant.toJson();
      final fromJson = ParticipantAmount.fromJson(json);
      
      expect(fromJson.name, participant.name);
      expect(fromJson.amount, participant.amount);
    });

    test('should support copyWith method', () {
      final participant = ParticipantAmount(name: 'Bob', amount: 15.25);
      final updated = participant.copyWith(amount: 20.00);
      
      expect(updated.name, 'Bob');
      expect(updated.amount, 20.00);
    });
  });

  group('ReceiptModeConfig', () {
    test('should have correct receipt mode configuration', () {
      const config = ReceiptModeConfig.receiptMode;
      
      expect(config.isGroupEditable, false);
      expect(config.isTotalEditable, false);
      expect(config.isSplitTypeEditable, false);
      expect(config.areCustomAmountsEditable, false);
      expect(config.defaultSplitType, 'custom');
    });

    test('should have correct manual mode configuration', () {
      const config = ReceiptModeConfig.manualMode;
      
      expect(config.isGroupEditable, true);
      expect(config.isTotalEditable, true);
      expect(config.isSplitTypeEditable, true);
      expect(config.areCustomAmountsEditable, true);
      expect(config.defaultSplitType, 'equal');
    });

    test('should serialize to and from JSON correctly', () {
      const config = ReceiptModeConfig.receiptMode;
      final json = config.toJson();
      final fromJson = ReceiptModeConfig.fromJson(json);
      
      expect(fromJson.isGroupEditable, config.isGroupEditable);
      expect(fromJson.isTotalEditable, config.isTotalEditable);
      expect(fromJson.isSplitTypeEditable, config.isSplitTypeEditable);
      expect(fromJson.areCustomAmountsEditable, config.areCustomAmountsEditable);
      expect(fromJson.defaultSplitType, config.defaultSplitType);
    });
  });

  group('ReceiptModeData', () {
    late List<ParticipantAmount> validParticipants;
    late List<Map<String, dynamic>> validItems;
    late List<Map<String, dynamic>> validMembers;

    setUp(() {
      validParticipants = [
        ParticipantAmount(name: 'John', amount: 25.00),
        ParticipantAmount(name: 'Jane', amount: 25.00),
      ];
      
      validItems = [
        {'name': 'Pizza', 'totalPrice': 30.00, 'quantity': 1},
        {'name': 'Drinks', 'totalPrice': 20.00, 'quantity': 2},
      ];
      
      validMembers = [
        {'name': 'John', 'id': 1},
        {'name': 'Jane', 'id': 2},
      ];
    });

    test('should create valid ReceiptModeData', () {
      final receiptData = ReceiptModeData(
        total: 50.00,
        participantAmounts: validParticipants,
        mode: 'receipt',
        isEqualSplit: true,
        items: validItems,
        groupMembers: validMembers,
      );
      
      expect(receiptData.total, 50.00);
      expect(receiptData.participantAmounts.length, 2);
      expect(receiptData.mode, 'receipt');
      expect(receiptData.isEqualSplit, true);
      expect(receiptData.items.length, 2);
      expect(receiptData.groupMembers.length, 2);
    });

    test('should validate correctly with valid data', () {
      final receiptData = ReceiptModeData(
        total: 50.00,
        participantAmounts: validParticipants,
        mode: 'receipt',
        isEqualSplit: true,
        items: validItems,
        groupMembers: validMembers,
      );
      
      expect(receiptData.validate(), null);
      expect(receiptData.isValid, true);
    });

    test('should fail validation with negative total', () {
      final receiptData = ReceiptModeData(
        total: -10.00,
        participantAmounts: validParticipants,
        mode: 'receipt',
        isEqualSplit: true,
        items: validItems,
        groupMembers: validMembers,
      );
      
      expect(receiptData.validate(), 'Total amount must be greater than zero');
      expect(receiptData.isValid, false);
    });

    test('should fail validation with empty participant amounts', () {
      final receiptData = ReceiptModeData(
        total: 50.00,
        participantAmounts: [],
        mode: 'receipt',
        isEqualSplit: true,
        items: validItems,
        groupMembers: validMembers,
      );
      
      expect(receiptData.validate(), 'Participant amounts cannot be empty');
      expect(receiptData.isValid, false);
    });

    test('should fail validation with mismatched participant amounts sum', () {
      final mismatchedParticipants = [
        ParticipantAmount(name: 'John', amount: 20.00),
        ParticipantAmount(name: 'Jane', amount: 20.00),
      ];
      
      final receiptData = ReceiptModeData(
        total: 50.00,
        participantAmounts: mismatchedParticipants,
        mode: 'receipt',
        isEqualSplit: true,
        items: validItems,
        groupMembers: validMembers,
      );
      
      final validationError = receiptData.validate();
      expect(validationError, contains('Sum of participant amounts'));
      expect(receiptData.isValid, false);
    });

    test('should fail validation with invalid mode', () {
      final receiptData = ReceiptModeData(
        total: 50.00,
        participantAmounts: validParticipants,
        mode: 'invalid_mode',
        isEqualSplit: true,
        items: validItems,
        groupMembers: validMembers,
      );
      
      expect(receiptData.validate(), 'Invalid mode: must be either "receipt" or "manual"');
      expect(receiptData.isValid, false);
    });

    test('should serialize to and from JSON correctly', () {
      final receiptData = ReceiptModeData(
        total: 50.00,
        participantAmounts: validParticipants,
        mode: 'receipt',
        isEqualSplit: true,
        items: validItems,
        groupMembers: validMembers,
      );
      
      final json = receiptData.toJson();
      final fromJson = ReceiptModeData.fromJson(json);
      
      expect(fromJson.total, receiptData.total);
      expect(fromJson.participantAmounts.length, receiptData.participantAmounts.length);
      expect(fromJson.mode, receiptData.mode);
      expect(fromJson.isEqualSplit, receiptData.isEqualSplit);
      expect(fromJson.items.length, receiptData.items.length);
      expect(fromJson.groupMembers.length, receiptData.groupMembers.length);
    });

    test('should support copyWith method', () {
      final receiptData = ReceiptModeData(
        total: 50.00,
        participantAmounts: validParticipants,
        mode: 'receipt',
        isEqualSplit: true,
        items: validItems,
        groupMembers: validMembers,
      );
      
      final updated = receiptData.copyWith(total: 75.00, mode: 'manual');
      
      expect(updated.total, 75.00);
      expect(updated.mode, 'manual');
      expect(updated.participantAmounts, receiptData.participantAmounts);
      expect(updated.isEqualSplit, receiptData.isEqualSplit);
    });
  });
}