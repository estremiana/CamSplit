import 'participant_amount.dart';
import 'package:currency_picker/currency_picker.dart';
import '../services/currency_migration_service.dart';

/// Model representing detailed expense information for viewing and editing
/// 
/// This model extends the basic expense information with additional details
/// needed for the expense detail view, including split information,
/// receipt data, and metadata for editing operations.
class ExpenseDetailModel {
  final int id;
  final String title;
  final double amount;
  final Currency currency;
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
    // Extract payer information from payers array or fallback to individual fields
    String payerName = '';
    int payerId = 0;
    
    if (json['payers'] != null && json['payers'] is List && (json['payers'] as List).isNotEmpty) {
      // Use the first payer from the payers array
      final firstPayer = json['payers'][0];
      payerName = firstPayer['name'] ?? '';
      // The backend sends 'id' which is actually the group_member_id
      payerId = firstPayer['id'] ?? 0;
      print('Extracted payer ID: $payerId from payer data: $firstPayer');
    } else {
      // Fallback to individual payer fields
      payerName = json['payer_name'] ?? '';
      payerId = json['payer_id'] ?? 0;
    }
    
    return ExpenseDetailModel(
      id: json['id'],
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: CurrencyMigrationService.parseFromBackend(json['currency'] ?? 'EUR'),
      date: DateTime.parse(json['date']),
      category: json['category'] ?? 'Other',
      notes: json['notes'] ?? '',
      groupId: json['group_id']?.toString() ?? '',
      groupName: json['group_name'] ?? '',
      payerName: payerName,
      payerId: payerId,
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
      'currency': CurrencyMigrationService.prepareForBackend(currency, format: 'code'),
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
    Currency? currency,
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
           currency.code.isNotEmpty &&
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
    if (!participantAmounts.every((p) => (p.name?.isNotEmpty ?? false) && p.amount >= 0)) {
      return false;
    }

    // For custom split, sum should approximately equal total amount
    if (splitType == 'custom') {
      final sum = participantAmounts.fold<double>(0, (sum, p) => sum + p.amount);
      // Round to 2 decimal places to avoid floating-point precision issues
      final roundedSum = double.parse(sum.toStringAsFixed(2));
      final roundedAmount = double.parse(amount.toStringAsFixed(2));
      final difference = (roundedSum - roundedAmount).abs();

      return difference < 0.011; // Allow for small rounding differences
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
    return '${amount.toStringAsFixed(2)} ${currency.code}';
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
  final int groupId; // Add group ID for backend validation
  final String title;
  final double amount;
  final Currency currency;
  final DateTime date;
  final String category;
  final String notes;
  final String splitType;
  final List<ParticipantAmount> participantAmounts;
  final List<Map<String, dynamic>> payers; // Add payers for backend update

  ExpenseUpdateRequest({
    required this.expenseId,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    required this.notes,
    required this.splitType,
    required this.participantAmounts,
    required this.payers,
  });

  /// Create ExpenseUpdateRequest from ExpenseDetailModel
  factory ExpenseUpdateRequest.fromExpenseDetail(ExpenseDetailModel expense) {
    // Create payer data using the actual payer from the expense
    final payers = [
      {
        'group_member_id': expense.payerId, // Use the actual payer ID from the expense
        'amount_paid': expense.amount,
        'payment_method': 'unknown',
        'payment_date': DateTime.now().toIso8601String(),
      }
    ];
    
    return ExpenseUpdateRequest(
      expenseId: expense.id,
      groupId: int.tryParse(expense.groupId) ?? 0,
      title: expense.title,
      amount: expense.amount,
      currency: expense.currency,
      date: expense.date,
      category: expense.category,
      notes: expense.notes,
      splitType: expense.splitType,
      participantAmounts: expense.participantAmounts,
      payers: payers,
    );
  }

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'expense_id': expenseId,
      'group_id': groupId,
      'title': title,
      'total_amount': amount.isFinite ? amount : 0.0, // Ensure it's a valid number
      'currency': CurrencyMigrationService.prepareForBackend(currency, format: 'code'),
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}', // YYYY-MM-DD format
      'category': category,
      'notes': notes,
      'split_type': splitType, // Backend expects 'split_type'
      'receipt_image_url': null, // Backend expects this field
      'participant_amounts': participantAmounts.map((p) => p.toJson()).toList(),
      'payers': payers, // Add payers for backend update
    };
  }

  /// Validate update request data
  bool isValid() {
    return expenseId > 0 &&
           groupId > 0 &&
           title.isNotEmpty &&
           amount > 0 && // Changed from >= 0 to > 0
           amount.isFinite && // Ensure it's a valid number
           currency.code.isNotEmpty &&
           category.isNotEmpty &&
           _isValidSplitType() &&
           _hasValidParticipantAmounts() &&
           _hasValidPayers();
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
    if (!participantAmounts.every((p) => (p.name?.isNotEmpty ?? false) && p.amount >= 0)) {
      return false;
    }

    // For custom split, sum should approximately equal total amount
    if (splitType == 'custom') {
      final sum = participantAmounts.fold<double>(0, (sum, p) => sum + p.amount);
      return (sum - amount).abs() < 0.01;
    }

    return true;
  }

  /// Validate payers
  bool _hasValidPayers() {
    if (payers.isEmpty) return false;

    // Check that all payers have required fields
    if (!payers.every((p) => 
        p['group_member_id'] != null && 
        p['amount_paid'] != null && 
        p['amount_paid'] > 0)) {
      return false;
    }

    // Check that total paid matches expense amount
    final totalPaid = payers.fold<double>(0, (sum, p) => sum + ((p['amount_paid'] as num?)?.toDouble() ?? 0.0));
    return (totalPaid - amount).abs() < 0.01;
  }

  @override
  String toString() {
    return 'ExpenseUpdateRequest(expenseId: $expenseId, title: $title, amount: $amount)';
  }
}