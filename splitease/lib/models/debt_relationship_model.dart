class DebtRelationship {
  final int debtorId;
  final String debtorName;
  final int creditorId;
  final String creditorName;
  final double amount;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  DebtRelationship({
    required this.debtorId,
    required this.debtorName,
    required this.creditorId,
    required this.creditorName,
    required this.amount,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DebtRelationship.fromJson(Map<String, dynamic> json) {
    return DebtRelationship(
      debtorId: json['debtor_id'],
      debtorName: json['debtor_name'] ?? '',
      creditorId: json['creditor_id'],
      creditorName: json['creditor_name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'debtor_id': debtorId,
      'debtor_name': debtorName,
      'creditor_id': creditorId,
      'creditor_name': creditorName,
      'amount': amount,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Validation methods for data integrity
  bool isValid() {
    return debtorId > 0 &&
           creditorId > 0 &&
           debtorId != creditorId &&
           debtorName.isNotEmpty &&
           creditorName.isNotEmpty &&
           amount > 0 &&
           currency.isNotEmpty &&
           hasValidTimestamps();
  }

  bool hasValidTimestamps() {
    final now = DateTime.now();
    return createdAt.isBefore(now) &&
           updatedAt.isBefore(now) &&
           !createdAt.isAfter(updatedAt);
  }

  // Helper methods for display
  String get formattedAmount => '${amount.toStringAsFixed(2)}$currency';
  
  String get displayText => '$debtorName owes $formattedAmount to $creditorName';
  
  // Check if current user is involved in this debt relationship
  bool involvesUser(int userId) {
    return debtorId == userId || creditorId == userId;
  }

  // Check if current user is the debtor
  bool isUserDebtor(int userId) {
    return debtorId == userId;
  }

  // Check if current user is the creditor
  bool isUserCreditor(int userId) {
    return creditorId == userId;
  }

  // Get the other person's name in the relationship from user's perspective
  String getOtherPersonName(int userId) {
    if (debtorId == userId) {
      return creditorName;
    } else if (creditorId == userId) {
      return debtorName;
    } else {
      return '';
    }
  }

  // Get debt description from user's perspective
  String getUserPerspectiveText(int userId) {
    if (debtorId == userId) {
      return 'You owe $formattedAmount to $creditorName';
    } else if (creditorId == userId) {
      return '$debtorName owes you $formattedAmount';
    } else {
      return displayText;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebtRelationship &&
           other.debtorId == debtorId &&
           other.creditorId == creditorId &&
           other.amount == amount;
  }

  @override
  int get hashCode => Object.hash(debtorId, creditorId, amount);

  @override
  String toString() {
    return 'DebtRelationship(debtorId: $debtorId, creditorId: $creditorId, amount: $amount, currency: $currency)';
  }
}