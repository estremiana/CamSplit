class ReceiptItem {
  final String id;
  final String name;
  final double price; // Total price (unitPrice * quantity)
  final double quantity;
  final double unitPrice;
  final Map<String, double> assignments; // memberId -> quantity assigned
  final bool isCustomSplit; // Lock flag for advanced assignments

  ReceiptItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unitPrice,
    Map<String, double>? assignments,
    this.isCustomSplit = false,
  }) : assignments = assignments ?? {};

  ReceiptItem copyWith({
    String? id,
    String? name,
    double? price,
    double? quantity,
    double? unitPrice,
    Map<String, double>? assignments,
    bool? isCustomSplit,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      assignments: assignments ?? this.assignments,
      isCustomSplit: isCustomSplit ?? this.isCustomSplit,
    );
  }

  // Get total assigned quantity
  double getAssignedCount() {
    return assignments.values.fold(0.0, (sum, qty) => sum + qty);
  }

  // Get remaining quantity
  double getRemainingQuantity() {
    return quantity - getAssignedCount();
  }

  // Check if fully assigned
  bool get isFullyAssigned {
    return getRemainingQuantity() < 0.05; // Small tolerance for floating point
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit_price': unitPrice,
      'assignments': assignments,
      'is_custom_split': isCustomSplit,
    };
  }

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: (json['quantity'] ?? 1.0).toDouble(),
      unitPrice: (json['unit_price'] ?? json['unitPrice'] ?? 0.0).toDouble(),
      assignments: json['assignments'] != null
          ? Map<String, double>.from(
              (json['assignments'] as Map).map(
                (key, value) => MapEntry(key.toString(), (value ?? 0.0).toDouble()),
              ),
            )
          : {},
      isCustomSplit: json['is_custom_split'] ?? json['isCustomSplit'] ?? false,
    );
  }
}

