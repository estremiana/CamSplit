import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/receipt_item.dart';

class QuickSplitPanel extends StatelessWidget {
  final ReceiptItem item;
  final List<Map<String, dynamic>> groupMembers;
  final Function(Map<String, double>, {bool isAdvanced}) onAssignmentChanged;
  final VoidCallback onAdvancedSplit;

  const QuickSplitPanel({
    super.key,
    required this.item,
    required this.groupMembers,
    required this.onAssignmentChanged,
    required this.onAdvancedSplit,
  });

  void _handleMemberToggle(String memberId) {
    if (item.isCustomSplit) return; // Locked if advanced split exists

    final currentAssignments = Map<String, double>.from(item.assignments);
    final currentMemberIds = currentAssignments.keys.toList();
    
    Map<String, double> newAssignments;
    
    if (currentMemberIds.contains(memberId)) {
      // Remove member
      currentAssignments.remove(memberId);
      newAssignments = currentAssignments;
    } else {
      // Add member - equal split
      final newMemberIds = [...currentMemberIds, memberId];
      if (newMemberIds.isEmpty) {
        newAssignments = {};
      } else {
        final share = item.quantity / newMemberIds.length;
        newAssignments = {};
        for (final id in newMemberIds) {
          newAssignments[id] = share;
        }
      }
    }

    onAssignmentChanged(newAssignments, isAdvanced: false);
  }

  @override
  Widget build(BuildContext context) {
    final assignedCount = item.getAssignedQuantity();
    final isLocked = item.isCustomSplit;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor.withOpacity(0.03),
        border: Border(
          top: BorderSide(
            color: AppTheme.lightTheme.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUICK SPLIT (EQUAL)',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${assignedCount.toStringAsFixed(assignedCount % 1 == 0 ? 0 : 1)} / ${item.quantity.toInt()} ASSIGNED',
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  color: item.isFullyAssigned
                      ? Colors.green[600]
                      : AppTheme.lightTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Stack(
            children: [
              // Member grid
              Opacity(
                opacity: isLocked ? 0.2 : 1.0,
                child: IgnorePointer(
                  ignoring: isLocked,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 2.w,
                      mainAxisSpacing: 1.h,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: groupMembers.length,
                    itemBuilder: (context, index) {
                      final member = groupMembers[index];
                      final memberId = member['id'].toString();
                      final qty = item.assignments[memberId] ?? 0.0;
                      final isAssigned = qty > 0;

                      return GestureDetector(
                        onTap: () => _handleMemberToggle(memberId),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 10.w,
                                  height: 10.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isAssigned
                                          ? AppTheme.lightTheme.primaryColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    color: isAssigned
                                        ? AppTheme.lightTheme.primaryColor.withOpacity(0.1)
                                        : Colors.white,
                                  ),
                                  child: Center(
                                    child: Text(
                                      member['avatar'] ?? '?',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isAssigned
                                            ? AppTheme.lightTheme.primaryColor
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ),
                                if (isAssigned)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 4.w,
                                      height: 4.w,
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightTheme.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1),
                                      ),
                                      child: Center(
                                        child: Text(
                                          qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 7.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              (member['name'] ?? 'Unknown').split(' ')[0],
                              style: TextStyle(
                                fontSize: 8.sp,
                                color: isAssigned
                                    ? AppTheme.lightTheme.primaryColor
                                    : Colors.grey[400],
                                fontWeight: isAssigned ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Lock overlay
              if (isLocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, color: Colors.orange[600], size: 16),
                                SizedBox(width: 2.w),
                                Text(
                                  'Custom Split Active',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Reset assignments
                                onAssignmentChanged({});
                              },
                              icon: Icon(Icons.refresh, size: 14),
                              label: Text('Reset'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                                foregroundColor: AppTheme.lightTheme.primaryColor,
                                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Divider(color: Colors.grey[200]),
          SizedBox(height: 1.h),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onAdvancedSplit,
              icon: Icon(Icons.settings, size: 16),
              label: Text('Advanced / Partial Split'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                foregroundColor: AppTheme.lightTheme.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

