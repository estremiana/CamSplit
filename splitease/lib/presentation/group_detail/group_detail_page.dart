import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/group_detail_model.dart';
import '../../models/group_member.dart';
import '../../services/group_detail_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/loading_overlay.dart';
import '../../utils/error_recovery.dart';
import '../../utils/real_time_updates.dart';
import '../../widgets/loading_states.dart';
import 'widgets/group_header_widget.dart';
import 'widgets/balance_summary_widget.dart';
import 'widgets/expense_list_widget.dart';
import 'widgets/participant_list_widget.dart';
import 'widgets/settlements_widget.dart';
import 'widgets/group_actions_widget.dart';

class GroupDetailPage extends StatefulWidget {
  final int groupId;

  const GroupDetailPage({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> with RealTimeUpdateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isOptimisticUpdate = false;
  GroupDetailModel? _groupDetail;
  String? _errorMessage;
  final LoadingOverlayManager _loadingOverlay = LoadingOverlayManager();
  
  // Retry mechanism
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  // New group handling
  bool _isNewGroup = false;
  bool _hasShownWelcomeMessage = false;

  @override
  void initState() {
    super.initState();
    // Initialize real-time updates
    initializeRealTimeUpdates(widget.groupId);
    _loadGroupData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we're returning from expense creation and need to refresh
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    // Handle new group navigation
    if (args?['isNewGroup'] == true && !_isNewGroup) {
      setState(() {
        _isNewGroup = true;
      });
      
      // Show welcome message for new groups
      if (!_hasShownWelcomeMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showWelcomeMessage();
          _hasShownWelcomeMessage = true;
        });
      }
    }
    
    if (args?['refreshOnReturn'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshData();
      });
    }
  }

  Future<void> _loadGroupData({bool showLoading = true}) async {
    if (mounted) {
      setState(() {
        _isLoading = showLoading;
        _errorMessage = null;
      });
    }

    try {
      final groupDetail = await ErrorRecovery.executeWithRetry(
        operation: () => GroupDetailService.getGroupDetailsWithRetry(widget.groupId),
        context: context,
        operationName: 'load group details',
        retryType: 'network',
        onSuccess: (result) {
          // Notify real-time update listeners
          notifyGroupUpdate(result);
        },
      );
      
      if (groupDetail != null && mounted) {
        setState(() {
          _groupDetail = groupDetail;
          _isLoading = false;
          _retryCount = 0; // Reset retry count on success
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        _handleLoadError(e);
      }
    }
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    }

    try {
      final groupDetail = await GroupDetailService.refreshGroupDetails(widget.groupId);
      
      if (mounted) {
        setState(() {
          _groupDetail = groupDetail;
          _isRefreshing = false;
          _retryCount = 0; // Reset retry count on success
        });
        
        // Show success feedback for manual refresh
        SnackBarUtils.showSuccess(context, 'Group details updated');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isRefreshing = false;
        });
        _handleLoadError(e);
      }
    }
  }

  /// Handle loading errors with retry mechanism
  void _handleLoadError(dynamic error) {
    if (!mounted) return;

    ErrorRecovery.handleError(
      context,
      error,
      'load group details',
      showRetryButton: ErrorRecovery.isRecoverableError(error),
      onRetry: () {
        setState(() {
          _retryCount = 0;
          _errorMessage = null;
        });
        _loadGroupData(showLoading: false);
      },
    );
  }

  /// Show welcome message for newly created groups
  void _showWelcomeMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.celebration,
              color: AppTheme.lightTheme.primaryColor,
              size: 24,
            ),
            SizedBox(width: 2.w),
            Text('Welcome to Your New Group!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your group has been created successfully. Here\'s what you can do next:',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            _buildWelcomeStep('Add your first expense', Icons.add_shopping_cart),
            _buildWelcomeStep('Invite friends to join', Icons.person_add),
            _buildWelcomeStep('Set up group settings', Icons.settings),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _onAddExpense();
            },
            child: Text('Add First Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.lightTheme.primaryColor,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle back navigation with state preservation
  Future<bool> _onWillPop() async {
    // If this is a new group, navigate back to groups page with refresh flag
    if (_isNewGroup) {
      Navigator.pop(context);
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.groupManagement,
        arguments: {
          'newGroupCreated': true,
          'successMessage': 'Group created successfully! You can now add expenses and invite members.',
        },
      );
      return false; // Prevent default back behavior
    }
    
    // For existing groups, preserve state and navigate back normally
    return true;
  }

  /// Optimistic update for expense creation
  void _optimisticExpenseUpdate(GroupExpense newExpense) {
    if (_groupDetail != null) {
      setState(() {
        _isOptimisticUpdate = true;
        // Add the new expense to the beginning of the list
        _groupDetail = _groupDetail!.copyWith(
          expenses: [newExpense, ..._groupDetail!.expenses],
        );
      });
      
      // Apply optimistic update to real-time system
      RealTimeUpdates.applyOptimisticExpenseUpdate(widget.groupId, newExpense);
      
      // Show optimistic update feedback
      SnackBarUtils.showSuccess(context, 'Expense added successfully!');
      
      // Refresh data in background to get accurate calculations
      _refreshDataInBackground();
    }
  }

  /// Refresh data in background without showing loading state
  Future<void> _refreshDataInBackground() async {
    try {
      final groupDetail = await GroupDetailService.refreshGroupDetails(widget.groupId);
      
      if (mounted) {
        setState(() {
          _groupDetail = groupDetail;
          _isOptimisticUpdate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOptimisticUpdate = false;
        });
        // Don't show error for background refresh, just log it
        debugPrint('Background refresh failed: $e');
      }
    }
  }

  void _onAddExpense() async {
    // Show loading overlay briefly while preparing navigation
    _loadingOverlay.show(context: context, message: 'Opening expense creation...');
    
    // Hide the overlay immediately and navigate
    await Future.delayed(Duration(milliseconds: 300));
    _loadingOverlay.hide();
    
    try {
      // Navigate to expense creation without timeout
      final result = await Navigator.pushNamed(
        context,
        AppRoutes.expenseCreation,
        arguments: {
          'groupId': widget.groupId,
          'refreshOnReturn': true,
        },
      );
      
      // Check if expense was created successfully
      if (result != null && result is Map<String, dynamic>) {
        if (result['success'] == true && result['expense'] != null) {
          // Optimistic update with the new expense
          _optimisticExpenseUpdate(result['expense']);
        }
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to open expense creation: $e');
    }
  }

  void _onExpenseItemTap(GroupExpense expense) {
    Navigator.pushNamed(
      context,
      AppRoutes.expenseDetail,
      arguments: {'expenseId': expense.id},
    ).then((result) {
      // Refresh data when returning from expense detail
      if (result != null && result is Map<String, dynamic>) {
        if (result['expenseUpdated'] == true) {
          _refreshData();
        }
      }
    });
  }

  void _showGroupActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => GroupActionsWidget(
        groupDetail: _groupDetail!,
        onGroupUpdated: _loadGroupData,
        onGroupDeleted: () {
          // Navigation is already handled by the GroupActionsWidget
          // No need to do anything here
        },
      ),
    );
  }

  int _getCurrentUserId() {
    // TODO: Get current user ID from authentication service
    return 1; // Placeholder
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
          elevation: AppTheme.lightTheme.appBarTheme.elevation,
          title: Text(
            _groupDetail?.name ?? 'Group Details',
            style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
          ),
          actions: [
            // Refresh button in app bar
            IconButton(
              onPressed: _isRefreshing ? null : _refreshData,
              icon: _isRefreshing 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  )
                : CustomIconWidget(
                    iconName: 'refresh',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
            ),
            IconButton(
              onPressed: _showGroupActions,
              icon: CustomIconWidget(
                iconName: 'more_vert',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : _groupDetail == null
                ? _buildErrorState()
                : _buildContent(),
        floatingActionButton: FloatingActionButton(
          onPressed: _onAddExpense,
          backgroundColor: AppTheme.lightTheme.floatingActionButtonTheme.backgroundColor,
          child: CustomIconWidget(
            iconName: 'add',
            color: AppTheme.lightTheme.floatingActionButtonTheme.foregroundColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    if (_retryCount > 0) {
      return LoadingStates.withRetry(
        message: 'Loading group details...',
        retryCount: _retryCount,
        maxRetries: _maxRetries,
      );
    }
    return LoadingStates.fullScreen(message: 'Loading group details...');
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            color: AppTheme.errorLight,
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'Failed to load group details',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _errorMessage ?? 'Please check your connection and try again',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _retryCount < _maxRetries ? _loadGroupData : null,
                child: Text('Retry'),
              ),
              SizedBox(width: 2.w),
              TextButton(
                onPressed: () {
                  setState(() {
                    _retryCount = 0;
                    _errorMessage = null;
                  });
                  _loadGroupData();
                },
                child: Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.lightTheme.primaryColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optimistic update indicator
            if (_isOptimisticUpdate)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 3.w),
                margin: EdgeInsets.only(bottom: 2.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sync,
                      size: 16,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Updating group data...',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Group Header Section
            GroupHeaderWidget(groupDetail: _groupDetail!),
            SizedBox(height: 3.h),
            
            // Balance Summary Section
            BalanceSummaryWidget(
              balance: _groupDetail!.userBalance,
              currency: _groupDetail!.currency,
            ),
            SizedBox(height: 3.h),
            
            // Expenses Section
            _buildExpensesSection(),
            SizedBox(height: 3.h),
            
            // Participants Section
            ParticipantListWidget(
              groupDetail: _groupDetail!,
              onParticipantAdded: _loadGroupData,
              onParticipantRemoved: _loadGroupData,
            ),
            SizedBox(height: 3.h),
            
            // Settlements Section
            SettlementsWidget(
              settlements: _groupDetail!.settlements,
              currentUserId: _getCurrentUserId(),
            ),
            SizedBox(height: 10.h), // Extra space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesSection() {
    return Card(
      elevation: 1.0,
      color: AppTheme.lightTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Expenses',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isRefreshing)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 30.h, // Fixed height for the expense list
              child: ExpenseListWidget(
                expenses: _groupDetail?.expenses ?? [],
                onRefresh: _loadGroupData,
                isLoading: _isRefreshing,
                onExpenseItemTap: _onExpenseItemTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onGroupDataUpdated(GroupDetailModel groupData) {
    if (mounted) {
      setState(() {
        _groupDetail = groupData;
        _isOptimisticUpdate = false;
      });
    }
  }
}