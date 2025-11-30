import 'package:flutter/material.dart';

/// Reusable gradient fade overlay widget
/// 
/// Commonly used at the bottom of scrollable content to create
/// a fade effect that indicates more content is available
class GradientFadeOverlay extends StatelessWidget {
  final double height;
  final List<Color> colors;
  final List<double> stops;

  const GradientFadeOverlay({
    Key? key,
    required this.height,
    this.colors = const [
      Colors.white,
      Colors.white,
      Colors.white,
      Colors.white,
    ],
    this.stops = const [0.0, 0.4, 0.9, 1.0],
  }) : super(key: key);

  /// Default white fade overlay
  factory GradientFadeOverlay.white({
    required double height,
  }) {
    return GradientFadeOverlay(
      height: height,
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.4),
        Colors.white.withOpacity(0.9),
        Colors.white,
      ],
      stops: const [0.0, 0.4, 0.9, 1.0],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: height,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
              stops: stops,
            ),
          ),
        ),
      ),
    );
  }
}

