import '../models/receipt_item.dart';
import 'split_callbacks.dart';

/// Groups all callbacks for ReceiptItemCard into a single model
/// 
/// This reduces parameter count and improves maintainability
class ItemCardCallbacks {
  final ItemToggleCallback onToggleExpand;
  final QuickToggleCallback onQuickToggle;
  final ClearAssignmentsCallback onClearAssignments;
  final ShowAdvancedCallback onShowAdvanced;
  final ItemNameChangedCallback onNameChanged;
  final ItemQuantityChangedCallback onQuantityChanged;
  final ItemUnitPriceChangedCallback onUnitPriceChanged;
  final ItemDeleteCallback onDelete;

  const ItemCardCallbacks({
    required this.onToggleExpand,
    required this.onQuickToggle,
    required this.onClearAssignments,
    required this.onShowAdvanced,
    required this.onNameChanged,
    required this.onQuantityChanged,
    required this.onUnitPriceChanged,
    required this.onDelete,
  });

  /// Creates callbacks that automatically bind to a specific item
  factory ItemCardCallbacks.forItem(
    ReceiptItem item,
    ItemToggleCallback onToggleExpand,
    QuickToggleCallback onQuickToggle,
    ClearAssignmentsCallback onClearAssignments,
    ShowAdvancedCallback onShowAdvanced,
    ItemNameChangedCallback onNameChanged,
    ItemQuantityChangedCallback onQuantityChanged,
    ItemUnitPriceChangedCallback onUnitPriceChanged,
    ItemDeleteCallback onDelete,
  ) {
    return ItemCardCallbacks(
      onToggleExpand: onToggleExpand,
      onQuickToggle: (itemId, memberId) => onQuickToggle(item.id, memberId),
      onClearAssignments: (itemId) => onClearAssignments(item.id),
      onShowAdvanced: (itemId) => onShowAdvanced(item.id),
      onNameChanged: (itemId, name) => onNameChanged(item.id, name),
      onQuantityChanged: (itemId, qty) => onQuantityChanged(item.id, qty),
      onUnitPriceChanged: (itemId, price) => onUnitPriceChanged(item.id, price),
      onDelete: (itemId) => onDelete(item.id),
    );
  }
}

