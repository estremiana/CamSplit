import 'package:flutter/material.dart';
import '../models/group_member.dart';
import 'custom_image_widget.dart';

/// A reusable widget that displays member avatars in a stacked/overlapping layout.
/// Shows up to [maxVisible] avatars and displays a "+N" indicator for remaining members.
class StackedAvatarsWidget extends StatelessWidget {
  /// List of members to display
  final List<GroupMember> members;
  
  /// Maximum number of avatars to show before displaying "+N" indicator
  /// Default is 3
  final int maxVisible;
  
  /// Size of each avatar (width and height)
  /// Default is 32.0
  final double size;
  
  /// Horizontal spacing between overlapping avatars
  /// Default is 24.0 (creates 8px overlap with 32px avatars)
  final double spacing;
  
  /// Border color around each avatar
  /// Default is white
  final Color borderColor;
  
  /// Border width around each avatar
  /// Default is 2.0
  final double borderWidth;
  
  /// Background color for the "+N" indicator
  /// Default is grey[300]
  final Color? moreIndicatorColor;
  
  /// Text color for the "+N" indicator
  /// Default is grey[700]
  final Color? moreIndicatorTextColor;
  
  /// Font size for the "+N" text
  /// Default is 12.0
  final double moreIndicatorFontSize;

  const StackedAvatarsWidget({
    Key? key,
    required this.members,
    this.maxVisible = 3,
    this.size = 32.0,
    this.spacing = 24.0,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.moreIndicatorColor,
    this.moreIndicatorTextColor,
    this.moreIndicatorFontSize = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalMembers = members.length;
    final hasMore = totalMembers > maxVisible;
    final displayCount = hasMore ? maxVisible : totalMembers;
    final remainingCount = totalMembers - maxVisible;
    
    // Calculate total width needed
    // If we have more members, we need space for avatars + the "+N" indicator
    final totalItems = hasMore ? displayCount + 1 : displayCount;
    final width = (totalItems - 1) * spacing + size;

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          // Display member avatars
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * spacing,
              child: _buildAvatar(members[i]),
            ),
          
          // Display "+N" indicator if there are more members
          if (hasMore)
            Positioned(
              left: displayCount * spacing,
              child: _buildMoreIndicator(remainingCount),
            ),
        ],
      ),
    );
  }

  /// Build a single avatar with border
  Widget _buildAvatar(GroupMember member) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ClipOval(
        child: CustomImageWidget(
          imageUrl: member.avatarUrl,
          width: size,
          height: size,
          userName: member.nickname,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Build the "+N" indicator for remaining members
  Widget _buildMoreIndicator(int count) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: moreIndicatorColor ?? Colors.grey[300],
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: TextStyle(
            color: moreIndicatorTextColor ?? Colors.grey[700],
            fontSize: moreIndicatorFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
