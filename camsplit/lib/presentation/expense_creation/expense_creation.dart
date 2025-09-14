import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/receipt_mode_data.dart';
import '../../models/receipt_mode_config.dart';
import '../../models/group.dart';
import '../../services/group_service.dart';
import '../../services/api_service.dart';
import '../../services/currency_migration_service.dart';
import '../../services/currency_service.dart';
import '../../services/user_stats_service.dart';
import '../camera_capture/expense_photo_capture.dart';
import './widgets/expense_details_widget.dart';
import './widgets/receipt_image_widget.dart';
import './widgets/split_options_widget.dart';
import 'package:currency_picker/currency_picker.dart';

enum ExpenseCreationContext {
  dashboard,      // Show group field
  ocrAssignment,  // Hide group field
  groupDetail,    // Hide group field
  expenseDetail,  // Hide group field
}

class ExpenseCreation extends StatefulWidget {
  final String mode; // 'manual' or 'receipt'
  final ReceiptModeData? receiptData; // New parameter for receipt mode
  const ExpenseCreation({super.key, this.mode = 'manual', this.receiptData});

  @override
  State<ExpenseCreation> createState() => _ExpenseCreationState();
}

class _ExpenseCreationState extends State<ExpenseCreation>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late String mode;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  Currency _currency = CamSplitCurrencyService.getDefaultCurrency();

  // State variables
  bool _isLoading = false;
  String _selectedGroup = ''; // Initialize as empty string
  String _selectedCategory = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();
  String _splitType = 'equal';
  double _totalAmount = 0.0;
  
  // Receipt mode state
  bool _isReceiptMode = false;
  ReceiptModeData? _receiptData;
  ReceiptModeConfig _receiptModeConfig = ReceiptModeConfig.manualMode;
  Map<String, double> _prefilledCustomAmounts = {};
  
  // Custom split amounts for manual mode
  Map<String, double> _customAmounts = {};
  
  // Member percentages for percentage split mode
  Map<String, double> _memberPercentages = {};
  
  // Selected members for equal split mode
  List<String> _selectedMembers = [];

  // Group members - populated from receipt data or user selection
  List<Map<String, dynamic>> _groupMembers = [];
  bool _isLoadingMembers = false;

  // Payer selection state
  String _selectedPayerId = '';
  bool _isLoadingPayers = false;

  // Real groups from GroupService
  List<Group> _realGroups = [];
  bool _isLoadingGroups = false;

  // Context detection and group field visibility
  bool _showGroupField = true;

  // Store groupId from arguments for later use after groups are loaded
  int? _pendingGroupId;

  // Get groups from real service
  List<String> get _groups {
    return _realGroups.map((group) => group.name).toList();
  }
  final List<String> _categories = [
    'Food & Dining',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Utilities',
    'Healthcare',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    mode = widget.mode;
    _totalController.addListener(_onTotalChanged);
    
    debugPrint('ExpenseCreation initState - mode: $mode');
    
    // Defer reading arguments to determine if we need to load groups
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _initializeFromArguments();
        // Initialize receipt mode after arguments are processed
        _initializeReceiptMode();
        
        // In receipt mode, we already have all data, no need to load groups
        if (_isReceiptMode && _receiptData != null) {
          debugPrint('Receipt mode: Skipping _loadGroups() since we have all data');
          _initializeFromReceiptData();
        } else {
          // Only load groups for manual mode
          debugPrint('Manual mode: Loading groups from backend');
          _loadGroups().then((_) {
            debugPrint('Groups loaded for manual mode');
          }).catchError((error) {
            debugPrint('Error loading groups: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load groups: $error'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () => _loadGroups(),
                  ),
                  duration: Duration(seconds: 5),
                ),
              );
            }
          });
        }
      } catch (e) {
        debugPrint('Error during initialization: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to initialize expense creation: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  /// Load groups from the backend
  Future<void> _loadGroups() async {
    debugPrint('Loading groups...');
    if (mounted) {
      setState(() {
        _isLoadingGroups = true;
      });
    }

    try {
      final groups = await GroupService.getAllGroups().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout loading groups');
        },
      );
      debugPrint('Groups loaded: ${groups.length}');
      for (var group in groups) {
        debugPrint('Group: ${group.name} (ID: ${group.id}), Members: ${group.members.length}');
      }
      
      if (mounted) {
        setState(() {
          _realGroups = groups;
          _isLoadingGroups = false;
          
          debugPrint('Groups loaded successfully. Available groups: ${groups.map((g) => g.name).toList()}');
          debugPrint('Current selected group: $_selectedGroup');
          
          // Handle empty groups scenario
          if (groups.isEmpty) {
            debugPrint('No groups available');
            _selectedGroup = '';
            _groupMembers = [];
            _selectedPayerId = '';
            // Show message to user about no groups
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No groups available. Please create a group first.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            });
          } else {
            // Handle group selection after groups are loaded
            if (_pendingGroupId != null) {
              // Try to find the specific group that was requested
              final requestedGroup = groups.firstWhere(
                (group) => group.id == _pendingGroupId,
                orElse: () => groups.first, // Fallback to first group if not found
              );
              _selectedGroup = requestedGroup.name;
              debugPrint('Selected requested group: $_selectedGroup (ID: ${requestedGroup.id})');
              // Load members for the selected group
              _loadGroupMembers(requestedGroup.id.toString());
              
              // Set currency to group's currency
              setState(() {
                _currency = requestedGroup.currency;
              });
              debugPrint('Currency set to requested group: ${requestedGroup.currency.code}');
              _pendingGroupId = null; // Clear the pending groupId
            } else if (_selectedGroup.isEmpty) {
              // Set default selected group if available and not already set
              _selectedGroup = groups.first.name;
              debugPrint('Setting default group: $_selectedGroup (ID: ${groups.first.id})');
              // Load members for the default group
              _loadGroupMembers(groups.first.id.toString());
              
              // Set currency to group's currency
              setState(() {
                _currency = groups.first.currency;
              });
              debugPrint('Currency set to group default: ${groups.first.currency.code}');
            } else {
              debugPrint('Selected group already set: $_selectedGroup');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading groups: $e');
      if (mounted) {
        setState(() {
          _realGroups = [];
          _selectedGroup = '';
          _groupMembers = [];
          _selectedPayerId = '';
          _isLoadingGroups = false;
        });
        // Enhanced error handling with retry option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load groups: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadGroups(),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Load group members from the backend
  Future<void> _loadGroupMembers(String groupId) async {
    debugPrint('Loading members for group ID: $groupId');
    
    // Check if we have groups loaded
    if (_realGroups.isEmpty) {
      debugPrint('No groups available, cannot load members');
      return;
    }
    
    // For expense creation, we always need fresh member data
    // The cached groups from getAllGroups() don't include members
    debugPrint('Making API call to get group with members');
    
    if (mounted) {
      setState(() {
        _isLoadingMembers = true;
        _isLoadingPayers = true;
      });
    }

    try {
      final group = await GroupService.getGroupWithMembers(groupId).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout loading group members');
        },
      );
      debugPrint('Group loaded from API: ${group?.name}, Members count: ${group?.members.length}');
      if (mounted && group != null) {
        // Handle empty group scenario
        if (group.members.isEmpty) {
          debugPrint('Warning: Group has no members');
          setState(() {
            _groupMembers = [];
            _selectedPayerId = '';
            _isLoadingMembers = false;
            _isLoadingPayers = false;
          });
          // Show warning to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This group has no members. Please add members to the group first.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Get current user ID from API service
        final currentUserId = await ApiService.instance.getUserId();
        debugPrint('Current user ID from API service: $currentUserId');
        
        setState(() {
          _groupMembers = group.members.map((member) {
            // Determine if this member is the current user by comparing user_id
            final isCurrentUser = member.userId != null && 
                                 currentUserId != null && 
                                 member.userId.toString() == currentUserId;
            
            debugPrint('Member: ${member.nickname}, user_id: ${member.userId}, isCurrentUser: $isCurrentUser');
            
            return {
              'id': member.id,
              'name': member.nickname,
              'avatar': '', // GroupMember doesn't have avatar, using empty string
              'initials': _getInitials(member.nickname), // Add initials for avatar fallback
              'email': member.email ?? '',
              'isCurrentUser': isCurrentUser,
            };
          }).toList();
          _isLoadingMembers = false;
          _isLoadingPayers = false;
          
          // Initialize custom amounts for all members
          _customAmounts = {};
          for (final member in _groupMembers) {
            _customAmounts[member['name']] = 0.0;
          }
        });
        debugPrint('Members loaded from API: ${_groupMembers.length}');
        
        // Initialize selected members for equal split
        if (_splitType == 'equal' && _selectedMembers.isEmpty) {
          _selectedMembers = _groupMembers.map((m) => m['name'].toString()).toList();
          debugPrint('Initialized equal split with all members: $_selectedMembers');
        }
        
        // Set default payer after loading members
        _setDefaultPayer();
      } else if (mounted) {
        setState(() {
          _groupMembers = [];
          _selectedPayerId = '';
          _isLoadingMembers = false;
          _isLoadingPayers = false;
        });
        debugPrint('No group found for ID: $groupId');
        // Show error message for missing group
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group not found. Please select a different group.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading members: $e');
      if (mounted) {
        setState(() {
          _groupMembers = [];
          _selectedPayerId = '';
          _isLoadingMembers = false;
          _isLoadingPayers = false;
        });
        // Enhanced error handling with retry option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load group members: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadGroupMembers(groupId),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Get initials from member name
  String _getInitials(String name) {
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    return '${nameParts[0].substring(0, 1)}${nameParts[1].substring(0, 1)}'.toUpperCase();
  }

  void _initializeReceiptMode() {
    debugPrint('Initializing receipt mode - current mode: $mode, widget.receiptData: ${widget.receiptData != null}');
    
    // Check if we're in receipt mode
    _isReceiptMode = mode == 'receipt' || widget.receiptData != null;
    
    debugPrint('Receipt mode initialized - isReceiptMode: $_isReceiptMode');
    
    if (_isReceiptMode) {
      // Set receipt mode configuration
      _receiptModeConfig = ReceiptModeConfig.receiptMode;
      
      // Initialize receipt data only if not already set from arguments
      if (widget.receiptData != null && _receiptData == null) {
        _receiptData = widget.receiptData;
        
        // Validate receipt data
        final validationError = _receiptData!.validate();
        if (validationError != null) {
          // Log error and fallback to manual mode
          debugPrint('Receipt mode validation error: $validationError');
          _fallbackToManualMode('Invalid receipt data: $validationError');
          return;
        }
        
        // Note: We'll initialize from receipt data after groups are loaded
        // to ensure proper group selection
      }
    } else {
      _receiptModeConfig = ReceiptModeConfig.manualMode;
    }
  }

  void _initializeFromReceiptData() {
    if (_receiptData == null) return;
    
    debugPrint('Initializing from receipt data...');
    debugPrint('Receipt data total: ${_receiptData!.total}');
    debugPrint('Receipt data selected group: ${_receiptData!.selectedGroupName}');
    debugPrint('Receipt data group members: ${_receiptData!.groupMembers.length}');
    
    setState(() {
      // Set total amount
      _totalAmount = _receiptData!.total;
      _totalController.text = _totalAmount.toStringAsFixed(2);
      
      // Set split type to custom for receipt mode
      _splitType = _receiptModeConfig.defaultSplitType;
      
      // Pre-fill custom amounts
      _prefilledCustomAmounts = {};
      debugPrint('Setting prefilled custom amounts from receipt data:');
      for (var participantAmount in _receiptData!.participantAmounts) {
        final name = participantAmount.name ?? 'Unknown';
        final amount = participantAmount.amount;
        _prefilledCustomAmounts[name] = amount;
        debugPrint('  - $name: $amount');
      }
      debugPrint('Final prefilled custom amounts: $_prefilledCustomAmounts');
      
      // Also populate _customAmounts for consistency
      _customAmounts = Map<String, double>.from(_prefilledCustomAmounts);
      debugPrint('Also populated _customAmounts: $_customAmounts');
      
      // Set selected group from receipt data
      if (_receiptData!.selectedGroupName != null) {
        final selectedGroupName = _receiptData!.selectedGroupName!;
        debugPrint('Receipt data selected group: $selectedGroupName');
        
        // In receipt mode, we trust the receipt data and don't need to validate against _realGroups
        _selectedGroup = selectedGroupName;
        debugPrint('Receipt mode: Using selected group from receipt data: $selectedGroupName');
      } else {
        debugPrint('No selected group in receipt data');
      }
      
      // Update group members from receipt data
      if (_receiptData!.groupMembers.isNotEmpty) {
        // Clear existing group members and use the ones from receipt data
        _groupMembers.clear();
        _groupMembers.addAll(_receiptData!.groupMembers);
      }
      
      // Add new participants from receipt data if any
      if (_receiptData!.newParticipants != null && _receiptData!.newParticipants!.isNotEmpty) {
        _groupMembers.addAll(_receiptData!.newParticipants!);
        debugPrint('Added ${_receiptData!.newParticipants!.length} new participants from receipt data');
      }
      
      // Set default payer after loading all members
      _setDefaultPayerInReceiptMode();
    });
  }

  void _fallbackToManualMode(String errorMessage) {
    setState(() {
      _isReceiptMode = false;
      _receiptModeConfig = ReceiptModeConfig.manualMode;
      _receiptData = null;
      _prefilledCustomAmounts = {};
      mode = 'manual';
    });
    
    // Show error to user
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to manual mode: $errorMessage'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  /// Detect navigation context to determine group field visibility
  ExpenseCreationContext _detectNavigationContext(Map<String, dynamic>? args) {
    if (args == null) return ExpenseCreationContext.dashboard;
    
    // OCR assignment flow - has receiptData
    if (args.containsKey('receiptData')) {
      return ExpenseCreationContext.ocrAssignment;
    }
    
    // Group detail or expense detail flow - has groupId
    if (args.containsKey('groupId')) {
      return ExpenseCreationContext.groupDetail;
    }
    
    // Default to dashboard context
    return ExpenseCreationContext.dashboard;
  }

  void _initializeFromArguments() {
    // Read arguments for receipt mode initialization and group context
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    debugPrint('Initializing from arguments: $args');
    
    // Detect navigation context and set group field visibility
    final navigationContext = _detectNavigationContext(args);
    setState(() {
      _showGroupField = navigationContext == ExpenseCreationContext.dashboard;
    });
    debugPrint('Navigation context: $navigationContext, Show group field: $_showGroupField');
    
    if (args != null) {
      // Check if mode is specified in arguments
      if (args['mode'] != null) {
        final argMode = args['mode'] as String;
        debugPrint('Mode from arguments: $argMode, current mode: $mode');
        if (argMode != mode) {
          setState(() {
            mode = argMode;
          });
          debugPrint('Updated mode to: $mode');
        }
      }
      
      if (!_isReceiptMode) {
        // Handle group context from group detail page
        if (args['groupId'] != null) {
          _pendingGroupId = args['groupId'] as int;
          debugPrint('Stored pending group ID: $_pendingGroupId');
          // Don't try to find the group yet - wait for groups to be loaded
        }
        
        // Handle backward compatibility for receipt mode via arguments
        if (args['receiptData'] != null) {
          try {
            final receiptDataJson = args['receiptData'] as Map<String, dynamic>;
            final receiptData = ReceiptModeData.fromJson(receiptDataJson);
            
            // Validate the data
            final validationError = receiptData.validate();
            if (validationError != null) {
              _fallbackToManualMode('Invalid receipt data from arguments: $validationError');
              return;
            }
            
            // Switch to receipt mode
            setState(() {
              _isReceiptMode = true;
              _receiptModeConfig = ReceiptModeConfig.receiptMode;
              _receiptData = receiptData;
              mode = 'receipt';
            });
            
            // Note: We'll initialize from receipt data after groups are loaded
            // to ensure proper group selection
          } catch (e) {
            _fallbackToManualMode('Failed to parse receipt data: $e');
          }
        }
        // Maintain backward compatibility with direct total argument
        else if (args['total'] != null && mode == 'receipt') {
          setState(() {
            _totalAmount = (args['total'] as num).toDouble();
            _totalController.text = _totalAmount.toStringAsFixed(2);
          });
        }
      } else if (!_isReceiptMode) {
        _calculateTotal();
        _totalController.text = '';
      }
    }
  }

  void _onTotalChanged() {
    setState(() {});
  }

  /// Handle payer selection changes with validation integration
  void _onPayerChanged(String payerId) {
    setState(() {
      _selectedPayerId = payerId;
    });
    
    // Don't trigger validation immediately to prevent premature validation errors
    // Validation will be triggered when the user tries to save the expense
  }

  /// Handle title field changes
  void _onTitleChanged(String title) {
    // No need to call setState as the controller handles the text changes
    // This callback is mainly for future extensibility if needed
  }

  /// Set default payer to current user with validation integration
  void _setDefaultPayer() {
    // Handle empty group members scenario
    if (_groupMembers.isEmpty) {
      debugPrint('No group members available, cannot set default payer');
      setState(() {
        _selectedPayerId = '';
      });
      
      // Don't trigger validation immediately to prevent premature validation errors
      return;
    }

    // Find current user in group members and set as default payer
    try {
      final currentUser = _groupMembers.firstWhere(
        (member) => member['isCurrentUser'] == true,
      );
      setState(() {
        _selectedPayerId = currentUser['id'].toString();
      });
      debugPrint('Default payer set to current user: ${currentUser['name']}');
      
      // Don't trigger validation immediately to prevent premature validation errors
    } catch (e) {
      // Fallback logic when current user is not found in group members
      debugPrint('Current user not found in group members, using fallback');
      if (_groupMembers.isNotEmpty) {
        setState(() {
          _selectedPayerId = _groupMembers.first['id'].toString();
        });
        debugPrint('Fallback payer set to: ${_groupMembers.first['name']}');
        
        // Don't trigger validation immediately to prevent premature validation errors
        
        // Show warning to user about fallback (only once)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You are not a member of this group. Defaulted to ${_groupMembers.first['name']} as payer.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        setState(() {
          _selectedPayerId = '';
        });
        debugPrint('No members available for fallback');
        
        // Don't trigger validation immediately to prevent premature validation errors
      }
    }
  }

  /// Set default payer in receipt mode using current user ID from API service
  Future<void> _setDefaultPayerInReceiptMode() async {
    // Handle empty group members scenario
    if (_groupMembers.isEmpty) {
      debugPrint('No group members available, cannot set default payer');
      setState(() {
        _selectedPayerId = '';
      });
      return;
    }

    try {
      // Get current user ID from API service
      final currentUserId = await ApiService.instance.getUserId();
      debugPrint('Current user ID from API service: $currentUserId');
      
      if (currentUserId != null) {
        // Find current user in group members by comparing user IDs
        final currentUser = _groupMembers.firstWhere(
          (member) => member['id'].toString() == currentUserId,
          orElse: () => <String, dynamic>{},
        );
        
        if (currentUser.isNotEmpty) {
          setState(() {
            _selectedPayerId = currentUser['id'].toString();
          });
          debugPrint('Default payer set to current user: ${currentUser['name']}');
        } else {
          // Fallback to first member if current user not found
          setState(() {
            _selectedPayerId = _groupMembers.first['id'].toString();
          });
          debugPrint('Current user not found in group members, fallback to: ${_groupMembers.first['name']}');
        }
      } else {
        // Fallback to first member if current user ID not available
        setState(() {
          _selectedPayerId = _groupMembers.first['id'].toString();
        });
        debugPrint('Current user ID not available, fallback to: ${_groupMembers.first['name']}');
      }
    } catch (e) {
      debugPrint('Error setting default payer in receipt mode: $e');
      // Fallback to first member on error
      if (_groupMembers.isNotEmpty) {
        setState(() {
          _selectedPayerId = _groupMembers.first['id'].toString();
        });
        debugPrint('Error fallback payer set to: ${_groupMembers.first['name']}');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    _totalController.removeListener(_onTotalChanged);
    _totalController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    double itemsTotal = 0.0; // No items to sum up
    _totalAmount = itemsTotal;
    if (mode == 'receipt') {
      _totalController.text = _totalAmount.toStringAsFixed(2);
    }
    setState(() {});
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense() async {
    // Comprehensive form validation - blocks submission if validation fails
    debugPrint('Starting expense save validation...');
    
    // First, trigger form validation to show all field errors
    if (_formKey.currentState != null) {
      _formKey.currentState!.validate();
    }
    
    // Perform comprehensive validation
    if (!_validateForm()) {
      debugPrint('Form validation failed - expense save blocked');
      // Additional user feedback for validation failure
      _showValidationError('Please fix the validation errors before saving the expense');
      return;
    }

    debugPrint('Form validation passed - proceeding with expense save');
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Additional validation for receipt mode
      if (_isReceiptMode && _receiptData != null) {
        final validationError = _receiptData!.validate();
        if (validationError != null) {
          throw Exception('Receipt data validation failed: $validationError');
        }
      }

      // Log successful validation details for debugging
      debugPrint('Expense validation successful:');
      debugPrint('- Group: $_selectedGroup');
      debugPrint('- Payer: $_selectedPayerId');
      debugPrint('- Total: ${_totalController.text}');
      debugPrint('- Category: $_selectedCategory');

      // Get the selected group ID
      final selectedGroupId = _isReceiptMode && _receiptData != null
          ? _receiptData!.selectedGroupId
          : _realGroups.firstWhere(
              (group) => group.name == _selectedGroup,
              orElse: () => throw Exception('Selected group not found'),
            ).id;

      // Prepare expense data for API
      final expenseData = {
        'title': _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Expense',
        'total_amount': double.parse(_totalController.text.replaceAll(',', '.')),
        'currency': _currency.code,
        'date': _selectedDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'category': _selectedCategory,
        'notes': _notesController.text,
        'group_id': int.tryParse(selectedGroupId.toString()) ?? selectedGroupId,
        'split_type': _splitType,
        'payers': [
          {
            'group_member_id': _selectedPayerId,
            'amount_paid': double.parse(_totalController.text.replaceAll(',', '.')),
            'payment_method': 'unknown',
          }
        ],
        'splits': _buildSplitsData(),
      };

      // Handle receipt image URL
      String? imageUrlToUse;
      
      debugPrint('Image handling - isReceiptMode: $_isReceiptMode, receiptData: ${_receiptData != null}');
      if (_receiptData != null) {
        debugPrint('Receipt data - imageUrl: ${_receiptData!.imageUrl}, imagePath: ${_receiptData!.imagePath}');
      }
      
      if (_isReceiptMode && _receiptData != null) {
        // Receipt mode: use existing URL or upload local image
        if (_receiptData!.imageUrl != null) {
          imageUrlToUse = _receiptData!.imageUrl;
          debugPrint('Using existing image URL from receipt mode: $imageUrlToUse');
        } else if (_receiptData!.imagePath != null) {
          // Upload local image to Cloudinary and get URL
          debugPrint('Uploading local image from receipt mode: ${_receiptData!.imagePath}');
          try {
            final imageFile = File(_receiptData!.imagePath!);
            imageUrlToUse = await _uploadImageToCloudinary(imageFile);
            debugPrint('Successfully uploaded image from receipt mode: $imageUrlToUse');
          } catch (e) {
            debugPrint('Failed to upload image from receipt mode: $e');
            // Continue without image URL - expense can still be created
          }
        }
      } else if (!_isReceiptMode && _receiptData != null && _receiptData!.imagePath != null) {
        // Manual mode: upload local image if available
        debugPrint('Uploading local image from manual mode: ${_receiptData!.imagePath}');
        try {
          final imageFile = File(_receiptData!.imagePath!);
          imageUrlToUse = await _uploadImageToCloudinary(imageFile);
          debugPrint('Successfully uploaded image from manual mode: $imageUrlToUse');
        } catch (e) {
          debugPrint('Failed to upload image from manual mode: $e');
          // Continue without image URL - expense can still be created
        }
      }
      
      // Add image URL to expense data if available
      if (imageUrlToUse != null) {
        expenseData['receipt_image_url'] = imageUrlToUse;
        debugPrint('Added receipt_image_url to expense data: $imageUrlToUse');
      } else {
        debugPrint('No image URL to add to expense data');
      }

      // Add items if in receipt mode with items
      if (_isReceiptMode && _receiptData?.items.isNotEmpty == true) {
        expenseData['items'] = _receiptData!.items.map((item) => {
          'name': item['name'] ?? item['description'] ?? 'Item',
          'unit_price': item['unit_price'] ?? item['unitPrice'] ?? 0.0,
          'max_quantity': item['quantity'] ?? item['max_quantity'] ?? 1,
          'category': item['category'] ?? 'Other',
          'description': item['description'] ?? '',
        }).toList();
      }

      debugPrint('Sending expense data to API: $expenseData');

      // Create new members in the group if any were added during assignment
      Map<String, int> newMemberIds = {};
      if (_isReceiptMode && _receiptData?.newParticipants != null && _receiptData!.newParticipants!.isNotEmpty) {
        newMemberIds = await _createNewMembersInGroup(selectedGroupId.toString());
      }

      // Update expense data with new member IDs if any were created
      if (newMemberIds.isNotEmpty) {
        final splits = expenseData['splits'] as List<Map<String, dynamic>>;
        expenseData['splits'] = _updateSplitsWithNewMemberIds(splits, newMemberIds);
        
        // Also update payer information if the selected payer is a new participant
        final selectedPayerName = _findMemberNameById(_selectedPayerId);
        if (selectedPayerName != null && newMemberIds.containsKey(selectedPayerName)) {
          final payers = expenseData['payers'] as List<Map<String, dynamic>>;
          payers[0]['group_member_id'] = newMemberIds[selectedPayerName];
          debugPrint('Updated payer ID for $selectedPayerName: ${_selectedPayerId} -> ${newMemberIds[selectedPayerName]}');
        } else {
          // The payer is a new participant with a temporary ID
          final payerMember = _groupMembers.firstWhere(
            (m) => m['id'].toString() == _selectedPayerId,
            orElse: () => <String, Object>{},
          );
          if (payerMember.isNotEmpty) {
            final payerName = payerMember['name'] as String?;
            if (payerName != null && newMemberIds.containsKey(payerName)) {
              final payers = expenseData['payers'] as List<Map<String, dynamic>>;
              payers[0]['group_member_id'] = newMemberIds[payerName];
              debugPrint('Updated payer ID for new participant $payerName: ${_selectedPayerId} -> ${newMemberIds[payerName]}');
            }
          }
        }
      }

      // Call the actual API
      final response = await ApiService.instance.createExpense(expenseData);
      
      debugPrint('API response: $response');

      // Optimistic update: Increment expenses count
      UserStatsService.incrementExpensesCount();
      
      // Background refresh of stats
      UserStatsService.refreshStatsInBackground();

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Check if we came from group detail page
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final groupId = args?['groupId'];
        
        if (groupId != null) {
          // Return to group detail page with success result
          Navigator.pop(context, {
            'success': true,
            'expense': {
              'id': response['data']['id'],
              'title': expenseData['title'],
              'total_amount': expenseData['total_amount'],
              'currency': expenseData['currency'],
              'date': expenseData['date'],
              'payer_name': _groupMembers.firstWhere(
                (m) => m['id'].toString() == _selectedPayerId.toString(),
                orElse: () => <String, Object>{'name': 'Unknown'},
              )['name'],
              'payer_id': int.tryParse(_selectedPayerId.toString()) ?? 0,
              'created_at': DateTime.now().toIso8601String(),
            },
            'groupId': groupId,
          });
        } else {
          // Navigate to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isReceiptMode 
                ? 'Receipt expense created successfully!' 
                : 'Expense created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/expense-dashboard');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      debugPrint('Expense save failed: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create expense: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Build splits data based on split type and group members
  List<Map<String, dynamic>> _buildSplitsData() {
    final totalAmount = double.parse(_totalController.text.replaceAll(',', '.'));
    final splits = <Map<String, dynamic>>[];
    
    print('Building splits data for split type: $_splitType');
    print('Total amount: $totalAmount');
    print('Selected members: $_selectedMembers');
    print('Member percentages: $_memberPercentages');
    print('Custom amounts: $_customAmounts');
    
    if (_splitType == 'equal') {
      // Equal split among selected members or all members if none selected
      final membersToSplit = _selectedMembers.isNotEmpty ? _selectedMembers : _groupMembers.map((m) => m['name'].toString()).toList();
      final memberCount = membersToSplit.length;
      final amountPerMember = totalAmount / memberCount;
      
      for (final memberName in membersToSplit) {
        // Find the group member by name
        final member = _groupMembers.firstWhere(
          (m) => m['name'] == memberName,
          orElse: () => <String, Object>{'id': 0, 'name': memberName},
        );
        
        // Handle both real group member IDs and temporary IDs for new participants
        final memberId = member['id'];
        if (memberId != 0) {
          // Check if this is a temporary ID (string)
          if (memberId is String) {
            // This is a temporary ID for a new participant
            // We'll handle this in the expense creation process
            splits.add({
              'group_member_id': memberId,
              'amount_owed': amountPerMember,
              'member_name': memberName, // Include name for later mapping
            });
          } else {
            // This is a real group member ID
            splits.add({
              'group_member_id': int.parse(memberId.toString()),
              'amount_owed': amountPerMember,
            });
          }
        }
      }
    } else if (_splitType == 'percentage') {
      // Percentage split - use member percentages from UI
      if (_memberPercentages.isNotEmpty) {
        for (final member in _groupMembers) {
          final memberName = member['name'];
          final percentage = _memberPercentages[memberName] ?? 0.0;
          if (percentage > 0) {
            final amount = totalAmount * (percentage / 100.0);
            final memberId = member['id'];
            
            // Handle both real group member IDs and temporary IDs for new participants
            if (memberId is String) {
              // This is a temporary ID for a new participant
              splits.add({
                'group_member_id': memberId,
                'amount_owed': amount,
                'percentage': percentage,
                'member_name': memberName, // Include name for later mapping
              });
            } else {
              // This is a real group member ID
              splits.add({
                'group_member_id': int.parse(memberId.toString()),
                'amount_owed': amount,
                'percentage': percentage,
              });
            }
          }
        }
      } else {
        // Fallback to equal split if no percentages are set
        final memberCount = _groupMembers.length;
        final amountPerMember = totalAmount / memberCount;
        
        for (final member in _groupMembers) {
          final memberId = member['id'];
          
          // Handle both real group member IDs and temporary IDs for new participants
          if (memberId is String) {
            // This is a temporary ID for a new participant
            splits.add({
              'group_member_id': memberId,
              'amount_owed': amountPerMember,
              'member_name': member['name'], // Include name for later mapping
            });
          } else {
            // This is a real group member ID
            splits.add({
              'group_member_id': int.parse(memberId.toString()),
              'amount_owed': amountPerMember,
            });
          }
        }
      }
    } else if (_splitType == 'custom') {
      // Custom split - use prefilled amounts from receipt mode or custom amounts from UI
      if (_isReceiptMode && _prefilledCustomAmounts.isNotEmpty) {
        debugPrint('Building custom splits in receipt mode:');
        debugPrint('  Prefilled amounts: $_prefilledCustomAmounts');
        debugPrint('  Group members: ${_groupMembers.map((m) => m['name']).toList()}');
        
        for (final member in _groupMembers) {
          final memberName = member['name'];
          final amount = _prefilledCustomAmounts[memberName] ?? 0.0;
          debugPrint('  Checking member: $memberName, amount: $amount');
          
          // Include all members, even if amount is 0 (they might have been assigned items)
          final memberId = member['id'];
          
          // Handle both real group member IDs and temporary IDs for new participants
          if (memberId is String) {
            // This is a temporary ID for a new participant
            splits.add({
              'group_member_id': memberId,
              'amount_owed': amount,
              'member_name': memberName, // Include name for later mapping
            });
            debugPrint('    Added new participant: $memberName (ID: $memberId) with amount: $amount');
          } else {
            // This is a real group member ID
            splits.add({
              'group_member_id': int.parse(memberId.toString()),
              'amount_owed': amount,
            });
            debugPrint('    Added existing member: $memberName (ID: $memberId) with amount: $amount');
          }
        }
      } else if (_customAmounts.isNotEmpty) {
        // Use custom amounts from the UI
        for (final member in _groupMembers) {
          final memberName = member['name'];
          final amount = _customAmounts[memberName] ?? 0.0;
          if (amount > 0) {
            final memberId = member['id'];
            
            // Handle both real group member IDs and temporary IDs for new participants
            if (memberId is String) {
              // This is a temporary ID for a new participant
              splits.add({
                'group_member_id': memberId,
                'amount_owed': amount,
                'member_name': memberName, // Include name for later mapping
              });
            } else {
              // This is a real group member ID
              splits.add({
                'group_member_id': int.parse(memberId.toString()),
                'amount_owed': amount,
              });
            }
          }
        }
      } else {
        // Fallback to equal split for custom mode without any custom amounts
        final memberCount = _groupMembers.length;
        final amountPerMember = totalAmount / memberCount;
        
        for (final member in _groupMembers) {
          final memberId = member['id'];
          
          // Handle both real group member IDs and temporary IDs for new participants
          if (memberId is String) {
            // This is a temporary ID for a new participant
            splits.add({
              'group_member_id': memberId,
              'amount_owed': amountPerMember,
              'member_name': member['name'], // Include name for later mapping
            });
          } else {
            // This is a real group member ID
            splits.add({
              'group_member_id': int.parse(memberId.toString()),
              'amount_owed': amountPerMember,
            });
          }
        }
      }
    }
    
    print('Final splits data: $splits');
    return splits;
  }

  /// Creates new members in the group before creating the expense
  /// Returns a map of member names to their new IDs for updating splits data
  Future<Map<String, int>> _createNewMembersInGroup(String groupId) async {
    if (_receiptData?.newParticipants == null || _receiptData!.newParticipants!.isEmpty) {
      return {};
    }

    debugPrint('Creating ${_receiptData!.newParticipants!.length} new members in group $groupId');
    final memberIdMap = <String, int>{};

    try {
      for (final newParticipant in _receiptData!.newParticipants!) {
        final memberName = newParticipant['name'] as String? ?? '';
        if (memberName.isNotEmpty) {
          debugPrint('Creating member: $memberName');
          
          // Call the API to add the member to the group
          final response = await ApiService.instance.addGroupMember(groupId, {
            'nickname': memberName,
            'email': '', // Empty email for non-registered users
            'role': 'member', // Default role
          });
          
          // Extract the new member ID from the response
          if (response['success'] && response['data'] != null) {
            final newMemberId = response['data']['id'] as int?;
            if (newMemberId != null) {
              memberIdMap[memberName] = newMemberId;
              debugPrint('Successfully created member: $memberName with ID: $newMemberId');
            }
          }
        }
      }
      
      debugPrint('All new members created successfully. Member ID map: $memberIdMap');
      return memberIdMap;
    } catch (e) {
      debugPrint('Error creating new members: $e');
      // Don't throw here - we want to continue with expense creation even if member creation fails
      // The expense will still be created with the existing members
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Some new members could not be added to the group: $e'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return memberIdMap; // Return partial results
    }
  }

  /// Updates splits data with new member IDs for participants that were just created
  List<Map<String, dynamic>> _updateSplitsWithNewMemberIds(
    List<Map<String, dynamic>> splits, 
    Map<String, int> newMemberIds
  ) {
    final updatedSplits = <Map<String, dynamic>>[];
    
    for (final split in splits) {
      final memberId = split['group_member_id'];
      final memberName = split['member_name'] as String?;
      
      // Check if this is a temporary ID (string)
      if (memberId is String) {
        // This is a temporary ID for a new participant
        if (memberName != null && newMemberIds.containsKey(memberName)) {
          // Replace with the real member ID
          final updatedSplit = Map<String, dynamic>.from(split);
          updatedSplit['group_member_id'] = newMemberIds[memberName];
          updatedSplit.remove('member_name'); // Remove the temporary field
          updatedSplits.add(updatedSplit);
          debugPrint('Updated split for member $memberName: ${memberId} -> ${newMemberIds[memberName]}');
          continue;
        } else {
          // Could not find the member name or new member ID, skip this split
          debugPrint('Warning: Could not update split for member $memberName (ID: $memberId)');
          continue;
        }
      }
      
      // Keep the original split if no update needed
      updatedSplits.add(split);
    }
    
    return updatedSplits;
  }

  /// Helper method to find member name by ID
  String? _findMemberNameById(String memberId) {
    for (final member in _groupMembers) {
      if (member['id'].toString() == memberId) {
        return member['name'] as String?;
      }
    }
    return null;
  }

  bool _validateForm() {
    // Standard form validation - this validates all form fields including payer selection
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // Additional comprehensive validation for payer selection integration
    if (!_validatePayerSelection()) {
      return false;
    }

    // Receipt mode specific validation
    if (_isReceiptMode) {
      if (!_validateReceiptMode()) {
        return false;
      }
    } else {
      // Manual mode validation
      if (!_validateManualMode()) {
        return false;
      }
    }

    return true;
  }

  /// Comprehensive payer selection validation
  bool _validatePayerSelection() {
    // Group selection validation
    if (_selectedGroup.isEmpty) {
      _showValidationError('Please select a group first');
      return false;
    }

    // Group members availability validation
    if (_groupMembers.isEmpty && !_isLoadingPayers) {
      _showValidationError('No members available in the selected group. Please add members to the group first.');
      return false;
    }

    // Loading state validation - prevent submission during loading
    if (_isLoadingPayers || _isLoadingMembers) {
      _showValidationError('Please wait while group members are loading');
      return false;
    }

    // Payer selection validation
    if (_selectedPayerId.isEmpty) {
      _showValidationError('Please select who paid for this expense');
      return false;
    }

    // Validate that selected payer is a valid group member
          final payerExists = _groupMembers.any((member) => member['id'].toString() == _selectedPayerId.toString());
    if (!payerExists) {
      _showValidationError('Selected payer is not a valid group member. Please select a different payer.');
      return false;
    }

    // Validate payer is part of the selected group (additional safety check)
    // Skip this validation in receipt mode since we don't load _realGroups
    if (!_isReceiptMode) {
      final selectedGroupObj = _realGroups.firstWhere(
        (group) => group.name == _selectedGroup,
        orElse: () => Group(
          id: 0,
          name: '',
          currency: CurrencyMigrationService.parseFromBackend('USD'),
          description: '',
          createdBy: 0,
          members: [],
          lastUsed: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (selectedGroupObj.id == 0) {
        _showValidationError('Selected group is invalid. Please select a different group.');
        return false;
      }
    }

    return true;
  }

  /// Receipt mode specific validation
  bool _validateReceiptMode() {
    // Ensure receipt data is valid
    if (_receiptData == null) {
      _showValidationError('Receipt data is missing');
      return false;
    }

    // Validate receipt data integrity
    final validationError = _receiptData!.validate();
    if (validationError != null) {
      _showValidationError('Receipt validation failed: $validationError');
      return false;
    }

    // Ensure total amount matches receipt data
    double parsedTotal = double.tryParse(_totalController.text.replaceAll(',', '.')) ?? 0.0;
    if ((parsedTotal - _receiptData!.total).abs() > 0.01) {
      _showValidationError('Total amount does not match receipt data');
      return false;
    }

    // Ensure split type is custom for receipt mode
    if (_splitType != 'custom') {
      _showValidationError('Receipt mode requires custom split type');
      return false;
    }

    // Validate payer selection works with receipt mode constraints
    // Check if payer exists in either group members or new participants
    bool payerExists = false;
    
    // Check in group members
    if (_receiptData!.groupMembers.isNotEmpty) {
      payerExists = _receiptData!.groupMembers.any(
        (member) => member['id'].toString() == _selectedPayerId.toString()
      );
    }
    
    // Check in new participants if not found in group members
    if (!payerExists && _receiptData!.newParticipants != null && _receiptData!.newParticipants!.isNotEmpty) {
      payerExists = _receiptData!.newParticipants!.any(
        (member) => member['id'].toString() == _selectedPayerId.toString()
      );
    }
    
    if (!payerExists) {
      _showValidationError('Selected payer is not part of the receipt group members or new participants');
      return false;
    }

    return true;
  }

  /// Manual mode specific validation
  bool _validateManualMode() {
    double parsedTotal = double.tryParse(_totalController.text.replaceAll(',', '.')) ?? 0.0;
    if (parsedTotal <= 0) {
      _showValidationError('Total amount must be greater than zero');
      return false;
    }

    return true;
  }

  void _showValidationError(String message) {
    // Show validation error with consistent styling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
    
    // Also trigger form validation to show field-level errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _formKey.currentState != null) {
        _formKey.currentState!.validate();
      }
    });
  }



  void _onCurrencyChanged(Currency? value) {
    if (value != null) {
      try {
        // Validate currency before setting
        _validateCurrency(value);
        
        setState(() {
          _currency = value;
        });
        
        // Provide immediate visual feedback for currency change
        _showCurrencyChangeFeedback(value);
      } catch (e) {
        _showCurrencyError('Invalid currency selected: $e');
      }
    }
  }
  
  /// Validate currency object
  void _validateCurrency(Currency currency) {
    if (currency.code.isEmpty) {
      throw ArgumentError('Currency code cannot be empty');
    }
    
    if (currency.code.length != 3) {
      throw ArgumentError('Currency code must be exactly 3 characters');
    }
    
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency.code)) {
      throw ArgumentError('Currency code must contain only uppercase letters');
    }
  }
  
  /// Show currency error message
  void _showCurrencyError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show visual feedback when currency changes
  void _showCurrencyChangeFeedback(Currency newCurrency) {
    // Show a brief snackbar with the currency change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.currency_exchange,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text('Currency changed to ${newCurrency.code}'),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.primaryColor,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    
    // Trigger haptic feedback for currency change
    HapticFeedback.lightImpact();
  }

  /// Upload image to Cloudinary and return the URL
  Future<String> _uploadImageToCloudinary(File imageFile) async {
    try {
      debugPrint('Starting image upload to Cloudinary: ${imageFile.path}');
      
      // Use the API service to upload the image
      final response = await ApiService.instance.processReceipt(imageFile);
      
      debugPrint('Upload response: $response');
      
      if (response['success'] == true && response['data'] != null) {
        final imageUrl = response['data']['image_url'];
        if (imageUrl != null) {
          debugPrint('Successfully got image URL from upload: $imageUrl');
          return imageUrl;
        } else {
          debugPrint('No image_url in response data: ${response['data']}');
        }
      } else {
        debugPrint('Upload failed or no data in response: success=${response['success']}, data=${response['data']}');
      }
      
      throw Exception('Failed to get image URL from upload response');
    } catch (e) {
      debugPrint('Error uploading image to Cloudinary: $e');
      rethrow;
    }
  }

  /// Navigate to camera to capture receipt image
  void _navigateToCamera() async {
    try {
      // Use the new flexible camera system for expense photo capture
      final result = await ExpensePhotoCapture.showExpensePhotoCaptureWithResult(context);
      
      if (result != null && result['success'] == true && result['imagePath'] != null) {
        setState(() {
          // Update receipt data with the captured image
          _receiptData = ReceiptModeData(
            total: _receiptData?.total ?? 0.0,
            participantAmounts: _receiptData?.participantAmounts ?? [],
            mode: _receiptData?.mode ?? 'receipt',
            isEqualSplit: _receiptData?.isEqualSplit ?? false,
            items: _receiptData?.items ?? [],
            groupMembers: _receiptData?.groupMembers ?? [],
            quantityAssignments: _receiptData?.quantityAssignments,
            selectedGroupId: _receiptData?.selectedGroupId ?? _realGroups.first.id.toString(),
            selectedGroupName: _receiptData?.selectedGroupName,
            newParticipants: _receiptData?.newParticipants,
            imagePath: result['imagePath'],
            imageUrl: _receiptData?.imageUrl, // Preserve existing imageUrl if any
          );
        });
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt image added successfully'),
            backgroundColor: AppTheme.lightTheme.primaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open camera'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double parsedTotal = double.tryParse(_totalController.text.replaceAll(',', '.')) ?? 0.0;
    final symbol = _currency.symbol;
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Sticky Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
                        'Cancel',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Create Expense',
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(4.w),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 200, // Ensure minimum height
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Receipt Image
                        ReceiptImageWidget(
                          imageUrl: _receiptData?.imagePath,
                          onAddImage: _navigateToCamera,
                        ),

                        SizedBox(height: 3.h),

                        // Expense Details
                        ExpenseDetailsWidget(
                          selectedGroup: _selectedGroup,
                          selectedCategory: _selectedCategory,
                          selectedDate: _selectedDate,
                          notesController: _notesController,
                          groups: _groups,
                          categories: _categories,
                          onGroupChanged: _receiptModeConfig.isGroupEditable 
                              ? (value) {
                                  setState(() {
                                    _selectedGroup = value;
                                    // Reset payer selection when group changes
                                    _selectedPayerId = '';
                                    // Clear group members while loading new ones
                                    _groupMembers = [];
                                  });
                                  
                                  // Don't trigger validation immediately to prevent premature validation errors
                                  
                                  // Load members for the selected group and update currency
                                  try {
                                    final selectedGroup = _realGroups.firstWhere(
                                      (group) => group.name == value,
                                    );
                                    _loadGroupMembers(selectedGroup.id.toString());
                                    
                                    // Cascade group currency to expense
                                    setState(() {
                                      _currency = selectedGroup.currency;
                                    });
                                    debugPrint('Currency cascaded from group: ${selectedGroup.currency.code}');
                                  } catch (e) {
                                    debugPrint('Error finding selected group: $e');
                                    // Handle case where selected group is not found
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Selected group not found. Please try again.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          onCategoryChanged: (value) =>
                              setState(() => _selectedCategory = value),
                          onDateTap: _selectDate,
                          totalController: _totalController,
                          currency: _currency,
                          onCurrencyChanged: _onCurrencyChanged,
                          mode: mode,
                          isReceiptMode: _isReceiptMode,
                          receiptModeConfig: _receiptModeConfig,
                          isLoadingGroups: _isLoadingGroups,
                          // Payer selection parameters
                          selectedPayerId: _selectedPayerId,
                          onPayerChanged: _onPayerChanged,
                          groupMembers: _groupMembers,
                          isLoadingPayers: _isLoadingPayers,
                          // Title field and group visibility parameters
                          showGroupField: _showGroupField,
                          titleController: _titleController,
                          onTitleChanged: _onTitleChanged,
                        ),

                        SizedBox(height: 3.h),

                        // Split Options
                        SplitOptionsWidget(
                          splitType: _splitType,
                          onSplitTypeChanged: _receiptModeConfig.isSplitTypeEditable
                              ? (value) {
                                  setState(() {
                                    _splitType = value;
                                    // When switching to equal split, select all members by default
                                    if (value == 'equal' && _selectedMembers.isEmpty) {
                                      _selectedMembers = _groupMembers.map((m) => m['name'].toString()).toList();
                                    }
                                  });
                                }
                              : null,
                          groupMembers: _groupMembers,
                          totalAmount: parsedTotal,
                          currency: _currency,
                          isReceiptMode: _isReceiptMode,
                          prefilledCustomAmounts: _isReceiptMode ? _prefilledCustomAmounts : null,
                          selectedMembers: _splitType == 'equal' ? _selectedMembers : null,
                          memberPercentages: _splitType == 'percentage' ? _memberPercentages : null,
                          onMembersChanged: (members) {
                            setState(() {
                              _selectedMembers = members;
                            });
                          },
                          onPercentagesChanged: (percentages) {
                            setState(() {
                              _memberPercentages = percentages;
                            });
                          },
                          onCustomAmountsChanged: (amounts) {
                            setState(() {
                              _customAmounts = amounts;
                            });
                          },
                          isLoadingMembers: _isLoadingMembers,
                        ),

                        SizedBox(height: 4.h),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Action Button
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.cardColor,
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.lightTheme.dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveExpense,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.lightTheme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Create Expense',
                            style: AppTheme.lightTheme.textTheme.titleMedium
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
