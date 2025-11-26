import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../models/receipt_item.dart';

class AdvancedSplitModal extends StatefulWidget {
  final ReceiptItem item;
  final List<Map<String, dynamic>> groupMembers;
  final Function(Map<String, double>, {bool isAdvanced}) onAssignmentChanged;
  final VoidCallback onClose;

  const AdvancedSplitModal({
    super.key,
    required this.item,
    required this.groupMembers,
    required this.onAssignmentChanged,
    required this.onClose,
  });

  @override
  State<AdvancedSplitModal> createState() => _AdvancedSplitModalState();
}

class _AdvancedSplitModalState extends State<AdvancedSplitModal> {
  double _assignQty = 1.0;
  final List<String> _selectedMemberIds = [];

  @override
  void initState() {
    super.initState();
    final remaining = widget.item.getRemainingQuantity();
    _assignQty = remaining > 0 ? (remaining < 1 ? remaining : 1.0) : 0.0;
  }

  void _toggleMember(String memberId) {
    setState(() {
      if (_selectedMemberIds.contains(memberId)) {
        _selectedMemberIds.remove(memberId);
      } else {
        _selectedMemberIds.add(memberId);
      }
    });
  }

  void _commitAssignment() {
    if (_selectedMemberIds.isEmpty || _assignQty <= 0) return;

    final currentAssignments = Map<String, double>.from(widget.item.assignments);
    final qtyPerPerson = _assignQty / _selectedMemberIds.length;

    for (final memberId in _selectedMemberIds) {
      final current = currentAssignments[memberId] ?? 0.0;
      currentAssignments[memberId] = current + qtyPerPerson;
    }

    widget.onAssignmentChanged(currentAssignments, isAdvanced: true);
    
    // Reset for next assignment
    final newRemaining = widget.item.quantity - 
        currentAssignments.values.fold(0.0, (sum, qty) => sum + qty);
    setState(() {
      _assignQty = newRemaining > 0 ? (newRemaining < 1 ? newRemaining : 1.0) : 0.0;
      _selectedMemberIds.clear();
    });
  }

  void _clearAssignment(String memberId) {
    final currentAssignments = Map<String, double>.from(widget.item.assignments);
    currentAssignments.remove(memberId);
    widget.onAssignmentChanged(currentAssignments, isAdvanced: true);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.item.getRemainingQuantity();
    final assignments = widget.item.assignments;

    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(color: Colors.grey[100]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${remaining.toStringAsFixed(remaining % 1 == 0 ? 0 : 1)} / ${widget.item.quantity.toInt()} Remaining',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppTheme.lightTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.grey[600], size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(5.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quantity selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QUANTITY TO ASSIGN',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _assignQty = (_assignQty - 0.5).clamp(0.5, remaining);
                                });
                              },
                              icon: Icon(Icons.remove),
                            ),
                            SizedBox(
                              width: 15.w,
                              child: TextField(
                                controller: TextEditingController(
                                  text: _assignQty.toStringAsFixed(_assignQty % 1 == 0 ? 0 : 1),
                                ),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  final qty = double.tryParse(value) ?? 0.0;
                                  setState(() {
                                    _assignQty = qty.clamp(0.0, remaining);
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _assignQty = (_assignQty + 0.5).clamp(0.5, remaining);
                                });
                              },
                              icon: Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // Member selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SELECT MEMBERS',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (_selectedMemberIds.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _selectedMemberIds.clear()),
                          child: Text(
                            'Clear',
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 2.h,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: widget.groupMembers.length,
                    itemBuilder: (context, index) {
                      final member = widget.groupMembers[index];
                      final memberId = member['id'].toString();
                      final isSelected = _selectedMemberIds.contains(memberId);

                      return GestureDetector(
                        onTap: () => _toggleMember(memberId),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 12.w,
                                  height: 12.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.lightTheme.primaryColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? AppTheme.lightTheme.primaryColor.withOpacity(0.1)
                                        : Colors.grey[100],
                                  ),
                                  child: Center(
                                    child: Text(
                                      member['avatar'] ?? '?',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppTheme.lightTheme.primaryColor
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      width: 5.w,
                                      height: 5.w,
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightTheme.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              (member['name'] ?? 'Unknown').split(' ')[0],
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: isSelected
                                    ? AppTheme.lightTheme.primaryColor
                                    : Colors.grey[400],
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 4.h),

                  // Commit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedMemberIds.isEmpty || _assignQty <= 0
                          ? null
                          : _commitAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lightTheme.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selectedMemberIds.isEmpty
                            ? 'Select members above'
                            : _selectedMemberIds.length == 1
                                ? 'Assign ${_assignQty.toStringAsFixed(_assignQty % 1 == 0 ? 0 : 1)} to ${widget.groupMembers.firstWhere((m) => m['id'].toString() == _selectedMemberIds.first)['name']?.split(' ')[0] ?? 'member'}'
                                : 'Split ${_assignQty.toStringAsFixed(_assignQty % 1 == 0 ? 0 : 1)} between ${_selectedMemberIds.length} people',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 4.h),
                  Divider(),
                  SizedBox(height: 2.h),

                  // Current assignments
                  Text(
                    'CURRENT ASSIGNMENTS',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  if (assignments.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(4.h),
                        child: Text(
                          'No one assigned yet.',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    )
                  else
                    ...assignments.entries.map((entry) {
                      final memberId = entry.key;
                      final qty = entry.value;
                      final member = widget.groupMembers.firstWhere(
                        (m) => m['id'].toString() == memberId,
                        orElse: () => <String, dynamic>{'name': 'Unknown', 'avatar': '?'},
                      );

                      return Container(
                        margin: EdgeInsets.only(bottom: 1.5.h),
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[100]!),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Center(
                                child: Text(
                                  member['avatar'] ?? '?',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                member['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 1)} items',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '€${(qty * widget.item.unitPrice).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 2.w),
                            IconButton(
                              onPressed: () => _clearAssignment(memberId),
                              icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

