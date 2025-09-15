import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/settlement.dart';
import '../../../services/settlement_service.dart';
import 'settlement_processing_workflow.dart';

class SettlementCardWidget extends StatefulWidget {
  final Settlement settlement;
  final bool isPrivacyMode;
  final VoidCallback? onSettle;
  final VoidCallback? onRemind;
  final VoidCallback? onRefresh;

  const SettlementCardWidget({
    super.key,
    required this.settlement,
    required this.isPrivacyMode,
    this.onSettle,
    this.onRemind,
    this.onRefresh,
  });

  @override
  State<SettlementCardWidget> createState() => _SettlementCardWidgetState();
}

class _SettlementCardWidgetState extends State<SettlementCardWidget> {
  bool _isProcessing = false;
  bool _isReminding = false;
  bool _showProcessingWorkflow = false;
  final SettlementService _settlementService = SettlementService();

  @override
  Widget build(BuildContext context) {
    final bool isOwed = _isUserOwed();
    final String personName = _getOtherPersonName();
    final String personAvatar = _getOtherPersonAvatar();
    final double amount = widget.settlement.amount;
    final String description = _getSettlementDescription();
    final DateTime date = widget.settlement.createdAt;
    final String status = widget.settlement.status;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: _getBorderColor(status, isOwed),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status indicator
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: CustomIconWidget(
                      iconName: _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Person avatar
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.borderLight,
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: CustomImageWidget(
                        imageUrl: personAvatar,
                        width: 12.w,
                        height: 12.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  // Person info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          personName,
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _getSettlementDirectionText(isOwed),
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.isPrivacyMode
                            ? '••••••'
                            : '\$${amount.toStringAsFixed(2)}',
                        style: AppTheme.getMonospaceStyle(
                          isLight: true,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ).copyWith(
                          color: _getAmountColor(status, isOwed),
                        ),
                      ),
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              // Description and status
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.settlement.createdExpenseId != null) ...[
                    SizedBox(width: 2.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                      decoration: BoxDecoration(
                        color: AppTheme.successLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'receipt',
                            color: AppTheme.successLight,
                            size: 12,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'Expense Created',
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.successLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 2.h),
              // Action buttons
              if (status == 'active' && _canProcessSettlement())
                Row(
                  children: [
                    // Reminder action removed per requirement
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _handleSettle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOwed
                              ? AppTheme.successLight
                              : AppTheme.warningLight,
                          foregroundColor: Colors.white,
                        ),
                        child: _isProcessing
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'payment',
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    isOwed ? 'Request' : 'Settle',
                                    style: AppTheme.lightTheme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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

  bool _isUserOwed() {
    // This would need to be determined based on current user ID
    // For now, using a simple heuristic based on the settlement data
    return widget.settlement.toGroupMemberId > widget.settlement.fromGroupMemberId;
  }

  String _getOtherPersonName() {
    // This would need to be determined based on current user ID
    // For now, returning a placeholder
    return 'John Doe';
  }

  String _getOtherPersonAvatar() {
    // This would need to be determined based on current user ID
    // For now, returning a placeholder
    return '';
  }

  String _getSettlementDescription() {
    return 'Settlement for group expenses';
  }

  String _getSettlementDirectionText(bool isOwed) {
    return isOwed ? 'owes you' : 'you owe';
  }

  Color _getBorderColor(String status, bool isOwed) {
    if (status == 'settled') return AppTheme.successLight;
    if (status == 'obsolete') return AppTheme.textSecondaryLight;
    return isOwed ? AppTheme.successLight : AppTheme.warningLight;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.warningLight;
      case 'settled':
        return AppTheme.successLight;
      case 'obsolete':
        return AppTheme.textSecondaryLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  Color _getAmountColor(String status, bool isOwed) {
    if (status == 'settled') return AppTheme.successLight;
    if (status == 'obsolete') return AppTheme.textSecondaryLight;
    return isOwed ? AppTheme.successLight : AppTheme.warningLight;
  }

  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'schedule';
      case 'settled':
        return 'check_circle';
      case 'obsolete':
        return 'cancel';
      default:
        return 'help';
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Pending';
      case 'settled':
        return 'Completed';
      case 'obsolete':
        return 'Obsolete';
      default:
        return 'Unknown';
    }
  }

  bool _canProcessSettlement() {
    // This would need to check if current user can process this settlement
    // For now, allowing all active settlements to be processed
    return true;
  }

  Future<void> _handleSettle() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _showProcessingWorkflow = true;
    });

    // Show processing workflow
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => SettlementProcessingWorkflow(
        onComplete: () async {
          Navigator.pop(context);
          await _processSettlement();
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() {
            _isProcessing = false;
            _showProcessingWorkflow = false;
          });
        },
      ),
    );
  }

  Future<void> _processSettlement() async {
    try {
      HapticFeedback.mediumImpact();
      
      final result = await _settlementService.processSettlement(
        widget.settlement.id.toString(),
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settlement processed successfully!'),
            backgroundColor: AppTheme.successLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        );
        
        // Refresh the settlements list
        widget.onRefresh?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to process settlement'),
            backgroundColor: AppTheme.errorLight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing settlement: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
        _showProcessingWorkflow = false;
      });
    }
  }

  // Reminder handler removed per requirement
}
