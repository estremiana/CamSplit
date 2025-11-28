import 'package:flutter/material.dart';
import 'models/wizard_expense_data.dart';
import 'models/split_type.dart';
import 'widgets/step_amount_page.dart';
import 'widgets/step_details_page.dart';
import 'widgets/step_split_page.dart';
import '../../services/api_service.dart';

/// Main wizard screen container that manages the three-page expense creation flow
/// Handles navigation between pages and maintains shared state
class ExpenseWizardScreen extends StatefulWidget {
  const ExpenseWizardScreen({super.key});

  @override
  State<ExpenseWizardScreen> createState() => _ExpenseWizardScreenState();
}

class _ExpenseWizardScreenState extends State<ExpenseWizardScreen> {
  // PageView controller for managing page navigation
  late final PageController _pageController;
  
  // Current page index (0-2 for the three wizard pages)
  int _currentPage = 0;
  
  // Shared wizard state across all pages
  late WizardExpenseData _wizardData;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _wizardData = WizardExpenseData(); // Initialize with default values
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  /// Navigate to a specific page by index
  void navigateToPage(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < 3) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      setState(() {
        _currentPage = pageIndex;
      });
    }
  }
  
  /// Navigate to the next page
  void goNext() {
    if (_currentPage < 2) {
      navigateToPage(_currentPage + 1);
    }
  }
  
  /// Navigate to the previous page
  void goBack() {
    if (_currentPage > 0) {
      navigateToPage(_currentPage - 1);
    }
  }
  
  /// Update wizard data and trigger rebuild
  void updateWizardData(WizardExpenseData newData) {
    setState(() {
      _wizardData = newData;
    });
  }
  
  /// Show discard confirmation dialog
  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Discard Expense?'),
          content: const Text(
            'Are you sure you want to discard this expense? All entered data will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
  
  /// Handle discard action with confirmation
  Future<void> discardWizard() async {
    final shouldDiscard = await _showDiscardDialog();
    if (shouldDiscard && mounted) {
      Navigator.of(context).pop();
    }
  }
  
  /// Submit the expense to the backend
  Future<void> submitExpense() async {
    // Show loading dialog
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: const CircularProgressIndicator(),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: child,
                    );
                  },
                  child: const Text(
                    'Creating Expense...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: child,
                    );
                  },
                  child: const Text(
                    'Notifying the group',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    try {
      // Import API service at the top of the file
      final apiService = ApiService.instance;
      
      // Create expense payload from wizard data
      final payload = _createExpensePayload();
      
      // Call backend API to create expense
      final response = await apiService.createExpense(payload);
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Handle success
      if (response['success'] == true) {
        if (mounted) {
          // Navigate back to previous screen
          Navigator.of(context).pop();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Handle unexpected response format
        _showErrorDialog('Failed to create expense. Please try again.');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Handle failure
      _showErrorDialog(e.toString());
    }
  }
  
  /// Create expense payload from wizard data
  Map<String, dynamic> _createExpensePayload() {
    final payload = <String, dynamic>{
      'group_id': _wizardData.groupId,
      'amount': _wizardData.amount,
      'description': _wizardData.title,
      'date': _wizardData.date,
      'category': _wizardData.category,
      'payer_id': _wizardData.payerId,
    };
    
    // Add notes if present
    if (_wizardData.notes != null && _wizardData.notes!.isNotEmpty) {
      payload['notes'] = _wizardData.notes;
    }
    
    // Add split type and details based on the split mode
    switch (_wizardData.splitType) {
      case SplitType.equal:
        payload['split_type'] = 'equal';
        payload['split_equally'] = true;
        payload['participants'] = _wizardData.involvedMembers;
        break;
        
      case SplitType.percentage:
        payload['split_type'] = 'percentage';
        payload['split_equally'] = false;
        // Convert percentage splits to participant amounts
        final splits = <Map<String, dynamic>>[];
        _wizardData.splitDetails.forEach((memberId, percentage) {
          final amount = (_wizardData.amount * percentage) / 100.0;
          splits.add({
            'participant_id': memberId,
            'amount': amount,
            'percentage': percentage,
          });
        });
        payload['splits'] = splits;
        break;
        
      case SplitType.custom:
        payload['split_type'] = 'custom';
        payload['split_equally'] = false;
        // Convert custom amounts to participant splits
        final splits = <Map<String, dynamic>>[];
        _wizardData.splitDetails.forEach((memberId, amount) {
          splits.add({
            'participant_id': memberId,
            'amount': amount,
          });
        });
        payload['splits'] = splits;
        break;
        
      case SplitType.items:
        payload['split_type'] = 'items';
        payload['split_equally'] = false;
        
        // Add items with their assignments
        final items = <Map<String, dynamic>>[];
        for (final item in _wizardData.items) {
          items.add({
            'name': item.name,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'total_price': item.price,
            'assignments': item.assignments.map((memberId, qty) {
              return MapEntry(memberId, {
                'quantity': qty,
                'amount': qty * item.unitPrice,
              });
            }),
          });
        }
        payload['items'] = items;
        
        // Calculate splits from item assignments
        final memberTotals = <String, double>{};
        for (final item in _wizardData.items) {
          item.assignments.forEach((memberId, qty) {
            memberTotals[memberId] = (memberTotals[memberId] ?? 0.0) + (qty * item.unitPrice);
          });
        }
        
        final splits = <Map<String, dynamic>>[];
        memberTotals.forEach((memberId, amount) {
          splits.add({
            'participant_id': memberId,
            'amount': amount,
          });
        });
        payload['splits'] = splits;
        break;
    }
    
    // Add receipt image if present
    if (_wizardData.receiptImage != null && _wizardData.receiptImage!.isNotEmpty) {
      payload['receipt_image'] = _wizardData.receiptImage;
    }
    
    return payload;
  }
  
  /// Show error dialog with retry option
  void _showErrorDialog(String errorMessage) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error Creating Expense'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                submitExpense(); // Retry
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }
  
  /// Handle back button press
  Future<bool> _onWillPop() async {
    if (_currentPage > 0) {
      // If not on first page, go back to previous page
      goBack();
      return false;
    } else {
      // If on first page, show discard dialog
      return await _showDiscardDialog();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Expense'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: discardWizard,
          ),
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            // Page 1: Amount & Scan
            StepAmountPage(
              wizardData: _wizardData,
              onNext: goNext,
              onDiscard: discardWizard,
              onDataChanged: updateWizardData,
            ),
            
            // Page 2: Details
            StepDetailsPage(
              wizardData: _wizardData,
              onNext: goNext,
              onBack: goBack,
              onDataChanged: updateWizardData,
            ),
            
            // Page 3: Split Options
            StepSplitPage(
              wizardData: _wizardData,
              onBack: goBack,
              onDataChanged: updateWizardData,
              onSubmit: submitExpense,
            ),
          ],
        ),
      ),
    );
  }
}
