import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class GroupSettlementWidget extends StatefulWidget {
  final bool isPrivacyMode;
  final VoidCallback onOptimizeSettlements;

  const GroupSettlementWidget({
    super.key,
    required this.isPrivacyMode,
    required this.onOptimizeSettlements,
  });

  @override
  State<GroupSettlementWidget> createState() => _GroupSettlementWidgetState();
}

class _GroupSettlementWidgetState extends State<GroupSettlementWidget> {
  String selectedGroup = 'All Groups';

  final List<Map<String, dynamic>> groups = [
    {
      'name': 'All Groups',
      'totalDebt': 0.0,
      'totalCredit': 0.0,
      'members': [],
    },
    {
      'name': 'Work Team',
      'totalDebt': 156.80,
      'totalCredit': 89.50,
      'members': [
        {
          'name': 'John Doe',
          'avatar':
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
          'amount': 45.50,
          'type': 'owes'
        },
        {
          'name': 'Sarah Johnson',
          'avatar':
              'https://images.unsplash.com/photo-1494790108755-2616b9e2-c7a4-9b1e-6f4d-8c9a2b3c4d5e',
          'amount': 67.30,
          'type': 'owed'
        },
        {
          'name': 'Mike Chen',
          'avatar':
              'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
          'amount': 44.00,
          'type': 'owes'
        }
      ]
    },
    {
      'name': 'Roommates',
      'totalDebt': 89.30,
      'totalCredit': 124.70,
      'members': [
        {
          'name': 'Lisa Park',
          'avatar':
              'https://images.pixabay.com/photo/2016/11-8-15-46-22-1810553_1280.jpg',
          'amount': 67.20,
          'type': 'owed'
        },
        {
          'name': 'Tom Wilson',
          'avatar':
              'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e',
          'amount': 57.50,
          'type': 'owed'
        },
        {
          'name': 'Alex Johnson',
          'avatar':
              'https://images.pexels.com/photos/91227/pexels-photo-91227.jpeg',
          'amount': 89.30,
          'type': 'owes'
        }
      ]
    },
    {
      'name': 'Friends',
      'totalDebt': 72.50,
      'totalCredit': 28.75,
      'members': [
        {
          'name': 'Emma Wilson',
          'avatar':
              'https://images.pexels.com/photos/733872/pexels-photo-733872.jpeg',
          'amount': 28.75,
          'type': 'owed'
        },
        {
          'name': 'David Kim',
          'avatar':
              'https://images.pixabay.com/photo/2016/11-18-18-52-7-1834105_1280.jpg',
          'amount': 43.75,
          'type': 'owes'
        },
        {
          'name': 'Julia Roberts',
          'avatar':
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
          'amount': 28.75,
          'type': 'owes'
        }
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    final currentGroup = groups.firstWhere((g) => g['name'] == selectedGroup);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group selector
        Container(
          margin: EdgeInsets.all(4.w),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: DropdownButton<String>(
            value: selectedGroup,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedGroup = newValue;
                });
              }
            },
            underline: const SizedBox(),
            isExpanded: true,
            icon: CustomIconWidget(
              iconName: 'keyboard_arrow_down',
              color: AppTheme.textSecondaryLight,
              size: 20,
            ),
            items: groups.map<DropdownMenuItem<String>>((group) {
              return DropdownMenuItem<String>(
                value: group['name'],
                child: Text(
                  group['name'],
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        if (selectedGroup == 'All Groups')
          _buildAllGroupsView()
        else
          _buildGroupDetailView(currentGroup),
      ],
    );
  }

  Widget _buildAllGroupsView() {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: groups.length - 1, // Exclude 'All Groups'
        itemBuilder: (context, index) {
          final group = groups[index + 1];
          return _buildGroupCard(group);
        },
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final double totalDebt = group['totalDebt'];
    final double totalCredit = group['totalCredit'];
    final double netBalance = totalCredit - totalDebt;
    final bool isPositive = netBalance >= 0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              selectedGroup = group['name'];
            });
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group['name'],
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                      decoration: BoxDecoration(
                        color: (isPositive
                                ? AppTheme.successLight
                                : AppTheme.warningLight)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        widget.isPrivacyMode
                            ? '••••••'
                            : '${isPositive ? '+' : ''}\$${netBalance.abs().toStringAsFixed(2)}',
                        style: AppTheme.getMonospaceStyle(
                          isLight: true,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ).copyWith(
                          color: isPositive
                              ? AppTheme.successLight
                              : AppTheme.warningLight,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You are owed',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                          Text(
                            widget.isPrivacyMode
                                ? '••••••'
                                : '\$${totalCredit.toStringAsFixed(2)}',
                            style: AppTheme.getMonospaceStyle(
                              isLight: true,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ).copyWith(
                              color: AppTheme.successLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You owe',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                          Text(
                            widget.isPrivacyMode
                                ? '••••••'
                                : '\$${totalDebt.toStringAsFixed(2)}',
                            style: AppTheme.getMonospaceStyle(
                              isLight: true,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ).copyWith(
                              color: AppTheme.warningLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Text(
                      '${group['members'].length} members',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    const Spacer(),
                    CustomIconWidget(
                      iconName: 'arrow_forward_ios',
                      color: AppTheme.textSecondaryLight,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupDetailView(Map<String, dynamic> group) {
    return Expanded(
      child: Column(
        children: [
          // Optimize button
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onOptimizeSettlements,
              icon: CustomIconWidget(
                iconName: 'auto_fix_high',
                color: AppTheme.onPrimaryLight,
                size: 20,
              ),
              label: const Text('Optimize Settlements'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 3.w),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // Group members
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: group['members'].length,
              itemBuilder: (context, index) {
                final member = group['members'][index];
                return _buildMemberCard(member);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final bool isOwed = member['type'] == 'owed';
    final double amount = member['amount'];

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Card(
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              // Member avatar
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
                    imageUrl: member['avatar'],
                    width: 12.w,
                    height: 12.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              // Member info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'],
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isOwed ? 'owes you' : 'you owe',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                decoration: BoxDecoration(
                  color:
                      (isOwed ? AppTheme.successLight : AppTheme.warningLight)
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  widget.isPrivacyMode
                      ? '••••••'
                      : '\$${amount.toStringAsFixed(2)}',
                  style: AppTheme.getMonospaceStyle(
                    isLight: true,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color:
                        isOwed ? AppTheme.successLight : AppTheme.warningLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
