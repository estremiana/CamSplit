import 'split_type.dart';
import 'receipt_item.dart';

/// Model holding all wizard state across the three pages
class WizardExpenseData {
  final double amount;
  final String title;
  final String date;
  final String category;
  final String payerId;
  final String groupId;
  final SplitType splitType;
  final Map<String, double> splitDetails; // memberId -> amount/percentage
  final List<String> involvedMembers; // for Equal mode
  final String? receiptImage; // base64 or file path
  final List<ReceiptItem> items;
  final String? notes;

  WizardExpenseData({
    this.amount = 0.0,
    this.title = '',
    this.date = '',
    this.category = '',
    this.payerId = '',
    this.groupId = '',
    this.splitType = SplitType.equal,
    Map<String, double>? splitDetails,
    List<String>? involvedMembers,
    this.receiptImage,
    List<ReceiptItem>? items,
    this.notes,
  })  : splitDetails = splitDetails ?? {},
        involvedMembers = involvedMembers ?? [],
        items = items ?? [];

  /// Validate that amount is greater than zero
  bool isAmountValid() {
    return amount > 0;
  }

  /// Validate that all required details are filled
  bool isDetailsValid() {
    return groupId.isNotEmpty && 
           payerId.isNotEmpty && 
           date.isNotEmpty;
  }

  /// Validate that the split configuration is valid
  bool isSplitValid() {
    switch (splitType) {
      case SplitType.equal:
        return involvedMembers.isNotEmpty;
        
      case SplitType.percentage:
        if (splitDetails.isEmpty) return false;
        final totalPercentage = splitDetails.values.fold(0.0, (sum, pct) => sum + pct);
        // Allow 0.1% tolerance for floating point errors
        return (totalPercentage - 100.0).abs() <= 0.1;
        
      case SplitType.custom:
        if (splitDetails.isEmpty) return false;
        final totalAmount = splitDetails.values.fold(0.0, (sum, amt) => sum + amt);
        // Allow 0.05 tolerance for floating point errors
        return (totalAmount - amount).abs() <= 0.05;
        
      case SplitType.items:
        if (items.isEmpty) return false;
        // All items must be fully assigned
        return items.every((item) => item.isFullyAssigned());
    }
  }

  /// Create a copy with updated fields
  WizardExpenseData copyWith({
    double? amount,
    String? title,
    String? date,
    String? category,
    String? payerId,
    String? groupId,
    SplitType? splitType,
    Map<String, double>? splitDetails,
    List<String>? involvedMembers,
    String? receiptImage,
    List<ReceiptItem>? items,
    String? notes,
  }) {
    return WizardExpenseData(
      amount: amount ?? this.amount,
      title: title ?? this.title,
      date: date ?? this.date,
      category: category ?? this.category,
      payerId: payerId ?? this.payerId,
      groupId: groupId ?? this.groupId,
      splitType: splitType ?? this.splitType,
      splitDetails: splitDetails ?? Map<String, double>.from(this.splitDetails),
      involvedMembers: involvedMembers ?? List<String>.from(this.involvedMembers),
      receiptImage: receiptImage ?? this.receiptImage,
      items: items ?? List<ReceiptItem>.from(this.items),
      notes: notes ?? this.notes,
    );
  }

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'title': title,
      'date': date,
      'category': category,
      'payer_id': payerId,
      'group_id': groupId,
      'split_type': splitType.apiValue,
      'split_details': splitDetails,
      'involved_members': involvedMembers,
      'receipt_image': receiptImage,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
    };
  }

  /// Create from JSON
  factory WizardExpenseData.fromJson(Map<String, dynamic> json) {
    return WizardExpenseData(
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      payerId: json['payer_id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      splitType: SplitTypeExtension.fromString(json['split_type']?.toString() ?? 'equal'),
      splitDetails: (json['split_details'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, double.tryParse(value.toString()) ?? 0.0),
      ) ?? {},
      involvedMembers: (json['involved_members'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      receiptImage: json['receipt_image']?.toString(),
      items: (json['items'] as List<dynamic>?)
          ?.map((itemJson) => ReceiptItem.fromJson(itemJson))
          .toList() ?? [],
      notes: json['notes']?.toString(),
    );
  }

  @override
  String toString() {
    return 'WizardExpenseData(amount: $amount, title: $title, groupId: $groupId, splitType: ${splitType.displayName})';
  }
}
