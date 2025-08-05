import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:splitease/services/settlement_service.dart';
import 'package:splitease/services/api_service.dart';
import 'package:splitease/models/settlement.dart';

import 'settlement_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  group('SettlementService', () {
    late SettlementService settlementService;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      settlementService = SettlementService();
    });

    group('getGroupSettlements', () {
      test('should return list of settlements when API call is successful', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': {
            'settlements': [
              {
                'id': 1,
                'group_id': 1,
                'from_group_member_id': 1,
                'to_group_member_id': 2,
                'amount': 50.0,
                'currency': 'EUR',
                'status': 'active',
                'created_at': '2024-01-01T00:00:00Z',
                'updated_at': '2024-01-01T00:00:00Z',
              }
            ]
          }
        };

        when(mockApiService.getGroupSettlements('1'))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await settlementService.getGroupSettlements('1');

        // Assert
        expect(result, isA<List<Settlement>>());
        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.amount, 50.0);
        expect(result.first.status, 'active');
      });

      test('should return empty list when API call fails', () async {
        // Arrange
        when(mockApiService.getGroupSettlements('1'))
            .thenThrow(Exception('API Error'));

        // Act & Assert
        expect(
          () => settlementService.getGroupSettlements('1'),
          throwsException,
        );
      });
    });

    group('processSettlement', () {
      test('should return success when settlement is processed successfully', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'data': {
            'settlement': {
              'id': 1,
              'status': 'settled',
            },
            'expense': {
              'id': 100,
              'title': 'Settlement Payment',
            }
          },
          'message': 'Settlement processed successfully'
        };

        when(mockApiService.processSettlement('1'))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await settlementService.processSettlement('1');

        // Assert
        expect(result['success'], true);
        expect(result['message'], 'Settlement processed successfully');
        expect(result['settlement']['id'], 1);
        expect(result['expense']['id'], 100);
      });

      test('should return failure when API call fails', () async {
        // Arrange
        when(mockApiService.processSettlement('1'))
            .thenThrow(Exception('Processing failed'));

        // Act
        final result = await settlementService.processSettlement('1');

        // Assert
        expect(result['success'], false);
        expect(result['message'], contains('Error processing settlement'));
      });
    });

    group('sendSettlementReminder', () {
      test('should return true when reminder is sent successfully', () async {
        // Arrange
        final mockResponse = {
          'success': true,
          'message': 'Reminder sent successfully'
        };

        when(mockApiService.sendSettlementReminder('1'))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await settlementService.sendSettlementReminder('1');

        // Assert
        expect(result, true);
      });

      test('should return false when reminder fails', () async {
        // Arrange
        when(mockApiService.sendSettlementReminder('1'))
            .thenThrow(Exception('Reminder failed'));

        // Act
        final result = await settlementService.sendSettlementReminder('1');

        // Assert
        expect(result, false);
      });
    });

    group('canProcessSettlement', () {
      test('should return true when user is involved in settlement', () {
        // Arrange
        final settlement = Settlement(
          id: 1,
          groupId: 1,
          fromGroupMemberId: 1,
          toGroupMemberId: 2,
          amount: 50.0,
          currency: 'EUR',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = settlementService.canProcessSettlement(settlement, '1');

        // Assert
        expect(result, true);
      });

      test('should return true when user is the recipient', () {
        // Arrange
        final settlement = Settlement(
          id: 1,
          groupId: 1,
          fromGroupMemberId: 1,
          toGroupMemberId: 2,
          amount: 50.0,
          currency: 'EUR',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = settlementService.canProcessSettlement(settlement, '2');

        // Assert
        expect(result, true);
      });

      test('should return false when user is not involved', () {
        // Arrange
        final settlement = Settlement(
          id: 1,
          groupId: 1,
          fromGroupMemberId: 1,
          toGroupMemberId: 2,
          amount: 50.0,
          currency: 'EUR',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = settlementService.canProcessSettlement(settlement, '3');

        // Assert
        expect(result, false);
      });
    });

    group('getSettlementStatusText', () {
      test('should return correct status text for active', () {
        expect(settlementService.getSettlementStatusText('active'), 'Pending');
      });

      test('should return correct status text for settled', () {
        expect(settlementService.getSettlementStatusText('settled'), 'Completed');
      });

      test('should return correct status text for obsolete', () {
        expect(settlementService.getSettlementStatusText('obsolete'), 'Obsolete');
      });

      test('should return unknown for invalid status', () {
        expect(settlementService.getSettlementStatusText('invalid'), 'Unknown');
      });
    });

    group('getSettlementStatusColor', () {
      test('should return correct color for active', () {
        expect(settlementService.getSettlementStatusColor('active'), Colors.orange);
      });

      test('should return correct color for settled', () {
        expect(settlementService.getSettlementStatusColor('settled'), Colors.green);
      });

      test('should return correct color for obsolete', () {
        expect(settlementService.getSettlementStatusColor('obsolete'), Colors.grey);
      });

      test('should return grey for invalid status', () {
        expect(settlementService.getSettlementStatusColor('invalid'), Colors.grey);
      });
    });
  });
} 