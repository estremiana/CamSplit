/// Enum representing the different split types available in the expense wizard
enum SplitType {
  /// Equal split - divide expense equally among selected members
  equal,
  
  /// Percentage split - divide expense by percentage for each member
  percentage,
  
  /// Custom split - specify exact amounts for each member
  custom,
  
  /// Items split - assign receipt items to members
  items,
}

/// Extension to provide string representation of split types
extension SplitTypeExtension on SplitType {
  String get displayName {
    switch (this) {
      case SplitType.equal:
        return 'Equal';
      case SplitType.percentage:
        return '%';
      case SplitType.custom:
        return 'Custom';
      case SplitType.items:
        return 'Items';
    }
  }
  
  String get apiValue {
    switch (this) {
      case SplitType.equal:
        return 'equal';
      case SplitType.percentage:
        return 'percentage';
      case SplitType.custom:
        return 'custom';
      case SplitType.items:
        return 'items';
    }
  }
  
  static SplitType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'equal':
        return SplitType.equal;
      case 'percentage':
        return SplitType.percentage;
      case 'custom':
        return SplitType.custom;
      case 'items':
        return SplitType.items;
      default:
        return SplitType.equal;
    }
  }
}
