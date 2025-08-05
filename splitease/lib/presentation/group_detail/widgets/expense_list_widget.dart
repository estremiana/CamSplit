import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/group_detail_model.dart';
import '../../../utils/snackbar_utils.dart';
import '../../../widgets/loading_states.dart';

/// Widget that displays a list of group expenses with pull-to-refresh functionality
class ExpenseListWidget extends StatefulWidget {
  final List<GroupExpense> expenses;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final Function(GroupExpense)? onExpenseItemTap;

  const ExpenseListWidget({
    Key? key,
    required this.expenses,
    this.onRefresh,
    this.isLoading = false,
    this.onExpenseItemTap,
  }) : super(key: key);

  @override
  State<ExpenseListWidget> createState() => _ExpenseListWidgetState();
}

class _ExpenseListWidgetState extends State<ExpenseListWidget> {
  bool _isRefreshing = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.expenses.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      color: AppTheme.lightTheme.primaryColor,
      child: Container(
        color: Colors.white,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
          itemCount: widget.expenses.length,
          separatorBuilder: (context, index) => SizedBox(height: 1.h),
          itemBuilder: (context, index) {
            final expense = widget.expenses[index];
            return ExpenseItemWidget(
              expense: expense,
              onTap: widget.onExpenseItemTap != null 
                  ? () => widget.onExpenseItemTap!(expense)
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return LoadingStates.fullScreen(message: 'Loading expenses...');
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Call the parent's refresh callback
      widget.onRefresh?.call();
      
      // Show success feedback
      SnackBarUtils.showSuccess(context, 'Expenses refreshed');
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to refresh expenses: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _handleRefresh,
      color: AppTheme.lightTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 50.h,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 15.w,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 3.h),
              Text(
                'No expenses yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                'Start adding expenses to track group spending',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: () {
                  // Trigger refresh to check for new expenses
                  _handleRefresh();
                },
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual expense item widget with enhanced loading states
class ExpenseItemWidget extends StatefulWidget {
  final GroupExpense expense;
  final VoidCallback? onTap;

  const ExpenseItemWidget({
    Key? key,
    required this.expense,
    this.onTap,
  }) : super(key: key);

  @override
  State<ExpenseItemWidget> createState() => _ExpenseItemWidgetState();
}

class _ExpenseItemWidgetState extends State<ExpenseItemWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.grey.shade50
          : Colors.grey.shade800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: InkWell(
        onTap: _isLoading ? null : _handleTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.expense.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 0.5.w),
                        Expanded(
                          child: Text(
                            'Paid by ${widget.expense.payerName}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.expense.amount.toStringAsFixed(2)}${widget.expense.currency}',
                    style: AppTheme.getMonospaceStyle(
                      isLight: Theme.of(context).brightness == Brightness.light,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.25.h),
                  Text(
                    _formatDate(widget.expense.date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (_isLoading) ...[
                SizedBox(width: 2.w),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.lightTheme.primaryColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap() async {
    if (widget.onTap == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Add a small delay to show loading state
      await Future.delayed(Duration(milliseconds: 100));
      
      if (mounted) {
        widget.onTap!();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Failed to open expense: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }
}