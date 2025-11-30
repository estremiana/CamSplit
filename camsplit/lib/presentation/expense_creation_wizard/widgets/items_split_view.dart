import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../models/group_member.dart';
import '../models/receipt_item.dart';
import 'receipt_item_card.dart';
import 'items_summary_widget.dart';
import 'gradient_fade_overlay.dart';
import 'split_text_styles.dart';
import 'split_widget_constants.dart';
import 'split_callbacks.dart';

class ItemsSplitView extends StatelessWidget {
  final List<ReceiptItem> items;
  final List<GroupMember> groupMembers;
  final bool isEditingItems;
  final String? expandedItemId;
  final double bottomButtonHeight;
  final double gradientHeight;
  final ItemToggleCallback onToggleExpand;
  final QuickToggleCallback onQuickToggle;
  final ClearAssignmentsCallback onClearAssignments;
  final Function(ReceiptItem) onShowAdvanced; // Keep as Function since it passes ReceiptItem
  final ItemNameChangedCallback onItemNameChanged;
  final ItemQuantityChangedCallback onItemQuantityChanged;
  final ItemUnitPriceChangedCallback onItemUnitPriceChanged;
  final ItemDeleteCallback onItemDelete;
  final Function(String itemId)? onSelectAll; // Callback to select/deselect all members for an item
  final Map<String, double> memberTotals;
  final double unassignedAmount;

  const ItemsSplitView({
    Key? key,
    required this.items,
    required this.groupMembers,
    required this.isEditingItems,
    required this.expandedItemId,
    required this.bottomButtonHeight,
    required this.gradientHeight,
    required this.onToggleExpand,
    required this.onQuickToggle,
    required this.onClearAssignments,
    required this.onShowAdvanced,
    required this.onItemNameChanged,
    required this.onItemQuantityChanged,
    required this.onItemUnitPriceChanged,
    required this.onItemDelete,
    this.onSelectAll,
    required this.memberTotals,
    required this.unassignedAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items found. Please scan a receipt or add items manually.',
          style: SplitTextStyles.bodySecondary(),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(
            left: SplitWidgetConstants.spacingLarge.w,
            right: SplitWidgetConstants.spacingLarge.w,
            bottom: bottomButtonHeight, // Stop scrolling at top of button
          ),
          child: Column(
            children: [
              ...items.map((item) => ReceiptItemCard(
                    item: item,
                    isExpanded: expandedItemId == item.id,
                    isEditing: isEditingItems,
                    groupMembers: groupMembers,
                    onToggleExpand: onToggleExpand,
                    onQuickToggle: (memberId) => onQuickToggle(item.id, memberId),
                    onClearAssignments: () => onClearAssignments(item.id),
                    onShowAdvanced: () => onShowAdvanced(item),
                    onNameChanged: (name) => onItemNameChanged(item.id, name),
                    onQuantityChanged: (qty) => onItemQuantityChanged(item.id, qty),
                    onUnitPriceChanged: (price) => onItemUnitPriceChanged(item.id, price),
                    onDelete: () => onItemDelete(item.id),
                    onSelectAll: onSelectAll != null ? () => onSelectAll!(item.id) : null,
                  )),
              if (!isEditingItems) ...[
                ItemsSummaryWidget(
                  groupMembers: groupMembers,
                  memberTotals: memberTotals,
                  unassignedAmount: unassignedAmount,
                ),
                SizedBox(height: 4.h), // Extra spacing so summary appears above button
              ],
            ],
          ),
        ),
        // Gradient fade overlay at bottom
        GradientFadeOverlay.white(height: gradientHeight),
      ],
    );
  }
}

