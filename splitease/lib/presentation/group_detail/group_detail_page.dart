import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/group_detail_model.dart';
import '../../models/group_member.dart';
import '../../models/debt_relationship_model.dart';
import 'widgets/group_header_widget.dart';
import 'widgets/balance_summary_widget.dart';
import 'widgets/expense_list_widget.dart';
import 'widgets/participant_list_widget.dart';
import 'widgets/debt_list_widget.dart';
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

class _GroupDetailPageState extends State<GroupDetailPage> {
  bool _isLoading = true;
  GroupDetailModel? _groupDetail;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Replace with actual API call
    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));

    // Mock data for now - this will be replaced with actual API call
    setState(() {
      _groupDetail = GroupDetailModel(
        id: widget.groupId,
        name: "Roommates",
        description: "Monthly apartment expenses",
        imageUrl: null,
        members: [
          GroupMember(
            id: "1",
            name: "John Doe",
            email: "john.doe@example.com",
            avatar: "",
            isCurrentUser: true,
            joinedAt: DateTime.now().subtract(Duration(days: 30)),
          ),
          GroupMember(
            id: "2",
            name: "Jane Smith",
            email: "jane.smith@example.com",
            avatar: "",
            isCurrentUser: false,
            joinedAt: DateTime.now().subtract(Duration(days: 25)),
          ),
          GroupMember(
            id: "3",
            name: "Bob Wilson",
            email: "bob.wilson@example.com",
            avatar: "",
            isCurrentUser: false,
            joinedAt: DateTime.now().subtract(Duration(days: 20)),
          ),
        ],
        expenses: [
          GroupExpense(
            id: 1,
            title: "Grocery shopping",
            amount: 85.50,
            currency: "USD",
            date: DateTime.now().subtract(Duration(days: 1)),
            payerName: "John Doe",
            payerId: 1,
            createdAt: DateTime.now().subtract(Duration(days: 1)),
          ),
          GroupExpense(
            id: 2,
            title: "Electricity bill",
            amount: 120.00,
            currency: "USD",
            date: DateTime.now().subtract(Duration(days: 3)),
            payerName: "Jane Smith",
            payerId: 2,
            createdAt: DateTime.now().subtract(Duration(days: 3)),
          ),
          GroupExpense(
            id: 3,
            title: "Internet bill",
            amount: 65.00,
            currency: "USD",
            date: DateTime.now().subtract(Duration(days: 5)),
            payerName: "Bob Wilson",
            payerId: 3,
            createdAt: DateTime.now().subtract(Duration(days: 5)),
          ),
          GroupExpense(
            id: 4,
            title: "Cleaning supplies",
            amount: 45.75,
            currency: "USD",
            date: DateTime.now().subtract(Duration(days: 7)),
            payerName: "John Doe",
            payerId: 1,
            createdAt: DateTime.now().subtract(Duration(days: 7)),
          ),
          GroupExpense(
            id: 5,
            title: "Pizza night",
            amount: 32.50,
            currency: "USD",
            date: DateTime.now().subtract(Duration(days: 10)),
            payerName: "Jane Smith",
            payerId: 2,
            createdAt: DateTime.now().subtract(Duration(days: 10)),
          ),
        ],
        debts: [
          // Add some mock debts to test debt validation
          DebtRelationship(
            debtorId: 2,
            debtorName: "Jane Smith",
            creditorId: 1,
            creditorName: "John Doe",
            amount: 50.0,
            currency: "USD",
            createdAt: DateTime.now().subtract(Duration(days: 5)),
            updatedAt: DateTime.now().subtract(Duration(days: 5)),
          ),
        ],
        userBalance: 245.50,
        currency: "USD",
        lastActivity: DateTime.now().subtract(Duration(hours: 2)),
        canEdit: true,
        canDelete: true,
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now().subtract(Duration(hours: 2)),
      );
      _isLoading = false;
    });
  }

  void _onAddExpense() {
    Navigator.pushNamed(
      context,
      AppRoutes.expenseCreation,
      arguments: {'groupId': widget.groupId},
    ).then((_) {
      // Refresh data when returning from expense creation
      _loadGroupData();
    });
  }

  void _onExpenseItemTap(GroupExpense expense) {
    Navigator.pushNamed(
      context,
      AppRoutes.expenseDetail,
      arguments: {'expenseId': expense.id},
    ).then((_) {
      // Refresh data when returning from expense detail
      _loadGroupData();
    });
  }

  void _showGroupActions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => GroupActionsWidget(
        groupDetail: _groupDetail!,
        onGroupUpdated: _loadGroupData,
        onGroupDeleted: () {
          // Navigate back to groups page when group is deleted
          Navigator.pop(context);
        },
      ),
    );
  }

  int? _getCurrentUserId() {
    final currentUser = _groupDetail?.currentUser;
    if (currentUser != null) {
      return int.tryParse(currentUser.id);
    }
    return null;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: AppTheme.lightTheme.appBarTheme.elevation,
        title: Text(
          _groupDetail?.name ?? 'Group Details',
          style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
        ),
        actions: [
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
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading group details...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
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
            'Please check your connection and try again',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: _loadGroupData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          
          // Debt Relationships Section
          DebtListWidget(
            debts: _groupDetail!.debts,
            currentUserId: _getCurrentUserId(),
          ),
          SizedBox(height: 10.h), // Extra space for FAB
        ],
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
            Text(
              'Recent Expenses',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 30.h, // Fixed height for the expense list
              child: ExpenseListWidget(
                expenses: _groupDetail?.expenses ?? [],
                onRefresh: _loadGroupData,
                isLoading: _isLoading,
                onExpenseItemTap: _onExpenseItemTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}