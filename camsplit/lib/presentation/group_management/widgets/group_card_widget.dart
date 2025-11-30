import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/group.dart';
import '../../../services/group_image_service.dart';

import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/currency_display_widget.dart';
import '../../../widgets/stacked_avatars_widget.dart';

class GroupCardWidget extends StatefulWidget {
  final Group group;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GroupCardWidget({
    Key? key,
    required this.group,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<GroupCardWidget> createState() => _GroupCardWidgetState();
}

class _GroupCardWidgetState extends State<GroupCardWidget> {
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildMemberAvatars() {
    return StackedAvatarsWidget(
      members: widget.group.members,
      maxVisible: 3,
      size: 32.0,
      spacing: 24.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.group.userBalance ?? 0;
    final isPositive = balance >= 0;
    final balanceColor = isPositive ? Color(0xFF059669) : Color(0xFFEF4444); // emerald-600 : red-500

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h), // p-6 space-y-4
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Header Section
              Container(
                height: 96, // h-24
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover Image
                      if (widget.group.imageUrl != null)
                        CustomImageWidget(
                          imageUrl: widget.group.imageUrl,
                          width: double.infinity,
                          height: 96,
                          fit: BoxFit.cover,
                          userName: widget.group.name,
                        )
                      else
                        Container(color: Colors.grey[300]),
                    
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      
                      // Text Overlay
                      Positioned(
                        bottom: 12,
                        left: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.group.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${widget.group.memberCount} members',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Info Section
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatars
                    _buildMemberAvatars(),
                    
                    // Balance
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isPositive ? 'you are owed' : 'you owe',
                          style: TextStyle(
                            color: balanceColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CurrencyDisplayWidget(
                          amount: balance.abs(),
                          currency: widget.group.currency,
                          style: TextStyle(
                            color: balanceColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
}
