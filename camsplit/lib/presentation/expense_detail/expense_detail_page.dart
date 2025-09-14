import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';
import '../../core/app_export.dart';
import '../../models/expense_detail_model.dart';
import '../../models/participant_amount.dart';
import '../../models/group_member.dart';
import '../../services/expense_detail_service.dart';
import '../../services/currency_service.dart';
import '../expense_creation/widgets/expense_details_widget.dart';
import '../expense_creation/widgets/receipt_image_widget.dart';
import '../expense_creation/widgets/split_options_widget.dart';
import 'widgets/expense_detail_header.dart';

/// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  final List<String> errors;
  const ValidationException(this.errors);
  
  @override
  String toString() => 'ValidationException: ${errors.join(', ')}';
}

class ExpenseDetailPage extends StatefulWidget {
  final int expenseId;

  const ExpenseDetailPage({
    Key? key,
    required this.expenseId,
  }) : super(key: key);

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSaving = false;
  ExpenseDetailModel? _expense;
  ExpenseDetailModel? _originalExpense; // For cancel functionality
  String? _errorMessage;

  // Form controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  // Form state
  String _selectedGroup = '';
  String _selectedCategory = 'Food & Dining';
  DateTime _selectedDate = DateTime.now();
  String _splitType = 'equal';
  double _totalAmount = 0.0;
  Currency? _selectedCurrency;
  
  // Split options state
  List<String> _selectedMembers = [];
  Map<String, double> _memberPercentages = {};
  Map<String, double> _customAmounts = {};
  
  // Group members for selection
  List<Map<String, dynamic>> _groupMembers = [];
  String _groupName = 'Unknown Group'; // State variable to hold the group name
  
  // Selected payer ID for change tracking
  int _selectedPayerId = 0;

  // Categories list - this could come from a service in the future
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
    _loadExpenseData();
    
    // Listen to total controller changes to update total amount
    _totalController.addListener(() {
      final newTotal = double.tryParse(_totalController.text) ?? 0.0;
      if (newTotal != _totalAmount) {
        setState(() {
          _totalAmount = newTotal;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _notesController.dispose();
    _totalController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenseData() async {
    await _loadExpenseDataWithRetry();
  }

  /// Load expense data with automatic retry for transient failures
  Future<void> _loadExpenseDataWithRetry({int maxRetries = 3}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    int retryCount = 0;
    Duration retryDelay = Duration(seconds: 1);

    while (retryCount <= maxRetries) {
      try {
        // First get basic expense to get group ID
        final basicExpense = await ExpenseDetailService.getExpenseById(widget.expenseId);
        final groupId = int.tryParse(basicExpense.groupId);
        
        if (groupId == null || groupId <= 0) {
          throw ExpenseDetailServiceException('Invalid group ID for expense');
        }
        
        // Then get expense with enhanced member details
        final expense = await ExpenseDetailService.getExpenseWithMemberDetails(widget.expenseId, groupId);
        
        // Debug logging for receipt image
        debugPrint('ExpenseDetailPage: Loaded expense with receipt image URL: ${expense.receiptImageUrl}');
        debugPrint('ExpenseDetailPage: Has receipt image: ${expense.hasReceiptImage}');
        
        // Also load the full group member list for selection
        await _loadGroupMembers(groupId);
        
        setState(() {
          _expense = expense;
          _originalExpense = expense; // Store original for cancel functionality
          _isLoading = false;
          _errorMessage = null;
        });
        
        // Populate form fields after state is updated and group members are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _populateFormFields();
          }
        });
        return; // Success, exit retry loop
        
      } on ExpenseDetailServiceException catch (e) {
        // Don't retry service exceptions (not found, permission denied, etc.)
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
        
        _handleLoadError(e, isServiceError: true);
        return;
        
      } catch (e) {
        retryCount++;
        
        if (retryCount > maxRetries) {
          // Max retries reached
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load expense after $maxRetries attempts';
          });
          
          _handleLoadError(e, isServiceError: false, retryCount: retryCount - 1);
          return;
        }
        
        // Show retry attempt to user (except for first attempt)
        if (retryCount > 1 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loading failed, retrying... (${retryCount - 1}/$maxRetries)'),
              duration: retryDelay,
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        await Future.delayed(retryDelay);
        retryDelay = Duration(seconds: retryDelay.inSeconds * 2); // Exponential backoff
      }
    }
  }

  /// Handle loading errors with appropriate user feedback and recovery options
  void _handleLoadError(dynamic error, {required bool isServiceError, int retryCount = 0}) {
    if (!mounted) return;

    String userMessage;
    List<SnackBarAction> actions = [];

    if (isServiceError && error is ExpenseDetailServiceException) {
      if (error.message.contains('not found')) {
        userMessage = 'Expense not found. It may have been deleted.';
        actions.add(SnackBarAction(
          label: 'Go Back',
          onPressed: () => Navigator.of(context).pop(),
        ));
      } else if (error.message.contains('permission')) {
        userMessage = 'You don\'t have permission to view this expense.';
        actions.add(SnackBarAction(
          label: 'Go Back',
          onPressed: () => Navigator.of(context).pop(),
        ));
      } else {
        userMessage = 'Failed to load expense: ${error.message}';
        actions.add(SnackBarAction(
          label: 'Retry',
          onPressed: () => _loadExpenseDataWithRetry(),
        ));
      }
    } else {
      // Network or other errors
      if (retryCount > 0) {
        userMessage = 'Failed to load expense after $retryCount attempts. Check your connection.';
      } else {
        userMessage = 'Failed to load expense. Check your connection.';
      }
      
      actions.addAll([
        SnackBarAction(
          label: 'Retry',
          onPressed: () => _loadExpenseDataWithRetry(),
        ),
        SnackBarAction(
          label: 'Go Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ]);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isServiceError ? Icons.error_outline : Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(userMessage)),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: actions.isNotEmpty ? actions.first : null,
      ),
    );
  }

  /// Load group members for selection
  Future<void> _loadGroupMembers(int groupId) async {
    try {
      print('Loading group members for group ID: $groupId');
      final response = await ApiService.instance.getGroupWithMembers(groupId.toString());
      print('Group members response: $response');
      
      if (response['success'] && response['data'] != null) {
        final groupData = response['data'];
        print('Group data: $groupData');
        
        // Store the group name
        final groupName = groupData['name'] ?? 'Unknown Group';
        print('Group name: $groupName');
        
        final members = (groupData['members'] as List<dynamic>?)
            ?.map((memberJson) => GroupMember.fromJson(memberJson, groupId: groupId))
            .toList() ?? [];
        
        print('Parsed members: ${members.map((m) => '${m.id}:${m.nickname}').join(', ')}');
        
        final groupMembersList = members.map((member) {
          return <String, dynamic>{
            'id': member.id,
            'name': member.nickname,
            'avatar': member.avatarUrl ?? '', // Use actual avatar URL from GroupMember
            'initials': _getInitials(member.nickname), // Add initials for avatar fallback
            'email': member.email ?? '',
            'isCurrentUser': false, // We'll determine this later if needed
          };
        }).toList();
        
        print('Group members list: ${groupMembersList.map((m) => '${m['id']}:${m['name']}').join(', ')}');
        
        // Group members loaded successfully
        setState(() {
          _groupMembers = groupMembersList;
          _groupName = groupName; // Store the group name
        });
      } else {
        print('Group members response not successful: ${response['message']}');
        setState(() {
          _groupMembers = [];
          _groupName = 'Unknown Group';
        });
      }
    } catch (e) {
      // If group members fail to load, continue with empty list
      print('Failed to load group members: $e');
      setState(() {
        _groupMembers = [];
        _groupName = 'Unknown Group';
      });
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

  /// Get a valid payer ID that exists in the group members list
  String _getValidPayerId() {
    print('Getting valid payer ID. Selected: $_selectedPayerId, Available: ${_groupMembers.map((m) => m['id']).join(', ')}');
    
    // If the current selected payer ID exists in group members, use it
    if (_groupMembers.any((member) => member['id'] == _selectedPayerId)) {
      print('Using current selected payer ID: $_selectedPayerId');
      return _selectedPayerId.toString();
    }
    
    // If expense has a valid payer ID and it exists in group members, use it
    if (_expense != null && _expense!.payerId > 0 && _groupMembers.any((member) => member['id'] == _expense!.payerId)) {
      print('Using expense payer ID: ${_expense!.payerId}');
      return _expense!.payerId.toString();
    }
    
    // Otherwise, use the first available member
    if (_groupMembers.isNotEmpty) {
      print('Using first available member: ${_groupMembers.first['id']}');
      return _groupMembers.first['id'].toString();
    }
    
    // Fallback to empty string if no members available
    print('No valid payer ID found, using empty string');
    return '';
  }

  /// Refresh UI state to match the current expense data
  Future<void> _refreshUIState() async {
    if (_expense == null) return;
    
    try {
      print('Refreshing UI state for expense: ${_expense!.id}');
      print('Current payer ID: ${_expense!.payerId}');
      print('Current selected payer ID: $_selectedPayerId');
      print('Group members count: ${_groupMembers.length}');
      
      // Reload group members to ensure we have the latest data
      final groupId = int.tryParse(_expense!.groupId);
      if (groupId != null && groupId > 0) {
        await _loadGroupMembers(groupId);
        print('Reloaded group members. New count: ${_groupMembers.length}');
      }
      
      // Only update payer ID if it's different from the expense's payer ID
      final expensePayerId = _expense!.payerId;
      if (_selectedPayerId != expensePayerId) {
        final payerExists = _groupMembers.any((member) => member['id'] == expensePayerId);
        
        if (!payerExists && _groupMembers.isNotEmpty) {
          print('Warning: Payer ID $expensePayerId not found in group members. Using first member.');
          setState(() {
            _selectedPayerId = _groupMembers.first['id'];
          });
        } else {
          setState(() {
            _selectedPayerId = expensePayerId;
          });
        }
        print('Updated selected payer ID to: $_selectedPayerId');
      } else {
        print('Payer ID unchanged: $_selectedPayerId');
      }
      
      // Repopulate form fields to ensure consistency
      _populateFormFields();
      print('Form fields repopulated');
    } catch (e) {
      print('Failed to refresh UI state: $e');
    }
  }

  void _populateFormFields() {
    if (_expense == null) return;

    print('Populating form fields for expense: ${_expense!.id}');
    print('Expense payer ID: ${_expense!.payerId}, payer name: ${_expense!.payerName}');
    print('Expense group name: ${_expense!.groupName}');
    print('Actual group name: $_groupName');

    _totalController.text = _expense!.amount.toStringAsFixed(2);
    _totalAmount = _expense!.amount;
    _selectedDate = _expense!.date;
    _selectedGroup = _groupName; // Use the actual group name instead of the generic one
    _selectedCategory = _expense!.category;
    _splitType = _expense!.splitType;
    _notesController.text = _expense!.notes;
    _titleController.text = _expense!.title;
    
    // Initialize split-related state
    // For equal split, all participants with amounts > 0 should be selected
    if (_splitType == 'equal') {
      print('Initializing equal split selected members');
      print('Participant amounts: ${_expense!.participantAmounts.map((p) => '${p.name}: ${p.amount}').join(', ')}');
      _selectedMembers = _expense!.participantAmounts
          .where((p) => p.amount > 0) // Only include participants with amounts > 0
          .map((p) => p.name ?? 'Unknown') // Use the participant name directly
          .toList();
      print('Selected members for equal split: $_selectedMembers');
    } else {
      // For other split types, map participant names to group member names
      _selectedMembers = _expense!.participantAmounts
          .where((p) => p.amount > 0) // Only include participants with amounts > 0
          .map((p) {
            // Try to find matching group member by name
            String memberName = p.name ?? 'Unknown'; // Default to 'Unknown' if name is null
            for (final member in _groupMembers) {
              if (member['name'] == p.name) {
                memberName = member['name']; // Use the member name, not nickname
                break;
              }
            }
            return memberName;
          })
          .toList();
    }
    
    // Initialize percentages and custom amounts based on split type
    if (_splitType == 'percentage') {
      print('Initializing percentage data for split type: $_splitType');
      print('Participant amounts: ${_expense!.participantAmounts.map((p) => '${p.name}: ${p.percentage}%').join(', ')}');
      print('Group members: ${_groupMembers.map((m) => '${m['id']}:${m['name']}').join(', ')}');
      
      _memberPercentages = {};
      for (final participant in _expense!.participantAmounts) {
        if (participant.percentage != null && participant.percentage! > 0) {
          // Try to find matching group member by name first
          String memberName = participant.name ?? 'Unknown';
          
          // Look for exact name match
          final matchingMember = _groupMembers.firstWhere(
            (member) => member['name'] == participant.name,
            orElse: () => <String, dynamic>{},
          );
          
          if (matchingMember.isNotEmpty) {
            memberName = matchingMember['name'];
            print('Found matching member by name: $memberName');
          } else {
            // If no exact match, try to find by group member ID
            if (participant.groupMemberId != null) {
              final memberById = _groupMembers.firstWhere(
                (member) => member['id'] == participant.groupMemberId,
                orElse: () => <String, dynamic>{},
              );
              if (memberById.isNotEmpty) {
                memberName = memberById['name'];
                print('Found matching member by ID: $memberName');
              }
            }
          }
          
          _memberPercentages[memberName] = participant.percentage!;
          print('Added percentage for $memberName: ${participant.percentage}%');
        }
      }
      print('Final member percentages: $_memberPercentages');
      
      // Force UI update when percentage data is loaded
      if (mounted) {
        setState(() {});
      }
    } else if (_splitType == 'custom') {
      print('Initializing custom amounts for split type: $_splitType');
      print('Participant amounts: ${_expense!.participantAmounts.map((p) => '${p.name}: ${p.amount}').join(', ')}');
      
      _customAmounts = {};
      for (final participant in _expense!.participantAmounts) {
        if (participant.amount > 0) {
          // Try to find matching group member by name first
          String memberName = participant.name ?? 'Unknown';
          
          // Look for exact name match
          final matchingMember = _groupMembers.firstWhere(
            (member) => member['name'] == participant.name,
            orElse: () => <String, dynamic>{},
          );
          
          if (matchingMember.isNotEmpty) {
            memberName = matchingMember['name'];
          } else {
            // If no exact match, try to find by group member ID
            if (participant.groupMemberId != null) {
              final memberById = _groupMembers.firstWhere(
                (member) => member['id'] == participant.groupMemberId,
                orElse: () => <String, dynamic>{},
              );
              if (memberById.isNotEmpty) {
                memberName = memberById['name'];
              }
            }
          }
          
          _customAmounts[memberName] = participant.amount;
        }
      }
      print('Final custom amounts: $_customAmounts');
      
      // Force UI update when custom amounts are loaded
      if (mounted) {
        setState(() {});
      }
    }
    
    // Set currency - use group currency context if available, otherwise use expense currency
    try {
      final groupId = int.tryParse(_expense!.groupId);
      if (groupId != null) {
        // Try to get group currency from service
        _selectedCurrency = CamSplitCurrencyService.getGroupCurrency(groupId);
        print('Using group currency context: ${_selectedCurrency?.code}');
      } else {
        // Fallback to expense currency
        _selectedCurrency = _expense!.currency;
        print('Using expense currency: ${_selectedCurrency?.code}');
      }
    } catch (e) {
      // Fallback to expense currency if group currency lookup fails
      _selectedCurrency = _expense!.currency;
      print('Fallback to expense currency: ${_selectedCurrency?.code}');
    }
    
    // Set selected payer ID - only if it's not already set or if it's different
    if (_selectedPayerId == 0 || _selectedPayerId != _expense!.payerId) {
      _selectedPayerId = _expense!.payerId;
      print('Updated selected payer ID to: $_selectedPayerId');
    }
    
    // Force UI update to reflect the changes
    if (mounted) {
      setState(() {});
    }
  }

  void _onSplitTypeChanged(String newSplitType) {
    setState(() {
      _splitType = newSplitType;
      
      // When switching to equal split, select all participants with amounts > 0
      if (newSplitType == 'equal' && _expense != null) {
        _selectedMembers = _expense!.participantAmounts
            .where((p) => p.amount > 0)
            .map((p) => p.name ?? 'Unknown')
            .toList();
      }
      
      // Clear other split-related data when switching types
      if (newSplitType != 'percentage') {
        _memberPercentages.clear();
      }
      if (newSplitType != 'custom') {
        _customAmounts.clear();
      }
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      
      // If entering edit mode, ensure form is ready for validation
      if (_isEditMode) {
        // Reset any previous validation errors
        _formKey.currentState?.reset();
      }
    });
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

  void _cancelEdit() {
    // Check if there are unsaved changes
    final hasChanges = _hasUnsavedChanges();
    
    if (hasChanges) {
      // Show confirmation dialog for unsaved changes
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Keep Editing'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performCancel();
                },
                child: const Text('Discard'),
              ),
            ],
          );
        },
      );
    } else {
      _performCancel();
    }
  }

  void _performCancel() {
    setState(() {
      _isEditMode = false;
      // Restore original data
      if (_originalExpense != null) {
        _expense = _originalExpense;
        _populateFormFields();
      }
    });
    
    // Show confirmation that changes were discarded
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changes discarded'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool _hasUnsavedChanges() {
    if (_originalExpense == null) return false;
    
    final currentTotal = double.tryParse(_totalController.text) ?? 0.0;
    
    return currentTotal != _originalExpense!.amount ||
           _selectedCategory != _originalExpense!.category ||
           _selectedDate != _originalExpense!.date ||
           _notesController.text != _originalExpense!.notes ||
           _splitType != _originalExpense!.splitType ||
           _selectedCurrency?.code != _originalExpense!.currency ||
           _selectedPayerId != _originalExpense!.payerId || // Check for payer changes
           !_areParticipantAmountsEqual(_calculateParticipantAmounts(currentTotal), _originalExpense!.participantAmounts);
  }

  bool _areParticipantAmountsEqual(List<ParticipantAmount> list1, List<ParticipantAmount> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].name != list2[i].name || (list1[i].amount - list2[i].amount).abs() > 0.01) {
        return false;
      }
    }
    return true;
  }

  Future<void> _saveChanges() async {
    // Comprehensive validation before attempting save
    final validationErrors = _performComprehensiveValidation();
    if (validationErrors.isNotEmpty) {
      _showValidationErrors(validationErrors);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null; // Clear any previous errors
    });

    try {
      // Update the total amount from the controller with robust parsing
      final text = _totalController.text.trim();
      double? newTotal;
      
      // Try to parse the amount, handling potential formatting issues
      if (text.isNotEmpty) {
        // Remove any currency symbols and extra spaces
        final cleanText = text.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
        newTotal = double.tryParse(cleanText);
      }
      
      // Fallback to original amount if parsing fails
      newTotal ??= _totalAmount;
      
      // Validate amount before proceeding
      if (newTotal <= 0) {
        _showValidationErrors(['Total amount must be greater than zero']);
        setState(() {
          _isSaving = false;
        });
        return;
      }
      
      // Calculate participant amounts
      final calculatedParticipantAmounts = _calculateParticipantAmounts(newTotal);
      
      // Create updated expense data
      final updatedExpense = _expense!.copyWith(
        title: _expense!.title, // Title is not editable in current implementation
        amount: newTotal,
        category: _selectedCategory,
        date: _selectedDate,
        notes: _notesController.text.trim(),
        splitType: _splitType,
        currency: _selectedCurrency ?? _expense!.currency,
        // Update participant amounts based on split type
        participantAmounts: calculatedParticipantAmounts,
        updatedAt: DateTime.now(),
      );

      // Validate the updated expense using service validation
      final validationResult = ExpenseDetailService.validateExpenseUpdate(updatedExpense);
      if (!validationResult['isValid']) {
        final errors = validationResult['errors'] as List<String>;
        _showValidationErrors(errors);
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Create payer data from selected payer and group members
      final payerData = _createPayerData(newTotal);
      
      // Create update request for API call with proper payer data
      final updateRequest = ExpenseUpdateRequest(
        expenseId: updatedExpense.id,
        groupId: int.tryParse(updatedExpense.groupId) ?? 0,
        title: updatedExpense.title,
        amount: updatedExpense.amount,
        currency: updatedExpense.currency,
        date: updatedExpense.date,
        category: updatedExpense.category,
        notes: updatedExpense.notes,
        splitType: updatedExpense.splitType,
        participantAmounts: updatedExpense.participantAmounts,
        payers: payerData,
      );
      
      // Call the expense detail service to update the expense with retry logic
      final savedExpense = await _saveWithRetry(updateRequest);

      setState(() {
        _expense = savedExpense;
        _originalExpense = savedExpense; // Update original for future cancels
        _isSaving = false;
        _isEditMode = false;
      });
      
      // Refresh UI state to match the updated expense data
      await _refreshUIState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Expense updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ExpenseDetailServiceException catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.message;
      });
      
      _handleServiceError(e);
    } on NetworkException catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Network error: ${e.message}';
      });
      
      _handleNetworkError(e);
    } on ValidationException catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      _showValidationErrors(e.errors);
    } catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Unexpected error occurred';
      });
      
      _handleUnexpectedError(e);
    }
  }

  /// Perform comprehensive validation of all form fields and business rules
  List<String> _performComprehensiveValidation() {
    final errors = <String>[];

    // Form validation
    if (!_formKey.currentState!.validate()) {
      errors.add('Please fix the form errors before saving');
    }

    // Split options validation
    final splitErrors = _validateSplitOptionsComprehensive();
    errors.addAll(splitErrors);

    // Business rules validation
    final businessErrors = _validateBusinessRulesComprehensive();
    errors.addAll(businessErrors);

    // Data consistency validation
    final consistencyErrors = _validateDataConsistency();
    errors.addAll(consistencyErrors);

    return errors;
  }

  /// Comprehensive split options validation with detailed error messages
  List<String> _validateSplitOptionsComprehensive() {
    final errors = <String>[];
    final totalAmount = double.tryParse(_totalController.text) ?? 0.0;

    switch (_splitType) {
      case 'equal':
        if (_selectedMembers.isEmpty) {
          errors.add('Please select at least one member for equal split');
        }
        if (_selectedMembers.length > 20) {
          errors.add('Too many members selected (maximum 20 allowed)');
        }
        break;

      case 'percentage':
        if (_memberPercentages.isEmpty) {
          errors.add('Please assign percentages to members');
        }
        
        // Check for invalid percentages
        final invalidPercentages = _memberPercentages.entries
            .where((entry) => entry.value < 0 || entry.value > 100);
        if (invalidPercentages.isNotEmpty) {
          errors.add('Percentages must be between 0% and 100%');
        }
        
        // Check for zero percentages when members are selected
        final zeroPercentages = _memberPercentages.entries
            .where((entry) => entry.value == 0 && _selectedMembers.contains(entry.key));
        if (zeroPercentages.isNotEmpty) {
          errors.add('Selected members must have percentages greater than 0%');
        }
        
        // Check total percentage
        final totalPercentage = _memberPercentages.values.fold(0.0, (sum, p) => sum + p);
        if (totalPercentage == 0) {
          errors.add('Please assign percentages to members');
        } else if ((totalPercentage - 100.0).abs() > 0.01) {
          errors.add('Percentages must total exactly 100% (currently ${totalPercentage.toStringAsFixed(1)}%)');
        }
        break;

      case 'custom':
        if (_customAmounts.isEmpty) {
          errors.add('Please assign custom amounts to members');
        }
        
        if (totalAmount <= 0) {
          errors.add('Please enter a valid total amount greater than zero');
        }
        
        // Check for invalid amounts
        final invalidAmounts = _customAmounts.entries
            .where((entry) => entry.value < 0);
        if (invalidAmounts.isNotEmpty) {
          errors.add('Custom amounts cannot be negative');
        }
        
        // Check for zero amounts when members are selected
        final zeroAmounts = _customAmounts.entries
            .where((entry) => entry.value == 0 && _selectedMembers.contains(entry.key));
        if (zeroAmounts.isNotEmpty) {
          errors.add('Selected members must have amounts greater than zero');
        }
        
        final totalCustom = _customAmounts.values.fold(0.0, (sum, a) => sum + a);
        if (totalCustom == 0) {
          errors.add('Please assign custom amounts to members');
        } else if ((totalCustom - totalAmount).abs() > 0.01) {
          final currencySymbol = _selectedCurrency?.symbol ?? '€';
          errors.add('Custom amounts (${currencySymbol}${totalCustom.toStringAsFixed(2)}) must equal total amount (${currencySymbol}${totalAmount.toStringAsFixed(2)})');
        }
        break;
    }
    return errors;
  }

  /// Comprehensive business rules validation
  List<String> _validateBusinessRulesComprehensive() {
    final errors = <String>[];

    // Check if expense can be edited
    if (_originalExpense != null && !_originalExpense!.canBeEdited) {
      errors.add('This expense is too old to be edited (older than 30 days)');
    }

    // Date validation
    final now = DateTime.now();
    final maxFutureDate = now.add(const Duration(days: 1));
    final maxPastDate = now.subtract(const Duration(days: 365));
    
    if (_selectedDate.isAfter(maxFutureDate)) {
      errors.add('Date cannot be more than 1 day in the future');
    }
    if (_selectedDate.isBefore(maxPastDate)) {
      errors.add('Date cannot be more than 1 year in the past');
    }

    // Amount validation
    final newTotal = double.tryParse(_totalController.text) ?? 0.0;
    if (newTotal <= 0) {
      errors.add('Total amount must be greater than zero');
    }
    if (newTotal > 999999.99) {
      errors.add('Total amount cannot exceed 999,999.99');
    }

    // Notes validation
    if (_notesController.text.length > 500) {
      errors.add('Notes cannot exceed 500 characters');
    }

    // Currency validation
    if (_selectedCurrency == null || _selectedCurrency!.code.isEmpty) {
      errors.add('Please select a valid currency');
    }

    return errors;
  }

  /// Validate data consistency between form fields
  List<String> _validateDataConsistency() {
    final errors = <String>[];

    // Check if selected members exist in participant amounts
    final participantNames = _expense?.participantAmounts.map((p) => p.name).toSet() ?? <String>{};
    final invalidMembers = _selectedMembers.where((member) => !participantNames.contains(member));
    if (invalidMembers.isNotEmpty) {
      errors.add('Some selected members are no longer in the group');
    }

    // Check for duplicate member names
    final duplicateMembers = <String>[];
    final seenMembers = <String>{};
    for (final member in _selectedMembers) {
      if (seenMembers.contains(member)) {
        duplicateMembers.add(member);
      } else {
        seenMembers.add(member);
      }
    }
    if (duplicateMembers.isNotEmpty) {
      errors.add('Duplicate members found: ${duplicateMembers.join(', ')}');
    }

    return errors;
  }

  /// Display validation errors to the user with improved UX
  void _showValidationErrors(List<String> errors) {
    if (errors.isEmpty) return;

    // Show the first error as a snackbar for immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(errors.first)),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: errors.length > 1 ? SnackBarAction(
          label: 'View All',
          textColor: Colors.white,
          onPressed: () => _showAllValidationErrors(errors),
        ) : null,
      ),
    );

    // If multiple errors, also show them in a dialog
    if (errors.length > 1) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _showAllValidationErrors(errors);
        }
      });
    }
  }

  /// Show all validation errors in a dialog
  void _showAllValidationErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.orange[700]),
              SizedBox(width: 8),
              Text('Validation Errors'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: errors.map((error) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(error)),
                  ],
                ),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Legacy validation methods - kept for backward compatibility
  /// These are now replaced by comprehensive validation but maintained
  /// to avoid breaking existing code paths
  bool _validateBusinessRules() {
    final errors = _validateBusinessRulesComprehensive();
    if (errors.isNotEmpty) {
      _showValidationErrors(errors);
      return false;
    }
    return true;
  }

  bool _validateSplitOptions() {
    final errors = _validateSplitOptionsComprehensive();
    if (errors.isNotEmpty) {
      _showValidationErrors(errors);
      return false;
    }
    return true;
  }

  List<ParticipantAmount> _calculateParticipantAmounts(double totalAmount) {
    switch (_splitType) {
      case 'equal':
        if (_selectedMembers.isEmpty) {
          // Fallback to original participant amounts if no members are selected
          return _expense?.participantAmounts ?? [];
        }
        final amountPerPerson = totalAmount / _selectedMembers.length;
        return _selectedMembers.map((memberName) {
          // Find the group member ID for this name
          final groupMember = _groupMembers.firstWhere(
            (member) => member['name'] == memberName,
            orElse: () => <String, dynamic>{'id': 0, 'name': memberName},
          );
          return ParticipantAmount(
            name: memberName,
            amount: amountPerPerson,
            groupMemberId: groupMember['id'] as int?,
          );
        }).toList();
      case 'percentage':
        if (_memberPercentages.isEmpty) {
          // Fallback to original participant amounts if no percentages are set
          return _expense?.participantAmounts ?? [];
        }
        return _memberPercentages.entries.map((entry) {
          final memberName = entry.key;
          final percentage = entry.value;
          final amount = totalAmount * (percentage / 100.0);
          
          // Find the group member ID for this name
          final groupMember = _groupMembers.firstWhere(
            (member) => member['name'] == memberName,
            orElse: () => <String, dynamic>{'id': 0, 'name': memberName},
          );
          
          return ParticipantAmount(
            name: memberName,
            amount: amount,
            percentage: percentage.toDouble(),
            groupMemberId: groupMember['id'] as int?,
          );
        }).toList();
      case 'custom':
        if (_customAmounts.isEmpty) {
          // Fallback to original participant amounts if no custom amounts are set
          return _expense?.participantAmounts ?? [];
        }
        return _customAmounts.entries.map((entry) {
          final memberName = entry.key;
          final amount = entry.value;
          final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0;
          
          // Find the group member ID for this name
          final groupMember = _groupMembers.firstWhere(
            (member) => member['name'] == memberName,
            orElse: () => <String, dynamic>{'id': 0, 'name': memberName},
          );
          
          return ParticipantAmount(
            name: memberName,
            amount: amount,
            percentage: percentage.toDouble(),
            groupMemberId: groupMember['id'] as int?,
          );
        }).toList();
      default:
        return _expense?.participantAmounts ?? [];
    }
  }

  /// Create payer data for backend update
  List<Map<String, dynamic>> _createPayerData(double totalAmount) {
    print('Creating payer data. Selected payer ID: $_selectedPayerId');
    print('Available group members: ${_groupMembers.map((m) => '${m['id']}:${m['name']}').join(', ')}');
    
    // Find the selected payer in group members
    Map<String, dynamic> selectedPayer;
    try {
      selectedPayer = _groupMembers.firstWhere(
        (member) => member['id'] == _selectedPayerId,
      );
      print('Found selected payer: ${selectedPayer['name']} (ID: ${selectedPayer['id']})');
    } catch (_) {
      // If not found, use first member or create a default
      selectedPayer = _groupMembers.isNotEmpty 
          ? _groupMembers.first 
          : <String, dynamic>{'id': 0, 'name': 'Unknown'};
      print('Payer not found, using fallback: ${selectedPayer['name']} (ID: ${selectedPayer['id']})');
    }
    
    final payerData = [
      {
        'group_member_id': selectedPayer['id'],
        'amount_paid': totalAmount,
        'payment_method': 'unknown',
        'payment_date': DateTime.now().toIso8601String(),
      }
    ];
    
    print('Created payer data: $payerData');
    return payerData;
  }

  /// Save expense with automatic retry mechanism for transient failures
  Future<ExpenseDetailModel> _saveWithRetry(ExpenseUpdateRequest request, {int maxRetries = 3}) async {
    int retryCount = 0;
    Duration retryDelay = Duration(seconds: 1);

    // Log the request data for debugging
    print('Sending update request: ${request.toJson()}');

    while (retryCount < maxRetries) {
      try {
        return await ExpenseDetailService.updateExpense(request);
      } on NetworkException catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          rethrow;
        }
        
        // Show retry attempt to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Network error, retrying... (${retryCount}/$maxRetries)'),
              duration: retryDelay,
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        await Future.delayed(retryDelay);
        retryDelay = Duration(seconds: retryDelay.inSeconds * 2); // Exponential backoff
      } on ExpenseDetailServiceException catch (e) {
        // Don't retry service exceptions (validation errors, etc.)
        rethrow;
      }
    }
    
    throw NetworkException('Failed to save after $maxRetries attempts');
  }

  /// Handle service-specific errors with appropriate user feedback
  void _handleServiceError(ExpenseDetailServiceException e) {
    String userMessage;
    SnackBarAction? action;

    // Categorize service errors for better user experience
    if (e.message.contains('validation')) {
      userMessage = 'Validation failed: ${e.message}';
    } else if (e.message.contains('permission')) {
      userMessage = 'You don\'t have permission to edit this expense';
    } else if (e.message.contains('not found')) {
      userMessage = 'Expense not found. It may have been deleted.';
      action = SnackBarAction(
        label: 'Refresh',
        onPressed: _loadExpenseData,
      );
    } else if (e.message.contains('conflict')) {
      userMessage = 'Expense was modified by someone else. Please refresh and try again.';
      action = SnackBarAction(
        label: 'Refresh',
        onPressed: _loadExpenseData,
      );
    } else {
      userMessage = 'Failed to save: ${e.message}';
      action = SnackBarAction(
        label: 'Retry',
        onPressed: _saveChanges,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(userMessage)),
            ],
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          action: action,
        ),
      );
    }
  }

  /// Handle network errors with retry options
  void _handleNetworkError(NetworkException e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('Network error: ${e.message}')),
            ],
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _saveChanges,
          ),
        ),
      );
    }
  }

  /// Handle unexpected errors with debugging information
  void _handleUnexpectedError(dynamic error) {
    // Log error for debugging (in production, this would go to crash reporting)
    print('Unexpected error in expense detail save: $error');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.bug_report, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('An unexpected error occurred. Please try again.')),
            ],
          ),
          backgroundColor: Colors.red[800],
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _saveChanges,
          ),
        ),
      );
    }
  }

  /// Get appropriate error title based on error message
  String _getErrorTitle() {
    if (_errorMessage?.contains('not found') == true) {
      return 'Expense Not Found';
    } else if (_errorMessage?.contains('permission') == true) {
      return 'Access Denied';
    } else if (_errorMessage?.contains('network') == true || _errorMessage?.contains('connection') == true) {
      return 'Connection Error';
    } else {
      return 'Loading Failed';
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_expense == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Expense Detail'),
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _errorMessage?.contains('not found') == true 
                        ? Icons.search_off
                        : _errorMessage?.contains('permission') == true
                            ? Icons.lock_outline
                            : Icons.error_outline,
                    size: 48,
                    color: AppTheme.lightTheme.colorScheme.error,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _getErrorTitle(),
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  _errorMessage ?? 'Expense not found',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!(_errorMessage?.contains('not found') == true || 
                          _errorMessage?.contains('permission') == true))
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _loadExpenseDataWithRetry(),
                          icon: Icon(Icons.refresh),
                          label: Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                          ),
                        ),
                      ),
                    if (!(_errorMessage?.contains('not found') == true || 
                          _errorMessage?.contains('permission') == true))
                      SizedBox(width: 4.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back),
                        label: Text('Go Back'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !(_isEditMode && _hasUnsavedChanges()),
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isEditMode && _hasUnsavedChanges()) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Discard Changes?'),
                content: const Text('You have unsaved changes. Are you sure you want to leave without saving?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Stay'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Discard'),
                  ),
                ],
              );
            },
          );
          if (shouldPop == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Header
                    ExpenseDetailHeader(
                      isEditMode: _isEditMode,
                      isSaving: _isSaving,
                      onEditPressed: _toggleEditMode,
                      onSavePressed: _saveChanges,
                      onCancelPressed: _cancelEdit,
                      onBackPressed: () async {
                        if (_isEditMode && _hasUnsavedChanges()) {
                          final shouldPop = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Discard Changes?'),
                                content: const Text('You have unsaved changes. Are you sure you want to leave without saving?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Stay'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Discard'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (shouldPop == true) {
                            Navigator.pop(context);
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),

                    // Scrollable Content
                    Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Receipt Image (if available)
                      if (_expense!.hasReceiptImage)
                        ReceiptImageWidget(
                          imageUrl: _expense!.receiptImageUrl!,
                        ),

                      if (_expense!.hasReceiptImage) SizedBox(height: 3.h),

                      // Expense Details
                      ExpenseDetailsWidget(
                        key: ValueKey('expense_details_${_selectedPayerId}_${_groupMembers.length}'),
                        selectedGroup: _selectedGroup,
                        selectedCategory: _selectedCategory,
                        selectedDate: _selectedDate,
                        notesController: _notesController,
                        groups: [_groupName], // Use the actual group name instead of the generic one
                        categories: _categories,
                        onGroupChanged: null, // Group is locked in edit mode per requirements
                        onCategoryChanged: _isEditMode 
                            ? (value) => setState(() => _selectedCategory = value)
                            : null,
                        onDateTap: _isEditMode ? _selectDate : null,
                        totalController: _totalController,
                        currency: _selectedCurrency,
                        onCurrencyChanged: _isEditMode ? (currency) {
                          setState(() => _selectedCurrency = currency);
                          if (currency != null) {
                            _showCurrencyChangeFeedback(currency);
                          }
                        } : null,
                        mode: 'detail',
                        isReceiptMode: false,
                        receiptModeConfig: null,
                        isReadOnly: !_isEditMode,
                        // Add payer selection parameters
                        selectedPayerId: _getValidPayerId(),
                        onPayerChanged: _isEditMode ? (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPayerId = int.tryParse(value) ?? 0;
                            });
                          }
                        } : null,
                        groupMembers: _groupMembers,
                        isLoadingPayers: false,
                        titleController: _titleController,
                      ),

                      SizedBox(height: 3.h),

                      // Debug logging for split options
                      Builder(
                        builder: (context) {
                          print('Building SplitOptionsWidget:');
                          print('  Split type: $_splitType');
                          print('  Member percentages: $_memberPercentages');
                          print('  Group members count: ${_groupMembers.length}');
                          print('  Is edit mode: $_isEditMode');
                          print('  Participant amounts: ${_expense!.participantAmounts.map((p) => '${p.name}: ${p.percentage}%').join(', ')}');
                          return SizedBox.shrink();
                        },
                      ),

                      // Split Options
                      SplitOptionsWidget(
                        key: ValueKey('split_options_${_splitType}_${_memberPercentages.length}_${_isEditMode}'),
                        splitType: _splitType,
                        onSplitTypeChanged: _isEditMode 
                            ? (value) => _onSplitTypeChanged(value)
                            : null,
                        groupMembers: _groupMembers.isNotEmpty 
                            ? _groupMembers 
                            : _expense!.participantAmounts.map((p) => {
                                'id': p.name.hashCode,
                                'name': p.name,
                                'avatar': '', // No avatar data in expense detail model
                              }).toList(),
                        totalAmount: double.tryParse(_totalController.text) ?? _totalAmount,
                        currency: _selectedCurrency ?? _expense!.currency,
                        isReceiptMode: false,
                        prefilledCustomAmounts: _splitType == 'custom' ? _customAmounts : null,
                        selectedMembers: _selectedMembers,
                        memberPercentages: _splitType == 'percentage' ? _memberPercentages : null,
                        onMembersChanged: _isEditMode ? (members) {
                          setState(() => _selectedMembers = members);
                        } : null,
                        onPercentagesChanged: _isEditMode ? (percentages) {
                          setState(() => _memberPercentages = percentages);
                        } : null,
                        onCustomAmountsChanged: _isEditMode ? (amounts) {
                          setState(() => _customAmounts = amounts);
                        } : null,
                        isReadOnly: !_isEditMode,
                      ),

                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
                ),
                  ],
                ),
              ),
              
              // Enhanced loading overlay during save operations
              if (_isSaving)
                Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      margin: EdgeInsets.symmetric(horizontal: 10.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.lightTheme.colorScheme.primary,
                            ),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Saving changes...',
                            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Please don\'t close the app',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.secondary,
                            ),
                          ),
                        ],
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
}