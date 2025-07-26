class ReceiptModeConfig {
  final bool isGroupEditable;
  final bool isTotalEditable;
  final bool isSplitTypeEditable;
  final bool areCustomAmountsEditable;
  final String defaultSplitType;

  const ReceiptModeConfig({
    required this.isGroupEditable,
    required this.isTotalEditable,
    required this.isSplitTypeEditable,
    required this.areCustomAmountsEditable,
    required this.defaultSplitType,
  });

  static const ReceiptModeConfig receiptMode = ReceiptModeConfig(
    isGroupEditable: false,
    isTotalEditable: false,
    isSplitTypeEditable: false,
    areCustomAmountsEditable: false,
    defaultSplitType: 'custom',
  );

  static const ReceiptModeConfig manualMode = ReceiptModeConfig(
    isGroupEditable: true,
    isTotalEditable: true,
    isSplitTypeEditable: true,
    areCustomAmountsEditable: true,
    defaultSplitType: 'equal',
  );

  factory ReceiptModeConfig.fromJson(Map<String, dynamic> json) {
    return ReceiptModeConfig(
      isGroupEditable: json['is_group_editable'] ?? true,
      isTotalEditable: json['is_total_editable'] ?? true,
      isSplitTypeEditable: json['is_split_type_editable'] ?? true,
      areCustomAmountsEditable: json['are_custom_amounts_editable'] ?? true,
      defaultSplitType: json['default_split_type'] ?? 'equal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_group_editable': isGroupEditable,
      'is_total_editable': isTotalEditable,
      'is_split_type_editable': isSplitTypeEditable,
      'are_custom_amounts_editable': areCustomAmountsEditable,
      'default_split_type': defaultSplitType,
    };
  }

  ReceiptModeConfig copyWith({
    bool? isGroupEditable,
    bool? isTotalEditable,
    bool? isSplitTypeEditable,
    bool? areCustomAmountsEditable,
    String? defaultSplitType,
  }) {
    return ReceiptModeConfig(
      isGroupEditable: isGroupEditable ?? this.isGroupEditable,
      isTotalEditable: isTotalEditable ?? this.isTotalEditable,
      isSplitTypeEditable: isSplitTypeEditable ?? this.isSplitTypeEditable,
      areCustomAmountsEditable: areCustomAmountsEditable ?? this.areCustomAmountsEditable,
      defaultSplitType: defaultSplitType ?? this.defaultSplitType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptModeConfig &&
        other.isGroupEditable == isGroupEditable &&
        other.isTotalEditable == isTotalEditable &&
        other.isSplitTypeEditable == isSplitTypeEditable &&
        other.areCustomAmountsEditable == areCustomAmountsEditable &&
        other.defaultSplitType == defaultSplitType;
  }

  @override
  int get hashCode {
    return isGroupEditable.hashCode ^
        isTotalEditable.hashCode ^
        isSplitTypeEditable.hashCode ^
        areCustomAmountsEditable.hashCode ^
        defaultSplitType.hashCode;
  }

  @override
  String toString() {
    return 'ReceiptModeConfig(isGroupEditable: $isGroupEditable, isTotalEditable: $isTotalEditable, isSplitTypeEditable: $isSplitTypeEditable, areCustomAmountsEditable: $areCustomAmountsEditable, defaultSplitType: $defaultSplitType)';
  }
}