import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/settlement.dart';
import '../../services/settlement_service.dart';
import './widgets/group_settlement_widget.dart';
import './widgets/payment_method_widget.dart';
import './widgets/settlement_card_widget.dart';
import './widgets/settlement_history_widget.dart';

class SettlementSummary extends StatefulWidget {
  final String? groupId;
  
  const SettlementSummary({super.key, this.groupId});

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
  final SettlementService _settlementService = SettlementService();

  List<Settlement> _activeSettlements = [];
  List<Settlement> _settlementHistory = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSettlements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSettlements() async {
    if (widget.groupId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load active settlements
      final activeSettlements = await _settlementService.getGroupSettlements(widget.groupId!);
      
      // Load settlement history
      final historySettlements = await _settlementService.getSettlementHistory(
        widget.groupId!,
        status: 'settled',
        limit: 20,
      );

      setState(() {
        _activeSettlements = activeSettlements;
        _settlementHistory = historySettlements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load settlements: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSettlements() async {
    await _loadSettlements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settlements',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isPrivacyMode = !_isPrivacyMode;
              });
              HapticFeedback.selectionClick();
            },
            icon: CustomIconWidget(
              iconName: _isPrivacyMode ? 'visibility' : 'visibility_off',
              color: AppTheme.lightTheme.primaryColor,
              size: 24,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.lightTheme.primaryColor,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Loading settlements...',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: AppTheme.errorLight,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'Error',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.errorLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage!,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: _loadSettlements,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshSettlements,
      color: AppTheme.lightTheme.primaryColor,
      child: Column(
        children: [
          // Summary cards
          _buildSummaryCards(),
          
          // Tab bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1.0,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: AppTheme.lightTheme.primaryColor,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondaryLight,
              labelStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'schedule',
                        color: _tabController.index == 0 ? Colors.white : AppTheme.textSecondaryLight,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text('Pending'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'history',
                        color: _tabController.index == 1 ? Colors.white : AppTheme.textSecondaryLight,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text('History'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingSettlements(),
                _buildSettlementHistory(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalOwed = _activeSettlements
        .where((s) => _isUserOwed(s))
        .fold(0.0, (sum, s) => sum + s.amount);
    
    final totalOwe = _activeSettlements
        .where((s) => !_isUserOwed(s))
        .fold(0.0, (sum, s) => sum + s.amount);

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'You\'re Owed',
              amount: totalOwed,
              color: AppTheme.successLight,
              icon: 'arrow_downward',
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildSummaryCard(
              title: 'You Owe',
              amount: totalOwe,
              color: AppTheme.warningLight,
              icon: 'arrow_upward',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required String icon,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: icon,
                color: color,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            _isPrivacyMode ? '••••••' : '\$${amount.toStringAsFixed(2)}',
            style: AppTheme.getMonospaceStyle(
              isLight: true,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ).copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSettlements() {
    if (_activeSettlements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.successLight,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Pending Settlements',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'All debts are settled!',
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
      itemCount: _activeSettlements.length,
      itemBuilder: (context, index) {
        final settlement = _activeSettlements[index];
        return SettlementCardWidget(
          settlement: settlement,
          isPrivacyMode: _isPrivacyMode,
          onRefresh: _refreshSettlements,
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
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Settlement History',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Completed settlements will appear here',
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
        return SettlementCardWidget(
          settlement: settlement,
          isPrivacyMode: _isPrivacyMode,
        );
      },
    );
  }

  bool _isUserOwed(Settlement settlement) {
    // This would need to be determined based on current user ID
    // For now, using a simple heuristic based on the settlement data
    return settlement.toGroupMemberId > settlement.fromGroupMemberId;
  }
}
