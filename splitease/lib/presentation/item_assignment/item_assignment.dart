import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';

import '../../core/app_export.dart';
import '../../models/receipt_mode_data.dart';
import '../../models/participant_amount.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
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
  
  // State management for assignment summary
  Map<String, double>? _previousIndividualTotals;
  Map<String, double>? _currentIndividualTotals;
  Map<String, double>? _equalSplitTotals;

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _quantityAssignments = [];

  // Group selection state
  List<Group> _availableGroups = [];
  String? _selectedGroupId;

  // Group members data (loaded from API)
  List<Map<String, dynamic>> _groupMembers = [];
  
  // Track new participants added during assignment
  List<Map<String, dynamic>> _newParticipants = [];

  // Currency for the selected group
  Currency _currency = Currency(
    code: 'USD',
    name: 'US Dollar',
    symbol: '\$',
    flag: 'USD',
    number: 840,
    decimalDigits: 2,
    namePlural: 'US Dollars',
    symbolOnLeft: true,
    decimalSeparator: '.',
    thousandsSeparator: ',',
    spaceBetweenAmountAndSymbol: false,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadGroupData(); // This is now async but we don't need to await it in initState
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

  Future<void> _loadGroupData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load groups from backend API
      final groups = await GroupService.getAllGroups();
      
      setState(() {
        _availableGroups = groups;
        _isLoading = false;
        
        // Pre-select the most recent group (first in sorted list)
        if (_availableGroups.isNotEmpty) {
          _selectedGroupId = _availableGroups.first.id.toString();
          // Set initial currency for the first group
          _currency = _availableGroups.first.currency;
          print('DEBUG: Initial currency set to: ${_currency.code}');
          // Load members for the initially selected group
          _updateGroupMembers(_selectedGroupId!); // Don't await here, let it run asynchronously
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _availableGroups = [];
        _selectedGroupId = null;
        _groupMembers = [];
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load groups: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _onGroupChanged(String groupId) {
    print('DEBUG: _onGroupChanged - groupId: $groupId');
    
    // Update selected group and members
    _selectedGroupId = groupId;
    
    // Update currency for the selected group
    final selectedGroup = _availableGroups.firstWhere(
      (group) => group.id.toString() == groupId,
      orElse: () => _availableGroups.first,
    );
    setState(() {
      _currency = selectedGroup.currency;
    });
    print('DEBUG: Currency updated to: ${_currency.code}');
    
    // Clear all existing assignments when group changes
    _clearAllAssignments();
    
    // Update group members (this will handle loading state and member fetching)
    _updateGroupMembers(groupId); // Let it run asynchronously
    
    // Force UI refresh to ensure all widgets reflect the new participant list
    // This ensures QuantityAssignmentWidget and AssignmentSummaryWidget update properly
    if (mounted) {
      setState(() {
        // State has been updated in _clearAllAssignments
        // _updateGroupMembers will update the state when it completes
      });
    }
  }

  void _updateGroupMembers(String groupId) async {
    print('DEBUG: _updateGroupMembers - groupId: $groupId');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch group members from the backend API
      final groupWithMembers = await GroupService.getGroupWithMembers(groupId);
      print('DEBUG: _updateGroupMembers - loaded group: ${groupWithMembers?.name}, members count: ${groupWithMembers?.members.length}');
      
      if (groupWithMembers != null) {
        // Convert Group members to the format expected by the existing code
        final newGroupMembers = groupWithMembers.members.map((member) => <String, dynamic>{
          'id': member.id.toString(),
          'name': member.nickname,
          'avatar': '', // GroupMember doesn't have avatar field, will use initials
        }).toList();

        // Update group members and maintain UI state consistency
        setState(() {
          _groupMembers = newGroupMembers;
          _isLoading = false;
          
          // Reset assignment totals to ensure clean state with new participants
          _previousIndividualTotals = null;
          _currentIndividualTotals = null;
          _equalSplitTotals = null;
          
          // Maintain expanded states but reset selection states that depend on members
          // Keep _expandedQuantityItemId and _expandedItemId as they are item-specific
          // Reset any member-specific selections if they exist
        });
        
        print('DEBUG: _updateGroupMembers - updated group members count: ${_groupMembers.length}');
        for (var member in _groupMembers) {
          print('DEBUG: _updateGroupMembers - member: ${member['name']} (ID: ${member['id']})');
        }
      } else {
        setState(() {
          _groupMembers = [];
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load group members'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _groupMembers = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load group members: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _clearAllAssignments() {
    setState(() {
      // Clear all item assignments
      for (var item in _items) {
        item['assignedMembers'] = <String>[];
        item['remainingQuantity'] = item['originalQuantity'];
        item['quantityAssignments'] = <Map<String, dynamic>>[];
      }
      
      // Clear quantity assignments
      _quantityAssignments.clear();
      
      // Clear assignment totals
      _previousIndividualTotals = null;
      _currentIndividualTotals = null;
      _equalSplitTotals = null;
      
      // Reset bulk selection state as member IDs may have changed
      _selectedItems.clear();
      
      // Keep UI expansion states as they are item-specific, not member-specific
      // _expandedQuantityItemId and _expandedItemId remain unchanged
    });
  }

  bool _hasExistingAssignments() {
    // Check if any items have assignments
    final hasItemAssignments = _items.any((item) {
      final assignedMembers = item['assignedMembers'] as List<String>? ?? [];
      return assignedMembers.isNotEmpty;
    });

    // Check if there are any quantity assignments
    final hasQuantityAssignments = _quantityAssignments.isNotEmpty;

    return hasItemAssignments || hasQuantityAssignments;
  }

  /// Validates that all assignment data is consistent with current member list
  void _validateAssignmentConsistency() {
    final currentMemberIds = _groupMembers.map((m) => m['id'].toString()).toSet();
    
    // Validate quantity assignments
    for (var assignment in _quantityAssignments) {
      final memberIds = assignment['memberIds'] as List<dynamic>? ?? [];
      for (var memberId in memberIds) {
        if (!currentMemberIds.contains(memberId.toString())) {
          print('WARNING: Assignment contains invalid member ID: $memberId');
        }
      }
    }
    
    // Validate item assignments
    for (var item in _items) {
      final assignedMembers = item['assignedMembers'] as List<String>? ?? [];
      for (var memberId in assignedMembers) {
        if (!currentMemberIds.contains(memberId)) {
          print('WARNING: Item assignment contains invalid member ID: $memberId');
        }
      }
    }
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
        
        // ALSO update assignedMembers to include all members from quantity assignments
        final allAssignedMemberIds = <String>{};
        for (var assign in currentAssignments) {
          final memberIds = assign['memberIds'] as List<dynamic>? ?? [];
          allAssignedMemberIds.addAll(memberIds.map((id) => id.toString()));
        }
        _items[itemIndex]['assignedMembers'] = allAssignedMemberIds.toList();
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
        
        // ALSO update assignedMembers to include all members from remaining quantity assignments
        final allAssignedMemberIds = <String>{};
        for (var assign in currentAssignments) {
          final memberIds = assign['memberIds'] as List<dynamic>? ?? [];
          allAssignedMemberIds.addAll(memberIds.map((id) => id.toString()));
        }
        _items[itemIndex]['assignedMembers'] = allAssignedMemberIds.toList();
      }
    });
  }

  void _toggleEqualSplit() {
    setState(() {
      if (_isEqualSplit) {
        // Currently equal split is ON, turning it OFF
        // Restore individual assignments from previously stored state
        // The AssignmentSummaryWidget will handle showing individual totals
        // based on _previousIndividualTotals
      } else {
        // Currently equal split is OFF, turning it ON
        // Store current individual totals before switching to equal split
        if (_currentIndividualTotals != null) {
          _previousIndividualTotals = Map<String, double>.from(_currentIndividualTotals!);
        }
        
        // Calculate and store equal split totals for reference
        final totalAmount = _items.fold(0.0, (sum, item) => sum + (item['total_price'] as double? ?? 0.0));
        final perMember = _groupMembers.isNotEmpty ? totalAmount / _groupMembers.length : 0.0;
        
        _equalSplitTotals = {};
        for (var member in _groupMembers) {
          _equalSplitTotals![member['id'].toString()] = perMember;
        }
      }
      
      _isEqualSplit = !_isEqualSplit;
    });
    HapticFeedback.lightImpact();
  }

  void _onIndividualTotalsChanged(Map<String, double> totals) {
    // Store the current individual totals
    _currentIndividualTotals = Map<String, double>.from(totals);
    
    // If we're not in equal split mode, also update previous individual totals
    // This ensures we preserve the state when toggling between modes
    if (!_isEqualSplit) {
      _previousIndividualTotals = Map<String, double>.from(totals);
    }
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

    try {
      // Calculate total amount and prepare receipt mode data
      final receiptData = _prepareReceiptModeData();
      
      // Validate receipt data
      final validationError = receiptData.validate();
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data validation error: $validationError')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Simulate processing
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.expenseCreation,
            arguments: {
              'receiptData': receiptData.toJson(),
              'mode': 'receipt',
            },
          );
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      // Handle any errors in data preparation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error preparing receipt data: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Prepares structured receipt mode data from current assignment state
  ReceiptModeData _prepareReceiptModeData() {
    // Calculate total amount - for equal split, always use total of all items
    // For individual assignments, use assigned items
    double totalAmount = 0.0;
    
    print('DEBUG: Calculating total - isEqualSplit: $_isEqualSplit, quantityAssignments: ${_quantityAssignments.length}, items: ${_items.length}');
    
    if (_isEqualSplit) {
      // Equal split: always use total of all items regardless of assignments
      for (var item in _items) {
        final itemPrice = item['total_price'] as double? ?? 0.0;
        print('DEBUG: Equal split - Item ${item['name']} has total_price: $itemPrice');
        totalAmount += itemPrice;
      }
      print('DEBUG: Equal split - Total from all items: $totalAmount');
    } else {
      // Individual assignments: use assigned items only
      if (_quantityAssignments.isNotEmpty) {
        // Use quantity assignment prices when available
        totalAmount = _quantityAssignments.fold(0.0, (sum, assignment) => 
            sum + (assignment['totalPrice'] as double? ?? 0.0));
        print('DEBUG: Individual assignments - Total from quantity assignments: $totalAmount');
      } else {
        // Fall back to item total prices for assigned items
        for (var item in _items) {
          final assignedMembers = item['assignedMembers'] as List<String>? ?? [];
          if (assignedMembers.isNotEmpty) {
            final itemPrice = item['total_price'] as double? ?? 0.0;
            print('DEBUG: Individual assignments - Item ${item['name']} has total_price: $itemPrice');
            totalAmount += itemPrice;
          }
        }
        print('DEBUG: Individual assignments - Total from assigned items: $totalAmount');
      }
    }

    // Create participant amount pairs from assignment data
    List<ParticipantAmount> participantAmounts = [];
    
    print('DEBUG: _prepareReceiptModeData - isEqualSplit: $_isEqualSplit, totalAmount: $totalAmount, groupMembers: ${_groupMembers.length}');
    
    if (_isEqualSplit) {
      // Equal split: divide total equally among all members
      final perMemberAmount = _groupMembers.isNotEmpty ? totalAmount / _groupMembers.length : 0.0;
      
      print('DEBUG: Equal split - perMemberAmount: $perMemberAmount');
      
      for (var member in _groupMembers) {
        final memberName = member['name'] ?? '';
        print('DEBUG: Adding equal amount for $memberName: $perMemberAmount');
        participantAmounts.add(ParticipantAmount(
          name: memberName,
          amount: perMemberAmount,
        ));
      }
    } else {
      // Individual assignments: calculate based on assigned items
      participantAmounts = _calculateIndividualParticipantAmounts();
    }

    // Transform items to use camelCase keys for validation
    List<Map<String, dynamic>> transformedItems = _items.map((item) {
      Map<String, dynamic> transformedItem = Map<String, dynamic>.from(item);
      // Convert total_price to totalPrice for validation
      if (transformedItem.containsKey('total_price')) {
        transformedItem['totalPrice'] = transformedItem['total_price'];
      }
      return transformedItem;
    }).toList();

    // Transform quantity assignments to individual participant entries for validation
    List<Map<String, dynamic>>? transformedQuantityAssignments;
    if (_quantityAssignments.isNotEmpty) {
      transformedQuantityAssignments = [];
      
      for (var assignment in _quantityAssignments) {
        final memberIds = assignment['memberIds'] as List<dynamic>? ?? [];
        final quantity = assignment['quantity'] as int? ?? 1;
        final totalPrice = assignment['totalPrice'] as double? ?? 0.0;
        final itemId = assignment['itemId'];
        
        // Create individual assignment entries for each participant
        for (var memberId in memberIds) {
          // Calculate individual quantity and price for shared assignments
          final individualQuantity = memberIds.length > 1 ? quantity : quantity;
          final individualPrice = totalPrice / memberIds.length;
          
          transformedQuantityAssignments.add(<String, dynamic>{
            'itemId': itemId,
            'participantId': memberId.toString(),
            'quantity': individualQuantity,
            'totalPrice': individualPrice,
            'assignmentId': assignment['assignmentId'],
            'isShared': memberIds.length > 1,
          });
        }
      }
    }

    // Get the selected group information
    final selectedGroup = _availableGroups.firstWhere(
      (group) => group.id.toString() == _selectedGroupId,
      orElse: () => _availableGroups.first,
    );

    print('DEBUG: _prepareReceiptModeData - selectedGroupId: $_selectedGroupId');
    print('DEBUG: _prepareReceiptModeData - selectedGroup: ${selectedGroup.name} (ID: ${selectedGroup.id})');
    print('DEBUG: _prepareReceiptModeData - groupMembers count: ${_groupMembers.length}');
    for (var member in _groupMembers) {
      print('DEBUG: _prepareReceiptModeData - group member: ${member['name']} (ID: ${member['id']})');
    }

    // Separate existing group members from new participants
    final existingGroupMembers = _groupMembers.where((member) => 
      !_newParticipants.any((newParticipant) => newParticipant['id'] == member['id'])
    ).toList();

    // Create and return structured receipt mode data
    return ReceiptModeData(
      total: totalAmount,
      participantAmounts: participantAmounts,
      mode: 'receipt',
      isEqualSplit: _isEqualSplit,
      items: transformedItems,
      groupMembers: existingGroupMembers,
      quantityAssignments: transformedQuantityAssignments,
      selectedGroupId: selectedGroup.id.toString(),
      selectedGroupName: selectedGroup.name,
      newParticipants: _newParticipants.isNotEmpty ? _newParticipants : null,
    );
  }

  /// Calculates participant amounts based on individual item assignments
  List<ParticipantAmount> _calculateIndividualParticipantAmounts() {
    // Initialize amounts for all members
    Map<String, double> memberAmounts = {};
    for (var member in _groupMembers) {
      memberAmounts[member['id'].toString()] = 0.0;
    }

    if (_quantityAssignments.isNotEmpty) {
      // Calculate from quantity assignments
      for (var assignment in _quantityAssignments) {
        final memberIds = assignment['memberIds'] as List<dynamic>? ?? [];
        final totalPrice = assignment['totalPrice'] as double? ?? 0.0;
        final quantity = assignment['quantity'] as int? ?? 1;
        
        if (memberIds.isNotEmpty) {
          final pricePerMember = totalPrice / memberIds.length;
          for (var memberId in memberIds) {
            final memberIdStr = memberId.toString();
            if (memberAmounts.containsKey(memberIdStr)) {
              memberAmounts[memberIdStr] = memberAmounts[memberIdStr]! + pricePerMember;
            }
          }
        }
      }
    } else {
      // Calculate from regular item assignments
      for (var item in _items) {
        final assignedMembers = item['assignedMembers'] as List<String>? ?? [];
        final itemPrice = item['total_price'] as double? ?? 0.0;
        
        if (assignedMembers.isNotEmpty) {
          final pricePerMember = itemPrice / assignedMembers.length;
          for (var memberId in assignedMembers) {
            if (memberAmounts.containsKey(memberId)) {
              memberAmounts[memberId] = memberAmounts[memberId]! + pricePerMember;
            }
          }
        }
      }
    }

    // Convert to ParticipantAmount objects
    List<ParticipantAmount> participantAmounts = [];
    for (var member in _groupMembers) {
      final memberId = member['id'].toString();
      final memberName = member['name'] ?? '';
      final amount = memberAmounts[memberId] ?? 0.0;
      
      participantAmounts.add(ParticipantAmount(
        name: memberName,
        amount: amount,
      ));
    }

    return participantAmounts;
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
                        // Generate a unique random ID that doesn't conflict with existing members
                        final existingIds = _groupMembers.map((m) => m['id'].toString()).toSet();
                        String newId;
                        do {
                          newId = DateTime.now().millisecondsSinceEpoch.remainder(1000000).toString();
                        } while (existingIds.contains(newId));
                        
                        final newParticipant = <String, dynamic>{
                          "id": newId,
                          "name": nameController.text.trim(),
                          "avatar": avatarUrl,
                          "isNewParticipant": true, // Mark as new participant
                        };

                        setState(() {
                          _groupMembers.add(newParticipant);
                          _newParticipants.add(newParticipant); // Track for later use
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
                        quantityAssignments: _quantityAssignments,
                        previousIndividualTotals: _previousIndividualTotals,
                        onIndividualTotalsChanged: _onIndividualTotalsChanged,
                        availableGroups: _availableGroups,
                        selectedGroupId: _selectedGroupId,
                        onGroupChanged: _onGroupChanged,
                        hasExistingAssignments: _hasExistingAssignments(),
                        isLoadingGroups: _isLoading,
                        currency: _currency),

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
                            currency: _currency,
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
                                currency: _currency,
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
