import 'participant_amount.dart';

/// Model representing detailed expense information for viewing and editing
/// 
/// This model extends the basic expense information with additional details
/// needed for the expense detail view, including split information,
/// receipt data, and metadata for editing operations.
class ExpenseDetailModel {
  final int id;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final String category;
  final String notes;
  final String groupId;
  final String groupName;
  final String payerName;
  final int payerId;
  final String splitType;
  final List<ParticipantAmount> participantAmounts;
  final String? receiptImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseDetailModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    required this.notes,
    required this.groupId,
    required this.groupName,
    required this.payerName,
    required this.payerId,
    required this.splitType,
    required this.participantAmounts,
    this.receiptImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ExpenseDetailModel from JSON response
  factory ExpenseDetailModel.fromJson(Map<String, dynamic> json) {
    return ExpenseDetailModel(
      id: json['id'],
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      date: DateTime.parse(json['date']),
      category: json['category'] ?? 'Other',
      notes: json['notes'] ?? '',
      groupId: json['group_id']?.toString() ?? '',
      groupName: json['group_name'] ?? '',
      payerName: json['payer_name'] ?? '',
      payerId: json['payer_id'] ?? 0,
      splitType: json['split_type'] ?? 'equal',
      participantAmounts: (json['participant_amounts'] as List<dynamic>?)
          ?.map((participantJson) => ParticipantAmount.fromJson(participantJson))
          .toList() ?? [],
      receiptImageUrl: json['receipt_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Convert ExpenseDetailModel to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'category': category,
      'notes': notes,
      'group_id': groupId,
      'group_name': groupName,
      'payer_name': payerName,
      'payer_id': payerId,
      'split_type': splitType,
      'participant_amounts': participantAmounts.map((p) => p.toJson()).toList(),
      'receipt_image_url': receiptImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this model with updated fields
  ExpenseDetailModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? currency,
    DateTime? date,
    String? category,
    String? notes,
    String? groupId,
    String? groupName,
    String? payerName,
    int? payerId,
    String? splitType,
    List<ParticipantAmount>? participantAmounts,
    String? receiptImageUrl,
    bool clearReceiptImageUrl = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseDetailModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      payerName: payerName ?? this.payerName,
      payerId: payerId ?? this.payerId,
      splitType: splitType ?? this.splitType,
      participantAmounts: participantAmounts ?? this.participantAmounts,
      receiptImageUrl: clearReceiptImageUrl ? null : (receiptImageUrl ?? this.receiptImageUrl),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validate expense detail data integrity
  bool isValid() {
    return id > 0 &&
           title.isNotEmpty &&
           amount >= 0 &&
           currency.isNotEmpty &&
           category.isNotEmpty &&
           groupId.isNotEmpty &&
           groupName.isNotEmpty &&
           payerName.isNotEmpty &&
           payerId > 0 &&
           _isValidSplitType() &&
           _hasValidParticipantAmounts() &&
           _hasValidTimestamps();
  }

  /// Validate split type
  bool _isValidSplitType() {
    const validSplitTypes = ['equal', 'custom', 'percentage'];
    return validSplitTypes.contains(splitType);
  }

  /// Validate participant amounts based on split type
  bool _hasValidParticipantAmounts() {
    if (participantAmounts.isEmpty) return false;

    // Check that all participant amounts are valid
    if (!participantAmounts.every((p) => p.name.isNotEmpty && p.amount >= 0)) {
      return false;
    }

    // For custom split, sum should approximately equal total amount
    if (splitType == 'custom') {
      final sum = participantAmounts.fold<double>(0, (sum, p) => sum + p.amount);
      return (sum - amount).abs() < 0.01; // Allow for small rounding differences
    }

    return true;
  }

  /// Validate timestamps
  bool _hasValidTimestamps() {
    final now = DateTime.now();
    return createdAt.isBefore(now.add(const Duration(minutes: 1))) &&
           updatedAt.isBefore(now.add(const Duration(minutes: 1))) &&
           !createdAt.isAfter(updatedAt) &&
           date.isBefore(now.add(const Duration(days: 1)));
  }

  /// Get total amount from participant amounts (for validation)
  double get calculatedTotal {
    return participantAmounts.fold<double>(0, (sum, p) => sum + p.amount);
  }

  /// Check if expense has a receipt image
  bool get hasReceiptImage => receiptImageUrl != null && receiptImageUrl!.isNotEmpty;

  /// Get formatted date string
  String get formattedDate {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    return '${amount.toStringAsFixed(2)} $currency';
  }

  /// Check if expense can be edited (not older than 30 days)
  bool get canBeEdited {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return createdAt.isAfter(thirtyDaysAgo);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseDetailModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ExpenseDetailModel(id: $id, title: $title, amount: $amount, groupName: $groupName, payerName: $payerName)';
  }
}

/// Model for expense update requests to the API
/// 
/// This model contains only the fields that can be updated
/// and excludes read-only fields like id, groupId, createdAt, etc.
class ExpenseUpdateRequest {
  final int expenseId;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final String category;
  final String notes;
  final String splitType;
  final List<ParticipantAmount> participantAmounts;

  ExpenseUpdateRequest({
    required this.expenseId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    required this.notes,
    required this.splitType,
    required this.participantAmounts,
  });

  /// Create ExpenseUpdateRequest from ExpenseDetailModel
  factory ExpenseUpdateRequest.fromExpenseDetail(ExpenseDetailModel expense) {
    return ExpenseUpdateRequest(
      expenseId: expense.id,
      title: expense.title,
      amount: expense.amount,
      currency: expense.currency,
      date: expense.date,
      category: expense.category,
      notes: expense.notes,
      splitType: expense.splitType,
      participantAmounts: expense.participantAmounts,
    );
  }

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'expense_id': expenseId,
      'title': title,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'category': category,
      'notes': notes,
      'split_type': splitType,
      'participant_amounts': participantAmounts.map((p) => p.toJson()).toList(),
    };
  }

  /// Validate update request data
  bool isValid() {
    return expenseId > 0 &&
           title.isNotEmpty &&
           amount >= 0 &&
           currency.isNotEmpty &&
           category.isNotEmpty &&
           _isValidSplitType() &&
           _hasValidParticipantAmounts();
  }

  /// Validate split type
  bool _isValidSplitType() {
    const validSplitTypes = ['equal', 'custom', 'percentage'];
    return validSplitTypes.contains(splitType);
  }

  /// Validate participant amounts
  bool _hasValidParticipantAmounts() {
    if (participantAmounts.isEmpty) return false;

    // Check that all participant amounts are valid
    if (!participantAmounts.every((p) => p.name.isNotEmpty && p.amount >= 0)) {
      return false;
    }

    // For custom split, sum should approximately equal total amount
    if (splitType == 'custom') {
      final sum = participantAmounts.fold<double>(0, (sum, p) => sum + p.amount);
      return (sum - amount).abs() < 0.01;
    }

    return true;
  }

  @override
  String toString() {
    return 'ExpenseUpdateRequest(expenseId: $expenseId, title: $title, amount: $amount)';
  }
}