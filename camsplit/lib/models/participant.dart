class Participant {
  final int id;
  final String name;
  final String email;
  final int billId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Participant({
    required this.id,
    required this.name,
    required this.email,
    required this.billId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      billId: json['bill_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bill_id': billId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 