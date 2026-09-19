import 'dart:math' as math;
import 'package:flutter/material.dart';

/// iOS screens own the home-indicator inset, so it is painted by their surface.
/// Keep the existing application-level system navigation protection elsewhere.
class AppSafeArea extends StatelessWidget {
  final Widget child;
  const AppSafeArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    bottom: Theme.of(context).platform != TargetPlatform.iOS,
    child: child,
  );
}

/// Paint the bar to the screen edge and reserve the actual bottom inset once.
class BottomNavigationSurface extends StatelessWidget {
  final Widget child;
  final Decoration decoration;
  final double contentHeight;
  final double? width;
  final EdgeInsetsGeometry padding;
  const BottomNavigationSurface({
    super.key,
    required this.child,
    required this.decoration,
    this.contentHeight = 65,
    this.width,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final labelGrowth = math.max(
      0.0,
      MediaQuery.textScalerOf(context).scale(12) - 12,
    );
    final compactHeight = Theme.of(context).platform == TargetPlatform.iOS
        ? math.min(contentHeight, 60.0)
        : contentHeight;
    return Container(
      width: width,
      decoration: decoration,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: SizedBox(
          height: compactHeight + labelGrowth * 1.5,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
