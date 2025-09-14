import 'user_model.dart';
import 'group.dart';
import 'expense.dart';

class DashboardModel {
  final UserModel user;
  final List<Group> groups;
  final List<Expense> recentExpenses;
  final PaymentSummaryModel paymentSummary;

  DashboardModel({
    required this.user,
    required this.groups,
    required this.recentExpenses,
    required this.paymentSummary,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      user: UserModel.fromJson(json['user']),
      groups: (json['groups'] as List)
          .map((group) => Group.fromJson(group))
          .toList(),
      recentExpenses: (json['recent_expenses'] as List)
          .map((expense) => Expense.fromJson(expense))
          .toList(),
      paymentSummary: PaymentSummaryModel.fromJson(json['payment_summary']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'groups': groups.map((group) => group.toJson()).toList(),
      'recent_expenses': recentExpenses.map((expense) => expense.toJson()).toList(),
      'payment_summary': paymentSummary.toJson(),
    };
  }
}

class PaymentSummaryModel {
  final double totalToPay;
  final double totalToGetPaid;
  final double balance;

  PaymentSummaryModel({
    required this.totalToPay,
    required this.totalToGetPaid,
    required this.balance,
  });

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return PaymentSummaryModel(
      totalToPay: _parseDouble(json['total_to_pay']),
      totalToGetPaid: _parseDouble(json['total_to_get_paid']),
      balance: _parseDouble(json['balance']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'total_to_pay': totalToPay,
      'total_to_get_paid': totalToGetPaid,
      'balance': balance,
    };
  }

  // Helper getters for backward compatibility
  double get totalOwed => totalToGetPaid;
  double get totalOwing => totalToPay;
} 