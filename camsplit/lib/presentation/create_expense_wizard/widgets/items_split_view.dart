import 'package:flutter/material.dart';
import '../models/wizard_expense_data.dart';
import '../models/receipt_item.dart';
import '../../../models/group_member.dart';
import 'quick_split_panel.dart';
import 'advanced_split_modal.dart';
import 'split_summary.dart';

/// View for Items split mode - displays receipt items as expandable cards
/// Allows assigning items to group members
class ItemsSplitView extends StatefulWidget {
  final WizardExpenseData wizardData;
  final List<GroupMember> groupMembers;
  final Function(WizardExpenseData) onDataChanged;

  const ItemsSplitView({
    super.key,
    required this.wizardData,
    required this.groupMembers,
    required this.onDataChanged,
  });

  @override
  State<ItemsSplitView> createState() => _ItemsSplitViewState();
}

class _ItemsSplitViewState extends State<ItemsSplitView> {
  String? _expandedItemId;
  bool _isEditingItems = false;
  final Map<String, TextEditingController> _nameControllers = {};
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, TextEditingController> _unitPriceControllers = {};

  @override
  void dispose() {
    // Dispose all text controllers
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final controller in _unitPriceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Toggle item card expansion
  void _toggleItemExpansion(String itemId) {
    setState(() {
      _expandedItemId = _expandedItemId == itemId ? null : itemId;
    });
  }

  /// Toggle edit mode
  void _toggleEditMode() {
    setState(() {
      if (_isEditingItems) {
        // Exiting edit mode - recalculate expense total
        _exitEditMode();
      } else {
        // Entering edit mode - initialize controllers
        _enterEditMode();
      }
      _isEditingItems = !_isEditingItems;
    });
  }

  /// Enter edit mode - initialize text controllers
  void _enterEditMode() {
    // Clear existing controllers
    _nameControllers.clear();
    _quantityControllers.clear();
    _unitPriceControllers.clear();

    // Create controllers for each item
    for (final item in widget.wizardData.items) {
      _nameControllers[item.id] = TextEditingController(text: item.name);
      _quantityControllers[item.id] = TextEditingController(
        text: item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 2),
      );
      _unitPriceControllers[item.id] = TextEditingController(
        text: item.unitPrice.toStringAsFixed(2),
      );
    }

    // Collapse any expanded items
    _expandedItemId = null;
  }

  /// Exit edit mode - recalculate expense total
  void _exitEditMode() {
    // Apply all changes from controllers to items
    final updatedItems = <ReceiptItem>[];
    
    for (final item in widget.wizardData.items) {
      final name = _nameControllers[item.id]?.text ?? item.name;
      final quantity = double.tryParse(_quantityControllers[item.id]?.text ?? '') ?? item.quantity;
      final unitPrice = double.tryParse(_unitPriceControllers[item.id]?.text ?? '') ?? item.unitPrice;
      final price = quantity * unitPrice;

      updatedItems.add(item.copyWith(
        name: name,
        quantity: quantity,
        unitPrice: unitPrice,
        price: price,
      ));
    }

    // Calculate new expense total
    final newTotal = updatedItems.fold(0.0, (sum, item) => sum + item.price);

    // Update wizard data with new items and total
    widget.onDataChanged(widget.wizardData.copyWith(
      items: updatedItems,
      amount: newTotal,
    ));

    // Clear controllers
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final controller in _unitPriceControllers.values) {
      controller.dispose();
    }
    _nameControllers.clear();
    _quantityControllers.clear();
    _unitPriceControllers.clear();
  }

  /// Delete an item
  void _deleteItem(String itemId) {
    final updatedItems = widget.wizardData.items.where((item) => item.id != itemId).toList();
    widget.onDataChanged(widget.wizardData.copyWith(items: updatedItems));

    // Remove controllers for deleted item
    _nameControllers[itemId]?.dispose();
    _quantityControllers[itemId]?.dispose();
    _unitPriceControllers[itemId]?.dispose();
    _nameControllers.remove(itemId);
    _quantityControllers.remove(itemId);
    _unitPriceControllers.remove(itemId);
  }

  /// Add a new item
  void _addItem() {
    final newItem = ReceiptItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'New Item',
      quantity: 1.0,
      unitPrice: 0.0,
      price: 0.0,
    );

    final updatedItems = [...widget.wizardData.items, newItem];
    widget.onDataChanged(widget.wizardData.copyWith(items: updatedItems));

    // Create controllers for new item
    _nameControllers[newItem.id] = TextEditingController(text: newItem.name);
    _quantityControllers[newItem.id] = TextEditingController(text: '1');
    _unitPriceControllers[newItem.id] = TextEditingController(text: '0.00');
  }



  /// Handle member toggle in QuickSplit mode
  /// Calculates equal shares automatically
  void _handleMemberToggle(ReceiptItem item, String memberId) {
    final updatedItems = List<ReceiptItem>.from(widget.wizardData.items);
    final itemIndex = updatedItems.indexWhere((i) => i.id == item.id);
    
    if (itemIndex == -1) return;

    final currentItem = updatedItems[itemIndex];
    final newAssignments = Map<String, double>.from(currentItem.assignments);

    // Toggle member assignment
    if (newAssignments.containsKey(memberId) && newAssignments[memberId]! > 0) {
      // Remove member
      newAssignments.remove(memberId);
    } else {
      // Add member - will be recalculated below
      newAssignments[memberId] = 0.0;
    }

    // Calculate equal shares for all assigned members
    final assignedMemberCount = newAssignments.length;
    if (assignedMemberCount > 0) {
      final equalShare = currentItem.quantity / assignedMemberCount;
      for (final key in newAssignments.keys) {
        newAssignments[key] = equalShare;
      }
    }

    // Update the item with new assignments
    updatedItems[itemIndex] = currentItem.copyWith(
      assignments: newAssignments,
    );

    // Update wizard data
    widget.onDataChanged(widget.wizardData.copyWith(items: updatedItems));
  }

  /// Handle reset of custom assignments
  void _handleReset(ReceiptItem item) {
    final updatedItems = List<ReceiptItem>.from(widget.wizardData.items);
    final itemIndex = updatedItems.indexWhere((i) => i.id == item.id);
    
    if (itemIndex == -1) return;

    // Clear all assignments and reset custom split flag
    updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
      assignments: {},
      isCustomSplit: false,
    );

    // Update wizard data
    widget.onDataChanged(widget.wizardData.copyWith(items: updatedItems));
  }

  /// Open advanced split modal
  void _openAdvancedModal(ReceiptItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedSplitModal(
        item: item,
        groupMembers: widget.groupMembers,
        onAssignmentCreated: (newAssignments) {
          _handleAdvancedAssignment(item, newAssignments);
        },
      ),
    );
  }

  /// Handle advanced assignment creation
  void _handleAdvancedAssignment(ReceiptItem item, Map<String, double> newAssignments) {
    final updatedItems = List<ReceiptItem>.from(widget.wizardData.items);
    final itemIndex = updatedItems.indexWhere((i) => i.id == item.id);
    
    if (itemIndex == -1) return;

    // Update the item with new assignments and set custom split flag
    updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
      assignments: newAssignments,
      isCustomSplit: true,
    );

    // Update wizard data
    widget.onDataChanged(widget.wizardData.copyWith(items: updatedItems));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Check if items exist
    if (widget.wizardData.items.isEmpty) {
      return _buildNoItemsMessage(context);
    }

    return Column(
      children: [
        // Edit/Done button header with animation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _toggleEditMode,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return RotationTransition(
                      turns: animation,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    _isEditingItems ? Icons.check : Icons.edit,
                    key: ValueKey<bool>(_isEditingItems),
                  ),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _isEditingItems ? 'Done' : 'Edit',
                    key: ValueKey<bool>(_isEditingItems),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: widget.wizardData.items.length + (_isEditingItems ? 1 : 1), // +1 for summary or add button
            itemBuilder: (context, index) {
              // Show "Add Item" button at the end in edit mode
              if (_isEditingItems && index == widget.wizardData.items.length) {
                return _buildAddItemButton(context);
              }

              // Show summary at the end in normal mode
              if (!_isEditingItems && index == widget.wizardData.items.length) {
                return SplitSummary(
                  wizardData: widget.wizardData,
                  groupMembers: widget.groupMembers,
                );
              }

              final item = widget.wizardData.items[index];
              final isExpanded = _expandedItemId == item.id;

              if (_isEditingItems) {
                return _buildEditableItemCard(context, item);
              } else {
                return _buildItemCard(context, item, isExpanded);
              }
            },
          ),
        ),
      ],
    );
  }

  /// Build a single item card
  Widget _buildItemCard(BuildContext context, ReceiptItem item, bool isExpanded) {
    final theme = Theme.of(context);
    final assignedCount = item.getAssignedCount();
    final isFullyAssigned = item.isFullyAssigned();

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      color: isFullyAssigned 
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: () => _toggleItemExpansion(item.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item header
              Row(
                children: [
                  // Item name
                  Expanded(
                    child: Text(
                      item.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Fully assigned indicator with animation
                  AnimatedScale(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    scale: isFullyAssigned ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  
                  // Custom split lock indicator
                  if (item.isCustomSplit)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Custom Split',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Item details row
              Row(
                children: [
                  // Quantity
                  Text(
                    'Qty: ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Unit price
                  Text(
                    'Unit: \$${item.unitPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Total price
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Assignment status
              Row(
                children: [
                  Icon(
                    isFullyAssigned ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: isFullyAssigned 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${assignedCount.toStringAsFixed(assignedCount.truncateToDouble() == assignedCount ? 0 : 1)}/${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} assigned',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isFullyAssigned 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isFullyAssigned ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),

              // Expanded content - QuickSplit panel with animation
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: isExpanded
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          QuickSplitPanel(
                            item: item,
                            groupMembers: widget.groupMembers,
                            onMemberToggle: (memberId) => _handleMemberToggle(item, memberId),
                            onReset: () => _handleReset(item),
                            onAdvancedSplit: () => _openAdvancedModal(item),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build editable item card for edit mode
  Widget _buildEditableItemCard(BuildContext context, ReceiptItem item) {
    final theme = Theme.of(context);
    final quantity = double.tryParse(_quantityControllers[item.id]?.text ?? '1') ?? 1.0;
    final unitPrice = double.tryParse(_unitPriceControllers[item.id]?.text ?? '0') ?? 0.0;
    final calculatedTotal = quantity * unitPrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item name input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameControllers[item.id],
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                IconButton(
                  onPressed: () => _deleteItem(item.id),
                  icon: const Icon(Icons.delete),
                  color: theme.colorScheme.error,
                  tooltip: 'Delete item',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quantity and unit price inputs
            Row(
              children: [
                // Quantity input
                Expanded(
                  child: TextField(
                    controller: _quantityControllers[item.id],
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}), // Trigger rebuild to update total
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Unit price input
                Expanded(
                  child: TextField(
                    controller: _unitPriceControllers[item.id],
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}), // Trigger rebuild to update total
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Calculated total
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '\$${calculatedTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build "Add Item" button
  Widget _buildAddItemButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: OutlinedButton.icon(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
      ),
    );
  }

  /// Build message when no items are available
  Widget _buildNoItemsMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Items Available',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Scan a receipt on the first page to use Items split mode',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
