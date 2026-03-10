import 'package:flutter/material.dart';

/// A wrapper widget that ensures its child does not exceed a certain width
/// and stays centered horizontally. This is useful for adapting full-screen
/// mobile layouts to larger screens like tablets.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 768, // iPad portrait width is 768 logical pixels
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
