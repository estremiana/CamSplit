class Settlement {
  final int id;
  final int groupId;
  final int fromGroupMemberId;
  final int toGroupMemberId;
  final double amount;
  final String currency;
  final String status;
  final DateTime? calculationTimestamp;
  final DateTime? settledAt;
  final int? settledBy;
  final int? createdExpenseId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional metadata from API response
  final Map<String, dynamic>? fromMember;
  final Map<String, dynamic>? toMember;

  Settlement({
    required this.id,
    required this.groupId,
    required this.fromGroupMemberId,
    required this.toGroupMemberId,
    required this.amount,
    required this.currency,
    required this.status,
    this.calculationTimestamp,
    this.settledAt,
    this.settledBy,
    this.createdExpenseId,
    required this.createdAt,
    required this.updatedAt,
    this.fromMember,
    this.toMember,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] ?? 0,
      groupId: json['group_id'] ?? 0,
      fromGroupMemberId: json['from_group_member_id'] ?? 0,
      toGroupMemberId: json['to_group_member_id'] ?? 0,
      amount: _parseAmount(json['amount']),
      currency: json['currency'] ?? 'EUR',
      status: json['status'] ?? 'active',
      calculationTimestamp: _parseDateTime(json['calculation_timestamp']),
      settledAt: _parseDateTime(json['settled_at']),
      settledBy: json['settled_by'],
      createdExpenseId: json['created_expense_id'],
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']) ?? DateTime.now(),
      fromMember: json['from_member'],
      toMember: json['to_member'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'from_group_member_id': fromGroupMemberId,
      'to_group_member_id': toGroupMemberId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'calculation_timestamp': calculationTimestamp?.toIso8601String(),
      'settled_at': settledAt?.toIso8601String(),
      'settled_by': settledBy,
      'created_expense_id': createdExpenseId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'from_member': fromMember,
      'to_member': toMember,
    };
  }

  /// Get the name of the member who owes money
  String get debtorName {
    if (fromMember != null && fromMember!['nickname'] != null) {
      return fromMember!['nickname'];
    }
    return 'Member $fromGroupMemberId';
  }

  /// Get the name of the member who is owed money
  String get creditorName {
    if (toMember != null && toMember!['nickname'] != null) {
      return toMember!['nickname'];
    }
    return 'Member $toGroupMemberId';
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  /// Check if settlement is active (not settled)
  bool get isActive => status == 'active';

  /// Validate settlement data integrity
  bool isValid() {
    return id > 0 && 
           groupId > 0 &&
           fromGroupMemberId > 0 &&
           toGroupMemberId > 0 &&
           amount > 0 &&
           currency.isNotEmpty &&
           status.isNotEmpty &&
           createdAt.isBefore(DateTime.now()) &&
           updatedAt.isBefore(DateTime.now());
  }

  /// Check if settlement is settled
  bool get isSettled => status == 'settled';

  /// Check if a specific user is involved in this settlement
  bool involvesUser(int userId) {
    return fromGroupMemberId == userId || toGroupMemberId == userId;
  }

  /// Get the user's perspective text for this settlement
  String getUserPerspectiveText(int userId) {
    if (fromGroupMemberId == userId) {
      return 'You owe ${creditorName}';
    } else if (toGroupMemberId == userId) {
      return '${debtorName} owes you';
    }
    return '${debtorName} owes ${creditorName}';
  }

  /// Get the display text for the settlement
  String get displayText {
    return '${debtorName} owes ${creditorName}';
  }

  static double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) {
      try {
        return double.parse(amount);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'Settlement(id: $id, groupId: $groupId, $debtorName owes $creditorName $formattedAmount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Settlement && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 