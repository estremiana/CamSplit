/// Model representing data extracted from a scanned receipt
class ScannedReceiptData {
  final double? total;
  final String? merchant;
  final String? date;
  final String? category;
  final List<ScannedItem> items;

  ScannedReceiptData({
    this.total,
    this.merchant,
    this.date,
    this.category,
    List<ScannedItem>? items,
  }) : items = items ?? [];

  /// Create from JSON response from AI scanner
  factory ScannedReceiptData.fromJson(Map<String, dynamic> json) {
    return ScannedReceiptData(
      total: json['total'] != null 
          ? double.tryParse(json['total'].toString()) 
          : null,
      merchant: json['merchant']?.toString(),
      date: json['date']?.toString(),
      category: json['category']?.toString(),
      items: (json['items'] as List<dynamic>?)
          ?.map((itemJson) => ScannedItem.fromJson(itemJson))
          .toList() ?? [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'merchant': merchant,
      'date': date,
      'category': category,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'ScannedReceiptData(total: $total, merchant: $merchant, items: ${items.length})';
  }
}

/// Model representing a single item from a scanned receipt
class ScannedItem {
  final String name;
  final double price;
  final int? quantity;

  ScannedItem({
    required this.name,
    required this.price,
    this.quantity,
  });

  /// Create from JSON
  factory ScannedItem.fromJson(Map<String, dynamic> json) {
    return ScannedItem(
      name: json['name']?.toString() ?? json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] != null 
          ? int.tryParse(json['quantity'].toString()) 
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  @override
  String toString() {
    return 'ScannedItem(name: $name, price: $price, quantity: $quantity)';
  }
}
