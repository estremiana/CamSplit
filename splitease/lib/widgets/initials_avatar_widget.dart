import 'package:flutter/material.dart';

class InitialsAvatarWidget extends StatelessWidget {
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final TextStyle? textStyle;

  const InitialsAvatarWidget({
    Key? key,
    required this.name,
    required this.size,
    this.backgroundColor,
    this.textColor,
    this.textStyle,
  }) : super(key: key);

  String _getInitials() {
    if (name == null || name!.trim().isEmpty) {
      return '?';
    }

    final nameParts = name!.trim().split(' ');
    if (nameParts.length >= 2) {
      // First letter of first name + first letter of last name
      return '${nameParts[0][0].toUpperCase()}${nameParts[nameParts.length - 1][0].toUpperCase()}';
    } else if (nameParts.length == 1) {
      // Single name - first two letters
      final name = nameParts[0];
      if (name.length >= 2) {
        return name.substring(0, 2).toUpperCase();
      } else {
        return name[0].toUpperCase();
      }
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = theme.primaryColor;
    final defaultTextColor = Colors.white;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBackgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: textStyle ??
              TextStyle(
                color: textColor ?? defaultTextColor,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }
} 