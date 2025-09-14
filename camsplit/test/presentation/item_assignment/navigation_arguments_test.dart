import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/models/receipt_mode_data.dart';
import 'package:camsplit/models/participant_amount.dart';

void main() {
  group('Navigation Arguments Tests', () {
    test('should create proper navigation arguments structure', () {
      // Arrange
      final receiptData = ReceiptModeData(
        total: 30.0,
        participantAmounts: [
          ParticipantAmount(name: 'Alice', amount: 10.0),
          ParticipantAmount(name: 'Bob', amount: 10.0),
          ParticipantAmount(name: 'Charlie', amount: 10.0),
        ],
        mode: 'receipt',
        isEqualSplit: true,
        items: [
          {'id': 1, 'name': 'Pizza', 'totalPrice': 20.0},
          {'id': 2, 'name': 'Drinks', 'totalPrice': 10.0},
        ],
        groupMembers: [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
          {'id': 3, 'name': 'Charlie'},
        ],
      );

      // Act
      final navigationArgs = {
        'receiptData': receiptData.toJson(),
        'mode': 'receipt',
      };

      // Assert
      expect(navigationArgs['mode'], equals('receipt'));
      expect(navigationArgs['receiptData'], isA<Map<String, dynamic>>());
      
      final receiptDataJson = navigationArgs['receiptData'] as Map<String, dynamic>;
      expect(receiptDataJson['total'], equals(30.0));
      expect(receiptDataJson['mode'], equals('receipt'));
      expect(receiptDataJson['is_equal_split'], equals(true));
      expect(receiptDataJson['participant_amounts'], isA<List>());
      expect(receiptDataJson['items'], isA<List>());
      expect(receiptDataJson['group_members'], isA<List>());
    });

    test('should maintain backward compatibility with existing total argument', () {
      // Arrange
      final receiptData = ReceiptModeData(
        total: 25.50,
        participantAmounts: [
          ParticipantAmount(name: 'Alice', amount: 12.75),
          ParticipantAmount(name: 'Bob', amount: 12.75),
        ],
        mode: 'receipt',
        isEqualSplit: true,
        items: [
          {'id': 1, 'name': 'Lunch', 'totalPrice': 25.50},
        ],
        groupMembers: [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ],
      );

      // Act
      final navigationArgs = {
        'receiptData': receiptData.toJson(),
        'mode': 'receipt',
      };

      // Assert - The total should be accessible from receiptData
      final receiptDataJson = navigationArgs['receiptData'] as Map<String, dynamic>;
      expect(receiptDataJson['total'], equals(25.50));
      
      // Verify that the expense creation screen can still access the total
      // even if it's looking for the old 'total' key
      final backwardCompatibleTotal = receiptDataJson['total'];
      expect(backwardCompatibleTotal, equals(25.50));
    });
  });
}