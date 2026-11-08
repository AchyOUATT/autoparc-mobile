import 'package:flutter/material.dart';

/// Keeps short empty/error states centered, but lets their full content and
/// actions scroll into reach on short screens or when the keyboard is open.
class ScrollableCenter extends StatelessWidget {
  const ScrollableCenter({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: padding,
            child: Center(child: child),
          ),
        ),
      ),
    ),
  );
}
