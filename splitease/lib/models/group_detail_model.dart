import 'group_member.dart';
import 'settlement.dart';

class GroupExpense {
  final int id;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final String payerName;
  final int payerId;
  final DateTime createdAt;

  GroupExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.payerName,
    required this.payerId,
    required this.createdAt,
  });

  factory GroupExpense.fromJson(Map<String, dynamic> json) {
    // Handle new backend structure with payers array
    String payerName = 'Unknown';
    int payerId = 0;
    
    if (json['payers'] != null && json['payers'] is List && (json['payers'] as List).isNotEmpty) {
      // Take the first payer from the array
      final firstPayer = json['payers'][0];
      payerName = firstPayer['name'] ?? 'Unknown';
      payerId = firstPayer['id'] ?? 0;
    } else {
      // Fallback to old structure if payers array is not present
      payerName = json['payer_name'] ?? 'Unknown';
      payerId = json['payer_id'] ?? 0;
    }
    
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
    
    return GroupExpense(
      id: json['id'],
      title: json['title'] ?? '',
      amount: (json['total_amount'] ?? json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      date: parseDate(json['date']),
      payerName: payerName,
      payerId: payerId,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'payer_name': payerName,
      'payer_id': payerId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Validation method for data integrity
  bool isValid() {
    return id > 0 &&
           title.isNotEmpty &&
           amount >= 0 &&
           currency.isNotEmpty &&
           payerName.isNotEmpty &&
           payerId > 0 &&
           date.isBefore(DateTime.now().add(Duration(days: 1))) &&
           createdAt.isBefore(DateTime.now().add(Duration(minutes: 1)));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupExpense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupExpense(id: $id, title: $title, amount: $amount, payerName: $payerName)';
  }
}

class GroupDetailModel {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;
  final List<GroupMember> members;
  final List<GroupExpense> expenses;
  final List<Settlement> settlements;
  final double userBalance;
  final String currency;
  final DateTime lastActivity;
  final bool canEdit;
  final bool canDelete;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupDetailModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.members,
    required this.expenses,
    required this.settlements,
    required this.userBalance,
    required this.currency,
    required this.lastActivity,
    required this.canEdit,
    required this.canDelete,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupDetailModel.fromJson(Map<String, dynamic> json) {
    return GroupDetailModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      members: (json['members'] as List<dynamic>?)
          ?.map((memberJson) => GroupMember.fromJson(memberJson, groupId: json['id']))
          .toList() ?? [],
      expenses: (json['expenses'] as List<dynamic>?)
          ?.map((expenseJson) => GroupExpense.fromJson(expenseJson))
          .toList() ?? [],
      settlements: (json['settlements'] as List<dynamic>?)
          ?.map((settlementJson) => Settlement.fromJson(settlementJson))
          .toList() ?? [],
      userBalance: (json['user_balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      lastActivity: DateTime.parse(json['last_activity'] ?? json['updated_at']),
      canEdit: json['can_edit'] ?? true, // Default to true for now
      canDelete: json['can_delete'] ?? true, // Default to true for now
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'members': members.map((member) => member.toJson()).toList(),
      'expenses': expenses.map((expense) => expense.toJson()).toList(),
      'settlements': settlements.map((settlement) => settlement.toJson()).toList(),
      'user_balance': userBalance,
      'currency': currency,
      'last_activity': lastActivity.toIso8601String(),
      'can_edit': canEdit,
      'can_delete': canDelete,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Validation methods for data integrity
  bool isValid() {
    return id > 0 &&
           name.isNotEmpty &&
           currency.isNotEmpty &&
           members.isNotEmpty &&
           members.every((member) => member.isValid()) &&
           expenses.every((expense) => expense.isValid()) &&
           settlements.every((settlement) => settlement.id > 0) &&
           hasValidTimestamps();
  }

  bool hasValidTimestamps() {
    final now = DateTime.now();
    return createdAt.isBefore(now) &&
           updatedAt.isBefore(now) &&
           lastActivity.isBefore(now.add(Duration(minutes: 1))) &&
           !createdAt.isAfter(updatedAt);
  }

  // Helper methods
  int get memberCount => members.length;
  
  int get expenseCount => expenses.length;
  
  bool get hasExpenses => expenses.isNotEmpty;
  
  bool get hasSettlements => settlements.isNotEmpty;
  
  bool get isSettledUp => settlements.isEmpty;
  
  GroupMember? get currentUser {
    try {
      return members.firstWhere((member) => member.isCurrentUser);
    } catch (e) {
      return null;
    }
  }

  // Get user's balance status for display
  String get balanceStatus {
    if (userBalance > 0) {
      return 'You are owed ${userBalance.toStringAsFixed(2)}$currency';
    } else if (userBalance < 0) {
      return 'You owe ${(-userBalance).toStringAsFixed(2)}$currency';
    } else {
      return 'You are settled up';
    }
  }

  // Get expenses sorted by date (newest first)
  List<GroupExpense> get sortedExpenses {
    final sorted = List<GroupExpense>.from(expenses);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  // Check if user can remove a specific member
  bool canRemoveMember(String memberId) {
    if (!canEdit) return false;
    
    // Check if member has any active settlements
    return !settlements.any((settlement) => 
        settlement.fromGroupMemberId.toString() == memberId || 
        settlement.toGroupMemberId.toString() == memberId);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupDetailModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupDetailModel(id: $id, name: $name, memberCount: $memberCount, expenseCount: $expenseCount)';
  }

  /// Create a copy of this model with updated fields
  GroupDetailModel copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    List<GroupMember>? members,
    List<GroupExpense>? expenses,
    List<Settlement>? settlements,
    double? userBalance,
    String? currency,
    DateTime? lastActivity,
    bool? canEdit,
    bool? canDelete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupDetailModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      settlements: settlements ?? this.settlements,
      userBalance: userBalance ?? this.userBalance,
      currency: currency ?? this.currency,
      lastActivity: lastActivity ?? this.lastActivity,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}