class ParticipantAmount {
  final String? name; // Optional, for backward compatibility
  final double amount;
  final double? percentage; // Percentage value for percentage-based splits
  final int? groupMemberId; // New field for direct backend communication

  ParticipantAmount({
    this.name,
    required this.amount,
    this.percentage,
    this.groupMemberId,
  });

  factory ParticipantAmount.fromJson(Map<String, dynamic> json) {
    return ParticipantAmount(
      name: json['name'],
      amount: (json['amount'] ?? 0).toDouble(),
      percentage: json['percentage'] != null ? (json['percentage'] as num).toDouble() : null,
      groupMemberId: json['group_member_id'] != null ? (json['group_member_id'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      'amount': amount,
      if (percentage != null) 'percentage': percentage,
      if (groupMemberId != null) 'group_member_id': groupMemberId,
    };
  }

  ParticipantAmount copyWith({
    String? name,
    double? amount,
    double? percentage,
    int? groupMemberId,
  }) {
    return ParticipantAmount(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      percentage: percentage ?? this.percentage,
      groupMemberId: groupMemberId ?? this.groupMemberId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParticipantAmount &&
        other.name == name &&
        other.amount == amount &&
        other.percentage == percentage &&
        other.groupMemberId == groupMemberId;
  }

  @override
  int get hashCode => name.hashCode ^ amount.hashCode ^ (percentage?.hashCode ?? 0) ^ (groupMemberId?.hashCode ?? 0);

  @override
  String toString() => 'ParticipantAmount(name: $name, amount: $amount, percentage: $percentage, groupMemberId: $groupMemberId)';
}