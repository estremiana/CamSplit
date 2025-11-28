/// Model representing a line item from a scanned receipt
/// Used in the Items split mode for assigning items to group members
class ReceiptItem {
  final String id;
  final String name;
  final double price; // total price (unitPrice * quantity)
  final double quantity;
  final double unitPrice;
  final Map<String, double> assignments; // memberId -> quantity assigned
  final bool isCustomSplit;

  ReceiptItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unitPrice,
    Map<String, double>? assignments,
    this.isCustomSplit = false,
  }) : assignments = assignments ?? {};

  /// Calculate the total quantity that has been assigned
  double getAssignedCount() {
    return assignments.values.fold(0.0, (sum, qty) => sum + qty);
  }

  /// Calculate the remaining quantity that hasn't been assigned
  double getRemainingCount() {
    return quantity - getAssignedCount();
  }

  /// Check if the item is fully assigned (within tolerance)
  bool isFullyAssigned() {
    return getRemainingCount() <= 0.05;
  }

  /// Create a copy with updated fields
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
      assignments: assignments ?? Map<String, double>.from(this.assignments),
      isCustomSplit: isCustomSplit ?? this.isCustomSplit,
    );
  }

  /// Convert to JSON for API submission
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

  /// Create from JSON
  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      quantity: double.tryParse(json['quantity']?.toString() ?? '1') ?? 1.0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      assignments: (json['assignments'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, double.tryParse(value.toString()) ?? 0.0),
      ) ?? {},
      isCustomSplit: json['is_custom_split'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ReceiptItem(id: $id, name: $name, quantity: $quantity, unitPrice: $unitPrice, assigned: ${getAssignedCount()}/${quantity})';
  }
}
