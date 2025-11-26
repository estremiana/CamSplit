import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../models/receipt_item.dart';
import '../../services/api_service.dart';
import '../../services/group_service.dart';
import 'steps/expense_wizard_step_amount.dart';
import 'steps/expense_wizard_step_details.dart';
import 'steps/expense_wizard_step_split.dart';

/// Split type enum matching the reference implementation
enum SplitType {
  equal,
  percentage,
  custom,
  itemized,
}

/// Main wizard container that manages state and navigation between steps
class ExpenseWizard extends StatefulWidget {
  const ExpenseWizard({super.key});

  @override
  State<ExpenseWizard> createState() => _ExpenseWizardState();
}

class _ExpenseWizardState extends State<ExpenseWizard> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Wizard data state
  double _amount = 0.0;
  String _title = '';
  String? _receiptImage; // base64 or file path
  List<ReceiptItem> _items = [];
  
  String? _groupId;
  String? _payerId;
  DateTime _date = DateTime.now();
  String _category = 'Food & Dining';
  
  SplitType _splitType = SplitType.equal;
  Map<String, double> _splitDetails = {}; // memberId -> amount/percentage
  List<String> _involvedMembers = []; // For equal split
  
  // Groups and members
  List<Group> _groups = [];
  List<Map<String, dynamic>> _groupMembers = [];
  bool _isLoadingGroups = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoadingGroups = true;
    });

    try {
      final groups = await GroupService.getAllGroups();
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoadingGroups = false;
          
          // Set default group if available
          if (groups.isNotEmpty && _groupId == null) {
            _groupId = groups.first.id.toString();
            _loadGroupMembers(_groupId!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load groups: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadGroupMembers(String groupId) async {
    try {
      final group = await GroupService.getGroupWithMembers(groupId);
      if (mounted && group != null) {
        final currentUserId = await ApiService.instance.getUserId();
        
        setState(() {
          _groupMembers = group.members.map((member) {
            final isCurrentUser = member.userId != null && 
                                 currentUserId != null && 
                                 member.userId.toString() == currentUserId;
            
            return {
              'id': member.id.toString(),
              'name': member.nickname,
              'avatar': _getInitials(member.nickname),
              'email': member.email ?? '',
              'isCurrentUser': isCurrentUser,
            };
          }).toList();
          
          // Set default payer to current user
          if (_payerId == null && _groupMembers.isNotEmpty) {
            final currentUser = _groupMembers.firstWhere(
              (m) => m['isCurrentUser'] == true,
              orElse: () => _groupMembers.first,
            );
            _payerId = currentUser['id'].toString();
          }
          
          // Initialize involved members for equal split
          if (_splitType == SplitType.equal && _involvedMembers.isEmpty) {
            _involvedMembers = _groupMembers.map((m) => m['id'].toString()).toList();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading group members: $e');
    }
  }

  String _getInitials(String name) {
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    return '${nameParts[0].substring(0, 1)}${nameParts[1].substring(0, 1)}'.toUpperCase();
  }

  void _updateAmount(double amount) {
    setState(() {
      _amount = amount;
    });
  }

  void _updateTitle(String title) {
    setState(() {
      _title = title;
    });
  }

  void _updateReceiptData(Map<String, dynamic> data) {
    setState(() {
      if (data.containsKey('receiptImage')) _receiptImage = data['receiptImage'];
      if (data.containsKey('items')) _items = data['items'] as List<ReceiptItem>? ?? [];
      if (data.containsKey('amount')) _amount = data['amount'] as double? ?? 0.0;
      if (data.containsKey('title')) _title = data['title'] as String? ?? '';
      if (data.containsKey('date')) {
        try {
          final dateStr = data['date'] as String?;
          if (dateStr != null) {
            _date = DateTime.parse(dateStr);
          }
        } catch (e) {
          debugPrint('Error parsing date: $e');
        }
      }
      if (data.containsKey('category')) _category = data['category'] as String? ?? '';
    });
  }

  void _updateDetails(Map<String, dynamic> data) {
    setState(() {
      if (data.containsKey('groupId')) {
        final groupId = data['groupId'] as String?;
        if (groupId != null) {
          _groupId = groupId;
          _loadGroupMembers(groupId);
        }
      }
      if (data.containsKey('payerId')) _payerId = data['payerId'] as String?;
      if (data.containsKey('date')) {
        final date = data['date'];
        if (date is DateTime) {
          _date = date;
        }
      }
      if (data.containsKey('category')) _category = data['category'] as String? ?? '';
    });
  }

  void _updateSplit(Map<String, dynamic> data) {
    setState(() {
      if (data.containsKey('splitType')) {
        final splitType = data['splitType'];
        if (splitType is SplitType) {
          _splitType = splitType;
        }
      }
      if (data.containsKey('splitDetails')) {
        final splitDetails = data['splitDetails'];
        if (splitDetails is Map<String, double>) {
          _splitDetails = splitDetails;
        }
      }
      if (data.containsKey('involvedMembers')) {
        final involvedMembers = data['involvedMembers'];
        if (involvedMembers is List<String>) {
          _involvedMembers = involvedMembers;
        }
      }
      if (data.containsKey('items')) {
        final items = data['items'];
        if (items is List<ReceiptItem>) {
          _items = items;
        }
      }
      if (data.containsKey('amount')) {
        final amount = data['amount'];
        if (amount is double) {
          _amount = amount;
        }
      }
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _canProceedFromStep1() {
    return _amount > 0 || _items.isNotEmpty;
  }

  bool _canProceedFromStep2() {
    return _groupId != null && _payerId != null && _category.isNotEmpty;
  }

  bool _canProceedFromStep3() {
    if (_splitType == SplitType.itemized) {
      // Check if all items are assigned
      final unassigned = _items.fold(0.0, (sum, item) => sum + item.getRemainingQuantity() * item.unitPrice);
      return unassigned < 0.05;
    } else if (_splitType == SplitType.percentage) {
      final total = _splitDetails.values.fold(0.0, (sum, val) => sum + val);
      return (100 - total).abs() < 0.1;
    } else if (_splitType == SplitType.custom) {
      final total = _splitDetails.values.fold(0.0, (sum, val) => sum + val);
      return (_amount - total).abs() < 0.05;
    }
    return true; // Equal split is always valid
  }

  Future<void> _submitExpense() async {
    if (!_canProceedFromStep3()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields before creating the expense'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Build expense data
      final expenseData = <String, dynamic>{
        'title': _title.isNotEmpty ? _title : 'Expense',
        'total_amount': _amount,
        'currency': _groups.isNotEmpty && _groupId != null
            ? _groups.firstWhere(
                (g) => g.id.toString() == _groupId,
                orElse: () => _groups.first,
              ).currency.code
            : 'EUR',
        'date': _date.toIso8601String().split('T')[0],
        'category': _category,
        'group_id': int.parse(_groupId!),
        'split_type': _getSplitTypeString(_splitType),
        'payers': [
          {
            'group_member_id': int.parse(_payerId!),
            'amount_paid': _amount,
            'payment_method': 'unknown',
          }
        ],
        'splits': _buildSplitsData(),
      };

      // Add receipt image if available
      if (_receiptImage != null) {
        // If it's a file path, upload it first
        if (!_receiptImage!.startsWith('http') && !_receiptImage!.startsWith('data:')) {
          try {
            final imageFile = await File(_receiptImage!).readAsBytes();
            // Upload to Cloudinary via API
            final uploadResponse = await ApiService.instance.processReceipt(File(_receiptImage!));
            if (uploadResponse['success'] == true && uploadResponse['data'] != null) {
              expenseData['receipt_image_url'] = uploadResponse['data']['image_url'];
            }
          } catch (e) {
            debugPrint('Error uploading receipt image: $e');
          }
        } else {
          expenseData['receipt_image_url'] = _receiptImage;
        }
      }

      // Add items if in itemized mode
      if (_splitType == SplitType.itemized && _items.isNotEmpty) {
        expenseData['items'] = _items.map((item) {
          // Build assignments for this item
          // Group members by assignment type and quantity to optimize
          final simpleAssignments = <String, double>{};
          final advancedAssignments = <String, double>{};
          
          item.assignments.forEach((memberId, quantity) {
            if (quantity > 0) {
              if (item.isCustomSplit) {
                advancedAssignments[memberId] = quantity;
              } else {
                simpleAssignments[memberId] = quantity;
              }
            }
          });
          
          final assignments = <Map<String, dynamic>>[];
          
          // Create assignments for simple mode (group members with same quantity)
          if (simpleAssignments.isNotEmpty) {
            // Group by quantity
            final quantityGroups = <double, List<String>>{};
            simpleAssignments.forEach((memberId, qty) {
              quantityGroups.putIfAbsent(qty, () => []).add(memberId);
            });
            
            quantityGroups.forEach((qty, memberIds) {
              final totalPrice = item.unitPrice * qty;
              assignments.add({
                'assignment_type': 'simple',
                'quantity': qty,
                'user_ids': memberIds.map((id) => int.parse(id)).toList(),
                'unit_price': item.unitPrice,
                'total_price': totalPrice,
                'people_count': memberIds.length,
                'price_per_person': totalPrice / memberIds.length,
              });
            });
          }
          
          // Create assignments for advanced mode (one per member)
          if (advancedAssignments.isNotEmpty) {
            advancedAssignments.forEach((memberId, quantity) {
              final totalPrice = item.unitPrice * quantity;
              assignments.add({
                'assignment_type': 'advanced',
                'quantity': quantity,
                'user_ids': [int.parse(memberId)],
                'unit_price': item.unitPrice,
                'total_price': totalPrice,
                'people_count': 1,
                'price_per_person': totalPrice,
              });
            });
          }

          return {
            'name': item.name,
            'unit_price': item.unitPrice,
            'max_quantity': item.quantity,
            'total_price': item.totalPrice,
            'assignments': assignments,
          };
        }).toList();
      }

      // Create expense
      final response = await ApiService.instance.createExpense(expenseData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back
        Navigator.pop(context, {'success': true, 'expense': response['data']});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSplitTypeString(SplitType type) {
    switch (type) {
      case SplitType.equal:
        return 'equal';
      case SplitType.percentage:
        return 'percentage';
      case SplitType.custom:
        return 'custom';
      case SplitType.itemized:
        return 'itemized';
    }
  }

  List<Map<String, dynamic>> _buildSplitsData() {
    if (_splitType == SplitType.itemized) {
      // For itemized, splits are calculated from item assignments
      final memberAmounts = <String, double>{};
      
      _items.forEach((item) {
        item.assignments.forEach((memberId, quantity) {
          if (quantity > 0) {
            final amount = quantity * item.unitPrice;
            memberAmounts[memberId] = (memberAmounts[memberId] ?? 0.0) + amount;
          }
        });
      });
      
      return memberAmounts.entries.map((entry) {
        return {
          'group_member_id': int.parse(entry.key),
          'amount_owed': double.parse(entry.value.toStringAsFixed(2)),
        };
      }).toList();
    } else if (_splitType == SplitType.equal) {
      if (_involvedMembers.isEmpty) return [];
      final memberCount = _involvedMembers.length;
      final amountPerMember = _amount / memberCount;
      
      return _involvedMembers.map((memberId) {
        return {
          'group_member_id': int.parse(memberId),
          'amount_owed': double.parse(amountPerMember.toStringAsFixed(2)),
        };
      }).toList();
    } else {
      // Percentage or Custom
      return _splitDetails.entries
          .where((entry) => entry.value > 0)
          .map((entry) {
            return {
              'group_member_id': int.parse(entry.key),
              'amount_owed': double.parse(entry.value.toStringAsFixed(2)),
              if (_splitType == SplitType.percentage) 
                'percentage': double.parse(entry.value.toStringAsFixed(1)),
            };
          }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Creating Expense...',
                style: AppTheme.lightTheme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Notifying the group',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Container(
              height: 2,
              color: Colors.grey[100],
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_currentStep + 1) / 3,
                child: Container(
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
            ),
            
            // Step content
            Expanded(
              child: _currentStep == 0
                  ? ExpenseWizardStepAmount(
                      amount: _amount,
                      title: _title,
                      receiptImage: _receiptImage,
                      items: _items,
                      onAmountChanged: _updateAmount,
                      onTitleChanged: _updateTitle,
                      onReceiptDataChanged: _updateReceiptData,
                      onNext: _canProceedFromStep1() ? _nextStep : null,
                      onCancel: () => Navigator.pop(context),
                    )
                  : _currentStep == 1
                      ? ExpenseWizardStepDetails(
                          groups: _groups,
                          groupMembers: _groupMembers,
                          selectedGroupId: _groupId,
                          selectedPayerId: _payerId,
                          selectedDate: _date,
                          selectedCategory: _category,
                          isLoadingGroups: _isLoadingGroups,
                          onDetailsChanged: _updateDetails,
                          onNext: _canProceedFromStep2() ? _nextStep : null,
                          onBack: _previousStep,
                        )
                      : ExpenseWizardStepSplit(
                          amount: _amount,
                          splitType: _splitType,
                          splitDetails: _splitDetails,
                          involvedMembers: _involvedMembers,
                          items: _items,
                          groupMembers: _groupMembers,
                          onSplitChanged: _updateSplit,
                          onSubmit: _canProceedFromStep3() ? _submitExpense : null,
                          onBack: _previousStep,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

