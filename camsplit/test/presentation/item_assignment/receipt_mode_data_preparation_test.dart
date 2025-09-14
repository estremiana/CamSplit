import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/models/receipt_mode_data.dart';
import 'package:camsplit/models/participant_amount.dart';

void main() {
  group('Receipt Mode Data Preparation Tests', () {
    late List<Map<String, dynamic>> mockItems;
    late List<Map<String, dynamic>> mockGroupMembers;
    late List<Map<String, dynamic>> mockQuantityAssignments;

    setUp(() {
      mockItems = [
        {
          'id': 1,
          'name': 'Pizza',
          'total_price': 20.0,
          'totalPrice': 20.0,
          'assignedMembers': ['1', '2'],
        },
        {
          'id': 2,
          'name': 'Drinks',
          'total_price': 10.0,
          'totalPrice': 10.0,
          'assignedMembers': ['2', '3'],
        },
      ];

      mockGroupMembers = [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
        {'id': 3, 'name': 'Charlie'},
      ];

      mockQuantityAssignments = [
        {
          'itemId': 1,
          'participantId': 1,
          'memberIds': [1, 2],
          'quantity': 2,
          'totalPrice': 15.0,
        },
      ];
    });

    test('should calculate total amount from items when no quantity assignments', () {
      // Arrange
      final expectedTotal = 30.0; // 20.0 + 10.0

      // Act
      final receiptData = ReceiptModeData(
        total: mockItems.fold(0.0, (sum, item) => sum + (item['total_price'] as double)),
        participantAmounts: [],
        mode: 'receipt',
        isEqualSplit: false,
        items: mockItems,
        groupMembers: mockGroupMembers,
      );

      // Assert
      expect(receiptData.total, equals(expectedTotal));
    });

    test('should calculate total amount from quantity assignments when available', () {
      // Arrange
      final expectedTotal = 15.0; // From quantity assignment

      // Act
      final receiptData = ReceiptModeData(
        total: mockQuantityAssignments.fold(0.0, (sum, assignment) => 
            sum + (assignment['totalPrice'] as double)),
        participantAmounts: [],
        mode: 'receipt',
        isEqualSplit: false,
        items: mockItems,
        groupMembers: mockGroupMembers,
        quantityAssignments: mockQuantityAssignments,
      );

      // Assert
      expect(receiptData.total, equals(expectedTotal));
    });

    test('should create equal split participant amounts correctly', () {
      // Arrange
      final total = 30.0;
      final expectedAmountPerMember = 10.0; // 30.0 / 3 members

      // Act
      final participantAmounts = mockGroupMembers.map((member) => 
          ParticipantAmount(
            name: member['name'],
            amount: expectedAmountPerMember,
          )).toList();

      final receiptData = ReceiptModeData(
        total: total,
        participantAmounts: participantAmounts,
        mode: 'receipt',
        isEqualSplit: true,
        items: mockItems,
        groupMembers: mockGroupMembers,
      );

      // Assert
      expect(receiptData.participantAmounts.length, equals(3));
      expect(receiptData.participantAmounts[0].name, equals('Alice'));
      expect(receiptData.participantAmounts[0].amount, equals(10.0));
      expect(receiptData.participantAmounts[1].name, equals('Bob'));
      expect(receiptData.participantAmounts[1].amount, equals(10.0));
      expect(receiptData.participantAmounts[2].name, equals('Charlie'));
      expect(receiptData.participantAmounts[2].amount, equals(10.0));
    });

    test('should create individual assignment participant amounts correctly', () {
      // Arrange - Alice gets half of Pizza (10.0), Bob gets half of Pizza + half of Drinks (15.0), Charlie gets half of Drinks (5.0)
      final participantAmounts = [
        ParticipantAmount(name: 'Alice', amount: 10.0),
        ParticipantAmount(name: 'Bob', amount: 15.0),
        ParticipantAmount(name: 'Charlie', amount: 5.0),
      ];

      // Act
      final receiptData = ReceiptModeData(
        total: 30.0,
        participantAmounts: participantAmounts,
        mode: 'receipt',
        isEqualSplit: false,
        items: mockItems,
        groupMembers: mockGroupMembers,
      );

      // Assert
      expect(receiptData.participantAmounts.length, equals(3));
      expect(receiptData.participantAmounts[0].amount, equals(10.0));
      expect(receiptData.participantAmounts[1].amount, equals(15.0));
      expect(receiptData.participantAmounts[2].amount, equals(5.0));
      
      // Verify total matches sum of participant amounts
      final totalFromParticipants = receiptData.participantAmounts
          .fold(0.0, (sum, pa) => sum + pa.amount);
      expect(totalFromParticipants, equals(30.0));
    });

    test('should validate receipt mode data correctly', () {
      // Arrange
      final validReceiptData = ReceiptModeData(
        total: 30.0,
        participantAmounts: [
          ParticipantAmount(name: 'Alice', amount: 10.0),
          ParticipantAmount(name: 'Bob', amount: 10.0),
          ParticipantAmount(name: 'Charlie', amount: 10.0),
        ],
        mode: 'receipt',
        isEqualSplit: true,
        items: mockItems,
        groupMembers: mockGroupMembers,
      );

      // Act & Assert
      expect(validReceiptData.validate(), isNull);
      expect(validReceiptData.isValid, isTrue);
    });

    test('should detect invalid receipt mode data', () {
      // Arrange - participant amounts don't match total
      final invalidReceiptData = ReceiptModeData(
        total: 30.0,
        participantAmounts: [
          ParticipantAmount(name: 'Alice', amount: 5.0),
          ParticipantAmount(name: 'Bob', amount: 5.0),
          ParticipantAmount(name: 'Charlie', amount: 5.0),
        ],
        mode: 'receipt',
        isEqualSplit: false,
        items: mockItems,
        groupMembers: mockGroupMembers,
      );

      // Act & Assert
      expect(invalidReceiptData.validate(), isNotNull);
      expect(invalidReceiptData.isValid, isFalse);
    });

    test('should handle quantity assignments in receipt data', () {
      // Arrange
      final receiptData = ReceiptModeData(
        total: 15.0,
        participantAmounts: [
          ParticipantAmount(name: 'Alice', amount: 7.5),
          ParticipantAmount(name: 'Bob', amount: 7.5),
          ParticipantAmount(name: 'Charlie', amount: 0.0),
        ],
        mode: 'receipt',
        isEqualSplit: false,
        items: mockItems,
        groupMembers: mockGroupMembers,
        quantityAssignments: mockQuantityAssignments,
      );

      // Act & Assert
      expect(receiptData.quantityAssignments, isNotNull);
      expect(receiptData.quantityAssignments!.length, equals(1));
      expect(receiptData.validate(), isNull);
    });
  });
}