import 'package:flutter/material.dart';

import 'api_service.dart';
import '../models/settlement.dart';

class SettlementService {
  static final SettlementService _instance = SettlementService._internal();
  factory SettlementService() => _instance;
  SettlementService._internal();

  final ApiService _apiService = ApiService.instance;

  /// Get active settlements for a group
  Future<List<Settlement>> getGroupSettlements(String groupId) async {
    try {
      final response = await _apiService.getGroupSettlements(groupId);
      
      if (response['success'] && response['data'] != null) {
        final settlementsData = response['data']['settlements'] as List<dynamic>?;
        if (settlementsData != null) {
          return settlementsData.map((settlementJson) {
            try {
              return Settlement.fromJson(settlementJson);
            } catch (e) {
              print('Failed to parse settlement: $e');
              return null;
            }
          }).where((settlement) => settlement != null).cast<Settlement>().toList();
        }
      }
      return [];
    } catch (e) {
      print('Failed to fetch group settlements: $e');
      rethrow;
    }
  }

  /// Process a settlement by converting it to an expense
  Future<Map<String, dynamic>> processSettlement(String settlementId) async {
    try {
      final response = await _apiService.processSettlement(settlementId);
      
      if (response['success']) {
        return {
          'success': true,
          'settlement': response['data']['settlement'],
          'expense': response['data']['expense'],
          'message': response['message'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to process settlement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error processing settlement: ${e.toString()}',
      };
    }
  }

  /// Get settlement details
  Future<Settlement?> getSettlementDetails(String settlementId) async {
    try {
      final response = await _apiService.getSettlementDetails(settlementId);
      
      if (response['success'] && response['data'] != null) {
        return Settlement.fromJson(response['data']['settlement']);
      }
      return null;
    } catch (e) {
      print('Failed to fetch settlement details: $e');
      return null;
    }
  }

  /// Get settlement history for a group
  Future<List<Settlement>> getSettlementHistory(String groupId, {
    int? limit,
    int? offset,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final response = await _apiService.getSettlementHistory(
        groupId,
        limit: limit,
        offset: offset,
        status: status,
        fromDate: fromDate,
        toDate: toDate,
      );
      
      if (response['success'] && response['data'] != null) {
        final settlementsData = response['data']['settlements'] as List<dynamic>?;
        if (settlementsData != null) {
          return settlementsData.map((settlementJson) {
            try {
              return Settlement.fromJson(settlementJson);
            } catch (e) {
              print('Failed to parse settlement: $e');
              return null;
            }
          }).where((settlement) => settlement != null).cast<Settlement>().toList();
        }
      }
      return [];
    } catch (e) {
      print('Failed to fetch settlement history: $e');
      rethrow;
    }
  }

  /// Send a reminder for a settlement
  Future<bool> sendSettlementReminder(String settlementId) async {
    try {
      final response = await _apiService.sendSettlementReminder(settlementId);
      return response['success'] ?? false;
    } catch (e) {
      print('Failed to send settlement reminder: $e');
      return false;
    }
  }

  /// Check if user can process a settlement
  bool canProcessSettlement(Settlement settlement, String currentUserId) {
    // User can process if they are involved in the settlement
    final fromMemberId = settlement.fromGroupMemberId.toString();
    final toMemberId = settlement.toGroupMemberId.toString();
    
    return fromMemberId == currentUserId || toMemberId == currentUserId;
  }

  /// Get settlement status display text
  String getSettlementStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Pending';
      case 'settled':
        return 'Completed';
      case 'obsolete':
        return 'Obsolete';
      default:
        return 'Unknown';
    }
  }

  /// Get settlement status color
  Color getSettlementStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.orange;
      case 'settled':
        return Colors.green;
      case 'obsolete':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
} 