import 'receipt_item.dart';

enum SplitType {
  equal,
  percentage,
  custom,
  items,
}

class ExpenseWizardData {
  double amount;
  String title;
  String date; // ISO format YYYY-MM-DD
  String category;
  String? payerId; // Group member ID
  String? groupId; // Group ID
  SplitType splitType;
  Map<String, double> splitDetails; // memberId -> amount/percentage
  List<String> involvedMembers; // List of member IDs involved in split
  String? receiptImage; // Base64 or file path
  List<ReceiptItem> items;
  String? notes;

  ExpenseWizardData({
    this.amount = 0.0,
    this.title = '',
    String? date,
    this.category = '',
    this.payerId,
    this.groupId,
    this.splitType = SplitType.equal,
    Map<String, double>? splitDetails,
    List<String>? involvedMembers,
    this.receiptImage,
    List<ReceiptItem>? items,
    this.notes,
  })  : date = date ?? DateTime.now().toIso8601String().split('T')[0],
        splitDetails = splitDetails ?? {},
        involvedMembers = involvedMembers ?? [],
        items = items ?? [];

  ExpenseWizardData copyWith({
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
    return ExpenseWizardData(
      amount: amount ?? this.amount,
      title: title ?? this.title,
      date: date ?? this.date,
      category: category ?? this.category,
      payerId: payerId ?? this.payerId,
      groupId: groupId ?? this.groupId,
      splitType: splitType ?? this.splitType,
      splitDetails: splitDetails ?? this.splitDetails,
      involvedMembers: involvedMembers ?? this.involvedMembers,
      receiptImage: receiptImage ?? this.receiptImage,
      items: items ?? this.items,
      notes: notes ?? this.notes,
    );
  }

  // Validation for step 1 (Amount)
  bool validateStep1() {
    return amount > 0;
  }

  // Validation for step 2 (Details)
  bool validateStep2() {
    return groupId != null && groupId!.isNotEmpty && payerId != null && payerId!.isNotEmpty;
  }

  // Validation for step 3 (Split)
  bool validateStep3() {
    if (splitType == SplitType.items) {
      // All items must be fully assigned
      for (var item in items) {
        if (!item.isFullyAssigned) {
          return false;
        }
      }
      return items.isNotEmpty;
    } else if (splitType == SplitType.percentage) {
      // Must sum to 100%
      final total = splitDetails.values.fold(0.0, (sum, val) => sum + val);
      return (total - 100.0).abs() < 0.1;
    } else if (splitType == SplitType.custom) {
      // Must sum to total amount
      final total = splitDetails.values.fold(0.0, (sum, val) => sum + val);
      return (total - amount).abs() < 0.05;
    } else {
      // Equal split - just need at least one member
      return involvedMembers.isNotEmpty;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'title': title,
      'date': date,
      'category': category,
      'payer_id': payerId,
      'group_id': groupId,
      'split_type': splitType.name,
      'split_details': splitDetails,
      'involved_members': involvedMembers,
      'receipt_image': receiptImage,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
    };
  }
}

