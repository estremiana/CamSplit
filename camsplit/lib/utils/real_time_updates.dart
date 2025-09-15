import 'dart:async';

import 'package:flutter/material.dart';
import '../models/group_detail_model.dart';

/// Utility class for handling real-time updates and optimistic updates
/// This class provides methods for managing data synchronization and
/// optimistic UI updates across the application
class RealTimeUpdates {
  static final Map<int, List<Function(GroupDetailModel)>> _groupUpdateListeners = {};
  static final Map<int, GroupDetailModel> _cachedGroupData = {};
  
  /// Register a listener for group updates
  /// [groupId] - The ID of the group to listen for updates
  /// [listener] - Callback function to be called when group data changes
  static void addGroupUpdateListener(int groupId, Function(GroupDetailModel) listener) {
    if (!_groupUpdateListeners.containsKey(groupId)) {
      _groupUpdateListeners[groupId] = [];
    }
    _groupUpdateListeners[groupId]!.add(listener);
  }

  /// Remove a listener for group updates
  /// [groupId] - The ID of the group to stop listening for updates
  /// [listener] - The callback function to remove
  static void removeGroupUpdateListener(int groupId, Function(GroupDetailModel) listener) {
    _groupUpdateListeners[groupId]?.remove(listener);
    if (_groupUpdateListeners[groupId]?.isEmpty == true) {
      _groupUpdateListeners.remove(groupId);
    }
  }

  /// Notify all listeners of a group update
  /// [groupId] - The ID of the group that was updated
  /// [groupData] - The updated group data
  static void notifyGroupUpdate(int groupId, GroupDetailModel groupData) {
    _cachedGroupData[groupId] = groupData;
    
    final listeners = _groupUpdateListeners[groupId];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(groupData);
        } catch (e) {
          debugPrint('Error in group update listener: $e');
        }
      }
    }
  }

  /// Get cached group data
  /// [groupId] - The ID of the group to get cached data for
  static GroupDetailModel? getCachedGroupData(int groupId) {
    return _cachedGroupData[groupId];
  }

  /// Clear cached group data
  /// [groupId] - The ID of the group to clear cache for (optional, clears all if null)
  static void clearCachedGroupData([int? groupId]) {
    if (groupId != null) {
      _cachedGroupData.remove(groupId);
    } else {
      _cachedGroupData.clear();
    }
  }

  /// Create an optimistic expense update
  /// This method creates a temporary expense object for immediate UI updates
  /// [expenseData] - The expense data from the creation response
  /// [groupId] - The ID of the group the expense belongs to
  static GroupExpense createOptimisticExpense(Map<String, dynamic> expenseData, int groupId) {
    return GroupExpense(
      id: expenseData['id'] ?? 0,
      title: expenseData['title'] ?? 'New Expense',
      amount: (expenseData['amount'] ?? 0.0).toDouble(),
      currency: expenseData['currency'] ?? 'EUR',
      date: expenseData['date'] is DateTime 
          ? expenseData['date'] 
          : DateTime.parse(expenseData['date'] ?? DateTime.now().toIso8601String()),
      payerName: expenseData['payerName'] ?? 'Unknown',
      payerId: expenseData['payerId'] ?? 1,
      createdAt: DateTime.now(),
    );
  }

  /// Apply optimistic update to group data
  /// [groupId] - The ID of the group to update
  /// [newExpense] - The new expense to add optimistically
  static GroupDetailModel? applyOptimisticExpenseUpdate(int groupId, GroupExpense newExpense) {
    final currentData = _cachedGroupData[groupId];
    if (currentData == null) return null;

    final updatedExpenses = [newExpense, ...currentData.expenses];
    final updatedData = currentData.copyWith(expenses: updatedExpenses);
    
    _cachedGroupData[groupId] = updatedData;
    notifyGroupUpdate(groupId, updatedData);
    
    return updatedData;
  }

  /// Revert optimistic update
  /// [groupId] - The ID of the group to revert
  /// [originalData] - The original group data before optimistic update
  static void revertOptimisticUpdate(int groupId, GroupDetailModel originalData) {
    _cachedGroupData[groupId] = originalData;
    notifyGroupUpdate(groupId, originalData);
  }

  /// Check if data is stale and needs refresh
  /// [lastUpdateTime] - The timestamp of the last update
  /// [maxAge] - Maximum age before data is considered stale
  static bool isDataStale(DateTime lastUpdateTime, Duration maxAge) {
    return DateTime.now().difference(lastUpdateTime) > maxAge;
  }

  /// Debounce function for frequent updates
  /// [callback] - The function to debounce
  /// [delay] - The delay duration
  static Function debounce(Function callback, Duration delay) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, () => callback());
    };
  }

  /// Throttle function for rate limiting updates
  /// [callback] - The function to throttle
  /// [delay] - The delay duration
  static Function throttle(Function callback, Duration delay) {
    DateTime? lastCall;
    return () {
      final now = DateTime.now();
      if (lastCall == null || now.difference(lastCall!) >= delay) {
        lastCall = now;
        callback();
      }
    };
  }
}

/// Mixin for widgets that need real-time updates
mixin RealTimeUpdateMixin<T extends StatefulWidget> on State<T> {
  int? _groupId;
  Function(GroupDetailModel)? _updateListener;

  /// Initialize real-time updates for a group
  /// [groupId] - The ID of the group to listen for updates
  void initializeRealTimeUpdates(int groupId) {
    _groupId = groupId;
    _updateListener = (GroupDetailModel groupData) {
      if (mounted) {
        setState(() {
          // Override this method in the implementing class
          onGroupDataUpdated(groupData);
        });
      }
    };
    
    RealTimeUpdates.addGroupUpdateListener(groupId, _updateListener!);
  }

  /// Clean up real-time updates
  @override
  void dispose() {
    if (_groupId != null && _updateListener != null) {
      RealTimeUpdates.removeGroupUpdateListener(_groupId!, _updateListener!);
    }
    super.dispose();
  }

  /// Override this method to handle group data updates
  void onGroupDataUpdated(GroupDetailModel groupData) {
    // Default implementation - override in subclasses
  }

  /// Notify other components of group updates
  void notifyGroupUpdate(GroupDetailModel groupData) {
    if (_groupId != null) {
      RealTimeUpdates.notifyGroupUpdate(_groupId!, groupData);
    }
  }
} 