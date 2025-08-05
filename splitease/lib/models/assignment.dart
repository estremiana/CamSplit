class Assignment {
  final int id;
  final int expenseId;
  final int itemId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final int peopleCount;
  final double pricePerPerson;
  final DateTime createdAt;
  final DateTime updatedAt;

  Assignment({
    required this.id,
    required this.expenseId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.peopleCount,
    required this.pricePerPerson,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: int.tryParse(json['id'].toString()) ?? 0,
      expenseId: int.tryParse(json['expense_id'].toString()) ?? 0,
      itemId: int.tryParse(json['item_id'].toString()) ?? 0,
      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      peopleCount: int.tryParse(json['people_count'].toString()) ?? 1,
      pricePerPerson: double.tryParse(json['price_per_person'].toString()) ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'item_id': itemId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'people_count': peopleCount,
      'price_per_person': pricePerPerson,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Validation methods
  bool isValid() {
    return id > 0 && 
           expenseId > 0 &&
           itemId > 0 &&
           quantity > 0 &&
           unitPrice > 0 &&
           totalPrice > 0 &&
           peopleCount > 0 &&
           pricePerPerson > 0 &&
           createdAt.isBefore(DateTime.now()) &&
           updatedAt.isBefore(DateTime.now());
  }

  // Copy with method for updates
  Assignment copyWith({
    int? id,
    int? expenseId,
    int? itemId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    int? peopleCount,
    double? pricePerPerson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      peopleCount: peopleCount ?? this.peopleCount,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Assignment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Assignment(id: $id, expenseId: $expenseId, itemId: $itemId, quantity: $quantity, pricePerPerson: $pricePerPerson)';
  }
} 