import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/group_settlement_widget.dart';
import './widgets/payment_method_widget.dart';
import './widgets/settlement_card_widget.dart';
import './widgets/settlement_history_widget.dart';

class SettlementSummary extends StatefulWidget {
  const SettlementSummary({super.key});

  @override
  State<SettlementSummary> createState() => _SettlementSummaryState();
}

class _SettlementSummaryState extends State<SettlementSummary>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isLoading = false;
  bool _isPrivacyMode = false;

  // Mock data for settlements
  final List<Map<String, dynamic>> _pendingSettlements = [
    {
      "id": 1,
      "creditor": "Sarah Johnson",
      "creditorAvatar":
          "https://images.unsplash.com/photo-1494790108755-2616b9e2-c7a4-9b1e-6f4d-8c9a2b3c4d5e",
      "amount": 45.50,
      "description": "Restaurant dinner split",
      "date": DateTime.now().subtract(const Duration(days: 2)),
      "group": "Work Team",
      "category": "Food",
      "suggestedMethods": ["Venmo", "PayPal", "Bank Transfer"],
      "status": "pending"
    },
    {
      "id": 2,
      "debtor": "Mike Chen",
      "debtorAvatar":
          "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg",
      "amount": 28.75,
      "description": "Uber ride home",
      "date": DateTime.now().subtract(const Duration(hours: 12)),
      "group": "Friends",
      "category": "Transportation",
      "suggestedMethods": ["Venmo", "Cash"],
      "status": "pending"
    },
    {
      "id": 3,
      "creditor": "Lisa Park",
      "creditorAvatar":
          "https://images.pixabay.com/photo/2016/11-8-15-46-22-1810553_1280.jpg",
      "amount": 67.20,
      "description": "Grocery shopping",
      "date": DateTime.now().subtract(const Duration(days: 1)),
      "group": "Roommates",
      "category": "Groceries",
      "suggestedMethods": ["PayPal", "Bank Transfer", "Cash"],
      "status": "pending"
    }
  ];

  final List<Map<String, dynamic>> _settlementHistory = [
    {
      "id": 1,
      "person": "John Doe",
      "personAvatar":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d",
      "amount": 32.50,
      "description": "Movie tickets",
      "date": DateTime.now().subtract(const Duration(days: 3)),
      "method": "Venmo",
      "status": "completed",
      "type": "received"
    },
    {
      "id": 2,
      "person": "Emma Wilson",
      "personAvatar":
          "https://images.pexels.com/photos/733872/pexels-photo-733872.jpeg",
      "amount": 89.00,
      "description": "Weekend getaway",
      "date": DateTime.now().subtract(const Duration(days: 5)),
      "method": "PayPal",
      "status": "completed",
      "type": "paid"
    },
    {
      "id": 3,
      "person": "David Kim",
      "personAvatar":
          "https://images.pixabay.com/photo/2016/11-18-18-52-7-1834105_1280.jpg",
      "amount": 156.80,
      "description": "Restaurant dinner",
      "date": DateTime.now().subtract(const Duration(days: 7)),
      "method": "Bank Transfer",
      "status": "completed",
      "type": "received"
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalOwed = _pendingSettlements
        .where((s) => s.containsKey('debtor'))
        .fold(0.0, (sum, s) => sum + s['amount']);
    final totalOwing = _pendingSettlements
        .where((s) => s.containsKey('creditor'))
        .fold(0.0, (sum, s) => sum + s['amount']);

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.cardColor,
        elevation: 1.0,
        title: Text(
          'Settlement Summary',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _togglePrivacyMode,
            icon: CustomIconWidget(
              iconName: _isPrivacyMode ? 'visibility_off' : 'visibility',
              color: AppTheme.textPrimaryLight,
              size: 24,
            ),
          ),
          IconButton(
            onPressed: _showSettlementOptions,
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: AppTheme.textPrimaryLight,
              size: 24,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        color: AppTheme.lightTheme.primaryColor,
        child: Column(
          children: [
            _buildBalanceOverview(totalOwed, totalOwing),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingSettlements(),
                  _buildSettlementHistory(),
                  _buildGroupSettlements(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSmartSettlementSuggestions,
        backgroundColor: AppTheme.lightTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryLight,
        icon: CustomIconWidget(
          iconName: 'auto_fix_high',
          color: AppTheme.onPrimaryLight,
          size: 20,
        ),
        label: const Text('Smart Settle'),
      ),
    );
  }

  Widget _buildBalanceOverview(double totalOwed, double totalOwing) {
    final netBalance = totalOwed - totalOwing;
    final isPositive = netBalance >= 0;

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.primaryColor,
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are owed',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.onPrimaryLight.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _isPrivacyMode
                          ? '••••••'
                          : '\$${totalOwed.toStringAsFixed(2)}',
                      style: AppTheme.getMonospaceStyle(
                        isLight: false,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ).copyWith(
                        color: AppTheme.onPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 6.h,
                color: AppTheme.onPrimaryLight.withValues(alpha: 0.3),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You owe',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.onPrimaryLight.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      _isPrivacyMode
                          ? '••••••'
                          : '\$${totalOwing.toStringAsFixed(2)}',
                      style: AppTheme.getMonospaceStyle(
                        isLight: false,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ).copyWith(
                        color: AppTheme.onPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.onPrimaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: isPositive ? 'trending_up' : 'trending_down',
                  color: isPositive
                      ? AppTheme.successLight
                      : AppTheme.warningLight,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Net Balance: ',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onPrimaryLight.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  _isPrivacyMode
                      ? '••••••'
                      : '${isPositive ? '+' : ''}\$${netBalance.abs().toStringAsFixed(2)}',
                  style: AppTheme.getMonospaceStyle(
                    isLight: false,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: AppTheme.onPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.lightTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.lightTheme.primaryColor,
        indicatorWeight: 2.0,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'History'),
          Tab(text: 'Groups'),
        ],
      ),
    );
  }

  Widget _buildPendingSettlements() {
    if (_pendingSettlements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'check_circle_outline',
              color: AppTheme.successLight,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'All settled up!',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'You have no pending settlements',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _pendingSettlements.length,
      itemBuilder: (context, index) {
        final settlement = _pendingSettlements[index];
        return SettlementCardWidget(
          settlement: settlement,
          isPrivacyMode: _isPrivacyMode,
          onSettle: () => _initiateSettlement(settlement),
          onRemind: () => _sendReminder(settlement),
        );
      },
    );
  }

  Widget _buildSettlementHistory() {
    if (_settlementHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'history',
              color: AppTheme.textSecondaryLight,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'No settlement history',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your completed settlements will appear here',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _settlementHistory.length,
      itemBuilder: (context, index) {
        final settlement = _settlementHistory[index];
        return SettlementHistoryWidget(
          settlement: settlement,
          isPrivacyMode: _isPrivacyMode,
        );
      },
    );
  }

  Widget _buildGroupSettlements() {
    return GroupSettlementWidget(
      isPrivacyMode: _isPrivacyMode,
      onOptimizeSettlements: _optimizeGroupSettlements,
    );
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settlements updated successfully'),
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

  void _showSettlementOptions() {
    HapticFeedback.selectionClick();
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
              'Settlement Options',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'file_download',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Export Report'),
              onTap: _exportSettlementReport,
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'settings',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: const Text('Settlement Settings'),
              onTap: _openSettlementSettings,
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _initiateSettlement(Map<String, dynamic> settlement) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => PaymentMethodWidget(
        settlement: settlement,
        isPrivacyMode: _isPrivacyMode,
        onPaymentComplete: (method) => _completeSettlement(settlement, method),
      ),
    );
  }

  void _sendReminder(Map<String, dynamic> settlement) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder sent to ${settlement['creditor'] ?? settlement['debtor']}',
        ),
        backgroundColor: AppTheme.lightTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  void _completeSettlement(Map<String, dynamic> settlement, String method) {
    HapticFeedback.lightImpact();
    setState(() {
      _pendingSettlements.removeWhere((s) => s['id'] == settlement['id']);
      _settlementHistory.insert(0, {
        ...settlement,
        'method': method,
        'status': 'completed',
        'date': DateTime.now(),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settlement completed via $method'),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  void _showSmartSettlementSuggestions() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smart Settlement Suggestions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('We found ways to optimize your settlements:'),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.successLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'savings',
                    color: AppTheme.successLight,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  const Expanded(
                    child: Text('Reduce 5 transactions to 2 transfers'),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applySmartSuggestions();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _optimizeGroupSettlements() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Group settlements optimized'),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  void _exportSettlementReport() {
    Navigator.pop(context);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Settlement report exported'),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  void _openSettlementSettings() {
    Navigator.pop(context);
    HapticFeedback.selectionClick();
    // Navigate to settlement settings
  }

  void _applySmartSuggestions() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Smart suggestions applied'),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
