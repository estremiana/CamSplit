import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/balance_card_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/quick_stats_widget.dart';
import './widgets/recent_expense_card_widget.dart';

class ExpenseDashboard extends StatefulWidget {
  const ExpenseDashboard({super.key});

  @override
  State<ExpenseDashboard> createState() => _ExpenseDashboardState();
}

class _ExpenseDashboardState extends State<ExpenseDashboard>
    with TickerProviderStateMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isPrivacyMode = false;
  bool _isLoading = false;
  int _currentBottomNavIndex = 0;

  // FAB menu state
  late AnimationController _fabController;
  late Animation<double> _fabRotation;
  late Animation<double> _fabTranslation;
  bool _fabMenuOpen = false;

  // Mock data for expenses
  final List<Map<String, dynamic>> _recentExpenses = [
    {
      "id": 1,
      "description": "Grocery Shopping",
      "amount": 85.50,
      "date": DateTime.now().subtract(const Duration(hours: 2)),
      "group": "Roommates",
      "category": "Food",
      "receiptUrl":
          "https://images.pexels.com/photos/264636/pexels-photo-264636.jpeg",
      "paidBy": "You",
      "splitWith": ["Alice", "Bob"],
      "status": "pending"
    },
    {
      "id": 2,
      "description": "Uber Ride",
      "amount": 24.75,
      "date": DateTime.now().subtract(const Duration(days: 1)),
      "group": "Friends",
      "category": "Transportation",
      "receiptUrl":
          "https://images.pixabay.com/photo/2017/03/29/04/47/car-2184865_1280.jpg",
      "paidBy": "Sarah",
      "splitWith": ["You", "Mike"],
      "status": "settled"
    },
    {
      "id": 3,
      "description": "Restaurant Dinner",
      "amount": 156.80,
      "date": DateTime.now().subtract(const Duration(days: 2)),
      "group": "Work Team",
      "category": "Food",
      "receiptUrl":
          "https://images.unsplash.com/photo-1414235077428-338989a2e8c0",
      "paidBy": "John",
      "splitWith": ["You", "Emma", "David"],
      "status": "pending"
    },
    {
      "id": 4,
      "description": "Movie Tickets",
      "amount": 45.00,
      "date": DateTime.now().subtract(const Duration(days: 3)),
      "group": "Friends",
      "category": "Entertainment",
      "receiptUrl":
          "https://images.pexels.com/photos/7991579/pexels-photo-7991579.jpeg",
      "paidBy": "You",
      "splitWith": ["Lisa", "Tom"],
      "status": "settled"
    }
  ];

  // Mock user data
  final Map<String, dynamic> _userData = {
    "name": "Alex Johnson",
    "avatar": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
    "totalOwed": 127.35,
    "totalOwing": 89.50,
    "monthlySpending": 1245.80,
    "pendingSettlements": 3,
    "activeGroups": 4
  };

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabRotation = Tween<double>(begin: 0, end: 0.25).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
    _fabTranslation = Tween<double>(begin: 0, end: 70).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

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

  void _openCameraCapture() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/camera-receipt-capture');
    _closeFabMenu();
  }

  void _openDynamicParticipantDemo() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/dynamic-participant-demo');
    _closeFabMenu();
  }

  void _openExpenseCreation() {
    HapticFeedback.mediumImpact();
    Navigator.pushNamed(context, '/expense-creation');
    _closeFabMenu();
  }

  void _closeFabMenu() {
    setState(() {
      _fabMenuOpen = false;
      _fabController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_fabMenuOpen) {
          _closeFabMenu();
          return false;
        }
        return true;
      },
      child: Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: AppTheme.lightTheme.primaryColor,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _recentExpenses.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyStateWidget(
                        onAddExpense: _openCameraCapture,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildListDelegate([
                        SizedBox(height: 2.h),
                        BalanceCardWidget(
                          totalOwed: _userData["totalOwed"] as double,
                          totalOwing: _userData["totalOwing"] as double,
                          isPrivacyMode: _isPrivacyMode,
                          onPrivacyToggle: _togglePrivacyMode,
                        ),
                        SizedBox(height: 3.h),
                        QuickStatsWidget(
                          monthlySpending:
                              _userData["monthlySpending"] as double,
                          pendingSettlements:
                              _userData["pendingSettlements"] as int,
                          activeGroups: _userData["activeGroups"] as int,
                          isPrivacyMode: _isPrivacyMode,
                        ),
                        SizedBox(height: 3.h),
                        _buildRecentExpensesSection(),
                        SizedBox(height: 10.h),
                      ]),
                    ),
            ],
          ),
        ),
      ),
            // Modal barrier for closing FAB menu on outside tap
            if (_fabMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeFabMenu,
                  behavior: HitTestBehavior.opaque,
                  child: Container(),
                ),
              ),
          ],
        ),
        floatingActionButton: _buildFabMenu(),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildFabMenu() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Demo FAB (tertiary)
        AnimatedBuilder(
          animation: _fabController,
          builder: (context, child) {
            return Positioned(
              right: 0,
              bottom: 0 + _fabTranslation.value * 2,
              child: IgnorePointer(
                ignoring: !_fabMenuOpen && _fabController.value == 0,
                child: Opacity(
                  opacity: _fabController.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label
                      AnimatedOpacity(
                        opacity: _fabMenuOpen ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Dynamic Participant Demo',
                                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.lightTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      FloatingActionButton(
                        heroTag: 'fab_demo',
                        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
                        foregroundColor: AppTheme.lightTheme.colorScheme.onSecondary,
                        elevation: 3.0,
                        onPressed: _fabMenuOpen ? _openDynamicParticipantDemo : null,
                        child: const Icon(Icons.science, size: 28),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Camera FAB (secondary)
        AnimatedBuilder(
          animation: _fabController,
          builder: (context, child) {
            return Positioned(
              right: 0,
              bottom: 0 + _fabTranslation.value,
              child: IgnorePointer(
                ignoring: !_fabMenuOpen && _fabController.value == 0,
                child: Opacity(
                  opacity: _fabController.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label
                      AnimatedOpacity(
                        opacity: _fabMenuOpen ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Scan receipt',
                                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.lightTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      FloatingActionButton(
                        heroTag: 'fab_camera',
                        // Remove mini: true to make it same size as plus FAB
        backgroundColor: AppTheme.lightTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryLight,
                        elevation: 3.0,
                        onPressed: _fabMenuOpen ? _openCameraCapture : null,
        child: CustomIconWidget(
          iconName: 'camera_alt',
          color: AppTheme.onPrimaryLight,
                          size: 28,
        ),
      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Main FAB (plus)
        Positioned(
          right: 0,
          bottom: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only show label when menu is open
              if (_fabMenuOpen)
                AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            'Create new expense',
                            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.lightTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () {
                  if (_fabMenuOpen) {
                    _openExpenseCreation();
                  } else {
                    _toggleFabMenu();
                  }
                },
                child: AnimatedBuilder(
                  animation: _fabController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _fabRotation.value * 2 * 3.1415926535,
                      child: FloatingActionButton(
                        heroTag: 'fab_plus',
                        backgroundColor: AppTheme.lightTheme.primaryColor,
                        foregroundColor: AppTheme.onPrimaryLight,
                        elevation: 4.0,
                        onPressed: null, // Use GestureDetector's onTap
                        child: CustomIconWidget(
                          iconName: 'add',
                          color: AppTheme.onPrimaryLight,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppTheme.lightTheme.cardColor,
      elevation: 1.0,
      pinned: true,
      expandedHeight: 12.h,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(),
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.lightTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: _userData["avatar"] as String,
                      width: 12.w,
                      height: 12.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome back,',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      _userData["name"] as String,
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showNotifications,
                icon: Stack(
                  children: [
                    CustomIconWidget(
                      iconName: 'notifications_outlined',
                      color: AppTheme.textPrimaryLight,
                      size: 24,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.errorLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentExpensesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Expenses',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _viewAllExpenses,
                child: Text(
                  'View All',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 1.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentExpenses.length,
          itemBuilder: (context, index) {
            final expense = _recentExpenses[index];
            return RecentExpenseCardWidget(
              expense: expense,
              isPrivacyMode: _isPrivacyMode,
              onEdit: () => _editExpense(expense),
              onDuplicate: () => _duplicateExpense(expense),
              onShare: () => _shareExpense(expense),
              onDelete: () => _deleteExpense(expense),
              onTap: () => _viewExpenseDetails(expense),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentBottomNavIndex,
      onTap: _onBottomNavTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.cardColor,
      selectedItemColor: AppTheme.lightTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondaryLight,
      elevation: 8.0,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'dashboard_outlined',
            color: _currentBottomNavIndex == 0
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'dashboard',
            color: AppTheme.lightTheme.primaryColor,
            size: 24,
          ),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'group_outlined',
            color: _currentBottomNavIndex == 1
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'group',
            color: AppTheme.lightTheme.primaryColor,
            size: 24,
          ),
          label: 'Groups',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person_outlined',
            color: _currentBottomNavIndex == 2
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'person',
            color: AppTheme.lightTheme.primaryColor,
            size: 24,
          ),
          label: 'Profile',
        ),
      ],
    );
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Expenses updated successfully',
            style: AppTheme.lightTheme.snackBarTheme.contentTextStyle,
          ),
          backgroundColor: AppTheme.successLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      );
    }
  }

  void _togglePrivacyMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _isPrivacyMode = !_isPrivacyMode;
    });
  }

  void _onBottomNavTap(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.pushNamed(context, '/group-management');
        break;
      case 2:
        Navigator.pushNamed(context, '/profile-settings');
        break;
    }
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile-settings');
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Notifications',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'receipt',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('New expense added'),
              subtitle: const Text('Sarah added dinner expense'),
              trailing: const Text('2h ago'),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'payment',
                color: AppTheme.successLight,
                size: 24,
              ),
              title: const Text('Payment received'),
              subtitle: const Text('John settled movie tickets'),
              trailing: const Text('1d ago'),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _viewAllExpenses() {
    Navigator.pushNamed(context, '/expense-creation');
  }

  void _editExpense(Map<String, dynamic> expense) {
    HapticFeedback.selectionClick();
    // Navigate to edit expense screen
  }

  void _duplicateExpense(Map<String, dynamic> expense) {
    HapticFeedback.selectionClick();
    // Duplicate expense logic
  }

  void _shareExpense(Map<String, dynamic> expense) {
    HapticFeedback.selectionClick();
    // Share expense logic
  }

  void _deleteExpense(Map<String, dynamic> expense) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _recentExpenses.removeWhere((e) => e["id"] == expense["id"]);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense deleted successfully'),
                  backgroundColor: AppTheme.errorLight,
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorLight),
            ),
          ),
        ],
      ),
    );
  }

  void _viewExpenseDetails(Map<String, dynamic> expense) {
    HapticFeedback.selectionClick();
    // Navigate to expense details screen
  }
}
