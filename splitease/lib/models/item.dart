class Item {
  final int id;
  final String name;
  final double unitPrice;
  final double totalPrice;
  final int quantity;
  final int billId;
  final int? participantId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.totalPrice,
    required this.quantity,
    required this.billId,
    this.participantId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      billId: json['bill_id'],
      participantId: json['participant_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': name, // send as 'description' for backend
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'quantity': quantity,
      'bill_id': billId,
      'participant_id': participantId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Item copyWith({
    int? id,
    String? name,
    double? unitPrice,
    double? totalPrice,
    int? quantity,
    int? billId,
    int? participantId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      quantity: quantity ?? this.quantity,
      billId: billId ?? this.billId,
      participantId: participantId ?? this.participantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 