import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ReceiptZoomWidget extends StatefulWidget {
  final String imageUrl;

  const ReceiptZoomWidget({
    super.key,
    required this.imageUrl,
  });

  @override
  State<ReceiptZoomWidget> createState() => _ReceiptZoomWidgetState();
}

class _ReceiptZoomWidgetState extends State<ReceiptZoomWidget> {
  final TransformationController _transformationController =
      TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.8,
          maxScale: 4.0,
          child: Container(
            width: double.infinity,
            color: AppTheme.lightTheme.cardColor,
            child: CustomImageWidget(
              imageUrl: widget.imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
