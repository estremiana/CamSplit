class Payment {
  final int id;
  final int fromParticipantId;
  final int toParticipantId;
  final double amount;
  final int billId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.fromParticipantId,
    required this.toParticipantId,
    required this.amount,
    required this.billId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      fromParticipantId: json['from_participant_id'],
      toParticipantId: json['to_participant_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      billId: json['bill_id'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_participant_id': fromParticipantId,
      'to_participant_id': toParticipantId,
      'amount': amount,
      'bill_id': billId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 