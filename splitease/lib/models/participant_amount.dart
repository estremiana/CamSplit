class ParticipantAmount {
  final String name;
  final double amount;

  ParticipantAmount({
    required this.name,
    required this.amount,
  });

  factory ParticipantAmount.fromJson(Map<String, dynamic> json) {
    return ParticipantAmount(
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }

  ParticipantAmount copyWith({
    String? name,
    double? amount,
  }) {
    return ParticipantAmount(
      name: name ?? this.name,
      amount: amount ?? this.amount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParticipantAmount &&
        other.name == name &&
        other.amount == amount;
  }

  @override
  int get hashCode => name.hashCode ^ amount.hashCode;

  @override
  String toString() => 'ParticipantAmount(name: $name, amount: $amount)';
}