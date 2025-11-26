/// Model representing a receipt item extracted from OCR or manually entered
class ReceiptItem {
  final String id;
  final String name;
  final double unitPrice;
  final double quantity; // max_quantity - total available quantity
  final double totalPrice; // unitPrice * quantity
  final Map<String, double> assignments; // memberId -> quantity assigned
  final bool isCustomSplit; // true if advanced assignments exist (locks simple mode)

  ReceiptItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.assignments = const {},
    this.isCustomSplit = false,
  });

  /// Create from JSON (typically from OCR or API)
  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    // Handle different JSON formats
    final id = json['id']?.toString() ?? 
               json['item_id']?.toString() ?? 
               'item-${DateTime.now().millisecondsSinceEpoch}';
    
    final name = json['name']?.toString() ?? 
                 json['description']?.toString() ?? 
                 'Unknown Item';
    
    final unitPrice = (json['unit_price'] ?? json['unitPrice'] ?? 0.0).toDouble();
    final quantity = (json['quantity'] ?? json['max_quantity'] ?? json['maxQuantity'] ?? 1).toDouble();
    final totalPrice = (json['total_price'] ?? json['totalPrice'] ?? unitPrice * quantity).toDouble();
    
    // Parse assignments if present
    Map<String, double> assignments = {};
    if (json['assignments'] != null) {
      if (json['assignments'] is Map) {
        assignments = Map<String, double>.from(
          (json['assignments'] as Map).map(
            (key, value) => MapEntry(key.toString(), (value ?? 0.0).toDouble())
          )
        );
      }
    }
    
    final isCustomSplit = json['is_custom_split'] ?? 
                          json['isCustomSplit'] ?? 
                          json['isCustom'] ?? 
                          false;

    return ReceiptItem(
      id: id,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity,
      totalPrice: totalPrice,
      assignments: assignments,
      isCustomSplit: isCustomSplit,
    );
  }

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit_price': unitPrice,
      'max_quantity': quantity,
      'total_price': totalPrice,
      'assignments': assignments,
      'is_custom_split': isCustomSplit,
    };
  }

  /// Get total assigned quantity for this item
  double getAssignedQuantity() {
    return assignments.values.fold(0.0, (sum, qty) => sum + qty);
  }

  /// Get remaining unassigned quantity
  double getRemainingQuantity() {
    return quantity - getAssignedQuantity();
  }

  /// Check if item is fully assigned (within 0.05 tolerance for floating point)
  bool get isFullyAssigned {
    return getRemainingQuantity() < 0.05;
  }

  /// Get assigned quantity for a specific member
  double getAssignedQuantityForMember(String memberId) {
    return assignments[memberId] ?? 0.0;
  }

  /// Get total price assigned to a specific member
  double getAssignedPriceForMember(String memberId) {
    return getAssignedQuantityForMember(memberId) * unitPrice;
  }

  /// Create a copy with updated values
  ReceiptItem copyWith({
    String? id,
    String? name,
    double? unitPrice,
    double? quantity,
    double? totalPrice,
    Map<String, double>? assignments,
    bool? isCustomSplit,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      assignments: assignments ?? this.assignments,
      isCustomSplit: isCustomSplit ?? this.isCustomSplit,
    );
  }

  /// Update assignments (creates new instance)
  ReceiptItem updateAssignments(Map<String, double> newAssignments, {bool isAdvanced = false}) {
    return copyWith(
      assignments: newAssignments,
      isCustomSplit: isAdvanced ? true : this.isCustomSplit,
    );
  }

  /// Clear all assignments
  ReceiptItem clearAssignments() {
    return copyWith(
      assignments: {},
      isCustomSplit: false,
    );
  }

  @override
  String toString() {
    return 'ReceiptItem(id: $id, name: $name, unitPrice: $unitPrice, quantity: $quantity, assigned: ${getAssignedQuantity()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

