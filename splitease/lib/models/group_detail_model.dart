import 'group_member.dart';
import 'debt_relationship_model.dart';

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
    return GroupExpense(
      id: json['id'],
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      date: DateTime.parse(json['date']),
      payerName: json['payer_name'] ?? '',
      payerId: json['payer_id'],
      createdAt: DateTime.parse(json['created_at']),
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
  final List<DebtRelationship> debts;
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
    required this.debts,
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
          ?.map((memberJson) => GroupMember.fromJson(memberJson))
          .toList() ?? [],
      expenses: (json['expenses'] as List<dynamic>?)
          ?.map((expenseJson) => GroupExpense.fromJson(expenseJson))
          .toList() ?? [],
      debts: (json['debts'] as List<dynamic>?)
          ?.map((debtJson) => DebtRelationship.fromJson(debtJson))
          .toList() ?? [],
      userBalance: (json['user_balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      lastActivity: DateTime.parse(json['last_activity']),
      canEdit: json['can_edit'] ?? false,
      canDelete: json['can_delete'] ?? false,
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
      'debts': debts.map((debt) => debt.toJson()).toList(),
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
           debts.every((debt) => debt.isValid()) &&
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
  
  bool get hasDebts => debts.isNotEmpty;
  
  bool get isSettledUp => debts.isEmpty;
  
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
    
    // Check if member has any outstanding debts
    return !debts.any((debt) => 
        debt.debtorId.toString() == memberId || 
        debt.creditorId.toString() == memberId);
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
}