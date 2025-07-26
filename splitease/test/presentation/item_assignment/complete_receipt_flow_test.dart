import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/models/receipt_mode_data.dart';
import 'package:splitease/models/participant_amount.dart';

void main() {
  group('Complete Receipt Flow Tests', () {
    test('should handle complete equal split flow', () {
      // Arrange - Simulate item assignment data
      final items = [
        {'id': 1, 'name': 'Pizza', 'total_price': 20.0, 'totalPrice': 20.0, 'assignedMembers': []},
        {'id': 2, 'name': 'Drinks', 'total_price': 10.0, 'totalPrice': 10.0, 'assignedMembers': []},
      ];
      
      final groupMembers = [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
        {'id': 3, 'name': 'Charlie'},
      ];
      
      final isEqualSplit = true;
      final quantityAssignments = <Map<String, dynamic>>[];

      // Act - Simulate receipt data preparation
      final totalAmount = items.fold(0.0, (sum, item) => sum + (item['total_price'] as double));
      final perMemberAmount = totalAmount / groupMembers.length;
      
      final participantAmounts = groupMembers.map((member) => 
          ParticipantAmount(name: member['name'] as String, amount: perMemberAmount)).toList();

      final receiptData = ReceiptModeData(
        total: totalAmount,
        participantAmounts: participantAmounts,
        mode: 'receipt',
        isEqualSplit: isEqualSplit,
        items: items,
        groupMembers: groupMembers,
        quantityAssignments: quantityAssignments.isEmpty ? null : quantityAssignments,
      );

      // Assert
      expect(receiptData.total, equals(30.0));
      expect(receiptData.participantAmounts.length, equals(3));
      expect(receiptData.participantAmounts[0].amount, equals(10.0));
      expect(receiptData.participantAmounts[1].amount, equals(10.0));
      expect(receiptData.participantAmounts[2].amount, equals(10.0));
      expect(receiptData.isEqualSplit, isTrue);
      expect(receiptData.validate(), isNull);
    });

    test('should handle complete individual assignment flow', () {
      // Arrange - Simulate individual assignments
      final items = [
        {'id': 1, 'name': 'Pizza', 'total_price': 20.0, 'totalPrice': 20.0, 'assignedMembers': ['1', '2']},
        {'id': 2, 'name': 'Drinks', 'total_price': 10.0, 'totalPrice': 10.0, 'assignedMembers': ['2', '3']},
      ];
      
      final groupMembers = [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
        {'id': 3, 'name': 'Charlie'},
      ];
      
      final isEqualSplit = false;

      // Act - Calculate individual amounts
      Map<String, double> memberAmounts = {};
      for (var member in groupMembers) {
        memberAmounts[member['id'].toString()] = 0.0;
      }

      for (var item in items) {
        final assignedMembers = item['assignedMembers'] as List<String>;
        final itemPrice = item['total_price'] as double;
        
        if (assignedMembers.isNotEmpty) {
          final pricePerMember = itemPrice / assignedMembers.length;
          for (var memberId in assignedMembers) {
            if (memberAmounts.containsKey(memberId)) {
              memberAmounts[memberId] = memberAmounts[memberId]! + pricePerMember;
            }
          }
        }
      }

      final participantAmounts = groupMembers.map((member) {
        final memberId = member['id'].toString();
        final amount = memberAmounts[memberId] ?? 0.0;
        return ParticipantAmount(name: member['name'] as String, amount: amount);
      }).toList();

      final totalAmount = items.fold(0.0, (sum, item) => sum + (item['total_price'] as double));

      final receiptData = ReceiptModeData(
        total: totalAmount,
        participantAmounts: participantAmounts,
        mode: 'receipt',
        isEqualSplit: isEqualSplit,
        items: items,
        groupMembers: groupMembers,
      );

      // Assert
      expect(receiptData.total, equals(30.0));
      expect(receiptData.participantAmounts.length, equals(3));
      // Alice: half of pizza = 10.0
      expect(receiptData.participantAmounts[0].amount, equals(10.0));
      // Bob: half of pizza + half of drinks = 15.0
      expect(receiptData.participantAmounts[1].amount, equals(15.0));
      // Charlie: half of drinks = 5.0
      expect(receiptData.participantAmounts[2].amount, equals(5.0));
      expect(receiptData.isEqualSplit, isFalse);
      expect(receiptData.validate(), isNull);
    });

    test('should handle quantity assignments flow', () {
      // Arrange - Simulate quantity assignments
      final items = [
        {'id': 1, 'name': 'Pizza Slices', 'total_price': 24.0, 'totalPrice': 24.0, 'assignedMembers': ['1', '2']},
      ];
      
      final groupMembers = [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
        {'id': 3, 'name': 'Charlie'},
      ];
      
      final quantityAssignments = [
        {
          'itemId': 1,
          'participantId': 1,
          'memberIds': [1, 2],
          'quantity': 4,
          'totalPrice': 16.0, // 4 slices at $4 each
        },
        {
          'itemId': 1,
          'participantId': 2,
          'memberIds': [3],
          'quantity': 2,
          'totalPrice': 8.0, // 2 slices at $4 each
        },
      ];

      // Act - Calculate from quantity assignments
      final totalAmount = quantityAssignments.fold(0.0, (sum, assignment) => 
          sum + (assignment['totalPrice'] as double));

      Map<String, double> memberAmounts = {};
      for (var member in groupMembers) {
        memberAmounts[member['id'].toString()] = 0.0;
      }

      for (var assignment in quantityAssignments) {
        final memberIds = assignment['memberIds'] as List<dynamic>;
        final totalPrice = assignment['totalPrice'] as double;
        
        if (memberIds.isNotEmpty) {
          final pricePerMember = totalPrice / memberIds.length;
          for (var memberId in memberIds) {
            final memberIdStr = memberId.toString();
            if (memberAmounts.containsKey(memberIdStr)) {
              memberAmounts[memberIdStr] = memberAmounts[memberIdStr]! + pricePerMember;
            }
          }
        }
      }

      final participantAmounts = groupMembers.map((member) {
        final memberId = member['id'].toString();
        final amount = memberAmounts[memberId] ?? 0.0;
        return ParticipantAmount(name: member['name'] as String, amount: amount);
      }).toList();

      final receiptData = ReceiptModeData(
        total: totalAmount,
        participantAmounts: participantAmounts,
        mode: 'receipt',
        isEqualSplit: false,
        items: items,
        groupMembers: groupMembers,
        quantityAssignments: quantityAssignments,
      );

      // Assert
      expect(receiptData.total, equals(24.0));
      expect(receiptData.participantAmounts.length, equals(3));
      // Alice: half of first assignment = 8.0
      expect(receiptData.participantAmounts[0].amount, equals(8.0));
      // Bob: half of first assignment = 8.0
      expect(receiptData.participantAmounts[1].amount, equals(8.0));
      // Charlie: full second assignment = 8.0
      expect(receiptData.participantAmounts[2].amount, equals(8.0));
      expect(receiptData.quantityAssignments, isNotNull);
      expect(receiptData.quantityAssignments!.length, equals(2));
      expect(receiptData.validate(), isNull);
    });

    test('should create proper navigation arguments for expense creation', () {
      // Arrange
      final receiptData = ReceiptModeData(
        total: 50.0,
        participantAmounts: [
          ParticipantAmount(name: 'Alice', amount: 25.0),
          ParticipantAmount(name: 'Bob', amount: 25.0),
        ],
        mode: 'receipt',
        isEqualSplit: true,
        items: [
          {'id': 1, 'name': 'Dinner', 'totalPrice': 50.0},
        ],
        groupMembers: [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ],
      );

      // Act - Create navigation arguments as done in _proceedToExpenseCreation
      final navigationArgs = {
        'receiptData': receiptData.toJson(),
        'mode': 'receipt',
      };

      // Assert
      expect(navigationArgs['mode'], equals('receipt'));
      expect(navigationArgs['receiptData'], isA<Map<String, dynamic>>());
      
      final receiptDataJson = navigationArgs['receiptData'] as Map<String, dynamic>;
      expect(receiptDataJson['total'], equals(50.0));
      expect(receiptDataJson['mode'], equals('receipt'));
      expect(receiptDataJson['is_equal_split'], equals(true));
      
      // Verify participant amounts structure
      final participantAmountsJson = receiptDataJson['participant_amounts'] as List;
      expect(participantAmountsJson.length, equals(2));
      expect(participantAmountsJson[0]['name'], equals('Alice'));
      expect(participantAmountsJson[0]['amount'], equals(25.0));
      expect(participantAmountsJson[1]['name'], equals('Bob'));
      expect(participantAmountsJson[1]['amount'], equals(25.0));
    });
  });
}