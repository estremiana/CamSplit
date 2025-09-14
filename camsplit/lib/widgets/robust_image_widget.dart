import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'initials_avatar_widget.dart';

/// A more robust image widget that handles network failures and retries
class RobustImageWidget extends StatefulWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? errorWidget;
  final String? userName;
  final int maxRetries;
  final Duration retryDelay;

  const RobustImageWidget({
    Key? key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.userName,
    this.maxRetries = 2,
    this.retryDelay = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<RobustImageWidget> createState() => _RobustImageWidgetState();
}

class _RobustImageWidgetState extends State<RobustImageWidget> {
  int _retryCount = 0;
  bool _isRetrying = false;

  bool get _isNetworkUrl =>
      widget.imageUrl != null && 
      widget.imageUrl!.isNotEmpty &&
      (widget.imageUrl!.startsWith('http://') || widget.imageUrl!.startsWith('https://'));

  void _retryLoad() {
    if (_retryCount < widget.maxRetries && !_isRetrying) {
      setState(() {
        _isRetrying = true;
        _retryCount++;
      });
      
      // Wait for retry delay then reset retry state
      Future.delayed(widget.retryDelay, () {
        if (mounted) {
          setState(() {
            _isRetrying = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isNetworkUrl) {
      return CachedNetworkImage(
        key: ValueKey('${widget.imageUrl}_retry_$_retryCount'), // Force rebuild on retry
        imageUrl: widget.imageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorWidget: (context, url, error) {
          debugPrint('RobustImageWidget: Failed to load image: $url, Error: $error');
          
          // Show retry option if we haven't exceeded max retries
          if (_retryCount < widget.maxRetries) {
            return GestureDetector(
              onTap: _retryLoad,
              child: Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 32,
                        color: Colors.grey[600],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to retry',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (_isRetrying)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
          
          // Show final error state
          return widget.errorWidget ??
              (widget.userName != null 
                ? InitialsAvatarWidget(
                    name: widget.userName,
                    size: widget.width,
                  )
                : Container(
                    width: widget.width,
                    height: widget.height,
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
                  ));
        },
        placeholder: (context, url) => Container(
          width: widget.width,
          height: widget.height,
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
        memCacheWidth: 1000,
        memCacheHeight: 1000,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    } else if (widget.imageUrl != null) {
      // Local file path
      return Image.file(
        File(widget.imageUrl!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => widget.errorWidget ?? 
          (widget.userName != null 
            ? InitialsAvatarWidget(
                name: widget.userName,
                size: widget.width,
              )
            : Container(
                width: widget.width,
                height: widget.height,
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
      if (widget.userName != null) {
        return InitialsAvatarWidget(
          name: widget.userName,
          size: widget.width,
        );
      } else {
        return Image.asset(
          "assets/images/no-image.jpg",
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          errorBuilder: (context, error, stackTrace) => Container(
            width: widget.width,
            height: widget.height,
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
