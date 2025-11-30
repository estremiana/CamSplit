/// Type-safe callback definitions for split-related widgets
/// 
/// Using typedefs instead of Function types provides:
/// - Better IDE autocomplete
/// - Clearer documentation
/// - Type safety
/// - Easier refactoring

/// Callback for toggling member selection
typedef MemberToggleCallback = void Function(String memberId);

/// Callback for toggling item expansion
typedef ItemToggleCallback = void Function(String itemId);

/// Callback for quick toggle of member assignment to item
typedef QuickToggleCallback = void Function(String itemId, String memberId);

/// Callback for clearing item assignments
typedef ClearAssignmentsCallback = void Function(String itemId);

/// Callback for showing advanced assignment modal
typedef ShowAdvancedCallback = void Function(String itemId);

/// Callback for item name changes
typedef ItemNameChangedCallback = void Function(String itemId, String name);

/// Callback for item quantity changes
typedef ItemQuantityChangedCallback = void Function(String itemId, double quantity);

/// Callback for item unit price changes
typedef ItemUnitPriceChangedCallback = void Function(String itemId, double unitPrice);

/// Callback for deleting an item
typedef ItemDeleteCallback = void Function(String itemId);

/// Callback for manual split value changes
typedef ManualValueChangedCallback = void Function(String memberId, String value);

/// Callback for assigning quantity to members
typedef AssignmentCallback = void Function(List<String> memberIds, double quantity);

/// Callback for removing an assignment
typedef RemoveAssignmentCallback = void Function(String memberId);

