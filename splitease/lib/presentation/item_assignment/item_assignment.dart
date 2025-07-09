import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../receipt_ocr_review/widgets/progress_indicator_widget.dart';
import './widgets/assignment_instructions_widget.dart';
import './widgets/assignment_summary_widget.dart';
import './widgets/bulk_assignment_widget.dart';
import './widgets/enhanced_empty_state_widget.dart';
import './widgets/member_drop_zone_widget.dart';
import './widgets/member_search_widget.dart';
import './widgets/quantity_assignment_widget.dart';

class ItemAssignment extends StatefulWidget {
  const ItemAssignment({super.key});

  @override
  State<ItemAssignment> createState() => _ItemAssignmentState();
}

class _ItemAssignmentState extends State<ItemAssignment>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final Set<int> _selectedItems = {};

  bool _isLoading = false;
  bool _isEqualSplit = false;
  bool _isBulkMode = false;
  bool _isDragMode = false;
  bool _showInstructions = true;
  int _expandedItemId = -1;
  int _expandedQuantityItemId = -1;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _quantityAssignments = [];

  // Mock group members data
  List<Map<String, dynamic>> _groupMembers = [
    {
      "id": 1,
      "name": "You",
      "avatar":
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80"
    },
    {
      "id": 2,
      "name": "Sarah",
      "avatar":
          "https://images.unsplash.com/photo-1494790108755-2616b612b1e9?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80"
    },
    {
      "id": 3,
      "name": "Mike",
      "avatar":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80"
    },
    {
      "id": 4,
      "name": "Emma",
      "avatar":
          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80"
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadData() {
    // Get data from previous screen (OCR results)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments
          as List<Map<String, dynamic>>?;
      if (args != null) {
        setState(() {
          _items = args.map((item) {
            final updatedItem = Map<String, dynamic>.from(item);
            updatedItem['quantity'] = 1;
            updatedItem['assignedMembers'] = <String>[];
            // Add quantity assignment support
            updatedItem['originalQuantity'] = item['quantity'] ?? 1;
            updatedItem['remainingQuantity'] = item['quantity'] ?? 1;
            updatedItem['quantityAssignments'] = <Map<String, dynamic>>[];
            return updatedItem;
          }).toList();
        });
      }
    });
  }

  void _onQuantityAssigned(Map<String, dynamic> assignment) {
    setState(() {
      _quantityAssignments.add(assignment);

      // Update the item's remaining quantity
      final itemIndex =
          _items.indexWhere((item) => item['id'] == assignment['itemId']);
      if (itemIndex != -1) {
        final item = _items[itemIndex];
        final currentAssignments =
            List<Map<String, dynamic>>.from(item['quantityAssignments'] ?? []);
        currentAssignments.add(assignment);

        final totalAssignedQuantity = currentAssignments.fold<int>(
            0, (sum, assign) => sum + (assign['quantity'] as int));

        _items[itemIndex]['quantityAssignments'] = currentAssignments;
        _items[itemIndex]['remainingQuantity'] =
            (_items[itemIndex]['originalQuantity'] as int) -
                totalAssignedQuantity;
      }
    });
  }

  void _onQuantityAssignmentRemoved(Map<String, dynamic> assignment) {
    setState(() {
      _quantityAssignments.removeWhere(
          (assign) => assign['assignmentId'] == assignment['assignmentId']);

      // Update the item's remaining quantity
      final itemIndex =
          _items.indexWhere((item) => item['id'] == assignment['itemId']);
      if (itemIndex != -1) {
        final item = _items[itemIndex];
        final currentAssignments =
            List<Map<String, dynamic>>.from(item['quantityAssignments'] ?? []);
        currentAssignments.removeWhere(
            (assign) => assign['assignmentId'] == assignment['assignmentId']);

        final totalAssignedQuantity = currentAssignments.fold<int>(
            0, (sum, assign) => sum + (assign['quantity'] as int));

        _items[itemIndex]['quantityAssignments'] = currentAssignments;
        _items[itemIndex]['remainingQuantity'] =
            (_items[itemIndex]['originalQuantity'] as int) -
                totalAssignedQuantity;
      }
    });
  }

  void _toggleEqualSplit() {
    setState(() {
      _isEqualSplit = !_isEqualSplit;
      if (_isEqualSplit) {
        // Clear all individual assignments
        for (var item in _items) {
          item['assignedMembers'] =
              _groupMembers.map((m) => m['id'].toString()).toList();
        }
      }
    });
    HapticFeedback.lightImpact();
  }

  void _toggleBulkMode() {
    setState(() {
      _isBulkMode = !_isBulkMode;
      if (!_isBulkMode) {
        _selectedItems.clear();
      }
      _isDragMode = false;
    });
    HapticFeedback.selectionClick();
  }

  void _toggleDragMode() {
    setState(() {
      _isDragMode = !_isDragMode;
      if (_isDragMode) {
        _isBulkMode = false;
        _selectedItems.clear();
        _expandedItemId = -1;
      }
    });
    HapticFeedback.selectionClick();
  }

  void _toggleItemSelection(int itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _onAssignmentChanged(Map<String, dynamic> updatedItem) {
    setState(() {
      final index =
          _items.indexWhere((item) => item['id'] == updatedItem['id']);
      if (index != -1) {
        _items[index] = updatedItem;
      }
    });
  }

  void _onBulkAssignmentChanged(List<Map<String, dynamic>> updatedItems) {
    setState(() {
      for (var updatedItem in updatedItems) {
        final index =
            _items.indexWhere((item) => item['id'] == updatedItem['id']);
        if (index != -1) {
          _items[index] = updatedItem;
        }
      }
      _selectedItems.clear();
      _isBulkMode = false;
    });
  }

  void _onMemberSelected(String memberId) {
    // Find items that are currently expanded and assign them to the selected member
    if (_expandedItemId != -1) {
      final item = _items.firstWhere((item) => item['id'] == _expandedItemId);
      final assignedMembers = List<String>.from(item['assignedMembers'] ?? []);

      if (!assignedMembers.contains(memberId)) {
        assignedMembers.add(memberId);
        final updatedItem = Map<String, dynamic>.from(item);
        updatedItem['assignedMembers'] = assignedMembers;
        _onAssignmentChanged(updatedItem);
      }
    }
  }

  void _onItemDroppedToMember(
      Map<String, dynamic> member, Map<String, dynamic> item) {
    final memberId = member['id'].toString();
    final assignedMembers = List<String>.from(item['assignedMembers'] ?? []);

    if (!assignedMembers.contains(memberId)) {
      assignedMembers.add(memberId);
      final updatedItem = Map<String, dynamic>.from(item);
      updatedItem['assignedMembers'] = assignedMembers;
      _onAssignmentChanged(updatedItem);
    }
  }

  Map<String, List<Map<String, dynamic>>> _getAssignmentsByMember() {
    Map<String, List<Map<String, dynamic>>> assignments = {};

    // Initialize all members
    for (var member in _groupMembers) {
      assignments[member['id'].toString()] = [];
    }

    // Group items by assigned members
    for (var item in _items) {
      final assignedMembers = item['assignedMembers'] as List<String>? ?? [];
      for (var memberId in assignedMembers) {
        if (assignments.containsKey(memberId)) {
          assignments[memberId]!.add(item);
        }
      }
    }

    return assignments;
  }

  void _showBulkAssignmentBottomSheet() {
    final selectedItemsData =
        _items.where((item) => _selectedItems.contains(item['id'])).toList();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BulkAssignmentWidget(
            selectedItems: selectedItemsData,
            members: _groupMembers,
            onBulkAssignmentChanged: _onBulkAssignmentChanged,
            onClose: () => Navigator.pop(context)));
  }

  void _proceedToExpenseCreation() {
    // Check if all items are assigned (unless equal split is enabled)
    if (!_isEqualSplit) {
      final unassignedItems = _items.where((item) {
        final assignedMembers = item['assignedMembers'] as List<String>? ?? [];
        return assignedMembers.isEmpty;
      }).toList();

      if (unassignedItems.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('${unassignedItems.length} items need to be assigned'),
            action: SnackBarAction(
                label: 'Review',
                onPressed: () {
                  // Scroll to first unassigned item
                  final firstUnassignedIndex = _items.indexWhere((item) {
                    final assignedMembers =
                        item['assignedMembers'] as List<String>? ?? [];
                    return assignedMembers.isEmpty;
                  });
                  if (firstUnassignedIndex != -1) {
                    setState(() {
                      _expandedItemId = _items[firstUnassignedIndex]['id'];
                    });
                    _scrollController.animateTo(firstUnassignedIndex * 200.0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut);
                  }
                })));
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate processing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushNamed(context, AppRoutes.expenseCreation, arguments: {
          'items': _items,
          'isEqualSplit': _isEqualSplit,
          'groupMembers': _groupMembers,
          'quantityAssignments': _quantityAssignments,
        });
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _addParticipant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddParticipantBottomSheet(),
    );
  }

  Widget _buildAddParticipantBottomSheet() {
    final TextEditingController nameController = TextEditingController();
    String avatarUrl =
        "https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1";

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Add New Participant',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Participant Name',
                hintText: 'Enter name',
              ),
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty) {
                        final newParticipant = {
                          "id": _groupMembers.length + 1,
                          "name": nameController.text.trim(),
                          "avatar": avatarUrl,
                        };

                        setState(() {
                          _groupMembers.add(newParticipant);
                        });

                        Navigator.pop(context);
                        HapticFeedback.lightImpact();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${nameController.text} added to the group'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text('Add Participant'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsByMember = _getAssignmentsByMember();

    // Show empty state if no items
    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.cardColor,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.lightTheme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Back',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    Text(
                      'Item Assignment',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 60), // Balance the row
                  ],
                ),
              ),
              // Empty state
              Expanded(
                child: EnhancedEmptyStateWidget(
                  title: 'No Items to Assign',
                  description:
                      'Start by capturing a receipt to see items that can be assigned to group members.',
                  actionText: 'Capture Receipt',
                  onActionPressed: () {
                    Navigator.pushNamed(
                        context, AppRoutes.cameraReceiptCapture);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
            child: Column(children: [
          // Header
          Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                  color: AppTheme.lightTheme.cardColor,
                  border: Border(
                      bottom: BorderSide(
                          color: AppTheme.lightTheme.dividerColor, width: 1))),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Back',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.secondary))),
                      Text('Item Assignment',
                          style: AppTheme.lightTheme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'bulk':
                              _toggleBulkMode();
                              break;
                            case 'drag':
                              _toggleDragMode();
                              break;
                            case 'instructions':
                              setState(() {
                                _showInstructions = true;
                              });
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'bulk',
                            child: Row(
                              children: [
                                Icon(Icons.select_all, size: 5.w),
                                SizedBox(width: 2.w),
                                Text(_isBulkMode
                                    ? 'Exit Bulk Mode'
                                    : 'Bulk Mode'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'drag',
                            child: Row(
                              children: [
                                Icon(Icons.drag_indicator, size: 5.w),
                                SizedBox(width: 2.w),
                                Text(_isDragMode
                                    ? 'Exit Drag Mode'
                                    : 'Drag Mode'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'instructions',
                            child: Row(
                              children: [
                                Icon(Icons.help_outline, size: 5.w),
                                SizedBox(width: 2.w),
                                const Text('Show Help'),
                              ],
                            ),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          color: AppTheme.lightTheme.colorScheme.secondary,
                        ),
                      ),
                    ]),
                ProgressIndicatorWidget(
                    currentStep: 2,
                    totalSteps: 3,
                    stepLabels: ['Capture', 'Review', 'Assign']),
              ])),

          // Mode indicators
          if (_isBulkMode || _isDragMode)
            Container(
              padding: EdgeInsets.all(4.w),
              color: _isBulkMode
                  ? AppTheme.lightTheme.colorScheme.secondaryContainer
                  : AppTheme.lightTheme.colorScheme.tertiaryContainer,
              child: Row(
                children: [
                  Icon(
                    _isBulkMode ? Icons.select_all : Icons.drag_indicator,
                    color: _isBulkMode
                        ? AppTheme.lightTheme.colorScheme.onSecondaryContainer
                        : AppTheme.lightTheme.colorScheme.onTertiaryContainer,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _isBulkMode
                          ? 'Bulk mode: ${_selectedItems.length} items selected'
                          : 'Drag mode: Long press items to drag them to members',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isBulkMode
                            ? AppTheme
                                .lightTheme.colorScheme.onSecondaryContainer
                            : AppTheme
                                .lightTheme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  if (_isBulkMode && _selectedItems.isNotEmpty)
                    ElevatedButton(
                      onPressed: _showBulkAssignmentBottomSheet,
                      child: const Text('Assign Selected'),
                    ),
                  if (_isBulkMode || _isDragMode)
                    TextButton(
                      onPressed:
                          _isBulkMode ? _toggleBulkMode : _toggleDragMode,
                      child: const Text('Done'),
                    ),
                ],
              ),
            ),

          // Instructions
          AssignmentInstructionsWidget(
            showInstructions: _showInstructions,
            onDismiss: () {
              setState(() {
                _showInstructions = false;
              });
            },
          ),

          // Main content
          Expanded(
              child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(4.w),
                  child: Column(children: [
                    // Assignment summary with add participant functionality
                    AssignmentSummaryWidget(
                        items: _items,
                        members: _groupMembers,
                        isEqualSplit: _isEqualSplit,
                        onToggleEqualSplit: _toggleEqualSplit,
                        onAddParticipant: _addParticipant,
                        quantityAssignments: _quantityAssignments),

                    SizedBox(height: 3.h),

                    // Quantity Assignment Section
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Quantity Assignment',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text('${_items.length} items',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.secondary)),
                        ]),

                    SizedBox(height: 1.h),

                    // Quantity assignment list
                    ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 2.h),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final isExpanded =
                              _expandedQuantityItemId == item['id'];

                          return QuantityAssignmentWidget(
                            item: item,
                            members: _groupMembers,
                            onQuantityAssigned: _onQuantityAssigned,
                            onAssignmentRemoved: _onQuantityAssignmentRemoved,
                            isExpanded: isExpanded,
                            onToggleExpanded: () {
                              setState(() {
                                _expandedQuantityItemId =
                                    isExpanded ? -1 : item['id'];
                              });
                            },
                          );
                        }),

                    SizedBox(height: 3.h),

                    // Search bar (only shown when not in drag mode)
                    if (!_isDragMode && !_isBulkMode && _expandedItemId != -1)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick member assignment:',
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          MemberSearchWidget(
                            members: _groupMembers,
                            onMemberSelected: _onMemberSelected,
                            hintText: 'Search members to assign...',
                          ),
                          SizedBox(height: 3.h),
                        ],
                      ),

                    // Drag mode: Member drop zones
                    if (_isDragMode)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drop items on members:',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 2.h,
                              crossAxisSpacing: 4.w,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: _groupMembers.length,
                            itemBuilder: (context, index) {
                              final member = _groupMembers[index];
                              final memberItems = assignmentsByMember[
                                      member['id'].toString()] ??
                                  [];
                              return MemberDropZoneWidget(
                                member: member,
                                assignedItems: memberItems,
                                onItemDropped: _onItemDroppedToMember,
                              );
                            },
                          ),
                          SizedBox(height: 4.h),
                        ],
                      ),
                  ]))),

          // Bottom action button
          Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                  color: AppTheme.lightTheme.cardColor,
                  border: Border(
                      top: BorderSide(
                          color: AppTheme.lightTheme.dividerColor, width: 1))),
              child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: _isLoading ? null : _proceedToExpenseCreation,
                      style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h)),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme
                                          .lightTheme.colorScheme.onPrimary)))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Text('Create Expense',
                                      style: AppTheme
                                          .lightTheme.textTheme.titleMedium
                                          ?.copyWith(
                                              color: AppTheme.lightTheme
                                                  .colorScheme.onPrimary,
                                              fontWeight: FontWeight.w600)),
                                  SizedBox(width: 2.w),
                                  Icon(Icons.arrow_forward,
                                      color: AppTheme
                                          .lightTheme.colorScheme.onPrimary),
                                ])))),
        ])));
  }
}
