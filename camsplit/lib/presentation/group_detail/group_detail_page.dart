import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/group_detail_model.dart';
import '../../models/group_member.dart';

import '../../services/group_detail_service.dart';
import '../../services/currency_migration_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/currency_utils.dart';
import '../../utils/loading_overlay.dart';
import '../../utils/error_recovery.dart';
import '../../utils/real_time_updates.dart';
import '../../widgets/loading_states.dart';
import '../../widgets/stacked_avatars_widget.dart';
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

class _GroupDetailPageState extends State<GroupDetailPage> with RealTimeUpdateMixin, TickerProviderStateMixin {
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



  // FAB Menu state
  bool _fabMenuOpen = false;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    // Initialize real-time updates
    initializeRealTimeUpdates(widget.groupId);
    
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
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

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
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
      // Store the original expense count before optimistic update
      final originalExpenseCount = _groupDetail!.expenses.length;
      
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
      _refreshDataInBackground(originalExpenseCount);
    }
  }

  /// Refresh data in background without showing loading state
  Future<void> _refreshDataInBackground([int? originalExpenseCount]) async {
    try {
      // Wait for backend settlement recalculation to complete
      // The backend has a 1000ms delay for expense creation
      await Future.delayed(Duration(milliseconds: 1500));
      
      // First attempt to refresh
      final groupDetail = await GroupDetailService.refreshGroupDetails(widget.groupId);
      
      if (mounted) {
        setState(() {
          _groupDetail = groupDetail;
          _isOptimisticUpdate = false;
        });
        
        // Check if the new expense was added to the group
        // If not, the backend might still be processing, so retry
        if (originalExpenseCount != null && groupDetail.expenses.length <= originalExpenseCount) {
          debugPrint('New expense not found in group yet, retrying in 1 second...');
          await Future.delayed(Duration(milliseconds: 1000));
          
          final retryGroupDetail = await GroupDetailService.refreshGroupDetails(widget.groupId);
          
          if (mounted) {
            setState(() {
              _groupDetail = retryGroupDetail;
            });
          }
        }
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
    // Show options menu
    final option = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Create Expense',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: Icon(Icons.auto_awesome, color: AppTheme.primaryLight),
              title: Text('New Expense (Wizard)'),
              subtitle: Text('Step-by-step expense creation'),
              onTap: () => Navigator.pop(context, 'wizard'),
            ),
            ListTile(
              leading: Icon(Icons.edit, color: AppTheme.primaryLight),
              title: Text('Create Expense (Classic)'),
              subtitle: Text('Traditional expense creation'),
              onTap: () => Navigator.pop(context, 'classic'),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );

    if (option == null) return;

    // Show loading overlay briefly while preparing navigation
    _loadingOverlay.show(context: context, message: 'Opening expense creation...');
    
    // Hide the overlay immediately and navigate
    await Future.delayed(Duration(milliseconds: 300));
    _loadingOverlay.hide();
    
    try {
      Map<String, dynamic>? result;
      
      if (option == 'wizard') {
        // Navigate to wizard
        result = await Navigator.pushNamed(
          context,
          AppRoutes.expenseCreationWizard,
          arguments: {
            'groupId': widget.groupId,
          },
        ) as Map<String, dynamic>?;
      } else {
        // Navigate to classic expense creation
        result = await Navigator.pushNamed(
          context,
          AppRoutes.expenseCreation,
          arguments: {
            'groupId': widget.groupId,
            'refreshOnReturn': true,
          },
        ) as Map<String, dynamic>?;
      }
      
      // Check if expense was created successfully
      if (result != null && result is Map<String, dynamic>) {
        if (result['success'] == true && result['expense'] != null) {
          // Convert the expense map to GroupExpense object
          try {
            final expenseMap = result['expense'] as Map<String, dynamic>;
            final newExpense = GroupExpense.fromJson(expenseMap);
            // Optimistic update with the new expense
            _optimisticExpenseUpdate(newExpense);
          } catch (e) {
            debugPrint('Failed to parse expense data: $e');
            // Fallback: refresh data instead of optimistic update
            // Wait a bit for backend processing to complete
            await Future.delayed(Duration(milliseconds: 1500));
            _refreshData();
          }
        }
      }
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to open expense creation: $e');
    }
  }

  // FAB menu control methods
  void _toggleFabMenu() {
    setState(() {
      _fabMenuOpen = !_fabMenuOpen;
      if (_fabMenuOpen) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  void _closeFabMenu() {
    setState(() {
      _fabMenuOpen = false;
      _fabController.reverse();
    });
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
        onGroupUpdated: _refreshData,
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
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: _isLoading
            ? _buildLoadingState()
            : _groupDetail == null
                ? _buildErrorState()
                : _buildContent(),
        floatingActionButton: _groupDetail != null ? _buildFab() : null,
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      heroTag: 'fab_add_expense',
      backgroundColor: AppTheme.lightTheme.primaryColor,
      foregroundColor: AppTheme.onPrimaryLight,
      elevation: 3.0,
      onPressed: _onAddExpense,
      child: CustomIconWidget(
        iconName: 'add',
        color: AppTheme.onPrimaryLight,
        size: 28,
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
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Parallax-like Header
          _buildHeader(),
          
          // Member Strip
          _buildMemberStrip(),
          
          // Tabs
          _buildTabs(),
          
          // Content
          Expanded(
            child: TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppTheme.lightTheme.primaryColor,
                  child: _buildExpensesTab(),
                ),
                RefreshIndicator(
                  onRefresh: _refreshData,
                  color: AppTheme.lightTheme.primaryColor,
                  child: _buildBalancesTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48.w, // h-48 equivalent
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover Image
          if (_groupDetail!.imageUrl != null)
            CustomImageWidget(
              imageUrl: _groupDetail!.imageUrl!,
              width: double.infinity,
              height: 48.w,
              fit: BoxFit.cover,
            )
          else
            Container(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
            ),
          
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          
          // Top buttons
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: CustomIconWidget(
                        iconName: 'arrow_back',
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: _showGroupActions,
                      icon: CustomIconWidget(
                        iconName: 'settings',
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Title and description at bottom
          Positioned(
            bottom: 4.w,
            left: 6.w,
            right: 6.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _groupDetail!.name,
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _groupDetail!.description.isNotEmpty 
                      ? _groupDetail!.description 
                      : 'No description',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStrip() {
    final totalSpent = _groupDetail!.expenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Member avatars
          Row(
            children: [
              _buildAvatarStack(),
              SizedBox(width: 2.w),
              GestureDetector(
                onTap: _showAddParticipantDialog,
                child: Text(
                  '+ Invite',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          
          // Total Spent
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Spent',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              SizedBox(height: 0.25.h),
              Text(
                CamSplitCurrencyUtils.formatAmount(
                  totalSpent,
                  CurrencyMigrationService.parseFromBackend(_groupDetail!.currency),
                ),
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack() {
    return StackedAvatarsWidget(
      members: _groupDetail!.members,
      maxVisible: 3,
      size: 32.0,
      spacing: 24.0,
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        labelColor: AppTheme.lightTheme.primaryColor,
        unselectedLabelColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        indicatorColor: AppTheme.lightTheme.primaryColor,
        indicatorWeight: 3,
        labelStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTheme.lightTheme.textTheme.bodyMedium,
        tabs: [
          Tab(text: 'Expenses'),
          Tab(text: 'Balances'),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    if (_groupDetail!.expenses.isEmpty) {
      return Center(
        child: Text(
          'No expenses yet.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _groupDetail!.expenses.length,
      itemBuilder: (context, index) {
        final expense = _groupDetail!.expenses[index];
        return _buildExpenseCard(expense);
      },
    );
  }

  Widget _buildExpenseCard(GroupExpense expense) {
    final currentUserId = _getCurrentUserId();
    final isPayer = expense.payerId == currentUserId;
    
    // Calculate user's share (simplified - would need to check splits in real implementation)
    final userShare = expense.amount / (_groupDetail!.members.length);
    
    return Container(
      margin: EdgeInsets.only(bottom: 3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _onExpenseItemTap(expense),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              // Date badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${expense.date.day}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _getMonthAbbreviation(expense.date.month),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              
              // Expense info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${isPayer ? "You" : expense.payerName} paid ${CamSplitCurrencyUtils.formatAmount(expense.amount, CurrencyMigrationService.parseFromBackend(expense.currency))}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              
              // User's share
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'You lent',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: 0.25.h),
                  Text(
                    CamSplitCurrencyUtils.formatAmount(
                      userShare,
                      CurrencyMigrationService.parseFromBackend(expense.currency),
                    ),
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTheme.colorScheme.tertiary,
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

  Widget _buildBalancesTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Who owes who',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 3.h),
        ..._buildBalanceItems(),
      ],
    );
  }

  List<Widget> _buildBalanceItems() {
    final currentUserId = _getCurrentUserId();
    
    // Build balance items from ALL settlements (show who owes who in the group)
    final userSettlements = <Widget>[];
    final otherSettlements = <Widget>[];
    
    for (final settlement in _groupDetail!.settlements) {
      // Only show active settlements
      if (settlement.status != 'active') {
        continue;
      }
      
      // Find the members involved in this settlement
      final fromMember = _groupDetail!.members.firstWhere(
        (m) => m.id == settlement.fromGroupMemberId,
        orElse: () => _groupDetail!.members.first,
      );
      
      final toMember = _groupDetail!.members.firstWhere(
        (m) => m.id == settlement.toGroupMemberId,
        orElse: () => _groupDetail!.members.first,
      );
      
      final settlementCard = _buildSettlementCard(
        fromMember,
        toMember,
        settlement.amount,
        settlement.currency,
      );
      
      // Separate user settlements from others
      if (fromMember.userId == currentUserId || toMember.userId == currentUserId) {
        userSettlements.add(settlementCard);
      } else {
        otherSettlements.add(settlementCard);
      }
    }
    
    // Combine with user settlements on top
    final balanceItems = [...userSettlements, ...otherSettlements];
    
    if (balanceItems.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: EdgeInsets.all(4.h),
            child: Text(
              'All settled up!',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }
    
    return balanceItems;
  }

  Widget _buildSettlementCard(GroupMember fromMember, GroupMember toMember, double amount, String currency) {
    final currentUserId = _getCurrentUserId();
    final isCurrentUserInvolved = fromMember.userId == currentUserId || toMember.userId == currentUserId;
    final isUserDebtor = fromMember.userId == currentUserId;
    
    return Container(
      margin: EdgeInsets.only(bottom: 2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUserInvolved 
              ? AppTheme.lightTheme.primaryColor.withOpacity(0.3)
              : AppTheme.lightTheme.colorScheme.outline.withOpacity(0.1),
          width: isCurrentUserInvolved ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
        child: Row(
          children: [
            // Settlement info
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(
                      text: isUserDebtor ? 'You' : fromMember.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: isUserDebtor ? ' owe ' : ' owes ',
                      style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextSpan(
                      text: toMember.userId == currentUserId ? 'you' : toMember.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(width: 3.w),
            
            // Amount
            Text(
              CamSplitCurrencyUtils.formatAmount(
                amount,
                CurrencyMigrationService.parseFromBackend(currency),
              ),
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.lightTheme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddParticipantDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Member'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter member name',
                    prefixIcon: CustomIconWidget(
                      iconName: 'person',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter member email',
                    prefixIcon: CustomIconWidget(
                      iconName: 'email',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  _addParticipant(
                    nameController.text.trim(),
                    emailController.text.trim(),
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addParticipant(String name, String email) async {
    try {
      await GroupDetailService.addParticipant(
        _groupDetail!.id,
        email,
        name,
      );
      
      SnackBarUtils.showSuccess(context, 'Member added successfully!');
      _loadGroupData(showLoading: false);
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to add member: $e');
    }
  }


  String _getMonthAbbreviation(int month) {
    const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 
                    'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
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