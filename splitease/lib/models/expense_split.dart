class ExpenseSplit {
  final int id;
  final int expenseId;
  final int groupMemberId;
  final double amountOwed;
  final String? name;
  final double? percentage; // Percentage value for percentage-based splits
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.groupMemberId,
    required this.amountOwed,
    this.name,
    this.percentage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse dates
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    return ExpenseSplit(
      id: int.tryParse(json['id'].toString()) ?? 0,
      expenseId: int.tryParse(json['expense_id'].toString()) ?? 0,
      groupMemberId: int.tryParse(json['group_member_id'].toString()) ?? 0,
      amountOwed: double.tryParse(json['amount_owed'].toString()) ?? 0.0,
      name: json['nickname'] ?? json['user_name'] ?? json['name'],
      percentage: json['percentage'] != null ? double.tryParse(json['percentage'].toString()) : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'group_member_id': groupMemberId,
      'amount_owed': amountOwed,
      'name': name,
      if (percentage != null) 'percentage': percentage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Validation methods
  bool isValid() {
    return id > 0 && 
           expenseId > 0 &&
           groupMemberId > 0 &&
           amountOwed > 0 &&
           createdAt.isBefore(DateTime.now()) &&
           updatedAt.isBefore(DateTime.now());
  }

  // Copy with method for updates
  ExpenseSplit copyWith({
    int? id,
    int? expenseId,
    int? groupMemberId,
    double? amountOwed,
    String? name,
    double? percentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseSplit(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      groupMemberId: groupMemberId ?? this.groupMemberId,
      amountOwed: amountOwed ?? this.amountOwed,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseSplit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ExpenseSplit(id: $id, expenseId: $expenseId, groupMemberId: $groupMemberId, amountOwed: $amountOwed, name: $name, percentage: $percentage)';
  }

  /// Get the display name for the split
  String get displayName {
    return name ?? 'Member $groupMemberId';
  }
} 