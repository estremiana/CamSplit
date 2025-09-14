class Item {
  final int id;
  final String name;
  final double unitPrice;
  final double totalPrice;
  final int quantity;
  final int expenseId;
  final double? confidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.totalPrice,
    required this.quantity,
    required this.expenseId,
    this.confidence,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? json['description'] ?? '',
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
      expenseId: int.tryParse(json['expense_id'].toString()) ?? 0,
      confidence: json['confidence'] != null ? double.tryParse(json['confidence'].toString()) : null,
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
      'expense_id': expenseId,
      'confidence': confidence,
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
    int? expenseId,
    double? confidence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      quantity: quantity ?? this.quantity,
      expenseId: expenseId ?? this.expenseId,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 