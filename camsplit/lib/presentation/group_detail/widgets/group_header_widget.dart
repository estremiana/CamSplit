import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/group_detail_model.dart';

/// Widget that displays the group header information including image, title, description,
/// member count, and last activity timestamp.
class GroupHeaderWidget extends StatelessWidget {
  final GroupDetailModel groupDetail;

  const GroupHeaderWidget({
    Key? key,
    required this.groupDetail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      color: AppTheme.lightTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(_getResponsivePadding(context)),
        child: Row(
          children: [
            _buildGroupImage(context),
            SizedBox(width: _getResponsiveSpacing(context)),
            Expanded(
              child: _buildGroupInfo(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Get responsive padding based on screen width
  double _getResponsivePadding(BuildContext context) {
    try {
      return 4.w;
    } catch (e) {
      // Fallback for tests or when Sizer is not initialized
      return 16.0;
    }
  }

  /// Get responsive spacing based on screen width
  double _getResponsiveSpacing(BuildContext context) {
    try {
      return 4.w;
    } catch (e) {
      // Fallback for tests or when Sizer is not initialized
      return 16.0;
    }
  }

  /// Get responsive radius based on screen width
  double _getResponsiveRadius(BuildContext context) {
    try {
      return 8.w;
    } catch (e) {
      // Fallback for tests or when Sizer is not initialized
      return 32.0;
    }
  }

  /// Get responsive image size based on screen width
  double _getResponsiveImageSize(BuildContext context) {
    try {
      return 16.w;
    } catch (e) {
      // Fallback for tests or when Sizer is not initialized
      return 64.0;
    }
  }

  /// Get responsive height spacing based on screen height
  double _getResponsiveHeightSpacing(BuildContext context, double heightPercent) {
    try {
      return heightPercent.h;
    } catch (e) {
      // Fallback for tests or when Sizer is not initialized
      return heightPercent * 8.0; // Approximate conversion
    }
  }

  /// Get responsive width spacing based on screen width
  double _getResponsiveWidthSpacing(BuildContext context, double widthPercent) {
    try {
      return widthPercent.w;
    } catch (e) {
      // Fallback for tests or when Sizer is not initialized
      return widthPercent * 4.0; // Approximate conversion
    }
  }

  /// Builds the group image with proper fallback handling
  Widget _buildGroupImage(BuildContext context) {
    final radius = _getResponsiveRadius(context);
    final imageSize = _getResponsiveImageSize(context);
    
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.lightTheme.colorScheme.primaryContainer,
      child: groupDetail.imageUrl != null
          ? ClipOval(
              child: CustomImageWidget(
                imageUrl: groupDetail.imageUrl,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                errorWidget: _buildFallbackIcon(),
              ),
            )
          : _buildFallbackIcon(),
    );
  }

  /// Builds the fallback icon when no image is available
  Widget _buildFallbackIcon() {
    return CustomIconWidget(
      iconName: 'group',
      color: AppTheme.lightTheme.colorScheme.primary,
      size: 32,
    );
  }

  /// Builds the group information section
  Widget _buildGroupInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupTitle(context),
        SizedBox(height: _getResponsiveHeightSpacing(context, 0.5)),
        _buildGroupDescription(context),
        SizedBox(height: _getResponsiveHeightSpacing(context, 1.0)),
        _buildGroupMetadata(context),
      ],
    );
  }

  /// Builds the group title
  Widget _buildGroupTitle(BuildContext context) {
    return Text(
      groupDetail.name,
      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the group description
  Widget _buildGroupDescription(BuildContext context) {
    return Text(
      groupDetail.description.isNotEmpty 
          ? groupDetail.description 
          : 'No description',
      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the group metadata (member count and last activity)
  Widget _buildGroupMetadata(BuildContext context) {
    return Row(
      children: [
        _buildMemberCount(context),
        SizedBox(width: _getResponsiveWidthSpacing(context, 3.0)),
        _buildLastActivity(context),
      ],
    );
  }

  /// Builds the member count indicator
  Widget _buildMemberCount(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomIconWidget(
          iconName: 'group',
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          size: 16,
        ),
        SizedBox(width: _getResponsiveWidthSpacing(context, 1.0)),
        Text(
          '${groupDetail.memberCount} ${groupDetail.memberCount == 1 ? 'member' : 'members'}',
          style: AppTheme.lightTheme.textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Builds the creation timestamp (time since created_at)
  Widget _buildLastActivity(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomIconWidget(
          iconName: 'schedule',
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          size: 16,
        ),
        SizedBox(width: _getResponsiveWidthSpacing(context, 1.0)),
        Text(
          _formatTimeAgo(groupDetail.createdAt),
          style: AppTheme.lightTheme.textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Formats the time ago string for last activity
  String _formatTimeAgo(DateTime dateTime) {
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
}