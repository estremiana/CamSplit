import 'participant_amount.dart';

class ReceiptModeData {
  final double total;
  final List<ParticipantAmount> participantAmounts;
  final String mode;
  final bool isEqualSplit;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> groupMembers;
  final List<Map<String, dynamic>>? quantityAssignments;
  final String? selectedGroupId;
  final String? selectedGroupName;
  final List<Map<String, dynamic>>? newParticipants;
  final String? imagePath;

  ReceiptModeData({
    required this.total,
    required this.participantAmounts,
    required this.mode,
    required this.isEqualSplit,
    required this.items,
    required this.groupMembers,
    this.quantityAssignments,
    this.selectedGroupId,
    this.selectedGroupName,
    this.newParticipants,
    this.imagePath,
  });

  factory ReceiptModeData.fromJson(Map<String, dynamic> json) {
    return ReceiptModeData(
      total: (json['total'] ?? 0).toDouble(),
      participantAmounts: json['participant_amounts'] != null
          ? (json['participant_amounts'] as List)
              .map((item) => ParticipantAmount.fromJson(item))
              .toList()
          : [],
      mode: json['mode'] ?? 'receipt',
      isEqualSplit: json['is_equal_split'] ?? false,
      items: json['items'] != null
          ? List<Map<String, dynamic>>.from(json['items'])
          : [],
      groupMembers: json['group_members'] != null
          ? List<Map<String, dynamic>>.from(json['group_members'])
          : [],
      quantityAssignments: json['quantity_assignments'] != null
          ? List<Map<String, dynamic>>.from(json['quantity_assignments'])
          : null,
      selectedGroupId: json['selected_group_id'],
      selectedGroupName: json['selected_group_name'],
      newParticipants: json['new_participants'] != null
          ? List<Map<String, dynamic>>.from(json['new_participants'])
          : null,
      imagePath: json['image_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'participant_amounts': participantAmounts.map((item) => item.toJson()).toList(),
      'mode': mode,
      'is_equal_split': isEqualSplit,
      'items': items,
      'group_members': groupMembers,
      'quantity_assignments': quantityAssignments,
      'selected_group_id': selectedGroupId,
      'selected_group_name': selectedGroupName,
      'new_participants': newParticipants,
      'image_path': imagePath,
    };
  }

  ReceiptModeData copyWith({
    double? total,
    List<ParticipantAmount>? participantAmounts,
    String? mode,
    bool? isEqualSplit,
    List<Map<String, dynamic>>? items,
    List<Map<String, dynamic>>? groupMembers,
    List<Map<String, dynamic>>? quantityAssignments,
    String? selectedGroupId,
    String? selectedGroupName,
    List<Map<String, dynamic>>? newParticipants,
    String? imagePath,
  }) {
    return ReceiptModeData(
      total: total ?? this.total,
      participantAmounts: participantAmounts ?? this.participantAmounts,
      mode: mode ?? this.mode,
      isEqualSplit: isEqualSplit ?? this.isEqualSplit,
      items: items ?? this.items,
      groupMembers: groupMembers ?? this.groupMembers,
      quantityAssignments: quantityAssignments ?? this.quantityAssignments,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      selectedGroupName: selectedGroupName ?? this.selectedGroupName,
      newParticipants: newParticipants ?? this.newParticipants,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  /// Validates the receipt mode data for integrity
  /// Returns null if valid, otherwise returns error message
  String? validate() {
    // Check if total is positive
    if (total <= 0) {
      return 'Total amount must be greater than zero';
    }

    // Check if participant amounts list is not empty
    if (participantAmounts.isEmpty) {
      return 'Participant amounts cannot be empty';
    }

    // Check if group members list is not empty
    if (groupMembers.isEmpty) {
      return 'Group members cannot be empty';
    }

    // Check if items list is not empty
    if (items.isEmpty) {
      return 'Items list cannot be empty';
    }

    // Validate mode
    if (mode != 'receipt' && mode != 'manual') {
      return 'Invalid mode: must be either "receipt" or "manual"';
    }

    // Check if participant amounts match total participants count (group members + new participants)
    final totalParticipantsCount = groupMembers.length + (newParticipants?.length ?? 0);
    if (participantAmounts.length != totalParticipantsCount) {
      return 'Participant amounts count must match total participants count (group members: ${groupMembers.length}, new participants: ${newParticipants?.length ?? 0})';
    }

    // Validate participant amounts sum matches total (with small tolerance for floating point)
    double participantAmountsSum = participantAmounts
        .map((pa) => pa.amount)
        .fold(0.0, (sum, amount) => sum + amount);
    
    if ((participantAmountsSum - total).abs() > 0.01) {
      return 'Sum of participant amounts (${participantAmountsSum.toStringAsFixed(2)}) does not match total (${total.toStringAsFixed(2)})';
    }

    // Validate participant names are not empty
    for (var participant in participantAmounts) {
      if (participant.name?.trim().isEmpty ?? true) {
        return 'Participant names cannot be empty';
      }
      if (participant.amount < 0) {
        return 'Participant amounts cannot be negative';
      }
    }

    // Validate group members have required fields
    for (var member in groupMembers) {
      if (member['name'] == null || member['name'].toString().trim().isEmpty) {
        return 'Group member names cannot be empty';
      }
    }

    // Validate items have required fields
    for (var item in items) {
      if (item['name'] == null || item['name'].toString().trim().isEmpty) {
        return 'Item names cannot be empty';
      }
      if (item['totalPrice'] == null || item['totalPrice'] <= 0) {
        return 'Item total prices must be greater than zero';
      }
    }

    // Validate quantity assignments if present
    if (quantityAssignments != null) {
      for (var assignment in quantityAssignments!) {
        if (assignment['itemId'] == null) {
          return 'Quantity assignment item ID cannot be null';
        }
        if (assignment['participantId'] == null) {
          return 'Quantity assignment participant ID cannot be null';
        }
        if (assignment['quantity'] == null || assignment['quantity'] <= 0) {
          return 'Quantity assignment quantity must be greater than zero';
        }
      }
    }

    return null; // Valid
  }

  /// Checks if the data is valid
  bool get isValid => validate() == null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptModeData &&
        other.total == total &&
        _listEquals(other.participantAmounts, participantAmounts) &&
        other.mode == mode &&
        other.isEqualSplit == isEqualSplit &&
        _mapListEquals(other.items, items) &&
        _mapListEquals(other.groupMembers, groupMembers) &&
        _mapListEquals(other.quantityAssignments, quantityAssignments);
  }

  @override
  int get hashCode {
    return total.hashCode ^
        participantAmounts.hashCode ^
        mode.hashCode ^
        isEqualSplit.hashCode ^
        items.hashCode ^
        groupMembers.hashCode ^
        quantityAssignments.hashCode;
  }

  @override
  String toString() {
    return 'ReceiptModeData(total: $total, participantAmounts: $participantAmounts, mode: $mode, isEqualSplit: $isEqualSplit, items: ${items.length} items, groupMembers: ${groupMembers.length} members, quantityAssignments: ${quantityAssignments?.length ?? 0} assignments)';
  }

  // Helper method for comparing lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  // Helper method for comparing map lists
  bool _mapListEquals(List<Map<String, dynamic>>? a, List<Map<String, dynamic>>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (!_mapEquals(a[index], b[index])) return false;
    }
    return true;
  }

  // Helper method for comparing maps
  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}