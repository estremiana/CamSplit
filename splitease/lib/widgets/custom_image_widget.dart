import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'initials_avatar_widget.dart';

class CustomImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  /// Optional widget to show when the image fails to load.
  /// If null, a default initials avatar or asset image is shown.
  final Widget? errorWidget;
  
  /// User name for initials fallback
  final String? userName;

  const CustomImageWidget({
    Key? key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.userName,
  }) : super(key: key);

  bool get _isNetworkUrl =>
      imageUrl != null && 
      imageUrl!.isNotEmpty &&
      (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    if (_isNetworkUrl) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorWidget: (context, url, error) =>
            errorWidget ??
            (userName != null 
              ? InitialsAvatarWidget(
                  name: userName,
                  size: width,
                )
              : Container(
                  width: width,
                  height: height,
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 32,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Image unavailable',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        httpHeaders: const {
          'User-Agent': 'CamSplit/1.0',
        },
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
        // Add retry mechanism for failed loads
        memCacheWidth: 1000,
        memCacheHeight: 1000,
        // Add timeout for image loading
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    } else if (imageUrl != null) {
      // Local file path
      return Image.file(
        File(imageUrl!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => errorWidget ?? 
          (userName != null 
            ? InitialsAvatarWidget(
                name: userName,
                size: width,
              )
            : Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Image unavailable',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
      );
    } else {
      // Fallback - use initials if userName is provided, otherwise use asset
      if (userName != null) {
        return InitialsAvatarWidget(
          name: userName,
          size: width,
        );
      } else {
        return Image.asset(
          "assets/images/no-image.jpg",
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No image',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }
}
