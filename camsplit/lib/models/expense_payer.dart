class ExpensePayer {
  final int id;
  final int expenseId;
  final int groupMemberId;
  final double amountPaid;
  final String? name;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpensePayer({
    required this.id,
    required this.expenseId,
    required this.groupMemberId,
    required this.amountPaid,
    this.name,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpensePayer.fromJson(Map<String, dynamic> json) {
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
    
    return ExpensePayer(
      id: int.tryParse(json['id'].toString()) ?? 0,
      expenseId: int.tryParse(json['expense_id'].toString()) ?? 0,
      groupMemberId: int.tryParse(json['id'].toString()) ?? 0,
      amountPaid: double.tryParse(json['amount_paid'].toString()) ?? 0.0,
      name: json['user_name'] ?? json['nickname'] ?? json['name'],
      email: json['email'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'group_member_id': groupMemberId,
      'amount_paid': amountPaid,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Validation methods
  bool isValid() {
    return id > 0 && 
           expenseId > 0 &&
           groupMemberId > 0 &&
           amountPaid > 0 &&
           createdAt.isBefore(DateTime.now()) &&
           updatedAt.isBefore(DateTime.now());
  }

  // Copy with method for updates
  ExpensePayer copyWith({
    int? id,
    int? expenseId,
    int? groupMemberId,
    double? amountPaid,
    String? name,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpensePayer(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      groupMemberId: groupMemberId ?? this.groupMemberId,
      amountPaid: amountPaid ?? this.amountPaid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpensePayer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ExpensePayer(id: $id, expenseId: $expenseId, groupMemberId: $groupMemberId, amountPaid: $amountPaid, name: $name)';
  }

  /// Get the display name for the payer
  String get displayName {
    return name ?? 'Unknown Payer';
  }
} 