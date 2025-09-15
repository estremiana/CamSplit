import 'expense_payer.dart';
import 'expense_split.dart';
import 'receipt_image.dart';

class Expense {
  final int id;
  final int groupId;
  final String title;
  final String? description;
  final double totalAmount;
  final String currency;
  final DateTime? date;
  final String? merchant;
  final String? category;
  final String splitType;
  final List<ExpensePayer> payers;
  final List<ExpenseSplit> splits;
  final List<ReceiptImage> receiptImages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? groupName;
  final String? payerNickname;
  final double amountOwed;

  Expense({
    required this.id,
    required this.groupId,
    required this.title,
    this.description,
    required this.totalAmount,
    required this.currency,
    this.date,
    this.merchant,
    this.category,
    this.splitType = 'equal',
    this.payers = const [],
    this.splits = const [],
    this.receiptImages = const [],
    required this.createdAt,
    required this.updatedAt,
    this.groupName,
    this.payerNickname,
    this.amountOwed = 0.0,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
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
    
    // Helper function to parse receipt images from different formats
    List<ReceiptImage> parseReceiptImages(Map<String, dynamic> json) {
      // Debug logging
      print('Expense.fromJson: Parsing receipt images from JSON');
      print('Expense.fromJson: receipt_images field: ${json['receipt_images']}');
      print('Expense.fromJson: receipt_image_url field: ${json['receipt_image_url']}');
      
      // First try the new format with receipt_images array (but only if it has content)
      if (json['receipt_images'] != null && 
          json['receipt_images'] is List && 
          (json['receipt_images'] as List).isNotEmpty) {
        print('Expense.fromJson: Using receipt_images array format');
        return (json['receipt_images'] as List<dynamic>)
            .map((imageJson) => ReceiptImage.fromJson(imageJson))
            .toList();
      }
      
      // Fallback to the old format with direct receipt_image_url
      if (json['receipt_image_url'] != null && json['receipt_image_url'].toString().isNotEmpty) {
        print('Expense.fromJson: Using receipt_image_url direct format');
        final receiptImage = ReceiptImage(
          id: 0, // No ID available in this format
          expenseId: json['id'] ?? 0,
          imageUrl: json['receipt_image_url'].toString(),
          cloudinaryPublicId: '', // Not available in this format
          createdAt: parseDate(json['created_at']),
          updatedAt: parseDate(json['updated_at']),
        );
        print('Expense.fromJson: Created receipt image with URL: ${receiptImage.imageUrl}');
        return [receiptImage];
      }
      
      print('Expense.fromJson: No receipt images found');
      return [];
    }
    
    return Expense(
      id: int.tryParse(json['id'].toString()) ?? 0,
      groupId: int.tryParse(json['group_id'].toString()) ?? 0,
      title: json['title'] ?? json['description'] ?? '',
      description: json['notes'] ?? json['description'],
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      currency: json['currency'] ?? 'USD',
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      merchant: json['merchant'],
      category: json['category'],
      splitType: json['split_type'] ?? 'equal',
      payers: (json['payers'] as List<dynamic>?)
          ?.map((payerJson) => ExpensePayer.fromJson(payerJson))
          .toList() ?? [],
      splits: (json['splits'] as List<dynamic>?)
          ?.map((splitJson) => ExpenseSplit.fromJson(splitJson))
          .toList() ?? [],
      receiptImages: parseReceiptImages(json),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      groupName: json['group_name'],
      payerNickname: json['payer_nickname'],
      amountOwed: double.tryParse(json['amount_owed']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'title': title,
      'description': description,
      'total_amount': totalAmount,
      'currency': currency,
      'date': date?.toIso8601String(),
      'merchant': merchant,
      'category': category,
      'split_type': splitType,
      'payers': payers.map((payer) => payer.toJson()).toList(),
      'splits': splits.map((split) => split.toJson()).toList(),
      'receipt_images': receiptImages.map((image) => image.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'group_name': groupName,
      'payer_nickname': payerNickname,
      'amount_owed': amountOwed,
    };
  }

  // Validation methods
  bool isValid() {
    return id > 0 && 
           groupId > 0 &&
           title.isNotEmpty && 
           totalAmount > 0 &&
           currency.isNotEmpty &&
           createdAt.isBefore(DateTime.now()) &&
           updatedAt.isBefore(DateTime.now());
  }

  // Helper method to get total paid amount
  double get totalPaid {
    return payers.fold(0.0, (sum, payer) => sum + payer.amountPaid);
  }

  // Helper method to get total owed amount
  double get totalOwed {
    return splits.fold(0.0, (sum, split) => sum + split.amountOwed);
  }

  // Helper method to check if expense is fully paid
  bool get isFullyPaid {
    return totalPaid >= totalAmount;
  }

  // Helper method to check if expense is fully split
  bool get isFullySplit {
    return totalOwed >= totalAmount;
  }

  // Helper method to get remaining amount to be paid
  double get remainingToPay {
    return totalAmount - totalPaid;
  }

  // Helper method to get remaining amount to be split
  double get remainingToSplit {
    return totalAmount - totalOwed;
  }

  // Helper method to get payer by member ID
  ExpensePayer? getPayerByMemberId(int memberId) {
    try {
      return payers.firstWhere((payer) => payer.groupMemberId == memberId);
    } catch (e) {
      return null;
    }
  }

  // Helper method to get split by member ID
  ExpenseSplit? getSplitByMemberId(int memberId) {
    try {
      return splits.firstWhere((split) => split.groupMemberId == memberId);
    } catch (e) {
      return null;
    }
  }

  // Copy with method for updates
  Expense copyWith({
    int? id,
    int? groupId,
    String? title,
    String? description,
    double? totalAmount,
    String? currency,
    DateTime? date,
    String? merchant,
    String? category,
    String? splitType,
    List<ExpensePayer>? payers,
    List<ExpenseSplit>? splits,
    List<ReceiptImage>? receiptImages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      splitType: splitType ?? this.splitType,
      payers: payers ?? this.payers,
      splits: splits ?? this.splits,
      receiptImages: receiptImages ?? this.receiptImages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, totalAmount: $totalAmount, currency: $currency)';
  }

  /// Get the first payer (assuming single payer for frontend)
  ExpensePayer? get firstPayer {
    return payers.isNotEmpty ? payers.first : null;
  }

  /// Get the payer name (first payer's name or 'Unknown')
  String get payerName {
    return firstPayer?.displayName ?? 'Unknown';
  }

  /// Get the payer ID (first payer's ID or 0)
  int get payerId {
    return firstPayer?.groupMemberId ?? 0;
  }
} 