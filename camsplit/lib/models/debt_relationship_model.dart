/// Model representing a debt relationship between two group members
/// 
/// This model tracks who owes money to whom within a group context.
class DebtRelationshipModel {
  final int id;
  final int groupId;
  final int debtorId; // Member who owes money
  final int creditorId; // Member who is owed money
  final double amount;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  DebtRelationshipModel({
    required this.id,
    required this.groupId,
    required this.debtorId,
    required this.creditorId,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DebtRelationshipModel.fromJson(Map<String, dynamic> json) {
    return DebtRelationshipModel(
      id: json['id'] ?? 0,
      groupId: json['group_id'] ?? 0,
      debtorId: json['debtor_id'] ?? 0,
      creditorId: json['creditor_id'] ?? 0,
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'debtor_id': debtorId,
      'creditor_id': creditorId,
      'amount': amount,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool isValid() {
    return id > 0 &&
           groupId > 0 &&
           debtorId > 0 &&
           creditorId > 0 &&
           debtorId != creditorId &&
           amount > 0 &&
           currency.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebtRelationshipModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DebtRelationshipModel(id: $id, debtorId: $debtorId, creditorId: $creditorId, amount: $amount)';
  }
}