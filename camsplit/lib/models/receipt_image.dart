class ReceiptImage {
  final int id;
  final int expenseId;
  final String imageUrl;
  final String cloudinaryPublicId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReceiptImage({
    required this.id,
    required this.expenseId,
    required this.imageUrl,
    required this.cloudinaryPublicId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReceiptImage.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse dates
    DateTime parseDate(dynamic dateValue) {
      if (dateValue == null) return DateTime.now();
      if (dateValue is DateTime) return dateValue;
      if (dateValue is String) {
        try {
          return DateTime.parse(dateValue);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }
    
    return ReceiptImage(
      id: json['id'] ?? 0,
      expenseId: json['expense_id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      cloudinaryPublicId: json['cloudinary_public_id'] ?? '', // Make this optional
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'image_url': imageUrl,
      'cloudinary_public_id': cloudinaryPublicId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Validation methods
  bool isValid() {
    return id >= 0 && // Allow 0 for receipt_image_url format
           expenseId > 0 &&
           imageUrl.isNotEmpty &&
           // cloudinaryPublicId is now optional, so don't require it
           createdAt.isBefore(DateTime.now()) &&
           updatedAt.isBefore(DateTime.now());
  }

  // Copy with method for updates
  ReceiptImage copyWith({
    int? id,
    int? expenseId,
    String? imageUrl,
    String? cloudinaryPublicId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceiptImage(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      imageUrl: imageUrl ?? this.imageUrl,
      cloudinaryPublicId: cloudinaryPublicId ?? this.cloudinaryPublicId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptImage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ReceiptImage(id: $id, expenseId: $expenseId, imageUrl: $imageUrl)';
  }
} 